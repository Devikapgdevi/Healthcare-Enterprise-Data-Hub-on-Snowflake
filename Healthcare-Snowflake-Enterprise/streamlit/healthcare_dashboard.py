import streamlit as st
from snowflake.snowpark.context import get_active_session

session = get_active_session()

st.title("Healthcare Dashboard")

st.header("Overview")

col1, col2, col3 = st.columns(3)

with col1:
    df = session.sql("SELECT COUNT(*) as CNT FROM RAW_DB.RAW_SCHEMA.PATIENT_RAW").to_pandas()
    st.metric("Patients", int(df['CNT'][0]))

with col2:
    df = session.sql("SELECT COUNT(*) as CNT FROM RAW_DB.RAW_SCHEMA.ICU_EVENTS").to_pandas()
    st.metric("ICU Events", int(df['CNT'][0]))

with col3:
    df = session.sql("SELECT COUNT(*) as CNT FROM RAW_DB.RAW_SCHEMA.BILLING_DATA").to_pandas()
    st.metric("Bills", int(df['CNT'][0]))

st.subheader("Select Diagnosis")
diagnosis = st.selectbox("Diagnosis", ["All", "Cardiology", "Neurology", "Orthopedics", "General"])

if diagnosis == "All":
    df = session.sql("SELECT PATIENT_ID, NAME, AGE, GENDER, DIAGNOSIS FROM RAW_DB.RAW_SCHEMA.PATIENT_RAW LIMIT 50").to_pandas()
else:
    df = session.sql(f"SELECT PATIENT_ID, NAME, AGE, GENDER, DIAGNOSIS FROM RAW_DB.RAW_SCHEMA.PATIENT_RAW WHERE DIAGNOSIS = '{diagnosis}' LIMIT 50").to_pandas()

st.write(f"Showing {len(df)} patients")
st.dataframe(df)
