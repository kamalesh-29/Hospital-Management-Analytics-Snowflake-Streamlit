-- ============================================================
-- 05. SNOWPIPE
-- PURPOSE: Automated ingestion with PATTERN matching
-- ============================================================

USE DATABASE HOSPITAL_DW;
USE SCHEMA RAW;

-- ----------------------------------------------------------
-- PATIENT PIPE
-- ----------------------------------------------------------

CREATE OR REPLACE PIPE PATIENT_PIPE
AUTO_INGEST = TRUE
AS
COPY INTO HOSPITAL_DW.RAW.RAW_PATIENTS
    (PATIENT_ID, FULL_NAME, DOB, GENDER, PHONE, EMAIL, CITY, STATE, REGISTRATION_DATE)
FROM @HOSPITAL_CSV_STAGE
PATTERN = '.*patients.*[.]csv'
FILE_FORMAT = (FORMAT_NAME = HOSPITAL_DW.RAW.CSV_FILE_FORMAT);

-- ----------------------------------------------------------
-- APPOINTMENT PIPE
-- ----------------------------------------------------------

CREATE OR REPLACE PIPE APPOINTMENT_PIPE
AUTO_INGEST = TRUE
AS
COPY INTO HOSPITAL_DW.RAW.RAW_APPOINTMENTS
    (APPT_ID, APPT_DATE, PATIENT_ID, DOCTOR_ID, DOCTOR_NAME, DEPARTMENT, SLOT, STATUS)
FROM @HOSPITAL_CSV_STAGE
PATTERN = '.*appointments.*[.]csv'
FILE_FORMAT = (FORMAT_NAME = HOSPITAL_DW.RAW.CSV_FILE_FORMAT);

-- ----------------------------------------------------------
-- BILLING PIPE
-- ----------------------------------------------------------

CREATE OR REPLACE PIPE BILLING_PIPE
AUTO_INGEST = TRUE
AS
COPY INTO HOSPITAL_DW.RAW.RAW_BILLING
    (BILL_ID, BILL_DATE, PATIENT_ID, SERVICE_CODE, SERVICE_DESC, DEPARTMENT,
     GROSS_AMOUNT, DISCOUNT_AMOUNT, TAX_AMOUNT, NET_AMOUNT, PAYMENT_MODE, INSURER_NAME)
FROM @HOSPITAL_CSV_STAGE
PATTERN = '.*billing.*[.]csv'
FILE_FORMAT = (FORMAT_NAME = HOSPITAL_DW.RAW.CSV_FILE_FORMAT);

-- ----------------------------------------------------------
-- VERIFY & MONITOR
-- ----------------------------------------------------------
SHOW PIPES IN SCHEMA HOSPITAL_DW.RAW;

-- SELECT SYSTEM$PIPE_STATUS('HOSPITAL_DW.RAW.PATIENT_PIPE');
-- SELECT SYSTEM$PIPE_STATUS('HOSPITAL_DW.RAW.APPOINTMENT_PIPE');
-- SELECT SYSTEM$PIPE_STATUS('HOSPITAL_DW.RAW.BILLING_PIPE');
