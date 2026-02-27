-- ============================================================================
-- PHASE 9: AUDIT LAYER
-- Healthcare Enterprise Data Hub
-- ============================================================================
-- Objectives: Create audit trail views for compliance
-- Role Required: ACCOUNTADMIN
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE AUDIT_DB;
USE SCHEMA AUDIT_SCHEMA;

-- ============================================================================
-- 9.1 LOGIN HISTORY AUDIT VIEW
-- Tracks all authentication events
-- ============================================================================
CREATE OR REPLACE VIEW V_AUDIT_LOGIN_HISTORY AS
SELECT
    EVENT_ID,
    EVENT_TIMESTAMP,
    USER_NAME,
    CLIENT_IP,
    REPORTED_CLIENT_TYPE,
    REPORTED_CLIENT_VERSION,
    FIRST_AUTHENTICATION_FACTOR,
    SECOND_AUTHENTICATION_FACTOR,
    IS_SUCCESS,
    ERROR_CODE,
    ERROR_MESSAGE,
    CONNECTION_REASON
FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
ORDER BY EVENT_TIMESTAMP DESC;

-- ============================================================================
-- 9.2 ROLE GRANTS AUDIT VIEW
-- Tracks privilege grants to roles
-- ============================================================================
CREATE OR REPLACE VIEW V_AUDIT_ROLE_GRANTS AS
SELECT
    CREATED_ON,
    MODIFIED_ON,
    PRIVILEGE,
    GRANTED_ON,
    NAME AS OBJECT_NAME,
    TABLE_CATALOG AS DATABASE_NAME,
    TABLE_SCHEMA AS SCHEMA_NAME,
    GRANTED_TO,
    GRANTEE_NAME,
    GRANT_OPTION,
    GRANTED_BY,
    DELETED_ON
FROM SNOWFLAKE.ACCOUNT_USAGE.GRANTS_TO_ROLES
ORDER BY CREATED_ON DESC;

-- ============================================================================
-- 9.3 USER GRANTS AUDIT VIEW
-- Tracks role assignments to users
-- ============================================================================
CREATE OR REPLACE VIEW V_AUDIT_USER_GRANTS AS
SELECT
    CREATED_ON,
    DELETED_ON,
    ROLE,
    GRANTED_TO,
    GRANTEE_NAME,
    GRANTED_BY
FROM SNOWFLAKE.ACCOUNT_USAGE.GRANTS_TO_USERS
ORDER BY CREATED_ON DESC;

-- ============================================================================
-- 9.4 USER MANAGEMENT AUDIT VIEW
-- Tracks user account changes
-- ============================================================================
CREATE OR REPLACE VIEW V_AUDIT_USERS AS
SELECT
    NAME AS USER_NAME,
    CREATED_ON,
    DELETED_ON,
    LOGIN_NAME,
    DISPLAY_NAME,
    EMAIL,
    DEFAULT_ROLE,
    DEFAULT_WAREHOUSE,
    DEFAULT_NAMESPACE,
    DISABLED,
    LOCKED_UNTIL_TIME,
    HAS_PASSWORD,
    HAS_RSA_PUBLIC_KEY,
    LAST_SUCCESS_LOGIN,
    EXPIRES_AT,
    COMMENT
FROM SNOWFLAKE.ACCOUNT_USAGE.USERS
ORDER BY CREATED_ON DESC;

-- ============================================================================
-- 9.5 ACCESS HISTORY AUDIT VIEW
-- Tracks data access patterns
-- ============================================================================
CREATE OR REPLACE VIEW V_AUDIT_ACCESS_HISTORY AS
SELECT
    QUERY_ID,
    QUERY_START_TIME,
    USER_NAME,
    DIRECT_OBJECTS_ACCESSED,
    BASE_OBJECTS_ACCESSED,
    OBJECTS_MODIFIED,
    OBJECT_MODIFIED_BY_DDL,
    POLICIES_REFERENCED
FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY
WHERE QUERY_START_TIME >= DATEADD(DAY, -30, CURRENT_DATE)
ORDER BY QUERY_START_TIME DESC;

-- ============================================================================
-- 9.6 COPY/LOAD HISTORY AUDIT VIEW
-- Tracks data ingestion operations
-- ============================================================================
CREATE OR REPLACE VIEW V_AUDIT_COPY_HISTORY AS
SELECT
    FILE_NAME,
    STAGE_LOCATION,
    LAST_LOAD_TIME,
    ROW_COUNT,
    ROW_PARSED,
    FILE_SIZE,
    FIRST_ERROR_MESSAGE,
    FIRST_ERROR_LINE_NUMBER,
    FIRST_ERROR_CHARACTER_POS,
    FIRST_ERROR_COLUMN_NAME,
    ERROR_COUNT,
    ERROR_LIMIT,
    STATUS,
    TABLE_ID,
    TABLE_NAME,
    TABLE_SCHEMA_ID,
    TABLE_SCHEMA_NAME,
    TABLE_CATALOG_ID,
    TABLE_CATALOG_NAME,
    PIPE_ID
FROM SNOWFLAKE.ACCOUNT_USAGE.COPY_HISTORY
WHERE LAST_LOAD_TIME >= DATEADD(DAY, -30, CURRENT_DATE)
ORDER BY LAST_LOAD_TIME DESC;

-- ============================================================================
-- 9.7 QUERY AUDIT VIEW
-- Comprehensive query tracking
-- ============================================================================
CREATE OR REPLACE VIEW V_AUDIT_QUERIES AS
SELECT
    QUERY_ID,
    QUERY_TEXT,
    DATABASE_NAME,
    SCHEMA_NAME,
    QUERY_TYPE,
    SESSION_ID,
    USER_NAME,
    ROLE_NAME,
    WAREHOUSE_NAME,
    WAREHOUSE_SIZE,
    EXECUTION_STATUS,
    ERROR_CODE,
    ERROR_MESSAGE,
    START_TIME,
    END_TIME,
    TOTAL_ELAPSED_TIME,
    BYTES_SCANNED,
    ROWS_PRODUCED,
    ROWS_INSERTED,
    ROWS_UPDATED,
    ROWS_DELETED
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE START_TIME >= DATEADD(DAY, -30, CURRENT_DATE)
ORDER BY START_TIME DESC;

-- ============================================================================
-- 9.8 SECURITY INTEGRATION AUDIT VIEW
-- Tracks security integration changes
-- ============================================================================
CREATE OR REPLACE VIEW V_AUDIT_SECURITY_INTEGRATIONS AS
SELECT
    INTEGRATION_NAME,
    CREATED,
    INTEGRATION_TYPE,
    ENABLED,
    COMMENT
FROM SNOWFLAKE.ACCOUNT_USAGE.SECURITY_INTEGRATIONS
ORDER BY CREATED DESC;

-- ============================================================================
-- 9.9 POLICY REFERENCE AUDIT VIEW
-- Tracks policy applications
-- ============================================================================
CREATE OR REPLACE VIEW V_AUDIT_POLICY_REFERENCES AS
SELECT
    POLICY_DB,
    POLICY_SCHEMA,
    POLICY_NAME,
    POLICY_KIND,
    REF_DATABASE_NAME,
    REF_SCHEMA_NAME,
    REF_ENTITY_NAME,
    REF_ENTITY_DOMAIN,
    REF_COLUMN_NAME,
    REF_ARG_COLUMN_NAMES
FROM SNOWFLAKE.ACCOUNT_USAGE.POLICY_REFERENCES
ORDER BY POLICY_NAME;

-- ============================================================================
-- 9.10 SESSIONS AUDIT VIEW
-- Tracks user sessions
-- ============================================================================
CREATE OR REPLACE VIEW V_AUDIT_SESSIONS AS
SELECT
    SESSION_ID,
    CREATED_ON,
    USER_NAME,
    AUTHENTICATION_METHOD,
    LOGIN_EVENT_ID,
    CLIENT_APPLICATION_ID,
    CLIENT_ENVIRONMENT
FROM SNOWFLAKE.ACCOUNT_USAGE.SESSIONS
WHERE CREATED_ON >= DATEADD(DAY, -7, CURRENT_DATE)
ORDER BY CREATED_ON DESC;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
SHOW VIEWS IN SCHEMA AUDIT_DB.AUDIT_SCHEMA;

-- Test views
SELECT COUNT(*) AS LOGIN_EVENTS FROM V_AUDIT_LOGIN_HISTORY;
SELECT COUNT(*) AS GRANT_EVENTS FROM V_AUDIT_ROLE_GRANTS;

-- ============================================================================
-- PHASE 9 COMPLETE
-- Audit Views Created: 10
--   - V_AUDIT_LOGIN_HISTORY
--   - V_AUDIT_ROLE_GRANTS
--   - V_AUDIT_USER_GRANTS
--   - V_AUDIT_USERS
--   - V_AUDIT_ACCESS_HISTORY
--   - V_AUDIT_COPY_HISTORY
--   - V_AUDIT_QUERIES
--   - V_AUDIT_SECURITY_INTEGRATIONS
--   - V_AUDIT_POLICY_REFERENCES
--   - V_AUDIT_SESSIONS
-- ============================================================================
