-- ============================================================================
-- PHASE 2: RBAC SETUP (Role-Based Access Control)
-- Healthcare Enterprise Data Hub
-- ============================================================================
-- Objectives: Create 6 healthcare roles with proper hierarchy
-- Role Required: ACCOUNTADMIN
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- 2.1 CREATE HEALTHCARE ROLES
-- ============================================================================

-- Account Administrator - Full healthcare platform control
CREATE ROLE IF NOT EXISTS HC_ACCOUNT_ADMIN
    COMMENT = 'Healthcare Account Administrator - Full platform control';

-- Security Administrator - Manages policies, masking, audit
CREATE ROLE IF NOT EXISTS HC_SECURITY_ADMIN
    COMMENT = 'Healthcare Security Administrator - Policies and compliance';

-- Data Engineer - ETL, transformations, data pipelines
CREATE ROLE IF NOT EXISTS HC_DATA_ENGINEER
    COMMENT = 'Healthcare Data Engineer - ETL and data pipelines';

-- Data Analyst - Analytics, reporting, BI
CREATE ROLE IF NOT EXISTS HC_ANALYST
    COMMENT = 'Healthcare Data Analyst - Analytics and reporting';

-- Data Scientist - ML/AI workloads, feature engineering
CREATE ROLE IF NOT EXISTS HC_DATA_SCIENTIST
    COMMENT = 'Healthcare Data Scientist - ML and AI workloads';

-- Viewer - Read-only access
CREATE ROLE IF NOT EXISTS HC_VIEWER
    COMMENT = 'Healthcare Viewer - Read-only access';

-- ============================================================================
-- 2.2 ROLE HIERARCHY
-- ============================================================================
/*
    ACCOUNTADMIN
        └── HC_ACCOUNT_ADMIN
                ├── HC_SECURITY_ADMIN
                ├── HC_DATA_SCIENTIST
                └── HC_DATA_ENGINEER
                        └── HC_ANALYST
                                └── HC_VIEWER
*/

GRANT ROLE HC_ACCOUNT_ADMIN TO ROLE ACCOUNTADMIN;
GRANT ROLE HC_SECURITY_ADMIN TO ROLE HC_ACCOUNT_ADMIN;
GRANT ROLE HC_DATA_SCIENTIST TO ROLE HC_ACCOUNT_ADMIN;
GRANT ROLE HC_DATA_ENGINEER TO ROLE HC_ACCOUNT_ADMIN;
GRANT ROLE HC_ANALYST TO ROLE HC_DATA_ENGINEER;
GRANT ROLE HC_VIEWER TO ROLE HC_ANALYST;

-- ============================================================================
-- 2.3 GRANT ROLES TO CURRENT USER
-- ============================================================================
GRANT ROLE HC_ACCOUNT_ADMIN TO USER DEVIKAPG;
GRANT ROLE HC_SECURITY_ADMIN TO USER DEVIKAPG;
GRANT ROLE HC_DATA_ENGINEER TO USER DEVIKAPG;
GRANT ROLE HC_ANALYST TO USER DEVIKAPG;
GRANT ROLE HC_DATA_SCIENTIST TO USER DEVIKAPG;
GRANT ROLE HC_VIEWER TO USER DEVIKAPG;

-- ============================================================================
-- 2.4 SECURITY DATABASE GRANTS
-- ============================================================================
GRANT USAGE ON DATABASE SECURITY_DB TO ROLE HC_SECURITY_ADMIN;
GRANT ALL PRIVILEGES ON SCHEMA SECURITY_DB.SECURITY_SCHEMA TO ROLE HC_SECURITY_ADMIN;
GRANT ALL PRIVILEGES ON SCHEMA SECURITY_DB.POLICIES TO ROLE HC_SECURITY_ADMIN;

GRANT USAGE ON DATABASE SECURITY_DB TO ROLE HC_DATA_ENGINEER;
GRANT USAGE ON SCHEMA SECURITY_DB.SECURITY_SCHEMA TO ROLE HC_DATA_ENGINEER;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
SHOW ROLES LIKE 'HC_%';

-- Show role grants
SHOW GRANTS TO ROLE HC_ACCOUNT_ADMIN;
SHOW GRANTS TO ROLE HC_DATA_ENGINEER;
SHOW GRANTS TO ROLE HC_ANALYST;

-- ============================================================================
-- PHASE 2 COMPLETE
-- Roles Created: 6
--   - HC_ACCOUNT_ADMIN
--   - HC_SECURITY_ADMIN
--   - HC_DATA_ENGINEER
--   - HC_ANALYST
--   - HC_DATA_SCIENTIST
--   - HC_VIEWER
-- ============================================================================
