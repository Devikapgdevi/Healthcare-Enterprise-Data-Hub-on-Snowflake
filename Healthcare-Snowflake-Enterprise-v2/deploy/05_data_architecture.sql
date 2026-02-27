-- ============================================================================
-- ENTERPRISE HEALTHCARE DATA PLATFORM - PHASE 4: DATA ARCHITECTURE
-- ============================================================================
-- File: 05_data_architecture.sql
-- Purpose: Medallion architecture databases and schemas
-- Version: 2.0.0
-- Phase: 4
-- Dependencies: 04_compute_infrastructure.sql
-- ============================================================================

!SET variable_substitution=true;

USE ROLE ACCOUNTADMIN;

-- Initialize deployment context
SET DEPLOYMENT_ID = (SELECT UUID_STRING());
SET ENV = COALESCE($ENV, 'DEV');
SET DB_PREFIX = (SELECT CASE $ENV WHEN 'DEV' THEN 'DEV_' WHEN 'QA' THEN 'QA_' ELSE '' END);
SET RETENTION_DAYS = (SELECT CASE $ENV WHEN 'DEV' THEN 1 WHEN 'QA' THEN 7 ELSE 90 END);

CALL OPS_DB.DEPLOYMENT.SP_LOG_DEPLOYMENT_START(
    $DEPLOYMENT_ID, $ENV, '05_data_architecture.sql', 4, $GIT_COMMIT, $GIT_BRANCH
);

-- ============================================================================
-- DATA ARCHITECTURE OVERVIEW
-- ============================================================================
/*
MEDALLION ARCHITECTURE:

┌─────────────────────────────────────────────────────────────────────────────┐
│                           DATA LAKE ZONES                                   │
├─────────────┬─────────────┬─────────────┬─────────────┬─────────────────────┤
│   LANDING   │   BRONZE    │   SILVER    │    GOLD     │     PLATINUM        │
│   (RAW_DB)  │   (RAW_DB)  │ (CURATED_DB)│(ANALYTICS_DB)│   (AI_READY_DB)    │
├─────────────┼─────────────┼─────────────┼─────────────┼─────────────────────┤
│ - RAW files │ - Raw tables│ - Cleansed  │ - Aggregated│ - ML Features       │
│ - As-is    │ - Typed     │ - Conformed │ - KPIs      │ - Embeddings        │
│ - Staging   │ - Partitioned│ - SCD Type2│ - Dims/Facts│ - Semantic Models   │
└─────────────┴─────────────┴─────────────┴─────────────┴─────────────────────┘

NAMING STANDARDS:
- Tables: HC_{ENTITY}_{ZONE}  (e.g., HC_PATIENT_RAW, HC_PATIENT_DIM)
- Views: V_HC_{PURPOSE}       (e.g., V_HC_PATIENT_SUMMARY)
*/

-- ============================================================================
-- STEP 1: RAW DATABASE (BRONZE LAYER)
-- ============================================================================

SET STEP_START = (SELECT CURRENT_TIMESTAMP());

CREATE DATABASE IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'RAW_DB')
    DATA_RETENTION_TIME_IN_DAYS = $RETENTION_DAYS
    COMMENT = 'Bronze Layer - Raw ingested data with minimal transformation';

-- Raw data landing zone
CREATE SCHEMA IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'RAW_DB.LANDING')
    COMMENT = 'Raw file landing zone - temporary staging';

-- Typed raw data
CREATE SCHEMA IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'RAW_DB.RAW')
    COMMENT = 'Typed raw data - minimal transformations applied';

-- External data sources
CREATE SCHEMA IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'RAW_DB.EXTERNAL')
    COMMENT = 'External tables and stages';

-- Grant access
GRANT USAGE ON DATABASE IDENTIFIER($DB_PREFIX || 'RAW_DB') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_DATA_ENGINEER');
GRANT ALL ON ALL SCHEMAS IN DATABASE IDENTIFIER($DB_PREFIX || 'RAW_DB') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_DATA_ENGINEER');
GRANT CREATE TABLE, CREATE VIEW, CREATE STAGE ON ALL SCHEMAS IN DATABASE IDENTIFIER($DB_PREFIX || 'RAW_DB') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_DATA_ENGINEER');

-- Future grants
GRANT SELECT ON FUTURE TABLES IN DATABASE IDENTIFIER($DB_PREFIX || 'RAW_DB') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_DATA_ENGINEER');

CALL OPS_DB.DEPLOYMENT.SP_LOG_STEP($DEPLOYMENT_ID, 1, 'Created RAW_DB (Bronze layer)', 'SUCCESS',
    DATEDIFF('MILLISECOND', $STEP_START, CURRENT_TIMESTAMP()));

CALL OPS_DB.DEPLOYMENT.SP_REGISTER_OBJECT($DEPLOYMENT_ID, $ENV, 'DATABASE', 
    'RAW_DB', $DB_PREFIX || 'RAW_DB', 4, 'Bronze Layer Database', NULL);

-- ============================================================================
-- STEP 2: CURATED DATABASE (SILVER LAYER)
-- ============================================================================

SET STEP_START = (SELECT CURRENT_TIMESTAMP());

CREATE DATABASE IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'CURATED_DB')
    DATA_RETENTION_TIME_IN_DAYS = $RETENTION_DAYS
    COMMENT = 'Silver Layer - Cleansed, conformed, and quality-checked data';

-- Cleansed data
CREATE SCHEMA IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'CURATED_DB.CLEANSED')
    COMMENT = 'Cleansed data with data quality rules applied';

-- Conformed dimensions
CREATE SCHEMA IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'CURATED_DB.CONFORMED')
    COMMENT = 'Conformed dimensions and master data';

-- Historical tracking (SCD Type 2)
CREATE SCHEMA IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'CURATED_DB.HISTORY')
    COMMENT = 'Historical tracking with SCD Type 2';

-- Grant access
GRANT USAGE ON DATABASE IDENTIFIER($DB_PREFIX || 'CURATED_DB') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_DATA_ENGINEER');
GRANT USAGE ON DATABASE IDENTIFIER($DB_PREFIX || 'CURATED_DB') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_DATA_ANALYST');
GRANT ALL ON ALL SCHEMAS IN DATABASE IDENTIFIER($DB_PREFIX || 'CURATED_DB') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_DATA_ENGINEER');
GRANT SELECT ON FUTURE TABLES IN DATABASE IDENTIFIER($DB_PREFIX || 'CURATED_DB') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_DATA_ANALYST');

CALL OPS_DB.DEPLOYMENT.SP_LOG_STEP($DEPLOYMENT_ID, 2, 'Created CURATED_DB (Silver layer)', 'SUCCESS',
    DATEDIFF('MILLISECOND', $STEP_START, CURRENT_TIMESTAMP()));

-- ============================================================================
-- STEP 3: ANALYTICS DATABASE (GOLD LAYER)
-- ============================================================================

SET STEP_START = (SELECT CURRENT_TIMESTAMP());

CREATE DATABASE IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'ANALYTICS_DB')
    DATA_RETENTION_TIME_IN_DAYS = $RETENTION_DAYS
    COMMENT = 'Gold Layer - Business-ready aggregations and KPIs';

-- Dimensional model
CREATE SCHEMA IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'ANALYTICS_DB.DIM')
    COMMENT = 'Dimension tables';

CREATE SCHEMA IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'ANALYTICS_DB.FACT')
    COMMENT = 'Fact tables';

-- Aggregations and KPIs
CREATE SCHEMA IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'ANALYTICS_DB.AGG')
    COMMENT = 'Pre-aggregated tables and materialized KPIs';

-- Reporting views
CREATE SCHEMA IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'ANALYTICS_DB.RPT')
    COMMENT = 'Reporting views for BI tools';

-- Grant access
GRANT USAGE ON DATABASE IDENTIFIER($DB_PREFIX || 'ANALYTICS_DB') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_DATA_ANALYST');
GRANT USAGE ON DATABASE IDENTIFIER($DB_PREFIX || 'ANALYTICS_DB') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_VIEWER');
GRANT USAGE ON ALL SCHEMAS IN DATABASE IDENTIFIER($DB_PREFIX || 'ANALYTICS_DB') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_DATA_ANALYST');
GRANT SELECT ON FUTURE TABLES IN DATABASE IDENTIFIER($DB_PREFIX || 'ANALYTICS_DB') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_VIEWER');
GRANT SELECT ON FUTURE VIEWS IN DATABASE IDENTIFIER($DB_PREFIX || 'ANALYTICS_DB') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_VIEWER');

CALL OPS_DB.DEPLOYMENT.SP_LOG_STEP($DEPLOYMENT_ID, 3, 'Created ANALYTICS_DB (Gold layer)', 'SUCCESS',
    DATEDIFF('MILLISECOND', $STEP_START, CURRENT_TIMESTAMP()));

-- ============================================================================
-- STEP 4: AI-READY DATABASE (PLATINUM LAYER)
-- ============================================================================

SET STEP_START = (SELECT CURRENT_TIMESTAMP());

CREATE DATABASE IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'AI_READY_DB')
    DATA_RETENTION_TIME_IN_DAYS = $RETENTION_DAYS
    COMMENT = 'Platinum Layer - ML features, embeddings, and AI-ready data';

-- Feature store
CREATE SCHEMA IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'AI_READY_DB.FEATURES')
    COMMENT = 'ML feature store - engineered features for models';

-- Embeddings and vectors
CREATE SCHEMA IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'AI_READY_DB.EMBEDDINGS')
    COMMENT = 'Vector embeddings for semantic search and RAG';

-- Semantic models
CREATE SCHEMA IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'AI_READY_DB.SEMANTIC')
    COMMENT = 'Semantic models for Cortex Analyst';

-- Model artifacts
CREATE SCHEMA IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'AI_READY_DB.MODELS')
    COMMENT = 'Model artifacts and metadata';

-- Grant access
GRANT USAGE ON DATABASE IDENTIFIER($DB_PREFIX || 'AI_READY_DB') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_DATA_SCIENTIST');
GRANT ALL ON ALL SCHEMAS IN DATABASE IDENTIFIER($DB_PREFIX || 'AI_READY_DB') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_DATA_SCIENTIST');
GRANT SELECT ON FUTURE TABLES IN DATABASE IDENTIFIER($DB_PREFIX || 'AI_READY_DB') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_DATA_ANALYST');

CALL OPS_DB.DEPLOYMENT.SP_LOG_STEP($DEPLOYMENT_ID, 4, 'Created AI_READY_DB (Platinum layer)', 'SUCCESS',
    DATEDIFF('MILLISECOND', $STEP_START, CURRENT_TIMESTAMP()));

-- ============================================================================
-- STEP 5: AUDIT DATABASE
-- ============================================================================

SET STEP_START = (SELECT CURRENT_TIMESTAMP());

CREATE DATABASE IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'AUDIT_DB')
    DATA_RETENTION_TIME_IN_DAYS = 365  -- Long retention for compliance
    COMMENT = 'Audit trail and compliance tracking';

CREATE SCHEMA IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'AUDIT_DB.ACCESS_HISTORY')
    COMMENT = 'Data access history for compliance';

CREATE SCHEMA IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'AUDIT_DB.CHANGE_HISTORY')
    COMMENT = 'Data change history and lineage';

CREATE SCHEMA IF NOT EXISTS IDENTIFIER($DB_PREFIX || 'AUDIT_DB.COMPLIANCE')
    COMMENT = 'Compliance reports and attestations';

-- Grant read access for auditors
GRANT USAGE ON DATABASE IDENTIFIER($DB_PREFIX || 'AUDIT_DB') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_SECURITY_ADMIN');
GRANT SELECT ON ALL TABLES IN DATABASE IDENTIFIER($DB_PREFIX || 'AUDIT_DB') 
    TO ROLE IDENTIFIER($DB_PREFIX || 'HC_SECURITY_ADMIN');

CALL OPS_DB.DEPLOYMENT.SP_LOG_STEP($DEPLOYMENT_ID, 5, 'Created AUDIT_DB', 'SUCCESS',
    DATEDIFF('MILLISECOND', $STEP_START, CURRENT_TIMESTAMP()));

-- ============================================================================
-- STEP 6: DATA LINEAGE TRACKING TABLE
-- ============================================================================

SET STEP_START = (SELECT CURRENT_TIMESTAMP());

USE DATABASE OPS_DB;
USE SCHEMA DEPLOYMENT;

CREATE TABLE IF NOT EXISTS DATA_LINEAGE (
    LINEAGE_ID VARCHAR(36) DEFAULT UUID_STRING(),
    
    -- Source
    SOURCE_DATABASE VARCHAR(255) NOT NULL,
    SOURCE_SCHEMA VARCHAR(255) NOT NULL,
    SOURCE_OBJECT VARCHAR(255) NOT NULL,
    SOURCE_TYPE VARCHAR(50) NOT NULL,
    
    -- Target
    TARGET_DATABASE VARCHAR(255) NOT NULL,
    TARGET_SCHEMA VARCHAR(255) NOT NULL,
    TARGET_OBJECT VARCHAR(255) NOT NULL,
    TARGET_TYPE VARCHAR(50) NOT NULL,
    
    -- Transformation
    TRANSFORMATION_TYPE VARCHAR(50),  -- COPY, TRANSFORM, AGGREGATE, JOIN
    TRANSFORMATION_SQL VARCHAR(10000),
    
    -- Metadata
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CREATED_BY VARCHAR(255) DEFAULT CURRENT_USER(),
    ENVIRONMENT VARCHAR(10),
    
    CONSTRAINT PK_DATA_LINEAGE PRIMARY KEY (LINEAGE_ID)
);

-- Lineage view
CREATE OR REPLACE VIEW V_DATA_LINEAGE_GRAPH AS
SELECT
    SOURCE_DATABASE || '.' || SOURCE_SCHEMA || '.' || SOURCE_OBJECT AS SOURCE_FQN,
    TARGET_DATABASE || '.' || TARGET_SCHEMA || '.' || TARGET_OBJECT AS TARGET_FQN,
    TRANSFORMATION_TYPE,
    CREATED_AT
FROM DATA_LINEAGE
WHERE ENVIRONMENT = $ENV OR ENVIRONMENT IS NULL
ORDER BY CREATED_AT;

CALL OPS_DB.DEPLOYMENT.SP_LOG_STEP($DEPLOYMENT_ID, 6, 'Created data lineage tracking', 'SUCCESS',
    DATEDIFF('MILLISECOND', $STEP_START, CURRENT_TIMESTAMP()));

-- ============================================================================
-- POST-DEPLOYMENT VALIDATION
-- ============================================================================

SET STEP_START = (SELECT CURRENT_TIMESTAMP());

-- Count databases created
SET DB_COUNT = (
    SELECT COUNT(*) FROM (
        SHOW DATABASES LIKE $DB_PREFIX || '%_DB'
    ) WHERE "name" NOT IN ('OPS_DB')
);

-- Count schemas
SET SCHEMA_COUNT = (
    SELECT COUNT(*) FROM (
        SELECT SCHEMA_NAME FROM IDENTIFIER($DB_PREFIX || 'RAW_DB').INFORMATION_SCHEMA.SCHEMATA
        WHERE SCHEMA_NAME NOT IN ('INFORMATION_SCHEMA', 'PUBLIC')
        UNION ALL
        SELECT SCHEMA_NAME FROM IDENTIFIER($DB_PREFIX || 'CURATED_DB').INFORMATION_SCHEMA.SCHEMATA
        WHERE SCHEMA_NAME NOT IN ('INFORMATION_SCHEMA', 'PUBLIC')
        UNION ALL
        SELECT SCHEMA_NAME FROM IDENTIFIER($DB_PREFIX || 'ANALYTICS_DB').INFORMATION_SCHEMA.SCHEMATA
        WHERE SCHEMA_NAME NOT IN ('INFORMATION_SCHEMA', 'PUBLIC')
        UNION ALL
        SELECT SCHEMA_NAME FROM IDENTIFIER($DB_PREFIX || 'AI_READY_DB').INFORMATION_SCHEMA.SCHEMATA
        WHERE SCHEMA_NAME NOT IN ('INFORMATION_SCHEMA', 'PUBLIC')
    )
);

SET VALIDATION_PASSED = (SELECT $DB_COUNT >= 4 AND $SCHEMA_COUNT >= 12);

CALL OPS_DB.DEPLOYMENT.SP_LOG_STEP($DEPLOYMENT_ID, 99, 
    'Validation: ' || $DB_COUNT || ' databases, ' || $SCHEMA_COUNT || ' schemas', 
    CASE WHEN $VALIDATION_PASSED THEN 'SUCCESS' ELSE 'FAILED' END,
    DATEDIFF('MILLISECOND', $STEP_START, CURRENT_TIMESTAMP()));

-- Output summary
SELECT 
    'DATA_ARCHITECTURE' AS PHASE,
    $ENV AS ENVIRONMENT,
    $DB_COUNT AS DATABASES_CREATED,
    $SCHEMA_COUNT AS SCHEMAS_CREATED,
    CASE WHEN $VALIDATION_PASSED THEN 'VALIDATED' ELSE 'VALIDATION_FAILED' END AS STATUS;

-- ============================================================================
-- END OF DATA ARCHITECTURE
-- ============================================================================
