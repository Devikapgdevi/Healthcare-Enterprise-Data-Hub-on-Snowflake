-- ============================================================================
-- PHASE 6: MONITORING VIEWS (10+ Consumption Insight Views)
-- Healthcare Enterprise Data Hub
-- ============================================================================
-- Objectives: Create monitoring views for performance and cost tracking
-- Role Required: ACCOUNTADMIN
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE MONITORING_DB;
USE SCHEMA MONITORING_SCHEMA;

-- ============================================================================
-- 6.1 QUERY PERFORMANCE VIEW
-- ============================================================================
CREATE OR REPLACE VIEW V_QUERY_PERFORMANCE AS
SELECT
    QUERY_ID,
    QUERY_TEXT,
    USER_NAME,
    ROLE_NAME,
    WAREHOUSE_NAME,
    WAREHOUSE_SIZE,
    EXECUTION_STATUS,
    ERROR_CODE,
    ERROR_MESSAGE,
    START_TIME,
    END_TIME,
    TOTAL_ELAPSED_TIME / 1000 AS DURATION_SECONDS,
    BYTES_SCANNED / (1024*1024*1024) AS GB_SCANNED,
    ROWS_PRODUCED,
    COMPILATION_TIME / 1000 AS COMPILE_SECONDS,
    EXECUTION_TIME / 1000 AS EXEC_SECONDS,
    QUEUED_OVERLOAD_TIME / 1000 AS QUEUE_SECONDS,
    CREDITS_USED_CLOUD_SERVICES
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE START_TIME >= DATEADD(DAY, -30, CURRENT_DATE);

-- ============================================================================
-- 6.2 WAREHOUSE CREDIT USAGE VIEW
-- ============================================================================
CREATE OR REPLACE VIEW V_WAREHOUSE_CREDIT_USAGE AS
SELECT
    WAREHOUSE_NAME,
    DATE_TRUNC('DAY', START_TIME) AS USAGE_DATE,
    SUM(CREDITS_USED) AS TOTAL_CREDITS,
    SUM(CREDITS_USED_COMPUTE) AS COMPUTE_CREDITS,
    SUM(CREDITS_USED_CLOUD_SERVICES) AS CLOUD_CREDITS,
    COUNT(*) AS QUERY_COUNT
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE START_TIME >= DATEADD(DAY, -30, CURRENT_DATE)
GROUP BY WAREHOUSE_NAME, DATE_TRUNC('DAY', START_TIME)
ORDER BY USAGE_DATE DESC, TOTAL_CREDITS DESC;

-- ============================================================================
-- 6.3 DAILY CREDIT SUMMARY VIEW
-- ============================================================================
CREATE OR REPLACE VIEW V_DAILY_CREDIT_SUMMARY AS
SELECT
    DATE_TRUNC('DAY', START_TIME) AS USAGE_DATE,
    SUM(CREDITS_USED) AS TOTAL_CREDITS,
    COUNT(DISTINCT WAREHOUSE_NAME) AS WAREHOUSES_USED,
    ROUND(AVG(CREDITS_USED), 4) AS AVG_CREDITS_PER_QUERY
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE START_TIME >= DATEADD(DAY, -30, CURRENT_DATE)
GROUP BY DATE_TRUNC('DAY', START_TIME)
ORDER BY USAGE_DATE DESC;

-- ============================================================================
-- 6.4 LOGIN HISTORY VIEW
-- ============================================================================
CREATE OR REPLACE VIEW V_LOGIN_HISTORY AS
SELECT
    EVENT_TIMESTAMP,
    USER_NAME,
    CLIENT_IP,
    REPORTED_CLIENT_TYPE,
    REPORTED_CLIENT_VERSION,
    FIRST_AUTHENTICATION_FACTOR,
    SECOND_AUTHENTICATION_FACTOR,
    IS_SUCCESS,
    ERROR_CODE,
    ERROR_MESSAGE
FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
WHERE EVENT_TIMESTAMP >= DATEADD(DAY, -30, CURRENT_DATE)
ORDER BY EVENT_TIMESTAMP DESC;

-- ============================================================================
-- 6.5 FAILED LOGINS VIEW
-- ============================================================================
CREATE OR REPLACE VIEW V_FAILED_LOGINS AS
SELECT
    EVENT_TIMESTAMP,
    USER_NAME,
    CLIENT_IP,
    REPORTED_CLIENT_TYPE,
    ERROR_CODE,
    ERROR_MESSAGE
FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
WHERE IS_SUCCESS = 'NO'
    AND EVENT_TIMESTAMP >= DATEADD(DAY, -7, CURRENT_DATE)
ORDER BY EVENT_TIMESTAMP DESC;

-- ============================================================================
-- 6.6 LONG RUNNING QUERIES VIEW
-- ============================================================================
CREATE OR REPLACE VIEW V_LONG_RUNNING_QUERIES AS
SELECT
    QUERY_ID,
    USER_NAME,
    ROLE_NAME,
    WAREHOUSE_NAME,
    QUERY_TEXT,
    START_TIME,
    TOTAL_ELAPSED_TIME / 1000 AS DURATION_SECONDS,
    TOTAL_ELAPSED_TIME / 60000 AS DURATION_MINUTES,
    EXECUTION_STATUS
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE TOTAL_ELAPSED_TIME > 300000  -- > 5 minutes
    AND START_TIME >= DATEADD(DAY, -7, CURRENT_DATE)
ORDER BY TOTAL_ELAPSED_TIME DESC;

-- ============================================================================
-- 6.7 FAILED QUERIES VIEW
-- ============================================================================
CREATE OR REPLACE VIEW V_FAILED_QUERIES AS
SELECT
    QUERY_ID,
    USER_NAME,
    ROLE_NAME,
    WAREHOUSE_NAME,
    QUERY_TEXT,
    ERROR_CODE,
    ERROR_MESSAGE,
    START_TIME
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE ERROR_CODE IS NOT NULL
    AND START_TIME >= DATEADD(DAY, -7, CURRENT_DATE)
ORDER BY START_TIME DESC;

-- ============================================================================
-- 6.8 STORAGE USAGE VIEW
-- ============================================================================
CREATE OR REPLACE VIEW V_STORAGE_USAGE AS
SELECT
    USAGE_DATE,
    DATABASE_NAME,
    AVERAGE_DATABASE_BYTES / (1024*1024*1024) AS AVG_SIZE_GB,
    AVERAGE_FAILSAFE_BYTES / (1024*1024*1024) AS FAILSAFE_GB
FROM SNOWFLAKE.ACCOUNT_USAGE.DATABASE_STORAGE_USAGE_HISTORY
WHERE USAGE_DATE >= DATEADD(DAY, -30, CURRENT_DATE)
ORDER BY USAGE_DATE DESC, AVG_SIZE_GB DESC;

-- ============================================================================
-- 6.9 WAREHOUSE LOAD HISTORY VIEW
-- ============================================================================
CREATE OR REPLACE VIEW V_WAREHOUSE_LOAD AS
SELECT
    WAREHOUSE_NAME,
    START_TIME,
    END_TIME,
    AVG_RUNNING,
    AVG_QUEUED_LOAD,
    AVG_QUEUED_PROVISIONING,
    AVG_BLOCKED
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_DATE)
ORDER BY START_TIME DESC;

-- ============================================================================
-- 6.10 USER QUERY STATISTICS VIEW
-- ============================================================================
CREATE OR REPLACE VIEW V_USER_QUERY_STATS AS
SELECT
    USER_NAME,
    COUNT(*) AS TOTAL_QUERIES,
    SUM(CASE WHEN EXECUTION_STATUS = 'SUCCESS' THEN 1 ELSE 0 END) AS SUCCESSFUL_QUERIES,
    SUM(CASE WHEN EXECUTION_STATUS != 'SUCCESS' THEN 1 ELSE 0 END) AS FAILED_QUERIES,
    ROUND(AVG(TOTAL_ELAPSED_TIME) / 1000, 2) AS AVG_DURATION_SECONDS,
    ROUND(SUM(CREDITS_USED_CLOUD_SERVICES), 4) AS TOTAL_CREDITS,
    MAX(START_TIME) AS LAST_QUERY_TIME
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE START_TIME >= DATEADD(DAY, -30, CURRENT_DATE)
GROUP BY USER_NAME
ORDER BY TOTAL_QUERIES DESC;

-- ============================================================================
-- 6.11 COPY/LOAD HISTORY VIEW
-- ============================================================================
CREATE OR REPLACE VIEW V_COPY_HISTORY AS
SELECT
    TABLE_NAME,
    FILE_NAME,
    STAGE_LOCATION,
    LAST_LOAD_TIME,
    ROW_COUNT,
    FILE_SIZE / (1024*1024) AS FILE_SIZE_MB,
    STATUS,
    FIRST_ERROR_MESSAGE
FROM SNOWFLAKE.ACCOUNT_USAGE.COPY_HISTORY
WHERE LAST_LOAD_TIME >= DATEADD(DAY, -30, CURRENT_DATE)
ORDER BY LAST_LOAD_TIME DESC;

-- ============================================================================
-- 6.12 CREDIT USAGE TREND VIEW
-- ============================================================================
CREATE OR REPLACE VIEW V_CREDIT_TREND AS
SELECT
    DATE_TRUNC('WEEK', START_TIME) AS WEEK_START,
    WAREHOUSE_NAME,
    SUM(CREDITS_USED) AS WEEKLY_CREDITS,
    COUNT(*) AS QUERY_COUNT
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE START_TIME >= DATEADD(MONTH, -3, CURRENT_DATE)
GROUP BY DATE_TRUNC('WEEK', START_TIME), WAREHOUSE_NAME
ORDER BY WEEK_START DESC;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
SHOW VIEWS IN SCHEMA MONITORING_DB.MONITORING_SCHEMA;

-- Test views
SELECT * FROM V_DAILY_CREDIT_SUMMARY LIMIT 5;
SELECT * FROM V_USER_QUERY_STATS LIMIT 5;

-- ============================================================================
-- PHASE 6 COMPLETE
-- Monitoring Views Created: 12
--   - V_QUERY_PERFORMANCE
--   - V_WAREHOUSE_CREDIT_USAGE
--   - V_DAILY_CREDIT_SUMMARY
--   - V_LOGIN_HISTORY
--   - V_FAILED_LOGINS
--   - V_LONG_RUNNING_QUERIES
--   - V_FAILED_QUERIES
--   - V_STORAGE_USAGE
--   - V_WAREHOUSE_LOAD
--   - V_USER_QUERY_STATS
--   - V_COPY_HISTORY
--   - V_CREDIT_TREND
-- ============================================================================
