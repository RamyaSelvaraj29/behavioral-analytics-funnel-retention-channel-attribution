-- Analysis: Channel LTV Comparison
-- Compares average revenue per purchaser across traffic channels
-- Answers: which channel brings the highest-value customers, not just the most?
-- DA insight: a channel with lower conversion but higher LTV may still be worth investing in

select
    source,
    medium,
    count(distinct user_pseudo_id)                          as total_users,
    count(distinct case when event_name = 'purchase'
        then user_pseudo_id end)                            as purchasers,
    round(sum(case when event_name = 'purchase'
        then event_value else 0 end), 2)                    as total_revenue,
    round(sum(case when event_name = 'purchase'
        then event_value else 0 end)
        / nullif(count(distinct case when event_name = 'purchase'
        then user_pseudo_id end), 0), 2)                    as avg_revenue_per_purchaser
from `ga4-analytics-491218.ga4_ecommerce.stg_events`
group by 1, 2
having count(distinct user_pseudo_id) > 100
order by avg_revenue_per_purchaser desc