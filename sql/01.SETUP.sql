-- ============================================================
-- 01. SETUP
-- PURPOSE: Database, schemas, single warehouse
-- ============================================================

USE ROLE SYSADMIN;

-- =========================
-- DATABASE
-- =========================
CREATE DATABASE IF NOT EXISTS HOSPITAL_DW
    COMMENT = 'Hospital Management Data Warehouse';

-- =========================
-- SCHEMAS
-- =========================
CREATE SCHEMA IF NOT EXISTS HOSPITAL_DW.RAW
    COMMENT = 'RAW layer: Landing zone for CSV data';

CREATE SCHEMA IF NOT EXISTS HOSPITAL_DW.CORE
    COMMENT = 'CORE layer: Cleaned, validated, deduplicated data';

CREATE SCHEMA IF NOT EXISTS HOSPITAL_DW.MART
    COMMENT = 'MART layer: STAR schema (Dimension + Fact tables)';

CREATE SCHEMA IF NOT EXISTS HOSPITAL_DW.GOVERNANCE
    COMMENT = 'GOVERNANCE: Security policies, masking rules';

-- =========================
-- SINGLE WAREHOUSE
-- =========================
CREATE WAREHOUSE IF NOT EXISTS HOSPITAL_WH
    WAREHOUSE_SIZE = 'SMALL'
    AUTO_SUSPEND   = 120
    AUTO_RESUME    = TRUE
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 2
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Single warehouse for all hospital workloads';

-- =========================
-- RESOURCE MONITOR
-- =========================
USE ROLE ACCOUNTADMIN;

CREATE RESOURCE MONITOR IF NOT EXISTS HACKATHON_MONITOR
    WITH
        CREDIT_QUOTA = 10
        FREQUENCY    = MONTHLY
        START_TIMESTAMP = IMMEDIATELY
        TRIGGERS
            ON 75 PERCENT DO NOTIFY
            ON 90 PERCENT DO NOTIFY
            ON 100 PERCENT DO SUSPEND_IMMEDIATE;

ALTER WAREHOUSE HOSPITAL_WH SET RESOURCE_MONITOR = HACKATHON_MONITOR;

-- =========================
-- SET CONTEXT
-- =========================
USE ROLE SYSADMIN;
USE DATABASE HOSPITAL_DW;
USE WAREHOUSE HOSPITAL_WH;
