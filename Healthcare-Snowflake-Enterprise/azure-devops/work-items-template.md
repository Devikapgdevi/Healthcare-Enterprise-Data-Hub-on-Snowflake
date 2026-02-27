# Azure DevOps Work Items Template
## Healthcare Enterprise Snowflake Project

### Project URL
https://dev.azure.com/ArisData1/Snowflake

---

## Epic 1: Account Administration & Security
**Work Item Type:** Epic  
**Priority:** 1 - Critical

### User Stories
1. **US-101:** As a Security Admin, I need network policies configured so that only authorized IPs can access Snowflake
2. **US-102:** As a Security Admin, I need password policies enforced for all users
3. **US-103:** As a Security Admin, I need session timeouts configured for HIPAA compliance

### Tasks
- [ ] Task 1.1: Create network policy with IP allowlist
- [ ] Task 1.2: Configure password policy (12+ chars, complexity)
- [ ] Task 1.3: Set session timeout to 30 minutes
- [ ] Task 1.4: Enable Cortex AI cross-region
- [ ] Task 1.5: Create SECURITY_DB database

---

## Epic 2: Role-Based Access Control
**Work Item Type:** Epic  
**Priority:** 1 - Critical

### User Stories
1. **US-201:** As an Admin, I need healthcare-specific roles created
2. **US-202:** As an Admin, I need role hierarchy established for least-privilege access

### Tasks
- [ ] Task 2.1: Create HC_ACCOUNT_ADMIN role
- [ ] Task 2.2: Create HC_SECURITY_ADMIN role
- [ ] Task 2.3: Create HC_DATA_ENGINEER role
- [ ] Task 2.4: Create HC_ANALYST role
- [ ] Task 2.5: Create HC_DATA_SCIENTIST role
- [ ] Task 2.6: Create HC_VIEWER role
- [ ] Task 2.7: Establish role hierarchy grants
- [ ] Task 2.8: Document role permissions matrix

---

## Epic 3: Compute Infrastructure
**Work Item Type:** Epic  
**Priority:** 2 - High

### User Stories
1. **US-301:** As a Data Engineer, I need dedicated warehouses for ETL workloads
2. **US-302:** As a Data Scientist, I need a warehouse optimized for ML workloads

### Tasks
- [ ] Task 3.1: Create HC_ETL_WH (MEDIUM, 60s suspend)
- [ ] Task 3.2: Create HC_TRANSFORM_WH (LARGE, 120s suspend)
- [ ] Task 3.3: Create HC_ANALYTICS_WH (MEDIUM, 60s suspend)
- [ ] Task 3.4: Create HC_AI_WH (LARGE, 300s suspend)
- [ ] Task 3.5: Grant warehouse permissions to roles

---

## Epic 4: Database Architecture
**Work Item Type:** Epic  
**Priority:** 2 - High

### User Stories
1. **US-401:** As a Data Engineer, I need medallion architecture databases
2. **US-402:** As an Admin, I need support databases for monitoring and audit

### Tasks
- [ ] Task 4.1: Create RAW_DB (Bronze layer)
- [ ] Task 4.2: Create TRANSFORM_DB (Silver layer)
- [ ] Task 4.3: Create ANALYTICS_DB (Gold layer)
- [ ] Task 4.4: Create AI_READY_DB (Platinum layer)
- [ ] Task 4.5: Create MONITORING_DB
- [ ] Task 4.6: Create AUDIT_DB
- [ ] Task 4.7: Create DEVOPS_DB
- [ ] Task 4.8: Create all schemas

---

## Epic 5: Cost Management
**Work Item Type:** Epic  
**Priority:** 2 - High

### User Stories
1. **US-501:** As an Admin, I need resource monitors to control costs
2. **US-502:** As an Admin, I need alerts when credit thresholds are reached

### Tasks
- [ ] Task 5.1: Create account-level resource monitor (100 credits)
- [ ] Task 5.2: Create HC_ETL_WH monitor (25 credits)
- [ ] Task 5.3: Create HC_TRANSFORM_WH monitor (35 credits)
- [ ] Task 5.4: Create HC_ANALYTICS_WH monitor (20 credits)
- [ ] Task 5.5: Create HC_AI_WH monitor (50 credits)
- [ ] Task 5.6: Configure alert thresholds (50%, 75%, 90%, 100%)

---

## Epic 6: Monitoring & Observability
**Work Item Type:** Epic  
**Priority:** 3 - Medium

### User Stories
1. **US-601:** As an Admin, I need 10+ views for consumption insights
2. **US-602:** As a Security Admin, I need login monitoring views

### Tasks
- [ ] Task 6.1: Create V_QUERY_PERFORMANCE view
- [ ] Task 6.2: Create V_WAREHOUSE_CREDIT_USAGE view
- [ ] Task 6.3: Create V_DAILY_CREDIT_SUMMARY view
- [ ] Task 6.4: Create V_LOGIN_HISTORY view
- [ ] Task 6.5: Create V_FAILED_LOGINS view
- [ ] Task 6.6: Create V_LONG_RUNNING_QUERIES view
- [ ] Task 6.7: Create V_FAILED_QUERIES view
- [ ] Task 6.8: Create V_STORAGE_USAGE view
- [ ] Task 6.9: Create V_WAREHOUSE_LOAD view
- [ ] Task 6.10: Create V_USER_QUERY_STATS view
- [ ] Task 6.11: Create V_DATA_TRANSFER view
- [ ] Task 6.12: Create V_MV_REFRESH_HISTORY view

---

## Epic 7: Automated Alerts
**Work Item Type:** Epic  
**Priority:** 3 - Medium

### User Stories
1. **US-701:** As an Admin, I need automated alerts for cost monitoring
2. **US-702:** As a Healthcare Admin, I need patient risk alerts

### Tasks
- [ ] Task 7.1: Create high credit usage alert
- [ ] Task 7.2: Create failed login alert
- [ ] Task 7.3: Create long query alert
- [ ] Task 7.4: Create queue time alert
- [ ] Task 7.5: Create storage growth alert
- [ ] Task 7.6: Create ICU critical patient alert
- [ ] Task 7.7: Create billing overdue alert
- [ ] Task 7.8: Create device severity alert
- [ ] Task 7.9: Create ETL failure alert
- [ ] Task 7.10: Create concurrent query alert

---

## Epic 8: Data Governance (Horizon)
**Work Item Type:** Epic  
**Priority:** 1 - Critical

### User Stories
1. **US-801:** As a Security Admin, I need data classification tags
2. **US-802:** As a Security Admin, I need 3 masking policies for PII
3. **US-803:** As a Security Admin, I need row-level access control

### Tasks
- [ ] Task 8.1: Create DATA_CLASSIFICATION tag
- [ ] Task 8.2: Create PII_TYPE tag
- [ ] Task 8.3: Create PHI_TYPE tag
- [ ] Task 8.4: Create MASK_SSN policy
- [ ] Task 8.5: Create MASK_PHONE policy
- [ ] Task 8.6: Create MASK_INSURANCE policy
- [ ] Task 8.7: Create REGION_ACCESS_POLICY
- [ ] Task 8.8: Apply policies to PATIENT_RAW table

---

## Epic 9: Audit & Compliance
**Work Item Type:** Epic  
**Priority:** 2 - High

### User Stories
1. **US-901:** As a Compliance Officer, I need audit trail views
2. **US-902:** As a Security Admin, I need access history tracking

### Tasks
- [ ] Task 9.1: Create V_AUDIT_LOGIN_HISTORY view
- [ ] Task 9.2: Create V_AUDIT_ROLE_GRANTS view
- [ ] Task 9.3: Create V_AUDIT_USER_GRANTS view
- [ ] Task 9.4: Create V_AUDIT_USERS view
- [ ] Task 9.5: Create V_AUDIT_ACCESS_HISTORY view
- [ ] Task 9.6: Create V_AUDIT_COPY_HISTORY view

---

## Epic 10: Testing & Verification
**Work Item Type:** Epic  
**Priority:** 2 - High

### Tasks
- [ ] Task 10.1: Create test case for database verification
- [ ] Task 10.2: Create test case for role verification
- [ ] Task 10.3: Create test case for warehouse verification
- [ ] Task 10.4: Create test case for resource monitors
- [ ] Task 10.5: Create test case for monitoring views
- [ ] Task 10.6: Create test case for masking policies
- [ ] Task 10.7: Create test case for audit views
- [ ] Task 10.8: Document all test results

---

## Epic 11: Medallion Architecture Data
**Work Item Type:** Epic  
**Priority:** 2 - High

### Tasks
- [ ] Task 11.1: Create PATIENT_RAW table (10K records)
- [ ] Task 11.2: Create ICU_EVENTS table (50K records)
- [ ] Task 11.3: Create BILLING_DATA table (20K records)
- [ ] Task 11.4: Create DEVICE_ALERTS table (5K records)
- [ ] Task 11.5: Create Silver layer transformations
- [ ] Task 11.6: Create Gold layer aggregations
- [ ] Task 11.7: Verify data flow Bronze→Platinum

---

## Epic 12: AI-Ready Features
**Work Item Type:** Epic  
**Priority:** 3 - Medium

### Tasks
- [ ] Task 12.1: Create ICU_FEATURE_STORE (20+ features)
- [ ] Task 12.2: Create PATIENT_NOTES table
- [ ] Task 12.3: Create PATIENT_EMBEDDINGS table
- [ ] Task 12.4: Create semantic model view
- [ ] Task 12.5: Document feature engineering logic

---

## Epic 13: CI/CD Integration
**Work Item Type:** Epic  
**Priority:** 3 - Medium

### Tasks
- [ ] Task 13.1: Create GitHub Actions workflow
- [ ] Task 13.2: Create Azure DevOps pipeline
- [ ] Task 13.3: Create DEPLOYMENT_LOG table
- [ ] Task 13.4: Create SCRIPT_REGISTRY table
- [ ] Task 13.5: Create SP_DEPLOY_SQL procedure
- [ ] Task 13.6: Test deployment workflow

---

## Sprint Planning

### Sprint 1 (Week 1-2)
- Epic 1: Account Administration
- Epic 2: RBAC Setup
- Epic 3: Compute Infrastructure

### Sprint 2 (Week 3-4)
- Epic 4: Database Architecture
- Epic 5: Cost Management
- Epic 8: Data Governance

### Sprint 3 (Week 5-6)
- Epic 6: Monitoring
- Epic 7: Alerts
- Epic 9: Audit

### Sprint 4 (Week 7-8)
- Epic 10: Testing
- Epic 11: Medallion Data
- Epic 12: AI Features
- Epic 13: CI/CD

---

## Definition of Done
- [ ] Code committed to Git repository
- [ ] SQL executed successfully in Snowflake
- [ ] Test cases passed
- [ ] Documentation updated
- [ ] Code reviewed and approved
- [ ] Deployed to production
