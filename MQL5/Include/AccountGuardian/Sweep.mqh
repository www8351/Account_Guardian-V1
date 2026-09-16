//+------------------------------------------------------------------+
//| AccountGuardian - Sweep.mqh                                      |
//| Flatten engine, pending deletion, retry policy. SPEC v0.1 4.4.   |
//|                                                                  |
//| STATIC-STRUCTURE RULE (SPEC 1): this is the ONLY file in the     |
//| project permitted to reach the trade API. Every other file must  |
//| grep clean for OrderSend, CTrade, PositionClose, OrderDelete.    |
//|                                                                  |
//| ENFORCEMENT PHASE, owner rulings ENF-1 to ENF-29 of 2026-09-16,  |
//| recorded FINAL in LEDGER DECISIONS, plan                         |
//| docs/PLAN_ENFORCEMENT_SWEEP_2026-09-16.md. The Phase 0 clause    |
//| that kept this file empty of trading calls is retired by that    |
//| ruling; the static-structure rule above stands and is enforced   |
//| by static row ENF-S2 on every build, and static row ENF-S3      |
//| proves the one pass below is reachable from the LOCKED dispatch  |
//| and the OnTradeTransaction accelerator only.                     |
//|                                                                  |
//| WHAT THIS FILE IS AND IS NOT. It is the only file that builds a  |
//| MqlTradeRequest, calls OrderSend, or enumerates pending orders   |
//| through OrdersTotal and OrderGetTicket. Raw OrderSend, no        |
//| standard library, no CTrade (ENF-5(a)). Its policy, the retcode  |
//| classes, the backoff schedule, the ordering, the flat predicate, |
//| the Q3 names and every journal line shape, lives in              |
//| SweepPolicy.mqh so the vectors script proves it without linking  |
//| a trade API (ENF-24(b)). Nothing here is persisted: never loaded |
//| never written (FINAL 2026-07-29) is satisfied by there being no  |
//| file, and a restart re-enumerates the book from the server.      |
//|                                                                  |
//| CLOCK DISCIPLINE, ENF-10(a) and ENF-S6. The backoff and the      |
//| re-arm run on a TIMER PASS COUNTER and no clock. The single      |
//| clock read in this file is AgSweepServerNow, TimeCurrent through |
//| one site, and it serves two Q7 domain readings only: the session |
//| pre-check compares server time against the symbol's own session  |
//| table and names the next open (ENF-13(c)), and the reconnect     |
//| edge stamps the coverage gap the SPEC requires with timestamps   |
//| (ENF-20(a), SPEC 4.4). Neither is a backoff clock. No local,     |
//| GMT or trade-server clock is read anywhere in this file.         |
//|                                                                  |
//| STAGE 6 DISCIPLINE, ENF-S5. The connection is read fresh from    |
//| TerminalInfoInteger(TERMINAL_CONNECTED) on every pass and never  |
//| from the Stage 6 connection sample, a logging global no decision |
//| path may read (question SIX FINAL 2026-08-18).                   |
//+------------------------------------------------------------------+
#ifndef AG_SWEEP_MQH
#define AG_SWEEP_MQH

#include <AccountGuardian/Log.mqh>
#include <AccountGuardian/SweepPolicy.mqh>

//+------------------------------------------------------------------+
//| PER TICKET STATE, in memory only, keyed by ticket. Reset on the  |
//| LOCKED entry transition and in OnInit by AgSweepReset, persisted |
//| nowhere. Plain fields only so the array is a simple structure.   |
//+------------------------------------------------------------------+
//--- held reasons
#define AG_SWEEP_HOLD_NONE       0
#define AG_SWEEP_HOLD_SESSION    1   // pre-check: trade session closed (ENF-13)
#define AG_SWEEP_HOLD_MODE       2   // pre-check: SYMBOL_TRADE_MODE_DISABLED
#define AG_SWEEP_HOLD_RETCODE    3   // hold class retcode, condition must change (ENF-9(c))
#define AG_SWEEP_HOLD_HARD_STOP  4   // H attempts of the retry class (ENF-11(a))
#define AG_SWEEP_HOLD_REFUSE     5   // refuse class retcode, the request is wrong

struct AgSweepTicket
  {
   ulong    ticket;
   bool     is_order;        // pending order, else position
   int      attempts;        // retry class attempts made, reset by DONE_PARTIAL (ENF-12(a))
   int      next_due_pass;   // the pass at which the next attempt may run
   int      last_class;      // AG_RC_* of the last send
   uint     last_retcode;
   int      hold;            // AG_SWEEP_HOLD_*
   int      held_at_pass;    // the pass the hold began, for the cadence and the re-arm
   datetime since;           // server stamp at hold entry, from the last pre-check
   datetime next_open;       // server stamp of the next session open, 0 when unknown
   bool     alerted;         // the one ALERT at hold entry has fired (ENF-11(a), ENF-14(b))
   bool     rearmed;         // the current attempt is a re-arm; a repeat failure re-holds silently
  };

AgSweepTicket g_ag_sweep_tickets[];

//--- the pass counter, ENF-10(a): advanced by the timer pass only, so an
//--- accelerated pass (ENF-2(a)) runs on the current count and does not
//--- shorten a schedule.
int      g_ag_sweep_pass             = 0;
//--- connectivity edge for the coverage gap line (ENF-20(a))
bool     g_ag_sweep_connected        = true;
datetime g_ag_sweep_gap_from         = 0;
//--- the account wide blocked state, the CANNOT_TRADE sub-condition
bool     g_ag_sweep_blocked          = false;
string   g_ag_sweep_blocked_state    = "";
int      g_ag_sweep_blocked_at_pass  = 0;
//--- the flat detector (ENF-16(b)) and the episode bookkeeping
int      g_ag_sweep_flat_passes      = 0;
bool     g_ag_sweep_complete_armed   = true;
int      g_ag_sweep_episode_start    = 0;
int      g_ag_sweep_episode_attempts = 0;
//--- the counts the LOCKED LIFE line reports (ENF-17(b)), from the last pass
int      g_ag_sweep_open_count       = 0;
int      g_ag_sweep_held_count       = 0;

//+------------------------------------------------------------------+
//| THE ONLY CLOCK READ IN THIS FILE. See the header: two Q7 domain  |
//| readings, the session pre-check and the coverage gap stamps.     |
//+------------------------------------------------------------------+
datetime AgSweepServerNow() { return TimeCurrent(); }

//+------------------------------------------------------------------+
//| Reset every piece of sweep state. Called at the LOCKED entry     |
//| transition, both AgDeclareLock and AgEnterLockFromBoot, and in   |
//| OnInit. Nothing is loaded because nothing is stored.             |
//+------------------------------------------------------------------+
void AgSweepReset()
  {
   ArrayResize(g_ag_sweep_tickets, 0);
   g_ag_sweep_pass             = 0;
   g_ag_sweep_connected        = true;
   g_ag_sweep_gap_from         = 0;
   g_ag_sweep_blocked          = false;
   g_ag_sweep_blocked_state    = "";
   g_ag_sweep_blocked_at_pass  = 0;
   g_ag_sweep_flat_passes      = 0;
   g_ag_sweep_complete_armed   = true;
   g_ag_sweep_episode_start    = 0;
   g_ag_sweep_episode_attempts = 0;
   g_ag_sweep_open_count       = 0;
   g_ag_sweep_held_count       = 0;
  }

//--- the two counts the EA builder appends to the LOCKED LIFE line as
//--- sweep=<open>/<held> (ENF-17(b)); open is positions plus pendings
//--- still on the book at the last pass, held the tickets among them
//--- the sweep is holding for a named reason.
int AgSweepOpenCount() { return g_ag_sweep_open_count; }
int AgSweepHeldCount() { return g_ag_sweep_held_count; }

//--- the banner sub-conditions, SPEC 2 and ENF-11(a): CANNOT_TRADE while
//--- an account wide state blocks, CANNOT_FLATTEN while any ticket is held.
string AgSweepSubCondition()
  {
   string s = "";
   if(g_ag_sweep_blocked)
      s = "CANNOT_TRADE: " + g_ag_sweep_blocked_state;
   if(g_ag_sweep_held_count > 0)
      s += (s == "" ? "" : ", ") + "CANNOT_FLATTEN: " + (string)g_ag_sweep_held_count + " held";
   return s;
  }

//+------------------------------------------------------------------+
//| Read only enumeration of pending type orders, exposed so the EA  |
//| can count them for the ENF-18(a) ALERT without naming            |
//| OrdersTotal or OrderGetTicket outside this file. Sends nothing.  |
//+------------------------------------------------------------------+
int AgSweepCountPendings()
  {
   int count = 0;
   int total = OrdersTotal();
   for(int i = 0; i < total; i++)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;
      if(AgIsPendingType((int)OrderGetInteger(ORDER_TYPE)))
         count++;
     }
   return count;
  }

//+------------------------------------------------------------------+
//| The four account wide reads, one read each per pass, named       |
//| through SweepPolicy (Q3/F2 FINAL 2026-07-29).                    |
//+------------------------------------------------------------------+
bool AgTradeAllowed(string &blocking_state)
  {
   blocking_state = AgTradeBlockName((bool)TerminalInfoInteger(TERMINAL_TRADE_ALLOWED),
                                     (bool)MQLInfoInteger(MQL_TRADE_ALLOWED),
                                     (bool)AccountInfoInteger(ACCOUNT_TRADE_ALLOWED),
                                     (bool)AccountInfoInteger(ACCOUNT_TRADE_EXPERT));
   return blocking_state == "";
  }

//+------------------------------------------------------------------+
//| THE SESSION PRE-CHECK, ENF-13(c). Reads the symbol's own trade   |
//| session table through SymbolInfoSessionTrade against the server  |
//| clock and reports the next open. A symbol that reports no trade  |
//| session at all reads as OPEN, never closed, the AgQuoteSessionOpen |
//| precedent: claiming a closed session without evidence would hold |
//| a position the platform would have closed. The retcode tells the |
//| truth afterwards.                                                |
//+------------------------------------------------------------------+
bool AgSweepSessionOpen(const string symbol, datetime &now_out, datetime &next_open_out)
  {
   datetime now = AgSweepServerNow();
   now_out       = now;
   next_open_out = 0;
   MqlDateTime dt;
   TimeToStruct(now, dt);
   int      now_sec   = dt.hour * 3600 + dt.min * 60 + dt.sec;
   datetime day_start = now - now_sec;
   bool     any_session = false;
   datetime from = 0, to = 0;

   //--- yesterday's session running past midnight into today
   int dow_prev = (dt.day_of_week + 6) % 7;
   for(int i = 0; i < 8; i++)
     {
      if(!SymbolInfoSessionTrade(symbol, (ENUM_DAY_OF_WEEK)dow_prev, i, from, to))
         break;
      any_session = true;
      if((long)to > 86400 && now_sec + 86400 >= (int)from && now_sec + 86400 < (int)to)
         return true;
     }
   //--- today's sessions, and the earliest future one for next_open
   for(int i = 0; i < 8; i++)
     {
      if(!SymbolInfoSessionTrade(symbol, (ENUM_DAY_OF_WEEK)dt.day_of_week, i, from, to))
         break;
      any_session = true;
      if(now_sec >= (int)from && now_sec < (int)to)
         return true;
      if((int)from > now_sec && (next_open_out == 0 || day_start + from < next_open_out))
         next_open_out = day_start + from;
     }
   if(next_open_out == 0)
     {
      //--- the first session of the next day that has one, up to a week out
      for(int d = 1; d <= 7 && next_open_out == 0; d++)
        {
         int dow_d = (dt.day_of_week + d) % 7;
         for(int i = 0; i < 8; i++)
           {
            if(!SymbolInfoSessionTrade(symbol, (ENUM_DAY_OF_WEEK)dow_d, i, from, to))
               break;
            any_session = true;
            datetime candidate = day_start + d * 86400 + from;
            if(next_open_out == 0 || candidate < next_open_out)
               next_open_out = candidate;
           }
        }
     }
   return !any_session;
  }

//+------------------------------------------------------------------+
//| Per ticket state lookup, created on first sight.                 |
//+------------------------------------------------------------------+
int AgSweepFindTicket(const ulong ticket, const bool is_order)
  {
   int n = ArraySize(g_ag_sweep_tickets);
   for(int i = 0; i < n; i++)
      if(g_ag_sweep_tickets[i].ticket == ticket && g_ag_sweep_tickets[i].is_order == is_order)
         return i;
   ArrayResize(g_ag_sweep_tickets, n + 1);
   g_ag_sweep_tickets[n].ticket        = ticket;
   g_ag_sweep_tickets[n].is_order      = is_order;
   g_ag_sweep_tickets[n].attempts      = 0;
   g_ag_sweep_tickets[n].next_due_pass = 0;
   g_ag_sweep_tickets[n].last_class    = AG_RC_DONE;
   g_ag_sweep_tickets[n].last_retcode  = 0;
   g_ag_sweep_tickets[n].hold          = AG_SWEEP_HOLD_NONE;
   g_ag_sweep_tickets[n].held_at_pass  = 0;
   g_ag_sweep_tickets[n].since         = 0;
   g_ag_sweep_tickets[n].next_open     = 0;
   g_ag_sweep_tickets[n].alerted       = false;
   g_ag_sweep_tickets[n].rearmed       = false;
   return n;
  }

string AgSweepHoldReason(const int idx)
  {
   switch(g_ag_sweep_tickets[idx].hold)
     {
      case AG_SWEEP_HOLD_SESSION:   return "session closed";
      case AG_SWEEP_HOLD_MODE:      return "SYMBOL_TRADE_MODE_DISABLED";
      case AG_SWEEP_HOLD_RETCODE:   return "hold " + AgRetcodeName(g_ag_sweep_tickets[idx].last_retcode)
                                           + " (" + (string)g_ag_sweep_tickets[idx].last_retcode + ")";
      case AG_SWEEP_HOLD_HARD_STOP: return "hard stop after " + (string)g_ag_sweep_tickets[idx].attempts
                                           + " attempts, last " + AgRetcodeName(g_ag_sweep_tickets[idx].last_retcode)
                                           + " (" + (string)g_ag_sweep_tickets[idx].last_retcode + ")";
      case AG_SWEEP_HOLD_REFUSE:    return "refuse " + AgRetcodeName(g_ag_sweep_tickets[idx].last_retcode)
                                           + " (" + (string)g_ag_sweep_tickets[idx].last_retcode + ")";
     }
   return "-";
  }

string AgSweepStamp(const datetime t)
  {
   return (t == 0) ? "-" : TimeToString(t, TIME_DATE | TIME_SECONDS);
  }

//--- Enter a hold: the one ALERT naming the ticket at the first entry
//--- (ENF-11(a), ENF-14(b)), the journal line now and at the cadence
//--- thereafter. A repeat hold after a re-arm attempt raises no second
//--- popup, which is what keeps the re-arm from producing one a minute.
void AgSweepHold(const int idx, const int reason, const string symbol, const datetime since,
                 const datetime next_open, const int pass)
  {
   g_ag_sweep_tickets[idx].hold         = reason;
   g_ag_sweep_tickets[idx].held_at_pass = pass;
   g_ag_sweep_tickets[idx].since        = since;
   g_ag_sweep_tickets[idx].next_open    = next_open;
   string kind = g_ag_sweep_tickets[idx].is_order ? "order" : "position";
   string line = AgSweepHeldLine(kind, g_ag_sweep_tickets[idx].ticket, symbol, AgSweepHoldReason(idx),
                                 AgSweepStamp(next_open), AgSweepStamp(since));
   AgInfo(line);
   if(!g_ag_sweep_tickets[idx].alerted)
     {
      g_ag_sweep_tickets[idx].alerted = true;
      AgAlertEvent("CANNOT_FLATTEN: " + kind + " " + (string)g_ag_sweep_tickets[idx].ticket + " on " + symbol
                   + " is held while LOCKED, " + AgSweepHoldReason(idx)
                   + "; the sweep retries when the condition changes or at the re-arm cadence");
     }
  }

//--- Filling per symbol, ENF-6(a), on the symbol's own flag set.
ENUM_ORDER_TYPE_FILLING AgSweepFilling(const string symbol)
  {
   return AgSweepFillingFor(SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE));
  }

//+------------------------------------------------------------------+
//| THE ONE PASS, ENF-1(b) on every LOCKED tick and ENF-2(a) on the  |
//| accelerator, ENF-4(c) at most ONE synchronous send per pass.     |
//| origin is "timer" or "accelerated"; only the timer advances the  |
//| pass counter.                                                    |
//|                                                                  |
//| Order of operations: the connection, read fresh, with the        |
//| coverage gap line on the reconnect edge (ENF-20(a)); the account |
//| wide block, the CANNOT_TRADE sub-condition, one ALERT at entry   |
//| and one at exit and the journal line at the cadence (ENF-14(b)); |
//| enumeration of pendings then positions, positions sorted most    |
//| negative floating first (ENF-7(a)); the flat detector on two     |
//| consecutive passes that sent nothing (ENF-16(b)); then the walk, |
//| pendings before positions, every ticket's hold and cadence       |
//| handled, and the first DUE ticket sent: session pre-check and    |
//| trade mode (ENF-13(c), ENF-15(a)), the request, the send, the    |
//| classification, one journal line per attempt.                    |
//+------------------------------------------------------------------+
void AgSweepPass(const string origin)
  {
   if(origin == "timer")
      g_ag_sweep_pass++;
   int pass = g_ag_sweep_pass;

   //--- Never send from a disconnected pass (Q10's ground). Read fresh.
   bool connected = (bool)TerminalInfoInteger(TERMINAL_CONNECTED);
   if(!connected)
     {
      if(g_ag_sweep_connected)
        {
         g_ag_sweep_connected = false;
         g_ag_sweep_gap_from  = AgSweepServerNow();
        }
      return;
     }
   if(!g_ag_sweep_connected)
     {
      g_ag_sweep_connected = true;
      AgInfo(AgSweepResumedLine(AgSweepStamp(g_ag_sweep_gap_from), AgSweepStamp(AgSweepServerNow())));
     }

   //--- The account wide block, one read per state per pass.
   string blocking = "";
   if(!AgTradeAllowed(blocking))
     {
      if(!g_ag_sweep_blocked || blocking != g_ag_sweep_blocked_state)
        {
         g_ag_sweep_blocked         = true;
         g_ag_sweep_blocked_state   = blocking;
         g_ag_sweep_blocked_at_pass = pass;
         AgInfo(AgSweepBlockedLine(blocking));
         AgAlertEvent("CANNOT_TRADE while LOCKED: " + blocking
                      + "; the sweep sends nothing until trading is restored and resumes the moment it is");
        }
      else if((pass - g_ag_sweep_blocked_at_pass) % AG_SWEEP_CADENCE_PASSES == 0)
         AgInfo(AgSweepBlockedLine(blocking));
      return;
     }
   if(g_ag_sweep_blocked)
     {
      AgAlertEvent("trading restored while LOCKED: " + g_ag_sweep_blocked_state
                   + " cleared; the sweep resumes this pass");
      g_ag_sweep_blocked       = false;
      g_ag_sweep_blocked_state = "";
     }

   //--- Enumerate pendings, then positions, the AgFloating pattern with
   //--- the ticket zero skip (a position that vanished mid loop).
   ulong  o_ticket[]; string o_symbol[]; int o_type[];
   int    n_orders = 0;
   int    total_orders = OrdersTotal();
   ArrayResize(o_ticket, total_orders);
   ArrayResize(o_symbol, total_orders);
   ArrayResize(o_type,   total_orders);
   for(int i = 0; i < total_orders; i++)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;
      int type = (int)OrderGetInteger(ORDER_TYPE);
      if(!AgIsPendingType(type))
         continue;
      o_ticket[n_orders] = ticket;
      o_symbol[n_orders] = OrderGetString(ORDER_SYMBOL);
      o_type[n_orders]   = type;
      n_orders++;
     }

   ulong  p_ticket[]; string p_symbol[]; int p_type[]; double p_volume[]; double p_floating[];
   int    n_positions = 0;
   int    total_positions = PositionsTotal();
   ArrayResize(p_ticket,   total_positions);
   ArrayResize(p_symbol,   total_positions);
   ArrayResize(p_type,     total_positions);
   ArrayResize(p_volume,   total_positions);
   ArrayResize(p_floating, total_positions);
   for(int i = 0; i < total_positions; i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      p_ticket[n_positions]   = ticket;
      p_symbol[n_positions]   = PositionGetString(POSITION_SYMBOL);
      p_type[n_positions]     = (int)PositionGetInteger(POSITION_TYPE);
      p_volume[n_positions]   = PositionGetDouble(POSITION_VOLUME);
      p_floating[n_positions] = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      n_positions++;
     }
   //--- ENF-7(a): most negative floating first, ties by ticket, insertion sort
   for(int i = 1; i < n_positions; i++)
     {
      ulong  kt = p_ticket[i]; string ks = p_symbol[i]; int ky = p_type[i];
      double kv = p_volume[i]; double kf = p_floating[i];
      int j = i - 1;
      while(j >= 0 && AgSweepPositionCompare(p_floating[j], p_ticket[j], kf, kt) > 0)
        {
         p_ticket[j + 1] = p_ticket[j]; p_symbol[j + 1] = p_symbol[j]; p_type[j + 1] = p_type[j];
         p_volume[j + 1] = p_volume[j]; p_floating[j + 1] = p_floating[j];
         j--;
        }
      p_ticket[j + 1] = kt; p_symbol[j + 1] = ks; p_type[j + 1] = ky;
      p_volume[j + 1] = kv; p_floating[j + 1] = kf;
     }

   //--- The flat detector, ENF-16(b): two consecutive passes that sent
   //--- nothing on an empty book. A non flat book arms the complete line
   //--- again so every flatten episode ends with exactly one.
   bool flat = AgSweepFlat(n_positions, n_orders);
   if(!flat)
     {
      if(!g_ag_sweep_complete_armed)
        {
         g_ag_sweep_complete_armed   = true;
         g_ag_sweep_episode_start    = pass;
         g_ag_sweep_episode_attempts = 0;
        }
      g_ag_sweep_flat_passes = 0;
     }

   int  sent      = 0;
   int  held      = 0;
   int  idx       = -1;
   datetime now = 0, next_open = 0;

   //--- THE WALK. Pendings first (ENF-7(a), SPEC 2's "delete pendings,
   //--- begin sweep"), then the sorted positions. n_orders + n_positions
   //--- candidates, index k below n_orders is a pending.
   int candidates = n_orders + n_positions;
   for(int k = 0; k < candidates; k++)
     {
      bool   is_order = (k < n_orders);
      ulong  ticket   = is_order ? o_ticket[k] : p_ticket[k - n_orders];
      string symbol   = is_order ? o_symbol[k] : p_symbol[k - n_orders];
      idx = AgSweepFindTicket(ticket, is_order);

      //--- A held ticket: re-arm when its condition changes or at the cadence,
      //--- else the journal line at the cadence and nothing sent.
      if(g_ag_sweep_tickets[idx].hold != AG_SWEEP_HOLD_NONE)
        {
         bool release = false;
         int  hold    = g_ag_sweep_tickets[idx].hold;
         if(hold == AG_SWEEP_HOLD_SESSION || hold == AG_SWEEP_HOLD_MODE)
           {
            //--- the condition is re-read every pass (ENF-9(c))
            bool open     = AgSweepSessionOpen(symbol, now, next_open);
            bool sendable = AgSymbolTradeModeSendable(SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE));
            release = (open && sendable);
            g_ag_sweep_tickets[idx].next_open = next_open;
           }
         else if(pass - g_ag_sweep_tickets[idx].held_at_pass >= AG_SWEEP_REARM_PASSES)
            release = true;   // ENF-11(a): re-armed for one attempt every AG_SWEEP_REARM_PASSES
         if(!release)
           {
            held++;
            if((pass - g_ag_sweep_tickets[idx].held_at_pass) % AG_SWEEP_CADENCE_PASSES == 0
               && pass != g_ag_sweep_tickets[idx].held_at_pass)
               AgInfo(AgSweepHeldLine(is_order ? "order" : "position", ticket, symbol, AgSweepHoldReason(idx),
                                      AgSweepStamp(g_ag_sweep_tickets[idx].next_open),
                                      AgSweepStamp(g_ag_sweep_tickets[idx].since)));
            continue;
           }
         //--- a session or mode release is the condition changing, not a
         //--- re-arm; the cadence release is the one attempt ENF-11(a) grants
         g_ag_sweep_tickets[idx].hold          = AG_SWEEP_HOLD_NONE;
         g_ag_sweep_tickets[idx].rearmed       = (hold != AG_SWEEP_HOLD_SESSION && hold != AG_SWEEP_HOLD_MODE);
         g_ag_sweep_tickets[idx].next_due_pass = pass;
        }

      if(sent >= 1)
         continue;   // ENF-4(c): at most one send per pass
      if(pass < g_ag_sweep_tickets[idx].next_due_pass)
         continue;   // backoff not elapsed, in passes (ENF-9(c), ENF-10(a))

      //--- ENF-13(c) pre-check: the name from the session table and the
      //--- trade mode, the truth from the retcode below. ENF-15(a): CLOSEONLY
      //--- is sendable; only DISABLED holds here.
      bool open = AgSweepSessionOpen(symbol, now, next_open);
      long mode = SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE);
      if(!open)
        {
         AgSweepHold(idx, AG_SWEEP_HOLD_SESSION, symbol, now, next_open, pass);
         held++;
         continue;
        }
      if(!AgSymbolTradeModeSendable(mode))
        {
         AgSweepHold(idx, AG_SWEEP_HOLD_MODE, symbol, now, 0, pass);
         held++;
         continue;
        }
      if(mode != SYMBOL_TRADE_MODE_FULL)
         AgInfo("sweep symbol mode|symbol=" + symbol + "|mode=" + AgSymbolTradeModeName(mode) + "|sendable=1");

      //--- THE REQUEST. Raw MqlTradeRequest, ENF-5(a). A position close on
      //--- this hedging account is bound to its ticket through request.position
      //--- (plan 2.7.2); a pending is removed by ticket.
      MqlTradeRequest request;
      MqlTradeResult  result;
      ZeroMemory(request);
      ZeroMemory(result);
      request.magic   = AG_SWEEP_MAGIC;
      request.comment = AG_SWEEP_COMMENT;
      int    p        = k - n_orders;
      double volume   = 0.0;
      double floating = 0.0;
      string type_name;
      if(is_order)
        {
         request.action = TRADE_ACTION_REMOVE;
         request.order  = ticket;
         type_name      = AgPendingTypeName(o_type[k]);
        }
      else
        {
         volume   = p_volume[p];
         floating = p_floating[p];
         request.action       = TRADE_ACTION_DEAL;
         request.position     = ticket;
         request.symbol       = symbol;
         request.volume       = volume;
         request.type         = (p_type[p] == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
         request.price        = (p_type[p] == POSITION_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_BID)
                                                                  : SymbolInfoDouble(symbol, SYMBOL_ASK);
         request.deviation    = AG_SWEEP_DEVIATION_POINTS;
         request.type_filling = AgSweepFilling(symbol);
         type_name            = AgPositionTypeName(p_type[p]);
        }

      //--- THE SEND, synchronous, one per pass (ENF-4(c)). The bool return
      //--- says the terminal accepted the request for sending and nothing
      //--- more; the retcode is the answer and is classified either way.
      bool accepted = OrderSend(request, result);
      sent++;
      g_ag_sweep_episode_attempts++;
      uint retcode = result.retcode;
      if(!accepted && retcode == 0)
         AgWarn("sweep send not accepted by the terminal|" + (is_order ? "order=" : "position=")
                + (string)ticket + "|error=" + (string)GetLastError() + "|classified as retry");
      int  cls     = AgRetcodeClass(retcode);
      bool partial = AgRetcodeIsPartial(retcode);
      int  prev_class = g_ag_sweep_tickets[idx].last_class;
      //--- the re-arm grants exactly one attempt (ENF-11(a)); whatever it
      //--- returns, the next attempt is judged on the schedule alone
      bool was_rearm = g_ag_sweep_tickets[idx].rearmed;
      g_ag_sweep_tickets[idx].rearmed      = false;
      g_ag_sweep_tickets[idx].last_class   = cls;
      g_ag_sweep_tickets[idx].last_retcode = retcode;
      g_ag_sweep_tickets[idx].since        = now;
      g_ag_sweep_tickets[idx].next_open    = next_open;

      //--- one journal line per attempt (SPEC 6), attempt is the count
      //--- including this one for the retry class
      int attempt_no = g_ag_sweep_tickets[idx].attempts + ((cls == AG_RC_RETRY && !partial) ? 1 : 0);
      if(attempt_no == 0)
         attempt_no = 1;
      if(is_order)
         AgInfo(AgSweepDeleteLine(ticket, symbol, type_name, retcode, cls, attempt_no));
      else
         AgInfo(AgSweepCloseLine(ticket, symbol, type_name, volume, floating, retcode, cls, attempt_no,
                                 (cls == AG_RC_DONE || partial) ? result.volume : 0.0));

      //--- THE CLASSES.
      if(cls == AG_RC_DONE)
        {
         //--- the next enumeration is the evidence the ticket is gone
         //--- (plan 2.7.7); a held ticket that finally closed gets its exit ALERT
         if(g_ag_sweep_tickets[idx].alerted)
           {
            AgAlertEvent("flattened after hold: " + (is_order ? "order " : "position ") + (string)ticket
                         + " on " + symbol + " accepted with " + AgRetcodeName(retcode));
            g_ag_sweep_tickets[idx].alerted = false;
           }
        }
      else if(partial)
        {
         //--- ENF-12(a): the remainder is a fresh ticket for the schedule
         g_ag_sweep_tickets[idx].attempts      = 0;
         g_ag_sweep_tickets[idx].next_due_pass = pass + 1;
        }
      else if(cls == AG_RC_RETRY || cls == AG_RC_PLACED)
        {
         g_ag_sweep_tickets[idx].attempts++;
         if(was_rearm && prev_class == cls)
           {
            //--- a re-arm attempt that failed the same way re-holds silently
            AgSweepHold(idx, AG_SWEEP_HOLD_HARD_STOP, symbol, now, 0, pass);
            held++;
           }
         else if(g_ag_sweep_tickets[idx].attempts >= AG_SWEEP_HARD_STOP)
           {
            AgSweepHold(idx, AG_SWEEP_HOLD_HARD_STOP, symbol, now, 0, pass);
            held++;
           }
         else
            g_ag_sweep_tickets[idx].next_due_pass = pass + AgBackoffPasses(g_ag_sweep_tickets[idx].attempts);
        }
      else if(cls == AG_RC_HOLD)
        {
         //--- ENF-9(c): no attempts for the hold class until its condition changes
         AgSweepHold(idx, AG_SWEEP_HOLD_RETCODE, symbol, now, next_open, pass);
         held++;
        }
      else
        {
         //--- refuse: the request itself is wrong, the ticket stops here and is
         //--- reported as held; the re-arm cadence keeps it from being abandoned
         AgSweepHold(idx, AG_SWEEP_HOLD_REFUSE, symbol, now, 0, pass);
         held++;
        }
     }

   g_ag_sweep_open_count = n_positions + n_orders;
   g_ag_sweep_held_count = held;

   //--- sweep pass: once per pass that sent anything, and once when the
   //--- book first reads flat (plan 3.5)
   if(sent > 0 || (flat && g_ag_sweep_flat_passes == 0))
      AgInfo(AgSweepPassLine(n_positions, n_orders, held, sent));

   if(flat && sent == 0)
     {
      g_ag_sweep_flat_passes++;
      if(g_ag_sweep_flat_passes >= 2 && g_ag_sweep_complete_armed)
        {
         AgInfo(AgSweepCompleteLine(g_ag_sweep_episode_attempts, pass - g_ag_sweep_episode_start));
         g_ag_sweep_complete_armed = false;
        }
     }
  }

#endif // AG_SWEEP_MQH
