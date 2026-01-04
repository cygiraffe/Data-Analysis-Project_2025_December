# expansion_mrr_analysis
use da_project_no1;
# select * from subscriptions;


select *
from subscriptions;
# recursive month table
with recursive
    months as (select last_day('2023-01-01') as month
               union all
               select last_day(DATE_ADD(month, INTERVAL 1 MONTH))
               from months
               where month < DATE('2024-12-01')),
#select * from months;
    accounts_simple as (select account_id, country, referral_source
                        from accounts),
        months_accounts_combo AS (SELECT month, accounts_simple.*
                              FROM months
                                       CROSS JOIN accounts_simple),
    account_monthly_mrr AS (SELECT m.month,
                                   m.account_id,
                                   m.country,
                                   m.referral_source,

                                   COALESCE((SELECT SUM(s.mrr_amount)
                                             FROM subscriptions s
                                             WHERE s.account_id = m.account_id
                                               AND s.start_date <= m.month
                                               AND (s.end_date IS NULL OR s.end_date > m.month)
                                               AND s.is_trial = 0), 0) AS this_month_mrr

                            FROM months_accounts_combo m),
    with_lag AS (SELECT month,
                        account_id,
                        country,
                        referral_source,
                        this_month_mrr,
                        LAG(this_month_mrr) OVER (PARTITION BY account_id ORDER BY month) AS last_month_mrr
                 FROM account_monthly_mrr),
    expansion_mrr AS (SELECT month,
                             account_id,
                             country,
                             referral_source,
                             COALESCE(last_month_mrr, 0) AS prev_month_mrr,
                             this_month_mrr              AS current_month_mrr,

                             CASE
                                 WHEN COALESCE(last_month_mrr, 0) > 0
                                     AND this_month_mrr > COALESCE(last_month_mrr, 0)
                                     THEN this_month_mrr - COALESCE(last_month_mrr, 0)
                                 ELSE 0
                                 END                     AS expansion_mrr

                      FROM with_lag)
SELECT DATE_FORMAT(month, '%Y-%m') AS month,
       country,
       referral_source,
       SUM(prev_month_mrr)                                                                AS starting_mrr,
       SUM(expansion_mrr)                                                                 AS total_expansion_mrr,
       CONCAT(ROUND(SUM(expansion_mrr) * 100.0 / NULLIF(SUM(prev_month_mrr), 0), 2), '%') AS expansion_rate
FROM expansion_mrr
WHERE prev_month_mrr > 0
   OR current_month_mrr > 0
GROUP BY month, country, referral_source
ORDER BY month, country, referral_source;