-- ============================================================================
-- PHASE 14: GITHUB CI/CD FRAMEWORK
-- Healthcare Enterprise Data Hub
-- Priority: HIGH - DevOps Automation
-- ============================================================================
-- Author: DEVIKAPG
-- Account: tyb42779
-- GitHub Workflow: .github/workflows/snowflake-deploy.yml
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

-- ============================================================================
-- STEP 1: CREATE DEVOPS DATABASE & SCHEMA
-- ============================================================================

CREATE DATABASE IF NOT EXISTS DEVOPS_DB COMMENT = 'CI/CD and Deployment Tracking';
CREATE SCHEMA IF NOT EXISTS DEVOPS_DB.CI_CD COMMENT = 'CI/CD Pipeline Objects';

USE DATABASE DEVOPS_DB;
USE SCHEMA CI_CD;

-- ============================================================================
-- STEP 2: DEPLOYMENT LOG TABLE
-- Tracks all deployment activities
-- ============================================================================

CREATE OR REPLACE TABLE DEPLOYMENT_LOG (
    DEPLOYMENT_ID STRING DEFAULT UUID_STRING(),
    DEPLOYMENT_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    EXECUTED_BY STRING DEFAULT CURRENT_USER(),
    ROLE_USED STRING DEFAULT CURRENT_ROLE(),
    SCRIPT_NAME STRING NOT NULL,
    PHASE_NUMBER FLOAT,
    STATUS STRING NOT NULL,
    ERROR_MESSAGE STRING,
    DURATION_MS FLOAT,
    ENVIRONMENT STRING DEFAULT 'PRODUCTION',
    GIT_COMMIT_HASH STRING,
    GIT_BRANCH STRING,
    AZURE_WORK_ITEM STRING,
    CONSTRAINT PK_DEPLOYMENT_LOG PRIMARY KEY (DEPLOYMENT_ID)
);

COMMENT ON TABLE DEPLOYMENT_LOG IS 'Tracks all CI/CD deployment activities';

-- ============================================================================
-- STEP 3: SCRIPT REGISTRY TABLE
-- Maintains inventory of all deployed scripts
-- ============================================================================

CREATE OR REPLACE TABLE SCRIPT_REGISTRY (
    SCRIPT_ID STRING DEFAULT UUID_STRING(),
    SCRIPT_NAME STRING NOT NULL,
    SCRIPT_VERSION STRING DEFAULT '1.0.0',
    PHASE_NUMBER FLOAT,
    DEPLOYED_ON TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DEPLOYED_BY STRING DEFAULT CURRENT_USER(),
    CHECKSUM STRING,
    DESCRIPTION STRING,
    IS_ACTIVE BOOLEAN DEFAULT TRUE,
    CONSTRAINT PK_SCRIPT_REGISTRY PRIMARY KEY (SCRIPT_ID)
);

COMMENT ON TABLE SCRIPT_REGISTRY IS 'Registry of all deployment scripts';

-- ============================================================================
-- STEP 4: DEPLOYMENT STORED PROCEDURE
-- ============================================================================

CREATE OR REPLACE PROCEDURE SP_DEPLOY_SQL(
    P_SCRIPT_NAME STRING,
    P_PHASE_NUMBER FLOAT,
    P_SQL_SCRIPT STRING,
    P_GIT_COMMIT STRING DEFAULT NULL,
    P_ENVIRONMENT STRING DEFAULT 'PRODUCTION'
)
RETURNS STRING
LANGUAGE JAVASCRIPT
EXECUTE AS CALLER
AS
$$
var start_time = Date.now();
try {
    // Execute the SQL script
    var stmt = snowflake.createStatement({sqlText: P_SQL_SCRIPT});
    stmt.execute();
    var duration = Date.now() - start_time;
    
    // Log successful deployment
    var log_stmt = snowflake.createStatement({
        sqlText: `INSERT INTO DEVOPS_DB.CI_CD.DEPLOYMENT_LOG 
                  (SCRIPT_NAME, PHASE_NUMBER, STATUS, DURATION_MS, ENVIRONMENT, GIT_COMMIT_HASH) 
                  VALUES (?, ?, 'SUCCESS', ?, ?, ?)`,
        binds: [P_SCRIPT_NAME, P_PHASE_NUMBER, duration, P_ENVIRONMENT, P_GIT_COMMIT]
    });
    log_stmt.execute();
    
    // Register the script
    var reg_stmt = snowflake.createStatement({
        sqlText: `INSERT INTO DEVOPS_DB.CI_CD.SCRIPT_REGISTRY 
                  (SCRIPT_NAME, PHASE_NUMBER, DESCRIPTION) 
                  VALUES (?, ?, 'Deployed via CI/CD')`,
        binds: [P_SCRIPT_NAME, P_PHASE_NUMBER]
    });
    reg_stmt.execute();
    
    return 'SUCCESS: Deployed in ' + duration + 'ms';
} catch(err) {
    var duration = Date.now() - start_time;
    
    // Log failed deployment
    var err_stmt = snowflake.createStatement({
        sqlText: `INSERT INTO DEVOPS_DB.CI_CD.DEPLOYMENT_LOG 
                  (SCRIPT_NAME, PHASE_NUMBER, STATUS, ERROR_MESSAGE, DURATION_MS, ENVIRONMENT) 
                  VALUES (?, ?, 'FAILED', ?, ?, ?)`,
        binds: [P_SCRIPT_NAME, P_PHASE_NUMBER, err.message, duration, P_ENVIRONMENT]
    });
    err_stmt.execute();
    
    return 'FAILED: ' + err.message;
}
$$;

-- ============================================================================
-- STEP 5: DEPLOYMENT SUMMARY VIEW
-- ============================================================================

CREATE OR REPLACE VIEW V_DEPLOYMENT_SUMMARY AS
SELECT
    DATE_TRUNC('DAY', DEPLOYMENT_TIMESTAMP) AS DEPLOY_DATE,
    ENVIRONMENT,
    COUNT(*) AS TOTAL_DEPLOYMENTS,
    SUM(CASE WHEN STATUS = 'SUCCESS' THEN 1 ELSE 0 END) AS SUCCESSFUL,
    SUM(CASE WHEN STATUS = 'FAILED' THEN 1 ELSE 0 END) AS FAILED,
    ROUND(100.0 * SUM(CASE WHEN STATUS = 'SUCCESS' THEN 1 ELSE 0 END) / COUNT(*), 2) AS SUCCESS_RATE,
    ROUND(AVG(DURATION_MS), 2) AS AVG_DURATION_MS
FROM DEPLOYMENT_LOG
GROUP BY DATE_TRUNC('DAY', DEPLOYMENT_TIMESTAMP), ENVIRONMENT
ORDER BY DEPLOY_DATE DESC;

-- ============================================================================
-- STEP 6: RECENT DEPLOYMENTS VIEW
-- ============================================================================

CREATE OR REPLACE VIEW V_RECENT_DEPLOYMENTS AS
SELECT
    DEPLOYMENT_ID,
    DEPLOYMENT_TIMESTAMP,
    EXECUTED_BY,
    SCRIPT_NAME,
    PHASE_NUMBER,
    STATUS,
    DURATION_MS,
    ENVIRONMENT,
    GIT_COMMIT_HASH,
    ERROR_MESSAGE
FROM DEPLOYMENT_LOG
ORDER BY DEPLOYMENT_TIMESTAMP DESC
LIMIT 100;

-- ============================================================================
-- STEP 7: REGISTER ALL 15 PHASES
-- ============================================================================

INSERT INTO SCRIPT_REGISTRY (SCRIPT_NAME, PHASE_NUMBER, DESCRIPTION) VALUES
    ('01_account_setup.sql', 1, 'Account Administration - Network, Password, Session Policies'),
    ('02_rbac_setup.sql', 2, 'RBAC Setup - 6 Healthcare Roles with Hierarchy'),
    ('03_warehouse_setup.sql', 3, 'Warehouse Management - 4 Workload-Specific Warehouses'),
    ('04_database_structure.sql', 4, 'Database Structure - RAW, TRANSFORM, ANALYTICS, AI_READY'),
    ('05_resource_monitors.sql', 5, 'Resource Monitors - Account + 4 Warehouse Monitors'),
    ('06_monitoring.sql', 6, 'Monitoring - 12 Consumption Insight Views'),
    ('07_alerts.sql', 7, 'Alerts - 10 Cost and Queue Alerts'),
    ('08_governance.sql', 8, 'Data Governance - Tags, 3 Masking, Row Access'),
    ('09_audit.sql', 9, 'Audit - Login, Grants, User Tracking Views'),
    ('10_verification.sql', 10, 'Verification - Test Scripts and Test Cases'),
    ('11_medallion.sql', 11, 'Medallion Architecture - Bronze to Platinum'),
    ('12_industry.sql', 12, 'Industry - Healthcare HCLS'),
    ('13_ai_ready.sql', 13, 'AI-Ready Layer - Feature Store, Embeddings, Semantic'),
    ('14_github_cicd.sql', 14, 'GitHub CI/CD - Workflows, Deployment Tracking'),
    ('15_azure_devops.sql', 15, 'Azure DevOps - Pipeline, Work Items');

-- Log initial deployment
INSERT INTO DEPLOYMENT_LOG (SCRIPT_NAME, PHASE_NUMBER, STATUS, DURATION_MS, ENVIRONMENT)
VALUES ('FULL_DEPLOYMENT', 0, 'SUCCESS', 0, 'PRODUCTION');

-- ============================================================================
-- STEP 8: VERIFICATION
-- ============================================================================

SELECT 'DEPLOYMENT_LOG' AS TABLE_NAME, COUNT(*) AS ROWS FROM DEPLOYMENT_LOG
UNION ALL SELECT 'SCRIPT_REGISTRY', COUNT(*) FROM SCRIPT_REGISTRY;

SELECT * FROM V_DEPLOYMENT_SUMMARY;

-- ============================================================================
-- PHASE 14: GITHUB CI/CD - COMPLETE
-- ============================================================================
-- Objects Created:
--   - DEVOPS_DB.CI_CD.DEPLOYMENT_LOG
--   - DEVOPS_DB.CI_CD.SCRIPT_REGISTRY
--   - DEVOPS_DB.CI_CD.SP_DEPLOY_SQL (Stored Procedure)
--   - DEVOPS_DB.CI_CD.V_DEPLOYMENT_SUMMARY (View)
--   - DEVOPS_DB.CI_CD.V_RECENT_DEPLOYMENTS (View)
-- ============================================================================
