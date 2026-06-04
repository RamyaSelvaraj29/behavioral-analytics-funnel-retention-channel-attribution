-- Mart model: purchase funnel analysis
-- Counts unique users who completed each of the 6 funnel stages
-- Ground truth to verify against: purchasers must equal 4,419
-- Each stage counts DISTINCT users — a user who viewed 10 products counts once

select 'page_view' as stage, 1 as stage_order,
    count(distinct user_pseudo_id) as unique_users
from {{ ref('stg_events') }}
where event_name = 'page_view'

union all

select 'view_item', 2,
    count(distinct user_pseudo_id)
from {{ ref('stg_events') }}
where event_name = 'view_item'

union all

select 'add_to_cart', 3,
    count(distinct user_pseudo_id)
from {{ ref('stg_events') }}
where event_name = 'add_to_cart'

union all

select 'begin_checkout', 4,
    count(distinct user_pseudo_id)
from {{ ref('stg_events') }}
where event_name = 'begin_checkout'

union all

select 'add_payment_info', 5,
    count(distinct user_pseudo_id)
from {{ ref('stg_events') }}
where event_name = 'add_payment_info'

union all

select 'purchase', 6,
    count(distinct user_pseudo_id)
from {{ ref('stg_events') }}
where event_name = 'purchase'