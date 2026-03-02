# Test Cases - Healthcare Enterprise Data Hub

## Data Validation Tests

### Bronze Layer Tests
| Test ID | Test Name | Query | Expected |
|---------|-----------|-------|----------|
| TC001 | Patient Count | `SELECT COUNT(*) FROM RAW_DB.RAW_SCHEMA.PATIENT_RAW` | >= 10,000 |
| TC002 | ICU Events Count | `SELECT COUNT(*) FROM RAW_DB.RAW_SCHEMA.ICU_EVENTS` | >= 50,000 |
| TC003 | Billing Count | `SELECT COUNT(*) FROM RAW_DB.RAW_SCHEMA.BILLING_DATA` | >= 20,000 |
| TC004 | No Null Patient IDs | `SELECT COUNT(*) FROM RAW_DB.RAW_SCHEMA.PATIENT_RAW WHERE PATIENT_ID IS NULL` | = 0 |

### Silver Layer Tests
| Test ID | Test Name | Query | Expected |
|---------|-----------|-------|----------|
| TC005 | Clean Patient Count | `SELECT COUNT(*) FROM TRANSFORM_DB.TRANSFORM_SCHEMA.CLEAN_PATIENT` | >= 10,000 |
| TC006 | Clean ICU Events | `SELECT COUNT(*) FROM TRANSFORM_DB.TRANSFORM_SCHEMA.CLEAN_ICU_EVENTS` | >= 50,000 |
| TC007 | Critical Events Flagged | `SELECT COUNT(*) FROM TRANSFORM_DB.TRANSFORM_SCHEMA.CLEAN_ICU_EVENTS WHERE IS_CRITICAL = TRUE` | > 0 |

### Gold Layer Tests
| Test ID | Test Name | Query | Expected |
|---------|-----------|-------|----------|
| TC008 | Patient Analytics | `SELECT COUNT(*) FROM ANALYTICS_DB.ANALYTICS_SCHEMA.PATIENT_ANALYTICS` | >= 10,000 |
| TC009 | Billing Analytics | `SELECT COUNT(*) FROM ANALYTICS_DB.ANALYTICS_SCHEMA.BILLING_ANALYTICS` | > 0 |

## Infrastructure Tests

### RBAC Tests
| Test ID | Test Name | Query | Expected |
|---------|-----------|-------|----------|
| TC010 | HC Roles Exist | `SELECT COUNT(*) FROM (SHOW ROLES LIKE 'HC_%')` | = 6 |
| TC011 | Role Hierarchy | Grant chain from HC_VIEWER to ACCOUNTADMIN | Valid |

### Warehouse Tests
| Test ID | Test Name | Query | Expected |
|---------|-----------|-------|----------|
| TC012 | Warehouses Exist | `SELECT COUNT(*) FROM (SHOW WAREHOUSES LIKE 'HC_%')` | = 4 |
| TC013 | Auto-Suspend Config | All HC warehouses have auto-suspend | TRUE |

### Monitoring Tests
| Test ID | Test Name | Query | Expected |
|---------|-----------|-------|----------|
| TC014 | Monitoring Views | `SELECT COUNT(*) FROM (SHOW VIEWS IN MONITORING_DB.MONITORING_SCHEMA)` | >= 6 |
| TC015 | Resource Monitors | `SELECT COUNT(*) FROM (SHOW RESOURCE MONITORS LIKE 'HC_%')` | >= 4 |

## Security Tests

### Governance Tests
| Test ID | Test Name | Query | Expected |
|---------|-----------|-------|----------|
| TC016 | Masking Policies | Masking policies created | >= 3 |
| TC017 | Tags Created | Classification tags exist | >= 3 |

## Execution Results

Run all tests using:
```sql
-- Execute 10_verification.sql
```
