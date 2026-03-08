# Snowflake Intelligence — Hands-On Lab
## SoFi Risk Data Team

Build an AI agent that serves both business stakeholders and the Risk Data Team using Snowflake Intelligence.

### What You'll Build

An Enterprise Intelligence Agent (**Risk Data // AI**) with 3 tools:
1. **Cortex Analyst** — queries loan originations, portfolio performance, and data quality metrics via natural language
2. **Snowflake Documentation (Knowledge Extension)** — searches official Snowflake docs
3. **Send Email (Custom Tool)** — sends summary emails on demand

### Files

| File | Description |
|------|-------------|
| `01_bootstrap.sql` | Run first in a fresh SQL worksheet — creates role, warehouse, and Git API integration |
| `02_setup.sql` | Run from the Git workspace — creates database, tables, loads data, and sets up email procedure |
| `03_risk_data_model.yaml` | Semantic model backup (YAML) — use if you skip the UI-based semantic view creation |
| `data/products.csv` | 12 financial products with risk tier classifications |
| `data/loan_originations.csv` | Daily application volume, approvals, denials, funded amounts by region |
| `data/loan_performance.csv` | Monthly delinquency snapshots (30/60/90+ DPD) by vintage |
| `data/data_quality_metrics.csv` | Daily pipeline health: freshness, dbt tests, null rates, schema changes |

### Getting Started

1. Open your Snowflake trial account
2. Run the bootstrap SQL from the guide (creates role, warehouse, Git integration)
3. Create a **Git-enabled Workspace**: Projects → Workspaces → From Git repository → paste this repo URL
4. Open and run **`02_setup.sql`** from inside the workspace
5. Follow the rest of the step-by-step guide in **[HOL_GUIDE.md](HOL_GUIDE.md)**

### Prerequisites

- Snowflake trial account (provided by facilitator)
- ACCOUNTADMIN role access
- Chrome or Edge browser

### Duration

~1 hour
