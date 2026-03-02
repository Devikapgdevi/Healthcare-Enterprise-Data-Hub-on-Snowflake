import streamlit as st
from snowflake.snowpark.context import get_active_session

st.set_page_config(page_title="Healthcare Dashboard", page_icon="🏥", layout="wide")

session = get_active_session()

st.title("🏥 Healthcare Enterprise Data Hub")
st.markdown("---")

page = st.sidebar.selectbox("Select Page", ["Overview", "Patient Analytics", "ICU Monitoring", "Billing"])

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
    
    st.subheader("🔍 Select Diagnosis to View Patients")
    selected_diagnosis = st.selectbox("Choose Diagnosis", ["All", "Cardiology", "Neurology", "Orthopedics", "General"])
    
    st.subheader("Patient Distribution by Diagnosis")
    df = session.sql("SELECT DIAGNOSIS, COUNT(*) as PATIENT_COUNT FROM RAW_DB.RAW_SCHEMA.PATIENT_RAW GROUP BY DIAGNOSIS").to_pandas()
    st.bar_chart(df.set_index('DIAGNOSIS'))
    
    st.markdown("---")
    
    if selected_diagnosis == "All":
        st.subheader("👥 All Patients")
        patient_df = session.sql("SELECT PATIENT_ID, NAME, AGE, GENDER, DIAGNOSIS, ADMISSION_DATE FROM RAW_DB.RAW_SCHEMA.PATIENT_RAW ORDER BY ADMISSION_DATE DESC LIMIT 50").to_pandas()
    else:
        st.subheader(f"👥 Patients with {selected_diagnosis}")
        patient_df = session.sql(f"SELECT PATIENT_ID, NAME, AGE, GENDER, DIAGNOSIS, ADMISSION_DATE FROM RAW_DB.RAW_SCHEMA.PATIENT_RAW WHERE DIAGNOSIS = '{selected_diagnosis}' ORDER BY ADMISSION_DATE DESC LIMIT 50").to_pandas()
    
    st.info(f"Showing {len(patient_df)} patients")
    st.dataframe(patient_df, use_container_width=True)
    
    if selected_diagnosis != "All":
        st.markdown("---")
        st.subheader(f"📈 {selected_diagnosis} Analytics")
        
        col1, col2, col3 = st.columns(3)
        
        analytics_df = session.sql(f"""
            SELECT COUNT(*) as TOTAL, ROUND(AVG(AGE), 1) as AVG_AGE,
                   SUM(CASE WHEN GENDER = 'M' THEN 1 ELSE 0 END) as MALE,
                   SUM(CASE WHEN GENDER = 'F' THEN 1 ELSE 0 END) as FEMALE
            FROM RAW_DB.RAW_SCHEMA.PATIENT_RAW WHERE DIAGNOSIS = '{selected_diagnosis}'
        """).to_pandas()
        
        col1.metric("Total Patients", f"{analytics_df['TOTAL'][0]:,}")
        col2.metric("Average Age", analytics_df['AVG_AGE'][0])
        col3.metric("Male / Female", f"{analytics_df['MALE'][0]} / {analytics_df['FEMALE'][0]}")

elif page == "Patient Analytics":
    st.header("👥 Patient Analytics")
    
    col1, col2, col3 = st.columns(3)
    with col1:
        diagnosis_filter = st.selectbox("Diagnosis", ["All", "Cardiology", "Neurology", "Orthopedics", "General"])
    with col2:
        gender_filter = st.selectbox("Gender", ["All", "M", "F"])
    with col3:
        age_filter = st.selectbox("Age Group", ["All", "18-30", "31-50", "51-70", "70+"])
    
    query = "SELECT PATIENT_ID, NAME, AGE, GENDER, DIAGNOSIS, ICU_EVENT_COUNT, CRITICAL_EVENT_COUNT FROM ANALYTICS_DB.ANALYTICS_SCHEMA.PATIENT_ANALYTICS WHERE 1=1"
    
    if diagnosis_filter != "All":
        query += f" AND DIAGNOSIS = '{diagnosis_filter}'"
    if gender_filter != "All":
        query += f" AND GENDER = '{gender_filter}'"
    if age_filter == "18-30":
        query += " AND AGE BETWEEN 18 AND 30"
    elif age_filter == "31-50":
        query += " AND AGE BETWEEN 31 AND 50"
    elif age_filter == "51-70":
        query += " AND AGE BETWEEN 51 AND 70"
    elif age_filter == "70+":
        query += " AND AGE > 70"
    
    query += " LIMIT 100"
    df = session.sql(query).to_pandas()
    
    col1, col2, col3 = st.columns(3)
    col1.metric("Patients Found", len(df))
    col2.metric("Avg ICU Events", f"{df['ICU_EVENT_COUNT'].mean():.1f}" if len(df) > 0 else "N/A")
    col3.metric("Avg Critical", f"{df['CRITICAL_EVENT_COUNT'].mean():.1f}" if len(df) > 0 else "N/A")
    
    st.dataframe(df, use_container_width=True)
    
    if len(df) > 0:
        st.markdown("---")
        st.subheader("🔍 View Patient ICU Events")
        selected_patient = st.selectbox("Select Patient", df['PATIENT_ID'].tolist())
        
        events_df = session.sql(f"SELECT EVENT_ID, EVENT_TYPE, HEART_RATE, OXYGEN_LEVEL, IS_CRITICAL, EVENT_TIMESTAMP FROM TRANSFORM_DB.TRANSFORM_SCHEMA.CLEAN_ICU_EVENTS WHERE PATIENT_ID = '{selected_patient}' ORDER BY EVENT_TIMESTAMP DESC LIMIT 20").to_pandas()
        st.dataframe(events_df, use_container_width=True)

elif page == "ICU Monitoring":
    st.header("🏨 ICU Monitoring")
    
    col1, col2 = st.columns(2)
    with col1:
        df = session.sql("SELECT ROUND(AVG(HEART_RATE),1) as AVG FROM RAW_DB.RAW_SCHEMA.ICU_EVENTS").to_pandas()
        st.metric("Avg Heart Rate", df['AVG'][0])
    with col2:
        df = session.sql("SELECT ROUND(AVG(OXYGEN_LEVEL),1) as AVG FROM RAW_DB.RAW_SCHEMA.ICU_EVENTS").to_pandas()
        st.metric("Avg Oxygen Level", f"{df['AVG'][0]}%")
    
    st.markdown("---")
    event_type = st.selectbox("Filter by Event Type", ["All", "Vitals Check", "Medication", "Procedure", "Alert", "Transfer"])
    
    if event_type == "All":
        df = session.sql("SELECT EVENT_ID, PATIENT_ID, EVENT_TYPE, HEART_RATE, OXYGEN_LEVEL, EVENT_TIMESTAMP FROM TRANSFORM_DB.TRANSFORM_SCHEMA.CLEAN_ICU_EVENTS WHERE IS_CRITICAL = TRUE ORDER BY EVENT_TIMESTAMP DESC LIMIT 30").to_pandas()
    else:
        df = session.sql(f"SELECT EVENT_ID, PATIENT_ID, EVENT_TYPE, HEART_RATE, OXYGEN_LEVEL, EVENT_TIMESTAMP FROM TRANSFORM_DB.TRANSFORM_SCHEMA.CLEAN_ICU_EVENTS WHERE IS_CRITICAL = TRUE AND EVENT_TYPE = '{event_type}' ORDER BY EVENT_TIMESTAMP DESC LIMIT 30").to_pandas()
    
    st.subheader(f"🚨 Critical Events ({event_type})")
    st.info(f"Showing {len(df)} events")
    st.dataframe(df, use_container_width=True)

elif page == "Billing":
    st.header("💰 Billing Analytics")
    
    df = session.sql("SELECT SUM(TOTAL_AMOUNT) as TOTAL, SUM(PAID_AMOUNT) as PAID, SUM(PENDING_AMOUNT) as PENDING, SUM(OVERDUE_AMOUNT) as OVERDUE FROM ANALYTICS_DB.ANALYTICS_SCHEMA.BILLING_ANALYTICS").to_pandas()
    
    col1, col2, col3, col4 = st.columns(4)
    col1.metric("Total", f"${df['TOTAL'][0]:,.0f}")
    col2.metric("Paid", f"${df['PAID'][0]:,.0f}")
    col3.metric("Pending", f"${df['PENDING'][0]:,.0f}")
    col4.metric("Overdue", f"${df['OVERDUE'][0]:,.0f}")
    
    st.markdown("---")
    status_filter = st.selectbox("Filter by Status", ["All", "PAID", "PENDING", "OVERDUE"])
    
    st.subheader("Billing by Status")
    chart_df = session.sql("SELECT STATUS, SUM(AMOUNT) as AMOUNT FROM RAW_DB.RAW_SCHEMA.BILLING_DATA GROUP BY STATUS").to_pandas()
    st.bar_chart(chart_df.set_index('STATUS'))
    
    st.markdown("---")
    if status_filter == "All":
        billing_df = session.sql("SELECT BILL_ID, PATIENT_ID, AMOUNT, BILL_DATE, STATUS FROM RAW_DB.RAW_SCHEMA.BILLING_DATA ORDER BY BILL_DATE DESC LIMIT 50").to_pandas()
    else:
        billing_df = session.sql(f"SELECT BILL_ID, PATIENT_ID, AMOUNT, BILL_DATE, STATUS FROM RAW_DB.RAW_SCHEMA.BILLING_DATA WHERE STATUS = '{status_filter}' ORDER BY BILL_DATE DESC LIMIT 50").to_pandas()
    
    st.subheader(f"📋 {status_filter} Bills")
    st.dataframe(billing_df, use_container_width=True)

st.markdown("---")
st.caption("Healthcare Enterprise Data Hub | Account: tyb42779")
