# Phase Documentation - Healthcare Enterprise Data Hub

## Phase 1: Account Administration

### Objectives
- Configure network security policies
- Establish password and session policies
- Enable Cortex AI capabilities

### Objects Created
| Object | Type | Purpose |
|--------|------|---------|
| healthcare_network_policy | Network Policy | IP allowlist for access control |
| healthcare_password_policy | Password Policy | 12+ char, complexity requirements |
| healthcare_session_policy | Session Policy | 30-min idle timeout |
| SECURITY_DB | Database | Central security repository |

### Test Cases
```sql
-- TC1.1: Verify network policy exists
SHOW NETWORK POLICIES LIKE 'healthcare%';

-- TC1.2: Verify password policy
SHOW PASSWORD POLICIES IN SCHEMA SECURITY_DB.POLICIES;

-- TC1.3: Verify session policy
SHOW SESSION POLICIES IN SCHEMA SECURITY_DB.POLICIES;
```

---

## Phase 2: RBAC Setup

### Objectives
- Create 6 healthcare-specific roles
- Establish role hierarchy
- Implement least-privilege access

### Role Hierarchy
```
ACCOUNTADMIN
    └── HC_ACCOUNT_ADMIN
            ├── HC_SECURITY_ADMIN
            ├── HC_DATA_SCIENTIST
            └── HC_DATA_ENGINEER
                    └── HC_ANALYST
                            └── HC_VIEWER
```

### Role Permissions Matrix
| Role | Databases | Warehouses | Actions |
|------|-----------|------------|---------|
| HC_ACCOUNT_ADMIN | All | All | Full admin |
| HC_SECURITY_ADMIN | SECURITY_DB | HC_ANALYTICS_WH | Manage policies |
| HC_DATA_ENGINEER | RAW, TRANSFORM | HC_ETL, HC_TRANSFORM | ETL operations |
| HC_DATA_SCIENTIST | AI_READY_DB | HC_AI_WH | ML workloads |
| HC_ANALYST | ANALYTICS_DB | HC_ANALYTICS_WH | Query & report |
| HC_VIEWER | Read-only | HC_ANALYTICS_WH | View data |

### Test Cases
```sql
-- TC2.1: Verify 6 roles created
SELECT COUNT(*) FROM (SHOW ROLES LIKE 'HC_%');
-- Expected: 6

-- TC2.2: Test role hierarchy
USE ROLE HC_VIEWER;
-- Should inherit from HC_ANALYST

-- TC2.3: Verify grants
SHOW GRANTS TO ROLE HC_DATA_ENGINEER;
```

---

## Phase 3: Warehouse Management

### Objectives
- Create 4 workload-specific warehouses
- Configure auto-suspend/resume
- Optimize for different use cases

### Warehouse Configuration
| Warehouse | Size | Auto-Suspend | Use Case |
|-----------|------|--------------|----------|
| HC_ETL_WH | XSMALL | 60 sec | Data ingestion |
| HC_TRANSFORM_WH | XSMALL | 120 sec | Data processing |
| HC_ANALYTICS_WH | XSMALL | 60 sec | BI/Reporting |
| HC_AI_WH | XSMALL | 300 sec | ML/AI workloads |

### Test Cases
```sql
-- TC3.1: Verify 4 warehouses
SELECT COUNT(*) FROM (SHOW WAREHOUSES LIKE 'HC_%');
-- Expected: 4

-- TC3.2: Test auto-resume
USE WAREHOUSE HC_ANALYTICS_WH;
SELECT CURRENT_WAREHOUSE();

-- TC3.3: Verify suspend settings
SHOW WAREHOUSES LIKE 'HC_%';
```

---

## Phase 4: Database Structure

### Objectives
- Create medallion architecture databases
- Establish schema organization
- Configure database grants

### Database Summary
| Database | Purpose | Schemas |
|----------|---------|---------|
| RAW_DB | Bronze layer | RAW_SCHEMA, STAGING_SCHEMA |
| TRANSFORM_DB | Silver layer | TRANSFORM_SCHEMA |
| ANALYTICS_DB | Gold layer | ANALYTICS_SCHEMA |
| AI_READY_DB | Platinum layer | AI_SCHEMA, FEATURE_STORE, SEMANTIC_MODELS |
| SECURITY_DB | Governance | SECURITY_SCHEMA, POLICIES |
| MONITORING_DB | Monitoring | MONITORING_SCHEMA |
| AUDIT_DB | Audit trail | AUDIT_SCHEMA |
| DEVOPS_DB | CI/CD | CI_CD |

### Test Cases
```sql
-- TC4.1: Verify 8 databases
SELECT COUNT(*) FROM (SHOW DATABASES LIKE '%_DB');
-- Expected: 8

-- TC4.2: Verify schemas exist
SHOW SCHEMAS IN DATABASE AI_READY_DB;
-- Expected: AI_SCHEMA, FEATURE_STORE, SEMANTIC_MODELS
```

---

## Phase 5: Resource Monitors

### Objectives
- Account-level credit monitoring
- Per-warehouse credit limits
- Alert thresholds at 50%, 75%, 90%, 100%

### Monitor Configuration
| Monitor | Credit Quota | Notify At | Suspend At |
|---------|--------------|-----------|------------|
| HC_ACCOUNT_MONITOR | 100 | 50%, 75%, 90% | 100% |
| HC_ETL_WH_MONITOR | 25 | 75% | 100% |
| HC_TRANSFORM_WH_MONITOR | 35 | 75% | 100% |
| HC_ANALYTICS_WH_MONITOR | 20 | 75% | 100% |
| HC_AI_WH_MONITOR | 50 | 75% | 100% |

### Test Cases
```sql
-- TC5.1: Verify 5 resource monitors
SELECT COUNT(*) FROM (SHOW RESOURCE MONITORS LIKE 'HC_%');
-- Expected: 5

-- TC5.2: Check monitor assignments
SHOW WAREHOUSES LIKE 'HC_%';
-- Verify RESOURCE_MONITOR column
```

---

## Phase 6: Monitoring (12 Views)

### Objectives
- 10+ consumption insight views
- Performance tracking
- Cost analysis

### Views Created
1. V_QUERY_PERFORMANCE - Query execution metrics
2. V_WAREHOUSE_CREDIT_USAGE - Credit consumption by warehouse
3. V_DAILY_CREDIT_SUMMARY - Daily credit totals
4. V_LOGIN_HISTORY - User authentication tracking
5. V_FAILED_LOGINS - Security monitoring
6. V_LONG_RUNNING_QUERIES - Performance bottlenecks
7. V_FAILED_QUERIES - Error tracking
8. V_STORAGE_USAGE - Database sizes
9. V_WAREHOUSE_LOAD - Warehouse utilization
10. V_USER_QUERY_STATS - User activity summary
11. V_DATA_TRANSFER - Cross-region transfers
12. V_MV_REFRESH_HISTORY - Materialized view maintenance

### Test Cases
```sql
-- TC6.1: Verify 12 monitoring views
SELECT COUNT(*) FROM (SHOW VIEWS IN SCHEMA MONITORING_DB.MONITORING_SCHEMA);
-- Expected: 12

-- TC6.2: Test query performance view
SELECT * FROM MONITORING_DB.MONITORING_SCHEMA.V_QUERY_PERFORMANCE LIMIT 5;
```

---

## Phase 7: Alerts (10 Alerts)

### Objectives
- 10+ automated alerts
- Cost monitoring
- Performance monitoring
- Healthcare-specific alerts

### Alerts Created
1. HC_ALERT_HIGH_CREDITS - Daily credit threshold
2. HC_ALERT_FAILED_LOGINS - Security monitoring
3. HC_ALERT_LONG_QUERY - Query performance
4. HC_ALERT_QUEUE_TIME - Warehouse queuing
5. HC_ALERT_STORAGE_GROWTH - Database growth
6. HC_ALERT_ICU_CRITICAL - Patient risk alerts
7. HC_ALERT_BILLING_OVERDUE - Financial monitoring
8. HC_ALERT_DEVICE_SEVERITY - Device alerts
9. HC_ALERT_ETL_FAILURE - Data pipeline failures
10. HC_ALERT_CONCURRENT_QUERIES - Concurrency monitoring

### Test Cases
```sql
-- TC7.1: Verify 10 alerts
SELECT COUNT(*) FROM (SHOW ALERTS IN ACCOUNT);
-- Expected: 10

-- TC7.2: Check alert schedules
SHOW ALERTS LIKE 'HC_%';
```

---

## Phase 8: Data Governance (Horizon)

### Objectives
- Classification tags for data sensitivity
- 3 masking policies for PII/PHI
- Row access policy for region-based access

### Tags Created
| Tag | Allowed Values | Purpose |
|-----|----------------|---------|
| DATA_CLASSIFICATION | PUBLIC, INTERNAL, CONFIDENTIAL, RESTRICTED | Data sensitivity |
| PII_TYPE | SSN, PHONE, EMAIL, ADDRESS, DOB, NAME | PII identification |
| PHI_TYPE | DIAGNOSIS, TREATMENT, MEDICATION, VITALS | PHI identification |

### Masking Policies
| Policy | Column | Behavior |
|--------|--------|----------|
| MASK_SSN | SSN | Full for ACCOUNTADMIN, partial for admin, hidden for others |
| MASK_PHONE | PHONE | Full for security, partial for engineers, hidden for analysts |
| MASK_INSURANCE | INSURANCE_NO | Full for security only |

### Row Access Policy
| Policy | Based On | Logic |
|--------|----------|-------|
| REGION_ACCESS_POLICY | HOSPITAL_REGION | Admins see all, analysts see North/South, viewers see North only |

### Test Cases
```sql
-- TC8.1: Verify 3 masking policies
SELECT COUNT(*) FROM (SHOW MASKING POLICIES IN SCHEMA SECURITY_DB.SECURITY_SCHEMA);
-- Expected: 3

-- TC8.2: Test masking as different roles
USE ROLE HC_VIEWER;
SELECT SSN, PHONE FROM RAW_DB.RAW_SCHEMA.PATIENT_RAW LIMIT 1;
-- Should see masked values

-- TC8.3: Verify row access
USE ROLE HC_VIEWER;
SELECT DISTINCT HOSPITAL_REGION FROM RAW_DB.RAW_SCHEMA.PATIENT_RAW;
-- Should only see allowed regions
```

---

## Phase 9: Audit Layer (6 Views)

### Objectives
- Login tracking
- Grant history
- User management audit
- Access history

### Views Created
1. V_AUDIT_LOGIN_HISTORY - All authentication events
2. V_AUDIT_ROLE_GRANTS - Role privilege changes
3. V_AUDIT_USER_GRANTS - User role assignments
4. V_AUDIT_USERS - User account management
5. V_AUDIT_ACCESS_HISTORY - Data access tracking
6. V_AUDIT_COPY_HISTORY - Data load operations

### Test Cases
```sql
-- TC9.1: Verify 6 audit views
SELECT COUNT(*) FROM (SHOW VIEWS IN SCHEMA AUDIT_DB.AUDIT_SCHEMA);
-- Expected: 6

-- TC9.2: Test login audit
SELECT * FROM AUDIT_DB.AUDIT_SCHEMA.V_AUDIT_LOGIN_HISTORY LIMIT 5;
```

---

## Phase 10: Verification

### Test Case Summary
| Test ID | Description | Expected | Status |
|---------|-------------|----------|--------|
| TC01 | Databases exist | ≥7 | ✅ |
| TC02 | Roles exist | ≥6 | ✅ |
| TC03 | Warehouses exist | ≥4 | ✅ |
| TC04 | Resource monitors | ≥5 | ✅ |
| TC05 | Monitoring views | ≥10 | ✅ |
| TC06 | Masking policies | ≥3 | ✅ |
| TC07 | Audit views | ≥6 | ✅ |

---

## Phase 11: Medallion Architecture

### Data Flow
```
RAW_DB (Bronze) → TRANSFORM_DB (Silver) → ANALYTICS_DB (Gold) → AI_READY_DB (Platinum)
```

### Data Volumes
| Layer | Table | Records |
|-------|-------|---------|
| Bronze | PATIENT_RAW | 10,000 |
| Bronze | ICU_EVENTS | 50,000 |
| Bronze | BILLING_DATA | 20,000 |
| Bronze | DEVICE_ALERTS | 5,000 |
| Silver | CLEAN_PATIENT | 10,000 |
| Silver | CLEAN_ICU_EVENTS | 50,000 |
| Gold | PATIENT_ANALYTICS | 10,000 |
| Gold | BILLING_ANALYTICS | ~8,600 |
| Platinum | ICU_FEATURE_STORE | 10,000 |

---

## Phase 12: Industry - Healthcare

### Domain-Specific Features
- Patient demographics and admissions
- ICU vital signs monitoring
- Billing and insurance tracking
- Medical device alerts
- HIPAA-compliant masking
- PHI/PII classification

---

## Phase 13: AI-Ready Layer

### Feature Store
- ICU_FEATURE_STORE: 20+ ML features per patient
- Risk scores and categories
- Binary risk flags for model input

### Embeddings
- PATIENT_NOTES: Clinical note templates
- PATIENT_EMBEDDINGS: Vector representations (8-dim synthetic)

### Semantic Models
- V_PATIENT_SEMANTIC: Cortex Analyst ready view

---

## Phase 14: GitHub CI/CD

### Pipeline Features
- Automated SQL validation
- Staged deployment (dev → prod)
- Deployment logging
- Script registry

### Files
- `.github/workflows/snowflake-deploy.yml`
- `sql/master_deployment.sql`

---

## Phase 15: Azure DevOps

### Integration
- Project: https://dev.azure.com/ArisData1/Snowflake
- Pipeline: `azure-devops/azure-pipelines.yml`
- Work Items: Epics for each phase

---

## Summary

**Total Objects Created:**
- 8 Databases
- 15+ Schemas
- 6 Roles
- 4 Warehouses
- 5 Resource Monitors
- 12 Monitoring Views
- 10 Alerts
- 3 Tags
- 3 Masking Policies
- 1 Row Access Policy
- 6 Audit Views
- 9+ Data Tables
- 3 Feature Store Tables
- 2 CI/CD Tables
- 1 Stored Procedure

**Total Data Records: 163,000+**
