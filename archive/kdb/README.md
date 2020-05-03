# Orderbook/Microstructure data: examining execution and transaction settlement 


### ETH Trading pair data

I have made a request to Kraken and some other exchanges on Iceberg orders, non-gtc orders (e.g. FOK), requesting that information is usually propreitary trade data. Doubtful will happen.

### SPY 4/21/2020 Trading OHLC Orderbook (Nasdaq format/routing)

> too lazy for git lfs, heres dropbox links

[SPY 4/21 CSV](https://www.dropbox.com/s/lqa48a1w7xzlxyn/20200421_SPY.csv?dl=0)
[SPY 4/21 i40 forrmat](https://www.dropbox.com/s/efduyary1lfy1kf/20200421_SPY.i40?dl=0)

Other data from Nomics, Dune Analytics (see snippets folder for sql queries)



<br>
# Setting up kdb+ 
<br>
A vanilla kdb+ installation consists of 3 files - q, q.k and kc.lic
q.k and kc.lic should both reside in the default directory $HOME/q
<br>
~/q$ tree <br>
.<br>
+-- kc.lic<br>
+-- l64<br>
|   +-- q<br>
+-- q.k<br>
1 directory, 3 files<br>
<br>
[kx.com setup instructions](https://code.kx.com/q/learn/install/)
<br>
technical paper from KX on ["Transaction-cost analysis using kdb+"](https://code.kx.com/q/wp/transaction-cost/)
<br>
<br>
Thanks to KX & First Derivatives for providing an (open) licensewners. Tradingphysics.org for the order tick data, and Hanne Johansson form Nasdaq for answering some questions on pro rata matching.