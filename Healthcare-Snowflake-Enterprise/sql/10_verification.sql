-- ============================================================================
-- PHASE 10: VERIFICATION (Test Scripts and Test Cases)
-- Healthcare Enterprise Data Hub
-- ============================================================================
-- Objectives: Validate all infrastructure and data
-- Role Required: ACCOUNTADMIN
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- 10.1 INFRASTRUCTURE VERIFICATION
-- ============================================================================

-- TC-001: Verify Databases Exist (Expected: 8+)
SELECT 
    'TC-001' AS TEST_ID,
    'Database Count' AS TEST_NAME,
    COUNT(*) AS ACTUAL,
    8 AS EXPECTED,
    CASE WHEN COUNT(*) >= 8 THEN 'PASS' ELSE 'FAIL' END AS RESULT
FROM (SHOW DATABASES LIKE '%_DB');

-- TC-002: Verify Roles Exist (Expected: 6)
SELECT 
    'TC-002' AS TEST_ID,
    'Role Count' AS TEST_NAME,
    COUNT(*) AS ACTUAL,
    6 AS EXPECTED,
    CASE WHEN COUNT(*) >= 6 THEN 'PASS' ELSE 'FAIL' END AS RESULT
FROM (SHOW ROLES LIKE 'HC_%');

-- TC-003: Verify Warehouses Exist (Expected: 4)
SELECT 
    'TC-003' AS TEST_ID,
    'Warehouse Count' AS TEST_NAME,
    COUNT(*) AS ACTUAL,
    4 AS EXPECTED,
    CASE WHEN COUNT(*) >= 4 THEN 'PASS' ELSE 'FAIL' END AS RESULT
FROM (SHOW WAREHOUSES LIKE 'HC_%');

-- TC-004: Verify Resource Monitors (Expected: 5)
SELECT 
    'TC-004' AS TEST_ID,
    'Resource Monitor Count' AS TEST_NAME,
    COUNT(*) AS ACTUAL,
    5 AS EXPECTED,
    CASE WHEN COUNT(*) >= 5 THEN 'PASS' ELSE 'FAIL' END AS RESULT
FROM (SHOW RESOURCE MONITORS LIKE 'HC_%');

-- ============================================================================
-- 10.2 GOVERNANCE VERIFICATION
-- ============================================================================

-- TC-005: Verify Masking Policies (Expected: 3)
SELECT 
    'TC-005' AS TEST_ID,
    'Masking Policy Count' AS TEST_NAME,
    COUNT(*) AS ACTUAL,
    3 AS EXPECTED,
    CASE WHEN COUNT(*) >= 3 THEN 'PASS' ELSE 'FAIL' END AS RESULT
FROM (SHOW MASKING POLICIES IN SCHEMA SECURITY_DB.SECURITY_SCHEMA);

-- TC-006: Verify Row Access Policies (Expected: 1)
SELECT 
    'TC-006' AS TEST_ID,
    'Row Access Policy Count' AS TEST_NAME,
    COUNT(*) AS ACTUAL,
    1 AS EXPECTED,
    CASE WHEN COUNT(*) >= 1 THEN 'PASS' ELSE 'FAIL' END AS RESULT
FROM (SHOW ROW ACCESS POLICIES IN SCHEMA SECURITY_DB.SECURITY_SCHEMA);

-- TC-007: Verify Tags (Expected: 4)
SELECT 
    'TC-007' AS TEST_ID,
    'Tag Count' AS TEST_NAME,
    COUNT(*) AS ACTUAL,
    4 AS EXPECTED,
    CASE WHEN COUNT(*) >= 4 THEN 'PASS' ELSE 'FAIL' END AS RESULT
FROM (SHOW TAGS IN SCHEMA SECURITY_DB.SECURITY_SCHEMA);

-- ============================================================================
-- 10.3 MONITORING VERIFICATION
-- ============================================================================

-- TC-008: Verify Monitoring Views (Expected: 10+)
SELECT 
    'TC-008' AS TEST_ID,
    'Monitoring View Count' AS TEST_NAME,
    COUNT(*) AS ACTUAL,
    10 AS EXPECTED,
    CASE WHEN COUNT(*) >= 10 THEN 'PASS' ELSE 'FAIL' END AS RESULT
FROM (SHOW VIEWS IN SCHEMA MONITORING_DB.MONITORING_SCHEMA);

-- TC-009: Verify Audit Views (Expected: 6+)
SELECT 
    'TC-009' AS TEST_ID,
    'Audit View Count' AS TEST_NAME,
    COUNT(*) AS ACTUAL,
    6 AS EXPECTED,
    CASE WHEN COUNT(*) >= 6 THEN 'PASS' ELSE 'FAIL' END AS RESULT
FROM (SHOW VIEWS IN SCHEMA AUDIT_DB.AUDIT_SCHEMA);

-- TC-010: Verify Alerts (Expected: 10+)
SELECT 
    'TC-010' AS TEST_ID,
    'Alert Count' AS TEST_NAME,
    COUNT(*) AS ACTUAL,
    10 AS EXPECTED,
    CASE WHEN COUNT(*) >= 10 THEN 'PASS' ELSE 'FAIL' END AS RESULT
FROM (SHOW ALERTS LIKE 'HC_ALERT_%');

-- ============================================================================
-- 10.4 DATA VERIFICATION (After Phase 11)
-- ============================================================================

-- TC-011: Verify Bronze Layer Data
SELECT 
    'TC-011' AS TEST_ID,
    'Bronze PATIENT_RAW Count' AS TEST_NAME,
    COUNT(*) AS ACTUAL,
    10000 AS EXPECTED,
    CASE WHEN COUNT(*) >= 10000 THEN 'PASS' ELSE 'FAIL' END AS RESULT
FROM RAW_DB.RAW_SCHEMA.PATIENT_RAW;

-- TC-012: Verify Bronze ICU Events
SELECT 
    'TC-012' AS TEST_ID,
    'Bronze ICU_EVENTS Count' AS TEST_NAME,
    COUNT(*) AS ACTUAL,
    50000 AS EXPECTED,
    CASE WHEN COUNT(*) >= 50000 THEN 'PASS' ELSE 'FAIL' END AS RESULT
FROM RAW_DB.RAW_SCHEMA.ICU_EVENTS;

-- TC-013: Verify Silver Layer Data
SELECT 
    'TC-013' AS TEST_ID,
    'Silver CLEAN_PATIENT Count' AS TEST_NAME,
    COUNT(*) AS ACTUAL,
    10000 AS EXPECTED,
    CASE WHEN COUNT(*) >= 10000 THEN 'PASS' ELSE 'FAIL' END AS RESULT
FROM TRANSFORM_DB.TRANSFORM_SCHEMA.CLEAN_PATIENT;

-- TC-014: Verify Gold Layer Data
SELECT 
    'TC-014' AS TEST_ID,
    'Gold PATIENT_ANALYTICS Count' AS TEST_NAME,
    COUNT(*) AS ACTUAL,
    10000 AS EXPECTED,
    CASE WHEN COUNT(*) >= 10000 THEN 'PASS' ELSE 'FAIL' END AS RESULT
FROM ANALYTICS_DB.ANALYTICS_SCHEMA.PATIENT_ANALYTICS;

-- TC-015: Verify Platinum Layer Data
SELECT 
    'TC-015' AS TEST_ID,
    'Platinum ICU_FEATURE_STORE Count' AS TEST_NAME,
    COUNT(*) AS ACTUAL,
    10000 AS EXPECTED,
    CASE WHEN COUNT(*) >= 10000 THEN 'PASS' ELSE 'FAIL' END AS RESULT
FROM AI_READY_DB.AI_SCHEMA.ICU_FEATURE_STORE;

-- ============================================================================
-- 10.5 ROLE HIERARCHY VERIFICATION
-- ============================================================================

-- TC-016: Verify HC_ACCOUNT_ADMIN granted to ACCOUNTADMIN
SELECT 
    'TC-016' AS TEST_ID,
    'Role Hierarchy' AS TEST_NAME,
    CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS RESULT
FROM (SHOW GRANTS TO ROLE ACCOUNTADMIN)
WHERE "name" = 'HC_ACCOUNT_ADMIN';

-- ============================================================================
-- 10.6 CROSS-LAYER INTEGRITY
-- ============================================================================

-- TC-017: Bronze to Silver Record Match
SELECT 
    'TC-017' AS TEST_ID,
    'Bronze to Silver Match' AS TEST_NAME,
    CASE WHEN 
        (SELECT COUNT(*) FROM RAW_DB.RAW_SCHEMA.PATIENT_RAW) = 
        (SELECT COUNT(*) FROM TRANSFORM_DB.TRANSFORM_SCHEMA.CLEAN_PATIENT) 
    THEN 'PASS' ELSE 'FAIL' END AS RESULT;

-- TC-018: Silver to Gold Record Match
SELECT 
    'TC-018' AS TEST_ID,
    'Silver to Gold Match' AS TEST_NAME,
    CASE WHEN 
        (SELECT COUNT(*) FROM TRANSFORM_DB.TRANSFORM_SCHEMA.CLEAN_PATIENT) = 
        (SELECT COUNT(*) FROM ANALYTICS_DB.ANALYTICS_SCHEMA.PATIENT_ANALYTICS) 
    THEN 'PASS' ELSE 'FAIL' END AS RESULT;

-- TC-019: Gold to Platinum Record Match
SELECT 
    'TC-019' AS TEST_ID,
    'Gold to Platinum Match' AS TEST_NAME,
    CASE WHEN 
        (SELECT COUNT(*) FROM ANALYTICS_DB.ANALYTICS_SCHEMA.PATIENT_ANALYTICS) = 
        (SELECT COUNT(*) FROM AI_READY_DB.AI_SCHEMA.ICU_FEATURE_STORE) 
    THEN 'PASS' ELSE 'FAIL' END AS RESULT;

-- ============================================================================
-- 10.7 DATA QUALITY VERIFICATION
-- ============================================================================

-- TC-020: No Null Patient IDs in Bronze
SELECT 
    'TC-020' AS TEST_ID,
    'No Null Patient IDs' AS TEST_NAME,
    SUM(CASE WHEN PATIENT_ID IS NULL THEN 1 ELSE 0 END) AS NULL_COUNT,
    CASE WHEN SUM(CASE WHEN PATIENT_ID IS NULL THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'FAIL' END AS RESULT
FROM RAW_DB.RAW_SCHEMA.PATIENT_RAW;

-- ============================================================================
-- TEST SUMMARY
-- ============================================================================

SELECT 
    '========================================' AS SUMMARY,
    'HEALTHCARE ENTERPRISE DATA HUB' AS PROJECT,
    'VERIFICATION COMPLETE' AS STATUS,
    CURRENT_TIMESTAMP AS VERIFIED_AT,
    CURRENT_USER() AS VERIFIED_BY;

-- ============================================================================
-- PHASE 10 COMPLETE
-- Test Cases: 20
--   Infrastructure Tests: 4 (Databases, Roles, Warehouses, Monitors)
--   Governance Tests: 3 (Masking, Row Access, Tags)
--   Monitoring Tests: 3 (Views, Audit, Alerts)
--   Data Tests: 5 (Bronze, Silver, Gold, Platinum counts)
--   Integrity Tests: 5 (Cross-layer validation)
-- ============================================================================
