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
| `setup.sql` | Creates role, database, warehouse, tables, and email procedure |
| `risk_data_model.yaml` | Semantic model backup (YAML) — use if you skip the UI-based semantic view creation |
| `data/products.csv` | 12 financial products with risk tier classifications |
| `data/loan_originations.csv` | Daily application volume, approvals, denials, funded amounts by region |
| `data/loan_performance.csv` | Monthly delinquency snapshots (30/60/90+ DPD) by vintage |
| `data/data_quality_metrics.csv` | Daily pipeline health: freshness, dbt tests, null rates, schema changes |

### Getting Started

1. Download all files (click **Code → Download ZIP**)
2. Open your Snowflake trial account
3. Follow the step-by-step guide in **[HOL_GUIDE.md](HOL_GUIDE.md)**

### Prerequisites

- Snowflake trial account (provided by facilitator)
- ACCOUNTADMIN role access
- Chrome or Edge browser

### Duration

~1 hour
