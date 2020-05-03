WITH addresses AS (
    SELECT DISTINCT substring(tr.input from 17 for 20) as addr
     FROM ethereum.transactions tx
     LEFT JOIN ethereum.traces tr ON tx."hash" = tr.tx_hash
     WHERE tx."to" = '\x851cc731ce1613ae4fd8ec7f61f4b350f9ce1020' -- Argent wallet creator

       AND substring(tx."data"::bytea
                     FROM 0
                     FOR 5) = '\xaff18575' -- createWallet() method

       AND substring(tr."input"::bytea
                     FROM 0
                     FOR 5) = '\x19ab453c' -- init() method
)

SELECT date_trunc('week', block_time) AS date_week, sum(1) as total_tx_count
FROM ethereum.traces
WHERE "from" IN (select addr from addresses)
 and block_number >= 7193539
-- and substring(input::bytea from 0 for 5) = '\xa9059cbb' -- transfer() event. Need to double check this logic
GROUP BY date_trunc('week', block_time)
order by date_trunc('week', block_time) asc