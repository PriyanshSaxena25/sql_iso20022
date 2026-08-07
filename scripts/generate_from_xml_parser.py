"""
generate_from_xml_parser.py

Generates a dbt SQL model using Databricks from_xml from either:
  - CSV XPath files (PRIMARY, recommended)
  - XSD schema files (LEGACY, deprecated)

Usage (CSV mode - recommended):
  python scripts/generate_from_xml_parser.py \
    --csv XSD/CSV/pacs.008.001.14.csv \
    --output models/parser/parsed_pacs008.sql \
    --exclusions SplmtryData \
    --raw-xml RmtInf

Usage (XSD mode - deprecated):
  python scripts/generate_from_xml_parser.py \
    --xsd path/to/pacs.008.001.14.xsd \
    --output models/parser/parsed_pacs008.sql \
    --exclusions RmtInf,SplmtryData
"""

import csv
import xml.etree.ElementTree as ET
import re
import argparse
import sys
from pathlib import Path
from collections import OrderedDict
from typing import Optional, List, Tuple, Set

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

# ── Constants ─────────────────────────────────────────────────────────────────

XS = '{http://www.w3.org/2001/XMLSchema}'
MAX_ALIAS_LEN = 63

# XSD types that represent amounts with a @Ccy attribute (simpleContent)
AMOUNT_TYPE_KEYWORDS = ['CurrencyAndAmount']


# ── Utility Functions ─────────────────────────────────────────────────────────

def camel_to_snake(name: str) -> str:
    """Convert CamelCase or PascalCase to snake_case."""
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    s2 = re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1)
    return s2.lower()


def resolve_spark_type(type_name: str) -> Tuple[str, bool]:
    """
    Map an ISO 20022 type name to a Spark SQL type.
    Returns (spark_type, is_amount).
    - Amount types → STRUCT<_VALUE: DECIMAL(18,5), _Ccy: STRING>
    - Decimal types → DECIMAL(18,5)
    - Everything else → STRING
    """
    if not type_name:
        return 'STRING', False

    # Amount types with @Ccy attribute
    if any(kw in type_name for kw in AMOUNT_TYPE_KEYWORDS):
        return 'STRUCT<_VALUE: DECIMAL(18,5), _Ccy: STRING>', True

    # Decimal / rate types
    if type_name == 'DecimalNumber':
        return 'DECIMAL(18,5)', False
    if type_name.endswith('Rate') and 'Code' not in type_name and 'Type' not in type_name:
        return 'DECIMAL(18,5)', False

    return 'STRING', False


def make_alias(parts: List[str], used_aliases: Set[str]) -> str:
    """Build a unique, length-safe column alias from path parts."""
    alias = '_'.join(parts)
    if len(alias) > MAX_ALIAS_LEN:
        alias = alias[-MAX_ALIAS_LEN:]
        # Clean up leading partial word
        idx = alias.find('_')
        if idx > 0:
            alias = alias[idx + 1:]
    # Ensure uniqueness
    base = alias
    counter = 2
    while alias in used_aliases:
        alias = f'{base}_{counter}'
        counter += 1
    used_aliases.add(alias)
    return alias


# ── TreeNode ──────────────────────────────────────────────────────────────────

class TreeNode:
    """Represents a node in the schema tree built from CSV."""

    def __init__(
        self,
        name: str,
        xpath: str,
        type_name: str = '',
        min_occurs: str = '1',
        max_occurs: str = '1',
    ):
        self.name = name
        self.xpath = xpath
        self.type_name = type_name
        self.min_occurs = min_occurs
        self.max_occurs = max_occurs
        self.children: OrderedDict[str, 'TreeNode'] = OrderedDict()
        self.raw_xml: bool = False  # If True, keep as raw XML STRING

    @property
    def is_leaf(self) -> bool:
        return len(self.children) == 0

    @property
    def is_unbounded(self) -> bool:
        mo = self.max_occurs.strip()
        if mo in ('', 'unbounded'):
            return True
        if mo.isdigit() and int(mo) > 1:
            return True
        return False

    @property
    def is_amount(self) -> bool:
        return any(kw in self.type_name for kw in AMOUNT_TYPE_KEYWORDS)

    def to_ddl(self) -> str:
        """Generate Spark SQL DDL type string for this node."""
        if self.raw_xml:
            inner = 'STRING'
        elif self.is_leaf:
            inner, _ = resolve_spark_type(self.type_name)
        else:
            fields = []
            for child in self.children.values():
                fields.append(f'{child.name}: {child.to_ddl()}')
            inner = f'STRUCT<{", ".join(fields)}>'

        if self.is_unbounded:
            return f'ARRAY<{inner}>'
        return inner


# ── CSV Tree Builder ──────────────────────────────────────────────────────────

def build_tree_from_csv(
    csv_path: str,
    raw_xml_elements: Optional[List[str]] = None,
    exclude_elements: Optional[List[str]] = None,
) -> TreeNode:
    """
    Build a TreeNode tree from a CSV file of exploded XPaths.
    CSV columns: Message, XPath, XML Tag, Type, MinOccurs, MaxOccurs

    - raw_xml_elements: elements kept as raw XML STRING (e.g. RmtInf)
    - exclude_elements: elements fully excluded (e.g. SplmtryData)
    """
    raw_xml_set = set(raw_xml_elements or [])
    exclude_set = set(exclude_elements or [])

    with open(csv_path, encoding='utf-8') as f:
        rows = list(csv.DictReader(f))

    # Step 1: Filter rows
    filtered_rows = []
    for row in rows:
        xpath = row['XPath']
        tag = row['XML Tag']

        # Fully exclude elements and all their children
        if any(f'/{excl}/' in xpath or xpath.endswith(f'/{excl}') for excl in exclude_set):
            continue

        # Skip CHILDREN of raw_xml elements (but keep the element itself)
        skip = False
        for raw_elem in raw_xml_set:
            if f'/{raw_elem}/' in xpath:
                skip = True
                break
        if skip:
            continue

        filtered_rows.append(row)

    # Step 2: Create TreeNode for each row
    nodes = {}
    for row in filtered_rows:
        xpath = row['XPath']
        tag = row['XML Tag']
        type_name = row.get('Type', '')
        min_occurs = row.get('MinOccurs', '1')
        max_occurs = row.get('MaxOccurs', '1')

        node = TreeNode(tag, xpath, type_name, min_occurs, max_occurs)
        if tag in raw_xml_set:
            node.raw_xml = True
        nodes[xpath] = node

    # Step 3: Build parent-child relationships
    for xpath, node in nodes.items():
        if xpath == '/Document':
            continue
        parent_xpath = xpath.rsplit('/', 1)[0]
        if parent_xpath in nodes:
            parent = nodes[parent_xpath]
            # Avoid duplicate children (shouldn't happen but be safe)
            if node.name not in parent.children:
                parent.children[node.name] = node

    doc = nodes.get('/Document')
    if doc is None:
        raise ValueError(f"No /Document root found in CSV: {csv_path}")
    return doc


# ── Explode Node Finder ──────────────────────────────────────────────────────

TX_KEYWORDS = ['TxInf', 'PmtInf', 'CdtTrf', 'DrctDbt', 'SttlmReq', 'Sts']


def find_explode_node(msg_root: TreeNode) -> Optional[TreeNode]:
    """
    Find the primary unbounded transaction array element under the message root.
    This is the element that will be LATERAL VIEW EXPLODE'd.
    """
    unbounded = [
        child for child in msg_root.children.values()
        if child.is_unbounded and child.name not in ('SplmtryData', 'RmtInf')
    ]

    # Prefer elements containing transaction-related keywords
    for child in unbounded:
        if any(kw in child.name for kw in TX_KEYWORDS):
            return child

    # Fall back to first unbounded child
    if unbounded:
        return unbounded[0]

    return None


# ── SELECT Field Generator ───────────────────────────────────────────────────

def generate_select_fields(
    msg_root: TreeNode,
    explode_node: Optional[TreeNode],
) -> List[Tuple[str, str, str]]:
    """
    Generate list of (sql_expr, alias, xpath_comment) tuples for all leaf elements.

    - Non-exploded fields: xml_struct.MsgRoot.Path.Field AS alias
    - Exploded fields: tx.Path.Field AS alias
    - Amount types: two columns (_VALUE and _Ccy)
    - Secondary arrays: accessed with [0]
    """
    select_list: List[Tuple[str, str, str]] = []
    used_aliases: Set[str] = set()

    def traverse(
        node: TreeNode,
        sql_parts: List[str],
        alias_parts: List[str],
        xpath_parts: List[str],
        in_exploded: bool,
    ):
        # If this is the primary explode node and we haven't entered it yet
        if not in_exploded and explode_node and node.name == explode_node.name:
            for child in node.children.values():
                traverse(
                    child,
                    sql_parts=['tx'],
                    alias_parts=[camel_to_snake(node.name)],
                    xpath_parts=xpath_parts + [node.name],
                    in_exploded=True,
                )
            return

        # Raw XML element → single STRING column
        if node.raw_xml:
            sql_expr = '.'.join(sql_parts + [node.name])
            alias = make_alias(alias_parts + [camel_to_snake(node.name)], used_aliases)
            xpath = '/'.join(xpath_parts + [node.name])
            select_list.append((sql_expr, alias, xpath))
            return

        # Leaf node
        if node.is_leaf:
            _, is_amount = resolve_spark_type(node.type_name)
            if is_amount:
                # Amount value
                sql_val = '.'.join(sql_parts + [node.name, '_VALUE'])
                alias_val = make_alias(alias_parts + [camel_to_snake(node.name)], used_aliases)
                xpath_val = '/'.join(xpath_parts + [node.name])
                select_list.append((sql_val, alias_val, xpath_val))
                # Currency attribute
                sql_ccy = '.'.join(sql_parts + [node.name, '_Ccy'])
                alias_ccy = make_alias(alias_parts + [camel_to_snake(node.name), 'ccy'], used_aliases)
                xpath_ccy = '/'.join(xpath_parts + [node.name]) + '/@Ccy'
                select_list.append((sql_ccy, alias_ccy, xpath_ccy))
            else:
                sql_expr = '.'.join(sql_parts + [node.name])
                alias = make_alias(alias_parts + [camel_to_snake(node.name)], used_aliases)
                xpath = '/'.join(xpath_parts + [node.name])
                select_list.append((sql_expr, alias, xpath))
            return

        # Non-leaf: struct or secondary array
        if node.is_unbounded:
            # Secondary array → access first element with [0]
            for child in node.children.values():
                traverse(
                    child,
                    sql_parts=sql_parts + [f'{node.name}[0]'],
                    alias_parts=alias_parts + [camel_to_snake(node.name)],
                    xpath_parts=xpath_parts + [node.name],
                    in_exploded=in_exploded,
                )
        else:
            # Regular struct → traverse children
            for child in node.children.values():
                traverse(
                    child,
                    sql_parts=sql_parts + [node.name],
                    alias_parts=alias_parts + [camel_to_snake(node.name)],
                    xpath_parts=xpath_parts + [node.name],
                    in_exploded=in_exploded,
                )

    # Start traversal from message root's children
    for child in msg_root.children.values():
        traverse(
            child,
            sql_parts=['xml_struct', msg_root.name],
            alias_parts=[camel_to_snake(msg_root.name)],
            xpath_parts=['/Document', msg_root.name],
            in_exploded=False,
        )

    return select_list


# ── Message Type Detection ───────────────────────────────────────────────────

def detect_message_type(csv_path: Optional[str] = None, xsd_path: Optional[str] = None) -> str:
    """Infer message_type (e.g. 'pacs.008') from CSV or XSD filename/content."""
    if csv_path:
        # Try reading the Message column from CSV
        try:
            with open(csv_path, encoding='utf-8') as f:
                reader = csv.DictReader(f)
                first_row = next(reader)
                msg = first_row.get('Message', '')
                # "pacs.008.001.14" → "pacs.008"
                parts = msg.split('.')
                if len(parts) >= 2:
                    return f'{parts[0]}.{parts[1]}'
        except (StopIteration, KeyError):
            pass
        # Fall back to filename
        filename = Path(csv_path).stem.lower()
    elif xsd_path:
        filename = Path(xsd_path).stem.lower()
    else:
        return 'unknown'

    m = re.search(r'([a-z]{4}\.\d{3})', filename)
    return m.group(1) if m else 'unknown'


# ── SQL Assembly (CSV Mode) ──────────────────────────────────────────────────

def generate_dbt_sql(
    csv_path: str,
    raw_xml_elements: Optional[List[str]] = None,
    exclude_elements: Optional[List[str]] = None,
) -> str:
    """Generate complete dbt SQL model from a CSV XPath file."""
    raw_xml_elements = raw_xml_elements or ['RmtInf']
    exclude_elements = exclude_elements or ['SplmtryData']

    # Build tree
    doc_node = build_tree_from_csv(csv_path, raw_xml_elements, exclude_elements)

    if not doc_node.children:
        raise ValueError("Document element has no children in CSV!")

    msg_root = list(doc_node.children.values())[0]
    ddl_schema = doc_node.to_ddl()
    explode_node = find_explode_node(msg_root)
    message_type = detect_message_type(csv_path=csv_path)

    select_fields = generate_select_fields(msg_root, explode_node)

    # Assemble SQL
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

    for i, (sql_expr, alias, xpath) in enumerate(select_fields):
        is_last = (i == len(select_fields) - 1)
        comma = "" if is_last else ","
        lines.append(f"    {sql_expr} AS {alias}{comma} -- '{xpath}'")

    lines.append("FROM parsed_xml")
    if explode_node:
        lines.append(
            f"LATERAL VIEW EXPLODE(xml_struct.{msg_root.name}.{explode_node.name}) t AS tx"
        )

    return "\n".join(lines) + "\n"


# ── Legacy XSD Support ───────────────────────────────────────────────────────
# Kept for backward compatibility. Use --csv mode for accurate results.

def _resolve_simple_type_xsd(type_name: str, simple_types: dict) -> str:
    """Map XSD simpleType or primitive type to Spark SQL type (legacy)."""
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
    if any(k in type_name for k in ['Amount', 'Decimal', 'Rate', 'Percentage']):
        if 'NumericText' not in type_name and 'PhoneNumber' not in type_name and 'Count' not in type_name:
            return 'DECIMAL(18,5)'
    if type_name in simple_types:
        st = simple_types[type_name]
        restriction = st.find(f'{XS}restriction')
        if restriction is not None:
            base = restriction.get('base')
            if base:
                return _resolve_simple_type_xsd(base, simple_types)
    return 'STRING'


class _LegacySchemaNode:
    """Represents a node in the XSD schema tree (legacy)."""

    def __init__(self, name, kind, dbt_type='STRING', children=None,
                 element_node=None, min_occurs='1', max_occurs='1', is_unbounded=False):
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
        elif self.kind in ('simple_content', 'struct'):
            fields = [f"{c.name}: {c.to_ddl()}" for c in self.children]
            return f"STRUCT<{', '.join(fields)}>"
        return 'STRING'


def generate_dbt_sql_from_xsd(xsd_path: str, exclusions: Optional[List[str]] = None) -> str:
    """Generate dbt SQL from XSD (DEPRECATED - use CSV mode instead)."""
    print("  ⚠️  XSD mode is deprecated. Results may be incomplete.", file=sys.stderr)
    print("  ⚠️  Use --csv mode with pre-exploded CSV files for accurate coverage.", file=sys.stderr)

    exclusions = exclusions or ['RmtInf', 'SplmtryData']
    exclusions_set = set(exclusions)

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

    def walk_node(node_name, type_name, min_occ='1', max_occ='1', elem=None, visited=None):
        if visited is None:
            visited = set()
        if node_name in exclusions_set:
            return None
        is_unbounded = (max_occ == 'unbounded' or (max_occ.isdigit() and int(max_occ) > 1))
        if is_unbounded:
            inner = walk_node(node_name, type_name, '1', '1', elem, visited)
            if inner is None:
                return None
            return _LegacySchemaNode(node_name, 'array', element_node=inner,
                                     min_occurs=min_occ, max_occurs=max_occ, is_unbounded=True)
        ct = complex_types.get(type_name)
        if ct is None and elem is not None:
            ct = elem.find(f'{XS}complexType')
        if ct is None:
            spark_type = _resolve_simple_type_xsd(type_name, simple_types)
            return _LegacySchemaNode(node_name, 'primitive', dbt_type=spark_type,
                                     min_occurs=min_occ, max_occurs=max_occ)
        if type_name in visited:
            return _LegacySchemaNode(node_name, 'primitive', dbt_type='STRING',
                                     min_occurs=min_occ, max_occurs=max_occ)
        visited.add(type_name)
        sc = ct.find(f'{XS}simpleContent')
        if sc is not None:
            ext = sc.find(f'{XS}extension')
            if ext is not None:
                base_type = ext.get('base', '')
                val_type = _resolve_simple_type_xsd(base_type, simple_types)
                children = [_LegacySchemaNode('_VALUE', 'primitive', dbt_type=val_type)]
                for attr in ext.findall(f'{XS}attribute'):
                    attr_name = attr.get('name')
                    if attr_name:
                        attr_type = _resolve_simple_type_xsd(attr.get('type', ''), simple_types)
                        children.append(_LegacySchemaNode(f'_{attr_name}', 'primitive', dbt_type=attr_type))
                visited.remove(type_name)
                return _LegacySchemaNode(node_name, 'simple_content', children=children,
                                         min_occurs=min_occ, max_occurs=max_occ)
        children = []
        for tag in ['sequence', 'choice', 'all']:
            for container in ct.iter(f'{XS}{tag}'):
                for child_elem in container.findall(f'{XS}element'):
                    c_name = child_elem.get('name') or child_elem.get('ref')
                    c_type = child_elem.get('type', '')
                    c_min = child_elem.get('minOccurs', '1')
                    c_max = child_elem.get('maxOccurs', '1')
                    if not c_name or c_name in exclusions_set:
                        continue
                    child_node = walk_node(c_name, c_type, c_min, c_max, child_elem, set(visited))
                    if child_node is not None:
                        children.append(child_node)
        visited.remove(type_name)
        if not children:
            return _LegacySchemaNode(node_name, 'primitive', dbt_type='STRING',
                                     min_occurs=min_occ, max_occurs=max_occ)
        return _LegacySchemaNode(node_name, 'struct', children=children,
                                 min_occurs=min_occ, max_occurs=max_occ)

    doc_node = walk_node('Document', 'Document')
    if not doc_node or not doc_node.children:
        raise ValueError("XSD Document has no children!")

    msg_root = doc_node.children[0]
    ddl_schema = doc_node.to_ddl()
    message_type = detect_message_type(xsd_path=xsd_path)

    # Find explode node (legacy)
    explode = None
    for child in msg_root.children:
        if child.is_unbounded or child.kind == 'array':
            if child.name not in ('SplmtryData', 'RmtInf'):
                explode = child
                break

    # Generate SELECT fields (legacy - simplified)
    select_list = []
    used = set()

    def _legacy_traverse(node, sql_parts, alias_parts, xpath_parts, in_exploded):
        if not in_exploded and explode and node.name == explode.name:
            inner = node.element_node if node.kind == 'array' else node
            tx_alias = camel_to_snake(node.name)
            if inner.kind == 'struct':
                for child in inner.children:
                    _legacy_traverse(child, ['tx'], [tx_alias], xpath_parts + [node.name], True)
            return
        if node.kind == 'primitive':
            sql = '.'.join(sql_parts + [node.name])
            alias = make_alias(alias_parts + [camel_to_snake(node.name)], used)
            xpath = '/'.join(xpath_parts + [node.name])
            select_list.append((sql, alias, xpath))
        elif node.kind == 'simple_content':
            for child in node.children:
                sql = '.'.join(sql_parts + [node.name, child.name])
                if child.name == '_VALUE':
                    alias = make_alias(alias_parts + [camel_to_snake(node.name)], used)
                    xpath = '/'.join(xpath_parts + [node.name])
                else:
                    attr_clean = child.name.lstrip('_')
                    alias = make_alias(alias_parts + [camel_to_snake(node.name), attr_clean.lower()], used)
                    xpath = '/'.join(xpath_parts + [node.name]) + f'/@{attr_clean}'
                select_list.append((sql, alias, xpath))
        elif node.kind == 'struct':
            for child in node.children:
                _legacy_traverse(child, sql_parts + [node.name], alias_parts + [camel_to_snake(node.name)],
                                 xpath_parts + [node.name], in_exploded)
        elif node.kind == 'array':
            inner = node.element_node or _LegacySchemaNode(node.name, 'primitive')
            if inner.kind == 'struct':
                for child in inner.children:
                    _legacy_traverse(child, sql_parts + [f'{node.name}[0]'],
                                     alias_parts + [camel_to_snake(node.name)],
                                     xpath_parts + [node.name], in_exploded)
            elif inner.kind == 'simple_content':
                for child in inner.children:
                    sql = f"{'.'.join(sql_parts + [node.name])}[0].{child.name}"
                    if child.name == '_VALUE':
                        alias = make_alias(alias_parts + [camel_to_snake(node.name)], used)
                        xpath = '/'.join(xpath_parts + [node.name])
                    else:
                        attr_clean = child.name.lstrip('_')
                        alias = make_alias(alias_parts + [camel_to_snake(node.name), attr_clean.lower()], used)
                        xpath = '/'.join(xpath_parts + [node.name]) + f'/@{attr_clean}'
                    select_list.append((sql, alias, xpath))

    for child in msg_root.children:
        _legacy_traverse(child, ['xml_struct', msg_root.name], [camel_to_snake(msg_root.name)],
                         ['/Document', msg_root.name], False)

    # Assemble SQL
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

    for i, (sql_expr, alias, xpath) in enumerate(select_list):
        is_last = (i == len(select_list) - 1)
        comma = "" if is_last else ","
        lines.append(f"    {sql_expr} AS {alias}{comma} -- '{xpath}'")

    lines.append("FROM parsed_xml")
    if explode:
        lines.append(f"LATERAL VIEW EXPLODE(xml_struct.{msg_root.name}.{explode.name}) t AS tx")

    return "\n".join(lines) + "\n"


# ── Main ─────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Generate dbt SQL model using Databricks from_xml"
    )

    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument('--csv', help='Path to CSV file with exploded XPaths (recommended)')
    source.add_argument('--xsd', help='Path to XSD schema file (deprecated, use --csv)')

    parser.add_argument('--output', help='Output SQL file path (prints to stdout if omitted)')
    parser.add_argument(
        '--exclusions',
        default='SplmtryData',
        help='Comma-separated elements to fully exclude (default: SplmtryData)'
    )
    parser.add_argument(
        '--raw-xml',
        default='RmtInf',
        help='Comma-separated elements to keep as raw XML STRING (default: RmtInf)'
    )

    args = parser.parse_args()

    if args.csv:
        raw_xml = [e.strip() for e in args.raw_xml.split(',') if e.strip()]
        excludes = [e.strip() for e in args.exclusions.split(',') if e.strip()]
        sql_content = generate_dbt_sql(args.csv, raw_xml, excludes)
    else:
        # Legacy XSD mode: combine all exclusions
        all_exclusions = []
        all_exclusions += [e.strip() for e in args.exclusions.split(',') if e.strip()]
        all_exclusions += [e.strip() for e in args.raw_xml.split(',') if e.strip()]
        sql_content = generate_dbt_sql_from_xsd(args.xsd, all_exclusions)

    if not args.output or args.output == '-':
        sys.stdout.write(sql_content)
    else:
        out_path = Path(args.output)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(sql_content, encoding='utf-8')
        print(f"✅ Generated dbt model: {out_path}")
        # Print stats
        field_count = sql_content.count(' AS ')
        print(f"   Fields: {field_count - 1}")  # -1 for xml_struct AS


if __name__ == '__main__':
    main()
