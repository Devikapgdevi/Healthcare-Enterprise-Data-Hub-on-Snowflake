-- ============================================================================
-- ENTERPRISE HEALTHCARE DATA PLATFORM - DEPLOYMENT CONFIGURATION
-- ============================================================================
-- File: 00_config.sql
-- Purpose: Environment configuration and deployment parameters
-- Version: 2.0.0
-- Author: DEVIKAPG
-- Reviewed By: [Enterprise Architect]
-- Last Modified: 2026-02-27
-- ============================================================================
-- USAGE: 
--   snowsql -f 00_config.sql -D ENV=DEV
--   snowsql -f 00_config.sql -D ENV=QA
--   snowsql -f 00_config.sql -D ENV=PROD
-- ============================================================================

-- ============================================================================
-- ENVIRONMENT DETECTION & VALIDATION
-- ============================================================================

-- Default to DEV if not specified
SET ENV = COALESCE($ENV, 'DEV');

-- Validate environment
SET ENV_VALID = (
    SELECT CASE 
        WHEN $ENV IN ('DEV', 'QA', 'PROD') THEN TRUE 
        ELSE FALSE 
    END
);

-- Fail if invalid environment
SELECT CASE 
    WHEN $ENV_VALID = FALSE 
    THEN 1/0  -- Force error
    ELSE 'Environment validated: ' || $ENV 
END AS VALIDATION_RESULT;

-- ============================================================================
-- ENVIRONMENT-SPECIFIC CONFIGURATIONS
-- ============================================================================

-- Database Prefixes
SET DB_PREFIX = (
    SELECT CASE $ENV
        WHEN 'DEV'  THEN 'DEV_'
        WHEN 'QA'   THEN 'QA_'
        WHEN 'PROD' THEN ''
    END
);

-- Warehouse Sizes (Cost Control)
SET WH_SIZE_ETL = (
    SELECT CASE $ENV
        WHEN 'DEV'  THEN 'XSMALL'
        WHEN 'QA'   THEN 'SMALL'
        WHEN 'PROD' THEN 'MEDIUM'
    END
);

SET WH_SIZE_TRANSFORM = (
    SELECT CASE $ENV
        WHEN 'DEV'  THEN 'XSMALL'
        WHEN 'QA'   THEN 'SMALL'
        WHEN 'PROD' THEN 'LARGE'
    END
);

SET WH_SIZE_ANALYTICS = (
    SELECT CASE $ENV
        WHEN 'DEV'  THEN 'XSMALL'
        WHEN 'QA'   THEN 'SMALL'
        WHEN 'PROD' THEN 'MEDIUM'
    END
);

SET WH_SIZE_AI = (
    SELECT CASE $ENV
        WHEN 'DEV'  THEN 'XSMALL'
        WHEN 'QA'   THEN 'MEDIUM'
        WHEN 'PROD' THEN 'LARGE'
    END
);

-- Auto-Suspend Times (seconds)
SET WH_AUTO_SUSPEND = (
    SELECT CASE $ENV
        WHEN 'DEV'  THEN 60
        WHEN 'QA'   THEN 120
        WHEN 'PROD' THEN 300
    END
);

-- Credit Quotas (Cost Governance)
SET CREDIT_QUOTA_ACCOUNT = (
    SELECT CASE $ENV
        WHEN 'DEV'  THEN 50
        WHEN 'QA'   THEN 100
        WHEN 'PROD' THEN 500
    END
);

SET CREDIT_QUOTA_ETL = (
    SELECT CASE $ENV
        WHEN 'DEV'  THEN 10
        WHEN 'QA'   THEN 25
        WHEN 'PROD' THEN 100
    END
);

SET CREDIT_QUOTA_TRANSFORM = (
    SELECT CASE $ENV
        WHEN 'DEV'  THEN 15
        WHEN 'QA'   THEN 35
        WHEN 'PROD' THEN 150
    END
);

SET CREDIT_QUOTA_ANALYTICS = (
    SELECT CASE $ENV
        WHEN 'DEV'  THEN 10
        WHEN 'QA'   THEN 20
        WHEN 'PROD' THEN 75
    END
);

SET CREDIT_QUOTA_AI = (
    SELECT CASE $ENV
        WHEN 'DEV'  THEN 20
        WHEN 'QA'   THEN 50
        WHEN 'PROD' THEN 200
    END
);

-- Data Retention (days)
SET DATA_RETENTION_DAYS = (
    SELECT CASE $ENV
        WHEN 'DEV'  THEN 1
        WHEN 'QA'   THEN 7
        WHEN 'PROD' THEN 90
    END
);

-- Sample Data Size
SET SAMPLE_SIZE_PATIENTS = (
    SELECT CASE $ENV
        WHEN 'DEV'  THEN 1000
        WHEN 'QA'   THEN 5000
        WHEN 'PROD' THEN 100000
    END
);

SET SAMPLE_SIZE_EVENTS = (
    SELECT CASE $ENV
        WHEN 'DEV'  THEN 5000
        WHEN 'QA'   THEN 25000
        WHEN 'PROD' THEN 500000
    END
);

-- ============================================================================
-- NAMING CONVENTIONS (Enterprise Standards)
-- ============================================================================
/*
NAMING CONVENTION STANDARDS:

Databases:      {ENV_PREFIX}{DOMAIN}_DB
                Examples: DEV_RAW_DB, QA_ANALYTICS_DB, TRANSFORM_DB

Schemas:        {FUNCTION}_SCHEMA
                Examples: STAGING_SCHEMA, CURATED_SCHEMA, FEATURE_SCHEMA

Tables:         {DOMAIN}_{ENTITY}_{SUFFIX}
                Suffixes: _RAW, _STG, _DIM, _FACT, _AGG, _FEAT
                Examples: HC_PATIENT_RAW, HC_BILLING_FACT, HC_RISK_FEAT

Views:          V_{DOMAIN}_{PURPOSE}
                Examples: V_HC_PATIENT_SUMMARY, V_HC_BILLING_KPI

Procedures:     SP_{ACTION}_{ENTITY}
                Examples: SP_LOAD_PATIENT, SP_CALC_RISK_SCORE

Functions:      FN_{PURPOSE}
                Examples: FN_CALC_AGE_GROUP, FN_MASK_SSN

Warehouses:     {ENV_PREFIX}HC_{WORKLOAD}_WH
                Examples: DEV_HC_ETL_WH, HC_ANALYTICS_WH

Roles:          {ENV_PREFIX}HC_{FUNCTION}
                Examples: DEV_HC_DATA_ENGINEER, HC_ANALYST

Resource Monitors: {ENV_PREFIX}HC_{SCOPE}_RM
                Examples: DEV_HC_ACCOUNT_RM, HC_ETL_WH_RM

Policies:       POL_{TYPE}_{ENTITY}
                Examples: POL_MASK_SSN, POL_ROW_REGION

Tags:           TAG_{DOMAIN}_{CLASSIFICATION}
                Examples: TAG_HC_PHI, TAG_HC_PII
*/

-- ============================================================================
-- DEPLOYMENT METADATA
-- ============================================================================

SET DEPLOYMENT_ID = (SELECT UUID_STRING());
SET DEPLOYMENT_TIMESTAMP = (SELECT CURRENT_TIMESTAMP());
SET DEPLOYMENT_USER = (SELECT CURRENT_USER());
SET DEPLOYMENT_ROLE = (SELECT CURRENT_ROLE());
SET GIT_COMMIT = COALESCE($GIT_COMMIT, 'LOCAL');
SET GIT_BRANCH = COALESCE($GIT_BRANCH, 'main');

-- Display Configuration Summary
SELECT 
    $ENV AS ENVIRONMENT,
    $DB_PREFIX AS DATABASE_PREFIX,
    $WH_SIZE_ETL AS ETL_WAREHOUSE_SIZE,
    $CREDIT_QUOTA_ACCOUNT AS ACCOUNT_CREDIT_QUOTA,
    $DATA_RETENTION_DAYS AS DATA_RETENTION_DAYS,
    $SAMPLE_SIZE_PATIENTS AS SAMPLE_PATIENTS,
    $DEPLOYMENT_ID AS DEPLOYMENT_ID,
    $GIT_COMMIT AS GIT_COMMIT;

-- ============================================================================
-- END OF CONFIGURATION
-- ============================================================================
