import streamlit as st
import snowflake.connector
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go

# ==========================================
# PAGE CONFIGURATION
# ==========================================
st.set_page_config(
    page_title="Hospital Management Analytics",
    page_icon="🏥",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS for a professional look
st.markdown("""
<style>
    .reportview-container {
        background: #f0f2f6
    }
    .big-font {
        font-size: 24px !important;
        font-weight: bold;
    }
    .metric-card {
        background-color: white;
        padding: 20px;
        border-radius: 10px;
        box-shadow: 0 4px 6px rgba(0,0,0,0.1);
    }
</style>
""", unsafe_allow_html=True)

# ==========================================
# SNOWFLAKE CONNECTION
# ==========================================
@st.cache_resource
def init_connection():
    try:
        return snowflake.connector.connect(
            **st.secrets["snowflake"]
        )
    except Exception as e:
        st.error(f"Could not connect to Snowflake. Please check your .streamlit/secrets.toml file. Error: {e}")
        return None

conn = init_connection()

@st.cache_data(ttl=300) # Cache data for 5 minutes
def run_query(query):
    if conn is None:
        return pd.DataFrame()
    with conn.cursor() as cur:
        cur.execute(query)
        # Fetch data and column names
        data = cur.fetchall()
        columns = [desc[0] for desc in cur.description]
        return pd.DataFrame(data, columns=columns)

# ==========================================
# SIDEBAR NAVIGATION
# ==========================================
st.sidebar.title("🏥 Hospital Analytics")
st.sidebar.markdown("---")
page = st.sidebar.radio("Navigate to Dashboard:", 
    ["Executive Summary", "Operational Dashboard", "Revenue Analysis", "Patient Utilization"])
st.sidebar.markdown("---")
st.sidebar.info("Connected to Snowflake Data Warehouse: **HOSPITAL_DW** (MART Schema)")

# ==========================================
# PAGE 1: EXECUTIVE SUMMARY
# ==========================================
if page == "Executive Summary":
    st.title("📊 Executive KPI Summary")
    st.markdown("High-level overview of hospital performance.")
    
    # Fetch KPI data
    appt_kpis = run_query("""
        SELECT
            COUNT(DISTINCT APPT_ID) AS TOTAL_APPOINTMENTS,
            SUM(IS_COMPLETED) AS COMPLETED_VISITS,
            ROUND(SUM(IS_COMPLETED) * 100.0 / NULLIF(COUNT(*), 0), 1) AS COMPLETION_RATE_PCT,
            COUNT(DISTINCT PATIENT_KEY) AS UNIQUE_PATIENTS
        FROM FACT_APPOINTMENT
    """)
    
    rev_kpis = run_query("""
        SELECT
            ROUND(SUM(GROSS_AMOUNT), 2) AS TOTAL_GROSS_REVENUE,
            ROUND(SUM(NET_AMOUNT), 2) AS TOTAL_NET_REVENUE,
            ROUND(AVG(NET_AMOUNT), 2) AS AVG_BILL_VALUE
        FROM FACT_BILLING
    """)
    
    if not appt_kpis.empty and not rev_kpis.empty:
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            st.metric("Total Appointments", f"{appt_kpis['TOTAL_APPOINTMENTS'].iloc[0]:,}")
        with col2:
            st.metric("Completion Rate", f"{appt_kpis['COMPLETION_RATE_PCT'].iloc[0]}%")
        with col3:
            st.metric("Total Net Revenue", f"₹ {rev_kpis['TOTAL_NET_REVENUE'].iloc[0]:,.2f}")
        with col4:
            st.metric("Avg Bill Value", f"₹ {rev_kpis['AVG_BILL_VALUE'].iloc[0]:,.2f}")
            
        st.markdown("---")
        
        # Charts row
        c1, c2 = st.columns(2)
        
        with c1:
            st.subheader("Appointments by Department")
            dept_appts = run_query("""
                SELECT DEPARTMENT, COUNT(*) as APPOINTMENTS 
                FROM FACT_APPOINTMENT 
                GROUP BY DEPARTMENT 
                ORDER BY APPOINTMENTS DESC
            """)
            fig_dept = px.bar(dept_appts, x='DEPARTMENT', y='APPOINTMENTS', 
                              color='DEPARTMENT', title="Total Appointments per Department")
            st.plotly_chart(fig_dept, use_container_width=True)
            
        with c2:
            st.subheader("Revenue by Payment Mode")
            payment_rev = run_query("""
                SELECT PAYMENT_MODE, SUM(NET_AMOUNT) as REVENUE 
                FROM FACT_BILLING 
                GROUP BY PAYMENT_MODE
            """)
            fig_pay = px.pie(payment_rev, values='REVENUE', names='PAYMENT_MODE', 
                             title="Revenue Distribution by Payment Method", hole=0.4)
            st.plotly_chart(fig_pay, use_container_width=True)
    else:
        st.warning("No data found or connection not established.")

# ==========================================
# PAGE 2: OPERATIONAL DASHBOARD
# ==========================================
elif page == "Operational Dashboard":
    st.title("⚙️ Operational Dashboard")
    st.markdown("Daily appointment patterns, doctor workloads, and no-shows.")
    
    # Date trend
    daily_trend = run_query("SELECT * FROM VW_DAILY_OPD_TREND ORDER BY APPT_DATE")
    
    if not daily_trend.empty:
        st.subheader("Daily Appointment Volume")
        fig_trend = px.line(daily_trend, x='APPT_DATE', y=['TOTAL_APPOINTMENTS', 'COMPLETED_VISITS', 'NO_SHOWS'],
                            labels={'value': 'Count', 'variable': 'Metric', 'APPT_DATE': 'Date'},
                            title="Daily OPD Trends")
        st.plotly_chart(fig_trend, use_container_width=True)
        
        st.markdown("---")
        c1, c2 = st.columns(2)
        
        with c1:
            st.subheader("No-Show Rates by Department")
            noshow_dept = run_query("""
                SELECT DEPARTMENT, 
                       ROUND(SUM(IS_NO_SHOW) * 100.0 / NULLIF(COUNT(*), 0), 1) AS NO_SHOW_RATE
                FROM FACT_APPOINTMENT
                GROUP BY DEPARTMENT
                ORDER BY NO_SHOW_RATE DESC
            """)
            fig_noshow = px.bar(noshow_dept, x='DEPARTMENT', y='NO_SHOW_RATE',
                                text='NO_SHOW_RATE', color='NO_SHOW_RATE',
                                color_continuous_scale='Reds', title="No-Show Rate % by Dept")
            fig_noshow.update_traces(texttemplate='%{text}%', textposition='outside')
            st.plotly_chart(fig_noshow, use_container_width=True)
            
        with c2:
            st.subheader("Top Busiest Doctors")
            doctor_perf = run_query("""
                SELECT DOCTOR_NAME, PRIMARY_DEPARTMENT, TOTAL_APPOINTMENTS
                FROM VW_DOCTOR_PERFORMANCE
                ORDER BY TOTAL_APPOINTMENTS DESC
                LIMIT 10
            """)
            fig_doc = px.bar(doctor_perf, y='DOCTOR_NAME', x='TOTAL_APPOINTMENTS', 
                             color='PRIMARY_DEPARTMENT', orientation='h',
                             title="Top 10 Doctors by Appointment Volume")
            fig_doc.update_layout(yaxis={'categoryorder':'total ascending'})
            st.plotly_chart(fig_doc, use_container_width=True)
            
# ==========================================
# PAGE 3: REVENUE ANALYSIS
# ==========================================
elif page == "Revenue Analysis":
    st.title("💰 Financial & Revenue Analysis")
    
    c1, c2 = st.columns(2)
    
    with c1:
        st.subheader("Revenue by Department")
        rev_dept = run_query("""
            SELECT fb.DEPARTMENT, ROUND(SUM(fb.NET_AMOUNT), 2) AS TOTAL_REVENUE
            FROM FACT_BILLING fb
            GROUP BY fb.DEPARTMENT
            ORDER BY TOTAL_REVENUE DESC
        """)
        if not rev_dept.empty:
            fig_rev_dept = px.bar(rev_dept, x='DEPARTMENT', y='TOTAL_REVENUE', 
                                  text='TOTAL_REVENUE', color='TOTAL_REVENUE',
                                  color_continuous_scale='Greens')
            fig_rev_dept.update_traces(texttemplate='₹%{text:,.0f}', textposition='outside')
            st.plotly_chart(fig_rev_dept, use_container_width=True)
            
    with c2:
        st.subheader("Insurance vs Self-Pay")
        ins_mix = run_query("SELECT * FROM VW_INSURANCE_MIX")
        if not ins_mix.empty:
            fig_ins = px.sunburst(ins_mix, path=['DEPARTMENT', 'PAYMENT_MODE'], values='TOTAL_NET',
                                  title="Revenue Breakdown by Dept and Payment Mode")
            st.plotly_chart(fig_ins, use_container_width=True)
            
    st.markdown("---")
    st.subheader("Top Revenue-Generating Services")
    top_services = run_query("""
        SELECT svc.SERVICE_DESC, fb.DEPARTMENT, SUM(fb.NET_AMOUNT) as REVENUE
        FROM FACT_BILLING fb
        JOIN DIM_SERVICE svc ON fb.SERVICE_KEY = svc.SERVICE_KEY
        GROUP BY svc.SERVICE_DESC, fb.DEPARTMENT
        ORDER BY REVENUE DESC
        LIMIT 10
    """)
    if not top_services.empty:
        fig_svc = px.treemap(top_services, path=[px.Constant("All Services"), 'DEPARTMENT', 'SERVICE_DESC'], 
                             values='REVENUE', color='REVENUE', color_continuous_scale='Blues')
        st.plotly_chart(fig_svc, use_container_width=True)

# ==========================================
# PAGE 4: PATIENT UTILIZATION
# ==========================================
elif page == "Patient Utilization":
    st.title("👥 Patient Utilization & Demographics")
    
    c1, c2 = st.columns(2)
    
    with c1:
        st.subheader("Patient Age Groups")
        age_groups = run_query("""
            SELECT AGE_GROUP, COUNT(*) as PATIENT_COUNT 
            FROM DIM_PATIENT 
            GROUP BY AGE_GROUP
        """)
        if not age_groups.empty:
            fig_age = px.pie(age_groups, names='AGE_GROUP', values='PATIENT_COUNT', hole=0.3)
            st.plotly_chart(fig_age, use_container_width=True)
            
    with c2:
        st.subheader("High-Value Patients (Top 10 by Revenue)")
        top_patients = run_query("""
            SELECT FULL_NAME, LIFETIME_NET_REVENUE, TOTAL_APPOINTMENTS, AGE_GROUP 
            FROM VW_PATIENT_UTILIZATION 
            ORDER BY LIFETIME_NET_REVENUE DESC NULLS LAST
            LIMIT 10
        """)
        if not top_patients.empty:
            # Format currency for display
            display_df = top_patients.copy()
            display_df['LIFETIME_NET_REVENUE'] = display_df['LIFETIME_NET_REVENUE'].apply(lambda x: f"₹ {x:,.2f}")
            st.dataframe(display_df, use_container_width=True, hide_index=True)

    st.markdown("---")
    st.subheader("Patient Geographic Distribution")
    geo_data = run_query("""
        SELECT STATE, CITY, COUNT(*) as PATIENT_COUNT 
        FROM DIM_PATIENT 
        GROUP BY STATE, CITY 
        ORDER BY PATIENT_COUNT DESC
    """)
    if not geo_data.empty:
        fig_geo = px.bar(geo_data.head(15), x='CITY', y='PATIENT_COUNT', color='STATE',
                         title="Top 15 Cities by Patient Volume")
        st.plotly_chart(fig_geo, use_container_width=True)
