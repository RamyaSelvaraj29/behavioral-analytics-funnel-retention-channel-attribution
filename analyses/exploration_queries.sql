-- GA4 raw data exploration
-- Run sections 1 and 2 before building dbt models, section 3 after

-- SECTION 1: DATA VALIDATION

-- confirm data access and total rows (~4.3M expected)
SELECT COUNT(*) AS total_rows
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`;

-- check raw row structure  
SELECT *
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
LIMIT 1;

-- check how revenue is stored in event_params
SELECT
    ep.key,
    ep.value.string_value,
    ep.value.int_value,
    ep.value.float_value,
    ep.value.double_value
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
UNNEST(event_params) AS ep
WHERE event_name = 'purchase'
AND ep.key = 'value'
LIMIT 10;


-- SECTION 2: BUSINESS EXPLORATION
-- Core queries that inform the three dbt mart models

-- all 17 event types with counts - purchase should show ~5,692 events, ~4,419 unique users
SELECT
    event_name,
    COUNT(*) AS total_events,
    COUNT(DISTINCT user_pseudo_id) AS unique_users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
GROUP BY 1
ORDER BY 2 DESC;

-- six-stage funnel counts - visitors ~269K, purchasers ~4,419
SELECT
    COUNT(DISTINCT CASE WHEN event_name = 'page_view'        THEN user_pseudo_id END) AS visitors,
    COUNT(DISTINCT CASE WHEN event_name = 'view_item'        THEN user_pseudo_id END) AS product_viewers,
    COUNT(DISTINCT CASE WHEN event_name = 'add_to_cart'      THEN user_pseudo_id END) AS cart_adders,
    COUNT(DISTINCT CASE WHEN event_name = 'begin_checkout'   THEN user_pseudo_id END) AS checkout_starters,
    COUNT(DISTINCT CASE WHEN event_name = 'add_payment_info' THEN user_pseudo_id END) AS payment_adders,
    COUNT(DISTINCT CASE WHEN event_name = 'purchase'         THEN user_pseudo_id END) AS purchasers
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`;

-- daily traffic trend and conversion across 92 day period (Nov 2020- Jan 2021) 
-- Look for Black Friday and Christmas spikes
SELECT
    PARSE_DATE('%Y%m%d', event_date) AS date,
    COUNT(DISTINCT user_pseudo_id) AS daily_users,
    COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN user_pseudo_id END) AS daily_purchasers,
    ROUND(
        COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN user_pseudo_id END) * 100.0
        / NULLIF(COUNT(DISTINCT user_pseudo_id), 0),
    2) AS purchase_rate_pct
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
GROUP BY 1
ORDER BY 1;

-- channel conversion rates - channels with < 100 users excluded as statistically unreliable
---- Key finding: google/organic outperforms google/cpc on both conversion and LTV
SELECT
    traffic_source.source AS source,
    traffic_source.medium AS medium,
    COUNT(DISTINCT user_pseudo_id) AS total_users,
    COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN user_pseudo_id END) AS purchasers,
    ROUND(
        COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN user_pseudo_id END) * 100.0
        / NULLIF(COUNT(DISTINCT user_pseudo_id), 0),
    2) AS conversion_rate_pct
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
GROUP BY 1, 2
HAVING COUNT(DISTINCT user_pseudo_id) > 100
ORDER BY conversion_rate_pct DESC
LIMIT 20;


-- SECTION 3: MODEL VERIFICATION

-- stg_events: purchase rows should have revenue values (not null)
SELECT event_date, event_name, user_pseudo_id, event_value, transaction_id
FROM `ga4-analytics-491218.ga4_ecommerce.stg_events`
WHERE event_name = 'purchase'
LIMIT 5;

-- mart_funnel: must return 6 rows, purchase = 4,419
SELECT *
FROM `ga4-analytics-491218.ga4_ecommerce.mart_funnel`
ORDER BY stage_order;

-- mart_channel_performance: google/organic = 103,487 users, google/cpc = 15,527 users
SELECT *
FROM `ga4-analytics-491218.ga4_ecommerce.mart_channel_performance`
ORDER BY conversion_rate_pct DESC;

-- mart_cohort_retention: cohort_size must be constant per cohort, week 0 = 100%
-- Nov 1 cohort: week 1 retention should be ~6.31%
SELECT *
FROM `ga4-analytics-491218.ga4_ecommerce.mart_cohort_retention`
ORDER BY cohort_week, week_number
LIMIT 20;

-- mart_day_retention: Nov cohorts should show D7 ~12%, D30 ~16%
SELECT *
FROM `ga4-analytics-491218.ga4_ecommerce.mart_day_retention`
ORDER BY cohort_week;

-- mart_daily_trend: Nov 1 should show daily_users = 2,365, purchase_rate_pct = 0.55
SELECT *
FROM `ga4-analytics-491218.ga4_ecommerce.mart_daily_trend`
ORDER BY event_date
LIMIT 10;