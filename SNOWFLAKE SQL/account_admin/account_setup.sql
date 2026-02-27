-- =====================================================
-- PHASE 1: ACCOUNT ADMINISTRATION SETUP
-- Enterprise Healthcare Architecture
-- Role: ACCOUNTADMIN
-- =====================================================

USE ROLE ACCOUNTADMIN;

-- =====================================================
-- 1️⃣ NETWORK POLICY (Safe Replace Version)
-- =====================================================

-- Detach existing policy (required if already attached)
ALTER ACCOUNT UNSET NETWORK_POLICY;

-- Create / Replace policy
CREATE OR REPLACE NETWORK POLICY healthcare_network_policy
    ALLOWED_IP_LIST = ('0.0.0.0/0');  -- Replace with real IP range in production

-- Attach policy to account
ALTER ACCOUNT SET NETWORK_POLICY = healthcare_network_policy;

-- =====================================================
-- 2️⃣ PASSWORD POLICY
-- =====================================================

CREATE OR REPLACE PASSWORD POLICY healthcare_password_policy
    PASSWORD_MIN_LENGTH = 12
    PASSWORD_MAX_LENGTH = 64
    PASSWORD_MIN_UPPER_CASE_CHARS = 1
    PASSWORD_MIN_LOWER_CASE_CHARS = 1
    PASSWORD_MIN_NUMERIC_CHARS = 1
    PASSWORD_MIN_SPECIAL_CHARS = 1
    PASSWORD_REUSE_MAX = 5;

-- =====================================================
-- 3️⃣ SESSION POLICY
-- =====================================================

CREATE OR REPLACE SESSION POLICY healthcare_session_policy
    SESSION_IDLE_TIMEOUT_MINS = 30
    SESSION_UI_IDLE_TIMEOUT_MINS = 30;

-- =====================================================
-- 4️⃣ ENABLE CORTEX (AI Capability)
-- =====================================================

ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

-- =====================================================
-- 5️⃣ SECURITY DATABASE SETUP
-- =====================================================

CREATE DATABASE IF NOT EXISTS SECURITY_DB;

USE DATABASE SECURITY_DB;

CREATE SCHEMA IF NOT EXISTS SECURITY_SCHEMA;

-- =====================================================
-- END OF PHASE 1
-- =====================================================
