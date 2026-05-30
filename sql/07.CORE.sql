-- ============================================================
-- 07. CORE
-- PURPOSE: CORE layer cleaned tables (proper data types)
-- ============================================================

USE DATABASE HOSPITAL_DW;
USE SCHEMA CORE;
USE WAREHOUSE HOSPITAL_WH;

-- ============================================================
-- CORE TABLE: PATIENTS
-- ============================================================
CREATE OR REPLACE TABLE HOSPITAL_DW.CORE.CORE_PATIENTS (
    PATIENT_ID        NUMBER          NOT NULL,
    FULL_NAME         VARCHAR(200)    NOT NULL,
    DOB               DATE,
    GENDER            VARCHAR(20),
    PHONE             VARCHAR(20),
    EMAIL             VARCHAR(200),
    CITY              VARCHAR(100),
    STATE             VARCHAR(100),
    REGISTRATION_DATE DATE,
    _LOADED_AT        TIMESTAMP_NTZ,
    _SOURCE_FILE      VARCHAR(500),
    _CLEANED_AT       TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT PK_CORE_PATIENTS PRIMARY KEY (PATIENT_ID)
);

-- ============================================================
-- CORE TABLE: APPOINTMENTS
-- ============================================================
CREATE OR REPLACE TABLE HOSPITAL_DW.CORE.CORE_APPOINTMENTS (
    APPT_ID           NUMBER          NOT NULL,
    APPT_DATE         DATE            NOT NULL,
    PATIENT_ID        NUMBER          NOT NULL,
    DOCTOR_ID         NUMBER          NOT NULL,
    DOCTOR_NAME       VARCHAR(200),
    DEPARTMENT        VARCHAR(100),
    SLOT              VARCHAR(30),
    STATUS            VARCHAR(30)     NOT NULL,
    _LOADED_AT        TIMESTAMP_NTZ,
    _SOURCE_FILE      VARCHAR(500),
    _CLEANED_AT       TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT PK_CORE_APPOINTMENTS PRIMARY KEY (APPT_ID)
);

-- ============================================================
-- CORE TABLE: BILLING
-- ============================================================
CREATE OR REPLACE TABLE HOSPITAL_DW.CORE.CORE_BILLING (
    BILL_ID           NUMBER          NOT NULL,
    BILL_DATE         DATE            NOT NULL,
    PATIENT_ID        NUMBER          NOT NULL,
    SERVICE_CODE      VARCHAR(20)     NOT NULL,
    SERVICE_DESC      VARCHAR(200),
    DEPARTMENT        VARCHAR(100),
    GROSS_AMOUNT      NUMBER(12,2)    NOT NULL,
    DISCOUNT_AMOUNT   NUMBER(12,2)    DEFAULT 0,
    TAX_AMOUNT        NUMBER(12,2)    DEFAULT 0,
    NET_AMOUNT        NUMBER(12,2)    NOT NULL,
    PAYMENT_MODE      VARCHAR(30)     NOT NULL,
    INSURER_NAME      VARCHAR(200),
    _LOADED_AT        TIMESTAMP_NTZ,
    _SOURCE_FILE      VARCHAR(500),
    _CLEANED_AT       TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT PK_CORE_BILLING PRIMARY KEY (BILL_ID)
);
