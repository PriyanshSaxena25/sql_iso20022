"""
XSD Coverage Validator
Explodes an XSD file into all leaf-element XPaths, then compares
against a parser SQL file to verify completeness.

Usage:
  python xsd_coverage_validator.py \
    --xsd pacs.008.001.14.xsd \
    --parser parsed_pacs008.sql \
    --exclusions RmtInf,SplmtryData
"""

import xml.etree.ElementTree as ET
import re
import argparse
import sys
from pathlib import Path

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')


XS = '{http://www.w3.org/2001/XMLSchema}'


def explode_xsd(xsd_path: str) -> list[dict]:
    """
    Parse XSD and return all leaf element XPaths with metadata.
    Returns list of:
      { 'xpath': str, 'type': str, 'min_occurs': str, 'max_occurs': str }
    """
    tree = ET.parse(xsd_path)
    root = tree.getroot()

    # Build type registry: name -> element definition
    complex_types = {}
    for ct in root.findall(f'{XS}complexType'):
        name = ct.get('name')
        if name:
            complex_types[name] = ct

    simple_types = {}
    for st in root.findall(f'{XS}simpleType'):
        name = st.get('name')
        if name:
            simple_types[name] = st

    leaf_paths = []
    visited = set()  # Guard against circular references

    def walk_type(type_name: str, current_path: str, depth: int = 0):
        if depth > 25 or type_name in visited:
            return
        visited.add(type_name)

        ct = complex_types.get(type_name)
        if not ct:
            visited.discard(type_name)
            return

        # Find sequence/choice/all children
        for container_tag in ['sequence', 'choice', 'all']:
            for container in ct.iter(f'{XS}{container_tag}'):
                for elem in container.findall(f'{XS}element'):
                    elem_name = elem.get('name')
                    elem_type = elem.get('type', '')
                    min_occ = elem.get('minOccurs', '1')
                    max_occ = elem.get('maxOccurs', '1')

                    if not elem_name:
                        continue

                    child_path = f'{current_path}/{elem_name}'

                    if elem_type in complex_types:
                        walk_type(elem_type, child_path, depth + 1)
                    elif elem_type in simple_types or elem_type.startswith('xs:'):
                        leaf_paths.append({
                            'xpath': child_path,
                            'type': elem_type,
                            'min_occurs': min_occ,
                            'max_occurs': max_occ,
                        })
                    else:
                        leaf_paths.append({
                            'xpath': child_path,
                            'type': elem_type or 'UNKNOWN',
                            'min_occurs': min_occ,
                            'max_occurs': max_occ,
                        })

        # Check for simpleContent extension (e.g., amount types with @Ccy)
        for sc in ct.findall(f'{XS}simpleContent'):
            for ext in sc.findall(f'{XS}extension'):
                for attr in ext.findall(f'{XS}attribute'):
                    attr_name = attr.get('name')
                    attr_type = attr.get('type', '')
                    if attr_name:
                        leaf_paths.append({
                            'xpath': f'{current_path}/@{attr_name}',
                            'type': attr_type,
                            'min_occurs': '1' if attr.get('use') == 'required' else '0',
                            'max_occurs': '1',
                        })

        visited.discard(type_name)

    # Find the root Document type and start walking
    if 'Document' in complex_types:
        walk_type('Document', '/Document', 0)

    return leaf_paths


def extract_parser_xpaths(parser_sql_path: str) -> set[str]:
    """
    Extract all XPath expressions referenced in the parser SQL file.
    Looks for patterns in xml_extract/xpath_string calls.
    """
    content = Path(parser_sql_path).read_text(encoding='utf-8')

    # Match XPath strings in macro calls or xpath_string calls
    xpath_pattern = r"['\"](/Document/[^'\"]+)['\"]"
    matches = re.findall(xpath_pattern, content)

    xpaths = set()
    for m in matches:
        xpaths.add(m)
        clean_m = re.sub(r'\[\d+\]', '', m)
        xpaths.add(clean_m)
        # Also add base path without attribute for coverage matching
        if '/@' in m:
            xpaths.add(m.split('/@')[0])
            xpaths.add(clean_m.split('/@')[0])

    return xpaths



def validate_coverage(
    xsd_leaves: list[dict],
    parser_xpaths: set[str],
    exclusions: list[str],
) -> dict:
    """
    Compare XSD leaf XPaths against parser-extracted XPaths.
    Returns coverage report.
    """
    covered = []
    missing = []
    excluded = []

    for leaf in xsd_leaves:
        xpath = leaf['xpath']

        # Check exclusions
        if any(f'/{excl}/' in xpath or xpath.endswith(f'/{excl}') for excl in exclusions):
            excluded.append(leaf)
            continue

        # Check if parser covers this XPath
        is_covered = any(
            xpath == px or xpath.startswith(px + '/') or px.startswith(xpath)
            for px in parser_xpaths
        )

        if is_covered:
            covered.append(leaf)
        else:
            missing.append(leaf)

    total = len(covered) + len(missing)
    pct = (len(covered) / total * 100) if total > 0 else 0

    return {
        'total_leaves': len(xsd_leaves),
        'in_scope': total,
        'covered': len(covered),
        'missing': len(missing),
        'excluded': len(excluded),
        'coverage_pct': round(pct, 1),
        'missing_xpaths': sorted([
            {'xpath': m['xpath'], 'type': m['type'], 'required': m['min_occurs'] != '0'}
            for m in missing
        ], key=lambda x: x['xpath']),
    }


def print_report(report: dict, xsd_path: str, parser_path: str):
    """Print formatted coverage report."""
    print(f"\n{'=' * 70}")
    print(f"  XSD Coverage Report")
    print(f"{'=' * 70}")
    print(f"  XSD:    {xsd_path}")
    print(f"  Parser: {parser_path}")
    print(f"{'-' * 70}")
    print(f"  Total XSD leaf elements:  {report['total_leaves']}")
    print(f"  In scope (after excl.):   {report['in_scope']}")
    print(f"  Covered by parser:        {report['covered']}")
    print(f"  Missing from parser:      {report['missing']}")
    print(f"  Excluded (RmtInf, etc.):  {report['excluded']}")
    print(f"  Coverage:                 {report['coverage_pct']}%")
    print(f"{'=' * 70}")

    if report['missing_xpaths']:
        print(f"\n  MISSING XPaths ({report['missing']} fields):")
        print(f"  {'-' * 66}")
        for item in report['missing_xpaths']:
            req = "REQUIRED" if item['required'] else "optional"
            print(f"    [X] {item['xpath']}")
            print(f"      Type: {item['type']}  ({req})")
        print()

        print("  SQL SNIPPETS FOR MISSING FIELDS:")
        print("  --------------------------------")
        for item in report['missing_xpaths']:
            xpath = item['xpath']
            # generate a safe column name
            col_name = xpath.replace('/Document/', '').replace('/', '_').replace('@', 'attr_').lower()
            # truncate if too long
            if len(col_name) > 63: col_name = col_name[-63:]
            # format as jinja macro
            macro = "xml_extract"
            if item['type'] == 'DecimalNumber' or 'Amount' in item['type']:
                macro = "xml_extract_amount"
            print(f"    {{{{ {macro}('xml_content', '{xpath}') }}}} AS {col_name},")
        print()

    if report['coverage_pct'] == 100:
        print("  [PASS] All in-scope XSD fields covered by parser\n")
    else:
        print(f"  [FAIL] {report['missing']} field(s) not covered\n")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Validate parser SQL coverage against XSD schema'
    )
    parser.add_argument('--xsd', required=True, help='Path to XSD file')
    parser.add_argument('--parser', required=True, help='Path to parser SQL file')
    parser.add_argument(
        '--exclusions',
        default='RmtInf,SplmtryData',
        help='Comma-separated element names to exclude from coverage check'
    )
    parser.add_argument(
        '--list-all',
        action='store_true',
        help='List all XSD leaf elements (for debugging)'
    )
    args = parser.parse_args()

    exclusions = [e.strip() for e in args.exclusions.split(',') if e.strip()]

    # Explode XSD
    leaves = explode_xsd(args.xsd)

    if args.list_all:
        print(f"\nAll XSD leaf elements ({len(leaves)}):")
        for leaf in sorted(leaves, key=lambda x: x['xpath']):
            req = "REQ" if leaf['min_occurs'] != '0' else "OPT"
            print(f"  [{req}] {leaf['xpath']}  ({leaf['type']})")
        print()

    # Extract parser XPaths
    parser_xpaths = extract_parser_xpaths(args.parser)

    # Validate
    report = validate_coverage(leaves, parser_xpaths, exclusions)
    print_report(report, args.xsd, args.parser)

    # Exit code: 0 = pass, 1 = fail
    exit(0 if report['coverage_pct'] == 100 else 1)
