-- ============================================================================
-- PHASE 1: ACCOUNT ADMINISTRATION
-- Healthcare Enterprise Data Hub
-- ============================================================================
-- Objectives: Network policies, password policies, session policies, security
-- Role Required: ACCOUNTADMIN
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- 1.1 CREATE SECURITY DATABASE
-- ============================================================================
CREATE DATABASE IF NOT EXISTS SECURITY_DB 
    COMMENT = 'Security policies and governance objects';
CREATE SCHEMA IF NOT EXISTS SECURITY_DB.SECURITY_SCHEMA;
CREATE SCHEMA IF NOT EXISTS SECURITY_DB.POLICIES;

-- ============================================================================
-- 1.2 NETWORK POLICY
-- Restricts access to authorized IP addresses
-- ============================================================================
-- Note: In production, replace 0.0.0.0/0 with actual IP ranges
CREATE OR REPLACE NETWORK POLICY SECURITY_DB.POLICIES.HEALTHCARE_NETWORK_POLICY
    ALLOWED_IP_LIST = ('0.0.0.0/0')
    COMMENT = 'Healthcare network access policy - restrict IPs in production';

-- Apply to account (optional - uncomment when ready)
-- ALTER ACCOUNT SET NETWORK_POLICY = SECURITY_DB.POLICIES.HEALTHCARE_NETWORK_POLICY;

-- ============================================================================
-- 1.3 PASSWORD POLICY
-- Enforces strong password requirements for HIPAA compliance
-- ============================================================================
CREATE OR REPLACE PASSWORD POLICY SECURITY_DB.POLICIES.HEALTHCARE_PASSWORD_POLICY
    PASSWORD_MIN_LENGTH = 12
    PASSWORD_MAX_LENGTH = 64
    PASSWORD_MIN_UPPER_CASE_CHARS = 1
    PASSWORD_MIN_LOWER_CASE_CHARS = 1
    PASSWORD_MIN_NUMERIC_CHARS = 1
    PASSWORD_MIN_SPECIAL_CHARS = 1
    PASSWORD_MAX_AGE_DAYS = 90
    PASSWORD_MAX_RETRIES = 5
    PASSWORD_LOCKOUT_TIME_MINS = 30
    COMMENT = 'Healthcare password policy - HIPAA compliant';

-- ============================================================================
-- 1.4 SESSION POLICY
-- Controls session timeout for security
-- ============================================================================
CREATE OR REPLACE SESSION POLICY SECURITY_DB.POLICIES.HEALTHCARE_SESSION_POLICY
    SESSION_IDLE_TIMEOUT_MINS = 30
    SESSION_UI_IDLE_TIMEOUT_MINS = 30
    COMMENT = 'Healthcare session timeout policy';

-- ============================================================================
-- 1.5 ENABLE CORTEX AI (Cross-Region)
-- ============================================================================
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
SHOW NETWORK POLICIES IN SCHEMA SECURITY_DB.POLICIES;
SHOW PASSWORD POLICIES IN SCHEMA SECURITY_DB.POLICIES;
SHOW SESSION POLICIES IN SCHEMA SECURITY_DB.POLICIES;
SHOW DATABASES LIKE 'SECURITY_DB';

-- ============================================================================
-- PHASE 1 COMPLETE
-- Objects Created:
--   - SECURITY_DB database with SECURITY_SCHEMA and POLICIES schemas
--   - HEALTHCARE_NETWORK_POLICY
--   - HEALTHCARE_PASSWORD_POLICY  
--   - HEALTHCARE_SESSION_POLICY
--   - Cortex AI enabled
-- ============================================================================
