SELECT
    date_trunc('month', block_time) as time,
    SUM(CASE WHEN data IS NULL THEN 1 ELSE 0 END) as eth_transfers,
    SUM(CASE WHEN substring(data from 1 for 4) = '\xa9059cbb' THEN 1 ELSE 0 END) as token_transfers,
    SUM(CASE WHEN data IS NOT NULL AND "to" IS NULL THEN 1 ELSE 0 END) as deploy_operations,
    SUM(CASE WHEN NOT(data IS NULL) AND NOT(substring(data from 1 for 4) = '\xa9059cbb') AND NOT(data IS NULL AND "to" IS NULL) THEN 1 ELSE 0 END) as other_operations
FROM ethereum."transactions"
GROUP BY 1
ORDER BY 1 DESC
