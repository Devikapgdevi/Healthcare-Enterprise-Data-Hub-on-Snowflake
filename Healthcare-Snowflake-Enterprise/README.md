# 🏥 Healthcare Enterprise Data Hub on Snowflake
## Comprehensive Enterprise Snowflake Implementation

---

## 📋 Project Overview

| Attribute | Value |
|-----------|-------|
| **Industry** | Healthcare & Life Sciences (HCLS) |
| **Account** | tyb42779 |
| **Author** | DEVIKAPG |
| **Platform** | Snowflake with Cortex AI |
| **CI/CD** | GitHub Actions + Azure DevOps |

---

## 🏗️ Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        SNOWFLAKE ENTERPRISE DATA HUB                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │   GITHUB    │───▶│   AZURE     │───▶│  SNOWFLAKE  │───▶│  STREAMLIT  │  │
│  │    REPO     │    │   DEVOPS    │    │   ACCOUNT   │    │  DASHBOARD  │  │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘  │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                           SECURITY LAYER                                    │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  Network Policy │ Password Policy │ Session Policy │ MFA │ SSO       │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                           RBAC HIERARCHY                                    │
│                                                                             │
│                            ACCOUNTADMIN                                     │
│                                 │                                           │
│                         HC_ACCOUNT_ADMIN                                    │
│                    ┌────────────┼────────────┐                              │
│            HC_SECURITY    HC_DATA_ENG    HC_DATA_SCI                        │
│                 │              │                                            │
│                          HC_ANALYST                                         │
│                               │                                             │
│                          HC_VIEWER                                          │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                        COMPUTE LAYER                                        │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐            │
│  │ HC_ETL_WH  │  │HC_TRANS_WH │  │HC_ANALY_WH │  │  HC_AI_WH  │            │
│  │  MEDIUM    │  │   LARGE    │  │   MEDIUM   │  │   LARGE    │            │
│  │ Ingestion  │  │ Transform  │  │ Analytics  │  │   ML/AI    │            │
│  └────────────┘  └────────────┘  └────────────┘  └────────────┘            │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                      MEDALLION ARCHITECTURE                                 │
│                                                                             │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐     │
│  │   BRONZE    │──▶│   SILVER    │──▶│    GOLD     │──▶│  PLATINUM   │     │
│  │   RAW_DB    │   │TRANSFORM_DB │   │ANALYTICS_DB │   │ AI_READY_DB │     │
│  │             │   │             │   │             │   │             │     │
│  │ PATIENT_RAW │   │CLEAN_PATIENT│   │PAT_ANALYTICS│   │FEATURE_STORE│     │
│  │ ICU_EVENTS  │   │CLEAN_ICU    │   │BILL_ANALYTIC│   │ EMBEDDINGS  │     │
│  │ BILLING     │   │             │   │             │   │SEMANTIC_MDL │     │
│  │ DEVICE_ALRT │   │             │   │             │   │             │     │
│  └─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘     │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                      DATA GOVERNANCE (HORIZON)                              │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  Classification Tags │ Masking Policies │ Row Access │ Audit Trail   │  │
│  │    PII / PHI        │   SSN / Phone    │  Region    │  Login/Grants │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                         SUPPORT DATABASES                                   │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐            │
│  │SECURITY_DB │  │MONITORING  │  │  AUDIT_DB  │  │ DEVOPS_DB  │            │
│  │ Policies   │  │   Views    │  │   Trail    │  │   CI/CD    │            │
│  └────────────┘  └────────────┘  └────────────┘  └────────────┘            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
Healthcare-Snowflake-Enterprise/
│
├── 📄 README.md                          # This file
├── 📄 DEPLOYMENT_GUIDE.md                # Step-by-step deployment
│
├── 📂 sql/
│   ├── 01_account_administration.sql     # Phase 1: Account Setup
│   ├── 02_rbac_setup.sql                 # Phase 2: Roles & Hierarchy
│   ├── 03_warehouse_management.sql       # Phase 3: Compute Resources
│   ├── 04_database_structure.sql         # Phase 4: Database Schema
│   ├── 05_resource_monitors.sql          # Phase 5: Credit Monitoring
│   ├── 06_monitoring_views.sql           # Phase 6: 10+ Insight Views
│   ├── 07_alerts.sql                     # Phase 7: 10+ Alerts
│   ├── 08_data_governance.sql            # Phase 8: Horizon Features
│   ├── 09_audit_layer.sql                # Phase 9: Audit Trail
│   ├── 10_verification.sql               # Phase 10: Test Cases
│   ├── 11_medallion_architecture.sql     # Phase 11: Bronze→Platinum
│   ├── 13_ai_ready_layer.sql             # Phase 13: ML Features
│   └── 14_cicd_framework.sql             # Phase 14: Deployment Tracking
│
├── 📂 streamlit/
│   └── healthcare_dashboard.py           # Interactive Dashboard
│
├── 📂 .github/
│   └── workflows/
│       └── snowflake-deploy.yml          # GitHub Actions CI/CD
│
├── 📂 azure-devops/
│   ├── azure-pipelines.yml               # Azure Pipeline
│   └── work-items-template.md            # Epics & Tasks Template
│
└── 📂 docs/
    ├── phase_documentation.md            # All 15 Phases Documented
    └── test_cases.md                     # Test Scripts & Validation
```

---

## 🎯 Phase Completion Status

| Phase | Name | Status | Objects Created |
|-------|------|--------|-----------------|
| 1 | Account Administration | ✅ | Network, Password, Session Policies |
| 2 | RBAC Setup | ✅ | 6 Roles with Hierarchy |
| 3 | Warehouse Management | ✅ | 4 Workload-Specific Warehouses |
| 4 | Database Structure | ✅ | 7 Databases with Schemas |
| 5 | Resource Monitors | ✅ | 5 Monitors (Account + 4 Warehouse) |
| 6 | Monitoring | ✅ | 12 Consumption Insight Views |
| 7 | Alerts | ✅ | 10 Automated Alerts |
| 8 | Data Governance | ✅ | Tags, 3 Masking, Row Access |
| 9 | Audit | ✅ | 6 Audit Trail Views |
| 10 | Verification | ✅ | 15 Test Cases |
| 11 | Medallion Architecture | ✅ | 4 Layers, 85K+ Records |
| 12 | Industry | ✅ | Healthcare (HCLS) |
| 13 | AI-Ready Layer | ✅ | Feature Store, Embeddings |
| 14 | GitHub CI/CD | ✅ | Actions Workflow |
| 15 | Azure DevOps | ✅ | Pipeline + Work Items |

---

## 🗃️ Database Summary

| Database | Layer | Tables/Views | Purpose |
|----------|-------|--------------|---------|
| RAW_DB | Bronze | 4 Tables | Raw ingested data |
| TRANSFORM_DB | Silver | 2 Tables | Cleaned/transformed |
| ANALYTICS_DB | Gold | 2 Tables | Aggregated analytics |
| AI_READY_DB | Platinum | 3 Tables | ML features & embeddings |
| SECURITY_DB | Support | Policies | Security policies |
| MONITORING_DB | Support | 12 Views | Performance monitoring |
| AUDIT_DB | Support | 6 Views | Audit trail |
| DEVOPS_DB | Support | 2 Tables | CI/CD tracking |

---

## 👥 Role Hierarchy

```
ACCOUNTADMIN (Snowflake Built-in)
    └── HC_ACCOUNT_ADMIN (Healthcare Account Administrator)
            ├── HC_SECURITY_ADMIN (Security & Compliance)
            ├── HC_DATA_SCIENTIST (ML/AI Workloads)
            └── HC_DATA_ENGINEER (ETL & Transform)
                    └── HC_ANALYST (Analytics & Reporting)
                            └── HC_VIEWER (Read-Only Access)
```

---

## 🚀 Quick Start

```sql
-- Connect as ACCOUNTADMIN
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

-- Execute SQL files in order (01 through 14)
-- See sql/ folder for all scripts
```

---

## 📊 Data Volumes

| Layer | Table | Records |
|-------|-------|---------|
| Bronze | PATIENT_RAW | 10,000 |
| Bronze | ICU_EVENTS | 50,000 |
| Bronze | BILLING_DATA | 20,000 |
| Bronze | DEVICE_ALERTS | 5,000 |
| Silver | CLEAN_PATIENT | 10,000 |
| Silver | CLEAN_ICU_EVENTS | 50,000 |
| Gold | PATIENT_ANALYTICS | 10,000 |
| Gold | BILLING_ANALYTICS | 8,608 |
| Platinum | ICU_FEATURE_STORE | 10,000 |

**Total Records: 163,608+**

---

## 🔗 External Links

- **GitHub Repository**: [Your GitHub Repo URL]
- **Azure DevOps**: https://dev.azure.com/ArisData1/Snowflake
- **Snowflake Account**: tyb42779

---

## 📝 License

Internal Use Only - Healthcare Enterprise Data Hub

---

## 👤 Author

**DEVIKAPG**  
Snowflake Data Engineer  
February 2026
