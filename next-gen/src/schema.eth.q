// schema for defitions table from "d" msgs, quote table, trade table 
\d .schema

definitions:([] 
 TradeDate:`date$();
 TransactionSettlementTime:`timestamp$();
 ContractEventIndicator:`byte$();
 TransactionUpdateAction:`$();
 ChainID:`int$();
 Unit:`$();
// 4ByteID:`int$(); Convert 4byte into int, source from https://github.com/sambacha/ethereum-4bytes-all/blob/master/4bytes.json
 TokenURI:`$();
 TokenType:`$();
 UnderlyingProduct:`int$(); 
 UnderlyingProduct:`int$(); // 
 ProductExchange:`$(); // e.g. Loopring, IDEX, OkEx, etc 
 Currency:`$(); // Base Currency  , NOTE: WETH != ETH 
 MarketDepth:`int$(); // CounterParty Amount
 DisplayFactor:`float$()); // Open Interest
 BlockTime: `timestamp$(); // this needs to be reflective of the period, e.g. 4 blocks = 1 minute 

quote:([] 
 TradeDate:`date$();
 MsgSeqNum:`int$();
 TransactTime:`timestamp$();
 MatchEventIndicator:`byte$();
 MDUpdateAction:`$();
 MDEntryType:`$();
 SecurityID:`int$();
 Symbol:`$();
 RptSeq:`int$();
 MDEntryPx:`float$();
 MDEntrySize:`float$();
 NumberOfOrders:`int$();
 MDPriceLevel:`int$();
 SecurityDesc:`$());

trade:([] 
 TradeDate:`date$();
 MsgSeqNum:`int$();
 TransactTime:`timestamp$();
 MatchEventIndicator:`byte$();
 MDUpdateAction:`$();
 SecurityID:`int$();
 Symbol:`$();
 RptSeq:`int$();
 MDEntryPx:`float$();
 MDEntrySize:`float$();
 NumberOfOrders:`int$();
 AggressorSide:`$();
 SecurityDesc:`$());

status:([] 
 MsgSeqNum:`int$();
 TransactTime:`timestamp$();
 TradingDate:`date$();
 MatchEventIndicator:`byte$();
 SecurityGroup:`$();
 SecurityTradingStatus:`$();
 HaltReasonChar:`$();
 SecurityTradingEvent:`$());

init:{[] 
 .raw.definitions:.schema.definitions;
 .raw.quote:.schema.quote;
 .raw.trade:.schema.trade;
 .raw.status:.schema.status;
 }

savetype:(!) . flip (
  `.raw.quote`partitioned;
  `.raw.trade`partitioned;
  `.raw.definitions`splay;
  `.raw.status`splay
 );

/ field mappings for user-friendly trade table
trfieldmaps:(!) . flip (
  `date`TradeDate;
  `time`TransactTime;
  (`sym;(^;`SecurityDesc;`Symbol)); / fill null Symbol with SecurityDesc field
  `price`MDEntryPx;
  `size`MDEntrySize;
  `orders`NumberOfOrders;
  `side`AggressorSide;
  `msgseq`MsgSeqNum;
  `rptseq`RptSeq;
  `matchevent`MatchEventIndicator
 );

/ field mappings for user-friendly quote/book table
qtfieldmaps:(!) . flip (
  `date`TradeDate;
  `time`TransactTime;
  `sym`Symbol;
  `bprice`bprice;
  `bsize`bsize;
  `aprice`aprice;
  `asize`asize;
  `msgseq`MsgSeqNum;
  `rptseq`RptSeq;
  `matchevent`MatchEventIndicator
 );