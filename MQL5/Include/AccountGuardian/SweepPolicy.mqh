//+------------------------------------------------------------------+
//| AccountGuardian - SweepPolicy.mqh                                |
//| The sweep engine's POLICY, separated from its trade calls.       |
//| Owner ruling ENF-24(b) of 2026-09-16, plan                       |
//| docs/PLAN_ENFORCEMENT_SWEEP_2026-09-16.md section 3 and the      |
//| ruling sheet ENF-1 to ENF-29 recorded FINAL in LEDGER DECISIONS. |
//|                                                                  |
//| EVERYTHING IN THIS FILE IS A PURE FUNCTION OF ITS ARGUMENTS OR A |
//| COMPILE-TIME CONSTANT. No platform read, no clock, no global     |
//| that a trade call touches, no include of Sweep.mqh, and NO TRADE |
//| API OF ANY KIND: this file never builds a request, never sends   |
//| one, and never names the sending family the static-structure    |
//| rule (SPEC 1) confines to Sweep.mqh. Static row ENF-S2 greps it  |
//| clean of that family on every build, and static row ENF-S6      |
//| greps it clean of every clock.                                   |
//|                                                                  |
//| WHY IT EXISTS AS ITS OWN FILE: the vectors script includes this  |
//| file and NOT Sweep.mqh, so the retcode classes, the backoff     |
//| schedule, the ordering, the flat predicate, the Q3 names and the |
//| journal line shapes are all proven by AgPhase2StateVectors       |
//| before any live row runs (ENF-0), while the vectors ex5 links no |
//| trade API at all. That is the ruling C precedent of 2026-08-18   |
//| applied a third time.                                            |
//+------------------------------------------------------------------+
#ifndef AG_SWEEP_POLICY_MQH
#define AG_SWEEP_POLICY_MQH

//+------------------------------------------------------------------+
//| CONSTANTS, owner ruling ENF-25(a): compile-time constants and    |
//| never inputs, the AG_LIFE_INTERVAL and AG_MUTEX_STALE precedent  |
//| of 2026-07-29 ("a value able to disable a guarantee is core or   |
//| nowhere"). Every unit below is TIMER PASSES, never seconds       |
//| (ENF-10(a), a pass counter and no clock): one pass is one timer  |
//| tick, 1 s under D7b's AG_SWEEP_PERIOD_SECONDS, so the figures    |
//| read as seconds on a live timer and hold under a frozen quote.   |
//+------------------------------------------------------------------+
//--- ENF-11(a): the hard count H per ticket for the retry class. At H
//--- the ticket is held with one ALERT naming it, the cadence line
//--- thereafter, the CANNOT_FLATTEN sub-condition on the banner, and a
//--- re-arm when the retcode class changes or every AG_SWEEP_REARM_PASSES.
#define AG_SWEEP_HARD_STOP           10
//--- ENF-9(c): the retry class doubles 1, 2, 4, 8, 16, 32 and is capped
//--- here; the hold class consumes no attempts until its condition changes.
#define AG_SWEEP_BACKOFF_CAP_PASSES  60
//--- ENF-11(a): a held ticket is re-armed for one attempt every this many
//--- passes when its class has not changed.
#define AG_SWEEP_REARM_PASSES        60
//--- The cadence of the sweep held and sweep blocked journal lines,
//--- equal to AG_LIFE_INTERVAL_SECONDS (30 s) at the 1 s timer. Defined
//--- here in passes because this file carries no clock and the EA's
//--- AG_LIFE_INTERVAL_SECONDS is defined after the includes.
#define AG_SWEEP_CADENCE_PASSES      30
//--- ENF-19(a): the magic every guardian request carries, so DEAL_MAGIC
//--- and the terminal journal attribute every guardian close. The value
//--- is the ruling date of the enforcement phase as a decimal, which no
//--- other advisor on this account is known to use and which a reader of
//--- DEAL_MAGIC can trace to the LEDGER DECISIONS entry of that date.
#define AG_SWEEP_MAGIC               20260916
//--- ENF-19(a): the comment on every guardian request.
#define AG_SWEEP_COMMENT             "AG sweep"
//--- ENF-6(a): deviation in points, a compile-time constant. Under market
//--- execution the field is ignored (plan 2.7.5); under instant execution
//--- 100 points lets a close fill through a move of a full point on
//--- XAUUSD.ecn or a full index point on US100.ecn between quote and fill,
//--- which is what a flatten engine wants, and a requote beyond it is
//--- retry class and bounded by the schedule.
#define AG_SWEEP_DEVIATION_POINTS    100

//+------------------------------------------------------------------+
//| RETCODE CLASSES, plan 2.7.4, owner rulings ENF-9(c), ENF-11(a),  |
//| ENF-12(a), ENF-13(c). DONE covers a completed request and a      |
//| position that another route closed first (10036). PARTIAL 10010  |
//| is RETRY with a flag the caller reads through AgRetcodeIsPartial |
//| (ENF-12(a): it resets the attempt counter). PLACED 10008 is the  |
//| asynchronous acknowledgement and is neither a success nor a      |
//| failure. An unknown retcode is REFUSE, the class that stops the  |
//| ticket, because resending a request whose failure the guardian   |
//| cannot classify is the order storm SPEC 7 forbids; a refused     |
//| ticket is still re-armed at AG_SWEEP_REARM_PASSES, so nothing is |
//| ever abandoned for good.                                         |
//+------------------------------------------------------------------+
#define AG_RC_DONE    0
#define AG_RC_RETRY   1
#define AG_RC_HOLD    2
#define AG_RC_REFUSE  3
#define AG_RC_PLACED  4

int AgRetcodeClass(const uint retcode)
  {
   switch(retcode)
     {
      //--- successes
      case TRADE_RETCODE_DONE:                return AG_RC_DONE;
      case TRADE_RETCODE_POSITION_CLOSED:     return AG_RC_DONE;
      //--- the asynchronous acknowledgement, neither success nor failure
      case TRADE_RETCODE_PLACED:              return AG_RC_PLACED;
      //--- retry class: transient, the same request may succeed later
      case TRADE_RETCODE_REQUOTE:             return AG_RC_RETRY;
      case TRADE_RETCODE_REJECT:              return AG_RC_RETRY;
      case TRADE_RETCODE_DONE_PARTIAL:        return AG_RC_RETRY;
      case TRADE_RETCODE_ERROR:               return AG_RC_RETRY;
      case TRADE_RETCODE_TIMEOUT:             return AG_RC_RETRY;
      case TRADE_RETCODE_PRICE_CHANGED:       return AG_RC_RETRY;
      case TRADE_RETCODE_PRICE_OFF:           return AG_RC_RETRY;
      case TRADE_RETCODE_TOO_MANY_REQUESTS:   return AG_RC_RETRY;
      case TRADE_RETCODE_LOCKED:              return AG_RC_RETRY;
      case TRADE_RETCODE_FROZEN:              return AG_RC_RETRY;
      case TRADE_RETCODE_CONNECTION:          return AG_RC_RETRY;
      case TRADE_RETCODE_CLOSE_ORDER_EXIST:   return AG_RC_RETRY;
      //--- hold class: the condition will not change by retrying, the Q3
      //--- states in retcode form; the sweep re-arms when it changes
      case TRADE_RETCODE_TRADE_DISABLED:      return AG_RC_HOLD;
      case TRADE_RETCODE_MARKET_CLOSED:       return AG_RC_HOLD;
      case TRADE_RETCODE_SERVER_DISABLES_AT:  return AG_RC_HOLD;
      case TRADE_RETCODE_CLIENT_DISABLES_AT:  return AG_RC_HOLD;
      case TRADE_RETCODE_ONLY_REAL:           return AG_RC_HOLD;
      case TRADE_RETCODE_LONG_ONLY:           return AG_RC_HOLD;
      case TRADE_RETCODE_SHORT_ONLY:          return AG_RC_HOLD;
      case TRADE_RETCODE_CLOSE_ONLY:          return AG_RC_HOLD;
      case TRADE_RETCODE_HEDGE_PROHIBITED:    return AG_RC_HOLD;
      //--- refuse class: the request itself is wrong, a resend is a storm
      case TRADE_RETCODE_CANCEL:              return AG_RC_REFUSE;
      case TRADE_RETCODE_INVALID:             return AG_RC_REFUSE;
      case TRADE_RETCODE_INVALID_VOLUME:      return AG_RC_REFUSE;
      case TRADE_RETCODE_INVALID_PRICE:       return AG_RC_REFUSE;
      case TRADE_RETCODE_INVALID_STOPS:       return AG_RC_REFUSE;
      case TRADE_RETCODE_NO_MONEY:            return AG_RC_REFUSE;
      case TRADE_RETCODE_INVALID_EXPIRATION:  return AG_RC_REFUSE;
      case TRADE_RETCODE_ORDER_CHANGED:       return AG_RC_REFUSE;
      case TRADE_RETCODE_NO_CHANGES:          return AG_RC_REFUSE;
      case TRADE_RETCODE_INVALID_FILL:        return AG_RC_REFUSE;
      case TRADE_RETCODE_LIMIT_ORDERS:        return AG_RC_REFUSE;
      case TRADE_RETCODE_LIMIT_VOLUME:        return AG_RC_REFUSE;
      case TRADE_RETCODE_INVALID_ORDER:       return AG_RC_REFUSE;
      case TRADE_RETCODE_INVALID_CLOSE_VOLUME: return AG_RC_REFUSE;
      case TRADE_RETCODE_LIMIT_POSITIONS:     return AG_RC_REFUSE;
      case TRADE_RETCODE_REJECT_CANCEL:       return AG_RC_REFUSE;
      case TRADE_RETCODE_FIFO_CLOSE:          return AG_RC_REFUSE;
     }
   //--- retcode 0: the terminal did not accept the request for sending at
   //--- all (a client side error such as trade context busy), so no server
   //--- answered; transient and bounded by the schedule like any retry.
   if(retcode == 0)
      return AG_RC_RETRY;
   return AG_RC_REFUSE;
  }

//--- ENF-12(a): the one retry class member the caller treats specially.
bool AgRetcodeIsPartial(const uint retcode)
  {
   return retcode == TRADE_RETCODE_DONE_PARTIAL;
  }

string AgRetcodeClassName(const int cls)
  {
   switch(cls)
     {
      case AG_RC_DONE:   return "done";
      case AG_RC_RETRY:  return "retry";
      case AG_RC_HOLD:   return "hold";
      case AG_RC_REFUSE: return "refuse";
      case AG_RC_PLACED: return "placed";
     }
   return "unknown";
  }

//--- The retcode's own name, for the held reason and the journal. Every
//--- constant the classifier names is named here too, so a reader of a
//--- sweep line never has to look a number up.
string AgRetcodeName(const uint retcode)
  {
   switch(retcode)
     {
      case TRADE_RETCODE_REQUOTE:             return "REQUOTE";
      case TRADE_RETCODE_REJECT:              return "REJECT";
      case TRADE_RETCODE_CANCEL:              return "CANCEL";
      case TRADE_RETCODE_PLACED:              return "PLACED";
      case TRADE_RETCODE_DONE:                return "DONE";
      case TRADE_RETCODE_DONE_PARTIAL:        return "DONE_PARTIAL";
      case TRADE_RETCODE_ERROR:               return "ERROR";
      case TRADE_RETCODE_TIMEOUT:             return "TIMEOUT";
      case TRADE_RETCODE_INVALID:             return "INVALID";
      case TRADE_RETCODE_INVALID_VOLUME:      return "INVALID_VOLUME";
      case TRADE_RETCODE_INVALID_PRICE:       return "INVALID_PRICE";
      case TRADE_RETCODE_INVALID_STOPS:       return "INVALID_STOPS";
      case TRADE_RETCODE_TRADE_DISABLED:      return "TRADE_DISABLED";
      case TRADE_RETCODE_MARKET_CLOSED:       return "MARKET_CLOSED";
      case TRADE_RETCODE_NO_MONEY:            return "NO_MONEY";
      case TRADE_RETCODE_PRICE_CHANGED:       return "PRICE_CHANGED";
      case TRADE_RETCODE_PRICE_OFF:           return "PRICE_OFF";
      case TRADE_RETCODE_INVALID_EXPIRATION:  return "INVALID_EXPIRATION";
      case TRADE_RETCODE_ORDER_CHANGED:       return "ORDER_CHANGED";
      case TRADE_RETCODE_TOO_MANY_REQUESTS:   return "TOO_MANY_REQUESTS";
      case TRADE_RETCODE_NO_CHANGES:          return "NO_CHANGES";
      case TRADE_RETCODE_SERVER_DISABLES_AT:  return "SERVER_DISABLES_AT";
      case TRADE_RETCODE_CLIENT_DISABLES_AT:  return "CLIENT_DISABLES_AT";
      case TRADE_RETCODE_LOCKED:              return "LOCKED";
      case TRADE_RETCODE_FROZEN:              return "FROZEN";
      case TRADE_RETCODE_INVALID_FILL:        return "INVALID_FILL";
      case TRADE_RETCODE_CONNECTION:          return "CONNECTION";
      case TRADE_RETCODE_ONLY_REAL:           return "ONLY_REAL";
      case TRADE_RETCODE_LIMIT_ORDERS:        return "LIMIT_ORDERS";
      case TRADE_RETCODE_LIMIT_VOLUME:        return "LIMIT_VOLUME";
      case TRADE_RETCODE_INVALID_ORDER:       return "INVALID_ORDER";
      case TRADE_RETCODE_POSITION_CLOSED:     return "POSITION_CLOSED";
      case TRADE_RETCODE_INVALID_CLOSE_VOLUME: return "INVALID_CLOSE_VOLUME";
      case TRADE_RETCODE_CLOSE_ORDER_EXIST:   return "CLOSE_ORDER_EXIST";
      case TRADE_RETCODE_LIMIT_POSITIONS:     return "LIMIT_POSITIONS";
      case TRADE_RETCODE_REJECT_CANCEL:       return "REJECT_CANCEL";
      case TRADE_RETCODE_LONG_ONLY:           return "LONG_ONLY";
      case TRADE_RETCODE_SHORT_ONLY:          return "SHORT_ONLY";
      case TRADE_RETCODE_CLOSE_ONLY:          return "CLOSE_ONLY";
      case TRADE_RETCODE_FIFO_CLOSE:          return "FIFO_CLOSE";
      case TRADE_RETCODE_HEDGE_PROHIBITED:    return "HEDGE_PROHIBITED";
     }
   if(retcode == 0)
      return "NOT_SENT";
   return "UNKNOWN_" + (string)retcode;
  }

//+------------------------------------------------------------------+
//| THE BACKOFF SCHEDULE, ENF-9(c) and ENF-10(a). attempt is the      |
//| number of retry class attempts already made on the ticket, 1     |
//| after the first; the return is how many PASSES to wait before    |
//| the next: 1, 2, 4, 8, 16, 32, then the cap. A non positive       |
//| attempt count waits one pass.                                    |
//+------------------------------------------------------------------+
int AgBackoffPasses(const int attempt)
  {
   if(attempt <= 0)
      return 1;
   int wait = 1;
   for(int i = 1; i < attempt; i++)
     {
      wait *= 2;
      if(wait >= AG_SWEEP_BACKOFF_CAP_PASSES)
         return AG_SWEEP_BACKOFF_CAP_PASSES;
     }
   return wait;
  }

//+------------------------------------------------------------------+
//| THE ORDERING AMONG POSITIONS, ENF-7(a): most negative floating   |
//| first, so the largest bleed is stopped first; ties by ticket     |
//| ascending, so the order is deterministic. Negative when a sorts  |
//| before b, positive when b sorts before a, zero when equal.       |
//+------------------------------------------------------------------+
int AgSweepPositionCompare(const double floating_a, const ulong ticket_a,
                           const double floating_b, const ulong ticket_b)
  {
   if(floating_a < floating_b)
      return -1;
   if(floating_a > floating_b)
      return 1;
   if(ticket_a < ticket_b)
      return -1;
   if(ticket_a > ticket_b)
      return 1;
   return 0;
  }

//+------------------------------------------------------------------+
//| THE FLAT PREDICATE on one pass's counts. ENF-16(b) is applied by |
//| the caller across two consecutive passes that sent nothing; this |
//| is the one pass half of it.                                      |
//+------------------------------------------------------------------+
bool AgSweepFlat(const int positions, const int pendings)
  {
   return positions == 0 && pendings == 0;
  }

//+------------------------------------------------------------------+
//| PENDING ORDER TYPES, plan 2.7.3. A market order in flight, the   |
//| sweep's own close among them, appears in the same list as       |
//| ORDER_TYPE_BUY or ORDER_TYPE_SELL and is never a pending.         |
//+------------------------------------------------------------------+
bool AgIsPendingType(const int type)
  {
   return type == ORDER_TYPE_BUY_LIMIT || type == ORDER_TYPE_SELL_LIMIT
       || type == ORDER_TYPE_BUY_STOP  || type == ORDER_TYPE_SELL_STOP
       || type == ORDER_TYPE_BUY_STOP_LIMIT || type == ORDER_TYPE_SELL_STOP_LIMIT;
  }

string AgPendingTypeName(const int type)
  {
   switch(type)
     {
      case ORDER_TYPE_BUY_LIMIT:       return "buy_limit";
      case ORDER_TYPE_SELL_LIMIT:      return "sell_limit";
      case ORDER_TYPE_BUY_STOP:        return "buy_stop";
      case ORDER_TYPE_SELL_STOP:       return "sell_stop";
      case ORDER_TYPE_BUY_STOP_LIMIT:  return "buy_stop_limit";
      case ORDER_TYPE_SELL_STOP_LIMIT: return "sell_stop_limit";
     }
   return "type_" + (string)type;
  }

string AgPositionTypeName(const int type)
  {
   return (type == POSITION_TYPE_BUY) ? "buy" : "sell";
  }

//+------------------------------------------------------------------+
//| THE FILLING MODE, ENF-6(a): per symbol from SYMBOL_FILLING_MODE, |
//| a flag set; FOK when allowed, else IOC, else RETURN. Pure on the |
//| flags so the vectors prove all three branches.                   |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING AgSweepFillingFor(const long filling_flags)
  {
   if((filling_flags & SYMBOL_FILLING_FOK) != 0)
      return ORDER_FILLING_FOK;
   if((filling_flags & SYMBOL_FILLING_IOC) != 0)
      return ORDER_FILLING_IOC;
   return ORDER_FILLING_RETURN;
  }

//+------------------------------------------------------------------+
//| THE Q3 NAMES, owner ruling Q3/F2 of 2026-07-29 and ENF-15(a).    |
//| Account wide: the first blocking state in the ruled order, named |
//| exactly as the journal names it, or "" when nothing blocks.      |
//| Per symbol: SYMBOL_TRADE_MODE named distinctly, with CLOSEONLY   |
//| SENDABLE (ENF-15(a)): the platform accepts a close on such a     |
//| symbol, so the state is logged and the close is sent. DISABLED   |
//| is the one mode that holds; LONGONLY and SHORTONLY are sent and  |
//| the retcode tells the truth (ENF-13(c)).                         |
//+------------------------------------------------------------------+
string AgTradeBlockName(const bool terminal_trade_allowed, const bool mql_trade_allowed,
                        const bool account_trade_allowed, const bool account_trade_expert)
  {
   if(!terminal_trade_allowed)
      return "TERMINAL_TRADE_ALLOWED=false";
   if(!mql_trade_allowed)
      return "MQL_TRADE_ALLOWED=false";
   if(!account_trade_allowed)
      return "ACCOUNT_TRADE_ALLOWED=false";
   if(!account_trade_expert)
      return "ACCOUNT_TRADE_EXPERT=false";
   return "";
  }

string AgSymbolTradeModeName(const long trade_mode)
  {
   switch((int)trade_mode)
     {
      case SYMBOL_TRADE_MODE_DISABLED:  return "SYMBOL_TRADE_MODE_DISABLED";
      case SYMBOL_TRADE_MODE_LONGONLY:  return "SYMBOL_TRADE_MODE_LONGONLY";
      case SYMBOL_TRADE_MODE_SHORTONLY: return "SYMBOL_TRADE_MODE_SHORTONLY";
      case SYMBOL_TRADE_MODE_CLOSEONLY: return "SYMBOL_TRADE_MODE_CLOSEONLY";
      case SYMBOL_TRADE_MODE_FULL:      return "SYMBOL_TRADE_MODE_FULL";
     }
   return "SYMBOL_TRADE_MODE_" + (string)trade_mode;
  }

bool AgSymbolTradeModeSendable(const long trade_mode)
  {
   return trade_mode != SYMBOL_TRADE_MODE_DISABLED;
  }

//+------------------------------------------------------------------+
//| THE JOURNAL LINES, plan 3.5, field names exact. Pure formatters, |
//| so the vectors assert every shape on fixed arguments before a    |
//| live row ever produces one. Every stamp arrives as a string the  |
//| caller rendered, since this file reads no clock.                 |
//+------------------------------------------------------------------+
string AgSweepPassLine(const int positions, const int pendings, const int held, const int sent)
  {
   return "sweep pass|positions=" + (string)positions + "|pendings=" + (string)pendings
        + "|held=" + (string)held + "|sent=" + (string)sent;
  }

string AgSweepDeleteLine(const ulong order, const string symbol, const string type,
                         const uint retcode, const int cls, const int attempt)
  {
   return "sweep delete|order=" + (string)order + "|symbol=" + symbol + "|type=" + type
        + "|retcode=" + (string)retcode + "|class=" + AgRetcodeClassName(cls)
        + "|attempt=" + (string)attempt;
  }

string AgSweepCloseLine(const ulong position, const string symbol, const string type,
                        const double volume, const double floating, const uint retcode,
                        const int cls, const int attempt, const double filled)
  {
   return "sweep close|position=" + (string)position + "|symbol=" + symbol + "|type=" + type
        + "|volume=" + DoubleToString(volume, 2) + "|floating=" + DoubleToString(floating, 2)
        + "|retcode=" + (string)retcode + "|class=" + AgRetcodeClassName(cls)
        + "|attempt=" + (string)attempt + "|filled=" + DoubleToString(filled, 2);
  }

//--- kind is "position" or "order", the same key the close and delete lines use.
string AgSweepHeldLine(const string kind, const ulong ticket, const string symbol,
                       const string reason, const string next_open, const string since)
  {
   return "sweep held|" + kind + "=" + (string)ticket + "|symbol=" + symbol
        + "|reason=" + reason + "|next_open=" + next_open + "|since=" + since;
  }

string AgSweepBlockedLine(const string state)
  {
   return "sweep blocked|state=" + state;
  }

string AgSweepCompleteLine(const int attempts, const int elapsed)
  {
   return "sweep complete|positions=0|pendings=0|attempts=" + (string)attempts
        + "|elapsed=" + (string)elapsed;
  }

string AgSweepResumedLine(const string gap_from, const string gap_to)
  {
   return "sweep resumed|gap=" + gap_from + ".." + gap_to;
  }

string AgSweepAcceleratedLine(const ulong deal)
  {
   return "sweep accelerated|transaction=DEAL_ADD|deal=" + (string)deal;
  }

#endif // AG_SWEEP_POLICY_MQH
