-- ============================================================================
-- PHASE 3: WAREHOUSE MANAGEMENT
-- Healthcare Enterprise Data Hub
-- ============================================================================
-- Objectives: Create 4 workload-specific warehouses
-- Role Required: ACCOUNTADMIN
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- 3.1 ETL WAREHOUSE
-- Purpose: Data ingestion and extraction workloads
-- ============================================================================
CREATE WAREHOUSE IF NOT EXISTS HC_ETL_WH
    WAREHOUSE_SIZE = 'XSMALL'
    WAREHOUSE_TYPE = 'STANDARD'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 1
    SCALING_POLICY = 'STANDARD'
    COMMENT = 'Healthcare ETL and data ingestion workloads';

-- ============================================================================
-- 3.2 TRANSFORM WAREHOUSE
-- Purpose: Data transformation and processing
-- ============================================================================
CREATE WAREHOUSE IF NOT EXISTS HC_TRANSFORM_WH
    WAREHOUSE_SIZE = 'XSMALL'
    WAREHOUSE_TYPE = 'STANDARD'
    AUTO_SUSPEND = 120
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 2
    SCALING_POLICY = 'STANDARD'
    COMMENT = 'Healthcare data transformation workloads';

-- ============================================================================
-- 3.3 ANALYTICS WAREHOUSE
-- Purpose: BI, reporting, and analytics queries
-- ============================================================================
CREATE WAREHOUSE IF NOT EXISTS HC_ANALYTICS_WH
    WAREHOUSE_SIZE = 'XSMALL'
    WAREHOUSE_TYPE = 'STANDARD'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 2
    SCALING_POLICY = 'ECONOMY'
    COMMENT = 'Healthcare analytics and BI workloads';

-- ============================================================================
-- 3.4 AI WAREHOUSE
-- Purpose: ML/AI workloads, model training, feature engineering
-- ============================================================================
CREATE WAREHOUSE IF NOT EXISTS HC_AI_WH
    WAREHOUSE_SIZE = 'XSMALL'
    WAREHOUSE_TYPE = 'STANDARD'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 1
    SCALING_POLICY = 'STANDARD'
    COMMENT = 'Healthcare ML and AI workloads';

-- ============================================================================
-- 3.5 WAREHOUSE GRANTS TO ROLES
-- ============================================================================

-- ETL Warehouse
GRANT USAGE ON WAREHOUSE HC_ETL_WH TO ROLE HC_DATA_ENGINEER;
GRANT OPERATE ON WAREHOUSE HC_ETL_WH TO ROLE HC_DATA_ENGINEER;
GRANT USAGE ON WAREHOUSE HC_ETL_WH TO ROLE HC_ACCOUNT_ADMIN;

-- Transform Warehouse
GRANT USAGE ON WAREHOUSE HC_TRANSFORM_WH TO ROLE HC_DATA_ENGINEER;
GRANT OPERATE ON WAREHOUSE HC_TRANSFORM_WH TO ROLE HC_DATA_ENGINEER;
GRANT USAGE ON WAREHOUSE HC_TRANSFORM_WH TO ROLE HC_ACCOUNT_ADMIN;

-- Analytics Warehouse
GRANT USAGE ON WAREHOUSE HC_ANALYTICS_WH TO ROLE HC_ANALYST;
GRANT USAGE ON WAREHOUSE HC_ANALYTICS_WH TO ROLE HC_DATA_ENGINEER;
GRANT USAGE ON WAREHOUSE HC_ANALYTICS_WH TO ROLE HC_ACCOUNT_ADMIN;

-- AI Warehouse
GRANT USAGE ON WAREHOUSE HC_AI_WH TO ROLE HC_DATA_SCIENTIST;
GRANT OPERATE ON WAREHOUSE HC_AI_WH TO ROLE HC_DATA_SCIENTIST;
GRANT ALL ON WAREHOUSE HC_AI_WH TO ROLE HC_ACCOUNT_ADMIN;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
SHOW WAREHOUSES LIKE 'HC_%';

-- Check warehouse grants
SHOW GRANTS ON WAREHOUSE HC_ETL_WH;
SHOW GRANTS ON WAREHOUSE HC_ANALYTICS_WH;

-- ============================================================================
-- PHASE 3 COMPLETE
-- Warehouses Created: 4
--   - HC_ETL_WH (Data Ingestion)
--   - HC_TRANSFORM_WH (Data Processing)
--   - HC_ANALYTICS_WH (BI/Reporting)
--   - HC_AI_WH (ML/AI Workloads)
-- ============================================================================
