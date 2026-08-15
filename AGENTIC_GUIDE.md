# AGENTIC INTEGRATION GUIDE (FOR AI CLI AGENTS)

> **Purpose**: Single point of truth for any AI coding agent (Antigravity CLI, Claude Code, Cursor, Codex, Aider) to instantly understand, adopt, configure, and deploy this Data Product Catalog framework for any DAB-based dbt data product on GitLab Pages.

---

## 1. System Architecture at a Glance

```
dbt-dataproduct-pages/
├── site-config.yml              <-- [SINGLE SOURCE OF TRUTH] Edit this for any data product
├── .gitlab-ci.yml               <-- GitLab Pages CI/CD pipeline (Build -> Test -> Pages)
├── src/
│   └── build.py                 <-- Validates YAML & compiles public/data/site-config.json
├── scripts/
│   └── extract-dbt-artifacts.py <-- Compiles dbt manifest.json + catalog.json -> schema.json
├── public/                      <-- Static site root (Zero npm/Node runtime dependencies)
│   ├── index.html               <-- Product landing & quick facts
│   ├── schema.html              <-- Interactive client-side Schema Explorer
│   ├── sla.html                 <-- SLA commitments & data quality contract
│   ├── onboarding.html          <-- Consumer onboarding & sample SQL/PySpark queries
│   ├── ownership.html           <-- Team, governance & escalation path
│   ├── css/                     <-- Pure CSS design system (tokens, base, layout, components)
│   ├── js/                      <-- Client-side hydration (config-loader, nav, schema-explorer)
│   └── data/                    <-- JSON payloads consumed by client-side JS
├── tests/                       <-- Automated Playwright visual + functional regression test suite
└── docs/                        <-- Architecture Decision Records (ADRs) & adoption guides
```

---

## 2. Fast 3-Step Agentic Adoption Protocol

If you are an AI agent tasked with onboarding a new Data Product into this framework:

### Step 1: Update `site-config.yml`
Modify only the values in `site-config.yml` to match the target data product:
- `product.name`: Name of the Data Product (e.g. `FDP Payments`, `Customer 360`)
- `product.domain`: Business domain (e.g. `Payments`, `Risk`, `Marketing`)
- `ownership.team`: Producing team and contact Slack/email
- `sla`: Data freshness target, uptime SLA, and quality score thresholds
- `onboarding.catalog` & `schema`: Databricks Unity Catalog & schema names
- `onboarding.sample_queries`: 2–3 copy-paste SQL and PySpark query recipes

### Step 2: Extract dbt Artifacts (Optional / Automated)
When dbt docs generate `target/manifest.json` and `target/catalog.json`:
```bash
python scripts/extract-dbt-artifacts.py --manifest-path target/manifest.json --catalog-path target/catalog.json --output-path public/data/schema.json
```
*(If dbt artifacts are not yet built, the pre-populated `public/data/schema.json` serves as the fallback catalog).*

### Step 3: Compile and Validate
```bash
python src/build.py
```
This validates the YAML schema, compiles `public/data/site-config.json`, and verifies all HTML pages are present.

---

## 3. Subagent Squad Definitions (Model & Thinking Tiers)

When orchestrating in an agentic CLI harness (Claude Code, Antigravity CLI, Cursor Multi-Agent, Roo-Code), deploy using the following **Model & Thinking Tier Matrix**:

```yaml
agent_topology:
  supervisor:
    model: "claude-3-opus (or latest Opus / Pro equivalent)"
    thinking_tier: "max_effort"  # Maximum reasoning budget enabled
    role: "Lead Solutions Architect & Quality Gate Overseer"
    responsibilities:
      - Enforce 100% acceptance criteria across all pages and configurations.
      - Conduct multi-viewport visual audits (phone 390px, tablet 768px, desktop 1440px).
      - Verify zero horizontal overflow, WCAG AA contrast, and >= 44px tap targets.
      - Review and sign off on all code diffs before merging.

  workers_default:
    model: "claude-3-5-sonnet (or latest Sonnet equivalent)"
    thinking_tier: "ultracode_thinking"  # Extended architectural reasoning for high-craft code
    subagents:
      - name: config-integrator
        role: "Data Product Metadata Specialist"
        prompt: "Map target domain tables, SLAs, query samples, and team ownership into site-config.yml. Execute python src/build.py to ensure clean JSON compilation."

      - name: dbt-artifact-sync
        role: "dbt Artifact Parser"
        prompt: "Run scripts/extract-dbt-artifacts.py on dbt target/ files. Ensure model descriptions, column types, test assertions (unique, not_null, accepted_values), and tags map cleanly into public/data/schema.json."

      - name: coder-html
        role: "Semantic HTML Architect"
        prompt: "Maintain clean semantic HTML5 markup across all 5 pages. Ensure data-config binding attributes and accessible ARIA attributes are strictly intact."

      - name: style-craftsman
        role: "CSS & Design Token Engineer"
        prompt: "Maintain public/css/tokens.css, base.css, layout.css, and components.css. Enforce the Editorial Data broadsheet aesthetic with zero clipping and zero mobile overflow."

      - name: test-automator
        role: "Playwright QA & Verification Engineer"
        prompt: "Execute pytest tests/ -v. Run automated visual regression gates across phone (390px), tablet (768px), and desktop (1440px), asserting 100% test pass rate."

      - name: fixer
        role: "Rapid Defect Resolver"
        prompt: "Consume test failure logs and trace offending DOM/CSS nodes to apply minimal, high-precision surgical fixes without breaking existing desktop layouts."
```

---

## 4. Key Rules for Agents

1. **Zero Node/Webpack Build Tooling**: Keep all pages static HTML + Vanilla JS. Do not introduce npm, bundlers, or React unless explicitly requested.
2. **Deterministic Selectors**: All dynamic elements use `data-config="path.to.key"` attributes. The `public/js/config-loader.js` script handles automatic DOM injection at runtime.
3. **No Placeholders**: Never leave `TODO`, `lorem ipsum`, or unstyled tags.
4. **GitLab Pages Native**: GitLab CI publishes the `public/` directory artifact automatically when merged to the default branch.

---

## 5. Quick Commands Reference

| Action | Command |
|---|---|
| **Build & Validate** | `python src/build.py` |
| **Extract dbt Catalog** | `python scripts/extract-dbt-artifacts.py` |
| **Run Local Server** | `python -m http.server 8000 --directory public` |
| **Run Full Test Suite** | `pytest tests/ -v` |
| **Test Overflow Gate** | `pytest tests/visual/test_overflow.py -v` |
