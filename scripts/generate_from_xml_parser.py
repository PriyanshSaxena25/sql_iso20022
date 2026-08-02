"""
generate_from_xml_parser.py

Generates a dbt SQL model using Databricks from_xml from an ISO 20022 XSD schema.

Usage:
  python scripts/generate_from_xml_parser.py \
    --xsd path/to/pacs.008.001.14.xsd \
    --output models/parser/parsed_pacs008.sql \
    --exclusions RmtInf,SplmtryData
"""

import xml.etree.ElementTree as ET
import re
import argparse
import sys
from pathlib import Path
from typing import Optional, List, Dict, Tuple, Set

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

XS = '{http://www.w3.org/2001/XMLSchema}'


def camel_to_snake(name: str) -> str:
    """Convert CamelCase or PascalCase to snake_case."""
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    s2 = re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1)
    return s2.lower()


def resolve_simple_type(type_name: str, simple_types: dict) -> str:
    """Map XSD simpleType or primitive type to Databricks Spark SQL data type."""
    if not type_name:
        return 'STRING'

    clean_type = type_name.split(':')[-1]

    if clean_type in ['decimal', 'double', 'float']:
        return 'DECIMAL(18,5)'
    if clean_type in [
        'string', 'boolean', 'dateTime', 'date', 'time',
        'integer', 'int', 'long', 'short', 'anyURI',
        'base64Binary', 'gYear', 'gMonth', 'gDay'
    ]:
        return 'STRING'

    # Check indicator / numeric text keywords
    if any(k in type_name for k in ['Amount', 'Decimal', 'Rate', 'Percentage']):
        if 'NumericText' not in type_name and 'PhoneNumber' not in type_name and 'Count' not in type_name:
            return 'DECIMAL(18,5)'

    # Recursively resolve simple_types restriction base
    if type_name in simple_types:
        st = simple_types[type_name]
        restriction = st.find(f'{XS}restriction')
        if restriction is not None:
            base = restriction.get('base')
            if base:
                return resolve_simple_type(base, simple_types)

    return 'STRING'


class SchemaNode:
    """Represents a node in the XSD schema tree."""
    def __init__(
        self,
        name: str,
        kind: str,  # 'struct', 'array', 'simple_content', 'primitive'
        dbt_type: str = 'STRING',
        children: Optional[List['SchemaNode']] = None,
        element_node: Optional['SchemaNode'] = None,
        min_occurs: str = '1',
        max_occurs: str = '1',
        is_unbounded: bool = False
    ):
        self.name = name
        self.kind = kind
        self.dbt_type = dbt_type
        self.children = children or []
        self.element_node = element_node
        self.min_occurs = min_occurs
        self.max_occurs = max_occurs
        self.is_unbounded = is_unbounded

    def to_ddl(self) -> str:
        if self.kind == 'primitive':
            return self.dbt_type
        elif self.kind == 'array':
            inner_ddl = self.element_node.to_ddl() if self.element_node else 'STRING'
            return f"ARRAY<{inner_ddl}>"
        elif self.kind == 'simple_content':
            fields = [f"{c.name}: {c.to_ddl()}" for c in self.children]
            return f"STRUCT<{', '.join(fields)}>"
        elif self.kind == 'struct':
            fields = [f"{c.name}: {c.to_ddl()}" for c in self.children]
            return f"STRUCT<{', '.join(fields)}>"
        return 'STRING'


def build_schema_tree(xsd_path: str, exclusions: Optional[List[str]] = None) -> Tuple[SchemaNode, str]:
    """Parse XSD and build a complete SchemaNode tree rooted at Document."""
    tree = ET.parse(xsd_path)
    root = tree.getroot()

    exclusions_set = set(exclusions or [])

    complex_types: Dict[str, ET.Element] = {}
    for ct in root.findall(f'{XS}complexType'):
        name = ct.get('name')
        if name:
            complex_types[name] = ct

    simple_types: Dict[str, ET.Element] = {}
    for st in root.findall(f'{XS}simpleType'):
        name = st.get('name')
        if name:
            simple_types[name] = st

    def walk_node(
        node_name: str,
        type_name: str,
        min_occ: str = '1',
        max_occ: str = '1',
        elem: Optional[ET.Element] = None,
        visited: Optional[Set[str]] = None
    ) -> Optional[SchemaNode]:
        if visited is None:
            visited = set()

        if node_name in exclusions_set:
            return None

        is_unbounded = (max_occ == 'unbounded' or (max_occ.isdigit() and int(max_occ) > 1))

        if is_unbounded:
            inner_node = walk_node(
                node_name, type_name, min_occ='1', max_occ='1', elem=elem, visited=visited
            )
            if inner_node is None:
                return None
            return SchemaNode(
                name=node_name,
                kind='array',
                element_node=inner_node,
                min_occurs=min_occ,
                max_occurs=max_occ,
                is_unbounded=True
            )

        # Find complexType definition
        ct = complex_types.get(type_name)
        if ct is None and elem is not None:
            ct = elem.find(f'{XS}complexType')

        # If simple type or primitive
        if ct is None:
            spark_type = resolve_simple_type(type_name, simple_types)
            return SchemaNode(
                name=node_name,
                kind='primitive',
                dbt_type=spark_type,
                min_occurs=min_occ,
                max_occurs=max_occ
            )

        # Recursion guard
        if type_name in visited:
            return SchemaNode(
                name=node_name,
                kind='primitive',
                dbt_type='STRING',
                min_occurs=min_occ,
                max_occurs=max_occ
            )

        visited.add(type_name)

        # Check simpleContent (e.g. Amounts with attributes like @Ccy)
        sc = ct.find(f'{XS}simpleContent')
        if sc is not None:
            ext = sc.find(f'{XS}extension')
            if ext is not None:
                base_type = ext.get('base', '')
                val_spark_type = resolve_simple_type(base_type, simple_types)
                children = [SchemaNode(name='_VALUE', kind='primitive', dbt_type=val_spark_type)]
                for attr in ext.findall(f'{XS}attribute'):
                    attr_name = attr.get('name')
                    attr_type = attr.get('type', '')
                    if attr_name:
                        attr_spark_type = resolve_simple_type(attr_type, simple_types)
                        children.append(
                            SchemaNode(name=f'_{attr_name}', kind='primitive', dbt_type=attr_spark_type)
                        )
                visited.remove(type_name)
                return SchemaNode(
                    name=node_name,
                    kind='simple_content',
                    children=children,
                    min_occurs=min_occ,
                    max_occurs=max_occ
                )

        # ComplexType with sequence/choice/all element children
        children = []
        for container_tag in ['sequence', 'choice', 'all']:
            for container in ct.iter(f'{XS}{container_tag}'):
                for child_elem in container.findall(f'{XS}element'):
                    c_name = child_elem.get('name') or child_elem.get('ref')
                    c_type = child_elem.get('type', '')
                    c_min = child_elem.get('minOccurs', '1')
                    c_max = child_elem.get('maxOccurs', '1')

                    if not c_name or c_name in exclusions_set:
                        continue

                    child_node = walk_node(
                        node_name=c_name,
                        type_name=c_type,
                        min_occ=c_min,
                        max_occ=c_max,
                        elem=child_elem,
                        visited=set(visited)
                    )
                    if child_node is not None:
                        children.append(child_node)

        visited.remove(type_name)

        if not children:
            return SchemaNode(
                name=node_name,
                kind='primitive',
                dbt_type='STRING',
                min_occurs=min_occ,
                max_occurs=max_occ
            )

        return SchemaNode(
            name=node_name,
            kind='struct',
            children=children,
            min_occurs=min_occ,
            max_occurs=max_occ
        )

    doc_node = walk_node('Document', 'Document')
    return doc_node, root.attrib.get('targetNamespace', '')


def find_explode_node(msg_root_node: SchemaNode) -> Optional[SchemaNode]:
    """
    Find the main unbounded transaction array node under MessageRoot (e.g. CdtTrfTxInf, TxInfAndSts, PmtInf).
    """
    candidates = []

    # Check direct children under MessageRoot
    for child in msg_root_node.children:
        if child.is_unbounded or child.kind == 'array':
            if child.name not in ['SplmtryData', 'RmtInf']:
                candidates.append(child)

    # Prefer elements ending or containing transaction keywords
    for c in candidates:
        if any(kw in c.name for kw in ['TxInf', 'PmtInf', 'Tx', 'Sts', 'DrctDbt']):
            return c

    if candidates:
        return candidates[0]

    # Check level 2 (children of children) if no top-level array found
    for child in msg_root_node.children:
        if child.kind == 'struct':
            for subchild in child.children:
                if (subchild.is_unbounded or subchild.kind == 'array') and subchild.name not in ['SplmtryData', 'RmtInf']:
                    return subchild

    return None


def generate_select_fields(
    msg_root_node: SchemaNode,
    explode_node: Optional[SchemaNode]
) -> List[Tuple[str, str, str]]:
    """
    Generate list of (sql_expr, alias, xpath) tuples for all leaf elements.
    """
    select_list: List[Tuple[str, str, str]] = []
    used_aliases: Set[str] = set()

    def make_unique_alias(base_alias: str) -> str:
        alias = base_alias
        counter = 2
        while alias in used_aliases:
            alias = f"{base_alias}_{counter}"
            counter += 1
        used_aliases.add(alias)
        return alias

    def traverse(
        node: SchemaNode,
        sql_parts: List[str],
        alias_parts: List[str],
        xpath_parts: List[str],
        in_exploded: bool
    ):
        # Handle transition into exploded array
        if explode_node is not None and not in_exploded:
            if node.name == explode_node.name:
                inner = node.element_node if node.kind == 'array' else node
                tx_alias_part = camel_to_snake(node.name)
                
                # Traverse children of inner struct under tx alias directly
                if inner.kind == 'struct':
                    for child in inner.children:
                        traverse(
                            child,
                            ['tx'],
                            [tx_alias_part],
                            xpath_parts + [node.name],
                            in_exploded=True
                        )
                else:
                    traverse(
                        inner,
                        ['tx'],
                        [tx_alias_part],
                        xpath_parts + [node.name],
                        in_exploded=True
                    )
                return

        if node.kind == 'primitive':
            sql_expr = '.'.join(sql_parts + [node.name])
            alias_raw = '_'.join(alias_parts + [camel_to_snake(node.name)])
            alias = make_unique_alias(alias_raw)
            xpath = '/'.join(xpath_parts + [node.name])
            select_list.append((sql_expr, alias, xpath))

        elif node.kind == 'simple_content':
            for child in node.children:
                sql_expr = '.'.join(sql_parts + [node.name, child.name])
                if child.name == '_VALUE':
                    alias_raw = '_'.join(alias_parts + [camel_to_snake(node.name)])
                    xpath = '/'.join(xpath_parts + [node.name])
                else:
                    attr_clean = child.name.lstrip('_')
                    alias_raw = '_'.join(alias_parts + [camel_to_snake(node.name), attr_clean.lower()])
                    xpath = '/'.join(xpath_parts + [node.name]) + f"/@{attr_clean}"
                alias = make_unique_alias(alias_raw)
                select_list.append((sql_expr, alias, xpath))

        elif node.kind == 'struct':
            for child in node.children:
                new_sql = sql_parts + [node.name]
                new_alias = alias_parts + [camel_to_snake(node.name)]
                new_xpath = xpath_parts + [node.name]
                traverse(child, new_sql, new_alias, new_xpath, in_exploded)

        elif node.kind == 'array':
            inner = node.element_node if node.element_node else SchemaNode(node.name, 'primitive')
            if inner.kind == 'primitive':
                sql_expr = '.'.join(sql_parts + [node.name])
                alias_raw = '_'.join(alias_parts + [camel_to_snake(node.name)])
                alias = make_unique_alias(alias_raw)
                xpath = '/'.join(xpath_parts + [node.name])
                select_list.append((sql_expr, alias, xpath))
            elif inner.kind == 'simple_content':
                for child in inner.children:
                    sql_expr = f"{'.'.join(sql_parts + [node.name])}[0].{child.name}"
                    if child.name == '_VALUE':
                        alias_raw = '_'.join(alias_parts + [camel_to_snake(node.name)])
                        xpath = '/'.join(xpath_parts + [node.name])
                    else:
                        attr_clean = child.name.lstrip('_')
                        alias_raw = '_'.join(alias_parts + [camel_to_snake(node.name), attr_clean.lower()])
                        xpath = '/'.join(xpath_parts + [node.name]) + f"/@{attr_clean}"
                    alias = make_unique_alias(alias_raw)
                    select_list.append((sql_expr, alias, xpath))
            elif inner.kind == 'struct':
                for child in inner.children:
                    new_sql = sql_parts + [f"{node.name}[0]"]
                    new_alias = alias_parts + [camel_to_snake(node.name)]
                    new_xpath = xpath_parts + [node.name]
                    traverse(child, new_sql, new_alias, new_xpath, in_exploded)

    # Start traversal under MessageRoot
    for child in msg_root_node.children:
        traverse(
            child,
            ['xml_struct', msg_root_node.name],
            [camel_to_snake(msg_root_node.name)],
            ['/Document', msg_root_node.name],
            in_exploded=False
        )

    return select_list


def detect_message_type(xsd_path: str) -> str:
    """Infer message_type string (e.g. pacs.008) from XSD filename."""
    filename = Path(xsd_path).name.lower()
    m = re.search(r'([a-z]{4}\.\d{3})', filename)
    if m:
        return m.group(1)
    return 'pacs.008'


def generate_dbt_sql(xsd_path: str, exclusions: Optional[List[str]] = None) -> str:
    """Generate complete dbt SQL model content."""
    doc_node, _ = build_schema_tree(xsd_path, exclusions=exclusions)

    if not doc_node.children:
        raise ValueError("XSD Document element has no child message root!")

    msg_root_node = doc_node.children[0]
    ddl_schema = doc_node.to_ddl()
    explode_node = find_explode_node(msg_root_node)
    message_type = detect_message_type(xsd_path)

    select_fields = generate_select_fields(msg_root_node, explode_node)

    lines = []
    lines.append("{{ config(materialized='table', cluster_by=['PaymentSystemId', 'PaymentSystemName']) }}")
    lines.append("")
    lines.append("WITH base AS (")
    lines.append("    SELECT")
    lines.append("        PaymentSystemId,")
    lines.append("        PaymentSystemName,")
    lines.append("        msg_direction,")
    lines.append("        source_system,")
    lines.append("        message_type,")
    lines.append("        clean_xml")
    lines.append("    FROM {{ ref('stg_xml_router') }}")
    lines.append(f"    WHERE message_type = '{message_type}'")
    lines.append("),")
    lines.append("")
    lines.append("parsed_xml AS (")
    lines.append("    SELECT")
    lines.append("        PaymentSystemId,")
    lines.append("        PaymentSystemName,")
    lines.append("        msg_direction,")
    lines.append("        source_system,")
    lines.append("        message_type,")
    lines.append(f"        from_xml(clean_xml, '{ddl_schema}', map('rowTag', 'Document')) AS xml_struct")
    lines.append("    FROM base")
    lines.append(")")
    lines.append("")
    lines.append("SELECT")
    lines.append("    PaymentSystemId,")
    lines.append("    PaymentSystemName,")
    lines.append("    msg_direction,")
    lines.append("    source_system,")
    lines.append("    message_type,")

    field_lines = []
    for i, (sql_expr, alias, xpath) in enumerate(select_fields):
        is_last = (i == len(select_fields) - 1)
        comma = "" if is_last else ","
        field_lines.append(f"    {sql_expr} AS {alias}{comma} -- '{xpath}'")

    lines.append("\n".join(field_lines))
    lines.append("FROM parsed_xml")
    if explode_node:
        lines.append(f"LATERAL VIEW EXPLODE(xml_struct.{msg_root_node.name}.{explode_node.name}) t AS tx")

    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description="Generate dbt SQL model using Databricks from_xml")
    parser.add_argument("--xsd", required=True, help="Path to XSD file")
    parser.add_argument("--output", required=False, help="Path to output SQL file (prints to stdout if omitted or '-')")
    parser.add_argument("--exclusions", default="", help="Comma-separated list of element names to exclude")

    args = parser.parse_args()

    exclusions = [e.strip() for e in args.exclusions.split(',') if e.strip()]
    sql_content = generate_dbt_sql(args.xsd, exclusions=exclusions)

    if not args.output or args.output == '-':
        sys.stdout.write(sql_content)
    else:
        out_path = Path(args.output)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(sql_content, encoding='utf-8')
        print(f"Successfully generated dbt model at: {out_path}")


if __name__ == '__main__':
    main()
