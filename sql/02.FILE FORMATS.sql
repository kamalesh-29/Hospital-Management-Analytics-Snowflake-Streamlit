-- ============================================================
-- 02. FILE FORMATS
-- PURPOSE: CSV file format definition for all data ingestion
-- ============================================================

USE DATABASE HOSPITAL_DW;
USE SCHEMA RAW;

-- =========================
-- CSV FILE FORMAT
-- =========================
CREATE OR REPLACE FILE FORMAT HOSPITAL_DW.RAW.CSV_FILE_FORMAT
    TYPE                            = 'CSV'
    FIELD_DELIMITER                 = ','
    SKIP_HEADER                     = 1
    FIELD_OPTIONALLY_ENCLOSED_BY    = '"'
    NULL_IF                         = ('', 'NULL', 'null', 'N/A', 'n/a', 'None')
    EMPTY_FIELD_AS_NULL             = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH  = FALSE
    TRIM_SPACE                      = TRUE
    COMMENT = 'Standard CSV format for hospital data files';
