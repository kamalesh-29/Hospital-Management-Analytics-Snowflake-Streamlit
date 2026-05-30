-- ============================================================
-- 03. STAGE
-- PURPOSE: Single internal stage for all CSV files
-- ============================================================

USE DATABASE HOSPITAL_DW;
USE SCHEMA RAW;

-- =========================
-- SINGLE INTERNAL STAGE
-- =========================
CREATE OR REPLACE STAGE HOSPITAL_DW.RAW.HOSPITAL_CSV_STAGE
    FILE_FORMAT = HOSPITAL_DW.RAW.CSV_FILE_FORMAT
    COMMENT = 'Internal stage for all hospital CSV files';

-- ============================================================
-- UPLOAD FILES (Run in SnowSQL CLI):
-- ============================================================
-- PUT file://C:/path/patients_master_clean.csv @HOSPITAL_CSV_STAGE AUTO_COMPRESS=TRUE OVERWRITE=TRUE;
-- PUT file://C:/path/patients_master_dirty.csv @HOSPITAL_CSV_STAGE AUTO_COMPRESS=TRUE OVERWRITE=TRUE;
-- PUT file://C:/path/appointments_clean.csv    @HOSPITAL_CSV_STAGE AUTO_COMPRESS=TRUE OVERWRITE=TRUE;
-- PUT file://C:/path/billing_clean.csv         @HOSPITAL_CSV_STAGE AUTO_COMPRESS=TRUE OVERWRITE=TRUE;
-- PUT file://C:/path/billing_dirty.csv         @HOSPITAL_CSV_STAGE AUTO_COMPRESS=TRUE OVERWRITE=TRUE;
--
-- VERIFY:
-- LIST @HOSPITAL_DW.RAW.HOSPITAL_CSV_STAGE;
