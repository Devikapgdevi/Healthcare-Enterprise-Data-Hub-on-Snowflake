# Healthcare Enterprise Dashboard
# Streamlit Application for Snowflake Healthcare Data Hub

import streamlit as st

# Page Configuration
st.set_page_config(
    page_title="Healthcare Enterprise Data Hub",
    page_icon="🏥",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Connection (uses native Snowflake connection in Snowsight)
# When running in Snowsight, connection is automatic
# For local development, use snowflake.connector

def get_connection():
    """Get Snowflake connection - works in Snowsight natively"""
    try:
        # In Snowsight, use session
        from snowflake.snowpark.context import get_active_session
        return get_active_session()
    except:
        # For local dev
        import snowflake.connector
        return snowflake.connector.connect(
            account='tyb42779',
            user='DEVIKAPG',
            authenticator='externalbrowser',
            role='ACCOUNTADMIN',
            warehouse='COMPUTE_WH'
        )

# Sidebar Navigation
st.sidebar.title("🏥 Healthcare Hub")
page = st.sidebar.radio(
    "Navigate",
    ["📊 Dashboard", "👥 Patients", "🏃 ICU Monitor", "💰 Billing", "⚠️ Risk Analysis", "📈 Performance"]
)

# Main Dashboard
if page == "📊 Dashboard":
    st.title("Healthcare Enterprise Data Hub")
    st.markdown("### Real-time Analytics Dashboard")
    
    # KPI Metrics
    col1, col2, col3, col4 = st.columns(4)
    
    with col1:
        st.metric("Total Patients", "10,000", "+150 today")
    with col2:
        st.metric("ICU Events", "50,000", "+2,340 today")
    with col3:
        st.metric("Critical Patients", "1,247", "-23 from yesterday")
    with col4:
        st.metric("Revenue", "$12.5M", "+$500K")
    
    st.markdown("---")
    
    # Charts
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("📊 Patient Distribution by Diagnosis")
        st.bar_chart({
            "Cardiology": 2500,
            "Neurology": 2100,
            "Pulmonology": 1800,
            "Orthopedics": 1600,
            "General": 2000
        })
    
    with col2:
        st.subheader("📈 ICU Events Trend")
        import pandas as pd
        dates = pd.date_range(start='2026-02-01', periods=27, freq='D')
        events = [1500 + i*50 for i in range(27)]
        st.line_chart(pd.DataFrame({"Events": events}, index=dates))

# Patients Page
elif page == "👥 Patients":
    st.title("Patient Management")
    
    # Filters
    col1, col2, col3 = st.columns(3)
    with col1:
        diagnosis = st.selectbox("Diagnosis", ["All", "Cardiology", "Neurology", "Pulmonology", "Orthopedics", "General"])
    with col2:
        region = st.selectbox("Region", ["All", "North", "South", "East", "West"])
    with col3:
        risk = st.selectbox("Risk Level", ["All", "Critical", "High", "Medium", "Low"])
    
    st.markdown("---")
    
    # Sample Patient Data
    st.subheader("Patient List (Sample)")
    patient_data = {
        "Patient ID": ["P00001", "P00002", "P00003", "P00004", "P00005"],
        "Name": ["Patient_00001", "Patient_00002", "Patient_00003", "Patient_00004", "Patient_00005"],
        "Age": [45, 67, 32, 78, 54],
        "Gender": ["M", "F", "M", "F", "M"],
        "Diagnosis": ["Cardiology", "Neurology", "General", "Pulmonology", "Orthopedics"],
        "Risk Score": [2, 4, 1, 3, 2],
        "Status": ["Stable", "Critical", "Stable", "High", "Stable"]
    }
    st.dataframe(patient_data, use_container_width=True)

# ICU Monitor
elif page == "🏃 ICU Monitor":
    st.title("ICU Real-time Monitor")
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("❤️ Heart Rate Distribution")
        hr_data = {"60-80": 30, "80-100": 45, "100-120": 20, ">120": 5}
        st.bar_chart(hr_data)
    
    with col2:
        st.subheader("🫁 Oxygen Level Distribution")
        o2_data = {"95-100%": 60, "92-95%": 25, "88-92%": 10, "<88%": 5}
        st.bar_chart(o2_data)
    
    st.markdown("---")
    
    st.subheader("⚠️ Recent Critical Alerts")
    alerts = {
        "Time": ["14:32:15", "14:28:43", "14:25:01", "14:20:55"],
        "Patient": ["P03421", "P07832", "P01234", "P09876"],
        "Alert Type": ["Low Oxygen", "High Heart Rate", "High BP", "Low Oxygen"],
        "Value": ["87%", "135 bpm", "180/110", "85%"],
        "Status": ["Active", "Active", "Resolved", "Active"]
    }
    st.dataframe(alerts, use_container_width=True)

# Billing Page
elif page == "💰 Billing":
    st.title("Billing Analytics")
    
    col1, col2, col3 = st.columns(3)
    with col1:
        st.metric("Total Revenue", "$25.4M")
    with col2:
        st.metric("Paid", "$18.2M (72%)")
    with col3:
        st.metric("Overdue", "$2.1M (8%)")
    
    st.markdown("---")
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("Payment Status")
        st.bar_chart({"Paid": 14400, "Pending": 4000, "Overdue": 1600})
    
    with col2:
        st.subheader("Revenue by Service Type")
        st.bar_chart({
            "Surgery": 8500000,
            "Room Charges": 6200000,
            "Medication": 4800000,
            "Lab Tests": 3500000,
            "Consultation": 2400000
        })

# Risk Analysis
elif page == "⚠️ Risk Analysis":
    st.title("Patient Risk Analysis")
    
    # Risk Distribution
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("Risk Score Distribution")
        st.bar_chart({
            "Score 0 (Low)": 4200,
            "Score 1": 2800,
            "Score 2": 1500,
            "Score 3": 1000,
            "Score 4+ (Critical)": 500
        })
    
    with col2:
        st.subheader("Risk by Category")
        st.bar_chart({
            "Age Risk (>65)": 3200,
            "Low Oxygen (<92%)": 1800,
            "High Heart Rate": 2100,
            "High BP": 1500,
            "Critical Events": 900
        })
    
    st.markdown("---")
    
    st.subheader("🚨 Critical Patients (Risk Score >= 3)")
    critical = {
        "Patient ID": ["P04521", "P07234", "P01987", "P08432", "P03298"],
        "Age": [78, 82, 71, 85, 69],
        "Diagnosis": ["Cardiology", "Pulmonology", "Cardiology", "Neurology", "Pulmonology"],
        "Risk Score": [4, 4, 3, 4, 3],
        "Avg O2": [88, 86, 91, 89, 90],
        "Avg HR": [125, 118, 112, 130, 108],
        "Status": ["Critical", "Critical", "High", "Critical", "High"]
    }
    st.dataframe(critical, use_container_width=True, hide_index=True)

# Performance Page
elif page == "📈 Performance":
    st.title("System Performance")
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("Warehouse Credit Usage")
        st.bar_chart({
            "HC_ETL_WH": 12.5,
            "HC_TRANSFORM_WH": 18.3,
            "HC_ANALYTICS_WH": 8.7,
            "HC_AI_WH": 25.1
        })
    
    with col2:
        st.subheader("Query Performance (Avg Duration)")
        st.bar_chart({
            "< 1 sec": 8500,
            "1-5 sec": 3200,
            "5-30 sec": 1800,
            "30-60 sec": 400,
            "> 60 sec": 100
        })
    
    st.markdown("---")
    
    st.subheader("📊 Data Pipeline Status")
    pipeline = {
        "Layer": ["Bronze (RAW_DB)", "Silver (TRANSFORM_DB)", "Gold (ANALYTICS_DB)", "Platinum (AI_READY_DB)"],
        "Records": ["85,000", "60,000", "18,608", "10,000"],
        "Last Updated": ["2 min ago", "5 min ago", "10 min ago", "15 min ago"],
        "Status": ["✅ Active", "✅ Active", "✅ Active", "✅ Active"]
    }
    st.dataframe(pipeline, use_container_width=True, hide_index=True)
    
    st.subheader("🔔 Active Alerts")
    st.info("HC_ALERT_HIGH_CREDITS: Daily credit usage at 65%")
    st.warning("HC_ALERT_ICU_CRITICAL: 12 patients with risk score >= 3")

# Footer
st.sidebar.markdown("---")
st.sidebar.markdown("### Account Info")
st.sidebar.text("Account: tyb42779")
st.sidebar.text("User: DEVIKAPG")
st.sidebar.text("Role: ACCOUNTADMIN")

st.sidebar.markdown("---")
st.sidebar.markdown("*Healthcare Enterprise Data Hub v1.0*")
st.sidebar.markdown("*Built with Snowflake + Streamlit*")
