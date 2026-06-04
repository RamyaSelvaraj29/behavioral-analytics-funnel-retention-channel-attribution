-- Analysis: Weekly Active Users (WAU)
-- Tracks unique active users per week across the 92-day period
-- Answers: how did site traffic trend week over week?
-- DA insight: WAU is a core product health metric used by every growth team

select
    date_trunc(event_date, week)                            as week_start,
    count(distinct user_pseudo_id)                          as weekly_active_users,
    count(distinct case when event_name = 'purchase'
        then user_pseudo_id end)                            as weekly_purchasers,
    round(count(distinct case when event_name = 'purchase'
        then user_pseudo_id end) * 100.0
        / nullif(count(distinct user_pseudo_id), 0), 2)     as weekly_conversion_pct
from `ga4-analytics-491218.ga4_ecommerce.stg_events`
group by 1
order by 1