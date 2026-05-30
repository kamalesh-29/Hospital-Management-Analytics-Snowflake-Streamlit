-- ============================================================
-- 06. STREAMS
-- PURPOSE: Change Data Capture on RAW tables
-- ============================================================

USE DATABASE HOSPITAL_DW;
USE SCHEMA RAW;

-- ----------------------------------------------------------
-- PATIENT STREAM
-- ----------------------------------------------------------

CREATE OR REPLACE STREAM HOSPITAL_DW.RAW.STREAM_RAW_PATIENTS
    ON TABLE HOSPITAL_DW.RAW.RAW_PATIENTS
    APPEND_ONLY = TRUE
    SHOW_INITIAL_ROWS = TRUE
    COMMENT = 'Captures new patient records for CORE processing';

-- ----------------------------------------------------------
-- APPOINTMENT STREAM
-- ----------------------------------------------------------

CREATE OR REPLACE STREAM HOSPITAL_DW.RAW.STREAM_RAW_APPOINTMENTS
    ON TABLE HOSPITAL_DW.RAW.RAW_APPOINTMENTS
    APPEND_ONLY = TRUE
    SHOW_INITIAL_ROWS = TRUE
    COMMENT = 'Captures new appointment records for CORE processing';

-- ----------------------------------------------------------
-- BILLING STREAM
-- ----------------------------------------------------------

CREATE OR REPLACE STREAM HOSPITAL_DW.RAW.STREAM_RAW_BILLING
    ON TABLE HOSPITAL_DW.RAW.RAW_BILLING
    APPEND_ONLY = TRUE
    SHOW_INITIAL_ROWS = TRUE
    COMMENT = 'Captures new billing records for CORE processing';

-- ----------------------------------------------------------
-- VERIFY
-- ----------------------------------------------------------
SELECT 'STREAM_RAW_PATIENTS' AS STREAM_NAME,
       SYSTEM$STREAM_HAS_DATA('HOSPITAL_DW.RAW.STREAM_RAW_PATIENTS') AS HAS_DATA
UNION ALL
SELECT 'STREAM_RAW_APPOINTMENTS',
       SYSTEM$STREAM_HAS_DATA('HOSPITAL_DW.RAW.STREAM_RAW_APPOINTMENTS')
UNION ALL
SELECT 'STREAM_RAW_BILLING',
       SYSTEM$STREAM_HAS_DATA('HOSPITAL_DW.RAW.STREAM_RAW_BILLING');
