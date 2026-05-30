# 🏥 Hospital Management Analytics – Snowflake & Streamlit

<p align="center">
  <img src="https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white" />
  <img src="https://img.shields.io/badge/Streamlit-FF4B4B?style=for-the-badge&logo=streamlit&logoColor=white" />
  <img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" />
  <img src="https://img.shields.io/badge/SQL-4479A1?style=for-the-badge&logo=postgresql&logoColor=white" />
  <img src="https://img.shields.io/badge/Power_BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black" />
</p>

> A **production-grade Hospital Data Warehouse** built on Snowflake with a multi-layer architecture (RAW → CORE → MART), automated ETL pipelines using Snowpipe, Streams & Tasks, STAR schema analytics via Dynamic Tables, RBAC with data masking, and interactive Streamlit dashboards.

---

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Snowflake Features Used](#-snowflake-features-used)
- [Data Pipeline Flow](#-data-pipeline-flow)
- [Dashboards](#-dashboards)
- [Setup & Installation](#-setup--installation)
- [SQL Execution Order](#-sql-execution-order)
- [Security & Governance](#-security--governance)
- [Datasets](#-datasets)
- [Author](#-author)

---

## 🎯 Project Overview

This project implements an **end-to-end hospital analytics platform** that ingests raw CSV data (both clean and dirty), cleans and validates it through automated pipelines, transforms it into a STAR schema, and serves it through interactive dashboards.

### Key Objectives
- ✅ **Multi-Layer Data Warehouse** – RAW → CORE → MART architecture
- ✅ **Automated Data Cleaning** – Deduplication, date validation, FK integrity checks
- ✅ **Real-Time Ingestion** – Snowpipe with auto-ingest capability
- ✅ **Change Data Capture** – Streams track incremental changes
- ✅ **Scheduled ETL** – Tasks run every 5 minutes for cleaning & MERGE operations
- ✅ **STAR Schema** – Dynamic Tables auto-refresh dimensions & facts
- ✅ **Data Governance** – RBAC with 3 custom roles + data masking policies
- ✅ **Interactive Dashboards** – Streamlit (Python) + Power BI ready

---

## 🏗 Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                 HOSPITAL MANAGEMENT DATA PLATFORM                    │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   CSV FILES          SNOWFLAKE DATA WAREHOUSE                        │
│   ┌──────────┐       ┌──────────────────────────────────────┐        │
│   │ patients │  PUT  │  STAGES → SNOWPIPE → RAW TABLES      │        │
│   │ appts    │──────►│       │                              │        │
│   │ billing  │       │  STREAMS (CDC) ──► TASKS (MERGE)     │        │
│   └──────────┘       │       │                              │        │
│                      │  CORE LAYER (Cleaned & Validated)    │        │
│                      │       │                              │        │
│                      │  DYNAMIC TABLES (Auto-Refresh)       │        │
│                      │       │                              │        │
│                      │  MART LAYER (STAR Schema)            │        │
│                      │  ┌──────────┐  ┌──────────────┐      │        │
│                      │  │ DIM x 2  │  │  FACT x 2    │      │        │
│                      │  │ VIEWS x6 │  │  MAT.VIEWS x2│      │        │
│                      │  └──────────┘  └──────────────┘      │        │
│                      └──────────────────────────────────────┘        │
│                              │                                       │
│                    ┌─────────┴─────────┐                             │
│                    │                   │                             │
│               Streamlit App      Power BI                            │
│               (Python)           (4 Dashboards)                      │
│                                                                      │
│   GOVERNANCE: RBAC (3 Roles) + Masking Policies + Secure Views       │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 🛠 Tech Stack

| Technology | Purpose |
|:---|:---|
| **Snowflake** | Cloud Data Warehouse (Database, Compute, Storage) |
| **Snowpipe** | Automated data ingestion from internal stages |
| **Streams** | Change Data Capture (CDC) for incremental processing |
| **Tasks** | Scheduled ETL jobs (every 5 min) |
| **Dynamic Tables** | Auto-refreshing STAR schema |
| **Streamlit** | Interactive Python dashboards |
| **Power BI** | Enterprise BI dashboards (4 pages) |
| **Python** | Application logic (Pandas, Plotly, Altair) |
| **SQL** | Data transformations, cleaning, governance |

---

## 📁 Project Structure

```
Hospital-Management-Analytics-Snowflake-Streamlit/
│
├── README.md                          # Project documentation
├── .gitignore                         # Git ignore rules
├── app.py                             # Standalone Streamlit app (Altair charts)
│
├── streamlit_app/                     # Streamlit Cloud deployment app
│   ├── app.py                         # Multi-page dashboard (Plotly charts)
│   ├── requirements.txt               # Python dependencies
│   └── .streamlit/
│       └── secrets.toml.example       # Snowflake connection template
│
├── sql/                               # All Snowflake SQL scripts (run in order)
│   ├── 01.SETUP.sql                   # Database, schemas, warehouse, resource monitor
│   ├── 02.FILE FORMATS.sql            # CSV file format definition
│   ├── 03.STAGE.sql                   # Internal stage for CSV uploads
│   ├── 04.RAW INGESTION.sql           # RAW layer tables (all VARCHAR)
│   ├── 05.SNOWPIPE.sql                # Automated ingestion pipes
│   ├── 06.STREAMS.sql                 # CDC streams on RAW tables
│   ├── 07.CORE.sql                    # CORE layer tables (typed + constrained)
│   ├── 08.TASK.sql                    # Scheduled cleaning tasks (MERGE)
│   ├── 10.DYNAMIC TABLES.sql          # STAR schema (DIM + FACT + Visual tables)
│   ├── 11.RBAC.sql                    # Roles, users, and access grants
│   ├── 12.MASKING POLICY.sql          # Data masking for PII fields
│   ├── 13.VALIDATION QUERY.sql        # Data quality validation queries
│   ├── 14.JOIN QUERY.sql              # Complex JOIN queries
│   ├── 15.AGGEREGATE QUERRY.sql       # Aggregate analytics queries
│   ├── 16.MATERIALIZED VIEW.sql       # Pre-computed aggregations
│   └── 17.VIEWS.sql                   # 6 secure analytical views
│
├── dataset/                           # Source CSV data files
│   ├── patients_master_clean1.csv     # Clean patient records
│   ├── patients_master_dirty1.csv     # Dirty patient records (for testing)
│   ├── appointments_clean1.csv        # Clean appointment records
│   ├── billing_clean1.csv             # Clean billing records
│   └── billing_dirty1.csv             # Dirty billing records (for testing)
│
├── documents/                         # Project documentation
│   └── ARCHITECTURE_GUIDE.md          # Complete architecture & error prevention guide
│
└── problem statement/                 # Original problem statement
    └── Hospital_Management_Snowflake_Use_Case.docx
```

---

## ❄️ Snowflake Features Used

| # | Feature | Usage |
|:--|:--------|:------|
| 1 | **Internal Stages** | CSV file staging area |
| 2 | **File Formats** | CSV parser with NULL handling |
| 3 | **Snowpipe** | Auto-ingest from stage to RAW tables |
| 4 | **Streams** | CDC tracking on RAW tables |
| 5 | **Tasks** | Scheduled MERGE (every 5 min) for RAW → CORE |
| 6 | **Dynamic Tables** | Auto-refreshing STAR schema in MART |
| 7 | **MERGE Statements** | Upsert with deduplication (ROW_NUMBER) |
| 8 | **TRY_TO_DATE / TRY_TO_NUMBER** | Safe type conversions |
| 9 | **RBAC** | 3 custom roles (Engineer, Analyst, Viewer) |
| 10 | **Masking Policies** | PII protection (phone, email, name) |
| 11 | **Secure Views** | 6 analytical views for business users |
| 12 | **Materialized Views** | Pre-aggregated monthly summaries |
| 13 | **Resource Monitor** | Credit quota management (10 credits/month) |
| 14 | **Clustering** | Performance optimization on CORE tables |
| 15 | **QUALIFY + ROW_NUMBER** | Deduplication across all layers |

---

## 🔄 Data Pipeline Flow

```
1. CSV FILES uploaded → Internal Stage (PUT command)
           │
2. SNOWPIPE auto-loads → RAW tables (all VARCHAR, no cleaning)
           │
3. STREAMS detect new rows → CDC bookmarks advance
           │
4. TASKS (every 5 min) → Clean + Validate + MERGE into CORE
           │
   ┌───────┼───────┐
   │       │       │
   ▼       ▼       ▼
 Patients  Appts  Billing
   │       │       │
   └───────┼───────┘
           │
5. DYNAMIC TABLES auto-refresh → MART layer (STAR Schema)
           │
   ┌───┬───┼───┬───┐
   ▼   ▼   ▼   ▼   ▼
  DIM  DIM FACT FACT Visual
  PAT  DOC APPT BILL Tables
           │
6. DASHBOARDS read from MART
   ├── Streamlit (Python)
   └── Power BI (DirectQuery / Import)
```

### Data Cleaning Rules Applied
- ✅ **Deduplication** – `ROW_NUMBER() OVER (PARTITION BY PK)` in every layer
- ✅ **Date Validation** – `TRY_TO_DATE()` with multi-format fallback
- ✅ **Email Validation** – Must contain `@` symbol
- ✅ **Phone Validation** – Minimum 10 digits
- ✅ **Amount Validation** – `GROSS_AMOUNT >= 0` and `NET_AMOUNT >= 0`
- ✅ **Status Validation** – Only `SCHEDULED`, `COMPLETED`, `NO-SHOW`, `CANCELLED`
- ✅ **Business Rules** – Insurance records must have `INSURER_NAME`
- ✅ **FK Integrity** – Patient IDs validated before CORE insert

---

## 📊 Dashboards

### Streamlit Dashboard (5 Use Cases)

| Tab | Use Case | Key Metrics |
|:----|:---------|:------------|
| 1 | **Appointments** | Total appointments, completed, cancelled, daily volume, dept workload |
| 2 | **Financials** | Total revenue (₹), avg bill, monthly growth, payment mode breakdown |
| 3 | **Demographics** | Patient count, cities served, gender distribution, top cities |
| 4 | **No-Shows** | No-show count & rate, dept-wise rates, worst doctors |
| 5 | **VIP & Insurers** | Top insurance providers, high-value patients (with RBAC masking) |

### Power BI Dashboard (4 Pages)
1. **Executive Summary** – KPIs, department-wise appointments & revenue
2. **Operational Dashboard** – Daily OPD trends, doctor workloads, no-shows
3. **Revenue Analysis** – Revenue by dept, insurance mix, top services
4. **Patient Utilization** – Age groups, geographic distribution, high-value patients

---

## ⚙️ Setup & Installation

### Prerequisites
- Snowflake Account (trial works)
- Python 3.8+
- SnowSQL CLI (for file uploads)

### Step 1: Clone the Repository
```bash
git clone https://github.com/kamalesh-29/Hospital-Management-Analytics-Snowflake-Streamlit.git
cd Hospital-Management-Analytics-Snowflake-Streamlit
```

### Step 2: Run SQL Scripts in Snowflake
Execute scripts in the `sql/` folder **in numbered order** (01 → 17).

### Step 3: Upload CSV Data
```sql
-- Using SnowSQL CLI:
PUT file://./dataset/patients_master_clean1.csv @HOSPITAL_DW.RAW.HOSPITAL_CSV_STAGE AUTO_COMPRESS=TRUE;
PUT file://./dataset/patients_master_dirty1.csv @HOSPITAL_DW.RAW.HOSPITAL_CSV_STAGE AUTO_COMPRESS=TRUE;
PUT file://./dataset/appointments_clean1.csv @HOSPITAL_DW.RAW.HOSPITAL_CSV_STAGE AUTO_COMPRESS=TRUE;
PUT file://./dataset/billing_clean1.csv @HOSPITAL_DW.RAW.HOSPITAL_CSV_STAGE AUTO_COMPRESS=TRUE;
PUT file://./dataset/billing_dirty1.csv @HOSPITAL_DW.RAW.HOSPITAL_CSV_STAGE AUTO_COMPRESS=TRUE;
```

### Step 4: Run the Streamlit App
```bash
cd streamlit_app
pip install -r requirements.txt
```

Configure your Snowflake credentials:
```bash
# Copy the example and fill in your credentials
cp .streamlit/secrets.toml.example .streamlit/secrets.toml
```

```bash
streamlit run app.py
```

---

## 📜 SQL Execution Order

| Step | File | Purpose | Wait? |
|:-----|:-----|:--------|:------|
| 1 | `01.SETUP.sql` | Database, schemas, warehouse | No |
| 2 | `02.FILE FORMATS.sql` | CSV format definition | No |
| 3 | `03.STAGE.sql` | Internal stage | No |
| 4 | `04.RAW INGESTION.sql` | RAW tables | No |
| 5 | **Upload CSV files** | Data loading | Yes |
| 6 | `05.SNOWPIPE.sql` | Automated pipes | No |
| 7 | `06.STREAMS.sql` | CDC streams | No |
| 8 | `07.CORE.sql` | CORE tables | No |
| 9 | `08.TASK.sql` | Cleaning tasks | Yes* |
| 10 | `10.DYNAMIC TABLES.sql` | STAR schema | Yes* |
| 11 | `11.RBAC.sql` | Roles & users | No |
| 12 | `12.MASKING POLICY.sql` | Data masking | No |
| 13 | `13.VALIDATION QUERY.sql` | Data quality checks | No |
| 14 | `14.JOIN QUERY.sql` | Complex queries | No |
| 15 | `15.AGGEREGATE QUERRY.sql` | Analytics queries | No |
| 16 | `16.MATERIALIZED VIEW.sql` | Pre-aggregations | No |
| 17 | `17.VIEWS.sql` | Secure views | No |

> *Wait up to 5 minutes for Tasks to run and Dynamic Tables to auto-refresh.

---

## 🔐 Security & Governance

### Role-Based Access Control (RBAC)

| Role | Access Level | Schemas |
|:-----|:-------------|:--------|
| **HOSPITAL_ENGINEER** | Full access (DDL + DML) | RAW, CORE, MART |
| **HOSPITAL_ANALYST** | Read-only (SELECT) | MART only |
| **HOSPITAL_VIEWER** | Read-only + Masked PII | MART only (via Secure Views) |

### Data Masking Policies
- **Phone Numbers** – Masked for Viewer role
- **Email Addresses** – Masked for Viewer role
- **Patient Names** – Masked for Viewer role

---

## 📂 Datasets

| File | Records | Description |
|:-----|:--------|:------------|
| `patients_master_clean1.csv` | Clean data | Valid patient records |
| `patients_master_dirty1.csv` | Dirty data | Invalid dates, emails, duplicates |
| `appointments_clean1.csv` | Clean data | Valid appointment records |
| `billing_clean1.csv` | Clean data | Valid billing records |
| `billing_dirty1.csv` | Dirty data | Negative amounts, invalid modes |

> Dirty data files are intentionally included to demonstrate the data cleaning and validation capabilities of the pipeline.

---

## 👨‍💻 Author

**Kamalesh**
- GitHub: [@kamalesh-29](https://github.com/kamalesh-29)

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

<p align="center">
  ⭐ If you found this project helpful, please give it a star!
</p>
