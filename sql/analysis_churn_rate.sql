use da_project_no1;
select *
from churns;
# churn rate analysis
create or replace view vw_subscription_churn_rate as
WITH RECURSIVE
    months AS (SELECT DATE('2023-01-01') AS month_date
               UNION ALL
               SELECT DATE_ADD(month_date, INTERVAL 1 MONTH)
               FROM months
               WHERE month_date < '2024-12-01'),
    monthly_metrics AS (SELECT m.month_date,
                               # subscriptions active at the start of the month
                               (SELECT COUNT(DISTINCT subscription_id)
                                FROM subscriptions
                                WHERE start_date < m.month_date
                                  AND (end_date IS NULL OR end_date >= m.month_date)
                                  and is_trial = 0) AS subs_at_start,
                               # subscriptions churned during the month
                               (SELECT COUNT(DISTINCT subscription_id)
                                FROM subscriptions
                                WHERE start_date < m.month_date
                                  and end_date >= m.month_date
                                  AND end_date < DATE_ADD(m.month_date, INTERVAL 1 MONTH)
                                  and is_trial = 0) AS churned_subs

                        FROM months m)
SELECT DATE_FORMAT(month_date, '%Y-%m')                          AS month,
       subs_at_start                                             AS subscriptions_at_month_start,
       churned_subs                                              AS churned_during_month,
       ROUND(churned_subs * 100.0 / NULLIF(subs_at_start, 0), 2) AS subscription_churn_rate
FROM monthly_metrics
ORDER BY month_date;

#select * from subscriptions;
