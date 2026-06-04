-- Staging model: flatten and clean raw GA4 events
-- Source: bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*
-- All downstream mart models reference this view, never the raw table
-- Key transformation: UNNEST event_params array to extract nested fields
-- Revenue fix: COALESCE double_value and int_value (GA4 stores both depending on amount)

with raw_events as (
    select
        event_date,
        event_timestamp,
        event_name,
        user_pseudo_id,

        -- traffic source fields (stored as STRUCT, access via dot notation)
        traffic_source.source         as source,
        traffic_source.medium         as medium,
        traffic_source.name           as campaign,

        -- session id (stored in event_params array, UNNEST to extract)
        (select value.int_value
         from unnest(event_params)
         where key = 'ga_session_id')  as session_id,

        -- page location
        (select value.string_value
         from unnest(event_params)
         where key = 'page_location')  as page_location,

        -- purchase revenue: COALESCE because GA4 stores whole numbers as int_value
        -- and decimals as double_value — both must be captured
        (select COALESCE(value.double_value, CAST(value.int_value AS FLOAT64))
         from unnest(event_params)
         where key = 'value')          as event_value,

        -- transaction id for purchase events
        (select value.string_value
         from unnest(event_params)
         where key = 'transaction_id') as transaction_id,

        -- geography and device
        geo.country                    as country,
        geo.city                       as city,
        device.category                as device_category,
        device.operating_system        as operating_system

    from {{ source('ga4', 'events_*') }}
)

select
    parse_date('%Y%m%d', event_date)            as event_date,
    timestamp_micros(event_timestamp)           as event_timestamp,
    event_name,
    user_pseudo_id,
    session_id,
    source,
    medium,
    campaign,
    page_location,
    event_value,
    transaction_id,
    country,
    city,
    device_category,
    operating_system
from raw_events