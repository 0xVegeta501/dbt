{{
    config(
        materialized='table',
        snowflake_warehouse='TRADER_JOE'
    )
}}

with all_versions_metrics as (
    SELECT 
        date, 
        chain, 
        version,
        unique_traders,
        daily_txns,
        total_volume,
        total_fees,
        protocol_fees
    FROM {{ref('fact_trader_joe_v_2_1_metrics')}}

    UNION ALL

    SELECT 
        date, 
        chain,
        version,
        unique_traders,
        daily_txns,
        total_volume,
        total_fees,
        protocol_fees
    FROM {{ref('fact_trader_joe_v_2_2_metrics')}}
)
SELECT
    date,
    chain,
    version,
    sum(coalesce(unique_traders, 0)) as unique_traders,
    sum(coalesce(daily_txns, 0)) as number_of_swaps,
    sum(total_volume) as total_volume,
    sum(total_fees) as total_fees,
    sum(protocol_fees) as protocol_fees
FROM all_versions_metrics
GROUP BY 1, 2, 3
ORDER BY 1 DESC