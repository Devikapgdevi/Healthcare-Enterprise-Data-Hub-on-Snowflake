import streamlit as st
import pandas as pd

# ======================
# SNOWFLAKE CONNECTION
# ======================
try:
    # Try Snowflake Native Streamlit first
    from snowflake.snowpark.context import get_active_session
    session = get_active_session()
    IS_NATIVE = True
    
    def run_query(query):
        return session.sql(query).to_pandas()
        
except ImportError:
    # Fallback for Streamlit Cloud
    import snowflake.connector
    IS_NATIVE = False
    
    @st.cache_resource
    def get_connection():
        return snowflake.connector.connect(
            account=st.secrets["snowflake"]["account"],
            user=st.secrets["snowflake"]["user"],
            password=st.secrets["snowflake"]["password"],
            warehouse=st.secrets["snowflake"]["warehouse"],
            role=st.secrets["snowflake"]["role"]
        )
    
    def run_query(query):
        conn = get_connection()
        return pd.read_sql(query, conn)

# ======================
# PAGE CONFIG
# ======================
st.set_page_config(
    page_title="Healthcare Enterprise Data Hub",
    page_icon="🏥",
    layout="wide"
)

# Header
st.title("🏥 Healthcare Enterprise Data Hub")
st.markdown("**Enterprise-grade Snowflake Healthcare Data Platform**")
st.markdown("---")

# Sidebar Navigation
st.sidebar.header("Navigation")
page = st.sidebar.radio("Select Page", [
    "📊 Overview",
    "👥 Patient Analytics",
    "🏨 ICU Monitoring",
    "💰 Billing Analytics",
    "📈 Monitoring",
    "🔐 Governance"
])

# ======================
# PAGE: OVERVIEW
# ======================
if page == "📊 Overview":
    st.header("Dashboard Overview")
    
    try:
        # Key Metrics
        col1, col2, col3, col4 = st.columns(4)
        
        patient_count = run_query("SELECT COUNT(*) as cnt FROM RAW_DB.RAW_SCHEMA.PATIENT_RAW")['CNT'][0]
        col1.metric("👥 Total Patients", f"{patient_count:,}")
        
        icu_count = run_query("SELECT COUNT(*) as cnt FROM RAW_DB.RAW_SCHEMA.ICU_EVENTS")['CNT'][0]
        col2.metric("🏨 ICU Events", f"{icu_count:,}")
        
        critical_count = run_query("SELECT COUNT(*) as cnt FROM TRANSFORM_DB.TRANSFORM_SCHEMA.CLEAN_ICU_EVENTS WHERE IS_CRITICAL = TRUE")['CNT'][0]
        col3.metric("⚠️ Critical Events", f"{critical_count:,}")
        
        billing_total = run_query("SELECT SUM(TOTAL_AMOUNT) as total FROM ANALYTICS_DB.ANALYTICS_SCHEMA.BILLING_ANALYTICS")['TOTAL'][0]
        col4.metric("💰 Total Billing", f"${billing_total:,.0f}")
        
        st.markdown("---")
        
        # Architecture Diagram
        st.subheader("🏗️ Medallion Architecture")
        
        arch_col1, arch_col2, arch_col3, arch_col4 = st.columns(4)
        
        with arch_col1:
            st.markdown("### 🥉 Bronze")
            st.markdown("**RAW_DB**")
            bronze_count = run_query("""
                SELECT SUM(cnt) as total FROM (
                    SELECT COUNT(*) as cnt FROM RAW_DB.RAW_SCHEMA.PATIENT_RAW
                    UNION ALL SELECT COUNT(*) FROM RAW_DB.RAW_SCHEMA.ICU_EVENTS
                    UNION ALL SELECT COUNT(*) FROM RAW_DB.RAW_SCHEMA.BILLING_DATA
                )
            """)['TOTAL'][0]
            st.metric("Records", f"{bronze_count:,}")
        
        with arch_col2:
            st.markdown("### 🥈 Silver")
            st.markdown("**TRANSFORM_DB**")
            silver_count = run_query("""
                SELECT SUM(cnt) as total FROM (
                    SELECT COUNT(*) as cnt FROM TRANSFORM_DB.TRANSFORM_SCHEMA.CLEAN_PATIENT
                    UNION ALL SELECT COUNT(*) FROM TRANSFORM_DB.TRANSFORM_SCHEMA.CLEAN_ICU_EVENTS
                )
            """)['TOTAL'][0]
            st.metric("Records", f"{silver_count:,}")
        
        with arch_col3:
            st.markdown("### 🥇 Gold")
            st.markdown("**ANALYTICS_DB**")
            gold_count = run_query("""
                SELECT SUM(cnt) as total FROM (
                    SELECT COUNT(*) as cnt FROM ANALYTICS_DB.ANALYTICS_SCHEMA.PATIENT_ANALYTICS
                    UNION ALL SELECT COUNT(*) FROM ANALYTICS_DB.ANALYTICS_SCHEMA.BILLING_ANALYTICS
                )
            """)['TOTAL'][0]
            st.metric("Records", f"{gold_count:,}")
        
        with arch_col4:
            st.markdown("### 💎 Platinum")
            st.markdown("**AI_READY_DB**")
            st.metric("Feature Store", "Active")
        
        st.markdown("---")
        
        # Diagnosis Distribution
        st.subheader("📊 Patient Distribution by Diagnosis")
        diagnosis_df = run_query("""
            SELECT DIAGNOSIS, COUNT(*) as PATIENT_COUNT 
            FROM RAW_DB.RAW_SCHEMA.PATIENT_RAW 
            GROUP BY DIAGNOSIS 
            ORDER BY PATIENT_COUNT DESC
        """)
        st.bar_chart(diagnosis_df.set_index('DIAGNOSIS'))
        
    except Exception as e:
        st.error(f"Connection Error: {str(e)}")
        st.info("Please configure Snowflake secrets in .streamlit/secrets.toml")

# ======================
# PAGE: PATIENT ANALYTICS
# ======================
elif page == "👥 Patient Analytics":
    st.header("Patient Analytics")
    
    try:
        # Filters
        col1, col2 = st.columns(2)
        with col1:
            diagnosis_filter = st.selectbox("Filter by Diagnosis", ["All", "Cardiology", "Neurology", "Orthopedics", "General"])
        with col2:
            gender_filter = st.selectbox("Filter by Gender", ["All", "M", "F"])
        
        # Build query
        query = "SELECT * FROM ANALYTICS_DB.ANALYTICS_SCHEMA.PATIENT_ANALYTICS WHERE 1=1"
        if diagnosis_filter != "All":
            query += f" AND DIAGNOSIS = '{diagnosis_filter}'"
        if gender_filter != "All":
            query += f" AND GENDER = '{gender_filter}'"
        query += " LIMIT 100"
        
        patient_df = run_query(query)
        
        # Metrics
        col1, col2, col3 = st.columns(3)
        col1.metric("Patients Shown", len(patient_df))
        col2.metric("Avg ICU Events", f"{patient_df['ICU_EVENT_COUNT'].mean():.1f}" if len(patient_df) > 0 else "N/A")
        col3.metric("Avg Critical Events", f"{patient_df['CRITICAL_EVENT_COUNT'].mean():.1f}" if len(patient_df) > 0 else "N/A")
        
        st.markdown("---")
        
        # Data Table
        st.subheader("Patient Data")
        st.dataframe(patient_df, use_container_width=True)
        
        # Age Distribution
        st.subheader("Age Distribution")
        age_df = run_query("""
            SELECT 
                CASE 
                    WHEN AGE < 30 THEN '18-29'
                    WHEN AGE < 50 THEN '30-49'
                    WHEN AGE < 70 THEN '50-69'
                    ELSE '70+'
                END as AGE_GROUP,
                COUNT(*) as COUNT
            FROM RAW_DB.RAW_SCHEMA.PATIENT_RAW
            GROUP BY AGE_GROUP
            ORDER BY AGE_GROUP
        """)
        st.bar_chart(age_df.set_index('AGE_GROUP'))
        
    except Exception as e:
        st.error(f"Error: {str(e)}")

# ======================
# PAGE: ICU MONITORING
# ======================
elif page == "🏨 ICU Monitoring":
    st.header("ICU Monitoring Dashboard")
    
    try:
        # Real-time Metrics
        col1, col2, col3, col4 = st.columns(4)
        
        critical_today = run_query("""
            SELECT COUNT(*) as cnt FROM TRANSFORM_DB.TRANSFORM_SCHEMA.CLEAN_ICU_EVENTS 
            WHERE IS_CRITICAL = TRUE AND EVENT_TIMESTAMP >= CURRENT_DATE()
        """)['CNT'][0]
        col1.metric("🚨 Critical Today", critical_today)
        
        avg_hr = run_query("SELECT ROUND(AVG(HEART_RATE), 1) as avg_hr FROM RAW_DB.RAW_SCHEMA.ICU_EVENTS")['AVG_HR'][0]
        col2.metric("❤️ Avg Heart Rate", avg_hr)
        
        avg_o2 = run_query("SELECT ROUND(AVG(OXYGEN_LEVEL), 1) as avg_o2 FROM RAW_DB.RAW_SCHEMA.ICU_EVENTS")['AVG_O2'][0]
        col3.metric("🫁 Avg Oxygen Level", f"{avg_o2}%")
        
        total_events = run_query("SELECT COUNT(*) as cnt FROM RAW_DB.RAW_SCHEMA.ICU_EVENTS")['CNT'][0]
        col4.metric("📊 Total Events", f"{total_events:,}")
        
        st.markdown("---")
        
        # Critical Events by Type
        st.subheader("⚠️ Critical Events by Type")
        critical_df = run_query("""
            SELECT EVENT_TYPE, COUNT(*) as CRITICAL_COUNT
            FROM TRANSFORM_DB.TRANSFORM_SCHEMA.CLEAN_ICU_EVENTS
            WHERE IS_CRITICAL = TRUE
            GROUP BY EVENT_TYPE
            ORDER BY CRITICAL_COUNT DESC
        """)
        st.bar_chart(critical_df.set_index('EVENT_TYPE'))
        
        # Recent Critical Events
        st.subheader("🚨 Recent Critical Events")
        recent_critical = run_query("""
            SELECT EVENT_ID, PATIENT_ID, EVENT_TYPE, HEART_RATE, OXYGEN_LEVEL, EVENT_TIMESTAMP
            FROM TRANSFORM_DB.TRANSFORM_SCHEMA.CLEAN_ICU_EVENTS
            WHERE IS_CRITICAL = TRUE
            ORDER BY EVENT_TIMESTAMP DESC
            LIMIT 20
        """)
        st.dataframe(recent_critical, use_container_width=True)
        
        # Vitals Distribution
        st.subheader("📈 Vitals Distribution")
        col1, col2 = st.columns(2)
        
        with col1:
            st.markdown("**Heart Rate Distribution**")
            hr_df = run_query("""
                SELECT 
                    CASE 
                        WHEN HEART_RATE < 60 THEN 'Low (<60)'
                        WHEN HEART_RATE <= 100 THEN 'Normal (60-100)'
                        ELSE 'High (>100)'
                    END as HR_CATEGORY,
                    COUNT(*) as COUNT
                FROM RAW_DB.RAW_SCHEMA.ICU_EVENTS
                GROUP BY HR_CATEGORY
            """)
            st.bar_chart(hr_df.set_index('HR_CATEGORY'))
        
        with col2:
            st.markdown("**Oxygen Level Distribution**")
            o2_df = run_query("""
                SELECT 
                    CASE 
                        WHEN OXYGEN_LEVEL < 90 THEN 'Critical (<90%)'
                        WHEN OXYGEN_LEVEL < 95 THEN 'Low (90-94%)'
                        ELSE 'Normal (95%+)'
                    END as O2_CATEGORY,
                    COUNT(*) as COUNT
                FROM RAW_DB.RAW_SCHEMA.ICU_EVENTS
                GROUP BY O2_CATEGORY
            """)
            st.bar_chart(o2_df.set_index('O2_CATEGORY'))
            
    except Exception as e:
        st.error(f"Error: {str(e)}")

# ======================
# PAGE: BILLING ANALYTICS
# ======================
elif page == "💰 Billing Analytics":
    st.header("Billing Analytics")
    
    try:
        # Summary Metrics
        billing_summary = run_query("""
            SELECT 
                SUM(TOTAL_AMOUNT) as TOTAL,
                SUM(PAID_AMOUNT) as PAID,
                SUM(PENDING_AMOUNT) as PENDING,
                SUM(OVERDUE_AMOUNT) as OVERDUE
            FROM ANALYTICS_DB.ANALYTICS_SCHEMA.BILLING_ANALYTICS
        """)
        
        col1, col2, col3, col4 = st.columns(4)
        col1.metric("💵 Total Billed", f"${billing_summary['TOTAL'][0]:,.0f}")
        col2.metric("✅ Paid", f"${billing_summary['PAID'][0]:,.0f}")
        col3.metric("⏳ Pending", f"${billing_summary['PENDING'][0]:,.0f}")
        col4.metric("❌ Overdue", f"${billing_summary['OVERDUE'][0]:,.0f}")
        
        st.markdown("---")
        
        # Billing Status Distribution
        st.subheader("📊 Billing Status Distribution")
        status_df = run_query("""
            SELECT STATUS, COUNT(*) as COUNT, SUM(AMOUNT) as TOTAL_AMOUNT
            FROM RAW_DB.RAW_SCHEMA.BILLING_DATA
            GROUP BY STATUS
        """)
        st.bar_chart(status_df.set_index('STATUS')['TOTAL_AMOUNT'])
        
        # Top Patients by Billing
        st.subheader("💰 Top 10 Patients by Total Billing")
        top_billing = run_query("""
            SELECT PATIENT_ID, TOTAL_BILLS, TOTAL_AMOUNT, PAID_AMOUNT, OVERDUE_AMOUNT
            FROM ANALYTICS_DB.ANALYTICS_SCHEMA.BILLING_ANALYTICS
            ORDER BY TOTAL_AMOUNT DESC
            LIMIT 10
        """)
        st.dataframe(top_billing, use_container_width=True)
        
    except Exception as e:
        st.error(f"Error: {str(e)}")

# ======================
# PAGE: MONITORING
# ======================
elif page == "📈 Monitoring":
    st.header("System Monitoring")
    
    try:
        # Credit Usage
        st.subheader("💳 Credit Usage (Last 30 Days)")
        credit_df = run_query("""
            SELECT * FROM MONITORING_DB.MONITORING_SCHEMA.CREDIT_USAGE_VIEW
            ORDER BY USAGE_DATE DESC
            LIMIT 30
        """)
        
        if len(credit_df) > 0:
            st.bar_chart(credit_df.set_index('USAGE_DATE')['DAILY_CREDITS'])
        else:
            st.info("No credit usage data available")
        
        # Query Performance
        st.subheader("⚡ Recent Query Performance")
        query_df = run_query("""
            SELECT QUERY_ID, USER_NAME, WAREHOUSE_NAME, EXECUTION_STATUS, 
                   ROUND(TOTAL_ELAPSED_TIME/1000, 2) as ELAPSED_SECONDS
            FROM MONITORING_DB.MONITORING_SCHEMA.QUERY_HISTORY_VIEW
            ORDER BY START_TIME DESC
            LIMIT 20
        """)
        st.dataframe(query_df, use_container_width=True)
        
    except Exception as e:
        st.error(f"Error: {str(e)}")

# ======================
# PAGE: GOVERNANCE
# ======================
elif page == "🔐 Governance":
    st.header("Data Governance & Compliance")
    
    # RBAC Summary
    st.subheader("👥 Role Hierarchy")
    st.code("""
    ACCOUNTADMIN
        └── HC_ACCOUNT_ADMIN
                ├── HC_SECURITY_ADMIN
                ├── HC_DATA_SCIENTIST
                └── HC_DATA_ENGINEER
                        └── HC_ANALYST
                                └── HC_VIEWER
    """)
    
    # Masking Policies
    st.subheader("🎭 Data Masking Policies")
    masking_data = {
        "Policy": ["SSN_MASK", "PHONE_MASK", "INSURANCE_MASK"],
        "Protected Data": ["Social Security Numbers", "Phone Numbers", "Insurance Numbers"],
        "Visible To": [
            "ACCOUNTADMIN, HC_ACCOUNT_ADMIN, HC_DATA_ENGINEER",
            "ACCOUNTADMIN, HC_ACCOUNT_ADMIN, HC_DATA_ENGINEER", 
            "ACCOUNTADMIN, HC_ACCOUNT_ADMIN"
        ]
    }
    st.dataframe(pd.DataFrame(masking_data), use_container_width=True)
    
    # Compliance Metrics
    st.subheader("📋 Compliance Summary")
    col1, col2, col3 = st.columns(3)
    col1.metric("🏷️ Classification Tags", "3")
    col2.metric("🎭 Masking Policies", "3")
    col3.metric("🚪 Row Access Policies", "1")
    
    # HIPAA Compliance
    st.subheader("🏥 HIPAA Compliance Checklist")
    st.markdown("""
    - ✅ Data encryption at rest and in transit
    - ✅ Role-based access control (RBAC)
    - ✅ Audit logging enabled
    - ✅ PHI/PII masking policies active
    - ✅ Session timeout policies configured
    - ✅ Password policies enforced
    """)

# Footer
st.markdown("---")
st.caption("Healthcare Enterprise Data Hub © 2026 | Account: tyb42779 | User: DEVIKAPG")
