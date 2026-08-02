# ISO 20022 Databricks Parser - Agent Guide & Architecture

**Target Audience:** Autonomous AI Agents (Antigravity, Claude, etc.) and Human Engineers
**Purpose:** Rapid onboarding to the state, design patterns, and exact mechanisms of the ISO 20022 Databricks Parser codebase. Read this before modifying any code.

---

## 1. System Goal & Current State
**Goal:** Flatten complex ISO 20022 MX XML payloads (`pacs.008`, `pacs.009`, `pacs.004`, `pacs.003`, `pacs.002`, `pain.001`) into highly performant Databricks Delta tables.
**State (100% Coverage):** All 6 parsers are fully functional, extracting 100% of their in-scope XSD leaf nodes (~11,200 fields collectively). The architecture uses Databricks native `from_xml()` rather than `xpath_string()` to guarantee maximum throughput.

## 2. The Data Flow Pipeline
1. **Source Staging**: System-specific staging tables (e.g., `payment_staging_gppuk`) containing raw XML payloads in columns `RawMsg_in` / `RawMsg_out`.
2. **Router (`stg_xml_router.sql`)**: 
   - Unions all staging tables.
   - Determines `message_type` via `LIKE` patterns on the root tag.
   - **CRITICAL**: Strips all namespaces dynamically once per row using `regexp_replace(raw_xml, ' xmlns="[^"]*"', '') AS clean_xml`. This is mandatory for `from_xml` to map struct schemas correctly.
3. **Parsers (`parsed_pacs008.sql`, etc.)**: 
   - Filter by `message_type`.
   - Parse `clean_xml` using `from_xml(clean_xml, 'STRUCT<...>', map('rowTag', 'Document'))`.
   - Apply `LATERAL VIEW EXPLODE` on repeating transaction arrays.
   - Extract flattened `snake_case` aliases for every single leaf node.
4. **Foundation (Pending)**: Coalesce logic between parsed outputs and staging.

## 3. Strict Design Patterns (How to Code Here)

### A. NEVER Write SQL Parsers by Hand
The XML structures are too massive (up to 3,000 fields per message). If you need to add a new parser (e.g., `camt.053`) or update an existing one:
**DO NOT manually edit the `parsed_*.sql` models.**
**INSTEAD, use the Auto-Generator:**
```bash
python scripts/generate_from_xml_parser.py --xsd <path_to_xsd> --output models/parser/parsed_<msg>.sql
```
This Python script parses the XSD and dynamically builds the perfect Spark SQL `STRUCT` DDL string, the `EXPLODE` logic, and the thousands of flattened `SELECT` aliases. 

### B. Validation is Mandatory
You cannot claim a parser is complete until it achieves 100.0% coverage against its XSD.
**Run the coverage validator after generating:**
```bash
python scripts/xsd_coverage_validator.py --xsd <path_to_xsd> --parser <path_to_sql> --exclusions RmtInf,SplmtryData
```
If fields are missing, **fix the generator script (`generate_from_xml_parser.py`)**, do not manually patch the SQL. 

### C. Exploding Transaction Arrays
ISO 20022 groups multiple transactions inside a single document (e.g. `CdtTrfTxInf` inside `FIToFICstmrCdtTrf`). The generator script detects these `maxOccurs="unbounded"` arrays and generates a `LATERAL VIEW EXPLODE(...) t AS tx` clause. Root elements (like `GrpHdr`) are accessed via `xml_struct.Root.GrpHdr`, while exploded transaction elements are accessed via `tx.Field`. 

### D. Amount and Currency Flattening
Any `simpleContent` element with an `@Ccy` attribute (like `InstdAmt`) is translated by the generator into a `STRUCT<_VALUE: DECIMAL(18,5), _Ccy: STRING>`.
In the flattened SELECT list, this becomes two columns:
- `tx.InstdAmt._VALUE AS tx_instdamt`
- `tx.InstdAmt._Ccy AS tx_instdamt_ccy`

### E. Materialization
All parser models MUST use `table` materialization with `cluster_by=['PaymentSystemId', 'PaymentSystemName']`. The generator handles writing this config block natively.

---

## 4. Agent Execution Strategy for Future Work
If instructed to add a new message type (e.g., `pain.008`):
1. **Analyze**: Identify the XSD file and determine standard exclusions (`RmtInf`, `SplmtryData`).
2. **Generate**: Run `generate_from_xml_parser.py`.
3. **Verify**: Run `xsd_coverage_validator.py`.
4. **Debug**: If the validator flags missing paths, inspect why the Python generator failed to traverse or emit those paths. Fix the Python script's AST traversal or Spark string formatting, then regenerate. Do not touch the `.sql` directly.
5. **Commit**: Push changes cleanly.
