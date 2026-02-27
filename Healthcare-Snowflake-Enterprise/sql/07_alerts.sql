-- ============================================================================
-- PHASE 7: ALERTS (10+ Automated Alerts)
-- Healthcare Enterprise Data Hub
-- ============================================================================
-- Objectives: Create automated alerts for cost, performance, and healthcare
-- Role Required: ACCOUNTADMIN
-- Note: Email notifications require email integration setup
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE MONITORING_DB;
USE SCHEMA MONITORING_SCHEMA;

-- ============================================================================
-- 7.1 HIGH CREDIT USAGE ALERT
-- Triggers when daily credit usage exceeds threshold
-- ============================================================================
CREATE OR REPLACE ALERT HC_ALERT_HIGH_CREDITS
    WAREHOUSE = HC_ANALYTICS_WH
    SCHEDULE = 'USING CRON 0 8 * * * UTC'
    IF (EXISTS(
        SELECT 1
        FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -1, CURRENT_DATE)
        HAVING SUM(CREDITS_USED) > 20
    ))
    THEN CALL SYSTEM$SEND_EMAIL(
        'healthcare_alerts',
        'High Credit Usage Alert',
        'Daily credit usage exceeded 20 credits threshold.'
    );

-- ============================================================================
-- 7.2 FAILED LOGIN ALERT
-- Triggers on multiple failed login attempts
-- ============================================================================
CREATE OR REPLACE ALERT HC_ALERT_FAILED_LOGINS
    WAREHOUSE = HC_ANALYTICS_WH
    SCHEDULE = 'USING CRON */30 * * * * UTC'
    IF (EXISTS(
        SELECT 1
        FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
        WHERE IS_SUCCESS = 'NO'
            AND EVENT_TIMESTAMP >= DATEADD(HOUR, -1, CURRENT_TIMESTAMP)
        HAVING COUNT(*) > 5
    ))
    THEN CALL SYSTEM$SEND_EMAIL(
        'healthcare_alerts',
        'Security Alert: Failed Logins',
        'More than 5 failed login attempts in the past hour.'
    );

-- ============================================================================
-- 7.3 LONG RUNNING QUERY ALERT
-- Triggers when queries exceed 30 minutes
-- ============================================================================
CREATE OR REPLACE ALERT HC_ALERT_LONG_QUERY
    WAREHOUSE = HC_ANALYTICS_WH
    SCHEDULE = 'USING CRON */15 * * * * UTC'
    IF (EXISTS(
        SELECT 1
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE TOTAL_ELAPSED_TIME > 1800000
            AND START_TIME >= DATEADD(HOUR, -1, CURRENT_TIMESTAMP)
            AND EXECUTION_STATUS = 'RUNNING'
    ))
    THEN CALL SYSTEM$SEND_EMAIL(
        'healthcare_alerts',
        'Long Running Query Alert',
        'A query has been running for more than 30 minutes.'
    );

-- ============================================================================
-- 7.4 WAREHOUSE QUEUE ALERT
-- Triggers when queries are queuing
-- ============================================================================
CREATE OR REPLACE ALERT HC_ALERT_QUEUE_TIME
    WAREHOUSE = HC_ANALYTICS_WH
    SCHEDULE = 'USING CRON */10 * * * * UTC'
    IF (EXISTS(
        SELECT 1
        FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
        WHERE AVG_QUEUED_LOAD > 5
            AND START_TIME >= DATEADD(HOUR, -1, CURRENT_TIMESTAMP)
    ))
    THEN CALL SYSTEM$SEND_EMAIL(
        'healthcare_alerts',
        'Warehouse Queue Alert',
        'High query queue detected. Consider scaling warehouse.'
    );

-- ============================================================================
-- 7.5 STORAGE GROWTH ALERT
-- Triggers when database exceeds size threshold
-- ============================================================================
CREATE OR REPLACE ALERT HC_ALERT_STORAGE_GROWTH
    WAREHOUSE = HC_ANALYTICS_WH
    SCHEDULE = 'USING CRON 0 6 * * * UTC'
    IF (EXISTS(
        SELECT 1
        FROM SNOWFLAKE.ACCOUNT_USAGE.DATABASE_STORAGE_USAGE_HISTORY
        WHERE USAGE_DATE = CURRENT_DATE()
            AND AVERAGE_DATABASE_BYTES > 10737418240  -- 10GB
    ))
    THEN CALL SYSTEM$SEND_EMAIL(
        'healthcare_alerts',
        'Storage Growth Alert',
        'A database has exceeded 10GB storage threshold.'
    );

-- ============================================================================
-- 7.6 ICU CRITICAL PATIENT ALERT
-- Healthcare-specific: High-risk patients detected
-- ============================================================================
CREATE OR REPLACE ALERT HC_ALERT_ICU_CRITICAL
    WAREHOUSE = HC_AI_WH
    SCHEDULE = 'USING CRON */5 * * * * UTC'
    IF (EXISTS(
        SELECT 1
        FROM AI_READY_DB.AI_SCHEMA.ICU_FEATURE_STORE
        WHERE RISK_SCORE >= 4
    ))
    THEN CALL SYSTEM$SEND_EMAIL(
        'healthcare_alerts',
        'ICU Critical Patient Alert',
        'Critical risk patients detected (Risk Score >= 4).'
    );

-- ============================================================================
-- 7.7 BILLING OVERDUE ALERT
-- Healthcare-specific: Overdue bills threshold
-- ============================================================================
CREATE OR REPLACE ALERT HC_ALERT_BILLING_OVERDUE
    WAREHOUSE = HC_ANALYTICS_WH
    SCHEDULE = 'USING CRON 0 9 * * * UTC'
    IF (EXISTS(
        SELECT 1
        FROM RAW_DB.RAW_SCHEMA.BILLING_DATA
        WHERE PAYMENT_STATUS = 'OVERDUE'
        HAVING COUNT(*) > 100
    ))
    THEN CALL SYSTEM$SEND_EMAIL(
        'healthcare_alerts',
        'Billing Alert: Overdue Payments',
        'More than 100 overdue bills detected.'
    );

-- ============================================================================
-- 7.8 DEVICE HIGH SEVERITY ALERT
-- Healthcare-specific: Device alert monitoring
-- ============================================================================
CREATE OR REPLACE ALERT HC_ALERT_DEVICE_SEVERITY
    WAREHOUSE = HC_AI_WH
    SCHEDULE = 'USING CRON */5 * * * * UTC'
    IF (EXISTS(
        SELECT 1
        FROM RAW_DB.RAW_SCHEMA.DEVICE_ALERTS
        WHERE SEVERITY = 'HIGH'
            AND ALERT_TIMESTAMP >= DATEADD(MINUTE, -10, CURRENT_TIMESTAMP)
    ))
    THEN CALL SYSTEM$SEND_EMAIL(
        'healthcare_alerts',
        'Device Alert: High Severity',
        'High severity device alerts detected in last 10 minutes.'
    );

-- ============================================================================
-- 7.9 ETL FAILURE ALERT
-- Monitors data pipeline failures
-- ============================================================================
CREATE OR REPLACE ALERT HC_ALERT_ETL_FAILURE
    WAREHOUSE = HC_ETL_WH
    SCHEDULE = 'USING CRON */30 * * * * UTC'
    IF (EXISTS(
        SELECT 1
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE QUERY_TEXT ILIKE '%COPY INTO%'
            AND ERROR_CODE IS NOT NULL
            AND START_TIME >= DATEADD(HOUR, -1, CURRENT_TIMESTAMP)
    ))
    THEN CALL SYSTEM$SEND_EMAIL(
        'healthcare_alerts',
        'ETL Failure Alert',
        'Data load (COPY INTO) failed in the past hour.'
    );

-- ============================================================================
-- 7.10 CONCURRENT QUERY ALERT
-- High concurrency detection
-- ============================================================================
CREATE OR REPLACE ALERT HC_ALERT_CONCURRENT_QUERIES
    WAREHOUSE = HC_ANALYTICS_WH
    SCHEDULE = 'USING CRON */10 * * * * UTC'
    IF (EXISTS(
        SELECT 1
        FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
        WHERE AVG_RUNNING > 10
            AND START_TIME >= DATEADD(HOUR, -1, CURRENT_TIMESTAMP)
    ))
    THEN CALL SYSTEM$SEND_EMAIL(
        'healthcare_alerts',
        'High Concurrency Alert',
        'High number of concurrent queries detected.'
    );

-- ============================================================================
-- 7.11 RESOURCE MONITOR THRESHOLD ALERT
-- Monitors credit quota usage
-- ============================================================================
CREATE OR REPLACE ALERT HC_ALERT_RESOURCE_MONITOR
    WAREHOUSE = HC_ANALYTICS_WH
    SCHEDULE = 'USING CRON 0 */6 * * * UTC'
    IF (EXISTS(
        SELECT 1
        FROM TABLE(INFORMATION_SCHEMA.RESOURCE_MONITORS())
        WHERE USED_CREDITS / NULLIF(CREDIT_QUOTA, 0) > 0.75
    ))
    THEN CALL SYSTEM$SEND_EMAIL(
        'healthcare_alerts',
        'Resource Monitor Alert',
        'A resource monitor has exceeded 75% of quota.'
    );

-- ============================================================================
-- ENABLE ALERTS (Uncomment when email integration is configured)
-- ============================================================================
-- ALTER ALERT HC_ALERT_HIGH_CREDITS RESUME;
-- ALTER ALERT HC_ALERT_FAILED_LOGINS RESUME;
-- ALTER ALERT HC_ALERT_LONG_QUERY RESUME;
-- ALTER ALERT HC_ALERT_QUEUE_TIME RESUME;
-- ALTER ALERT HC_ALERT_STORAGE_GROWTH RESUME;
-- ALTER ALERT HC_ALERT_ICU_CRITICAL RESUME;
-- ALTER ALERT HC_ALERT_BILLING_OVERDUE RESUME;
-- ALTER ALERT HC_ALERT_DEVICE_SEVERITY RESUME;
-- ALTER ALERT HC_ALERT_ETL_FAILURE RESUME;
-- ALTER ALERT HC_ALERT_CONCURRENT_QUERIES RESUME;
-- ALTER ALERT HC_ALERT_RESOURCE_MONITOR RESUME;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
SHOW ALERTS LIKE 'HC_ALERT_%';

-- ============================================================================
-- PHASE 7 COMPLETE
-- Alerts Created: 11
--   Cost Alerts: HIGH_CREDITS, RESOURCE_MONITOR
--   Security Alerts: FAILED_LOGINS
--   Performance Alerts: LONG_QUERY, QUEUE_TIME, CONCURRENT_QUERIES
--   Storage Alerts: STORAGE_GROWTH
--   Healthcare Alerts: ICU_CRITICAL, BILLING_OVERDUE, DEVICE_SEVERITY
--   Pipeline Alerts: ETL_FAILURE
-- ============================================================================
