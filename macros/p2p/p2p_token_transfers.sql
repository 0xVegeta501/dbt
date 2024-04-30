{% macro p2p_token_transfers(chain) %}
    with 
        distinct_peer_address as (
            select address
            from {{ ref("dim_" ~ chain ~ "_eoa_addresses") }}
        ),
        {% if chain == "solana" %}
            token_prices as (
                select
                    recorded_hour::date as date,
                    token_address,
                    avg(close) as price
                from solana_flipside.price.ez_token_prices_hourly
                group by date, token_address
            ),
        {% endif %}
        transfers as (
            {% if chain == "tron" %}
                select 
                    block_timestamp,
                    block_number,
                    transaction_hash as tx_hash,
                    unique_id as index,
                    from_address,
                    to_address,
                    raw_amount as raw_amount_precise,
                    amount as amount_precise,
                    token_address,
                    usd_amount as amount_usd
                from tron_allium.assets.trc20_token_transfers
                where to_address != from_address 
                    and lower(to_address) != lower('TMerfyf1KwvKeszfVoLH3PEJH52fC2DENq')
                    and lower(from_address) != lower('TMerfyf1KwvKeszfVoLH3PEJH52fC2DENq')
            {% elif chain == "solana" %}
                select 
                    t2.block_timestamp,
                    t1.block_id as block_number,
                    t1.tx_id as tx_hash,
                    t1.index,
                    t1.tx_from as from_address,
                    t1.tx_to as to_address,
                    null as raw_amount_precise,
                    t1.amount as amount_precise,
                    mint as token_address,
                    coalesce(amount * price, 0) as amount_usd
                from solana_flipside.core.fact_transfers t1
                inner join solana_flipside.core.fact_blocks t2 using(block_id)
                left join token_prices t3 on t1.mint = t3.token_address and t2.block_timestamp::date = t3.date
                where mint <> 'So11111111111111111111111111111111111111112'
                    and t1.tx_from != t1.tx_to
                    and lower(t1.tx_from) != lower('1nc1nerator11111111111111111111111111111111') -- Burn address of solana
                    and lower(t1.tx_to) != lower('1nc1nerator11111111111111111111111111111111')
            {% else %}
                select 
                    block_timestamp,
                    block_number,
                    tx_hash,
                    event_index as index,
                    from_address,
                    to_address,
                    raw_amount_precise,
                    amount_precise,
                    contract_address as token_address,
                    amount_usd
                from {{ chain }}_flipside.core.ez_token_transfers
                where to_address != from_address 
                    and lower(from_address) != lower('0x0000000000000000000000000000000000000000')
                    and lower(to_address) != lower('0x0000000000000000000000000000000000000000')
            {% endif %}
            {% if is_incremental() %} 
                and block_timestamp >= (
                    select dateadd('day', -3, max(block_timestamp))
                    from {{ this }}
                )
            {% endif %}
        )

    select 
        t1.block_timestamp,
        t1.block_number,
        t1.tx_hash,
        t1.index,
        t1.token_address,
        t1.from_address,
        t1.to_address,
        t1.raw_amount_precise,
        t1.amount_precise,
        t1.amount_usd
    from transfers t1
    inner join distinct_peer_address t2 on lower(t1.to_address) = lower(t2.address)
    inner join distinct_peer_address t3 on lower(t1.from_address) = lower(t3.address)
    {% if is_incremental() %} 
        where block_timestamp >= (
            select dateadd('day', -3, max(block_timestamp))
            from {{ this }}
        )
    {% endif %}
{% endmacro %}
