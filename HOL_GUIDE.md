# Getting Started with Snowflake Intelligence
## Hands-On Lab for SoFi Risk Data Team

**Duration:** ~1 hour  
**Audience:** Risk Data Team (RDT) & Business Stakeholders  
**Facilitator:** Arnold Yeung, Snowflake Solutions Engineer

---

## Overview

Snowflake Intelligence is an Enterprise AI Agent that lets anyone ask complex questions in natural language across your business data. It moves beyond the "what" to the critical "why" — providing an always-available thought partner.

This agent serves **two audiences**:

**For Business Stakeholders:**
- *"What's the trend in personal loan originations over the last 6 months?"*
- *"Which product has the highest 90+ day delinquency rate?"*
- *"How do charge-off rates compare across vintages for student loan refi?"*

**For the Risk Data Team:**
- *"Which tables had dbt test failures this week?"*
- *"Is the LOAN_PERFORMANCE table fresh? When was it last updated?"*
- *"Which tables have the highest null rates right now?"*

### What You Will Build

An Enterprise Intelligence Agent with 3 tools:

1. **Cortex Analyst** — queries structured data (loan originations, portfolio performance, data quality metrics) via natural language
2. **Snowflake Documentation (Knowledge Extension)** — searches official Snowflake docs for technical answers
3. **Custom Tool (Send Email)** — sends summary emails on demand

### Prerequisites

- Access to a Snowflake trial account (provided by Arnold)
- The trial account has ACCOUNTADMIN role access
- Chrome or Edge browser

---

## Step 1: Setup — Bootstrap, Connect to Git & Load Data

### 1a. Bootstrap (Run Once in a Fresh Account)

This creates the minimum objects needed before connecting to the Git repository.

1. Log into your Snowflake trial account at [app.snowflake.com](https://app.snowflake.com)
2. Click **+ → SQL Worksheet**
3. Copy and paste the contents below into the worksheet and **Run All**:

```sql
use role accountadmin;

create or replace role snowflake_intelligence_admin;
grant create warehouse on account to role snowflake_intelligence_admin;
grant create database on account to role snowflake_intelligence_admin;
grant create integration on account to role snowflake_intelligence_admin;

set current_user = (select current_user());
grant role snowflake_intelligence_admin to user identifier($current_user);
alter user set default_role = snowflake_intelligence_admin;

use role snowflake_intelligence_admin;
create or replace warehouse sofi_wh_si
  warehouse_size = 'small'
  auto_suspend = 1800
  auto_resume = true
  initially_suspended = true;
alter user set default_warehouse = sofi_wh_si;

use role accountadmin;

create or replace api integration git_api_integration
  api_provider = git_https_api
  api_allowed_prefixes = ('https://github.com/aryeung0')
  enabled = true;

grant usage on integration git_api_integration to role snowflake_intelligence_admin;

grant usage on database snowflake_intelligence to role snowflake_intelligence_admin;
grant usage on schema snowflake_intelligence.agents to role snowflake_intelligence_admin;
grant create agent on schema snowflake_intelligence.agents to role snowflake_intelligence_admin;
```

> This is also available as **`01_bootstrap.sql`** in the Git repo (for reference after connecting).

### 1b. Create a Git-Enabled Workspace

Now connect Snowflake to the HOL GitHub repository:

1. In the left sidebar, navigate to **Projects → Workspaces**
2. Click **+ → From Git repository**
3. **Repository URL:** `https://github.com/aryeung0/SoFi_SnowflakeIntelligence_HOL.git`
4. **API Integration:** Select **GIT_API_INTEGRATION**
5. **Authentication:** Select **Public repository**
6. Click **Create**

You should now see the repository files in your workspace, including `02_setup.sql`, `03_data/` folder, and `04_risk_data_model.yaml`.

## Step 2: Run the Setup Script

1. In the workspace file explorer, open **`02_setup.sql`**
2. **Run All** — this creates the database, tables, loads data from the Git repo, and sets up the email procedure

### What the setup creates:

| Object | Name | Purpose |
|--------|------|---------|
| Database | `SOFI_DB_SI` | Houses all risk data |
| Schema | `SOFI_DB_SI.FINANCIAL` | Contains tables and stages |
| Warehouse | `SOFI_WH_SI` | Compute for queries |
| Table | `PRODUCTS` | 12 financial products with risk tiers |
| Table | `LOAN_ORIGINATIONS` | Daily application, approval, denial, and funded amounts by region |
| Table | `LOAN_PERFORMANCE` | Monthly delinquency snapshots (30/60/90+ DPD) by vintage |
| Table | `DATA_QUALITY_METRICS` | Daily pipeline health: freshness, dbt test results, null rates |
| Stage | `SEMANTIC_MODELS` | Stores the semantic model YAML (backup) |
| Procedure | `SEND_EMAIL()` | Sends email via Snowflake notification |
| Git Repo | `SOFI_HOL_REPO` | Connected to GitHub for data files |

The last query in 02_setup.sql verifies data loaded correctly:

Expected output:

| TBL | ROW_COUNT |
|-----|------|
| PRODUCTS | 12 |
| LOAN_ORIGINATIONS | 17,527 |
| LOAN_PERFORMANCE | 900 |
| DATA_QUALITY_METRICS | 1,810 |

---

## Step 3: Configure Cortex Analyst (Structured Data)

Cortex Analyst enables the agent to query structured data by generating SQL. It uses a **semantic view** — a schema-level object that maps business concepts to your physical tables and columns. We'll create one using the AI-assisted generator in Snowsight.

### Create the Semantic View

1. Navigate to: **AI & ML → Analyst** (left menu)
2. Confirm role is set to **SNOWFLAKE_INTELLIGENCE_ADMIN**
3. Click **Create new** → **Create new Semantic View**
4. **Location:** Select **SOFI_DB_SI → FINANCIAL**
5. **Name:** `RISK_DATA_MODEL`
6. **Description:** Enter the following:

   ```
   Semantic model for SoFi Risk Data Team. Covers loan originations, portfolio performance,
   product dimensions, and data pipeline quality metrics. Used by business stakeholders for
   portfolio analytics and by the RDT team for pipeline health monitoring.
   ```

7. Click **Next**

### Add Context

8. Under **SQL Queries**, add these example question/SQL pairs to help the AI understand your data:

   | Question | SQL |
   |----------|-----|
   | What is the trend in personal loan originations? | `SELECT o.date, SUM(o.funded_amount) as total_funded FROM sofi_db_si.financial.loan_originations o JOIN sofi_db_si.financial.products p ON o.product_id = p.product_id WHERE p.category = 'Personal Loans' GROUP BY o.date ORDER BY o.date` |
   | Which product has the highest 90+ day delinquency rate? | `SELECT p.product_name, SUM(lp.dpd_90_plus) as total_90plus, SUM(lp.current_count + lp.dpd_30 + lp.dpd_60 + lp.dpd_90_plus) as total_loans FROM sofi_db_si.financial.loan_performance lp JOIN sofi_db_si.financial.products p ON lp.product_id = p.product_id GROUP BY p.product_name ORDER BY total_90plus DESC` |

> **Why this matters:** These SQL queries teach the AI-assisted generator how your tables join and what kinds of questions users will ask. This significantly improves the quality of auto-generated descriptions and relationships.

### Select Tables & Columns

9. Under **Select tables**, add all 4 tables from **SOFI_DB_SI.FINANCIAL**:
   - `PRODUCTS`
   - `LOAN_ORIGINATIONS`
   - `LOAN_PERFORMANCE`
   - `DATA_QUALITY_METRICS`

10. Click **Next**

11. Under **Select columns**, select **all columns** for each table (we're under the 50-column recommendation)

12. Check **Add sample values** ✅ — this helps Cortex Analyst understand your data values (e.g., region names, product categories, risk tiers)

13. Check **Add AI-generated descriptions** ✅ — the AI will generate business-friendly descriptions for each column based on names and sample values

14. Click **Create and save**

> The generator will take 1–2 minutes. You'll see a progress indicator showing the steps: extracting metadata, generating descriptions, identifying relationships, and creating verified query suggestions.

### Review & Enhance (Optional)

Once the semantic view is created, you can fine-tune it:

15. Click on the semantic view to open it
16. Under **Relationships**, verify that these relationships were auto-detected (add them if not):
    - `LOAN_ORIGINATIONS.PRODUCT_ID` → `PRODUCTS.PRODUCT_ID` (many-to-one)
    - `LOAN_PERFORMANCE.PRODUCT_ID` → `PRODUCTS.PRODUCT_ID` (many-to-one)

17. Under each logical table, review the **Synonyms** — add any missing ones:
    - LOAN_PERFORMANCE: `delinquency` → DPD columns, `exposure` → OUTSTANDING_BALANCE
    - DATA_QUALITY_METRICS: `staleness` → FRESHNESS_HOURS, `pipeline health` → dbt test columns

18. Click **Save**

### What does the semantic view cover?

Your `RISK_DATA_MODEL` semantic view maps 4 tables:

- **PRODUCTS** — 12 financial products across 4 categories (Personal Loans, Student Loan Refi, Home Loans, Credit Cards) with risk tier classifications
- **LOAN_ORIGINATIONS** — daily application volume, approvals, denials, and funded amounts by region
- **LOAN_PERFORMANCE** — monthly portfolio snapshots with delinquency buckets (30/60/90+ DPD) and charge-offs by vintage
- **DATA_QUALITY_METRICS** — daily pipeline health for 10 risk tables: freshness, dbt test results, null rates, schema changes

The AI-generated descriptions and sample values help Cortex Analyst understand risk terminology automatically.

### ⏱️ Backup Option (if short on time)

If you need to catch up, you can create the semantic view from a YAML file instead:

1. Navigate to: **AI & ML → Analyst**
2. Click **Create new** → **Upload YAML file**
3. Upload **`04_risk_data_model.yaml`** (provided with course materials)
4. Click **Convert and save**

This creates the same semantic view in one step, with all tables, relationships, and synonyms pre-configured.

---

## Step 4: Add Snowflake Documentation Knowledge Extension (Marketplace)

Cortex Knowledge Extensions (CKEs) are pre-built search services from the Snowflake Marketplace. The **Snowflake Documentation** CKE gives your agent access to the complete official Snowflake docs.

1. Navigate to **Data Products → Marketplace** (left menu)
2. Search for **"Snowflake Documentation"**
3. Click **Get** on the Snowflake Documentation listing
4. In the dialog:
   - Note the database name: **`SNOWFLAKE_DOCUMENTATION`**
   - Grant access to role: **PUBLIC** (or SNOWFLAKE_INTELLIGENCE_ADMIN)
   - Click **Get**, then **Done**
5. Grant the agent role access — run in a SQL worksheet:

```sql
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE_DOCUMENTATION TO ROLE SNOWFLAKE_INTELLIGENCE_ADMIN;
```

> **Why this matters:** Your team can ask the agent Snowflake-specific questions alongside business data queries — no need to switch to docs.snowflake.com. Useful for questions about dynamic tables, dbt integration, semantic views, data metric functions, and more.

---

## Step 5: Create the Agent

1. Navigate to: **AI & ML → Agents** (left menu)
2. Click **Create agent** (top right)
3. Configure:
   - **Schema:** SNOWFLAKE_INTELLIGENCE.AGENTS
   - **Agent object name:** `RDT_AI`
   - **Display name:** `Risk Data // AI`
4. Select the newly created **RDT_AI** agent and click **Edit**

### Add Example Questions

Add the following starter questions:

```
What is the trend in personal loan originations over the last 6 months?
Which product has the highest 90+ day delinquency rate?
Which tables had dbt test failures in the last 30 days?
Are there any null values in the loan originations region column?
```

### Add Tools

#### Tool 1: Cortex Analyst (Structured Data)
- Click **+ Add** under Cortex Analyst
- **Semantic view:** SOFI_DB_SI.FINANCIAL → `RISK_DATA_MODEL`
- **Name:** `Risk_Data_Model`
- **Description:** The Risk Data Model provides a complete view of SoFi's lending portfolio including loan origination volumes, approval rates, and funded amounts by region; portfolio performance with delinquency buckets and charge-offs by vintage; product catalog with risk tier classifications; and daily data quality metrics tracking pipeline freshness, dbt test results, null rates, and schema changes across key risk tables.

#### Tool 2: Cortex Search — Snowflake Documentation (Knowledge Extension)
- Click **+ Add** under Cortex Search Services
- **Database:** SNOWFLAKE_DOCUMENTATION
- **Schema:** SHARED
- **Search service:** `CKE_SNOWFLAKE_DOCS_SERVICE`
- **ID column:** SOURCE_URL
- **Title column:** DOCUMENT_TITLE
- **Name:** `Snowflake_Docs`

#### Tool 3: Custom Tool (Send Email)
- Click **+ Add** under Custom tools
- **Resource type:** procedure
- **Database & Schema:** SOFI_DB_SI.FINANCIAL
- **Custom tool identifier:** SOFI_DB_SI.FINANCIAL.SEND_EMAIL()
- **Name:** `Send_Email`
- **Warehouse:** SOFI_WH_SI

**Parameter: `body`**
> Description: Use HTML-Syntax for this. If the content you get is in markdown, translate it to HTML. If body is not provided, summarize the last question and use that as content for the email.

**Parameter: `recipient_email`**
> Description: If the email is not provided, send it to the current user's email address.

**Parameter: `subject`**
> Description: If the subject is not provided, use "Snowflake Intelligence".

### Orchestration Instructions

Add this instruction:

```
Whenever you can answer visually with a chart, always choose to generate a chart even if the user didn't specify to.
```

### Access Control

- Grant access to: **SNOWFLAKE_INTELLIGENCE_ADMIN**

> Click **Save** in the top right corner.

---

## Step 6: Try It Out!

Open [Snowflake Intelligence](https://ai.snowflake.com) and ensure:
- Role: **SNOWFLAKE_INTELLIGENCE_ADMIN**
- Warehouse: **SOFI_WH_SI**
- Agent: **Risk Data // AI**

### Q1: Portfolio Trends (Business Stakeholder)
> **"What is the trend in personal loan originations over the last 6 months?"**

The agent uses Cortex Analyst to generate SQL against LOAN_ORIGINATIONS joined with PRODUCTS, then visualizes the results as a chart. You should see a dip in Q1 2025 for personal loans.

### Q2: Risk Analysis (Business Stakeholder)
> **"Which product has the highest 90+ day delinquency rate?"**

The agent queries LOAN_PERFORMANCE, calculates delinquency rates, and surfaces that subprime products have the highest 90+ DPD rates. Note: some Credit Card rows in the June snapshot have impossible DPD values (counts exceeding total loans) — this is a known data quality issue in the dataset.

### Q3: Data Quality — Pipeline Health (RDT Internal)
> **"Which tables had dbt test failures in the last 30 days and what are their null rates?"**

The agent queries DATA_QUALITY_METRICS and surfaces several issues:
- **COLLATERAL_VALUATIONS** has chronic test failures (~35% of days)
- **BORROWER_PROFILES** had a null rate spike to 8-10% starting May 20 (after a schema change), still elevated in June
- **LOAN_ORIGINATIONS** had dbt failures on Feb 15 (duplicate rows from a pipeline re-run) and elevated null rates in March-April
- **LOAN_PERFORMANCE** had null rate spikes in April and test failures in June

### Q4: Data Quality — Digging Into the Data (RDT Internal)
> **"Are there any null values in the LOAN_ORIGINATIONS region column? Show me when they occurred."**

The agent queries the actual LOAN_ORIGINATIONS table and finds ~293 rows with null regions, concentrated in March-April 2025. This is a real data defect — the agent can surface it directly from the source data, not just the metrics table.

> **Follow-up:** *"Are there any rows in LOAN_PERFORMANCE where the DPD counts exceed the total number of loans?"*

The agent finds ~8 rows in the June 2025 snapshot for Credit Cards where DPD_30 and DPD_60 exceed total loans — an impossible condition indicating a data pipeline bug.

### Q5: Snowflake Documentation (Knowledge Extension)
> **"How do I create a dynamic table in Snowflake?"**

The agent uses the Snowflake Documentation CKE to retrieve the relevant docs, provides a clear answer with SQL syntax, and includes a citation link back to docs.snowflake.com.

> **Follow-up:** *"What are data metric functions and how can I use them to monitor data quality automatically?"*

This ties into the data quality theme — DMFs can automate the kind of monitoring you just did manually.

### Q6: Take Action
> **"Send me an email summarizing the data quality issues we found today."**

The agent compiles the findings from previous questions, then calls the SEND_EMAIL procedure to deliver an HTML summary to your inbox.

### More Questions to Try

**Business Stakeholder questions:**
- *"How does the approval rate compare across regions for home loans?"*
- *"What are the total funded amounts by product category this year?"*
- *"How do charge-off rates compare across vintages for student loan refi?"*
- *"Which region has the highest denial rate?"*

**Data Quality deep-dives:**
- *"Are there any negative funded amounts in the loan originations table?"* (finds 7 rows in May 2025)
- *"Are there duplicate rows in loan originations on February 15?"* (finds 7 dupes from pipeline re-run)
- *"Show me rows in loan performance where outstanding balance is zero but delinquency counts are not."* (finds 16 stale records in Feb 2025, 2022 vintages)
- *"When did the LOAN_PERFORMANCE table go stale in May? How long was it down?"* (72+ hours, May 12-14)

**RDT Pipeline Monitoring:**
- *"Is the LOAN_PERFORMANCE table fresh? When was it last updated?"*
- *"Which tables have the highest null rates right now?"*
- *"Were there any schema changes detected in the last 30 days?"*
- *"Show me the freshness trend for CREDIT_DECISIONS over the last month."*

**Snowflake Documentation questions:**
- *"What is a semantic view in Snowflake and how do I create one?"*
- *"What are the differences between dynamic tables and streams + tasks?"*
- *"How do I set up row access policies in Snowflake?"*

---

## Connecting This to Your World

### How This Relates to RDT's Goals

| HOL Concept | RDT Application |
|-------------|-----------------|
| Semantic view (AI-generated) | Build semantic views over your TDM tables for self-service analytics |
| Git integration (Workspaces) | Connect your dbt repos and SQL scripts directly to Snowflake for version-controlled development |
| Cortex Analyst | Enable Tableau users and leadership to ask questions in natural language |
| Data Quality Metrics table | Monitor pipeline health, dbt test results, and freshness across your ~550 datasets |
| Knowledge Extensions (CKE) | Attach Snowflake docs, regulatory guides, or internal wikis to your agents |
| Custom tools | Automate email alerts, trigger dbt runs, or update Airtable records |
| Agent orchestration | Create domain-specific agents for different stakeholder groups |

### Next Steps After This HOL
1. **Semantic Views:** Build a semantic layer over your actual RDT tables (the ~550 datasets)
2. **Data Quality Agent:** Create an agent that reasons over your live dbt test results and Monte Carlo alerts
3. **Data Metric Functions (DMFs):** Automate data quality monitoring natively in Snowflake — define metrics like null rate, freshness, and uniqueness that run on a schedule and feed directly into your agent
4. **Streamlit + Intelligence:** Combine Streamlit UIs for fraud investigation with Intelligence agents for ad-hoc analysis
5. **Cortex Code:** Use CoCo to help optimize those 49 dbt models with 750+ lines of code

---

## Cleanup

To remove all objects created during this lab:

```sql
use role snowflake_intelligence_admin;
drop database if exists sofi_db_si;
drop database if exists snowflake_intelligence;
drop warehouse if exists sofi_wh_si;

use role accountadmin;
drop role if exists snowflake_intelligence_admin;
```

---

## Resources

- [Snowflake Intelligence Documentation](https://docs.snowflake.com/user-guide/snowflake-cortex/snowflake-intelligence)
- [Cortex Analyst Documentation](https://docs.snowflake.com/user-guide/snowflake-cortex/cortex-analyst)
- [Semantic Views](https://docs.snowflake.com/en/user-guide/views-semantic/overview)
- [Semantic Model Specification](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst/semantic-model-spec)
- [Cortex Knowledge Extensions](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-knowledge-extensions/cke-overview)
- [Git Integration in Snowflake](https://docs.snowflake.com/en/developer-guide/git/git-overview)
- [Data Metric Functions](https://docs.snowflake.com/en/user-guide/data-quality-intro)
