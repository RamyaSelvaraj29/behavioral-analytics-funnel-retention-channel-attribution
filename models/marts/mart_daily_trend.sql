-- Mart model: daily traffic and conversion trend
-- Powers the time series line chart on Looker Studio Page 1
-- Shows day-over-day purchase rate across the 92-day period

select
    event_date,
    count(distinct user_pseudo_id)                              as daily_users,
    count(distinct case when event_name = 'purchase'
        then user_pseudo_id end)                                as daily_purchasers,
    round(
        count(distinct case when event_name = 'purchase'
            then user_pseudo_id end) * 100.0
        / nullif(count(distinct user_pseudo_id), 0),
    2)                                                          as purchase_rate_pct
from {{ ref('stg_events') }}
group by 1
order by 1