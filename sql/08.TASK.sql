-- ============================================================
-- 08. TASK
-- PURPOSE: Scheduled tasks for RAW → CORE cleaning + MERGE
-- ============================================================

USE DATABASE HOSPITAL_DW;
USE SCHEMA CORE;
USE WAREHOUSE HOSPITAL_WH;

-- ============================================================
-- TASK 1: CLEAN PATIENTS
-- ============================================================

CREATE OR REPLACE TASK HOSPITAL_DW.CORE.TASK_CLEAN_PATIENTS
    WAREHOUSE = HOSPITAL_WH
    SCHEDULE  = '5 MINUTE'
    WHEN      SYSTEM$STREAM_HAS_DATA('HOSPITAL_DW.RAW.STREAM_RAW_PATIENTS')
AS
MERGE INTO HOSPITAL_DW.CORE.CORE_PATIENTS AS target
USING (
    SELECT
        TRY_TO_NUMBER(PATIENT_ID)                           AS PATIENT_ID,
        TRIM(FULL_NAME)                                     AS FULL_NAME,
        COALESCE(
            TRY_TO_DATE(DOB, 'YYYY-MM-DD'),
            TRY_TO_DATE(DOB, 'DD/MM/YYYY')
        )                                                    AS DOB,
        TRIM(GENDER)                                        AS GENDER,
        TRIM(PHONE)                                         AS PHONE,
        TRIM(EMAIL)                                         AS EMAIL,
        TRIM(CITY)                                          AS CITY,
        TRIM(STATE)                                         AS STATE,
        TRY_TO_DATE(REGISTRATION_DATE, 'YYYY-MM-DD')       AS REGISTRATION_DATE
    FROM HOSPITAL_DW.RAW.STREAM_RAW_PATIENTS
    WHERE TRY_TO_NUMBER(PATIENT_ID) IS NOT NULL
      AND TRIM(FULL_NAME) IS NOT NULL
      AND COALESCE(TRY_TO_DATE(DOB, 'YYYY-MM-DD'), TRY_TO_DATE(DOB, 'DD/MM/YYYY')) IS NOT NULL
      AND (EMAIL IS NULL OR EMAIL LIKE '%@%')
      AND (PHONE IS NULL OR LENGTH(TRIM(PHONE)) >= 10)
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TRY_TO_NUMBER(PATIENT_ID)
        ORDER BY METADATA$ACTION DESC, METADATA$ISUPDATE
    ) = 1
) AS source
ON target.PATIENT_ID = source.PATIENT_ID
WHEN MATCHED THEN UPDATE SET
    target.FULL_NAME         = source.FULL_NAME,
    target.DOB               = source.DOB,
    target.GENDER            = source.GENDER,
    target.PHONE             = source.PHONE,
    target.EMAIL             = source.EMAIL,
    target.CITY              = source.CITY,
    target.STATE             = source.STATE,
    target.REGISTRATION_DATE = source.REGISTRATION_DATE
WHEN NOT MATCHED THEN INSERT (
    PATIENT_ID, FULL_NAME, DOB, GENDER, PHONE, EMAIL,
    CITY, STATE, REGISTRATION_DATE
) VALUES (
    source.PATIENT_ID, source.FULL_NAME, source.DOB, source.GENDER,
    source.PHONE, source.EMAIL, source.CITY, source.STATE,
    source.REGISTRATION_DATE
);

-- ============================================================
-- TASK 2: CLEAN APPOINTMENTS
-- ============================================================

CREATE OR REPLACE TASK HOSPITAL_DW.CORE.TASK_CLEAN_APPOINTMENTS
    WAREHOUSE = HOSPITAL_WH
    SCHEDULE  = '5 MINUTE'
    WHEN      SYSTEM$STREAM_HAS_DATA('HOSPITAL_DW.RAW.STREAM_RAW_APPOINTMENTS')
AS
MERGE INTO HOSPITAL_DW.CORE.CORE_APPOINTMENTS AS target
USING (
    SELECT
        TRY_TO_NUMBER(s.APPT_ID)                AS APPT_ID,
        TRY_TO_DATE(s.APPT_DATE, 'YYYY-MM-DD') AS APPT_DATE,
        TRY_TO_NUMBER(s.PATIENT_ID)             AS PATIENT_ID,
        TRY_TO_NUMBER(s.DOCTOR_ID)              AS DOCTOR_ID,
        TRIM(s.DOCTOR_NAME)                     AS DOCTOR_NAME,
        TRIM(s.DEPARTMENT)                      AS DEPARTMENT,
        TRIM(s.SLOT)                            AS SLOT,
        UPPER(TRIM(s.STATUS))                   AS STATUS
    FROM HOSPITAL_DW.RAW.STREAM_RAW_APPOINTMENTS s
    WHERE TRY_TO_NUMBER(s.APPT_ID) IS NOT NULL
      AND TRY_TO_DATE(s.APPT_DATE, 'YYYY-MM-DD') IS NOT NULL
      AND TRY_TO_NUMBER(s.PATIENT_ID) IS NOT NULL
      AND TRY_TO_NUMBER(s.DOCTOR_ID) IS NOT NULL
      AND UPPER(TRIM(s.STATUS)) IN ('SCHEDULED', 'COMPLETED', 'NO-SHOW', 'CANCELLED')
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TRY_TO_NUMBER(s.APPT_ID)
        ORDER BY METADATA$ACTION DESC, METADATA$ISUPDATE
    ) = 1
) AS source
ON target.APPT_ID = source.APPT_ID
WHEN MATCHED THEN UPDATE SET
    target.APPT_DATE    = source.APPT_DATE,
    target.PATIENT_ID   = source.PATIENT_ID,
    target.DOCTOR_ID    = source.DOCTOR_ID,
    target.DOCTOR_NAME  = source.DOCTOR_NAME,
    target.DEPARTMENT   = source.DEPARTMENT,
    target.SLOT         = source.SLOT,
    target.STATUS       = source.STATUS
WHEN NOT MATCHED THEN INSERT (
    APPT_ID, APPT_DATE, PATIENT_ID, DOCTOR_ID, DOCTOR_NAME,
    DEPARTMENT, SLOT, STATUS
) VALUES (
    source.APPT_ID, source.APPT_DATE, source.PATIENT_ID,
    source.DOCTOR_ID, source.DOCTOR_NAME, source.DEPARTMENT,
    source.SLOT, source.STATUS
);

-- ============================================================
-- TASK 3: CLEAN BILLING
-- ============================================================

CREATE OR REPLACE TASK HOSPITAL_DW.CORE.TASK_CLEAN_BILLING
    WAREHOUSE = HOSPITAL_WH
    SCHEDULE  = '5 MINUTE'
    WHEN      SYSTEM$STREAM_HAS_DATA('HOSPITAL_DW.RAW.STREAM_RAW_BILLING')
AS
MERGE INTO HOSPITAL_DW.CORE.CORE_BILLING AS target
USING (
    SELECT
        TRY_TO_NUMBER(s.BILL_ID)                AS BILL_ID,
        TRY_TO_DATE(s.BILL_DATE, 'YYYY-MM-DD') AS BILL_DATE,
        TRY_TO_NUMBER(s.PATIENT_ID)             AS PATIENT_ID,
        TRIM(s.SERVICE_CODE)                    AS SERVICE_CODE,
        TRIM(s.SERVICE_DESC)                    AS SERVICE_DESC,
        TRIM(s.DEPARTMENT)                      AS DEPARTMENT,
        TRY_TO_NUMBER(s.GROSS_AMOUNT, 12, 2)   AS GROSS_AMOUNT,
        COALESCE(TRY_TO_NUMBER(s.DISCOUNT_AMOUNT, 12, 2), 0) AS DISCOUNT_AMOUNT,
        COALESCE(TRY_TO_NUMBER(s.TAX_AMOUNT, 12, 2), 0)      AS TAX_AMOUNT,
        ROUND(
            TRY_TO_NUMBER(s.GROSS_AMOUNT, 12, 2)
            - COALESCE(TRY_TO_NUMBER(s.DISCOUNT_AMOUNT, 12, 2), 0)
            + COALESCE(TRY_TO_NUMBER(s.TAX_AMOUNT, 12, 2), 0)
        , 2)                                     AS NET_AMOUNT,
        UPPER(TRIM(s.PAYMENT_MODE))             AS PAYMENT_MODE,
        TRIM(s.INSURER_NAME)                    AS INSURER_NAME
    FROM HOSPITAL_DW.RAW.STREAM_RAW_BILLING s
    WHERE TRY_TO_NUMBER(s.BILL_ID) IS NOT NULL
      AND TRY_TO_DATE(s.BILL_DATE, 'YYYY-MM-DD') IS NOT NULL
      AND TRY_TO_NUMBER(s.PATIENT_ID) IS NOT NULL
      AND TRY_TO_NUMBER(s.GROSS_AMOUNT, 12, 2) IS NOT NULL
      AND TRY_TO_NUMBER(s.GROSS_AMOUNT, 12, 2) >= 0
      AND ROUND(
            TRY_TO_NUMBER(s.GROSS_AMOUNT, 12, 2)
            - COALESCE(TRY_TO_NUMBER(s.DISCOUNT_AMOUNT, 12, 2), 0)
            + COALESCE(TRY_TO_NUMBER(s.TAX_AMOUNT, 12, 2), 0)
        , 2) >= 0
      AND UPPER(TRIM(s.PAYMENT_MODE)) IN ('CASH', 'CARD', 'UPI', 'INSURANCE')
      AND (UPPER(TRIM(s.PAYMENT_MODE)) != 'INSURANCE' OR TRIM(s.INSURER_NAME) IS NOT NULL)
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TRY_TO_NUMBER(s.BILL_ID)
        ORDER BY METADATA$ACTION DESC, METADATA$ISUPDATE
    ) = 1
) AS source
ON target.BILL_ID = source.BILL_ID
WHEN MATCHED THEN UPDATE SET
    target.BILL_DATE       = source.BILL_DATE,
    target.PATIENT_ID      = source.PATIENT_ID,
    target.SERVICE_CODE    = source.SERVICE_CODE,
    target.SERVICE_DESC    = source.SERVICE_DESC,
    target.DEPARTMENT      = source.DEPARTMENT,
    target.GROSS_AMOUNT    = source.GROSS_AMOUNT,
    target.DISCOUNT_AMOUNT = source.DISCOUNT_AMOUNT,
    target.TAX_AMOUNT      = source.TAX_AMOUNT,
    target.NET_AMOUNT      = source.NET_AMOUNT,
    target.PAYMENT_MODE    = source.PAYMENT_MODE,
    target.INSURER_NAME    = source.INSURER_NAME
WHEN NOT MATCHED THEN INSERT (
    BILL_ID, BILL_DATE, PATIENT_ID, SERVICE_CODE, SERVICE_DESC,
    DEPARTMENT, GROSS_AMOUNT, DISCOUNT_AMOUNT, TAX_AMOUNT,
    NET_AMOUNT, PAYMENT_MODE, INSURER_NAME
) VALUES (
    source.BILL_ID, source.BILL_DATE, source.PATIENT_ID,
    source.SERVICE_CODE, source.SERVICE_DESC, source.DEPARTMENT,
    source.GROSS_AMOUNT, source.DISCOUNT_AMOUNT, source.TAX_AMOUNT,
    source.NET_AMOUNT, source.PAYMENT_MODE, source.INSURER_NAME
);

-- ============================================================
-- ENABLE ALL TASKS
-- ============================================================
ALTER TASK HOSPITAL_DW.CORE.TASK_CLEAN_PATIENTS RESUME;
ALTER TASK HOSPITAL_DW.CORE.TASK_CLEAN_APPOINTMENTS RESUME;
ALTER TASK HOSPITAL_DW.CORE.TASK_CLEAN_BILLING RESUME;
