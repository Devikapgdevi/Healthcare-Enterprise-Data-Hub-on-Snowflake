-- =====================================================
-- PHASE 9: AUDIT LAYER (Snowflake-safe)
-- =====================================================

USE ROLE ACCOUNTADMIN;

-- 1️⃣ Create Audit Database and Schema
CREATE OR REPLACE DATABASE AUDIT_DB;
USE DATABASE AUDIT_DB;

CREATE OR REPLACE SCHEMA AUDIT_SCHEMA;
USE SCHEMA AUDIT_SCHEMA;

-- 2️⃣ Create Audit Views

-- Login History
CREATE OR REPLACE VIEW LOGIN_HISTORY_AUDIT AS
SELECT *
FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY;

-- Role Changes / Grants to Roles
CREATE OR REPLACE VIEW ROLE_CHANGES_AUDIT AS
SELECT *
FROM SNOWFLAKE.ACCOUNT_USAGE.GRANTS_TO_ROLES;

-- User Creation
CREATE OR REPLACE VIEW USER_CREATION_AUDIT AS
SELECT *
FROM SNOWFLAKE.ACCOUNT_USAGE.USERS;

-- Grant History / Grants to Users
CREATE OR REPLACE VIEW GRANT_HISTORY_AUDIT AS
SELECT *
FROM SNOWFLAKE.ACCOUNT_USAGE.GRANTS_TO_USERS;

-- 3️⃣ Verify Created Views
SHOW VIEWS IN SCHEMA AUDIT_DB.AUDIT_SCHEMA;

-- =====================================================
-- ✅ Phase 9 Audit Layer Complete (Snowflake-safe)
-- =====================================================
