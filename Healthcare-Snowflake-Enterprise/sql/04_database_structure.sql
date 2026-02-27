-- ============================================================================
-- PHASE 4: DATABASE STRUCTURE
-- Healthcare Enterprise Data Hub
-- ============================================================================
-- Objectives: Create medallion architecture databases and schemas
-- Role Required: ACCOUNTADMIN/SYSADMIN
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- 4.1 MEDALLION ARCHITECTURE DATABASES
-- ============================================================================

-- BRONZE LAYER - Raw ingested data
CREATE DATABASE IF NOT EXISTS RAW_DB
    COMMENT = 'Bronze Layer - Raw ingested healthcare data';

-- SILVER LAYER - Cleaned and transformed data
CREATE DATABASE IF NOT EXISTS TRANSFORM_DB
    COMMENT = 'Silver Layer - Cleaned and transformed data';

-- GOLD LAYER - Aggregated analytics-ready data
CREATE DATABASE IF NOT EXISTS ANALYTICS_DB
    COMMENT = 'Gold Layer - Aggregated analytics data';

-- PLATINUM LAYER - AI/ML feature store
CREATE DATABASE IF NOT EXISTS AI_READY_DB
    COMMENT = 'Platinum Layer - ML features and embeddings';

-- ============================================================================
-- 4.2 SUPPORT DATABASES
-- ============================================================================

-- Monitoring Database
CREATE DATABASE IF NOT EXISTS MONITORING_DB
    COMMENT = 'Performance and usage monitoring';

-- Audit Database
CREATE DATABASE IF NOT EXISTS AUDIT_DB
    COMMENT = 'Audit trail and compliance';

-- DevOps Database
CREATE DATABASE IF NOT EXISTS DEVOPS_DB
    COMMENT = 'CI/CD deployment tracking';

-- Data Quality Database
CREATE DATABASE IF NOT EXISTS DATA_QUALITY_DB
    COMMENT = 'Data quality validation results';

-- ============================================================================
-- 4.3 CREATE SCHEMAS
-- ============================================================================

-- RAW_DB Schemas
CREATE SCHEMA IF NOT EXISTS RAW_DB.RAW_SCHEMA;
CREATE SCHEMA IF NOT EXISTS RAW_DB.STAGING_SCHEMA;
CREATE SCHEMA IF NOT EXISTS RAW_DB.LANDING_SCHEMA;

-- TRANSFORM_DB Schemas
CREATE SCHEMA IF NOT EXISTS TRANSFORM_DB.TRANSFORM_SCHEMA;
CREATE SCHEMA IF NOT EXISTS TRANSFORM_DB.CLEANSED_SCHEMA;

-- ANALYTICS_DB Schemas
CREATE SCHEMA IF NOT EXISTS ANALYTICS_DB.ANALYTICS_SCHEMA;
CREATE SCHEMA IF NOT EXISTS ANALYTICS_DB.REPORTING_SCHEMA;

-- AI_READY_DB Schemas
CREATE SCHEMA IF NOT EXISTS AI_READY_DB.AI_SCHEMA;
CREATE SCHEMA IF NOT EXISTS AI_READY_DB.FEATURE_STORE;
CREATE SCHEMA IF NOT EXISTS AI_READY_DB.SEMANTIC_MODELS;
CREATE SCHEMA IF NOT EXISTS AI_READY_DB.EMBEDDINGS;

-- MONITORING_DB Schemas
CREATE SCHEMA IF NOT EXISTS MONITORING_DB.MONITORING_SCHEMA;

-- AUDIT_DB Schemas
CREATE SCHEMA IF NOT EXISTS AUDIT_DB.AUDIT_SCHEMA;

-- DEVOPS_DB Schemas
CREATE SCHEMA IF NOT EXISTS DEVOPS_DB.CI_CD;

-- DATA_QUALITY_DB Schemas
CREATE SCHEMA IF NOT EXISTS DATA_QUALITY_DB.DQ_SCHEMA;

-- ============================================================================
-- 4.4 DATABASE GRANTS TO ROLES
-- ============================================================================

-- RAW_DB Grants
GRANT USAGE ON DATABASE RAW_DB TO ROLE HC_DATA_ENGINEER;
GRANT ALL PRIVILEGES ON SCHEMA RAW_DB.RAW_SCHEMA TO ROLE HC_DATA_ENGINEER;
GRANT ALL PRIVILEGES ON SCHEMA RAW_DB.STAGING_SCHEMA TO ROLE HC_DATA_ENGINEER;
GRANT USAGE ON DATABASE RAW_DB TO ROLE HC_ANALYST;
GRANT USAGE ON SCHEMA RAW_DB.RAW_SCHEMA TO ROLE HC_ANALYST;

-- TRANSFORM_DB Grants
GRANT USAGE ON DATABASE TRANSFORM_DB TO ROLE HC_DATA_ENGINEER;
GRANT ALL PRIVILEGES ON SCHEMA TRANSFORM_DB.TRANSFORM_SCHEMA TO ROLE HC_DATA_ENGINEER;
GRANT USAGE ON DATABASE TRANSFORM_DB TO ROLE HC_ANALYST;
GRANT USAGE ON SCHEMA TRANSFORM_DB.TRANSFORM_SCHEMA TO ROLE HC_ANALYST;

-- ANALYTICS_DB Grants
GRANT USAGE ON DATABASE ANALYTICS_DB TO ROLE HC_ANALYST;
GRANT ALL PRIVILEGES ON SCHEMA ANALYTICS_DB.ANALYTICS_SCHEMA TO ROLE HC_ANALYST;
GRANT USAGE ON DATABASE ANALYTICS_DB TO ROLE HC_DATA_ENGINEER;

-- AI_READY_DB Grants
GRANT USAGE ON DATABASE AI_READY_DB TO ROLE HC_DATA_SCIENTIST;
GRANT ALL PRIVILEGES ON SCHEMA AI_READY_DB.AI_SCHEMA TO ROLE HC_DATA_SCIENTIST;
GRANT ALL PRIVILEGES ON SCHEMA AI_READY_DB.FEATURE_STORE TO ROLE HC_DATA_SCIENTIST;
GRANT USAGE ON DATABASE AI_READY_DB TO ROLE HC_DATA_ENGINEER;

-- MONITORING_DB Grants
GRANT USAGE ON DATABASE MONITORING_DB TO ROLE HC_ACCOUNT_ADMIN;
GRANT USAGE ON SCHEMA MONITORING_DB.MONITORING_SCHEMA TO ROLE HC_ACCOUNT_ADMIN;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
SHOW DATABASES LIKE '%_DB';
SHOW SCHEMAS IN DATABASE RAW_DB;
SHOW SCHEMAS IN DATABASE AI_READY_DB;

-- ============================================================================
-- PHASE 4 COMPLETE
-- Databases Created: 8
--   - RAW_DB (Bronze)
--   - TRANSFORM_DB (Silver)
--   - ANALYTICS_DB (Gold)
--   - AI_READY_DB (Platinum)
--   - SECURITY_DB (Governance)
--   - MONITORING_DB (Performance)
--   - AUDIT_DB (Compliance)
--   - DEVOPS_DB (CI/CD)
-- Schemas Created: 15+
-- ============================================================================
