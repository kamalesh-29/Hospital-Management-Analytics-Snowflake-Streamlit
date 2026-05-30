-- ============================================================
-- 16. MATERIALIZED VIEW
-- PURPOSE: Pre-computed aggregations for dashboard performance
-- ============================================================

USE DATABASE HOSPITAL_DW;
USE SCHEMA MART;
USE WAREHOUSE HOSPITAL_WH;

-- ============================================================
-- CLUSTERING (Performance optimization before materialized views)
-- ============================================================
ALTER TABLE HOSPITAL_DW.CORE.CORE_APPOINTMENTS CLUSTER BY (APPT_DATE, DEPARTMENT);
ALTER TABLE HOSPITAL_DW.CORE.CORE_BILLING CLUSTER BY (BILL_DATE, DEPARTMENT);

-- ============================================================
-- MATERIALIZED VIEW: MONTHLY REVENUE SUMMARY
-- ============================================================
CREATE OR REPLACE MATERIALIZED VIEW HOSPITAL_DW.MART.MV_MONTHLY_REVENUE
    COMMENT = 'Pre-aggregated monthly revenue by department. Auto-refreshes.'
AS
SELECT
    DATE_TRUNC('MONTH', BILL_DATE)      AS BILL_MONTH,
    DEPARTMENT,
    PAYMENT_MODE,
    COUNT(*)                             AS BILL_COUNT,
    SUM(GROSS_AMOUNT)                    AS TOTAL_GROSS,
    SUM(DISCOUNT_AMOUNT)                 AS TOTAL_DISCOUNT,
    SUM(TAX_AMOUNT)                      AS TOTAL_TAX,
    SUM(NET_AMOUNT)                      AS TOTAL_NET,
    AVG(NET_AMOUNT)                      AS AVG_NET
FROM HOSPITAL_DW.MART.FACT_BILLING
GROUP BY DATE_TRUNC('MONTH', BILL_DATE), DEPARTMENT, PAYMENT_MODE;

-- ============================================================
-- MATERIALIZED VIEW: DEPARTMENT APPOINTMENT MONTHLY SUMMARY
-- ============================================================
CREATE OR REPLACE MATERIALIZED VIEW HOSPITAL_DW.MART.MV_DEPT_APPT_MONTHLY
    COMMENT = 'Pre-aggregated monthly appointment stats by department.'
AS
SELECT
    DATE_TRUNC('MONTH', APPT_DATE)        AS APPT_MONTH,
    DEPARTMENT,
    COUNT(*)                              AS TOTAL_APPTS,
    SUM(IS_COMPLETED)                     AS COMPLETED,
    SUM(IS_NO_SHOW)                       AS NO_SHOWS,
    SUM(IS_CANCELLED)                     AS CANCELLED
FROM HOSPITAL_DW.MART.FACT_APPOINTMENT
GROUP BY DATE_TRUNC('MONTH', APPT_DATE), DEPARTMENT;

-- ============================================================
-- VERIFICATION
-- ============================================================
SHOW MATERIALIZED VIEWS IN SCHEMA HOSPITAL_DW.MART;
