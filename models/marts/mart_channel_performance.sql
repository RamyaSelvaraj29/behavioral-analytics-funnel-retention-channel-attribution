-- Mart model: channel performance analysis
-- Groups users by traffic source and medium
-- Calculates conversion rate per channel
-- Ground truth: google/organic = 103,487 users, 1,229 purchasers
-- Ground truth: google/cpc = 15,527 users, 152 purchasers
-- HAVING filter removes channels with < 100 users (statistically unreliable)

select
    source,
    medium,
    count(distinct user_pseudo_id)                                          as total_users,

    count(distinct case when event_name = 'purchase'
        then user_pseudo_id end)                                            as purchasers,

    round(
        count(distinct case when event_name = 'purchase'
            then user_pseudo_id end) * 100.0
        / nullif(count(distinct user_pseudo_id), 0),
    2)                                                                      as conversion_rate_pct,

    sum(case when event_name = 'purchase'
        then event_value else 0 end)                                        as total_revenue

from {{ ref('stg_events') }}
group by 1, 2
having count(distinct user_pseudo_id) > 100
order by conversion_rate_pct desc