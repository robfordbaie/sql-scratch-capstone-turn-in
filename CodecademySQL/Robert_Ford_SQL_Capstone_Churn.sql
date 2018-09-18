SELECT MIN(subscription_start) AS first_sub,
   MAX(subscription_end) AS last_sub
FROM subscriptions;

SELECT DISTINCT(segment)
FROM subscriptions
ORDER BY segment;

WITH months AS (
  SELECT 
    '2017-01-01' AS first_day, 
    '2017-01-31' AS last_day 
  UNION 
  SELECT 
    '2017-02-01' AS first_day, 
    '2017-02-28' AS last_day 
  UNION 
  SELECT 
    '2017-03-01' AS first_day, 
    '2017-03-31' AS last_day
),
cross_join AS (
  SELECT *
  FROM subscriptions
  CROSS JOIN months
),
status AS (
  SELECT 
    id, 
    first_day AS month, 
    CASE
      WHEN subscription_start < first_day 
        AND (
          subscription_end > first_day 
          OR subscription_end IS NULL
        ) THEN 1
      ELSE 0
    END AS is_active,
    CASE
      WHEN subscription_end BETWEEN first_day AND last_day THEN 1
      ELSE 0
    END AS is_canceled,
    CASE
      WHEN (segment = 30 
            AND subscription_start < first_day 
            AND (
              subscription_end > first_day 
              OR subscription_end IS NULL)
            ) THEN 1
      ELSE 0
    END AS is_active_30, 
    CASE
      WHEN (segment = 30 
            AND subscription_end BETWEEN first_day AND last_day) THEN 1
      ELSE 0
    END AS is_canceled_30, 
    CASE
      WHEN (segment = 87 
            AND subscription_start < first_day 
            AND (
              subscription_end > first_day 
              OR subscription_end IS NULL)
            ) THEN 1
      ELSE 0
    END AS is_active_87, 
    CASE
      WHEN (segment = 87 
            AND subscription_end BETWEEN first_day AND last_day) THEN 1
      ELSE 0
    END AS is_canceled_87 
  FROM cross_join
),
status_aggregate AS (
  SELECT 
    month, 
    SUM(is_active) AS active, 
    SUM(is_canceled) AS canceled,
    SUM(is_active_30) AS active_30, 
    SUM(is_canceled_30) AS canceled_30,
    SUM(is_active_87) AS active_87, 
    SUM(is_canceled_87) AS canceled_87
  FROM status 
  GROUP BY month
)

SELECT
  month, 
  1.0 * canceled / active AS churn_rate,
  1.0 * canceled_30 / active_30 AS churn_rate_30,
  1.0 * canceled_87 / active_87 AS churn_rate_87
FROM status_aggregate;