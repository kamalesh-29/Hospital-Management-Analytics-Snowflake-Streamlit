# Hospital Management – Complete Architecture & Error Prevention Guide

## 1. COMPLETE DATA FLOW ARCHITECTURE

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                        HOSPITAL MANAGEMENT DATA PLATFORM                         │
├──────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│  ┌─────────────────┐         ┌───────────────────────────────────────┐           │
│  │   CSV FILES      │         │          SNOWFLAKE                    │           │
│  │                  │  PUT    │                                       │           │
│  │ patients_clean   │────────►│  ┌─────────────┐    ┌──────────────┐│           │
│  │ patients_dirty   │         │  │ STG_PATIENTS │    │  RAW SCHEMA  ││           │
│  │ appointments     │  PUT    │  │ STG_APPTS    │───►│              ││           │
│  │ billing_clean    │────────►│  │ STG_BILLING  │    │ RAW_PATIENTS ││           │
│  │ billing_dirty    │         │  └─────────────┘    │ RAW_APPTS    ││           │
│  └─────────────────┘         │   Internal Stages    │ RAW_BILLING  ││           │
│                              │        │              │ EXCEPTIONS   ││           │
│                              │        │ Snowpipe     └──────┬───────┘│           │
│                              │        │ (Auto-Ingest)       │        │           │
│                              │        ▼                     │ Streams│           │
│                              │  ┌───────────┐              │ (CDC)  │           │
│                              │  │ SNOWPIPE   │              │        │           │
│                              │  │ Pipes x 3  │              ▼        │           │
│                              │  └───────────┘        ┌──────────────┐│           │
│                              │                       │ CORE SCHEMA  ││           │
│                              │                       │              ││           │
│                              │  ┌───────────┐       │CORE_PATIENTS ││           │
│                              │  │  TASKS     │──────►│CORE_APPTS   ││           │
│                              │  │ (Scheduled │  MERGE│CORE_BILLING  ││           │
│                              │  │  Cleaning) │       │              ││           │
│                              │  └───────────┘       └──────┬───────┘│           │
│                              │                             │        │           │
│                              │                  Dynamic Tables      │           │
│                              │                  (Auto-Refresh)      │           │
│                              │                             │        │           │
│                              │                      ┌──────┴───────┐│           │
│                              │                      │ MART SCHEMA  ││           │
│                              │                      │ (STAR Schema)││           │
│                              │                      │              ││           │
│                              │                      │ DIM_DATE     ││           │
│                              │                      │ DIM_PATIENT  ││    ┌─────┐│
│                              │                      │ DIM_DOCTOR   ││───►│Power││
│                              │                      │ DIM_DEPT     ││    │ BI  ││
│                              │                      │ DIM_SERVICE  ││    │     ││
│                              │                      │              ││    │4 Pg ││
│                              │                      │ FACT_APPT    ││    │Dash ││
│                              │                      │ FACT_BILLING ││    └─────┘│
│                              │                      │              ││           │
│                              │                      │ VIEWS x 6   ││           │
│                              │                      │ MAT.VIEWS x2││           │
│                              │                      └──────────────┘│           │
│                              │                                       │           │
│                              │  ┌───────────────────────────────────┐│           │
│                              │  │ GOVERNANCE SCHEMA                 ││           │
│                              │  │ • RBAC (3 custom roles)           ││           │
│                              │  │ • Masking (Phone, Email, Name)    ││           │
│                              │  │ • Row-Level Security              ││           │
│                              │  │ • Secure Views                    ││           │
│                              │  └───────────────────────────────────┘│           │
│                              └───────────────────────────────────────┘           │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. LAYER PURPOSE DEEP-DIVE

### RAW Layer (Schema: `HOSPITAL_DW.RAW`)
| Aspect | Detail |
|--------|--------|
| **Purpose** | Landing zone – stores raw CSV data exactly as received |
| **Data types** | ALL VARCHAR (to accept any data without failures) |
| **Cleaning** | NONE – raw data with all issues preserved |
| **Duplicates** | ALLOWED – both clean and dirty files loaded together |
| **Tables** | `RAW_PATIENTS`, `RAW_APPOINTMENTS`, `RAW_BILLING`, `RAW_EXCEPTIONS` |
| **Metadata** | `_LOADED_AT` (when), `_SOURCE_FILE` (which file) |
| **Access** | HOSPITAL_ADMIN only (not exposed to analysts) |

### CORE Layer (Schema: `HOSPITAL_DW.CORE`)
| Aspect | Detail |
|--------|--------|
| **Purpose** | Cleaned, validated, deduplicated data |
| **Data types** | PROPER types (NUMBER, DATE, VARCHAR with constraints) |
| **Cleaning** | Full validation (dates, emails, phones, amounts, FKs) |
| **Duplicates** | REJECTED – ROW_NUMBER() QUALIFY deduplication |
| **Tables** | `CORE_PATIENTS`, `CORE_APPOINTMENTS`, `CORE_BILLING` |
| **Process** | Streams detect changes → Tasks run MERGE with cleaning |
| **Access** | HOSPITAL_ADMIN + HOSPITAL_ANALYST |

### MART Layer (Schema: `HOSPITAL_DW.MART`)
| Aspect | Detail |
|--------|--------|
| **Purpose** | STAR schema for analytics and Power BI |
| **Tables** | 5 Dimensions + 2 Facts (Dynamic Tables) |
| **Views** | 6 analytical secure views + 2 materialized views |
| **Cleaning** | Additional safety-net deduplication in Dynamic Tables |
| **FK Integrity** | INNER JOINs ensure zero NULL foreign keys |
| **Access** | All roles (via secure views for business users) |

---

## 3. AUTOMATION FLOW

```
TIMING & TRIGGERS:
═══════════════════

1. FILE ARRIVES → Stage (manual PUT or UI upload)
                    │
2. SNOWPIPE     → Auto-loads into RAW table (ALTER PIPE REFRESH)
                    │
3. STREAM       → Detects new rows in RAW (CDC bookmark advances)
                    │
4. TASK CHAIN   → Every 5 minutes, checks if stream has data
                    │
    ┌───────────────┼───────────────┐
    │               │               │
    ▼               ▼               ▼
TASK_CLEAN     TASK_CLEAN      TASK_CLEAN
_PATIENTS      _APPOINTMENTS   _BILLING
(Root Task)    (After Patients) (After Patients)
    │               │               │
    ▼               ▼               ▼
MERGE INTO     MERGE INTO      MERGE INTO
CORE_PATIENTS  CORE_APPTS      CORE_BILLING
                    │
5. DYNAMIC     → Auto-refresh when CORE data changes
   TABLES         (TARGET_LAG = 5 minutes)
                    │
    ┌───┬───┬───┬───┼───┬───┬───┐
    ▼   ▼   ▼   ▼   ▼   ▼   ▼
   DIM  DIM  DIM  DIM  DIM FACT FACT
   DATE PAT  DOC  DEPT SVC APPT BILL
                    │
6. POWER BI    → Reads from MART layer
                  (Import mode: scheduled refresh)
                  (DirectQuery: live)
```

---

## 4. COMPLETE ERROR PREVENTION GUIDE (ALL 20 ERRORS)

### Error 1: Duplicate Dimension Keys
| Aspect | Detail |
|--------|--------|
| **What happens** | DIM_PATIENT has PATIENT_ID = 1001 twice |
| **Why it happens** | Both clean and dirty files have the same patient |
| **Power BI impact** | "Many-to-many cardinality" error, can't create relationship |
| **Prevention** | `QUALIFY ROW_NUMBER() OVER (PARTITION BY PATIENT_ID ORDER BY _LOADED_AT DESC) = 1` in ALL dimension Dynamic Tables |
| **Where** | `09_dynamic_tables.sql` – every DIM table has this |

### Error 2: NULL Foreign Keys
| Aspect | Detail |
|--------|--------|
| **What happens** | FACT_APPOINTMENT has PATIENT_KEY = NULL |
| **Why it happens** | Appointment references a patient that was rejected during cleaning |
| **Power BI impact** | Blank rows in visuals, wrong totals |
| **Prevention** | `INNER JOIN` in Dynamic Table queries (not LEFT JOIN) |
| **Where** | `09_dynamic_tables.sql` – FACT tables use INNER JOIN to dimensions |

### Error 3: Blank IDs
| Aspect | Detail |
|--------|--------|
| **What happens** | PATIENT_ID = '' (empty string) passes NULL checks |
| **Why it happens** | CSV has empty cells that become empty strings |
| **Prevention** | `WHERE PATIENT_ID IS NOT NULL AND TRIM(PATIENT_ID) != ''` |
| **Where** | `08_tasks.sql` – MERGE WHERE clause |

### Error 4: Wrong Power BI Cardinality
| Aspect | Detail |
|--------|--------|
| **What happens** | Relationship shows "Many-to-Many" instead of "One-to-Many" |
| **Why it happens** | Duplicate keys in dimension OR NULL keys in fact |
| **Prevention** | Deduplication in DIM + INNER JOIN in FACT (Errors 1+2) |
| **Verification** | `SELECT key, COUNT(*) FROM dim GROUP BY 1 HAVING COUNT(*) > 1` |

### Error 5: Wrong Relationship Direction
| Aspect | Detail |
|--------|--------|
| **What happens** | Slicer doesn't filter other visuals |
| **Why it happens** | Cross-filter direction set incorrectly |
| **Prevention** | ALL relationships: Single direction, DIM → FACT |
| **Where** | `14_powerbi_measures.sql` – Section B documents every relationship |

### Error 6: Dynamic Table DELETE Errors
| Aspect | Detail |
|--------|--------|
| **What happens** | `Cannot perform DML on dynamic table` error |
| **Why it happens** | Someone tries INSERT/UPDATE/DELETE on a Dynamic Table |
| **Prevention** | Dynamic Tables are READ-ONLY. All data flows through CORE → DIM/FACT automatically |
| **Key rule** | Never modify Dynamic Tables directly. Modify source CORE tables instead. |

### Error 7: Streams Becoming Empty
| Aspect | Detail |
|--------|--------|
| **What happens** | Stream returns 0 rows when you expect data |
| **Why it happens** | Stream was consumed by a COMMITTED transaction |
| **This is normal** | Streams are DESIGNED to be consumed once. After task processes data, stream is empty until new data arrives. |
| **How to reload** | Insert new data into RAW table → stream captures new rows |
| **Emergency** | `CREATE OR REPLACE STREAM ... SHOW_INITIAL_ROWS = TRUE` to reset |

### Error 8: Invalid JSON Flattening
| Aspect | Detail |
|--------|--------|
| **What happens** | `LATERAL FLATTEN` returns errors or unexpected results |
| **When it applies** | If CSV data contained JSON columns (not in our current datasets) |
| **Prevention** | Use `TRY_PARSE_JSON()` before `LATERAL FLATTEN` |
| **Pattern** | `SELECT f.value FROM table, LATERAL FLATTEN(input => TRY_PARSE_JSON(json_col)) f` |
| **Our approach** | Our data is flat CSV, so JSON handling is not needed here |

### Error 9: Invalid Business Rules
| Aspect | Detail |
|--------|--------|
| **What happens** | Billing record with `PAYMENT_MODE = 'Insurance'` but no `INSURER_NAME` |
| **Why it happens** | Dirty data has inconsistent values |
| **Prevention** | `AND (PAYMENT_MODE != 'INSURANCE' OR INSURER_NAME IS NOT NULL)` |
| **Where** | `08_tasks.sql` – TASK_CLEAN_BILLING WHERE clause |

### Error 10: Duplicate Transaction IDs
| Aspect | Detail |
|--------|--------|
| **What happens** | Same BILL_ID appears twice in FACT_BILLING |
| **Why it happens** | Both clean and dirty CSV files contain the same records |
| **Prevention** | `MERGE` with `ON target.BILL_ID = source.BILL_ID` → UPDATE instead of duplicate INSERT |
| **Safety net** | `QUALIFY ROW_NUMBER() OVER (PARTITION BY BILL_ID)` in Dynamic Table |

### Error 11: Negative Amount Values
| Aspect | Detail |
|--------|--------|
| **What happens** | GROSS_AMOUNT = -2946.78 in billing |
| **Why it happens** | Dirty file has corrupted amount values |
| **Prevention** | `AND source.GROSS_AMOUNT >= 0 AND source.NET_AMOUNT >= 0` |
| **Where** | `08_tasks.sql` – TASK_CLEAN_BILLING WHERE clause |

### Error 12: Invalid Date Conversions
| Aspect | Detail |
|--------|--------|
| **What happens** | DOB = '31/02/1995' causes conversion failure |
| **Why it happens** | February 31st doesn't exist |
| **Prevention** | `TRY_TO_DATE()` returns NULL for invalid dates instead of failing |
| **Where** | `08_tasks.sql` – uses `TRY_TO_DATE(DOB, 'YYYY-MM-DD')` with fallback to `'DD/MM/YYYY'` format |

### Error 13: Invalid Joins
| Aspect | Detail |
|--------|--------|
| **What happens** | JOIN produces wrong row count (too many or too few) |
| **Why it happens** | Joining on non-unique keys (duplicates in dimension side) |
| **Prevention** | Deduplication BEFORE joining. Our CORE tables have PRIMARY KEY constraints. |
| **Verification** | Check join cardinality: each dim key should appear exactly once |

### Error 14: Power BI Model-View Failures
| Aspect | Detail |
|--------|--------|
| **What happens** | Can't create relationships in Model View |
| **Why it happens** | Duplicate keys, NULL keys, or ambiguous paths |
| **Prevention** | All 3 root causes are prevented by our Dynamic Table design |
| **Verification** | Run validation queries from `09_dynamic_tables.sql` verification section |

### Error 15: Duplicate Relationships
| Aspect | Detail |
|--------|--------|
| **What happens** | "A relationship with the same columns already exists" |
| **Why it happens** | Power BI auto-creates relationships AND you create them manually |
| **Prevention** | After loading data, go to Model View → delete ALL auto-detected relationships → create 8 relationships manually per our guide |

### Error 16: Circular Relationships
| Aspect | Detail |
|--------|--------|
| **What happens** | "Circular dependency detected" warning |
| **Why it happens** | Cross-filter "Both" on multiple relationships creates a loop |
| **Prevention** | ALL 8 relationships use "Single" direction (DIM → FACT) |
| **If needed** | Use DAX `CROSSFILTER()` function for specific calculations instead |

### Error 17: Snowpipe Ingestion Issues
| Aspect | Detail |
|--------|--------|
| **What happens** | Files uploaded but not loaded into RAW tables |
| **Why it happens** | Internal stages require manual REFRESH |
| **Prevention** | After each PUT: `ALTER PIPE pipe_name REFRESH;` |
| **Monitoring** | `SELECT SYSTEM$PIPE_STATUS('pipe_name');` |

### Error 18: Stream Consumption Issues
| Aspect | Detail |
|--------|--------|
| **What happens** | Task runs but stream appears empty |
| **Why it happens** | Previous task run consumed the stream |
| **Prevention** | Streams are consumed ONCE per commit. This is correct behavior. |
| **If task fails** | Stream is NOT consumed (Snowflake rolls back). Data remains for next run. |

### Error 19: MERGE Failures
| Aspect | Detail |
|--------|--------|
| **What happens** | MERGE fails with "target row matched multiple times" |
| **Why it happens** | Source data has duplicate keys that match same target row |
| **Prevention** | `QUALIFY ROW_NUMBER() OVER (PARTITION BY key ORDER BY _LOADED_AT DESC) = 1` in source subquery |
| **Where** | All 3 MERGE statements in `08_tasks.sql` use this pattern |

### Error 20: Incremental Ingestion Issues
| Aspect | Detail |
|--------|--------|
| **What happens** | Same file loaded multiple times → duplicate data |
| **Why it happens** | Manual COPY INTO + Snowpipe both process the same file |
| **Prevention** | Use EITHER manual COPY (initial load) OR Snowpipe (ongoing), not both |
| **Our approach** | `05_copy_commands.sql` for initial load, `06_snowpipe.sql` for ongoing |
| **Safety** | MERGE with ON clause prevents duplicates even if file is loaded twice |

---

## 5. EXECUTION ORDER

Run the SQL files in this EXACT order:

```
Step  File                        Wait?   Verify?
────  ──────────────────────────  ──────  ────────
1     01_setup.sql                No      SHOW DATABASES, SCHEMAS, WAREHOUSES
2     02_file_formats.sql         No      SHOW FILE FORMATS
3     03_stages.sql               No      SHOW STAGES
4     04_raw_tables.sql           No      SHOW TABLES IN RAW
5     ** Upload CSV files **      Yes     LIST @stage_name
6     05_copy_commands.sql        No      Check row counts
7     06_snowpipe.sql             No      SHOW PIPES
8     07_streams.sql              No      Check STREAM_HAS_DATA
9     08_tasks.sql                Yes*    Check TASK_HISTORY, CORE row counts
10    09_dynamic_tables.sql       Yes*    Check DIM/FACT row counts
11    10_rbac.sql                 No      SHOW ROLES, MASKING POLICIES
12    11_views.sql                No      SHOW VIEWS
13    12_materialized_views.sql   No      SHOW MATERIALIZED VIEWS
14    13_queries.sql              No      Run each query
15    14_powerbi_measures.sql     N/A     Follow Power BI guide

* Wait for tasks to run (up to 5 minutes) and Dynamic Tables to refresh
```

---

## 6. INTERVIEW EXPLANATION (30-45 seconds)

> "I built a hospital analytics platform using Snowflake's multi-layer architecture. 
> Raw CSV data lands in the RAW layer through internal stages and Snowpipe. 
> Streams capture changes and Tasks apply professional data cleaning – deduplication 
> with ROW_NUMBER, date validation with TRY_TO_DATE, FK validation via INNER JOINs, 
> and amount validation. Clean data flows to the CORE layer via MERGE statements. 
> Dynamic Tables automatically build a STAR schema in the MART layer with 5 dimensions 
> and 2 fact tables. RBAC with masking policies ensures data privacy. 
> Power BI connects to the MART layer for 4 interactive dashboards covering 
> appointments, revenue, patient utilization, and no-show analytics."
