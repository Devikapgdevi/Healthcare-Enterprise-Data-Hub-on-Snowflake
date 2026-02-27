-- ============================================================================
-- PHASE 8: DATA GOVERNANCE (Snowflake Horizon)
-- Healthcare Enterprise Data Hub
-- ============================================================================
-- Objectives: Tags, 3 masking policies, row access policy
-- Role Required: ACCOUNTADMIN
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE SECURITY_DB;
USE SCHEMA SECURITY_SCHEMA;

-- ============================================================================
-- 8.1 DATA CLASSIFICATION TAGS
-- ============================================================================

-- Data Sensitivity Classification
CREATE OR REPLACE TAG DATA_CLASSIFICATION
    ALLOWED_VALUES 'PUBLIC', 'INTERNAL', 'CONFIDENTIAL', 'RESTRICTED'
    COMMENT = 'Data sensitivity classification levels';

-- PII Type Classification
CREATE OR REPLACE TAG PII_TYPE
    ALLOWED_VALUES 'SSN', 'PHONE', 'EMAIL', 'ADDRESS', 'DOB', 'NAME', 'INSURANCE'
    COMMENT = 'Personally Identifiable Information type';

-- PHI Type Classification (Healthcare specific)
CREATE OR REPLACE TAG PHI_TYPE
    ALLOWED_VALUES 'DIAGNOSIS', 'TREATMENT', 'MEDICATION', 'VITALS', 'LAB_RESULTS'
    COMMENT = 'Protected Health Information type';

-- Data Domain Tag
CREATE OR REPLACE TAG DATA_DOMAIN
    ALLOWED_VALUES 'PATIENT', 'BILLING', 'CLINICAL', 'DEVICE', 'ADMIN'
    COMMENT = 'Business domain classification';

-- ============================================================================
-- 8.2 MASKING POLICY 1: SSN MASKING
-- ============================================================================
CREATE OR REPLACE MASKING POLICY MASK_SSN
    AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'HC_SECURITY_ADMIN') THEN val
        WHEN CURRENT_ROLE() IN ('HC_ACCOUNT_ADMIN') THEN '***-**-' || RIGHT(val, 4)
        WHEN CURRENT_ROLE() IN ('HC_DATA_ENGINEER') THEN '***-**-' || RIGHT(val, 4)
        ELSE '***-**-****'
    END
    COMMENT = 'SSN masking - Full access for security, partial for engineers';

-- ============================================================================
-- 8.3 MASKING POLICY 2: PHONE MASKING
-- ============================================================================
CREATE OR REPLACE MASKING POLICY MASK_PHONE
    AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'HC_SECURITY_ADMIN') THEN val
        WHEN CURRENT_ROLE() IN ('HC_ACCOUNT_ADMIN', 'HC_DATA_ENGINEER') THEN 
            '(' || SUBSTR(val, 2, 3) || ') ***-' || RIGHT(val, 4)
        ELSE '(***) ***-****'
    END
    COMMENT = 'Phone masking - Full for security, partial for engineers';

-- ============================================================================
-- 8.4 MASKING POLICY 3: INSURANCE NUMBER MASKING
-- ============================================================================
CREATE OR REPLACE MASKING POLICY MASK_INSURANCE
    AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'HC_SECURITY_ADMIN') THEN val
        WHEN CURRENT_ROLE() IN ('HC_ACCOUNT_ADMIN') THEN 'INS-****-' || RIGHT(val, 4)
        ELSE 'INS-****-****'
    END
    COMMENT = 'Insurance number masking - Full for security only';

-- ============================================================================
-- 8.5 ROW ACCESS POLICY: REGION-BASED ACCESS
-- ============================================================================
CREATE OR REPLACE ROW ACCESS POLICY REGION_ACCESS_POLICY
    AS (hospital_region STRING) RETURNS BOOLEAN ->
    CASE
        -- Full access for admin roles
        WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'HC_SECURITY_ADMIN', 'HC_ACCOUNT_ADMIN') THEN TRUE
        -- Engineers see all regions
        WHEN CURRENT_ROLE() = 'HC_DATA_ENGINEER' THEN TRUE
        -- Analysts see North and South regions
        WHEN CURRENT_ROLE() = 'HC_ANALYST' AND hospital_region IN ('North', 'South', 'East', 'West') THEN TRUE
        -- Viewers see only North region
        WHEN CURRENT_ROLE() = 'HC_VIEWER' AND hospital_region = 'North' THEN TRUE
        -- Data Scientists see all for ML training
        WHEN CURRENT_ROLE() = 'HC_DATA_SCIENTIST' THEN TRUE
        ELSE TRUE  -- Default allow for demo
    END
    COMMENT = 'Region-based row access control';

-- ============================================================================
-- 8.6 APPLY TAGS TO PATIENT TABLE
-- ============================================================================
-- Apply tags (run after table creation in Phase 11)
-- ALTER TABLE RAW_DB.RAW_SCHEMA.PATIENT_RAW SET TAG 
--     SECURITY_DB.SECURITY_SCHEMA.DATA_CLASSIFICATION = 'RESTRICTED',
--     SECURITY_DB.SECURITY_SCHEMA.DATA_DOMAIN = 'PATIENT';

-- ALTER TABLE RAW_DB.RAW_SCHEMA.PATIENT_RAW MODIFY COLUMN SSN SET TAG
--     SECURITY_DB.SECURITY_SCHEMA.PII_TYPE = 'SSN';

-- ALTER TABLE RAW_DB.RAW_SCHEMA.PATIENT_RAW MODIFY COLUMN PHONE SET TAG
--     SECURITY_DB.SECURITY_SCHEMA.PII_TYPE = 'PHONE';

-- ALTER TABLE RAW_DB.RAW_SCHEMA.PATIENT_RAW MODIFY COLUMN INSURANCE_NO SET TAG
--     SECURITY_DB.SECURITY_SCHEMA.PII_TYPE = 'INSURANCE';

-- ============================================================================
-- 8.7 APPLY MASKING POLICIES (run after table creation)
-- ============================================================================
-- ALTER TABLE RAW_DB.RAW_SCHEMA.PATIENT_RAW
--     MODIFY COLUMN SSN SET MASKING POLICY SECURITY_DB.SECURITY_SCHEMA.MASK_SSN;

-- ALTER TABLE RAW_DB.RAW_SCHEMA.PATIENT_RAW
--     MODIFY COLUMN PHONE SET MASKING POLICY SECURITY_DB.SECURITY_SCHEMA.MASK_PHONE;

-- ALTER TABLE RAW_DB.RAW_SCHEMA.PATIENT_RAW
--     MODIFY COLUMN INSURANCE_NO SET MASKING POLICY SECURITY_DB.SECURITY_SCHEMA.MASK_INSURANCE;

-- ============================================================================
-- 8.8 APPLY ROW ACCESS POLICY (run after table creation)
-- ============================================================================
-- ALTER TABLE RAW_DB.RAW_SCHEMA.PATIENT_RAW
--     ADD ROW ACCESS POLICY SECURITY_DB.SECURITY_SCHEMA.REGION_ACCESS_POLICY 
--     ON (HOSPITAL_REGION);

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
SHOW TAGS IN SCHEMA SECURITY_DB.SECURITY_SCHEMA;
SHOW MASKING POLICIES IN SCHEMA SECURITY_DB.SECURITY_SCHEMA;
SHOW ROW ACCESS POLICIES IN SCHEMA SECURITY_DB.SECURITY_SCHEMA;

-- ============================================================================
-- PHASE 8 COMPLETE
-- Objects Created:
--   Tags: 4 (DATA_CLASSIFICATION, PII_TYPE, PHI_TYPE, DATA_DOMAIN)
--   Masking Policies: 3 (MASK_SSN, MASK_PHONE, MASK_INSURANCE)
--   Row Access Policies: 1 (REGION_ACCESS_POLICY)
-- ============================================================================
