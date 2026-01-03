use da_project_no1;
#select * from churns where reason='unknown';
# mrr, mrr growth 계산
select * from churns;
select * from da_project_no1.subscriptions;
#mrr growth by industry
with recursive months as (
    select last_day('2023-01-01') as month_end
    union all
    select last_day(date_add(month_end,interval 1 month))
    from months
    where month_end <= '2024-11-30'
),
#select * from months;
mrr_table as (
    select month_end, industry
   , sum(subscriptions.mrr_amount) as mrr_in_month
    from months
    left
    join subscriptions
    on start_date <= month_end and (end_date is null or end_date > month_end)
    left
    join accounts
    on accounts.account_id = subscriptions.account_id
    group
    by month_end,industry
    ),
mrr_total as (
        select month_end, 'Total' as industry,
        sum(subscriptions.mrr_amount) as mrr_in_month
        from months
        left join subscriptions
        on start_date <= month_end and (end_date is null or end_date > month_end)
        group by month_end
               )
select month_end,
       industry,
       mrr_in_month,
       lag(mrr_in_month) over (partition by industry order by month_end) as prev_mrr_in_month,
       concat(round(((mrr_table.mrr_in_month-lag(mrr_in_month) over (partition by industry order by month_end))/lag(mrr_in_month) over (partition by industry order by month_end))*100,2),'%') as mrr_change_rate
from mrr_table
union all
select month_end, industry, mrr_in_month,
       lag(mrr_in_month) over (order by month_end) as prev_mrr_in_month,
       concat(round(((mrr_in_month - lag(mrr_in_month) over (order by month_end)) /
                     lag(mrr_in_month) over (order by month_end)) * 100, 2), '%') as mrr_change_rate
from mrr_total
order by industry, month_end;




select * from subscriptions;
select * from accounts;
# mrr growth by plan tier
with recursive months as (
    select last_day('2023-01-01') as month_end
    union all
    select last_day(date_add(month_end,interval 1 month))
    from months
    where month_end <= '2024-11-30'
),
mrr_table as (
    select month_end,
           subscriptions.plan_tier,
           sum(subscriptions.mrr_amount) as mrr_in_month
    from months
    left
    join subscriptions
    on start_date <= month_end and (end_date is null or end_date
            > month_end)
    group
    by month_end, subscriptions.plan_tier
               ),
mrr_total as (
    select month_end, 'Total' as plan_tier,
    sum(subscriptions.mrr_amount) as mrr_in_month
    from months
    left join subscriptions
    on start_date <= month_end and (end_date is null or end_date > month_end)
    group by month_end
               )
select month_end,
       mrr_table.plan_tier,
       mrr_in_month,
       lag(mrr_in_month) over (partition by plan_tier order by month_end) as prev_mrr_in_month,
       concat(round(((mrr_table.mrr_in_month-lag(mrr_in_month) over (partition by plan_tier order by month_end))/lag(mrr_in_month) over (partition by plan_tier order by month_end))*100,2),'%') as mrr_change_rate
from mrr_table
union all
select month_end, plan_tier, mrr_in_month,
       lag(mrr_in_month) over (order by month_end) as prev_mrr_in_month,
       concat(round(((mrr_in_month - lag(mrr_in_month) over (order by month_end)) /
                     lag(mrr_in_month) over (order by month_end)) * 100, 2), '%') as mrr_change_rate
from mrr_total
order by plan_tier, month_end;