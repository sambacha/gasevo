// from tor-q 
// for configuring for gwei usage, OHLC would ==
// open = block,0 
// close = block,0+x -- this is the period of the contract term 
// low == lowest transaction successfuly included during Open-Close **Note: these are transactions `submitted` during the period, not transactions that had the lowest fee and just happened to be included  
// high == highest transaction successfuly included during  Opening-Close 
ohlc:{[dict]
  allkeys:`date`sym`exchanges`quote`byexchange;
  typecheck[allkeys!14 11 11 11 1h;01000b;dict];

  // Set default null dict and default date input depending on whether HDB or RDB is target (this allows user to omit keys)
  defaultdate:$[`rdb in .proc.proctype; .proc.cd[]; last date];
  d:setdefaults[allkeys!(defaultdate;`;`;`ask`bid;0b);dict];

  // Create sym and exchange lists, bid and ask dicts for functional select
  biddict:`openBid`closeBid`bidHigh`bidLow!((first;`bid);(last;`bid);(max;`bid);(min;`bid));
  askdict:`openAsk`closeAsk`askHigh`askLow!((first;`ask);(last;`ask);(max;`ask);(min;`ask));

  // Save exchangeTime.date/date colname as variable based on proctype
  c:$[`rdb~.proc.proctype;`exchangeTime.date;`date];

  // Conditionals to form the ohlc column dict, where clause and by clause
  coldict:$[any i:`bid`ask in d`quote;(,/)(biddict;askdict) where i;(enlist`)!(enlist())];
  wherecl:`date`sym`exchanges!
    ((in;c;enlist d`date);(in;`sym;enlist d`sym);(in;`exchange;enlist d`exchanges));
  wherecl@:where[not all each null d]except `quote`byexchange;

  bycl:(`date`sym!c,`sym),$[d`byexchange;{x!x}enlist`exchange;()!()];

  // Perform query - (select coldict by date:exchangeTime.date,sym from t (where exchangeTime.date in d`date, sym in syms, exchange in exchanges))
  ?[exchange_top; wherecl; bycl; coldict]
 };

/ 
                                **** ORDER BOOK FUNCTION ****
  Returns level 2 orderbook at a specific point in time considering only quotes within the look-back window.
  Takes a dictionary as an argument. The only mandatory key is sym, the others will revert to defaults.
  Example usage:
  orderbook[`sym`timestamp`exchanges`window!(`BTCUSDT;2020.03.29D15:00:00;`finex`okex`zb;00:01:00)]  ->  Get `BTCUSDT orderbook with a lookback window of 1 minute 
\

orderbook:{[dict]
  allkeys:`timestamp`sym`exchanges`window;
  typecheck[allkeys!12 11 11 18h;0100b;dict];
  if[not(1=count dict`sym)and not any null dict`sym;errfunc[`orderbook;"Please enter one non-null sym."]];

  // Set default dict and default date input depending on whether HDB or RDB is target (this allows user to omit keys)
  defaulttime:$[`rdb in .proc.proctype;
    exec last exchangeTime from exchange;
    first exec exchangeTime from select last exchangeTime from exchange where date=last date];
  d:setdefaults[allkeys!(defaulttime;`;`;`second$2*.crypto.deffreq);dict];

  // Create extra key if on HDB and order dictionary by date
  if[`hdb~.proc.proctype;d:`date xcols update date:timestamp from d];

  // Edit where clause based on proctype
  // If proctype is HDB, add on date to where clause at the start,
  // then join on default clause, then pass in dictionary elements which are not null
  wherecl:()!();
  window:enlist d[`timestamp] -d[`window],1;
  if[`hdb~.proc.proctype;wherecl[`date]:(within;`date;`date$window)];
  wherecl,:`timestamp`sym`exchanges!(
    (within;`exchangeTime;window);
    (=;`sym;enlist d`sym);
    (in;`exchange;enlist d`exchanges));
  wherecl@:(where not all each null d) except `window;
  // Define book builder projected function
  book:{[wherecl;columns]ungroup columns#0!?[exchange;wherecl;{x!x}enlist`exchange;()]}wherecl;

  // Create bid and ask books and join to create order book
  bid:`exchange_b`bidSize`bid xcols `exchange_b xcol `bid xdesc book[`exchange`bid`bidSize];
  ask:`ask`askSize`exchange_a xcols `exchange_a xcol `ask xasc book[`exchange`ask`askSize];
  dt:abs(-/)c:count each tl:(bid;ask);
  :uj[(,'/)min[c]#/:tl;neg[dt]#tl first where max[c]=c]
 };

/
                                  **** TOP OF BOOK FUNCTION ****
  Returns top of book data on a per exchange basis at set buckets between two timestamps.
  Takes a dictionary as an argument. The only mandatory key is sym, the others will revert to defaults.
  Example usage:
  topofbook[`sym`exchanges`starttime`endtime!(`ETHUSDT;`zb`huobi;2020.03.29D15:00:00.;2020.03.29D15:05:00)] -> Top of book data for ETHUSDT across zb and huobi exchanges 
\

topofbook:{[dict]
  allkeys:`starttime`endtime`sym`exchanges`bucket;
  typecheck[allkeys!12 12 11 11 18h;00100b;dict];
  if[any 1 0<(count;sum)@\: null dict[`sym];errfunc[`topofbook;"Please enter one non-null sym."]];

  // Set defaults and sanitise input
  defaulttimes:$[`rdb~.proc.proctype;"p"$(.proc.cd[];.proc.cp[]);0 -1 + "p"$0 1 + last date];
  d:setdefaults[allkeys!raze(defaulttimes;`;`;`second$2*.crypto.deffreq);dict];
  d:@[d;`starttime`endtime`bucket;first];
  d[`bucket]:`long$d`bucket;

  // Create extra date key if proctype=HDB and order dictionary by date
  if[`hdb~.proc.proctype;d:`date xcols update date:distinct "d"$d`starttime`endtime from d];

  // Check that dates passed in are valid
  if[any (all .proc.cp[]<;>/)@\:d`starttime`endtime;errfunc[`topofbook;"Invalid start and end times."]];

  // If proctype=HDB, add date to beginning of where clause and join remaining dict args to where clause
  wherecl:$[`hdb~.proc.proctype;(enlist `date)!enlist(within;`date;enlist,"d"$d`starttime`endtime);()!()];
  wherecl[`starttime]:(within;`exchangeTime;enlist,d`starttime`endtime);
  wherecl[`sym]:(in;`sym;enlist d`sym);
  wherecl[`exchanges]:(in;`exchange;enlist d`exchanges);
  wherecl@:where not all each null `endtime`bucket _d;

  // Perform query - (select exchangeTime, exchange, bid, ask, bisSize, askSize from exchange_top where (wherecl))
  t:?[exchange_top;wherecl;0b;cls!cls:`exchangeTime`exchange`bid`ask`bidSize`askSize];

  // Get exchanges and use them to generate table names
  exchanges:exec distinct exchange from t;

  // If no data is available, return an empty table 
  if[0=count t;r:{(raze(`exchangeTime;`$string[x],/:("Bid";"Ask";"BidSize";"AskSize"))) xcol y}[;t] each d`exchanges;:$[98h~type r;r;(,'/)r]];

  // Creates a list of tables with the best bid and ask for each exchange
  exchangebook:{[x;y;z] 
    (`exchangeTime,`$string[x],/:("Bid";"Ask";"BidSize";"AskSize"))xcol 
    select bid:last bid,ask:last ask ,bidSize:last bidSize ,askSize:last askSize 
      by exchangeTime:(`date$exchangeTime)+z+z xbar exchangeTime.second 
      from y where exchange=x
   }[;t;d`bucket] each exchanges;

  // If more than one exchange, join together all datasets, reorder the columns and return result
  :0!`exchangeTime xasc (,'/) exchangebook;
 };

/
                                  **** TOP OF BOOK FUNCTION ****
  Returns top of book with additional profit and arbitrage columns.
  Takes a dictionary as an argument. The only mandatory key is sym, the others will revert to defaults.
  Example usage:
  arbitrage[`sym`exchanges`starttime`endtime!(`ETHUSDT;`zb`huobi;2020.03.29D15:00:00.;2020.03.29D15:05:00)] -> Top of book with arbitrage indicator for ETHUSDT across zb and huobi exchanges
\

arbitrage:{[d]
  // Generate topofbook table
  arbtable:topofbook[d];

  // If no data is available or only one non-null exchange is passed, update arbtable with profit and arbitrage as 0
  if[(0=count arbtable) or (5=count cols arbtable);:update profit:0,arbitrage:0 from arbtable];

  // Aggregate profit-column function - calculates profit to be made
  calprofit:{[b;bs;a;as]
    enlist({[b;bs;a;as]
      // Find best bid
      b:max@'l:(,'/)b;
      // Find best BidSize
      bs:@'[flip bs;where'[b=l]];
      // Find best ask
      a:min@'l:(,'/)a;
      // Find best AskSize
      as:@'[flip as;where'[a=l]];
      // Calculates profit
      p:min'[(bs,'as)]*b-a;
      ?[0>p;0;p]
     };
    // Enlists args to aggregate clause
    enlist,b;enlist,bs;enlist,a;enlist,as)
   };
 
  // Input columns for aggregate profit-col function
  cc:calprofit . getcols[arbtable;] each ("*Bid";"*BidSize";"*Ask";"*AskSize");

  // Perform query - (update arbitrage:profit>0 from (update profit:cc from arbtable))
  :update arbitrage:profit>0 from ![arbtable;();0b;enlist[`profit]!cc]
 };

/
                                    **** UTILITY FUNCTIONS ****
  errfunc[] Function for logging and signalling errors
  getcols[] gets columns from a table which match a particular pattern, ie. "*Bid"
  setdefaults[] produces a dictionary where missing values are filled in with defaults
  typecheck[] checks the types of dictionary values that are passed in by the user
\

errfunc:{.lg.e[x;"Crypto User Error:",y];'y};

getcols:{[table;word]col where(col:cols table)like word};

setdefaults:{[def;dict]def,(where not all each null dict)#dict};

typecheck:{[typedict;requiredkeylist;dict]
  // Checks the arguments are given in the correct form and the right keys are given
  if[not 99=type dict;errfunc[`typecheck;"The argument passed must be a dictionary."]];
  if[not all keyresult:key[dict] in key typedict;
    errfunc[`typecheck;"The following dictionary keys are incorrect: ",(", " sv string key[dict] where 0=keyresult),". The allowed keys are: ",", " sv string key typedict]];

  // Determine required keys and throw an error if any are missing
  requiredkeys:(key typedict) where requiredkeylist;
  if[not all requiredkeys in key dict;errfunc[`requiredkeys;"The following key(s) must be included: ",", " sv  string requiredkeys]];
 
  // Determine if arguments passed in are of the correct types
  typematch:typedict[key dict]=abs type each dict;
  if[not all typematch;
    errfunc[`typematch;"The dictionary parameter(s) ",(", "sv string where not typematch)," must be of type(s): ",", "sv string {key'[x$\:()]}typedict where not typematch]]
 };
Terms