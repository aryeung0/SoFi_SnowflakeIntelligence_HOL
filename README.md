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
| `backup_risk_data_model.yaml` | Semantic model backup (YAML) — use if you skip the UI-based semantic view creation |
| `data/products.csv` | 12 financial products with risk tier classifications |
| `data/loan_originations.csv` | Daily application volume, approvals, denials, funded amounts by region |
| `data/loan_performance.csv` | Monthly delinquency snapshots (30/60/90+ DPD) by vintage |
| `data/data_quality_metrics.csv` | Daily pipeline health: freshness, dbt tests, null rates, schema changes |

### Getting Started

| Step | What | How |
|------|------|-----|
| 1a | Bootstrap | Paste the bootstrap SQL into a fresh worksheet → Run All |
| 1b | Connect to Git | Projects → Workspaces → From Git repository → paste this repo URL |
| 1c | Setup & Load Data | Open **`02_setup.sql`** in the workspace → Run All (loads data from Git — no CSV uploads) |
| 2 | Semantic View | AI & ML → Analyst → Create new Semantic View (or upload `backup_risk_data_model.yaml` as backup) |
| 3 | Knowledge Extension | Marketplace → Get "Snowflake Documentation" → Grant privileges |
| 4 | Create Agent | AI & ML → Agents → Create agent with 3 tools |
| 5 | Try It Out | Ask questions at [ai.snowflake.com](https://ai.snowflake.com) |

Full step-by-step guide provided by facilitator.

### Prerequisites

- Snowflake trial account (provided by facilitator)
- ACCOUNTADMIN role access
- Chrome or Edge browser

### Duration

~1 hour
