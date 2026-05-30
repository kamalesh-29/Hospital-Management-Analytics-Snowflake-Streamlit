import streamlit as st
import pandas as pd
import snowflake.connector
import altair as alt

# ==========================================
# PAGE CONFIGURATION
# ==========================================
st.set_page_config(page_title="Hospital Analytics Platform", page_icon="🏥", layout="wide")

# ==========================================
# CUSTOM CSS (Premium Look)
# ==========================================
st.markdown("""
    <style>
    .main {background-color: #f4f6f9;}
    .metric-card {
        background-color: #ffffff;
        padding: 20px;
        border-radius: 12px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.05);
        text-align: center;
        border-top: 5px solid #2980b9;
        transition: transform 0.3s;
    }
    .metric-card:hover { transform: translateY(-5px); }
    .metric-value {font-size: 34px; font-weight: 800; color: #2c3e50; margin-top: 10px;}
    .metric-label {font-size: 13px; color: #7f8c8d; text-transform: uppercase; letter-spacing: 1.5px; font-weight: 600;}
    .stTabs [data-baseweb="tab-list"] { gap: 24px; }
    .stTabs [data-baseweb="tab"] { height: 50px; font-size: 16px; font-weight: 600; }
    </style>
""", unsafe_allow_html=True)

# ==========================================
# SIDEBAR
# ==========================================
st.sidebar.image("https://cdn-icons-png.flaticon.com/512/2960/2960006.png", width=100)
st.sidebar.title("Data Platform Login")
st.sidebar.markdown("---")
account = st.sidebar.text_input("Account", value="VXQNNOF-VN94621")
user = st.sidebar.text_input("Username", value="HOSPITAL_VIEWER_USER")
password = st.sidebar.text_input("Password", type="password")
role = st.sidebar.text_input("Role", value="HOSPITAL_VIEWER_ROLE")
database = st.sidebar.text_input("Database", value="HOSPITAL_DW")
schema = st.sidebar.text_input("Schema", value="MART")
warehouse = st.sidebar.text_input("Warehouse", value="HOSPITAL_WH")

@st.cache_data(ttl=300)
def load_data(query, account, user, password, role, database, schema, warehouse):
    try:
        conn = snowflake.connector.connect(
            user=user, password=password, account=account, role=role,
            warehouse=warehouse, database=database, schema=schema
        )
        df = pd.read_sql(query, conn)
        conn.close()
        return df
    except Exception as e:
        st.error(f"⚠️ **Snowflake Error:** {e}")
        return pd.DataFrame()

# ==========================================
# DASHBOARD LOGIC
# ==========================================
st.title("🏥 Hospital Executive Intelligence")
st.markdown("Real-time clinical, operational, and financial analytics.")

if account and user and password:
    with st.spinner("Synchronizing with Snowflake MART Layer..."):
        
        # 5 USE CASES AS TABS
        tab1, tab2, tab3, tab4, tab5 = st.tabs([
            "USE CASE 1. Appointments", 
            "USE CASE 2. Financials", 
            "USE CASE 3. Demographics", 
            "USE CASE 4. No-Shows",
            "USE CASE 5. VIP & Insurers"
        ])
        
        # ==========================================
        # TAB 1: APPOINTMENTS
        # ==========================================
        with tab1:
            st.markdown("### 📅 Operational Scheduling")
            df_appt = load_data("SELECT COUNT(*) AS TOTAL, SUM(IS_COMPLETED) AS COMP, SUM(IS_CANCELLED) AS CANC FROM FACT_APPOINTMENT", account, user, password, role, database, schema, warehouse)
            if not df_appt.empty:
                c1, c2, c3 = st.columns(3)
                c1.markdown(f'<div class="metric-card"><div class="metric-label">Total Appointments</div><div class="metric-value">{df_appt["TOTAL"][0]:,}</div></div>', unsafe_allow_html=True)
                c2.markdown(f'<div class="metric-card" style="border-top-color:#27ae60;"><div class="metric-label">Completed</div><div class="metric-value">{df_appt["COMP"][0]:,}</div></div>', unsafe_allow_html=True)
                c3.markdown(f'<div class="metric-card" style="border-top-color:#e74c3c;"><div class="metric-label">Cancelled</div><div class="metric-value">{df_appt["CANC"][0]:,}</div></div>', unsafe_allow_html=True)
                st.write("<br>", unsafe_allow_html=True)
            
            c4, c5 = st.columns([1,1])
            with c4:
                st.subheader("Appointment Volume by Day")
                df_daily = load_data("SELECT APPT_DATE, COUNT(*) AS VOLUME FROM FACT_APPOINTMENT GROUP BY APPT_DATE ORDER BY APPT_DATE", account, user, password, role, database, schema, warehouse)
                if not df_daily.empty:
                    df_daily['APPT_DATE'] = df_daily['APPT_DATE'].astype(str)
                    base = alt.Chart(df_daily).encode(x=alt.X('APPT_DATE:T', title='Date'), y=alt.Y('VOLUME:Q', title='Appointments'))
                    area = base.mark_area(opacity=0.5, color="#3498db")
                    line = base.mark_line(color="#2980b9")
                    points = base.mark_circle(color="#2980b9", size=60)
                    text = base.mark_text(align='center', dy=-10, fontWeight='bold').encode(text='VOLUME:Q')
                    st.altair_chart((area + line + points + text).properties(height=380), theme="streamlit", use_container_width=True)
            with c5:
                st.subheader("Dept Workload")
                df_dept = load_data("SELECT DEPARTMENT, COUNT(*) AS APPOINTMENTS FROM FACT_APPOINTMENT GROUP BY DEPARTMENT", account, user, password, role, database, schema, warehouse)
                if not df_dept.empty:
                    bars = alt.Chart(df_dept).mark_bar(color='#9b59b6', cornerRadiusEnd=4).encode(
                        x=alt.X('APPOINTMENTS:Q', title='Total Appointments'),
                        y=alt.Y('DEPARTMENT:N', sort='-x', title='')
                    )
                    text = bars.mark_text(align='left', dx=3, fontWeight='bold').encode(text='APPOINTMENTS:Q')
                    st.altair_chart((bars + text).properties(height=380), theme="streamlit", use_container_width=True)

        # ==========================================
        # TAB 2: FINANCIALS (RUPEES)
        # ==========================================
        with tab2:
            st.markdown("### 💰 Financial Performance (₹ INR)")
            df_rev = load_data("SELECT SUM(NET_AMOUNT) AS TOTAL, AVG(NET_AMOUNT) AS AVG_BILL FROM FACT_BILLING", account, user, password, role, database, schema, warehouse)
            if not df_rev.empty:
                rc1, rc2 = st.columns(2)
                rc1.markdown(f'<div class="metric-card" style="border-top-color:#f1c40f;"><div class="metric-label">Total Revenue</div><div class="metric-value">₹{df_rev["TOTAL"][0]:,.2f}</div></div>', unsafe_allow_html=True)
                rc2.markdown(f'<div class="metric-card" style="border-top-color:#f1c40f;"><div class="metric-label">Average Bill Amount</div><div class="metric-value">₹{df_rev["AVG_BILL"][0]:,.2f}</div></div>', unsafe_allow_html=True)
                st.write("<br>", unsafe_allow_html=True)
            
            c6, c7 = st.columns(2)
            with c6:
                st.subheader("Monthly Revenue Growth")
                df_trend = load_data("SELECT DATE_TRUNC('MONTH', BILL_DATE) AS MONTH, SUM(NET_AMOUNT) AS REVENUE FROM FACT_BILLING GROUP BY DATE_TRUNC('MONTH', BILL_DATE) ORDER BY MONTH", account, user, password, role, database, schema, warehouse)
                if not df_trend.empty:
                    df_trend['MONTH'] = df_trend['MONTH'].astype(str).str[:7] # YYYY-MM
                    base = alt.Chart(df_trend).encode(x=alt.X('MONTH:N', title='Month'), y=alt.Y('REVENUE:Q', title='Revenue (₹)'))
                    line = base.mark_line(color="#2ecc71", strokeWidth=3)
                    points = base.mark_circle(color="#27ae60", size=100)
                    text = base.mark_text(align='center', dy=-15, fontWeight='bold').encode(text=alt.Text('REVENUE:Q', format=",.0f"))
                    st.altair_chart((line + points + text).properties(height=380), theme="streamlit", use_container_width=True)
            with c7:
                st.subheader("Revenue by Payment Mode")
                df_pay = load_data("SELECT PAYMENT_MODE, SUM(NET_AMOUNT) AS REVENUE FROM FACT_BILLING GROUP BY PAYMENT_MODE", account, user, password, role, database, schema, warehouse)
                if not df_pay.empty:
                    base = alt.Chart(df_pay).encode(
                        theta=alt.Theta(field="REVENUE", type="quantitative"),
                        color=alt.Color(field="PAYMENT_MODE", type="nominal", legend=alt.Legend(title="Payment Mode", orient="bottom")),
                    )
                    donut = base.mark_arc(innerRadius=60)
                    text = base.mark_text(radiusOffset=20, fontSize=14, fontWeight='bold').encode(text=alt.Text('REVENUE:Q', format=",.0f"))
                    st.altair_chart((donut + text).properties(height=380), theme="streamlit", use_container_width=True)

        # ==========================================
        # TAB 3: DEMOGRAPHICS
        # ==========================================
        with tab3:
            st.markdown("### 👥 Patient Demographics")
            df_pat = load_data("SELECT COUNT(*) AS TOTAL, COUNT(DISTINCT CITY) AS CITIES FROM DIM_PATIENT", account, user, password, role, database, schema, warehouse)
            if not df_pat.empty:
                dc1, dc2 = st.columns(2)
                dc1.markdown(f'<div class="metric-card"><div class="metric-label">Total Registered Patients</div><div class="metric-value">{df_pat["TOTAL"][0]:,}</div></div>', unsafe_allow_html=True)
                dc2.markdown(f'<div class="metric-card"><div class="metric-label">Cities Served</div><div class="metric-value">{df_pat["CITIES"][0]:,}</div></div>', unsafe_allow_html=True)
                st.write("<br>", unsafe_allow_html=True)
            
            c8, c9 = st.columns(2)
            with c8:
                st.subheader("Gender Distribution")
                df_gen = load_data("SELECT GENDER, COUNT(*) AS COUNT FROM DIM_PATIENT WHERE GENDER IS NOT NULL GROUP BY GENDER", account, user, password, role, database, schema, warehouse)
                if not df_gen.empty:
                    base = alt.Chart(df_gen).encode(
                        theta=alt.Theta(field="COUNT", type="quantitative"),
                        color=alt.Color(field="GENDER", type="nominal", scale=alt.Scale(scheme='pastel1'), legend=alt.Legend(title="Gender", orient="bottom")),
                    )
                    pie = base.mark_arc()
                    text = base.mark_text(radiusOffset=15, fontSize=14, fontWeight='bold').encode(text='COUNT:Q')
                    st.altair_chart((pie + text).properties(height=380), theme="streamlit", use_container_width=True)
            with c9:
                st.subheader("Top 10 Patient Cities")
                df_city = load_data("SELECT CITY, COUNT(*) AS PATIENTS FROM DIM_PATIENT WHERE CITY IS NOT NULL GROUP BY CITY ORDER BY PATIENTS DESC LIMIT 10", account, user, password, role, database, schema, warehouse)
                if not df_city.empty:
                    bars = alt.Chart(df_city).mark_bar(color="#e67e22", cornerRadiusEnd=4).encode(
                        x=alt.X('CITY:N', sort='-y', title='', axis=alt.Axis(labelAngle=-45)),
                        y=alt.Y('PATIENTS:Q', title='Number of Patients')
                    )
                    text = bars.mark_text(align='center', dy=-10, fontWeight='bold').encode(text='PATIENTS:Q')
                    st.altair_chart((bars + text).properties(height=380), theme="streamlit", use_container_width=True)

        # ==========================================
        # TAB 4: NO-SHOWS
        # ==========================================
        with tab4:
            st.markdown("### 🚫 Operational Inefficiencies (No-Shows)")
            df_noshow = load_data("SELECT SUM(IS_NO_SHOW) AS NOSHOWS, ROUND(SUM(IS_NO_SHOW)*100.0/NULLIF(COUNT(*),0), 2) AS RATE FROM FACT_APPOINTMENT", account, user, password, role, database, schema, warehouse)
            if not df_noshow.empty:
                rate_val = df_noshow["RATE"][0]
                rate_disp = f"{rate_val:.1f}%" if pd.notnull(rate_val) else "0.0%"
                nc1, nc2 = st.columns(2)
                nc1.markdown(f'<div class="metric-card" style="border-top-color:#c0392b;"><div class="metric-label">Total No-Shows</div><div class="metric-value" style="color:#c0392b;">{df_noshow["NOSHOWS"][0]:,}</div></div>', unsafe_allow_html=True)
                nc2.markdown(f'<div class="metric-card" style="border-top-color:#c0392b;"><div class="metric-label">Hospital No-Show Rate</div><div class="metric-value" style="color:#c0392b;">{rate_disp}</div></div>', unsafe_allow_html=True)
                st.write("<br>", unsafe_allow_html=True)

            c10, c11 = st.columns(2)
            with c10:
                st.subheader("No-Show Rate by Department (%)")
                df_ns_dept = load_data("SELECT DEPARTMENT, ROUND(SUM(IS_NO_SHOW)*100.0/NULLIF(COUNT(*),0), 1) AS RATE FROM FACT_APPOINTMENT GROUP BY DEPARTMENT HAVING RATE > 0 ORDER BY RATE DESC", account, user, password, role, database, schema, warehouse)
                if not df_ns_dept.empty:
                    bars = alt.Chart(df_ns_dept).mark_bar(color='#c0392b').encode(
                        x=alt.X('RATE:Q', title='No-Show %'),
                        y=alt.Y('DEPARTMENT:N', sort='-x', title='')
                    )
                    text = bars.mark_text(align='left', dx=3, fontWeight='bold').encode(text=alt.Text('RATE:Q', format=".1f"))
                    st.altair_chart((bars + text).properties(height=380), theme="streamlit", use_container_width=True)
            with c11:
                st.subheader("Worst Doctors for No-Shows (Total Cases)")
                df_ns_doc = load_data("SELECT DOCTOR_NAME, SUM(IS_NO_SHOW) AS NO_SHOWS FROM FACT_APPOINTMENT GROUP BY DOCTOR_NAME HAVING SUM(IS_NO_SHOW) > 0 ORDER BY NO_SHOWS DESC LIMIT 7", account, user, password, role, database, schema, warehouse)
                if not df_ns_doc.empty:
                    bars = alt.Chart(df_ns_doc).mark_bar(color='#e74c3c', cornerRadiusEnd=4).encode(
                        x=alt.X('DOCTOR_NAME:N', sort='-y', title='', axis=alt.Axis(labelAngle=-45)),
                        y=alt.Y('NO_SHOWS:Q', title='Total No-Shows')
                    )
                    text = bars.mark_text(align='center', dy=-10, fontWeight='bold').encode(text='NO_SHOWS:Q')
                    st.altair_chart((bars + text).properties(height=380), theme="streamlit", use_container_width=True)

        # ==========================================
        # TAB 5: VIP & INSURERS (RUPEES)
        # ==========================================
        with tab5:
            st.markdown("### ⭐ High-Value Accounts & Insurance (₹ INR)")
            st.write("Leveraging Secure Data Masking to protect VIP identities based on your role.")
            st.write("<br>", unsafe_allow_html=True)
            
            c12, c13 = st.columns([1,1])
            with c12:
                st.subheader("Top Insurance Providers by Revenue")
                df_ins = load_data("SELECT INSURER_NAME, SUM(NET_AMOUNT) AS TOTAL_BILLED FROM FACT_BILLING WHERE IS_INSURANCE = 1 AND INSURER_NAME IS NOT NULL GROUP BY INSURER_NAME ORDER BY TOTAL_BILLED DESC LIMIT 8", account, user, password, role, database, schema, warehouse)
                if not df_ins.empty:
                    bars = alt.Chart(df_ins).mark_bar(color='#27ae60').encode(
                        x=alt.X('TOTAL_BILLED:Q', title='Revenue Billed (₹)'),
                        y=alt.Y('INSURER_NAME:N', sort='-x', title='')
                    )
                    text = bars.mark_text(align='left', dx=3, fontWeight='bold').encode(text=alt.Text('TOTAL_BILLED:Q', format=",.0f"))
                    st.altair_chart((bars + text).properties(height=400), theme="streamlit", use_container_width=True)

            with c13:
                st.subheader("💎 VIP Patients (Highest Lifetime Value)")
                st.markdown("<p style='font-size:14px; color:gray;'>Role-Based Access Control dynamically masks names for Viewer roles.</p>", unsafe_allow_html=True)
                df_vip = load_data("""
                    SELECT p.FULL_NAME, COUNT(b.BILL_ID) AS VISITS, SUM(b.NET_AMOUNT) AS LIFETIME_SPEND
                    FROM FACT_BILLING b
                    JOIN DIM_PATIENT p ON b.PATIENT_KEY = p.PATIENT_KEY
                    GROUP BY p.FULL_NAME
                    ORDER BY LIFETIME_SPEND DESC LIMIT 10
                """, account, user, password, role, database, schema, warehouse)
                if not df_vip.empty:
                    df_vip['LIFETIME_SPEND'] = df_vip['LIFETIME_SPEND'].apply(lambda x: f"₹{x:,.2f}")
                    st.dataframe(df_vip, use_container_width=True, hide_index=True)

else:
    st.info("👈 Please enter your password in the sidebar to load the dashboard.")
