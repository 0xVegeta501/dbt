{{
    config(
        materialized="incremental",
        unique_key=["address", "chain", "source"],
        incremental_strategy="merge",
    )
}}

