SELECT date_trunc('week', block_time), COUNT(*), SUM(r.charge) / 1e18 as total_fees
FROM gasstationnetwork."RelayHub_evt_TransactionRelayed" r
LEFT JOIN ethereum.transactions tx on r.evt_tx_hash = tx.hash
WHERE block_time > now() - interval '10 weeks'
GROUP BY 1
ORDER BY 1;