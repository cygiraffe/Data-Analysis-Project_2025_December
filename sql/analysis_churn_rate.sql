/*
Subscription Churn Rate Analysis
Purpose: Calculate monthly subscription churn rate to measure customer retention
         at the subscription level (not account level)

Output View:
  - vw_subscription_churn_rate: Monthly churn rate time series

Key Metric Definition:
  - Churn Rate = Churned Subscriptions during the period(month) / Subscriptions at Period Start
  - Subscription-level: Each subscription counted independently
                        (one account can have multiple subscriptions)
  - Trial exclusion: [is_trial = 1] subscriptions excluded from calculation
  - "Joined & churned" exclusion: Subscriptions starting within the period
                                  are automatically excluded via start_date < period_start

Data Limitation:
  Standard churn calculations also exclude "churned & reactivated" subscriptions.
  However, this dataset creates new subscription_ids for reactivations with no
  linkage to original subscriptions, making same-period reactivation tracking
  impossible. This is a SIMPLIFIED churn rate as a result.
*/
use da_project_no1;
select *
from churns;
# churn rate analysis
create or replace view vw_subscription_churn_rate as
WITH RECURSIVE
    # Generate month series using period start dates (Jan 2023 - Dec 2024)
    months AS (SELECT DATE('2023-01-01') AS month_date
               UNION ALL
               SELECT DATE_ADD(month_date, INTERVAL 1 MONTH)
               FROM months
               WHERE month_date < '2024-12-01'),
    # Calculate subscription counts using correlated subqueries
    monthly_metrics AS (SELECT m.month_date,
                               # subscriptions active at the start of the month
                               (SELECT COUNT(DISTINCT subscription_id)
                                FROM subscriptions
                                WHERE start_date < m.month_date
                                  AND (end_date IS NULL OR end_date >= m.month_date)
                                  and is_trial = 0) AS subs_at_start,
                               # subscriptions churned during the month
                               # Started before period (existing customers) AND ended within period
                               (SELECT COUNT(DISTINCT subscription_id)
                                FROM subscriptions
                                WHERE start_date < m.month_date
                                  and end_date >= m.month_date
                                  AND end_date < DATE_ADD(m.month_date, INTERVAL 1 MONTH)
                                  and is_trial = 0) AS churned_subs

                        FROM months m)
# Final output: Monthly churn rate as decimal
SELECT DATE_FORMAT(month_date, '%Y-%m')                          AS month,
       subs_at_start                                             AS subscriptions_at_month_start,
       churned_subs                                              AS churned_during_month,
       ROUND(churned_subs * 1.0 / NULLIF(subs_at_start, 0), 6) AS subscription_churn_rate
FROM monthly_metrics
ORDER BY month_date;

#select * from subscriptions;
