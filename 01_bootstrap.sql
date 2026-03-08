-- ============================================================
-- Snowflake Intelligence HOL — Bootstrap Script
-- SoFi Risk Data Team
-- ============================================================
--
-- Run this FIRST in a fresh SQL worksheet before creating
-- the Git workspace. This creates the minimum objects needed
-- to connect to the HOL GitHub repository.
--
-- After running this script:
--   1. Go to Projects → Workspaces
--   2. Select "From Git repository"
--   3. Paste the repo URL and select the API integration
--   4. Then run 02_setup.sql from inside the workspace
-- ============================================================

use role accountadmin;

-- Role
create or replace role snowflake_intelligence_admin;
grant create warehouse on account to role snowflake_intelligence_admin;
grant create database on account to role snowflake_intelligence_admin;
grant create integration on account to role snowflake_intelligence_admin;

set current_user = (select current_user());
grant role snowflake_intelligence_admin to user identifier($current_user);
alter user set default_role = snowflake_intelligence_admin;

-- Warehouse (needed for Git operations)
use role snowflake_intelligence_admin;
create or replace warehouse sofi_wh_si with warehouse_size='large';
alter user set default_warehouse = sofi_wh_si;

-- API integration for Git (requires ACCOUNTADMIN)
use role accountadmin;

create or replace api integration git_api_integration
  api_provider = git_https_api
  api_allowed_prefixes = ('https://github.com/aryeung0')
  enabled = true;

grant usage on integration git_api_integration to role snowflake_intelligence_admin;

-- Cross-region inference
alter account set cortex_enabled_cross_region = 'AWS_US';

select 'Bootstrap complete! Now create a Git workspace (see HOL guide Step 1b).' as status;
