/*
Expansion & Contraction MRR Analysis
Purpose: Calculate revenue growth/decline from existing customers
         to measure account-level expansion and contraction trends

Output View:
  - vw_expansion_mrr_rate: Monthly expansion/contraction MRR with rates
    segmented by country and referral_source

Key Metric Definitions:
  - Expansion MRR: Revenue increase from existing paying customers
    (prev_mrr > 0 AND current_mrr > prev_mrr)
  - Contraction MRR: Revenue decrease from still-active customers
    (prev_mrr > 0 AND current_mrr > 0 AND current_mrr < prev_mrr)
  - Expansion Rate: Total Expansion MRR / Starting MRR
  - Contraction Rate: Total Contraction MRR / Starting MRR

Critical Design Decisions:
  - Account-level tracking (not subscription-level) because one account can have multiple subscriptions
  - CROSS JOIN ensures complete time series for accurate LAG() calculation
  - Excludes trials (is_trial = 0) to focus on paying customers only

Classification Logic:
  | prev_mrr | current_mrr | Classification              |
  |----------|-------------|------------------------------|
  | > 0      | increased   | Expansion                    |
  | > 0      | decreased   | Contraction (if current > 0) |
  | > 0      | 0           | Churn (excluded from both)   |
  | 0        | > 0         | New/Reactivation (excluded)  |
*/

use da_project_no1;
# recursive month table
create or replace view vw_expansion_mrr_rate as
# Generate complete month series (Jan 2023 - Dec 2024) using month-end dates
with recursive
    months as (select last_day('2023-01-01') as month
               union all
               select last_day(DATE_ADD(month, INTERVAL 1 MONTH))
               from months
               where month < DATE('2024-12-01')),
# Extract only needed columns from accounts for joining
    accounts_simple as (select account_id, country, referral_source
                        from accounts),
# CROSS JOIN: Create all (month × account) combinations
# This ensures every account has a row for every month, even months with no subscription
# Critical for LAG() to correctly reference "immediate previous month".
    months_accounts_combo AS (SELECT month, accounts_simple.*
                              FROM months
                                       CROSS JOIN accounts_simple),
# Calculate each account's MRR at each month-end
# COALESCE converts NULL (no subscription) to 0, making churned months explicit
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
# LAG() retrieves previous month's MRR for each account
# This enables month-over-month comparison
    with_lag AS (SELECT month,
                        account_id,
                        country,
                        referral_source,
                        this_month_mrr,
                        LAG(this_month_mrr) OVER (PARTITION BY account_id ORDER BY month) AS last_month_mrr
                 FROM account_monthly_mrr),
# Classify each account-month as Expansion, Contraction, or neither
    expansion_mrr_table AS (SELECT month,
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
                                       END                     AS expansion_mrr,
                                   CASE
                                       WHEN COALESCE(last_month_mrr, 0) > 0 AND
                                            this_month_mrr > 0 and
                                            this_month_mrr < COALESCE(last_month_mrr, 0)
                                           THEN COALESCE(last_month_mrr, 0) - this_month_mrr
                                       ELSE 0
                                       END                     AS contraction_mrr
                            FROM with_lag),
    # Aggregation Level 1: By segment (country × referral_source)
    by_segment as (SELECT month,
                          country,
                          referral_source,
                          SUM(prev_month_mrr)                                                   AS starting_mrr,
                          SUM(expansion_mrr)                                                    AS total_expansion_mrr,
                          sum(contraction_mrr)                                                  AS total_contraction_mrr,
                          ROUND(SUM(expansion_mrr) * 1.0 / NULLIF(SUM(prev_month_mrr), 0), 6)   AS expansion_rate,
                          ROUND(SUM(contraction_mrr) * 1.0 / NULLIF(SUM(prev_month_mrr), 0), 6) AS contraction_rate,
                          'segment'                                                             as agg_level
                   FROM expansion_mrr_table
                   WHERE prev_month_mrr > 0
                      OR current_month_mrr > 0
                   GROUP BY month, country, referral_source),
    # Aggregation Level 2: Company-wide total
    segment_total as (SELECT month,
                             'total'                                                               as country,
                             'total'                                                               as referral_source,
                             SUM(prev_month_mrr)                                                   AS starting_mrr,
                             SUM(expansion_mrr)                                                    AS total_expansion_mrr,
                             sum(contraction_mrr)                                                  AS total_contraction_mrr,
                             ROUND(SUM(expansion_mrr) * 1.0 / NULLIF(SUM(prev_month_mrr), 0), 6)   AS expansion_rate,
                             ROUND(SUM(contraction_mrr) * 1.0 / NULLIF(SUM(prev_month_mrr), 0), 6) AS contraction_rate,
                             'total'                                                               as agg_level
                      FROM expansion_mrr_table
                      WHERE prev_month_mrr > 0
                         OR current_month_mrr > 0
                      GROUP BY month),
    # Aggregation Level 3: By country only (all referral sources combined)
    by_country as (SELECT month,
                             country,
                             'all'                                                               as referral_source,
                             SUM(prev_month_mrr)                                                   AS starting_mrr,
                             SUM(expansion_mrr)                                                    AS total_expansion_mrr,
                             sum(contraction_mrr)                                                  AS total_contraction_mrr,
                             ROUND(SUM(expansion_mrr) * 1.0 / NULLIF(SUM(prev_month_mrr), 0), 6)   AS expansion_rate,
                             ROUND(SUM(contraction_mrr) * 1.0 / NULLIF(SUM(prev_month_mrr), 0), 6) AS contraction_rate,
                             'by_country'                                                               as agg_level
                      FROM expansion_mrr_table
                      WHERE prev_month_mrr > 0
                         OR current_month_mrr > 0
                      GROUP BY month, country)
# Combine all aggregation levels for flexible filtering in Power BI
select * from by_segment
union all
select * from segment_total
union all
select * from by_country
order by month, country, referral_source;
