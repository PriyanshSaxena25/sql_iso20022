# ISO 20022 Databricks Parser - Agent Guide & Architecture

**Target Audience:** Autonomous AI Agents (Antigravity, Claude, etc.) and Human Engineers
**Purpose:** Rapid onboarding to the state, design patterns, and exact mechanisms of the ISO 20022 Databricks Parser codebase. Read this before modifying any code.

---

## 1. System Goal & Current State
**Goal:** Flatten complex ISO 20022 MX XML payloads into highly performant Databricks Delta tables.
**State (100% Coverage):** 5 parsers (`pacs.008`, `pacs.009`, `pacs.004`, `pacs.003`, `pacs.002`) are fully functional with validated 100% coverage against their CSV XPath ground truth (~12,300 fields collectively). The architecture uses Databricks native `from_xml()` rather than `xpath_string()` to guarantee maximum throughput.

### Verified Parsers
| Parser | Message Type | Fields | Coverage |
|---|---|---|---|
| `parsed_pacs008.sql` | pacs.008 | 1,531 | 100% ✅ |
| `parsed_pacs002.sql` | pacs.002 | 1,491 | 100% ✅ |
| `parsed_pacs003.sql` | pacs.003 | 1,320 | 100% ✅ |
| `parsed_pacs004.sql` | pacs.004 | 4,815 | 100% ✅ |
| `parsed_pacs009.sql` | pacs.009 | 3,153 | 100% ✅ |

### Additional CSVs Available (Parsers Not Yet Generated)
`pacs.007`, `pacs.010`, `pacs.028`, `pacs.029` — CSV XPath files exist in `XSD/CSV/` and can be generated on demand.

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
The XML structures are too massive (up to 4,800+ fields per message). If you need to add a new parser or update an existing one:
**DO NOT manually edit the `parsed_*.sql` models.**
**INSTEAD, use the Auto-Generator with CSV source (PRIMARY):**
```bash
python scripts/generate_from_xml_parser.py \
  --csv XSD/CSV/<message>.csv \
  --output models/parser/parsed_<msg>.sql \
  --exclusions SplmtryData \
  --raw-xml RmtInf
```
The generator reads the pre-exploded CSV XPath file and builds the complete Spark SQL `STRUCT` DDL, the `EXPLODE` logic, and all flattened `SELECT` aliases.

**Legacy XSD mode (deprecated, may produce incomplete results):**
```bash
python scripts/generate_from_xml_parser.py \
  --xsd <path_to_xsd> \
  --output models/parser/parsed_<msg>.sql
```

### B. Validation is Mandatory
You cannot claim a parser is complete until it achieves 100.0% coverage.
**Run the CSV-based coverage validator after generating:**
```bash
python scripts/xsd_coverage_validator.py \
  --csv XSD/CSV/<message>.csv \
  --parser models/parser/parsed_<msg>.sql \
  --exclusions RmtInf,SplmtryData
```
If fields are missing, **fix the generator script (`generate_from_xml_parser.py`)**, do not manually patch the SQL.

**Legacy XSD validation (deprecated):**
```bash
python scripts/xsd_coverage_validator.py \
  --xsd <path_to_xsd> \
  --parser <path_to_sql> \
  --exclusions RmtInf,SplmtryData
```

### C. CSV XPath Files are the Source of Truth
The `XSD/CSV/` directory contains pre-exploded XPath CSV files for each message type. These are the **authoritative ground truth** for coverage validation and parser generation.

CSV schema: `Message, XPath, XML Tag, Type, MinOccurs, MaxOccurs`

The CSV files capture every XPath instance including reused complex types (e.g., `PostalAddress27` appears fully expanded under each agent/party that uses it). This is more accurate than XSD parsing, which can miss paths due to recursive type-reuse guards.

### D. Remittance Info (RmtInf) — Kept as Raw XML
`RmtInf` (Remittance Information) is **NOT parsed into individual fields**. Instead, it is kept as a single raw XML STRING column. This is by design — remittance data is complex and is consumed downstream as XML. The generator handles this via the `--raw-xml RmtInf` flag, which:
- Includes `RmtInf` in the `from_xml` STRUCT as `STRING`
- Emits a single `tx.RmtInf AS ...` column
- Skips all children of `RmtInf` in the CSV

### E. Exploding Transaction Arrays
ISO 20022 groups multiple transactions inside a single document (e.g. `CdtTrfTxInf` inside `FIToFICstmrCdtTrf`). The generator detects the primary unbounded array and generates a `LATERAL VIEW EXPLODE(...) t AS tx` clause. Root elements (like `GrpHdr`) are accessed via `xml_struct.Root.GrpHdr`, while exploded transaction elements are accessed via `tx.Field`.

Secondary arrays within transactions (e.g., `ChrgsInf`) are accessed with `[0]` (first element).

### F. Amount and Currency Flattening
Any element typed as `*CurrencyAndAmount` (like `InstdAmt`) is translated into a `STRUCT<_VALUE: DECIMAL(18,5), _Ccy: STRING>`.
In the flattened SELECT list, this becomes two columns:
- `tx.InstdAmt._VALUE AS cdt_trf_tx_inf_instd_amt`
- `tx.InstdAmt._Ccy AS cdt_trf_tx_inf_instd_amt_ccy`

### G. Materialization
All parser models MUST use `table` materialization with `cluster_by=['PaymentSystemId', 'PaymentSystemName']`. The generator handles writing this config block natively.

---

## 4. Agent Execution Strategy for Future Work
If instructed to add a new message type (e.g., `pacs.007`):
1. **Check CSV**: Look for the XPath CSV in `XSD/CSV/`. If it doesn't exist, create one from the XSD.
2. **Generate**: Run `generate_from_xml_parser.py --csv ...`
3. **Verify**: Run `xsd_coverage_validator.py --csv ...` — must be 100.0%.
4. **Debug**: If the validator flags missing paths, fix the generator script, then regenerate. Do not touch the `.sql` directly.
5. **Commit**: Push changes cleanly.
