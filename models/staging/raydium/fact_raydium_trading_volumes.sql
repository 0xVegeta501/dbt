{{
    config(
        materialized="incremental",
        unique_key="date",
        snowflake_warehouse="RAYDIUM",
    )
}}


{{fact_solana_trading_metrics('raydium')}}