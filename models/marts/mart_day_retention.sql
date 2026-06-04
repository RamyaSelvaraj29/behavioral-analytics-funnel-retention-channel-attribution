-- Mart model: day-level retention (D7, D30, D60)
-- Calculates what % of each weekly cohort returned by day 7, 30, and 60
-- Complements the weekly cohort heatmap with specific retention milestones

with first_visit as (
    select
        user_pseudo_id,
        min(event_date)                         as first_visit_date,
        date_trunc(min(event_date), week)       as cohort_week
    from {{ ref('stg_events') }}
    group by user_pseudo_id
),

user_activity as (
    select
        user_pseudo_id,
        event_date
    from {{ ref('stg_events') }}
    group by user_pseudo_id, event_date
)

select
    f.cohort_week,
    count(distinct f.user_pseudo_id)                                        as cohort_size,

    count(distinct case
        when date_diff(u.event_date, f.first_visit_date, day) between 1 and 7
        then u.user_pseudo_id end)                                          as d7_users,

    count(distinct case
        when date_diff(u.event_date, f.first_visit_date, day) between 1 and 30
        then u.user_pseudo_id end)                                          as d30_users,

    count(distinct case
        when date_diff(u.event_date, f.first_visit_date, day) between 1 and 60
        then u.user_pseudo_id end)                                          as d60_users,

    round(count(distinct case
        when date_diff(u.event_date, f.first_visit_date, day) between 1 and 7
        then u.user_pseudo_id end) * 100.0
        / nullif(count(distinct f.user_pseudo_id), 0), 2)                  as d7_retention_pct,

    round(count(distinct case
        when date_diff(u.event_date, f.first_visit_date, day) between 1 and 30
        then u.user_pseudo_id end) * 100.0
        / nullif(count(distinct f.user_pseudo_id), 0), 2)                  as d30_retention_pct,

    round(count(distinct case
        when date_diff(u.event_date, f.first_visit_date, day) between 1 and 60
        then u.user_pseudo_id end) * 100.0
        / nullif(count(distinct f.user_pseudo_id), 0), 2)                  as d60_retention_pct

from first_visit f
left join user_activity u
    on f.user_pseudo_id = u.user_pseudo_id
group by 1
order by 1