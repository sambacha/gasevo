# ⛽️ GasEVO 

!! Warning 
	no audit has been done, do not use

#### Embeded Volumetric Options on Ethereum Gas Pricing 

> see this repo for more documentation: ~/archive/


## Overview
- Contracts Denominated in wei
- Underlying Asset is GasTokenV2
- Margin Funding Rate [MFR] is Paid to the originating options party 
-  a % of the [MFR] is fed into protocol pool 
-  Ability to take delivery (buy gastoken at price spf.)
-  Or cash-settled [yUSD] (yUSD using 'best of' or 'denominated')
-  [yUSD] = Ability to accept multiple stablecoins to fund position
-  Benchmark Index created by us
-  Oracle Created by us 
-  % of fees retained go to Oracle Insurance Fund (mutual assurance guarantee model)

# Instrument Design

### Baseline
```javascript
[Open/Close],[block_expiry],[increment_tick_lbo],[strike_threashold_inverse_saddle],[yUSD(MFR)]
```
### 🎯 Example
```javascript
[1/5],[1000],[0.05],[0.05%],[0.025%]
```
* Where the increment per tick limit buy order is .05 cents meaning they can only bid on contracts in increments of 5 cents

* Where yUSD is the settlement funding pool in which arb. fees are collected as calculated by: "best off - worst off"

* Where strike threashold inverse saddle is the range from contract purchase price where no margin is collected, this is a 'stability fee'

* stability fee is used to rebate instrument creation



## Contract Example

User_1 buys Option for 50 gwei which is underwritten by User_2

### ⛽️ GasEvo Contract Calculation 

```
% of last 200 blocks accpeting this gas price: 79.3103448276
Mean Time to Confirm (Blocks):	5
Transaction fee (ETH): 0.0095353
Transaction fee (yUSD Fiat): $2.04055
```



## MarginRate [marginRatePerBlock]

GasTokenV2 / pEther

`function marginRatePerBlock() returns (uint)`

`RETURN` : The current margin rate as an unsigned integer, scaled by 1e18.



## goTokens Mint [goTokens]
When you supply GasTokenV2 to GasEVO, goTokens are minted. The number of goTokens minted is the amount of underlying asset being provided divided by the current Exchange Rate.

`function mint(uint mintAmount) returns (uint)`

msg.sender - The account which supplies the asset and owns the goTokens.

mintAmount - The amount supplied, in units of the underlying asset.

RETURN - 0 on success, otherwise an Error Code.

## Options Strike [exerciseContract]
The strike function transfers the underlying asset from the money market to the user in exchange for previously minted goTokens. The amount of underlying physical settlement (i.e. exercised for gastokenv2) is the number of goTokens multiplied by the current Exchange Rate. The amount exercised as specified in the `ContractPurchaseBlockTime` must be less than the user's Account Liquidity and the market's available liquidity.

`function exercise(uint exerciseContract) returns (uint)
msg.sender`

- The account to which exercised funds shall be transferred.

exerciseContract - The number of goTokens to be exercised.

RETURN - 0 on success, otherwise an Error Code.

---

TODO:
Integrate Oracle 
Integrate Escrow Pool Contract
Integrate yUSD via Curve
Silo contract expiry into distinct "markets"
testing 
v1 w/o inverse saddle trigger


🚧 