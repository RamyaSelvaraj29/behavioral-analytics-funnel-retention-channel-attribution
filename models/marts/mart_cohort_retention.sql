-- Mart model: weekly cohort retention
-- cohort_size calculated separately so it stays constant across all week_numbers
-- Uses ON instead of USING to properly distinguish cohort users from returning users

with first_visit as (
    select
        user_pseudo_id,
        date_trunc(min(event_date), week)       as cohort_week
    from {{ ref('stg_events') }}
    group by user_pseudo_id
),

cohort_sizes as (
    select
        cohort_week,
        count(distinct user_pseudo_id)          as cohort_size
    from first_visit
    group by cohort_week
),

activity as (
    select
        user_pseudo_id,
        date_trunc(event_date, week)            as activity_week
    from {{ ref('stg_events') }}
    group by user_pseudo_id, date_trunc(event_date, week)
),

cohort_activity as (
    select
        f.cohort_week,
        date_diff(a.activity_week, f.cohort_week, week)     as week_number,
        count(distinct a.user_pseudo_id)                     as retained_users
    from first_visit f
    left join activity a
        on f.user_pseudo_id = a.user_pseudo_id
    group by 1, 2
)

select
    ca.cohort_week,
    ca.week_number,
    cs.cohort_size,
    ca.retained_users,
    round(
        ca.retained_users * 100.0
        / nullif(cs.cohort_size, 0),
    2)                                                       as retention_rate_pct
from cohort_activity ca
join cohort_sizes cs
    on ca.cohort_week = cs.cohort_week
order by 1, 2