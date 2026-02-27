-- =====================================================
-- PHASE 8: DATA GOVERNANCE (HORIZON) - FULL WORKING SCRIPT
-- =====================================================

-- 1️⃣ Grant privileges so HC_SECURITY_ADMIN can create objects
USE ROLE ACCOUNTADMIN;

GRANT ALL PRIVILEGES ON SCHEMA SECURITY_DB.SECURITY_SCHEMA TO ROLE HC_SECURITY_ADMIN;

-- 2️⃣ Switch to security admin role
USE ROLE HC_SECURITY_ADMIN;

-- =====================================================
-- 2️⃣ Add missing columns to PATIENT_RAW
-- =====================================================
ALTER TABLE RAW_DB.RAW_SCHEMA.PATIENT_RAW
ADD COLUMN SSN STRING;

ALTER TABLE RAW_DB.RAW_SCHEMA.PATIENT_RAW
ADD COLUMN INSURANCE_NO STRING;

ALTER TABLE RAW_DB.RAW_SCHEMA.PATIENT_RAW
ADD COLUMN PHONE STRING;

ALTER TABLE RAW_DB.RAW_SCHEMA.PATIENT_RAW
ADD COLUMN HOSPITAL_REGION STRING;

-- =====================================================
-- 3️⃣ Create Tag
-- =====================================================
CREATE OR REPLACE TAG SECURITY_DB.SECURITY_SCHEMA.DATA_CLASSIFICATION
COMMENT = 'Classifies sensitive data (PII, PHI)';

-- =====================================================
-- 4️⃣ Create Masking Policies
-- =====================================================
CREATE OR REPLACE MASKING POLICY SECURITY_DB.SECURITY_SCHEMA.MASK_SSN
AS (val STRING) RETURNS STRING ->
CASE
  WHEN CURRENT_ROLE() IN ('HC_SECURITY_ADMIN') THEN val
  ELSE 'XXX-XX-XXXX'
END;

CREATE OR REPLACE MASKING POLICY SECURITY_DB.SECURITY_SCHEMA.MASK_INSURANCE
AS (val STRING) RETURNS STRING ->
CASE
  WHEN CURRENT_ROLE() IN ('HC_SECURITY_ADMIN') THEN val
  ELSE 'XXX-XXXX-XXXX'
END;

CREATE OR REPLACE MASKING POLICY SECURITY_DB.SECURITY_SCHEMA.MASK_PHONE
AS (val STRING) RETURNS STRING ->
CASE
  WHEN CURRENT_ROLE() IN ('HC_SECURITY_ADMIN') THEN val
  ELSE 'XXX-XXX-XXXX'
END;

-- =====================================================
-- 5️⃣ Create Row Access Policy (Restrict by Hospital Region)
-- =====================================================
CREATE OR REPLACE ROW ACCESS POLICY SECURITY_DB.SECURITY_SCHEMA.REGION_ACCESS_POLICY
AS (hospital_region STRING) RETURNS BOOLEAN ->
CASE
  WHEN CURRENT_ROLE() IN ('HC_SECURITY_ADMIN') THEN TRUE
  ELSE CURRENT_REGION() = hospital_region
END;

-- =====================================================
-- 6️⃣ Apply Masking Policies to PATIENT_RAW
-- =====================================================
ALTER TABLE RAW_DB.RAW_SCHEMA.PATIENT_RAW
MODIFY COLUMN SSN SET MASKING POLICY SECURITY_DB.SECURITY_SCHEMA.MASK_SSN;

ALTER TABLE RAW_DB.RAW_SCHEMA.PATIENT_RAW
MODIFY COLUMN INSURANCE_NO SET MASKING POLICY SECURITY_DB.SECURITY_SCHEMA.MASK_INSURANCE;

ALTER TABLE RAW_DB.RAW_SCHEMA.PATIENT_RAW
MODIFY COLUMN PHONE SET MASKING POLICY SECURITY_DB.SECURITY_SCHEMA.MASK_PHONE;

-- =====================================================
-- 7️⃣ Apply Row Access Policy
-- =====================================================
ALTER TABLE RAW_DB.RAW_SCHEMA.PATIENT_RAW
ADD ROW ACCESS POLICY SECURITY_DB.SECURITY_SCHEMA.REGION_ACCESS_POLICY
ON (HOSPITAL_REGION);

-- =====================================================
-- 8️⃣ Verify Created Objects
-- =====================================================
SHOW TAGS IN SCHEMA SECURITY_DB.SECURITY_SCHEMA;
SHOW MASKING POLICIES IN SCHEMA SECURITY_DB.SECURITY_SCHEMA;
SHOW ROW ACCESS POLICIES IN SCHEMA SECURITY_DB.SECURITY_SCHEMA;

-- =====================================================
-- ✅ Phase 8 Data Governance Complete
-- =====================================================
