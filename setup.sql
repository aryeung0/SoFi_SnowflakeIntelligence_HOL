-- ============================================================
-- Snowflake Intelligence HOL — Setup Script
-- SoFi Risk Data Team
-- ============================================================
--
-- Objects created:
--   Role:       snowflake_intelligence_admin
--   Warehouse:  sofi_wh_si
--   Database:   sofi_db_si (schema: financial)
--   Database:   snowflake_intelligence (schema: agents)
--   Tables:     products, loan_originations, loan_performance, data_quality_metrics
--   Stage:      semantic_models
--   Procedure:  send_email
--   Integration: email_integration
--
-- Data loading: CSV files are loaded via Snowsight UI after running this script.
-- ============================================================

use role accountadmin;

create or replace role snowflake_intelligence_admin;
grant create warehouse on account to role snowflake_intelligence_admin;
grant create database on account to role snowflake_intelligence_admin;
grant create integration on account to role snowflake_intelligence_admin;

set current_user = (select current_user());   
grant role snowflake_intelligence_admin to user identifier($current_user);
alter user set default_role = snowflake_intelligence_admin;
alter user set default_warehouse = sofi_wh_si;

use role snowflake_intelligence_admin;
create or replace database sofi_db_si;
create or replace schema financial;
create or replace warehouse sofi_wh_si with warehouse_size='large';

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
-- Stage for semantic model YAML
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

ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'AWS_US';

select 'Setup complete! Now load CSV data via Snowsight (see HOL guide Step 1).' as status;
