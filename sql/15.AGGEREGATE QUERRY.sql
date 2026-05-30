-- ============================================================
-- 15. AGGEREGATE QUERRY (Spelling as requested)
-- PURPOSE: High-level aggregations and KPI calculations
-- ============================================================

USE DATABASE HOSPITAL_DW;
USE SCHEMA MART;
USE WAREHOUSE HOSPITAL_WH;

-- ----------------------------------------------------------
-- EXECUTIVE KPI SUMMARY
-- ----------------------------------------------------------
SELECT
    COUNT(DISTINCT fa.APPT_ID) AS TOTAL_APPOINTMENTS,
    SUM(fa.IS_COMPLETED) AS COMPLETED_VISITS,
    SUM(fa.IS_NO_SHOW) AS TOTAL_NO_SHOWS,
    ROUND(SUM(fa.IS_COMPLETED) * 100.0 / NULLIF(COUNT(*), 0), 1) AS COMPLETION_RATE_PCT,
    COUNT(DISTINCT fa.PATIENT_KEY) AS UNIQUE_PATIENTS
FROM HOSPITAL_DW.MART.FACT_APPOINTMENT fa;

-- ----------------------------------------------------------
-- REVENUE AGGREGATION
-- ----------------------------------------------------------
SELECT
    COUNT(DISTINCT fb.BILL_ID) AS TOTAL_BILLS,
    ROUND(SUM(fb.GROSS_AMOUNT), 2) AS TOTAL_GROSS_REVENUE,
    ROUND(SUM(fb.NET_AMOUNT), 2) AS TOTAL_NET_REVENUE,
    ROUND(AVG(fb.NET_AMOUNT), 2) AS AVG_BILL_VALUE,
    ROUND(SUM(fb.DISCOUNT_AMOUNT), 2) AS TOTAL_DISCOUNTS
FROM HOSPITAL_DW.MART.FACT_BILLING fb;

-- ----------------------------------------------------------
-- INSURANCE VS SELF-PAY MIX
-- ----------------------------------------------------------
SELECT
    fb.PAYMENT_MODE,
    COALESCE(fb.INSURER_NAME, 'Self-Pay') AS INSURER,
    COUNT(*) AS BILL_COUNT,
    ROUND(SUM(fb.NET_AMOUNT), 2) AS TOTAL_REVENUE,
    ROUND(SUM(fb.NET_AMOUNT) * 100.0 / SUM(SUM(fb.NET_AMOUNT)) OVER(), 2) AS REVENUE_SHARE_PCT
FROM HOSPITAL_DW.MART.FACT_BILLING fb
GROUP BY fb.PAYMENT_MODE, COALESCE(fb.INSURER_NAME, 'Self-Pay')
ORDER BY TOTAL_REVENUE DESC;

-- ----------------------------------------------------------
-- TOP 10 SERVICES BY REVENUE
-- ----------------------------------------------------------
SELECT
    svc.SERVICE_DESC,
    COUNT(*) AS BILL_COUNT,
    ROUND(SUM(fb.NET_AMOUNT), 2) AS TOTAL_REVENUE
FROM HOSPITAL_DW.MART.FACT_BILLING fb
INNER JOIN HOSPITAL_DW.MART.DIM_SERVICE svc ON fb.SERVICE_KEY = svc.SERVICE_KEY
GROUP BY svc.SERVICE_DESC
ORDER BY TOTAL_REVENUE DESC
LIMIT 10;
