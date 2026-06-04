-- Analysis: Top Products by Revenue
-- UNNESTs the items array on purchase events to get product-level data
-- GA4 stores product details in items array, not in page_location
-- Answers: which products drive the most revenue?

select
    item.item_name                                          as product_name,
    item.item_category                                      as category,
    count(distinct user_pseudo_id)                          as purchasers,
    sum(item.quantity)                                      as units_sold,
    round(sum(item.price * item.quantity), 2)               as total_revenue,
    round(avg(item.price), 2)                               as avg_price
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
unnest(items) as item
where event_name = 'purchase'
group by 1, 2
order by total_revenue desc
limit 20