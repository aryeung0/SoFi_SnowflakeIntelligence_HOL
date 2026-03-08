-- ============================================================
-- Snowflake Intelligence HOL — Setup Script
-- SoFi Risk Data Team
-- ============================================================
--
-- Run this from INSIDE the Git-enabled workspace.
-- Prerequisite: 01_bootstrap.sql has already been run.
--
-- Objects created:
--   Database:   sofi_db_si (schema: financial)
--   Database:   snowflake_intelligence (schema: agents)
--   Tables:     products, loan_originations, loan_performance, data_quality_metrics
--   Stage:      semantic_models
--   Procedure:  send_email
--   Integration: email_integration
--
-- Data is loaded from the Git repository stage (no CSV upload needed).
-- ============================================================

use role snowflake_intelligence_admin;

-- ============================================================
-- Database & Schema
-- ============================================================

create or replace database sofi_db_si;
create or replace schema financial;

create database if not exists snowflake_intelligence;
create schema if not exists snowflake_intelligence.agents;

grant create agent on schema snowflake_intelligence.agents to role snowflake_intelligence_admin;
grant create semantic view on schema sofi_db_si.financial to role snowflake_intelligence_admin;

use database sofi_db_si;
use schema financial;
use warehouse sofi_wh_si;

-- ============================================================
-- Tables
-- ============================================================

create or replace table products (
  product_id number(38,0),
  product_name varchar,
  category varchar,
  risk_tier varchar,
  launch_date date
);

create or replace table loan_originations (
  date date,
  region varchar,
  product_id number(38,0),
  applications number(38,0),
  approvals number(38,0),
  denials number(38,0),
  funded_amount number(38,2)
);

create or replace table loan_performance (
  snapshot_date date,
  product_id number(38,0),
  vintage varchar,
  outstanding_balance number(38,0),
  current_count number(38,0),
  dpd_30 number(38,0),
  dpd_60 number(38,0),
  dpd_90_plus number(38,0),
  chargeoff_amount number(38,2)
);

create or replace table data_quality_metrics (
  date date,
  table_name varchar,
  row_count number(38,0),
  last_updated_at timestamp,
  freshness_hours number(38,1),
  dbt_tests_passed number(38,0),
  dbt_tests_failed number(38,0),
  null_rate_pct number(38,2),
  schema_changes number(38,0)
);

-- ============================================================
-- Load data from Git repository
-- ============================================================

create or replace file format csv_format
  type = csv
  skip_header = 1
  field_optionally_enclosed_by = '"';

create or replace git repository sofi_db_si.financial.sofi_hol_repo
  origin = 'https://github.com/aryeung0/SoFi_SnowflakeIntelligence_HOL.git'
  api_integration = git_api_integration;

alter git repository sofi_db_si.financial.sofi_hol_repo fetch;

copy into products
  from @sofi_db_si.financial.sofi_hol_repo/branches/main/data/products.csv
  file_format = csv_format;

copy into loan_originations
  from @sofi_db_si.financial.sofi_hol_repo/branches/main/data/loan_originations.csv
  file_format = csv_format;

copy into loan_performance
  from @sofi_db_si.financial.sofi_hol_repo/branches/main/data/loan_performance.csv
  file_format = csv_format;

copy into data_quality_metrics
  from @sofi_db_si.financial.sofi_hol_repo/branches/main/data/data_quality_metrics.csv
  file_format = csv_format;

-- ============================================================
-- Verify data loaded
-- ============================================================

select 'PRODUCTS' as tbl, count(*) as rows from products
union all
select 'LOAN_ORIGINATIONS', count(*) from loan_originations
union all
select 'LOAN_PERFORMANCE', count(*) from loan_performance
union all
select 'DATA_QUALITY_METRICS', count(*) from data_quality_metrics;

-- ============================================================
-- Stage for semantic model YAML (backup)
-- ============================================================

create or replace stage semantic_models encryption = (type = 'snowflake_sse') directory = ( enable = true );

-- ============================================================
-- Email notification integration & stored procedure
-- ============================================================

create or replace notification integration email_integration
  type=email
  enabled=true
  default_subject = 'snowflake intelligence';

create or replace procedure send_email(
    recipient_email varchar,
    subject varchar,
    body varchar
)
returns varchar
language python
runtime_version = '3.12'
packages = ('snowflake-snowpark-python')
handler = 'send_email'
as
$$
def send_email(session, recipient_email, subject, body):
    try:
        escaped_body = body.replace("'", "''")
        
        session.sql(f"""
            CALL SYSTEM$SEND_EMAIL(
                'email_integration',
                '{recipient_email}',
                '{subject}',
                '{escaped_body}',
                'text/html'
            )
        """).collect()
        
        return "Email sent successfully"
    except Exception as e:
        return f"Error sending email: {str(e)}"
$$;

select 'Setup complete! All data loaded from Git repository.' as status;
