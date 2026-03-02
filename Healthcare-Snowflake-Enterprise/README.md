# Healthcare Enterprise Data Hub on Snowflake

Enterprise-grade Snowflake Healthcare Data Platform with RBAC, Medallion Architecture, Governance, Monitoring & CI/CD

## Project Overview

| Component | Details |
|-----------|---------|
| **Account** | tyb42779 |
| **Author** | DEVIKAPG |
| **Architecture** | Medallion (Bronze → Silver → Gold → Platinum) |
| **Total Records** | 168,608+ |

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        SNOWFLAKE ENTERPRISE DATA HUB                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                      MEDALLION ARCHITECTURE                                 │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐     │
│  │   BRONZE    │──▶│   SILVER    │──▶│    GOLD     │──▶│  PLATINUM   │     │
│  │   RAW_DB    │   │TRANSFORM_DB │   │ANALYTICS_DB │   │ AI_READY_DB │     │
│  └─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘     │
└─────────────────────────────────────────────────────────────────────────────┘
```

## SQL Scripts (Execute in Order)

| # | Script | Purpose |
|---|--------|---------|
| 1 | `01_account_administration.sql` | Account setup, policies |
| 2 | `02_rbac_setup.sql` | Role hierarchy (6 roles) |
| 3 | `03_warehouse_management.sql` | 4 warehouses |
| 4 | `04_database_structure.sql` | 8 databases |
| 5 | `05_resource_monitors.sql` | Cost controls |
| 6 | `06_monitoring_views.sql` | 8 monitoring views |
| 7 | `07_alerts.sql` | Automated alerts |
| 8 | `08_data_governance.sql` | Tags, masking policies |
| 9 | `09_audit_layer.sql` | Audit views |
| 10 | `10_verification.sql` | Validation scripts |
| 11 | `11_medallion_architecture.sql` | Data tables (Bronze/Silver/Gold) |
| 12 | `12_healthcare_industry.sql` | Healthcare domain |
| 13 | `13_ai_ready_layer.sql` | ML Feature Store |

## Quick Start

```sql
-- Run master deployment
@Healthcare-Snowflake-Enterprise/sql/master_deployment.sql
```

## CI/CD

- **GitHub Actions**: `.github/workflows/snowflake-deploy.yml`
- **Azure DevOps**: `azure-devops/azure-pipelines.yml`

## Required GitHub Secrets

- `SNOWFLAKE_ACCOUNT`
- `SNOWFLAKE_USER`
- `SNOWFLAKE_PASSWORD`
