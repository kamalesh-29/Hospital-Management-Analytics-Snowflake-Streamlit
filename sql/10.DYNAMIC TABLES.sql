-- ============================================================
-- 10. DYNAMIC TABLES
-- PURPOSE: Auto-refreshing STAR schema (2 Dimensions + 2 Facts)
--          Plus specialized Dynamic Tables for Dashboard Visuals
-- ============================================================

USE DATABASE HOSPITAL_DW;
USE SCHEMA MART;

-- ============================================================
-- 1. DIMENSION: PATIENT
-- ============================================================
CREATE OR REPLACE DYNAMIC TABLE HOSPITAL_DW.MART.DIM_PATIENT
    TARGET_LAG = '5 MINUTES'
    WAREHOUSE  = HOSPITAL_WH
AS
SELECT
    PATIENT_ID                                      AS PATIENT_KEY,
    PATIENT_ID,
    FULL_NAME,
    DOB,
    GENDER,
    PHONE,
    EMAIL,
    CITY,
    STATE,
    REGISTRATION_DATE,
    TO_NUMBER(TO_CHAR(REGISTRATION_DATE, 'YYYYMMDD')) AS REGISTRATION_DATE_KEY
FROM HOSPITAL_DW.CORE.CORE_PATIENTS;

-- ============================================================
-- 2. DIMENSION: DOCTOR
-- ============================================================
CREATE OR REPLACE DYNAMIC TABLE HOSPITAL_DW.MART.DIM_DOCTOR
    TARGET_LAG = '5 MINUTES'
    WAREHOUSE  = HOSPITAL_WH
AS
SELECT
    DOCTOR_ID                                       AS DOCTOR_KEY,
    DOCTOR_ID,
    DOCTOR_NAME,
    DEPARTMENT                                      AS PRIMARY_DEPARTMENT
FROM HOSPITAL_DW.CORE.CORE_APPOINTMENTS
WHERE DOCTOR_ID IS NOT NULL
  AND DOCTOR_NAME IS NOT NULL
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY DOCTOR_ID
    ORDER BY APPT_DATE DESC
) = 1;

-- ============================================================
-- 3. FACT: APPOINTMENT
-- ============================================================
CREATE OR REPLACE DYNAMIC TABLE HOSPITAL_DW.MART.FACT_APPOINTMENT
    TARGET_LAG = '5 MINUTES'
    WAREHOUSE  = HOSPITAL_WH
AS
SELECT
    a.APPT_ID,
    TO_NUMBER(TO_CHAR(a.APPT_DATE, 'YYYYMMDD'))    AS DATE_KEY,
    a.PATIENT_ID                                   AS PATIENT_KEY,
    a.DOCTOR_ID                                    AS DOCTOR_KEY,
    a.APPT_DATE,
    a.SLOT,
    a.STATUS,
    a.DEPARTMENT,
    a.DOCTOR_NAME,
    CASE WHEN UPPER(a.STATUS) = 'COMPLETED'  THEN 1 ELSE 0 END AS IS_COMPLETED,
    CASE WHEN UPPER(a.STATUS) = 'NO-SHOW'    THEN 1 ELSE 0 END AS IS_NO_SHOW,
    CASE WHEN UPPER(a.STATUS) = 'CANCELLED'  THEN 1 ELSE 0 END AS IS_CANCELLED,
    CASE WHEN UPPER(a.STATUS) = 'SCHEDULED'  THEN 1 ELSE 0 END AS IS_SCHEDULED
FROM HOSPITAL_DW.CORE.CORE_APPOINTMENTS a;

-- ============================================================
-- 4. FACT: BILLING
-- ============================================================
CREATE OR REPLACE DYNAMIC TABLE HOSPITAL_DW.MART.FACT_BILLING
    TARGET_LAG = '5 MINUTES'
    WAREHOUSE  = HOSPITAL_WH
AS
SELECT
    b.BILL_ID,
    TO_NUMBER(TO_CHAR(b.BILL_DATE, 'YYYYMMDD'))    AS DATE_KEY,
    b.PATIENT_ID                                   AS PATIENT_KEY,
    b.BILL_DATE,
    b.SERVICE_CODE,
    b.SERVICE_DESC,
    b.DEPARTMENT,
    b.GROSS_AMOUNT,
    b.DISCOUNT_AMOUNT,
    b.TAX_AMOUNT,
    b.NET_AMOUNT,
    b.PAYMENT_MODE,
    b.INSURER_NAME,
    CASE WHEN UPPER(b.PAYMENT_MODE) = 'INSURANCE' THEN 1 ELSE 0 END AS IS_INSURANCE,
    CASE WHEN UPPER(b.PAYMENT_MODE) != 'INSURANCE' THEN 1 ELSE 0 END AS IS_SELF_PAY
FROM HOSPITAL_DW.CORE.CORE_BILLING b;

-- ============================================================
-- 5. VISUAL: APPOINTMENTS BY DEPARTMENT
-- ============================================================
CREATE OR REPLACE DYNAMIC TABLE HOSPITAL_DW.MART.DT_VISUAL_DEPT_APPT
    TARGET_LAG = '5 MINUTES'
    WAREHOUSE  = HOSPITAL_WH
AS
SELECT 
    DEPARTMENT, 
    COUNT(*) AS APPOINTMENTS 
FROM HOSPITAL_DW.MART.FACT_APPOINTMENT 
GROUP BY DEPARTMENT;

-- ============================================================
-- 6. VISUAL: REVENUE BY PAYMENT MODE
-- ============================================================
CREATE OR REPLACE DYNAMIC TABLE HOSPITAL_DW.MART.DT_VISUAL_PAYMENT_REVENUE
    TARGET_LAG = '5 MINUTES'
    WAREHOUSE  = HOSPITAL_WH
AS
SELECT 
    PAYMENT_MODE, 
    SUM(NET_AMOUNT) AS REVENUE 
FROM HOSPITAL_DW.MART.FACT_BILLING 
GROUP BY PAYMENT_MODE;

-- ============================================================
-- 7. VISUAL: MONTHLY REVENUE TREND
-- ============================================================
CREATE OR REPLACE DYNAMIC TABLE HOSPITAL_DW.MART.DT_VISUAL_MONTHLY_REVENUE
    TARGET_LAG = '5 MINUTES'
    WAREHOUSE  = HOSPITAL_WH
AS
SELECT 
    DATE_TRUNC('MONTH', BILL_DATE) AS MONTH, 
    SUM(NET_AMOUNT) AS REVENUE 
FROM HOSPITAL_DW.MART.FACT_BILLING 
GROUP BY DATE_TRUNC('MONTH', BILL_DATE);

-- ============================================================
-- 8. VISUAL: PATIENT DEMOGRAPHICS (GENDER)
-- ============================================================
CREATE OR REPLACE DYNAMIC TABLE HOSPITAL_DW.MART.DT_VISUAL_DEMOGRAPHICS
    TARGET_LAG = '5 MINUTES'
    WAREHOUSE  = HOSPITAL_WH
AS
SELECT 
    GENDER, 
    COUNT(*) AS COUNT 
FROM HOSPITAL_DW.MART.DIM_PATIENT 
WHERE GENDER IS NOT NULL 
GROUP BY GENDER;

-- ============================================================
-- 9. VISUAL: APPOINTMENT STATUS OVERVIEW
-- ============================================================
CREATE OR REPLACE DYNAMIC TABLE HOSPITAL_DW.MART.DT_VISUAL_APPT_STATUS
    TARGET_LAG = '5 MINUTES'
    WAREHOUSE  = HOSPITAL_WH
AS
SELECT 
    STATUS, 
    COUNT(*) AS COUNT 
FROM HOSPITAL_DW.MART.FACT_APPOINTMENT 
GROUP BY STATUS;

-- ============================================================
-- 10. VISUAL: TOP DOCTORS UTILIZATION
-- ============================================================
CREATE OR REPLACE DYNAMIC TABLE HOSPITAL_DW.MART.DT_VISUAL_TOP_DOCTORS
    TARGET_LAG = '5 MINUTES'
    WAREHOUSE  = HOSPITAL_WH
AS
SELECT 
    DOCTOR_NAME, 
    COUNT(*) AS APPOINTMENTS 
FROM HOSPITAL_DW.MART.FACT_APPOINTMENT 
GROUP BY DOCTOR_NAME;

-- ============================================================
-- VERIFY TABLES
-- ============================================================
SELECT * FROM HOSPITAL_DW.MART.DT_VISUAL_DEPT_APPT;
SELECT * FROM HOSPITAL_DW.MART.DT_VISUAL_MONTHLY_REVENUE;
