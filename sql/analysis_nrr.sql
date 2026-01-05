use da_project_no1;
select * from subscriptions;
create or replace view vw_nrr as
with recursive
    months as (select last_day('2024-01-01') as month_end
               union all
               select last_day(DATE_ADD(month_end, INTERVAL 1 MONTH))
               from months
               where month_end < DATE('2024-12-01')),
mrr_past as (
    select month_end, account_id, sum(mrr_amount) as cohort_mrr
    from months
    cross join subscriptions
    where start_date <= DATE_SUB(month_end, INTERVAL 12 MONTH) and (end_date is null or end_date >= DATE_SUB(month_end, INTERVAL 12 MONTH))
    group by 1,2
    having sum(mrr_amount)>0
    ),
mrr_current as (
    select month_end, account_id, sum(mrr_amount) as current_mrr
    from months
    cross join subscriptions
    where start_date <= month_end and (end_date is null or end_date >= month_end)
    group by 1,2
    having sum(mrr_amount)>0
    )
select mrr_past.month_end, sum(cohort_mrr) as cohort_mrr_final, sum(coalesce(current_mrr,0)) as current_mrr_final,
       case when
                sum(coalesce(cohort_mrr,0)) !=0 then concat(round(sum(current_mrr)*100/sum(cohort_mrr),2),'%')
                else null end as nrr_rate
    from mrr_past
left join mrr_current
on mrr_past.month_end = mrr_current.month_end and mrr_past.account_id = mrr_current.account_id
group by 1
order by month_end;