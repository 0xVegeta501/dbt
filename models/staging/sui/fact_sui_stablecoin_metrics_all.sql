{{
    config(
        materialized="table",
        unique_key="unique_id",
        snowflake_warehouse="STABLECOIN_V2_LG_2",
    )
}}


{{stablecoin_metrics_all("sui")}}