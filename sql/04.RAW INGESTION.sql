-- ============================================================
-- 04. RAW INGESTION
-- PURPOSE: RAW layer tables + initial COPY INTO
-- ============================================================

USE DATABASE HOSPITAL_DW;
USE SCHEMA RAW;
USE WAREHOUSE HOSPITAL_WH;

-- ============================================================
-- RAW TABLE: PATIENTS
-- ============================================================
CREATE OR REPLACE TABLE HOSPITAL_DW.RAW.RAW_PATIENTS (
    PATIENT_ID        VARCHAR(20),
    FULL_NAME         VARCHAR(200),
    DOB               VARCHAR(20),
    GENDER            VARCHAR(20),
    PHONE             VARCHAR(20),
    EMAIL             VARCHAR(200),
    CITY              VARCHAR(100),
    STATE             VARCHAR(100),
    REGISTRATION_DATE VARCHAR(20)
);

-- ============================================================
-- RAW TABLE: APPOINTMENTS
-- ============================================================
CREATE OR REPLACE TABLE HOSPITAL_DW.RAW.RAW_APPOINTMENTS (
    APPT_ID           VARCHAR(20),
    APPT_DATE         VARCHAR(20),
    PATIENT_ID        VARCHAR(20),
    DOCTOR_ID         VARCHAR(20),
    DOCTOR_NAME       VARCHAR(200),
    DEPARTMENT        VARCHAR(100),
    SLOT              VARCHAR(30),
    STATUS            VARCHAR(30)
);

-- ============================================================
-- RAW TABLE: BILLING
-- ============================================================
CREATE OR REPLACE TABLE HOSPITAL_DW.RAW.RAW_BILLING (
    BILL_ID           VARCHAR(20),
    BILL_DATE         VARCHAR(20),
    PATIENT_ID        VARCHAR(20),
    SERVICE_CODE      VARCHAR(20),
    SERVICE_DESC      VARCHAR(200),
    DEPARTMENT        VARCHAR(100),
    GROSS_AMOUNT      VARCHAR(30),
    DISCOUNT_AMOUNT   VARCHAR(30),
    TAX_AMOUNT        VARCHAR(30),
    NET_AMOUNT        VARCHAR(30),
    PAYMENT_MODE      VARCHAR(30),
    INSURER_NAME      VARCHAR(200)
);

-- ============================================================
-- EXCEPTION TABLE
-- ============================================================
CREATE OR REPLACE TABLE HOSPITAL_DW.RAW.RAW_EXCEPTIONS (
    EXCEPTION_ID      NUMBER AUTOINCREMENT,
    SOURCE_TABLE      VARCHAR(100),
    RECORD_ID         VARCHAR(50),
    REJECTION_REASON  VARCHAR(1000),
    RECORD_DATA       VARIANT,
    REJECTED_AT       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    REVIEWED          BOOLEAN DEFAULT FALSE
);



-- ============================================================
-- VERIFY
-- ============================================================
SELECT 'RAW_PATIENTS' AS TBL, COUNT(*) AS CNT FROM HOSPITAL_DW.RAW.RAW_PATIENTS
UNION ALL
SELECT 'RAW_APPOINTMENTS', COUNT(*) FROM HOSPITAL_DW.RAW.RAW_APPOINTMENTS
UNION ALL
SELECT 'RAW_BILLING', COUNT(*) FROM HOSPITAL_DW.RAW.RAW_BILLING;
