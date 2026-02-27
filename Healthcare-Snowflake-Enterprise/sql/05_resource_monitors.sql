-- ============================================================================
-- PHASE 5: RESOURCE MONITORS
-- Healthcare Enterprise Data Hub
-- ============================================================================
-- Objectives: Account and warehouse-level credit monitoring
-- Role Required: ACCOUNTADMIN
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- 5.1 ACCOUNT-LEVEL RESOURCE MONITOR
-- Monitors overall account credit consumption
-- ============================================================================
CREATE OR REPLACE RESOURCE MONITOR HC_ACCOUNT_MONITOR
    WITH CREDIT_QUOTA = 100
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS
        ON 50 PERCENT DO NOTIFY
        ON 75 PERCENT DO NOTIFY
        ON 90 PERCENT DO NOTIFY
        ON 100 PERCENT DO SUSPEND;

-- ============================================================================
-- 5.2 ETL WAREHOUSE MONITOR
-- ============================================================================
CREATE OR REPLACE RESOURCE MONITOR HC_ETL_WH_MONITOR
    WITH CREDIT_QUOTA = 25
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS
        ON 75 PERCENT DO NOTIFY
        ON 90 PERCENT DO NOTIFY
        ON 100 PERCENT DO SUSPEND;

ALTER WAREHOUSE HC_ETL_WH SET RESOURCE_MONITOR = HC_ETL_WH_MONITOR;

-- ============================================================================
-- 5.3 TRANSFORM WAREHOUSE MONITOR
-- ============================================================================
CREATE OR REPLACE RESOURCE MONITOR HC_TRANSFORM_WH_MONITOR
    WITH CREDIT_QUOTA = 35
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS
        ON 75 PERCENT DO NOTIFY
        ON 90 PERCENT DO NOTIFY
        ON 100 PERCENT DO SUSPEND;

ALTER WAREHOUSE HC_TRANSFORM_WH SET RESOURCE_MONITOR = HC_TRANSFORM_WH_MONITOR;

-- ============================================================================
-- 5.4 ANALYTICS WAREHOUSE MONITOR
-- ============================================================================
CREATE OR REPLACE RESOURCE MONITOR HC_ANALYTICS_WH_MONITOR
    WITH CREDIT_QUOTA = 20
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS
        ON 75 PERCENT DO NOTIFY
        ON 90 PERCENT DO NOTIFY
        ON 100 PERCENT DO SUSPEND;

ALTER WAREHOUSE HC_ANALYTICS_WH SET RESOURCE_MONITOR = HC_ANALYTICS_WH_MONITOR;

-- ============================================================================
-- 5.5 AI WAREHOUSE MONITOR
-- ============================================================================
CREATE OR REPLACE RESOURCE MONITOR HC_AI_WH_MONITOR
    WITH CREDIT_QUOTA = 50
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS
        ON 75 PERCENT DO NOTIFY
        ON 90 PERCENT DO NOTIFY
        ON 100 PERCENT DO SUSPEND;

ALTER WAREHOUSE HC_AI_WH SET RESOURCE_MONITOR = HC_AI_WH_MONITOR;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
SHOW RESOURCE MONITORS LIKE 'HC_%';

-- Check monitor assignments
SELECT 
    WAREHOUSE_NAME,
    RESOURCE_MONITOR 
FROM TABLE(INFORMATION_SCHEMA.WAREHOUSES())
WHERE WAREHOUSE_NAME LIKE 'HC_%';

-- ============================================================================
-- PHASE 5 COMPLETE
-- Resource Monitors Created: 5
--   - HC_ACCOUNT_MONITOR (100 credits)
--   - HC_ETL_WH_MONITOR (25 credits)
--   - HC_TRANSFORM_WH_MONITOR (35 credits)
--   - HC_ANALYTICS_WH_MONITOR (20 credits)
--   - HC_AI_WH_MONITOR (50 credits)
-- ============================================================================
