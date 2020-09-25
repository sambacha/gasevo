# Embedded Volumetric Optionality Protocol

> Embedded Controllable Liquidity

## Note

Some additional sections are being added with language being changed.
<br>
#### TL:DR = EVO = MANIFOLDS

## [Read in Presentation Mode](https://hackmd.io/@freight/evoprotocol_spec)

## Abstract

We propose a crypto-derived functional asset in which controllable volumetric functions are embedded within the operational utility of the asset. 
As a result this function exhibits desirable properties as a _unit of account_ for its underlying asset. We propose as a first iteration **GasEVO**, an ethereum-based 'ERC-20 compliant' protocol in which _Gwei_, the computational unit of account for the Ethereum Blockchain, is provided in a sort of packaged derivative in which agents may use to position themselves from higher transactional volumes of the network at large
 (i.e. higher gwei pricing events, typically of 2-3 stddev).


## Transaction Inclusion as a Function of Time

 Liquidity and velocity, as a property of *indifference curves* (re: willingness) is a deterministic property for any transactional instrument and its market exchange rate.

> TL:DR: Intangible worth is hard to approximate or convey, unless it is _time_

## Utility

Given enough liquidity (assuming frequent transactions) GasEVO has a way to compute the `exchange rate` towards the base instrument (ETH). Like this, movements of the bigger or significant volumes can be interpreted as market trends (i.e. higher gwei pricing.)

By utilizing small volume movements and disincentivizing the larger ones without compensation to holders every exceeding unusual trade of the token is tracked by the smart contract and higher "interest" fees are applied (re: withdraw, or 'consumption').

Transference of funds _below_ daily volume threshold does not impose any interest fee.

When the threshold has been exceeded some percentage of tokens gets burned, for the transfer, for deposit or for withdraw of the base instrument (ETH).

Thresholds are tracked individually per address as the average rate and have a function by which they operate on.

---

<!-- @format -->

### Protocol Overview

EVO tokens are minted and burned **on-demand** by deposit and withdraw operations directly via the contract.

#### Initiated Protocol Operations

* Deposit
* Withdraw
* Transfer

These **operations** contribute to the *transfer rates*. Transfer rates are tracked both **in aggregate** and **individually** (i.e. *per address*). The *period* of time for tracking is the last `25 days`

> 25 days has `36000 minutes`, which *divided by* `block_time=4` gives `9000`

**GasEVO** is determined both in aggregate (dynamically) and individually for each address based on transactional (i.e. volumetric transactional information) stored and updated through the smart contract during the previous transactions. 


All three operations such as deposit, withdraw and transfer can equally contribute to the transfer rates that are tracked totally and individually(as per holder) by the smart contract for the period of the last 25 days.The token price is determined dynamically(and individually for each holder) based on the information stored or updated in the smart contract during previous transactions:


{equation.gasevo}

$$
P_{t+1}(h, a):=\sqrt{\frac{D_{t}}{S_{t}}}+I_{t+1}^{\prime}(h, a)
$$

## License 

MIT / AGPL
