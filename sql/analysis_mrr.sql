use da_project_no1;
#select * from churns where reason='unknown';
# select * from accounts;
select *
from subscriptions;
# mrr, mrr growth 계산
select *
from churns;
select *
from da_project_no1.subscriptions;
#mrr growth by industry
CREATE OR REPLACE VIEW vw_mrr_growth_by_industry AS
with recursive
    months as (select last_day('2023-01-01') as month_end
               union all
               select last_day(date_add(month_end, interval 1 month))
               from months
               where month_end <= '2024-11-30'),
#select * from months;
    industry_list as (select distinct industry
                      from accounts),
    month_industry_combo as (select m.month_end, i.industry
                             from months m
                                      cross join industry_list i),
    subscriptions_in_detail as (select subscriptions.*,
                                       accounts.industry
                                from subscriptions
                                         left join accounts on subscriptions.account_id = accounts.account_id),
    mrr_table as (select month_end
                       , m_i_combo.industry
                       , coalesce(sum(subscriptions_in_detail.mrr_amount), 0) as mrr_in_month
                  from month_industry_combo as m_i_combo
                           left join subscriptions_in_detail
                                     on start_date <= month_end and (end_date is null or end_date > month_end)
                                         and subscriptions_in_detail.industry = m_i_combo.industry
                  group by month_end, industry),
    mrr_total as (select month_end,
                         'Total'                                    as industry,
                         coalesce(sum(subscriptions.mrr_amount), 0) as mrr_in_month
                  from months
                           left join subscriptions
                                     on start_date <= month_end and (end_date is null or end_date > month_end)
                  group by month_end)
select month_end,
       industry,
       mrr_in_month,
       lag(mrr_in_month) over (partition by industry order by month_end) as prev_mrr_in_month,
       case
           when lag(mrr_in_month) over (partition by industry order by month_end) = 0 then 'N/A'
           else
               round(((mrr_table.mrr_in_month -
                       lag(mrr_in_month) over (partition by industry order by month_end)) /
                      lag(mrr_in_month) over (partition by industry order by month_end)) * 100,
                     2) end                                              as mrr_change_rate
from mrr_table
union all
select month_end,
       industry,
       mrr_in_month,
       lag(mrr_in_month) over (order by month_end)                   as prev_mrr_in_month,
       round(((mrr_in_month - lag(mrr_in_month) over (order by month_end)) /
              lag(mrr_in_month) over (order by month_end)) * 100, 2) as mrr_change_rate
from mrr_total
order by industry, month_end;



select *
from subscriptions;
select *
from accounts;
# mrr growth by plan tier
CREATE OR REPLACE VIEW vw_mrr_growth_by_tier AS
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
                         coalesce(sum(subscriptions.mrr_amount), 0) as mrr_in_month
                  from month_plan_tier_combo as m_t_combo
                           left join subscriptions
                                     on start_date <= month_end and (end_date is null or end_date
                                         > month_end)
                                         and subscriptions.plan_tier = m_t_combo.plan_tier
                  group by month_end, subscriptions.plan_tier),
    mrr_total as (select month_end,
                         'Total'                                    as plan_tier,
                         coalesce(sum(subscriptions.mrr_amount), 0) as mrr_in_month
                  from months
                           left join subscriptions
                                     on start_date <= month_end and (end_date is null or end_date > month_end)
                  group by month_end)
select month_end,
       mrr_table.plan_tier,
       mrr_in_month,
       lag(mrr_in_month) over (partition by plan_tier order by month_end) as prev_mrr_in_month,
       case
           when lag(mrr_in_month) over (partition by plan_tier order by month_end) = 0 then 'N/A'
           else round(((mrr_table.mrr_in_month -
                        lag(mrr_in_month) over (partition by plan_tier order by month_end)) /
                       lag(mrr_in_month) over (partition by plan_tier order by month_end)) * 100,
                      2) end                                              as mrr_change_rate
from mrr_table
union all
select month_end,
       plan_tier,
       mrr_in_month,
       lag(mrr_in_month) over (order by month_end)                   as prev_mrr_in_month,
       round(((mrr_in_month - lag(mrr_in_month) over (order by month_end)) /
              lag(mrr_in_month) over (order by month_end)) * 100, 2) as mrr_change_rate
from mrr_total
order by plan_tier, month_end;