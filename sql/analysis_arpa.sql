/*
ARPA (Average Revenue Per Account) Analysis
Purpose: Calculate Average Revenue Per Account to understand customer value
         segmented by industry and plan tier

Output Views:
  - vw_arpa_by_industry: ARPA trends across industries + Total
  - vw_arpa_by_tier: ARPA trends across Basic/Pro/Enterprise + Total

Key Metric Definition:
  - ARPA = Total MRR / Number of Active Accounts
  - Active account: Has at least one active subscription at month-end
  - One account can have multiple subscriptions (all MRR summed per account)
*/
use da_project_no1;
#arpa by industry
create or replace view vw_arpa_by_industry as
with recursive
    # Generate complete month series (Jan 2023 - Dec 2024)
    months as (select last_day('2023-01-01') as month_end
               union all
               select last_day(date_add(month_end, interval 1 month))
               from months
               where month_end <= '2024-11-30'),
#select * from months;
    industry_list as (select distinct industry
                      from accounts),
    # Create complete month × industry grid to ensure no gaps in time series
    month_industry_combo as (select m.month_end, i.industry
                             from months m
                                      cross join industry_list i),
    # add industry column to subscriptions table
    subscriptions_in_detail as (select subscriptions.*,
                                       accounts.industry
                                from subscriptions
                                         left join accounts on subscriptions.account_id = accounts.account_id),
    # Calculate MRR and unique active accounts per industry per month
    mrr_table as (select month_end
                       , m_i_combo.industry
                       , coalesce(sum(subscriptions_in_detail.mrr_amount), 0) as mrr_in_month,
                         count(distinct subscriptions_in_detail.account_id) as number_of_accounts
                  from month_industry_combo as m_i_combo
                           left join subscriptions_in_detail
                                     on start_date <= month_end and (end_date is null or end_date > month_end)
                                         and subscriptions_in_detail.industry = m_i_combo.industry
                  group by month_end, industry),
    # Calculate company-wide total MRR and unique active accounts per month
    mrr_total as (select month_end,
                         'Total'                                    as industry,
                         coalesce(sum(subscriptions.mrr_amount), 0) as mrr_in_month,
                         count(distinct subscriptions.account_id) as number_of_accounts
                  from months
                           left join subscriptions
                                     on start_date <= month_end and (end_date is null or end_date > month_end)
                  group by month_end)
# Final output: ARPA trends across industries + Total
select *,
       case
           when number_of_accounts > 0
               then round(mrr_in_month / number_of_accounts, 6)
           end as arpa
from mrr_table
union all
select *,
       case
           when number_of_accounts > 0
               then round(mrr_in_month / number_of_accounts, 6)
           end as arpa
from mrr_total
group by month_end, industry
order by industry, month_end;

###############################################################

select *
from subscriptions;
select *
from accounts;
# arpa by plan tier
create or replace view vw_arpa_by_tier as
with recursive
    months as (select last_day('2023-01-01') as month_end
               union all
               select last_day(date_add(month_end, interval 1 month))
               from months
               where month_end <= '2024-11-30'),
    plan_tier_list as (select distinct plan_tier
                       from subscriptions),
    month_plan_tier_combo as (select m.month_end, p.plan_tier
                              from months m
                                       cross join plan_tier_list p),
    mrr_table as (select month_end,
                         subscriptions.plan_tier,
                         coalesce(sum(subscriptions.mrr_amount), 0) as mrr_in_month,
                         count(distinct subscriptions.account_id) as number_of_accounts
                  from month_plan_tier_combo as m_t_combo
                           left join subscriptions
                                     on start_date <= month_end and (end_date is null or end_date
                                         > month_end)
                                         and subscriptions.plan_tier = m_t_combo.plan_tier
                  group by month_end, subscriptions.plan_tier),
    mrr_total as (select month_end,
                         'Total'                                    as plan_tier,
                         coalesce(sum(subscriptions.mrr_amount), 0) as mrr_in_month,
                         count(distinct subscriptions.account_id) as number_of_accounts
                  from months
                           left join subscriptions
                                     on start_date <= month_end and (end_date is null or end_date > month_end)
                  group by month_end)
select *,
       case
           when number_of_accounts > 0
               then round(mrr_in_month / number_of_accounts, 6)
           else 0
           end as arpa
from mrr_table
union all
select *,
       case
           when number_of_accounts > 0
               then round(mrr_in_month*1.0 / number_of_accounts, 6)
           else 0
           end as arpa
from mrr_total
order by plan_tier, month_end;