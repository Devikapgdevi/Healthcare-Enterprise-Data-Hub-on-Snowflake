# Enterprise Healthcare Data Platform - Architecture & Deployment Guide

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Folder Structure](#folder-structure)
3. [Deployment Sequence](#deployment-sequence)
4. [Environment Strategy](#environment-strategy)
5. [Cost Governance](#cost-governance)
6. [Security & Compliance](#security--compliance)
7. [Identified Risks](#identified-risks)
8. [Architectural Improvements](#architectural-improvements)
9. [CI/CD Pipeline](#cicd-pipeline)
10. [Best Practices Applied](#best-practices-applied)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    ENTERPRISE HEALTHCARE DATA PLATFORM                       │
│                              Architecture v2.0                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                         CI/CD LAYER                                   │   │
│  │   GitHub Actions → Deploy.sh → SnowSQL → Snowflake                   │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                    │                                         │
│  ┌─────────────┬─────────────┬─────────────┐                                │
│  │     DEV     │     QA      │    PROD     │  ← Environment Isolation       │
│  │  (DEV_*)    │   (QA_*)    │   (No prefix)│                               │
│  └─────────────┴─────────────┴─────────────┘                                │
│                                    │                                         │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                      SECURITY LAYER                                   │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐     │   │
│  │  │  Network   │  │  Password  │  │  Session   │  │  Masking   │     │   │
│  │  │  Policy    │  │  Policy    │  │  Policy    │  │  Policies  │     │   │
│  │  └────────────┘  └────────────┘  └────────────┘  └────────────┘     │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                    │                                         │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                        RBAC LAYER                                     │   │
│  │                                                                       │   │
│  │    ACCOUNTADMIN                                                       │   │
│  │         └── HC_PLATFORM_ADMIN                                         │   │
│  │                 ├── HC_SECURITY_ADMIN                                 │   │
│  │                 ├── HC_DATA_ENGINEER ── HC_DATA_ANALYST ── HC_VIEWER  │   │
│  │                 └── HC_DATA_SCIENTIST                                 │   │
│  │                                                                       │   │
│  │    Service Roles: HC_SVC_ETL, HC_SVC_ANALYTICS, HC_SVC_ML            │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                    │                                         │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                      COMPUTE LAYER                                    │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐     │   │
│  │  │ HC_ETL_WH  │  │HC_TRANS_WH │  │HC_ANLYT_WH │  │  HC_AI_WH  │     │   │
│  │  │  + RM      │  │   + RM     │  │   + RM     │  │   + RM     │     │   │
│  │  │ (10-100cr) │  │ (15-150cr) │  │ (10-75cr)  │  │ (20-200cr) │     │   │
│  │  └────────────┘  └────────────┘  └────────────┘  └────────────┘     │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                    │                                         │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                   MEDALLION DATA LAYER                                │   │
│  │                                                                       │   │
│  │  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────────┐       │   │
│  │  │ RAW_DB  │───▶│CURATED  │───▶│ANALYTICS│───▶│ AI_READY_DB │       │   │
│  │  │ (Bronze)│    │   _DB   │    │   _DB   │    │  (Platinum) │       │   │
│  │  │         │    │ (Silver)│    │  (Gold) │    │             │       │   │
│  │  │ Landing │    │ Cleansed│    │ Dim/Fact│    │ Features    │       │   │
│  │  │ Raw     │    │ Conformed│   │ Agg/RPT │    │ Embeddings  │       │   │
│  │  │ External│    │ History │    │         │    │ Semantic    │       │   │
│  │  └─────────┘    └─────────┘    └─────────┘    └─────────────┘       │   │
│  │                                                                       │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                    │                                         │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                    OPERATIONS LAYER                                   │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐     │   │
│  │  │   OPS_DB   │  │ AUDIT_DB   │  │ SECURITY_DB│  │    DQ_DB   │     │   │
│  │  │ Deployment │  │ Compliance │  │ Governance │  │  Quality   │     │   │
│  │  │ Monitoring │  │ Access Hist│  │ Policies   │  │  Checks    │     │   │
│  │  └────────────┘  └────────────┘  └────────────┘  └────────────┘     │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Folder Structure

```
Healthcare-Snowflake-Enterprise-v2/
│
├── 📂 deploy/                          # Deployment scripts (numbered for order)
│   ├── 00_config.sql                   # Environment configuration
│   ├── 01_deployment_logger.sql        # Logging infrastructure
│   ├── 02_security_foundation.sql      # Security policies
│   ├── 03_rbac_hierarchy.sql           # Role-based access control
│   ├── 04_compute_infrastructure.sql   # Warehouses & resource monitors
│   ├── 05_data_architecture.sql        # Databases & schemas
│   ├── 06_medallion_tables.sql         # Bronze/Silver/Gold tables
│   ├── 07_governance_policies.sql      # Masking, row access, tags
│   ├── 08_monitoring_alerts.sql        # Monitoring views & alerts
│   ├── 09_audit_compliance.sql         # Audit trail setup
│   ├── 10_ai_ready_layer.sql           # ML features & embeddings
│   ├── 11_data_quality.sql             # DQ framework
│   └── 12_validation_tests.sql         # Post-deployment validation
│
├── 📂 rollback/                        # Rollback scripts
│   ├── 01_rollback.sql
│   ├── 02_rollback.sql
│   └── ...
│
├── 📂 tests/                           # Test scripts
│   ├── smoke_tests.sql                 # Quick validation
│   ├── integration_tests.sql           # Full integration tests
│   └── security_tests.sql              # Security validation
│
├── 📂 .github/workflows/               # CI/CD pipelines
│   └── snowflake-cicd.yml              # GitHub Actions workflow
│
├── 📂 docs/                            # Documentation
│   ├── ARCHITECTURE.md                 # This file
│   ├── RUNBOOK.md                      # Operations runbook
│   └── SECURITY.md                     # Security documentation
│
├── 📂 logs/                            # Deployment logs (gitignored)
│
├── deploy.sh                           # Deployment orchestrator
├── README.md                           # Project overview
└── .gitignore
```

---

## Deployment Sequence

| Order | Script | Phase | Dependencies | Description |
|-------|--------|-------|--------------|-------------|
| 0 | 00_config.sql | Config | None | Environment variables |
| 1 | 01_deployment_logger.sql | 0 | None | Logging infrastructure |
| 2 | 02_security_foundation.sql | 1 | 01 | Security policies |
| 3 | 03_rbac_hierarchy.sql | 2 | 02 | Roles & permissions |
| 4 | 04_compute_infrastructure.sql | 3 | 03 | Warehouses & monitors |
| 5 | 05_data_architecture.sql | 4 | 04 | Databases & schemas |
| 6 | 06_medallion_tables.sql | 5 | 05 | Data tables |
| 7 | 07_governance_policies.sql | 6 | 06 | Apply governance |
| 8 | 08_monitoring_alerts.sql | 7 | 07 | Monitoring |
| 9 | 09_audit_compliance.sql | 8 | 08 | Audit trail |
| 10 | 10_ai_ready_layer.sql | 9 | 09 | ML features |
| 11 | 11_data_quality.sql | 10 | 10 | DQ framework |
| 12 | 12_validation_tests.sql | 11 | All | Final validation |

---

## Environment Strategy

| Environment | Prefix | Warehouse Size | Credit Quota | Retention | Purpose |
|-------------|--------|----------------|--------------|-----------|---------|
| DEV | `DEV_` | XSMALL | 50 | 1 day | Development |
| QA | `QA_` | SMALL-MEDIUM | 100 | 7 days | Testing |
| PROD | (none) | MEDIUM-LARGE | 500 | 90 days | Production |

### Promotion Path
```
DEV → QA → PROD
 │     │     │
 │     │     └── Manual approval required
 │     └── Automated on main/release branches
 └── Automated on develop branch
```

---

## Cost Governance

### Resource Monitor Strategy

| Monitor | Scope | Quota | Triggers |
|---------|-------|-------|----------|
| HC_ACCOUNT_RM | Account | 500 (PROD) | 50%, 75%, 90%, 100% suspend |
| HC_ETL_WH_RM | ETL Warehouse | 100 | 75%, 90%, 100% suspend |
| HC_TRANSFORM_WH_RM | Transform WH | 150 | 75%, 90%, 100% suspend |
| HC_ANALYTICS_WH_RM | Analytics WH | 75 | 75%, 90%, 100% suspend |
| HC_AI_WH_RM | AI/ML WH | 200 | 50%, 75%, 90%, 100% suspend |

### Cost Optimization Features
- Auto-suspend: 60-300 seconds based on workload
- Auto-resume: Enabled for all warehouses
- Scaling policy: ECONOMY for analytics, STANDARD for ETL
- Multi-cluster: Limited by environment (1 DEV, 2-4 QA, 4-8 PROD)

---

## Security & Compliance

### Data Classification
- **PUBLIC**: Non-sensitive data
- **INTERNAL**: Internal use only
- **CONFIDENTIAL**: Business sensitive
- **RESTRICTED**: Highly sensitive
- **PHI**: Protected Health Information (HIPAA)
- **PII**: Personally Identifiable Information

### Masking Policies
| Policy | Data Type | Full Access | Partial Access | Masked |
|--------|-----------|-------------|----------------|--------|
| POL_MASK_SSN | SSN | Security Admin | Platform Admin (last 4) | XXX-XX-XXXX |
| POL_MASK_PHONE | Phone | Security Admin | Data Engineer | (XXX) XXX-XXXX |
| POL_MASK_NAME | Name | Admin roles | - | First initial only |
| POL_MASK_INSURANCE_ID | Insurance | Security Admin | - | INS-XXXX-XXXX |

---

## Identified Risks

### High Priority
| Risk | Impact | Mitigation |
|------|--------|------------|
| Network policy with 0.0.0.0/0 | Security breach | Restrict to corporate IPs in PROD |
| ACCOUNTADMIN usage | Over-privileged access | Use HC_PLATFORM_ADMIN for operations |
| No MFA enforcement | Account compromise | Enable MFA for all human users |

### Medium Priority
| Risk | Impact | Mitigation |
|------|--------|------------|
| Large warehouse sizes in DEV | Cost overrun | Enforce XSMALL in non-PROD |
| Missing data encryption | Compliance risk | Enable encryption for PHI columns |
| No backup strategy | Data loss | Implement fail-safe and replication |

### Low Priority
| Risk | Impact | Mitigation |
|------|--------|------------|
| Synthetic embeddings | AI accuracy | Replace with Cortex embeddings |
| Manual role assignments | Audit gaps | Use SCIM for user provisioning |

---

## Architectural Improvements

### Implemented in v2.0
1. ✅ Idempotent scripts with CREATE OR REPLACE / IF NOT EXISTS
2. ✅ Environment parameterization (DEV/QA/PROD)
3. ✅ Structured deployment logging
4. ✅ Object registry for traceability
5. ✅ Resource monitors on all warehouses
6. ✅ CI/CD pipeline with approval gates
7. ✅ Dependency sequencing
8. ✅ Post-deployment validation

### Recommended Future Improvements
1. 🔲 Implement Terraform for infrastructure-as-code
2. 🔲 Add Change Data Capture (CDC) with streams
3. 🔲 Implement data contracts with schema registry
4. 🔲 Add data quality scoring and SLAs
5. 🔲 Implement row-level security with mapping tables
6. 🔲 Add Cortex Search for semantic search
7. 🔲 Implement model registry for ML artifacts
8. 🔲 Add cost allocation tags per business unit

---

## CI/CD Pipeline

### Pipeline Stages
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Validate   │───▶│  Deploy DEV │───▶│  Deploy QA  │───▶│ Deploy PROD │
│             │    │             │    │             │    │  (Approval) │
│ - Lint SQL  │    │ - Execute   │    │ - Execute   │    │ - Execute   │
│ - Security  │    │ - Smoke test│    │ - Int. test │    │ - Validate  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

### Required Secrets
- `SNOWFLAKE_ACCOUNT`
- `SNOWFLAKE_USER`
- `SNOWFLAKE_PRIVATE_KEY`
- `SNOWFLAKE_PRIVATE_KEY_PROD` (separate for PROD)

---

## Best Practices Applied

### Data Engineering
- ✅ Medallion architecture (Bronze → Silver → Gold → Platinum)
- ✅ Separation of concerns (compute, storage, security)
- ✅ Data lineage tracking
- ✅ Schema evolution support

### Security
- ✅ Least privilege principle in RBAC
- ✅ Service accounts for non-human access
- ✅ Masking policies for sensitive data
- ✅ Row-level security framework

### Operations
- ✅ Structured logging for all deployments
- ✅ Object registry for inventory management
- ✅ Cost monitoring and forecasting
- ✅ Audit trail for compliance

### CI/CD
- ✅ Environment isolation (DEV/QA/PROD)
- ✅ Automated testing gates
- ✅ Manual approval for production
- ✅ Rollback capability

---

## Author
**DEVIKAPG**  
Healthcare Data Platform Team  
Version 2.0.0 | February 2026
