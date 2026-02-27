-- ============================================================================
-- ENTERPRISE HEALTHCARE DATA PLATFORM - PHASE 1: SECURITY FOUNDATION
-- ============================================================================
-- File: 02_security_foundation.sql
-- Purpose: Security database, policies, and governance infrastructure
-- Version: 2.0.0
-- Phase: 1
-- Dependencies: 01_deployment_logger.sql
-- Rollback: 02_security_foundation_rollback.sql
-- ============================================================================

!SET variable_substitution=true;

-- ============================================================================
-- PRE-DEPLOYMENT VALIDATION
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- Validate prerequisites
DO $$
DECLARE
    ops_db_exists BOOLEAN;
BEGIN
    SELECT COUNT(*) > 0 INTO ops_db_exists 
    FROM INFORMATION_SCHEMA.DATABASES WHERE DATABASE_NAME = 'OPS_DB';
    
    IF NOT ops_db_exists THEN
        RAISE EXCEPTION 'Prerequisite failed: OPS_DB does not exist. Run 01_deployment_logger.sql first.';
    END IF;
END;
$$;

-- Initialize deployment
SET DEPLOYMENT_ID = (SELECT UUID_STRING());
SET ENV = COALESCE($ENV, 'DEV');
SET DB_PREFIX = (SELECT CASE $ENV WHEN 'DEV' THEN 'DEV_' WHEN 'QA' THEN 'QA_' ELSE '' END);

-- Log deployment start
CALL OPS_DB.DEPLOYMENT.SP_LOG_DEPLOYMENT_START(
    $DEPLOYMENT_ID, $ENV, '02_security_foundation.sql', 1, $GIT_COMMIT, $GIT_BRANCH
);

-- ============================================================================
-- STEP 1: CREATE SECURITY DATABASE
-- ============================================================================

SET STEP_START = (SELECT CURRENT_TIMESTAMP());

CREATE DATABASE IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'SECURITY_DB')
    DATA_RETENTION_TIME_IN_DAYS = 90
    COMMENT = 'Security policies, governance objects, and access control';

-- Create schemas
CREATE SCHEMA IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'SECURITY_DB.POLICIES')
    COMMENT = 'Security policies (network, password, session)';

CREATE SCHEMA IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'SECURITY_DB.GOVERNANCE')
    COMMENT = 'Data governance objects (tags, masking, row access)';

CREATE SCHEMA IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'SECURITY_DB.KEYS')
    COMMENT = 'Encryption keys and secrets management';

-- Log step completion
CALL OPS_DB.DEPLOYMENT.SP_LOG_STEP($DEPLOYMENT_ID, 1, 'Created SECURITY_DB and schemas', 'SUCCESS',
    DATEDIFF('MILLISECOND', $STEP_START, CURRENT_TIMESTAMP()));

-- Register objects
CALL OPS_DB.DEPLOYMENT.SP_REGISTER_OBJECT($DEPLOYMENT_ID, $ENV, 'DATABASE', 'SECURITY_DB',
    $DB_PREFIX || 'SECURITY_DB', 1, 'Security and governance database', NULL);

-- ============================================================================
-- STEP 2: NETWORK POLICY (Idempotent)
-- ============================================================================

USE DATABASE IDENTIFIER($DB_PREFIX || 'SECURITY_DB');
USE SCHEMA POLICIES;

SET STEP_START = (SELECT CURRENT_TIMESTAMP());

-- Create network policy with environment-specific IPs
-- In production, replace with actual IP ranges
CREATE OR REPLACE NETWORK POLICY POL_NETWORK_ACCESS
    ALLOWED_IP_LIST = (
        '0.0.0.0/0'  -- SECURITY RISK: Replace with actual IPs in production
    )
    BLOCKED_IP_LIST = ()
    COMMENT = 'Network access policy for healthcare platform - Environment: ' || $ENV;

-- Conditional attachment based on environment
-- Only attach in PROD after review
EXECUTE IMMEDIATE $$
BEGIN
    IF ('$ENV' = 'PROD') THEN
        -- Requires explicit approval for PROD
        -- ALTER ACCOUNT SET NETWORK_POLICY = POL_NETWORK_ACCESS;
        RETURN 'Network policy created but NOT attached in PROD. Requires manual approval.';
    END IF;
    RETURN 'Network policy created for ' || '$ENV';
END;
$$;

CALL OPS_DB.DEPLOYMENT.SP_LOG_STEP($DEPLOYMENT_ID, 2, 'Created network policy', 'SUCCESS',
    DATEDIFF('MILLISECOND', $STEP_START, CURRENT_TIMESTAMP()));

-- ============================================================================
-- STEP 3: PASSWORD POLICY (Idempotent)
-- ============================================================================

SET STEP_START = (SELECT CURRENT_TIMESTAMP());

CREATE OR REPLACE PASSWORD POLICY POL_PASSWORD_STANDARD
    PASSWORD_MIN_LENGTH = 14
    PASSWORD_MAX_LENGTH = 256
    PASSWORD_MIN_UPPER_CASE_CHARS = 2
    PASSWORD_MIN_LOWER_CASE_CHARS = 2
    PASSWORD_MIN_NUMERIC_CHARS = 2
    PASSWORD_MIN_SPECIAL_CHARS = 2
    PASSWORD_MAX_AGE_DAYS = 90
    PASSWORD_MAX_RETRIES = 5
    PASSWORD_LOCKOUT_TIME_MINS = 30
    PASSWORD_HISTORY = 12
    COMMENT = 'Enterprise password policy - HIPAA compliant';

CALL OPS_DB.DEPLOYMENT.SP_LOG_STEP($DEPLOYMENT_ID, 3, 'Created password policy', 'SUCCESS',
    DATEDIFF('MILLISECOND', $STEP_START, CURRENT_TIMESTAMP()));

-- ============================================================================
-- STEP 4: SESSION POLICY (Idempotent)
-- ============================================================================

SET STEP_START = (SELECT CURRENT_TIMESTAMP());

-- Environment-specific session timeouts
SET SESSION_TIMEOUT = (
    SELECT CASE $ENV
        WHEN 'DEV' THEN 60
        WHEN 'QA' THEN 45
        WHEN 'PROD' THEN 30
    END
);

CREATE OR REPLACE SESSION POLICY POL_SESSION_STANDARD
    SESSION_IDLE_TIMEOUT_MINS = $SESSION_TIMEOUT
    SESSION_UI_IDLE_TIMEOUT_MINS = $SESSION_TIMEOUT
    COMMENT = 'Enterprise session policy - Timeout: ' || $SESSION_TIMEOUT || ' mins';

CALL OPS_DB.DEPLOYMENT.SP_LOG_STEP($DEPLOYMENT_ID, 4, 'Created session policy', 'SUCCESS',
    DATEDIFF('MILLISECOND', $STEP_START, CURRENT_TIMESTAMP()));

-- ============================================================================
-- STEP 5: DATA CLASSIFICATION TAGS (Idempotent)
-- ============================================================================

USE SCHEMA GOVERNANCE;

SET STEP_START = (SELECT CURRENT_TIMESTAMP());

-- Data sensitivity classification
CREATE OR REPLACE TAG TAG_DATA_CLASSIFICATION
    ALLOWED_VALUES 'PUBLIC', 'INTERNAL', 'CONFIDENTIAL', 'RESTRICTED', 'PHI', 'PII'
    COMMENT = 'Data classification per enterprise security policy';

-- Healthcare-specific tags
CREATE OR REPLACE TAG TAG_PHI_CATEGORY
    ALLOWED_VALUES 'DIAGNOSIS', 'TREATMENT', 'MEDICATION', 'VITALS', 'HISTORY', 'GENETIC'
    COMMENT = 'Protected Health Information category (HIPAA)';

CREATE OR REPLACE TAG TAG_PII_TYPE
    ALLOWED_VALUES 'SSN', 'NAME', 'DOB', 'ADDRESS', 'PHONE', 'EMAIL', 'INSURANCE_ID'
    COMMENT = 'Personally Identifiable Information type';

CREATE OR REPLACE TAG TAG_DATA_DOMAIN
    ALLOWED_VALUES 'PATIENT', 'CLINICAL', 'BILLING', 'DEVICE', 'OPERATIONAL', 'REFERENCE'
    COMMENT = 'Business data domain classification';

CREATE OR REPLACE TAG TAG_RETENTION_POLICY
    ALLOWED_VALUES '1_YEAR', '3_YEARS', '7_YEARS', '10_YEARS', 'PERMANENT', 'TRANSIENT'
    COMMENT = 'Data retention requirement per compliance';

CALL OPS_DB.DEPLOYMENT.SP_LOG_STEP($DEPLOYMENT_ID, 5, 'Created governance tags', 'SUCCESS',
    DATEDIFF('MILLISECOND', $STEP_START, CURRENT_TIMESTAMP()));

-- ============================================================================
-- STEP 6: MASKING POLICIES (Idempotent)
-- ============================================================================

SET STEP_START = (SELECT CURRENT_TIMESTAMP());

-- SSN Masking Policy
CREATE OR REPLACE MASKING POLICY POL_MASK_SSN
    AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', $DB_PREFIX || 'HC_SECURITY_ADMIN') THEN val
        WHEN CURRENT_ROLE() IN ($DB_PREFIX || 'HC_ACCOUNT_ADMIN') THEN 'XXX-XX-' || RIGHT(val, 4)
        ELSE 'XXX-XX-XXXX'
    END
    COMMENT = 'SSN masking - Full access: Security Admin only';

-- Phone Masking Policy
CREATE OR REPLACE MASKING POLICY POL_MASK_PHONE
    AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', $DB_PREFIX || 'HC_SECURITY_ADMIN') THEN val
        WHEN CURRENT_ROLE() IN ($DB_PREFIX || 'HC_ACCOUNT_ADMIN', $DB_PREFIX || 'HC_DATA_ENGINEER') 
            THEN REGEXP_REPLACE(val, '([0-9]{3})[0-9]{3}([0-9]{4})', '\\1-XXX-\\2')
        ELSE '(XXX) XXX-XXXX'
    END
    COMMENT = 'Phone number masking';

-- Name Masking Policy
CREATE OR REPLACE MASKING POLICY POL_MASK_NAME
    AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', $DB_PREFIX || 'HC_SECURITY_ADMIN', 
                                $DB_PREFIX || 'HC_ACCOUNT_ADMIN') THEN val
        ELSE LEFT(val, 1) || REPEAT('*', LENGTH(val) - 1)
    END
    COMMENT = 'Name masking - First initial only for restricted roles';

-- Insurance ID Masking Policy
CREATE OR REPLACE MASKING POLICY POL_MASK_INSURANCE_ID
    AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', $DB_PREFIX || 'HC_SECURITY_ADMIN') THEN val
        ELSE 'INS-XXXX-' || RIGHT(val, 4)
    END
    COMMENT = 'Insurance ID masking';

CALL OPS_DB.DEPLOYMENT.SP_LOG_STEP($DEPLOYMENT_ID, 6, 'Created masking policies', 'SUCCESS',
    DATEDIFF('MILLISECOND', $STEP_START, CURRENT_TIMESTAMP()));

-- ============================================================================
-- STEP 7: ROW ACCESS POLICY (Idempotent)
-- ============================================================================

SET STEP_START = (SELECT CURRENT_TIMESTAMP());

-- Region-based row access
CREATE OR REPLACE ROW ACCESS POLICY POL_ROW_REGION
    AS (region_col STRING) RETURNS BOOLEAN ->
    CASE
        -- Full access for admin roles
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', $DB_PREFIX || 'HC_SECURITY_ADMIN',
                                $DB_PREFIX || 'HC_ACCOUNT_ADMIN') THEN TRUE
        -- Data engineers see all for ETL
        WHEN CURRENT_ROLE() = $DB_PREFIX || 'HC_DATA_ENGINEER' THEN TRUE
        -- Analysts restricted by region mapping table
        WHEN CURRENT_ROLE() = $DB_PREFIX || 'HC_ANALYST' THEN 
            region_col IN ('NORTH', 'SOUTH', 'EAST', 'WEST')  -- Simplified; use mapping table in prod
        -- Viewers see limited regions
        WHEN CURRENT_ROLE() = $DB_PREFIX || 'HC_VIEWER' THEN 
            region_col IN ('NORTH')
        ELSE FALSE
    END
    COMMENT = 'Region-based row-level security';

CALL OPS_DB.DEPLOYMENT.SP_LOG_STEP($DEPLOYMENT_ID, 7, 'Created row access policy', 'SUCCESS',
    DATEDIFF('MILLISECOND', $STEP_START, CURRENT_TIMESTAMP()));

-- ============================================================================
-- POST-DEPLOYMENT VALIDATION
-- ============================================================================

SET STEP_START = (SELECT CURRENT_TIMESTAMP());

-- Validation queries
CREATE OR REPLACE TEMPORARY TABLE _VALIDATION_RESULTS AS
SELECT 'TAG' AS OBJECT_TYPE, TAG_NAME AS OBJECT_NAME, 'EXISTS' AS STATUS
FROM IDENTIFIER($DB_PREFIX || 'SECURITY_DB').INFORMATION_SCHEMA.TAGS
WHERE TAG_SCHEMA = 'GOVERNANCE'
UNION ALL
SELECT 'MASKING_POLICY', POLICY_NAME, 'EXISTS'
FROM IDENTIFIER($DB_PREFIX || 'SECURITY_DB').INFORMATION_SCHEMA.MASKING_POLICIES
WHERE POLICY_SCHEMA = 'GOVERNANCE'
UNION ALL
SELECT 'ROW_ACCESS_POLICY', POLICY_NAME, 'EXISTS'
FROM IDENTIFIER($DB_PREFIX || 'SECURITY_DB').INFORMATION_SCHEMA.ROW_ACCESS_POLICIES
WHERE POLICY_SCHEMA = 'GOVERNANCE';

-- Validate expected object counts
SET VALIDATION_PASSED = (
    SELECT CASE
        WHEN (SELECT COUNT(*) FROM _VALIDATION_RESULTS WHERE OBJECT_TYPE = 'TAG') >= 5
         AND (SELECT COUNT(*) FROM _VALIDATION_RESULTS WHERE OBJECT_TYPE = 'MASKING_POLICY') >= 4
         AND (SELECT COUNT(*) FROM _VALIDATION_RESULTS WHERE OBJECT_TYPE = 'ROW_ACCESS_POLICY') >= 1
        THEN TRUE
        ELSE FALSE
    END
);

-- Log validation result
CALL OPS_DB.DEPLOYMENT.SP_LOG_STEP($DEPLOYMENT_ID, 99, 'Post-deployment validation', 
    CASE WHEN $VALIDATION_PASSED THEN 'SUCCESS' ELSE 'FAILED' END,
    DATEDIFF('MILLISECOND', $STEP_START, CURRENT_TIMESTAMP()));

-- Output validation summary
SELECT 
    'SECURITY_FOUNDATION' AS PHASE,
    $ENV AS ENVIRONMENT,
    $DEPLOYMENT_ID AS DEPLOYMENT_ID,
    CASE WHEN $VALIDATION_PASSED THEN 'VALIDATED' ELSE 'VALIDATION_FAILED' END AS STATUS,
    (SELECT COUNT(*) FROM _VALIDATION_RESULTS) AS OBJECTS_CREATED;

-- ============================================================================
-- END OF SECURITY FOUNDATION
-- ============================================================================
