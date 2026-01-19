/*
Net Revenue Retention (NRR) Analysis
Purpose: Measure revenue retention and expansion from existing customers
         using a 12-month cohort comparison at the account level

Output View:
  - vw_nrr: Monthly NRR showing cohort MRR, current MRR, and NRR rate

Key Metric Definition:
  - NRR = Current MRR from Cohort Accounts / Cohort Starting MRR (12 months ago)
  - Account-level: Multiple subscriptions per account are summed
  - 12-month lookback: Compares same accounts' revenue 1 year apart

What NRR Captures Automatically:
  - Expansion: Account upgraded or added seats → current_mrr > cohort_mrr
  - Contraction: Account downgraded → current_mrr < cohort_mrr
  - Churn: Account no longer active → current_mrr = 0 (because it is null)
  - New accounts: Excluded (only cohort accounts are tracked)
*/
use da_project_no1;
create or replace view vw_nrr as
    # VIEW: Net Revenue Retention (12-Month Cohort)
with recursive
    months as (select last_day('2024-01-01') as month_end
               union all
               select last_day(DATE_ADD(month_end, INTERVAL 1 MONTH))
               from months
               where month_end < DATE('2024-12-01')),
    /*
   COHORT IDENTIFICATION (mrr_past)
   For each month_end, find accounts that were active 12 months ago.
   This becomes our "cohort" - the denominator of NRR.

   CROSS JOIN creates every combination of month × subscription,
   then WHERE filters to only subscriptions active at cohort date.
   GROUP BY account_id aggregates multiple subscriptions per account.
   */
mrr_past as (
    select month_end, account_id, sum(mrr_amount) as cohort_mrr
    from months
    cross join subscriptions
    where start_date <= DATE_SUB(month_end, INTERVAL 12 MONTH) and (end_date is null or end_date >= DATE_SUB(month_end, INTERVAL 12 MONTH))
    group by 1,2
    having sum(mrr_amount)>0
    ),
    /*
    CURRENT STATE (mrr_current)
    For each month_end, calculate current MRR for all active accounts.
    This will be matched against the cohort to measure retention.

    Note: This includes ALL currently active accounts, not just cohort.
    The LEFT JOIN in final query handles the cohort filtering.
    */
mrr_current as (
    select month_end, account_id, sum(mrr_amount) as current_mrr
    from months
    cross join subscriptions
    where start_date <= month_end and (end_date is null or end_date >= month_end)
    group by 1,2
    having sum(mrr_amount)>0
    )
/*
FINAL NRR CALCULATION
LEFT JOIN Logic:
  - Base table (mrr_past): All cohort accounts from 12 months ago
  - Joined table (mrr_current): All accounts active at current month

  JOIN behavior ensures correct NRR calculation:
  - New customers (in current only) → Excluded from result
  - Churned accounts (in cohort only) → current_mrr = NULL, counted as 0 in SUM
*/
select mrr_past.month_end, sum(cohort_mrr) as cohort_mrr_final, sum(current_mrr) as current_mrr_final,
       round(sum(current_mrr)*1.0/sum(cohort_mrr),6) as nrr_rate
    from mrr_past
left join mrr_current
on mrr_past.month_end = mrr_current.month_end and mrr_past.account_id = mrr_current.account_id
group by 1
order by month_end;