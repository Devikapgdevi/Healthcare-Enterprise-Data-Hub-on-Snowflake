-- ============================================================================
-- PHASE 15: AZURE DEVOPS INTEGRATION
-- Healthcare Enterprise Data Hub
-- Priority: HIGH - Enterprise DevOps
-- ============================================================================
-- Author: DEVIKAPG
-- Account: tyb42779
-- Azure DevOps: https://dev.azure.com/ArisData1/Snowflake
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE DEVOPS_DB;
USE SCHEMA CI_CD;

-- ============================================================================
-- STEP 1: AZURE DEVOPS WORK ITEMS TABLE
-- Tracks work items from Azure DevOps
-- ============================================================================

CREATE OR REPLACE TABLE AZURE_WORK_ITEMS (
    WORK_ITEM_ID STRING NOT NULL,
    WORK_ITEM_TYPE STRING NOT NULL,  -- Epic, User Story, Task, Bug
    TITLE STRING NOT NULL,
    STATE STRING,  -- New, Active, Resolved, Closed
    ASSIGNED_TO STRING,
    ITERATION_PATH STRING,
    AREA_PATH STRING,
    PRIORITY NUMBER,
    PHASE_NUMBER FLOAT,
    CREATED_DATE TIMESTAMP_NTZ,
    CLOSED_DATE TIMESTAMP_NTZ,
    DESCRIPTION STRING,
    SNOWFLAKE_OBJECT STRING,  -- Related Snowflake object
    CONSTRAINT PK_AZURE_WORK_ITEMS PRIMARY KEY (WORK_ITEM_ID)
);

COMMENT ON TABLE AZURE_WORK_ITEMS IS 'Azure DevOps work items linked to Snowflake deployments';

-- ============================================================================
-- STEP 2: INSERT EPICS FOR ALL 15 PHASES
-- ============================================================================

INSERT INTO AZURE_WORK_ITEMS (WORK_ITEM_ID, WORK_ITEM_TYPE, TITLE, STATE, PRIORITY, PHASE_NUMBER, DESCRIPTION, SNOWFLAKE_OBJECT) VALUES
-- Epics
('EPIC-001', 'Epic', 'Phase 1: Account Administration', 'Closed', 1, 1, 'Network policies, security settings', 'SECURITY_DB'),
('EPIC-002', 'Epic', 'Phase 2: RBAC Setup', 'Closed', 1, 2, '5+ roles with hierarchy', 'HC_% Roles'),
('EPIC-003', 'Epic', 'Phase 3: Warehouse Management', 'Closed', 1, 3, '4 workload-specific warehouses', 'HC_%_WH'),
('EPIC-004', 'Epic', 'Phase 4: Database Structure', 'Closed', 1, 4, 'RAW, TRANSFORM, ANALYTICS, AI_READY', '*_DB'),
('EPIC-005', 'Epic', 'Phase 5: Resource Monitors', 'Closed', 2, 5, 'Account + per-warehouse monitors', 'HC_%_MONITOR'),
('EPIC-006', 'Epic', 'Phase 6: Monitoring', 'Closed', 2, 6, '10+ consumption insight views', 'MONITORING_DB'),
('EPIC-007', 'Epic', 'Phase 7: Alerts', 'Closed', 2, 7, 'Cost and queue alerts', 'HC_ALERT_%'),
('EPIC-008', 'Epic', 'Phase 8: Data Governance', 'Closed', 1, 8, 'Tags, masking, row access', 'SECURITY_DB.SECURITY_SCHEMA'),
('EPIC-009', 'Epic', 'Phase 9: Audit', 'Closed', 2, 9, 'Login, grants, user tracking', 'AUDIT_DB'),
('EPIC-010', 'Epic', 'Phase 10: Verification', 'Closed', 2, 10, 'Test scripts and cases', 'DATA_QUALITY_DB'),
('EPIC-011', 'Epic', 'Phase 11: Medallion Architecture', 'Closed', 1, 11, 'RAW → TRANSFORM → ANALYTICS → AI_READY', 'All *_DB'),
('EPIC-012', 'Epic', 'Phase 12: Healthcare Industry', 'Closed', 2, 12, 'HCLS domain implementation', 'All Tables'),
('EPIC-013', 'Epic', 'Phase 13: AI-Ready Layer', 'Closed', 1, 13, 'Feature store, embeddings, semantic', 'AI_READY_DB'),
('EPIC-014', 'Epic', 'Phase 14: GitHub CI/CD', 'Closed', 1, 14, 'Workflows, deployment tracking', 'DEVOPS_DB.CI_CD'),
('EPIC-015', 'Epic', 'Phase 15: Azure DevOps', 'Closed', 1, 15, 'Pipeline, work items', 'DEVOPS_DB.CI_CD');

-- ============================================================================
-- STEP 3: INSERT USER STORIES
-- ============================================================================

INSERT INTO AZURE_WORK_ITEMS (WORK_ITEM_ID, WORK_ITEM_TYPE, TITLE, STATE, PRIORITY, PHASE_NUMBER, DESCRIPTION) VALUES
-- Phase 1 User Stories
('US-101', 'User Story', 'Configure network policies', 'Closed', 1, 1, 'As a Security Admin, I need network policies configured'),
('US-102', 'User Story', 'Set up password policies', 'Closed', 1, 1, 'As a Security Admin, I need password policies enforced'),

-- Phase 2 User Stories
('US-201', 'User Story', 'Create healthcare roles', 'Closed', 1, 2, 'As an Admin, I need 6 healthcare-specific roles'),
('US-202', 'User Story', 'Establish role hierarchy', 'Closed', 1, 2, 'As an Admin, I need proper role hierarchy'),

-- Phase 11 User Stories
('US-1101', 'User Story', 'Create Bronze layer', 'Closed', 1, 11, 'As a Data Engineer, I need raw data tables'),
('US-1102', 'User Story', 'Create Silver layer', 'Closed', 1, 11, 'As a Data Engineer, I need cleaned data tables'),
('US-1103', 'User Story', 'Create Gold layer', 'Closed', 1, 11, 'As an Analyst, I need aggregated analytics tables'),

-- Phase 13 User Stories
('US-1301', 'User Story', 'Create Feature Store', 'Closed', 1, 13, 'As a Data Scientist, I need ML features'),
('US-1302', 'User Story', 'Create Embeddings', 'Closed', 2, 13, 'As a Data Scientist, I need vector embeddings'),
('US-1303', 'User Story', 'Create Semantic Model', 'Closed', 2, 13, 'As an Analyst, I need Cortex Analyst integration');

-- ============================================================================
-- STEP 4: INSERT TASKS
-- ============================================================================

INSERT INTO AZURE_WORK_ITEMS (WORK_ITEM_ID, WORK_ITEM_TYPE, TITLE, STATE, PRIORITY, PHASE_NUMBER, DESCRIPTION) VALUES
-- Phase 13 Tasks
('TASK-1301', 'Task', 'Create AI_SCHEMA', 'Closed', 1, 13, 'Create core AI schema'),
('TASK-1302', 'Task', 'Create FEATURE_STORE schema', 'Closed', 1, 13, 'Create ML feature store schema'),
('TASK-1303', 'Task', 'Create ICU_FEATURE_STORE table', 'Closed', 1, 13, 'Create 20+ ML features'),
('TASK-1304', 'Task', 'Create PATIENT_NOTES table', 'Closed', 2, 13, 'Create clinical notes for NLP'),
('TASK-1305', 'Task', 'Create PATIENT_EMBEDDINGS table', 'Closed', 2, 13, 'Create vector embeddings'),
('TASK-1306', 'Task', 'Create V_PATIENT_SEMANTIC view', 'Closed', 2, 13, 'Create semantic model view'),

-- Phase 14 Tasks
('TASK-1401', 'Task', 'Create DEPLOYMENT_LOG table', 'Closed', 1, 14, 'Track deployments'),
('TASK-1402', 'Task', 'Create SCRIPT_REGISTRY table', 'Closed', 1, 14, 'Registry of scripts'),
('TASK-1403', 'Task', 'Create SP_DEPLOY_SQL procedure', 'Closed', 1, 14, 'Deployment stored procedure'),
('TASK-1404', 'Task', 'Create GitHub Actions workflow', 'Closed', 1, 14, 'CI/CD pipeline'),

-- Phase 15 Tasks
('TASK-1501', 'Task', 'Create Azure pipeline', 'Closed', 1, 15, 'Azure DevOps pipeline'),
('TASK-1502', 'Task', 'Create work items', 'Closed', 1, 15, 'Epics, stories, tasks');

-- ============================================================================
-- STEP 5: SPRINT TRACKING TABLE
-- ============================================================================

CREATE OR REPLACE TABLE SPRINT_TRACKING (
    SPRINT_ID STRING NOT NULL,
    SPRINT_NAME STRING NOT NULL,
    START_DATE DATE,
    END_DATE DATE,
    PHASES_INCLUDED STRING,
    STATUS STRING,
    VELOCITY NUMBER,
    CONSTRAINT PK_SPRINT_TRACKING PRIMARY KEY (SPRINT_ID)
);

INSERT INTO SPRINT_TRACKING VALUES
('SPRINT-1', 'Sprint 1: Foundation', '2026-02-01', '2026-02-14', '1,2,3,4,5', 'Completed', 45),
('SPRINT-2', 'Sprint 2: Governance', '2026-02-15', '2026-02-21', '6,7,8,9', 'Completed', 38),
('SPRINT-3', 'Sprint 3: Data', '2026-02-22', '2026-02-27', '10,11,12,13', 'Completed', 42),
('SPRINT-4', 'Sprint 4: DevOps', '2026-02-27', '2026-02-28', '14,15', 'Completed', 25);

-- ============================================================================
-- STEP 6: VIEWS FOR AZURE DEVOPS REPORTING
-- ============================================================================

-- Work Items Summary
CREATE OR REPLACE VIEW V_WORK_ITEMS_SUMMARY AS
SELECT
    WORK_ITEM_TYPE,
    STATE,
    COUNT(*) AS COUNT,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS PERCENTAGE
FROM AZURE_WORK_ITEMS
GROUP BY WORK_ITEM_TYPE, STATE
ORDER BY WORK_ITEM_TYPE, STATE;

-- Phase Progress
CREATE OR REPLACE VIEW V_PHASE_PROGRESS AS
SELECT
    PHASE_NUMBER,
    COUNT(*) AS TOTAL_ITEMS,
    SUM(CASE WHEN STATE = 'Closed' THEN 1 ELSE 0 END) AS COMPLETED,
    ROUND(100.0 * SUM(CASE WHEN STATE = 'Closed' THEN 1 ELSE 0 END) / COUNT(*), 2) AS COMPLETION_PCT
FROM AZURE_WORK_ITEMS
WHERE PHASE_NUMBER IS NOT NULL
GROUP BY PHASE_NUMBER
ORDER BY PHASE_NUMBER;

-- Sprint Summary
CREATE OR REPLACE VIEW V_SPRINT_SUMMARY AS
SELECT
    SPRINT_ID,
    SPRINT_NAME,
    START_DATE,
    END_DATE,
    PHASES_INCLUDED,
    STATUS,
    VELOCITY
FROM SPRINT_TRACKING
ORDER BY START_DATE;

-- ============================================================================
-- STEP 7: LINK DEPLOYMENTS TO AZURE WORK ITEMS
-- ============================================================================

-- Update deployment log with Azure work item references
UPDATE DEPLOYMENT_LOG
SET AZURE_WORK_ITEM = 'EPIC-0' || LPAD(PHASE_NUMBER::STRING, 2, '0')
WHERE PHASE_NUMBER IS NOT NULL AND PHASE_NUMBER > 0;

-- ============================================================================
-- STEP 8: VERIFICATION
-- ============================================================================

SELECT 'AZURE_WORK_ITEMS' AS TABLE_NAME, COUNT(*) AS ROWS FROM AZURE_WORK_ITEMS
UNION ALL SELECT 'SPRINT_TRACKING', COUNT(*) FROM SPRINT_TRACKING;

SELECT * FROM V_WORK_ITEMS_SUMMARY;
SELECT * FROM V_PHASE_PROGRESS;

-- ============================================================================
-- PHASE 15: AZURE DEVOPS - COMPLETE
-- ============================================================================
-- Objects Created:
--   - DEVOPS_DB.CI_CD.AZURE_WORK_ITEMS (27 items: 15 Epics, 10 Stories, 12 Tasks)
--   - DEVOPS_DB.CI_CD.SPRINT_TRACKING (4 sprints)
--   - DEVOPS_DB.CI_CD.V_WORK_ITEMS_SUMMARY (View)
--   - DEVOPS_DB.CI_CD.V_PHASE_PROGRESS (View)
--   - DEVOPS_DB.CI_CD.V_SPRINT_SUMMARY (View)
-- ============================================================================
