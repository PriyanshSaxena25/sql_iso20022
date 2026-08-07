"""
XSD Coverage Validator (CSV-based)
Uses pre-exploded CSV XPath files as the authoritative source of truth,
then compares against a parser SQL file to verify completeness.

Usage:
  python xsd_coverage_validator.py \
    --csv XSD/CSV/pacs.008.001.14.csv \
    --parser models/parser/parsed_pacs008.sql \
    --exclusions RmtInf,SplmtryData

Legacy XSD mode (deprecated but still supported):
  python xsd_coverage_validator.py \
    --xsd XSD/pacs.008.001.14.xsd \
    --parser models/parser/parsed_pacs008.sql \
    --exclusions RmtInf,SplmtryData
"""

import csv
import xml.etree.ElementTree as ET
import re
import argparse
import sys
from pathlib import Path

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

XS = '{http://www.w3.org/2001/XMLSchema}'


# ---------------------------------------------------------------------------
# CSV-based source (PRIMARY)
# ---------------------------------------------------------------------------

def load_leaves_from_csv(csv_path: str) -> list[dict]:
    """
    Load all XPaths from a CSV file and identify leaf nodes.
    A leaf node is one where no other XPath in the CSV is a child of it.

    CSV columns: Message, XPath, XML Tag, Type, MinOccurs, MaxOccurs

    Returns list of:
      { 'xpath': str, 'type': str, 'min_occurs': str, 'max_occurs': str }
    """
    with open(csv_path, encoding='utf-8') as f:
        rows = list(csv.DictReader(f))

    all_xpaths = set(r['XPath'] for r in rows)

    leaves = []
    for r in rows:
        xp = r['XPath']
        # A row is a leaf if no other XPath starts with it + '/'
        is_leaf = not any(x != xp and x.startswith(xp + '/') for x in all_xpaths)
        if is_leaf:
            leaves.append({
                'xpath': xp,
                'type': r.get('Type', 'UNKNOWN'),
                'min_occurs': r.get('MinOccurs', '1'),
                'max_occurs': r.get('MaxOccurs', '1'),
            })

    return leaves


# ---------------------------------------------------------------------------
# XSD-based source (LEGACY / DEPRECATED)
# ---------------------------------------------------------------------------

def explode_xsd(xsd_path: str) -> list[dict]:
    """
    Parse XSD and return all leaf element XPaths with metadata.
    DEPRECATED: Use load_leaves_from_csv() instead.
    Returns list of:
      { 'xpath': str, 'type': str, 'min_occurs': str, 'max_occurs': str }
    """
    tree = ET.parse(xsd_path)
    root = tree.getroot()

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
    visited = set()

    def walk_type(type_name: str, current_path: str, depth: int = 0):
        if depth > 25 or type_name in visited:
            return
        visited.add(type_name)

        ct = complex_types.get(type_name)
        if not ct:
            visited.discard(type_name)
            return

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

    if 'Document' in complex_types:
        walk_type('Document', '/Document', 0)

    return leaf_paths


# ---------------------------------------------------------------------------
# Parser SQL XPath extraction
# ---------------------------------------------------------------------------

def extract_parser_xpaths(parser_sql_path: str) -> set[str]:
    """
    Extract all XPath expressions referenced in the parser SQL file.
    Uses multiple strategies:
      1. Comment XPaths: patterns like -- '/Document/...'
      2. Struct access paths: patterns like xml_struct.Root.GrpHdr.MsgId
         converted back to /Document/Root/GrpHdr/MsgId
      3. tx.Field patterns from LATERAL VIEW EXPLODE
    """
    content = Path(parser_sql_path).read_text(encoding='utf-8')

    xpaths = set()

    # Strategy 1: Extract quoted XPath strings from comments
    xpath_pattern = r"['\"](/Document/[^'\"]+)['\"]"
    for m in re.findall(xpath_pattern, content):
        xpaths.add(m)
        # Also add without array indices
        clean_m = re.sub(r'\[\d+\]', '', m)
        xpaths.add(clean_m)

    # Strategy 2: Extract struct-access dot-notation paths
    # Match patterns like: xml_struct.FIToFICstmrCdtTrf.GrpHdr.MsgId AS alias
    struct_pattern = r'xml_struct\.([A-Za-z0-9_.]+)\s+AS\s+'
    for m in re.findall(struct_pattern, content):
        # Convert dot-notation to XPath: xml_struct.Root.Field -> /Document/Root/Field
        parts = m.replace('._VALUE', '').replace('._Ccy', '').split('.')
        # Remove array index notation like [0]
        parts = [re.sub(r'\[\d+\]', '', p) for p in parts]
        xpath = '/Document/' + '/'.join(parts)
        xpaths.add(xpath)

    # Strategy 3: Extract tx.Field patterns (from LATERAL VIEW EXPLODE)
    # First find what the explode target is
    explode_match = re.search(
        r'LATERAL\s+VIEW\s+EXPLODE\(xml_struct\.([A-Za-z0-9_.]+)\)',
        content
    )
    explode_prefix = ''
    if explode_match:
        parts = explode_match.group(1).split('.')
        explode_prefix = '/Document/' + '/'.join(parts)

    # Now match tx.Field.SubField AS alias
    tx_pattern = r'tx\.([A-Za-z0-9_.]+)\s+AS\s+'
    for m in re.findall(tx_pattern, content):
        parts = m.replace('._VALUE', '').replace('._Ccy', '').split('.')
        parts = [re.sub(r'\[\d+\]', '', p) for p in parts]
        if explode_prefix:
            xpath = explode_prefix + '/' + '/'.join(parts)
            xpaths.add(xpath)

    return xpaths


# ---------------------------------------------------------------------------
# Coverage validation
# ---------------------------------------------------------------------------

def validate_coverage(
    xsd_leaves: list[dict],
    parser_xpaths: set[str],
    exclusions: list[str],
) -> dict:
    """
    Compare XSD/CSV leaf XPaths against parser-extracted XPaths.
    Returns coverage report.

    Matching logic: An XPath is covered if the parser has an EXACT match.
    No loose prefix matching — each leaf must be explicitly selected.
    """
    covered = []
    missing = []
    excluded = []

    for leaf in xsd_leaves:
        xpath = leaf['xpath']

        # Check exclusions (RmtInf kept as raw XML, SplmtryData ignored)
        if any(f'/{excl}/' in xpath or xpath.endswith(f'/{excl}') for excl in exclusions):
            excluded.append(leaf)
            continue

        # Exact match only — the parser must explicitly reference this XPath
        is_covered = xpath in parser_xpaths

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
        'covered_xpaths': sorted([
            {'xpath': c['xpath'], 'type': c['type']}
            for c in covered
        ], key=lambda x: x['xpath']),
    }


def print_report(report: dict, source_path: str, parser_path: str):
    """Print formatted coverage report."""
    print(f"\n{'=' * 70}")
    print(f"  XSD Coverage Report")
    print(f"{'=' * 70}")
    print(f"  Source: {source_path}")
    print(f"  Parser: {parser_path}")
    print(f"{'-' * 70}")
    print(f"  Total leaf elements:      {report['total_leaves']}")
    print(f"  In scope (after excl.):   {report['in_scope']}")
    print(f"  Covered by parser:        {report['covered']}")
    print(f"  Missing from parser:      {report['missing']}")
    print(f"  Excluded (RmtInf, etc.):  {report['excluded']}")
    print(f"  Coverage:                 {report['coverage_pct']}%")
    print(f"{'=' * 70}")

    if report['missing_xpaths']:
        print(f"\n  MISSING XPaths ({report['missing']} fields):")
        print(f"  {'-' * 66}")
        for item in report['missing_xpaths'][:50]:  # Show first 50
            req = "REQUIRED" if item['required'] else "optional"
            print(f"    [X] {item['xpath']}")
            print(f"        Type: {item['type']}  ({req})")

        if len(report['missing_xpaths']) > 50:
            print(f"\n    ... and {len(report['missing_xpaths']) - 50} more missing fields")
            print(f"    Run with --output-missing to export full list to CSV")

        print()

    if report['coverage_pct'] == 100:
        print("  ✅ [PASS] All in-scope fields covered by parser\n")
    else:
        print(f"  ❌ [FAIL] {report['missing']} field(s) not covered\n")


def export_missing_csv(report: dict, output_path: str):
    """Export missing XPaths to a CSV file for review."""
    with open(output_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['XPath', 'Type', 'Required'])
        for item in report['missing_xpaths']:
            writer.writerow([item['xpath'], item['type'], item['required']])
    print(f"  Exported {len(report['missing_xpaths'])} missing XPaths to: {output_path}")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Validate parser SQL coverage against XSD schema (CSV or XSD source)'
    )
    source_group = parser.add_mutually_exclusive_group(required=True)
    source_group.add_argument('--csv', help='Path to CSV file with exploded XPaths (recommended)')
    source_group.add_argument('--xsd', help='Path to XSD file (deprecated, use --csv)')

    parser.add_argument('--parser', required=True, help='Path to parser SQL file')
    parser.add_argument(
        '--exclusions',
        default='RmtInf,SplmtryData',
        help='Comma-separated element names to exclude from coverage check (default: RmtInf,SplmtryData)'
    )
    parser.add_argument(
        '--list-all',
        action='store_true',
        help='List all leaf elements (for debugging)'
    )
    parser.add_argument(
        '--list-covered',
        action='store_true',
        help='List all covered (matched) XPaths'
    )
    parser.add_argument(
        '--output-missing',
        help='Export missing XPaths to a CSV file'
    )
    args = parser.parse_args()

    exclusions = [e.strip() for e in args.exclusions.split(',') if e.strip()]

    # Load leaves from CSV (primary) or XSD (legacy)
    if args.csv:
        source_path = args.csv
        leaves = load_leaves_from_csv(args.csv)
        print(f"\n  [CSV MODE] Loaded {len(leaves)} leaf elements from {args.csv}")
    else:
        source_path = args.xsd
        leaves = explode_xsd(args.xsd)
        print(f"\n  [XSD MODE - DEPRECATED] Loaded {len(leaves)} leaf elements from {args.xsd}")
        print(f"  ⚠️  Consider using --csv for more accurate results")

    if args.list_all:
        print(f"\nAll leaf elements ({len(leaves)}):")
        for leaf in sorted(leaves, key=lambda x: x['xpath']):
            req = "REQ" if leaf['min_occurs'] != '0' else "OPT"
            print(f"  [{req}] {leaf['xpath']}  ({leaf['type']})")
        print()

    # Extract parser XPaths
    parser_xpaths = extract_parser_xpaths(args.parser)

    # Validate
    report = validate_coverage(leaves, parser_xpaths, exclusions)
    print_report(report, source_path, args.parser)

    if args.list_covered:
        print(f"\n  COVERED XPaths ({report['covered']} fields):")
        print(f"  {'-' * 66}")
        for item in report['covered_xpaths']:
            print(f"    [✓] {item['xpath']}  ({item['type']})")
        print()

    if args.output_missing:
        export_missing_csv(report, args.output_missing)

    # Exit code: 0 = pass, 1 = fail
    exit(0 if report['coverage_pct'] == 100 else 1)
