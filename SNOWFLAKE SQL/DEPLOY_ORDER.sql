-- =====================================================
-- SNOWFLAKE NATIVE DEPLOYMENT SCRIPT
-- Run this in Snowflake to deploy all project components
-- =====================================================

USE ROLE ACCOUNTADMIN;

-- =====================================================
-- STEP 1: ACCOUNT SETUP
-- =====================================================
-- Run: SNOWFLAKE SQL/account_admin/account_setup.sql

-- =====================================================
-- STEP 2: WAREHOUSES
-- =====================================================
-- Run: SNOWFLAKE SQL/warehouses/warehouse_setup.sql

-- =====================================================
-- STEP 3: DATABASE STRUCTURE
-- =====================================================
-- Run: SNOWFLAKE SQL/database_structure/database_structure.sql

-- =====================================================
-- STEP 4: RBAC ROLES
-- =====================================================
-- Run: SNOWFLAKE SQL/rbac/rbac_roles.sql

-- =====================================================
-- STEP 5: RESOURCE MONITORS
-- =====================================================
-- Run: SNOWFLAKE SQL/resource_monitors/resource_monitor.sql

-- =====================================================
-- STEP 6: MONITORING
-- =====================================================
-- Run: SNOWFLAKE SQL/monitoring/monitoring_queries.sql

-- =====================================================
-- STEP 7: DATA GOVERNANCE
-- =====================================================
-- Run: SNOWFLAKE SQL/governance/masking_policies.sql

-- =====================================================
-- STEP 8: RAW DATA INSERT
-- =====================================================
-- Run: SNOWFLAKE SQL/raw_data_insert/raw_data_insert.sql

-- =====================================================
-- STEP 9: MEDALLION ARCHITECTURE
-- =====================================================
-- Run: SNOWFLAKE SQL/medallion/bronze_layer.sql

-- =====================================================
-- STEP 10: AI READY LAYER
-- =====================================================
-- Run: SNOWFLAKE SQL/ai_ready/ai_feature_views.sql

-- =====================================================
-- STEP 11: ALERTS
-- =====================================================
-- Run: SNOWFLAKE SQL/ai_ready/alerts/alert_tasks.sql

-- =====================================================
-- STEP 12: AUDIT
-- =====================================================
-- Run: SNOWFLAKE SQL/audit/audit_queries.sql

-- =====================================================
-- STEP 13: CI/CD FRAMEWORK
-- =====================================================
-- Run: SNOWFLAKE SQL/ci_cd/ci_cd_framework.sql

-- =====================================================
-- STEP 14: VERIFICATION
-- =====================================================
-- Run: SNOWFLAKE SQL/verification/validation_checks.sql

-- =====================================================
-- DEPLOYMENT COMPLETE
-- =====================================================
SELECT 'Healthcare Enterprise Data Hub Deployment Guide' AS STATUS;
