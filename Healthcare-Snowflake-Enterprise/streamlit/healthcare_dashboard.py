# Healthcare Enterprise Data Hub Dashboard
import streamlit as st
from snowflake.snowpark.context import get_active_session

st.set_page_config(page_title="Healthcare Dashboard", page_icon="🏥", layout="wide")

# Get session
session = get_active_session()

st.title("🏥 Healthcare Enterprise Data Hub")
st.markdown("---")

# Sidebar
page = st.sidebar.selectbox("Select Page", [
    "Overview",
    "Patient Analytics", 
    "ICU Monitoring",
    "Billing"
])

if page == "Overview":
    st.header("📊 Dashboard Overview")
    
    col1, col2, col3, col4 = st.columns(4)
    
    with col1:
        df = session.sql("SELECT COUNT(*) as CNT FROM RAW_DB.RAW_SCHEMA.PATIENT_RAW").to_pandas()
        st.metric("Total Patients", f"{df['CNT'][0]:,}")
    
    with col2:
        df = session.sql("SELECT COUNT(*) as CNT FROM RAW_DB.RAW_SCHEMA.ICU_EVENTS").to_pandas()
        st.metric("ICU Events", f"{df['CNT'][0]:,}")
    
    with col3:
        df = session.sql("SELECT COUNT(*) as CNT FROM TRANSFORM_DB.TRANSFORM_SCHEMA.CLEAN_ICU_EVENTS WHERE IS_CRITICAL = TRUE").to_pandas()
        st.metric("Critical Events", f"{df['CNT'][0]:,}")
    
    with col4:
        df = session.sql("SELECT COUNT(*) as CNT FROM RAW_DB.RAW_SCHEMA.BILLING_DATA").to_pandas()
        st.metric("Total Bills", f"{df['CNT'][0]:,}")
    
    st.markdown("---")
    st.subheader("Patient Distribution by Diagnosis")
    df = session.sql("""
        SELECT DIAGNOSIS, COUNT(*) as PATIENT_COUNT 
        FROM RAW_DB.RAW_SCHEMA.PATIENT_RAW 
        GROUP BY DIAGNOSIS
    """).to_pandas()
    st.bar_chart(df.set_index('DIAGNOSIS'))

elif page == "Patient Analytics":
    st.header("👥 Patient Analytics")
    
    df = session.sql("""
        SELECT PATIENT_ID, NAME, AGE, GENDER, DIAGNOSIS, ICU_EVENT_COUNT, CRITICAL_EVENT_COUNT
        FROM ANALYTICS_DB.ANALYTICS_SCHEMA.PATIENT_ANALYTICS
        LIMIT 50
    """).to_pandas()
    
    st.dataframe(df, use_container_width=True)

elif page == "ICU Monitoring":
    st.header("🏨 ICU Monitoring")
    
    col1, col2 = st.columns(2)
    
    with col1:
        df = session.sql("SELECT ROUND(AVG(HEART_RATE),1) as AVG FROM RAW_DB.RAW_SCHEMA.ICU_EVENTS").to_pandas()
        st.metric("Avg Heart Rate", df['AVG'][0])
    
    with col2:
        df = session.sql("SELECT ROUND(AVG(OXYGEN_LEVEL),1) as AVG FROM RAW_DB.RAW_SCHEMA.ICU_EVENTS").to_pandas()
        st.metric("Avg Oxygen Level", f"{df['AVG'][0]}%")
    
    st.subheader("Recent Critical Events")
    df = session.sql("""
        SELECT EVENT_ID, PATIENT_ID, EVENT_TYPE, HEART_RATE, OXYGEN_LEVEL
        FROM TRANSFORM_DB.TRANSFORM_SCHEMA.CLEAN_ICU_EVENTS
        WHERE IS_CRITICAL = TRUE
        LIMIT 20
    """).to_pandas()
    st.dataframe(df, use_container_width=True)

elif page == "Billing":
    st.header("💰 Billing Analytics")
    
    df = session.sql("""
        SELECT 
            SUM(TOTAL_AMOUNT) as TOTAL,
            SUM(PAID_AMOUNT) as PAID,
            SUM(PENDING_AMOUNT) as PENDING,
            SUM(OVERDUE_AMOUNT) as OVERDUE
        FROM ANALYTICS_DB.ANALYTICS_SCHEMA.BILLING_ANALYTICS
    """).to_pandas()
    
    col1, col2, col3, col4 = st.columns(4)
    col1.metric("Total", f"${df['TOTAL'][0]:,.0f}")
    col2.metric("Paid", f"${df['PAID'][0]:,.0f}")
    col3.metric("Pending", f"${df['PENDING'][0]:,.0f}")
    col4.metric("Overdue", f"${df['OVERDUE'][0]:,.0f}")
    
    st.subheader("Billing by Status")
    df = session.sql("""
        SELECT STATUS, SUM(AMOUNT) as AMOUNT
        FROM RAW_DB.RAW_SCHEMA.BILLING_DATA
        GROUP BY STATUS
    """).to_pandas()
    st.bar_chart(df.set_index('STATUS'))

st.markdown("---")
st.caption("Healthcare Enterprise Data Hub | Account: tyb42779")
