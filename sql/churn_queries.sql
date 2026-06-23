
-- ============================================================
-- Telecom Customer Churn Analytics — SQL Query Library
-- Author: Ujjawal Kumar
-- Dataset: IBM Telco Customer Churn (Kaggle)
-- Database: SQLite (data/telco.db)
-- ============================================================

-- Q1: Overall churn rate
SELECT 
    COUNT(*)                                    AS total_customers,
    SUM(Churn)                                  AS total_churned,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2)    AS churn_rate_pct
FROM customers;

-- Q2: Churn rate by contract type (strongest business signal)
SELECT 
    Contract,
    COUNT(*)                                    AS total_customers,
    SUM(Churn)                                  AS churned,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2)    AS churn_rate_pct
FROM customers
GROUP BY Contract
ORDER BY churn_rate_pct DESC;

-- Q3: Monthly revenue at risk from churned customers
SELECT 
    SUM(Churn)                              AS churned_customers,
    ROUND(AVG(MonthlyCharges), 2)           AS avg_monthly_charge,
    ROUND(SUM(MonthlyCharges), 2)           AS total_monthly_revenue_at_risk
FROM customers
WHERE Churn = 1;

-- Q4: Churn rate by tenure band (CASE WHEN bucketing)
SELECT 
    CASE 
        WHEN tenure BETWEEN 0  AND 12 THEN '1. First Year (0-12 months)'
        WHEN tenure BETWEEN 13 AND 24 THEN '2. Second Year (13-24 months)'
        WHEN tenure BETWEEN 25 AND 48 THEN '3. Years 2-4 (25-48 months)'
        ELSE                                '4. Loyal (49+ months)'
    END                                         AS tenure_band,
    COUNT(*)                                    AS customers,
    SUM(Churn)                                  AS churned,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2)    AS churn_rate_pct
FROM customers
GROUP BY tenure_band
ORDER BY tenure_band;

-- Q5: Senior vs Non-Senior churn comparison
SELECT
    CASE WHEN SeniorCitizen = 1 THEN 'Senior' 
         ELSE 'Non-Senior' 
    END                                         AS customer_type,
    COUNT(*)                                    AS customers,
    SUM(Churn)                                  AS churned,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2)    AS churn_rate_pct,
    ROUND(AVG(MonthlyCharges), 2)               AS avg_monthly_charge
FROM customers
GROUP BY SeniorCitizen
ORDER BY churn_rate_pct DESC;

-- Q6: Churn by payment method
SELECT
    PaymentMethod,
    COUNT(*)                                    AS customers,
    SUM(Churn)                                  AS churned,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2)    AS churn_rate_pct
FROM customers
GROUP BY PaymentMethod
ORDER BY churn_rate_pct DESC;

-- Q7: Top high-value churned customers for CRM targeting
SELECT
    customerID,
    tenure,
    Contract,
    ROUND(MonthlyCharges, 2)    AS monthly_charges,
    ROUND(TotalCharges, 2)      AS total_charges
FROM customers
WHERE Churn = 1
  AND MonthlyCharges > 70
  AND Contract = 'Month-to-month'
ORDER BY MonthlyCharges DESC
LIMIT 15;

-- Q8: Bundle effect — services count vs churn rate
SELECT
    (PhoneService + OnlineSecurity + OnlineBackup +
     DeviceProtection + TechSupport + 
     StreamingTV + StreamingMovies)             AS services_subscribed,
    COUNT(*)                                    AS customers,
    SUM(Churn)                                  AS churned,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2)    AS churn_rate_pct
FROM customers
GROUP BY services_subscribed
ORDER BY services_subscribed;

-- Q9: Window function — running churn total by tenure month
SELECT
    tenure,
    COUNT(*)                                        AS customers_at_tenure,
    SUM(Churn)                                      AS churned_at_tenure,
    SUM(SUM(Churn)) OVER (ORDER BY tenure)          AS running_total_churned,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2)        AS churn_rate_pct
FROM customers
GROUP BY tenure
ORDER BY tenure;

-- Q10: CTE — High-risk customer segment definition and sizing
WITH high_risk_customers AS (
    SELECT 
        customerID, tenure, MonthlyCharges, Contract, Churn
    FROM customers
    WHERE Contract      = 'Month-to-month'
      AND tenure        < 12
      AND MonthlyCharges > 65
)
SELECT
    COUNT(*)                                        AS high_risk_total,
    SUM(Churn)                                      AS already_churned,
    COUNT(*) - SUM(Churn)                          AS still_active_at_risk,
    ROUND(100.0 * SUM(Churn) / COUNT(*), 2)        AS churn_rate_pct,
    ROUND(AVG(MonthlyCharges), 2)                  AS avg_monthly_charge,
    ROUND(SUM(MonthlyCharges), 2)                  AS monthly_revenue_at_risk
FROM high_risk_customers;
