-- ============================================================================
-- ENTERPRISE HEALTHCARE DATA PLATFORM - PHASE 2: RBAC HIERARCHY
-- ============================================================================
-- File: 03_rbac_hierarchy.sql
-- Purpose: Role-Based Access Control with enterprise hierarchy
-- Version: 2.0.0
-- Phase: 2
-- Dependencies: 02_security_foundation.sql
-- ============================================================================

!SET variable_substitution=true;

USE ROLE ACCOUNTADMIN;

-- Initialize deployment context
SET DEPLOYMENT_ID = (SELECT UUID_STRING());
SET ENV = COALESCE($ENV, 'DEV');
SET DB_PREFIX = (SELECT CASE $ENV WHEN 'DEV' THEN 'DEV_' WHEN 'QA' THEN 'QA_' ELSE '' END);

CALL OPS_DB.DEPLOYMENT.SP_LOG_DEPLOYMENT_START(
    $DEPLOYMENT_ID, $ENV, '03_rbac_hierarchy.sql', 2, $GIT_COMMIT, $GIT_BRANCH
);

-- ============================================================================
-- RBAC HIERARCHY DESIGN
-- ============================================================================
/*
ROLE HIERARCHY (Least Privilege Principle):

ACCOUNTADMIN (Snowflake Built-in)
    │
    └── {ENV}_HC_PLATFORM_ADMIN
            │
            ├── {ENV}_HC_SECURITY_ADMIN
            │       └── (Manages policies, governance)
            │
            ├── {ENV}_HC_DATA_ENGINEER
            │       │
            │       └── {ENV}_HC_DATA_ANALYST
            │               │
            │               └── {ENV}_HC_VIEWER
            │
            └── {ENV}_HC_DATA_SCIENTIST
                    └── (ML/AI workloads)

SERVICE ROLES (Non-Human):
    - {ENV}_HC_SVC_ETL        : ETL pipeline execution
    - {ENV}_HC_SVC_ANALYTICS  : BI tool connections
    - {ENV}_HC_SVC_ML         : ML pipeline execution
*/

-- ============================================================================
-- STEP 1: CREATE FUNCTIONAL ROLES
-- ============================================================================

SET STEP_START = (SELECT CURRENT_TIMESTAMP());

-- Platform Administrator (Top of custom hierarchy)
CREATE ROLE IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'HC_PLATFORM_ADMIN')
    COMMENT = 'Healthcare Platform Administrator - Full platform access';

-- Security Administrator
CREATE ROLE IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'HC_SECURITY_ADMIN')
    COMMENT = 'Security Administrator - Manages policies and governance';

-- Data Engineer
CREATE ROLE IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'HC_DATA_ENGINEER')
    COMMENT = 'Data Engineer - ETL, data pipeline development';

-- Data Analyst
CREATE ROLE IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'HC_DATA_ANALYST')
    COMMENT = 'Data Analyst - Analytics and reporting';

-- Data Scientist
CREATE ROLE IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'HC_DATA_SCIENTIST')
    COMMENT = 'Data Scientist - ML/AI development';

-- Viewer (Read-only)
CREATE ROLE IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'HC_VIEWER')
    COMMENT = 'Viewer - Read-only access to analytics';

CALL OPS_DB.DEPLOYMENT.SP_LOG_STEP($DEPLOYMENT_ID, 1, 'Created functional roles', 'SUCCESS',
    DATEDIFF('MILLISECOND', $STEP_START, CURRENT_TIMESTAMP()));

-- ============================================================================
-- STEP 2: CREATE SERVICE ACCOUNT ROLES
-- ============================================================================

SET STEP_START = (SELECT CURRENT_TIMESTAMP());

-- ETL Service Role
CREATE ROLE IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'HC_SVC_ETL')
    COMMENT = 'Service Role - ETL pipeline execution (non-human)';

-- Analytics Service Role
CREATE ROLE IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'HC_SVC_ANALYTICS')
    COMMENT = 'Service Role - BI tool connections (non-human)';

-- ML Service Role
CREATE ROLE IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'HC_SVC_ML')
    COMMENT = 'Service Role - ML pipeline execution (non-human)';

CALL OPS_DB.DEPLOYMENT.SP_LOG_STEP($DEPLOYMENT_ID, 2, 'Created service account roles', 'SUCCESS',
    DATEDIFF('MILLISECOND', $STEP_START, CURRENT_TIMESTAMP()));

-- ============================================================================
-- STEP 3: ESTABLISH ROLE HIERARCHY (Idempotent)
-- ============================================================================

SET STEP_START = (SELECT CURRENT_TIMESTAMP());

-- Grant hierarchy (child TO parent means parent inherits child's privileges)
-- Platform Admin inherits all functional roles
GRANT ROLE IDENTIFIER($DB_PREFIX || 'HC_PLATFORM_ADMIN') TO ROLE ACCOUNTADMIN;

-- Security Admin under Platform Admin
GRANT ROLE IDENTIFIER($DB_PREFIX || 'HC_SECURITY_ADMIN') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_PLATFORM_ADMIN');

-- Data Engineer under Platform Admin
GRANT ROLE IDENTIFIER($DB_PREFIX || 'HC_DATA_ENGINEER') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_PLATFORM_ADMIN');

-- Data Scientist under Platform Admin
GRANT ROLE IDENTIFIER($DB_PREFIX || 'HC_DATA_SCIENTIST') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_PLATFORM_ADMIN');

-- Data Analyst under Data Engineer
GRANT ROLE IDENTIFIER($DB_PREFIX || 'HC_DATA_ANALYST') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_DATA_ENGINEER');

-- Viewer under Data Analyst
GRANT ROLE IDENTIFIER($DB_PREFIX || 'HC_VIEWER') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_DATA_ANALYST');

-- Service roles inherit from functional roles
GRANT ROLE IDENTIFIER($DB_PREFIX || 'HC_SVC_ETL') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_DATA_ENGINEER');

GRANT ROLE IDENTIFIER($DB_PREFIX || 'HC_SVC_ANALYTICS') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_DATA_ANALYST');

GRANT ROLE IDENTIFIER($DB_PREFIX || 'HC_SVC_ML') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_DATA_SCIENTIST');

CALL OPS_DB.DEPLOYMENT.SP_LOG_STEP($DEPLOYMENT_ID, 3, 'Established role hierarchy', 'SUCCESS',
    DATEDIFF('MILLISECOND', $STEP_START, CURRENT_TIMESTAMP()));

-- ============================================================================
-- STEP 4: GRANT SECURITY DB ACCESS
-- ============================================================================

SET STEP_START = (SELECT CURRENT_TIMESTAMP());

-- Security Admin gets full access to security DB
GRANT USAGE ON DATABASE IDENTIFIER($DB_PREFIX || 'SECURITY_DB') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_SECURITY_ADMIN');
GRANT USAGE ON ALL SCHEMAS IN DATABASE IDENTIFIER($DB_PREFIX || 'SECURITY_DB') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_SECURITY_ADMIN');
GRANT ALL PRIVILEGES ON ALL TABLES IN DATABASE IDENTIFIER($DB_PREFIX || 'SECURITY_DB') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_SECURITY_ADMIN');
GRANT CREATE MASKING POLICY ON SCHEMA IDENTIFIER($DB_PREFIX || 'SECURITY_DB.GOVERNANCE') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_SECURITY_ADMIN');
GRANT CREATE ROW ACCESS POLICY ON SCHEMA IDENTIFIER($DB_PREFIX || 'SECURITY_DB.GOVERNANCE') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_SECURITY_ADMIN');
GRANT CREATE TAG ON SCHEMA IDENTIFIER($DB_PREFIX || 'SECURITY_DB.GOVERNANCE') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_SECURITY_ADMIN');

-- Platform Admin inherits security admin
GRANT USAGE ON DATABASE IDENTIFIER($DB_PREFIX || 'SECURITY_DB') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_PLATFORM_ADMIN');

CALL OPS_DB.DEPLOYMENT.SP_LOG_STEP($DEPLOYMENT_ID, 4, 'Granted security DB access', 'SUCCESS',
    DATEDIFF('MILLISECOND', $STEP_START, CURRENT_TIMESTAMP()));

-- ============================================================================
-- STEP 5: GRANT OPS DB ACCESS (Monitoring)
-- ============================================================================

SET STEP_START = (SELECT CURRENT_TIMESTAMP());

-- All roles get read access to deployment logs
GRANT USAGE ON DATABASE OPS_DB TO ROLE IDENTIFIER($DB_PREFIX || 'HC_PLATFORM_ADMIN');
GRANT USAGE ON SCHEMA OPS_DB.DEPLOYMENT TO ROLE IDENTIFIER($DB_PREFIX || 'HC_PLATFORM_ADMIN');
GRANT SELECT ON ALL TABLES IN SCHEMA OPS_DB.DEPLOYMENT TO ROLE IDENTIFIER($DB_PREFIX || 'HC_PLATFORM_ADMIN');
GRANT SELECT ON ALL VIEWS IN SCHEMA OPS_DB.DEPLOYMENT TO ROLE IDENTIFIER($DB_PREFIX || 'HC_PLATFORM_ADMIN');

-- Future grants for new objects
GRANT SELECT ON FUTURE TABLES IN SCHEMA OPS_DB.DEPLOYMENT TO ROLE IDENTIFIER($DB_PREFIX || 'HC_PLATFORM_ADMIN');
GRANT SELECT ON FUTURE VIEWS IN SCHEMA OPS_DB.DEPLOYMENT TO ROLE IDENTIFIER($DB_PREFIX || 'HC_PLATFORM_ADMIN');

CALL OPS_DB.DEPLOYMENT.SP_LOG_STEP($DEPLOYMENT_ID, 5, 'Granted OPS DB access', 'SUCCESS',
    DATEDIFF('MILLISECOND', $STEP_START, CURRENT_TIMESTAMP()));

-- ============================================================================
-- STEP 6: ROLE ASSIGNMENT TRACKING TABLE
-- ============================================================================

SET STEP_START = (SELECT CURRENT_TIMESTAMP());

USE DATABASE OPS_DB;
USE SCHEMA DEPLOYMENT;

CREATE TABLE IF NOT EXISTS ROLE_ASSIGNMENTS (
    ASSIGNMENT_ID VARCHAR(36) DEFAULT UUID_STRING(),
    ROLE_NAME VARCHAR(255) NOT NULL,
    GRANTEE_TYPE VARCHAR(20) NOT NULL,  -- USER, ROLE
    GRANTEE_NAME VARCHAR(255) NOT NULL,
    GRANTED_BY VARCHAR(255) DEFAULT CURRENT_USER(),
    GRANTED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    VALID_FROM DATE,
    VALID_TO DATE,
    JUSTIFICATION VARCHAR(1000),
    TICKET_NUMBER VARCHAR(50),
    ENVIRONMENT VARCHAR(10),
    CONSTRAINT PK_ROLE_ASSIGNMENTS PRIMARY KEY (ASSIGNMENT_ID)
);

CALL OPS_DB.DEPLOYMENT.SP_LOG_STEP($DEPLOYMENT_ID, 6, 'Created role assignment tracking', 'SUCCESS',
    DATEDIFF('MILLISECOND', $STEP_START, CURRENT_TIMESTAMP()));

-- ============================================================================
-- POST-DEPLOYMENT VALIDATION
-- ============================================================================

SET STEP_START = (SELECT CURRENT_TIMESTAMP());

-- Validate all roles exist
SET ROLES_CREATED = (
    SELECT COUNT(*) FROM (
        SHOW ROLES LIKE $DB_PREFIX || 'HC_%'
    )
);

SET VALIDATION_PASSED = (SELECT $ROLES_CREATED >= 9);

-- Log validation
CALL OPS_DB.DEPLOYMENT.SP_LOG_STEP($DEPLOYMENT_ID, 99, 
    'Validation: ' || $ROLES_CREATED || ' roles created', 
    CASE WHEN $VALIDATION_PASSED THEN 'SUCCESS' ELSE 'FAILED' END,
    DATEDIFF('MILLISECOND', $STEP_START, CURRENT_TIMESTAMP()));

-- Output summary
SELECT 
    'RBAC_HIERARCHY' AS PHASE,
    $ENV AS ENVIRONMENT,
    $DEPLOYMENT_ID AS DEPLOYMENT_ID,
    $ROLES_CREATED AS ROLES_CREATED,
    CASE WHEN $VALIDATION_PASSED THEN 'VALIDATED' ELSE 'VALIDATION_FAILED' END AS STATUS;

-- Display role hierarchy
SHOW GRANTS ON ROLE IDENTIFIER($DB_PREFIX || 'HC_PLATFORM_ADMIN');

-- ============================================================================
-- END OF RBAC HIERARCHY
-- ============================================================================
