-- ============================================================================
-- PHASE 12: HEALTHCARE INDUSTRY (HCLS)
-- Healthcare Enterprise Data Hub
-- Priority: HIGH - Domain Specific Implementation
-- ============================================================================
-- Author: DEVIKAPG
-- Account: tyb42779
-- Industry: Healthcare & Life Sciences
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE HC_ANALYTICS_WH;

-- ============================================================================
-- HEALTHCARE INDUSTRY OVERVIEW
-- This phase documents the healthcare-specific implementation across all layers
-- ============================================================================

-- ============================================================================
-- STEP 1: HEALTHCARE DATA DOMAINS
-- ============================================================================

/*
HEALTHCARE DATA DOMAINS IMPLEMENTED:

1. PATIENT MANAGEMENT
   - Patient demographics (age, gender)
   - Admission tracking
   - Diagnosis classification
   - Hospital region assignment

2. ICU MONITORING
   - Vital signs (heart rate, oxygen, BP, temperature)
   - Critical event detection
   - Alert level classification
   - Real-time event tracking

3. BILLING & REVENUE
   - Bill generation
   - Payment status tracking
   - Service type classification
   - Revenue analytics

4. MEDICAL DEVICES
   - Device alerts
   - Severity classification
   - Device type tracking
   - Alert management

5. RISK ASSESSMENT
   - Multi-factor risk scoring
   - Critical patient identification
   - Risk category classification
   - Predictive features for ML
*/

-- ============================================================================
-- STEP 2: HEALTHCARE CLASSIFICATION TAGS
-- ============================================================================

USE DATABASE SECURITY_DB;
USE SCHEMA SECURITY_SCHEMA;

-- Healthcare Data Classification
CREATE OR REPLACE TAG HC_DATA_DOMAIN
    ALLOWED_VALUES 'Patient', 'Clinical', 'Billing', 'Device', 'Administrative'
    COMMENT = 'Healthcare data domain classification';

CREATE OR REPLACE TAG HC_SENSITIVITY
    ALLOWED_VALUES 'PHI', 'PII', 'Financial', 'Operational', 'Public'
    COMMENT = 'Healthcare data sensitivity classification';

CREATE OR REPLACE TAG HC_RETENTION_PERIOD
    ALLOWED_VALUES '7_YEARS', '10_YEARS', 'PERMANENT', 'TRANSIENT'
    COMMENT = 'Healthcare data retention requirements';

-- ============================================================================
-- STEP 3: HEALTHCARE SUMMARY VIEWS
-- ============================================================================

USE DATABASE ANALYTICS_DB;
USE SCHEMA ANALYTICS_SCHEMA;

-- Patient Demographics Summary
CREATE OR REPLACE VIEW V_HC_PATIENT_DEMOGRAPHICS AS
SELECT
    DIAGNOSIS AS "Diagnosis Department",
    AGE_GROUP AS "Age Group",
    GENDER AS "Gender",
    COUNT(*) AS "Patient Count",
    ROUND(AVG(AGE), 1) AS "Average Age",
    ROUND(AVG(DAYS_SINCE_ADMISSION), 1) AS "Avg Days Admitted"
FROM PATIENT_ANALYTICS
GROUP BY DIAGNOSIS, AGE_GROUP, GENDER
ORDER BY DIAGNOSIS, AGE_GROUP, GENDER;

-- ICU Critical Metrics Summary
CREATE OR REPLACE VIEW V_HC_ICU_METRICS AS
SELECT
    DIAGNOSIS AS "Department",
    COUNT(*) AS "Total Patients",
    SUM(ICU_EVENT_COUNT) AS "Total ICU Events",
    SUM(CRITICAL_EVENT_COUNT) AS "Critical Events",
    ROUND(100.0 * SUM(CRITICAL_EVENT_COUNT) / NULLIF(SUM(ICU_EVENT_COUNT), 0), 2) AS "Critical Event Rate %",
    ROUND(AVG(AVG_HEART_RATE), 1) AS "Avg Heart Rate",
    ROUND(AVG(AVG_OXYGEN_LEVEL), 1) AS "Avg Oxygen Level"
FROM PATIENT_ANALYTICS
GROUP BY DIAGNOSIS
ORDER BY "Critical Events" DESC;

-- Billing Revenue Summary
CREATE OR REPLACE VIEW V_HC_BILLING_SUMMARY AS
SELECT
    COUNT(DISTINCT PATIENT_ID) AS "Patients with Bills",
    SUM(TOTAL_AMOUNT) AS "Total Revenue",
    SUM(PAID_AMOUNT) AS "Collected Amount",
    SUM(PENDING_AMOUNT) AS "Pending Amount",
    SUM(OVERDUE_AMOUNT) AS "Overdue Amount",
    ROUND(100.0 * SUM(PAID_AMOUNT) / NULLIF(SUM(TOTAL_AMOUNT), 0), 2) AS "Collection Rate %",
    ROUND(AVG(AVG_BILL_AMOUNT), 2) AS "Avg Bill Amount"
FROM BILLING_ANALYTICS;

-- High Risk Patients View
CREATE OR REPLACE VIEW V_HC_HIGH_RISK_PATIENTS AS
SELECT
    f.PATIENT_ID AS "Patient ID",
    f.AGE AS "Age",
    f.GENDER AS "Gender",
    f.DIAGNOSIS AS "Diagnosis",
    f.RISK_SCORE AS "Risk Score",
    CASE 
        WHEN f.RISK_SCORE >= 4 THEN 'CRITICAL'
        WHEN f.RISK_SCORE >= 3 THEN 'HIGH'
        WHEN f.RISK_SCORE >= 2 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS "Risk Category",
    f.AVG_HEART_RATE AS "Avg Heart Rate",
    f.AVG_OXYGEN_LEVEL AS "Avg Oxygen Level",
    f.ICU_EVENT_COUNT AS "ICU Events",
    f.TOTAL_BILLING AS "Total Billing"
FROM AI_READY_DB.AI_SCHEMA.ICU_FEATURE_STORE f
WHERE f.RISK_SCORE >= 2
ORDER BY f.RISK_SCORE DESC, f.ICU_EVENT_COUNT DESC;

-- ============================================================================
-- STEP 4: HEALTHCARE KPIs
-- ============================================================================

CREATE OR REPLACE VIEW V_HC_KPIS AS
SELECT
    -- Patient Metrics
    (SELECT COUNT(*) FROM PATIENT_ANALYTICS) AS "Total Patients",
    (SELECT COUNT(*) FROM PATIENT_ANALYTICS WHERE AGE_GROUP = 'Senior') AS "Senior Patients",
    (SELECT ROUND(AVG(DAYS_SINCE_ADMISSION), 1) FROM PATIENT_ANALYTICS) AS "Avg Length of Stay",
    
    -- ICU Metrics
    (SELECT SUM(ICU_EVENT_COUNT) FROM PATIENT_ANALYTICS) AS "Total ICU Events",
    (SELECT SUM(CRITICAL_EVENT_COUNT) FROM PATIENT_ANALYTICS) AS "Critical Events",
    (SELECT COUNT(*) FROM AI_READY_DB.AI_SCHEMA.ICU_FEATURE_STORE WHERE RISK_SCORE >= 3) AS "High Risk Patients",
    
    -- Financial Metrics
    (SELECT ROUND(SUM(TOTAL_AMOUNT), 2) FROM BILLING_ANALYTICS) AS "Total Revenue",
    (SELECT ROUND(SUM(PAID_AMOUNT), 2) FROM BILLING_ANALYTICS) AS "Collected Revenue",
    (SELECT ROUND(SUM(OVERDUE_AMOUNT), 2) FROM BILLING_ANALYTICS) AS "Overdue Amount";

-- ============================================================================
-- STEP 5: VERIFICATION
-- ============================================================================

-- Show Healthcare Summary
SELECT * FROM V_HC_PATIENT_DEMOGRAPHICS LIMIT 10;
SELECT * FROM V_HC_ICU_METRICS;
SELECT * FROM V_HC_BILLING_SUMMARY;
SELECT * FROM V_HC_KPIS;

-- Count High Risk Patients by Category
SELECT 
    CASE 
        WHEN RISK_SCORE >= 4 THEN 'CRITICAL'
        WHEN RISK_SCORE >= 3 THEN 'HIGH'
        WHEN RISK_SCORE >= 2 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS RISK_CATEGORY,
    COUNT(*) AS PATIENT_COUNT,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS PERCENTAGE
FROM AI_READY_DB.AI_SCHEMA.ICU_FEATURE_STORE
GROUP BY RISK_CATEGORY
ORDER BY 
    CASE RISK_CATEGORY 
        WHEN 'CRITICAL' THEN 1 
        WHEN 'HIGH' THEN 2 
        WHEN 'MEDIUM' THEN 3 
        ELSE 4 
    END;

-- ============================================================================
-- PHASE 12: HEALTHCARE INDUSTRY - COMPLETE
-- ============================================================================
-- Healthcare Implementation:
--   - Patient Management: 10,000 patients across 5 departments
--   - ICU Monitoring: 50,000 events with critical detection
--   - Billing: 20,000 bills with payment tracking
--   - Device Alerts: 5,000 alerts with severity classification
--   - Risk Assessment: ML-ready risk scoring (0-5 scale)
--   - Views: 5 healthcare-specific analytics views
-- ============================================================================
