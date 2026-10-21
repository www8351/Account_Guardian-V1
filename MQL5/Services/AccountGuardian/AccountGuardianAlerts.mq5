//+------------------------------------------------------------------+
//| AccountGuardianAlerts.mq5                                        |
//| The alerts service of the guardian, TG-1 (B) of 2026-10-20,      |
//| design addendum docs/PLAN_TELEGRAM_ALERTS_ADDENDUM_TG1B.md.       |
//|                                                                  |
//| It reads the guardian's alert queue and the mutex heartbeat and  |
//| makes every network request: the Telegram messages, the network  |
//| heartbeat ping of the hosted check, and the one read only        |
//| command. THE GUARDIAN MAKES NO NETWORK CALL AND WAITS ON NOTHING |
//| THIS SERVICE DOES. Nothing this service writes is read by any    |
//| decision path of the guardian: it writes no file, and two global |
//| variables only, the acknowledgement AG_TGACK_<login>, which can  |
//| only make the guardian forget events already sent, and the       |
//| refusal it has reported, AG_TGREFSEEN_<login>. It sends no order |
//| and has no path to an input, a lock, a limit or the state        |
//| machine: no command can unlock, widen a limit or stop the        |
//| guardian (TG-8 (B)).                                             |
//|                                                                  |
//| The three inputs hold secrets. No journal line carries a token, |
//| a chat id or a URL: every request's line names its class, its    |
//| HTTP code, its error and its duration only (plan 6.2.2).         |
//+------------------------------------------------------------------+
#property service
#property copyright   "AccountGuardian"
#property version     "1.00"
#property description "Alerts service of the account guardian: reads the guardian's alert queue and sends its Telegram messages, the network heartbeat ping and the reply to the one read only command. Optional: an empty field turns its channel off and leaves the guardian unaffected."

#include <AccountGuardian/AlertQueue.mqh>
#include <AccountGuardian/AlertJson.mqh>
#include <AccountGuardian/AlertText.mqh>

//--- TG-6 as amended by TG-1 (B): entered by the owner when the service is
//--- added. Optional class (Q4/F9 read onto the service): empty turns the
//--- channel off, malformed turns it off with one WARN.
input string TelegramToken       = "";   // Telegram bot token (empty: Telegram off)
input string TelegramChatId      = "";   // Telegram chat id (empty: Telegram off)
input string NetworkHeartbeatUrl = "";   // Hosted check ping URL (empty: network heartbeat off)

//--- compile time constants, never inputs (the AG_MUTEX_STALE precedent)
#define AG_SVC_BUILD_LABEL       "TG"
#define AG_SVC_TIMEOUT_MS        2000   // every request (plan 6.1.4)
#define AG_SVC_FINAL_TIMEOUT_MS  1500   // the one attempt at a terminal close (TG-13 (B))
#define AG_SVC_SEND_GAP          3      // seconds between two messages (plan 6.4.5)
#define AG_SVC_PING_SECONDS      60     // TG-2.2
#define AG_SVC_POLL_SECONDS      60     // TG-14 (A)
#define AG_SVC_HOLD_SECONDS      60     // the in place restart merge (plan 6.4.3)
#define AG_SVC_RELEASE_GRACE     5      // a release with no stop event (item 4)
#define AG_SVC_START_GRACE       60     // not running, at the service's start (item 4)
#define AG_SVC_COMMAND_MAX_AGE   120    // a command older than this is ignored (item 5)
#define AG_SVC_DEDUP_SECONDS     300    // plan 6.4.2
#define AG_SVC_DATA_OLD          90     // the status message's age line (item 2)
#define AG_SVC_DELAY_SECONDS     60     // the delay line (plan 5)
#define AG_SVC_S11_SECONDS       60     // the S11 notice after this much failure
#define AG_SVC_BACKOFF_MAX       300    // failure backoff cap (plan 6.1.3)
#define AG_SVC_PING_LOG_SECONDS  30     // a ping success journaled at most this often

//--- the guardian's liveness as the service reads AG_HB_<login> (item 4)
#define AG_SVC_LIVE_UNKNOWN  -1
#define AG_SVC_LIVE_FRESH     0
#define AG_SVC_LIVE_STALE     1
#define AG_SVC_LIVE_RELEASED  2
#define AG_SVC_LIVE_MISSING   3

//--- the inputs as checked at the start
bool     g_svc_tg_on        = false;
bool     g_svc_ping_on      = false;
bool     g_svc_cmd_on       = false;
datetime g_svc_started      = 0;      // local clock
long     g_svc_login        = -1;

//--- the queue as last read, and the acknowledgement
long         g_svc_ack          = 0;
long         g_svc_enq_upto     = 0;  // the highest seq sent, merged, suppressed or converted
bool         g_svc_have_snap    = false;
AgTgSnapshot g_svc_snap;
string       g_svc_snap_build   = "";
AgTgEvent    g_svc_events[];          // the unacknowledged events of the last good read
int          g_svc_event_count  = 0;
long         g_svc_last_s2_local = 0; // local_t of the newest stop event seen
long         g_svc_consumed[];        // S1 or S16 seqs merged into a restarted message
int          g_svc_consumed_count = 0;

//--- the in place restart hold (TG-13 (B) read under TG-1 (B), item 7)
bool     g_svc_hold         = false;
long     g_svc_hold_seq     = 0;
long     g_svc_hold_until   = 0;      // local clock

//--- a refusal read this loop, reported after the conversion step
bool     g_svc_refusal_new  = false;
int      g_svc_refusal_code = 0;
long     g_svc_refusal_local = 0;

//--- the messages waiting to be sent, first in first out, parallel arrays
string   g_out_text[];
string   g_out_cls[];
long     g_out_seq[];       // the seq the journal line names, 0 for a service message
long     g_out_ack[];       // the acknowledgement this message carries, 0 for none
long     g_out_local[];     // the event's local time, for the delay line
long     g_out_notkept[];
long     g_out_heldback[];
int      g_out_count = 0;

//--- sending
datetime g_svc_next_send    = 0;
datetime g_svc_retry_until  = 0;      // a 429 window
datetime g_svc_backoff_until = 0;
int      g_svc_fail_count   = 0;
datetime g_svc_fail_since   = 0;      // the first failure of an outage, 0 when none

//--- the network heartbeat and the command
datetime g_svc_last_ping    = 0;
datetime g_svc_last_ping_log = 0;
datetime g_svc_last_poll    = 0;
int      g_svc_poll_interval = AG_SVC_POLL_SECONDS;
long     g_svc_offset       = 0;

//--- the guardian's liveness
int      g_svc_live         = AG_SVC_LIVE_UNKNOWN;
datetime g_svc_live_since   = 0;      // local, when this liveness began
bool     g_svc_seen_fresh   = false;  // seen fresh at least once this session
double   g_svc_last_fresh_hb = 0.0;   // the mutex heartbeat value last seen fresh
double   g_svc_live_id      = 0.0;    // the instance id when the episode began
bool     g_svc_alerted      = false;  // the episode's alert has gone

//--- the status schedule and the summary
long     g_svc_last_slot    = 0;
long     g_svc_s14_anchor   = 0;
double   g_svc_s14_peak     = 0.0;
long     g_svc_lock_times[];
int      g_svc_lock_count   = 0;

//--- the suppression of plan 6.4.2
string   g_dd_key[];
datetime g_dd_time[];
int      g_dd_count         = 0;
string   g_dd_cls[];
long     g_dd_held[];
int      g_dd_cls_count     = 0;

//+------------------------------------------------------------------+
//| SMALL HELPERS                                                    |
//+------------------------------------------------------------------+
string AgSvcLiveName(const int live)
  {
   switch(live)
     {
      case AG_SVC_LIVE_FRESH:    return "fresh";
      case AG_SVC_LIVE_STALE:    return "stale";
      case AG_SVC_LIVE_RELEASED: return "released";
      case AG_SVC_LIVE_MISSING:  return "missing";
     }
   return "unknown";
  }

string AgSvcBuildLine()
  {
   if(g_svc_have_snap && g_svc_snap_build != "" && g_svc_snap_build != AG_SVC_BUILD_LABEL)
      return "build=" + g_svc_snap_build + "|service=" + AG_SVC_BUILD_LABEL;
   return "build=" + AG_SVC_BUILD_LABEL;
  }

//--- the common lines of an event, from the event's own figures
void AgSvcCommonFromEvent(const AgTgEvent &e, AgTgCommon &c)
  {
   c.login    = g_svc_login;
   c.server_t = (datetime)e.server_t;
   c.balance  = e.balance;
   c.equity   = e.equity;
   c.pnl      = e.pnl;
   c.limit    = e.limit;
   c.pnl_mode = e.pnl_mode;
   c.state    = e.state;
  }

//--- the common lines of a service message: the guardian's last figures when
//--- it runs, else the service's own read, the day's result not computed
void AgSvcCommonNow(AgTgCommon &c, const bool guardian_runs)
  {
   c.login    = g_svc_login;
   c.server_t = TimeCurrent();
   if(guardian_runs && g_svc_have_snap)
     {
      c.balance  = g_svc_snap.balance;
      c.equity   = g_svc_snap.equity;
      c.pnl      = g_svc_snap.pnl;
      c.limit    = g_svc_snap.limit;
      c.pnl_mode = g_svc_snap.pnl_mode;
      c.state    = g_svc_snap.state;
      return;
     }
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   c.balance  = balance;
   c.equity   = balance + AgFloating();   // never an ACCOUNT_EQUITY read (D2D4-4(a))
   c.pnl      = 0.0;
   c.limit    = 0.0;
   c.pnl_mode = AG_TG_PNL_NONE;
   c.state    = AG_TG_STATE_NOT_RUNNING;
  }

//--- the symbol of a ticket, for the symbol line of S6 and S7; "" when unknown
string AgSvcSymbolOf(const ulong ticket, const bool is_order)
  {
   if(!is_order)
     {
      if(PositionSelectByTicket(ticket))
         return PositionGetString(POSITION_SYMBOL);
      if(HistorySelectByPosition(ticket))
        {
         int n = HistoryDealsTotal();
         for(int i = 0; i < n; i++)
           {
            ulong deal = HistoryDealGetTicket(i);
            if(deal > 0)
               return HistoryDealGetString(deal, DEAL_SYMBOL);
           }
        }
      return "";
     }
   if(OrderSelect(ticket))
      return OrderGetString(ORDER_SYMBOL);
   if(HistoryOrderSelect(ticket))
      return HistoryOrderGetString(ticket, ORDER_SYMBOL);
   return "";
  }

bool AgSvcConsumed(const long seq)
  {
   for(int i = 0; i < g_svc_consumed_count; i++)
      if(g_svc_consumed[i] == seq)
         return true;
   return false;
  }

void AgSvcConsume(const long seq)
  {
   ArrayResize(g_svc_consumed, g_svc_consumed_count + 1);
   g_svc_consumed[g_svc_consumed_count] = seq;
   g_svc_consumed_count++;
  }

//--- write the acknowledgement: only ever forward
void AgSvcAck(const long seq)
  {
   if(seq <= g_svc_ack)
      return;
   g_svc_ack = seq;
   GlobalVariableSet(AgGvTgAck(g_svc_login), (double)g_svc_ack);
   GlobalVariablesFlush();
  }

//--- an event handled without a message of its own: the last waiting message
//--- carries its acknowledgement, or, with none waiting, it is acknowledged now
void AgSvcAdvance(const long seq)
  {
   if(g_out_count > 0)
     {
      if(g_out_ack[g_out_count - 1] < seq)
         g_out_ack[g_out_count - 1] = seq;
      return;
     }
   AgSvcAck(seq);
  }

void AgSvcEnqueue(const string text, const string cls, const long seq, const long ack,
                  const long event_local, const long not_kept, const long held_back)
  {
   if(!g_svc_tg_on)
      return;   // Telegram off: nothing waits, nothing piles up in memory
   ArrayResize(g_out_text, g_out_count + 1);
   ArrayResize(g_out_cls, g_out_count + 1);
   ArrayResize(g_out_seq, g_out_count + 1);
   ArrayResize(g_out_ack, g_out_count + 1);
   ArrayResize(g_out_local, g_out_count + 1);
   ArrayResize(g_out_notkept, g_out_count + 1);
   ArrayResize(g_out_heldback, g_out_count + 1);
   g_out_text[g_out_count]     = text;
   g_out_cls[g_out_count]      = cls;
   g_out_seq[g_out_count]      = seq;
   g_out_ack[g_out_count]      = ack;
   g_out_local[g_out_count]    = event_local;
   g_out_notkept[g_out_count]  = not_kept;
   g_out_heldback[g_out_count] = held_back;
   g_out_count++;
  }

void AgSvcDropFirst()
  {
   for(int i = 1; i < g_out_count; i++)
     {
      g_out_text[i - 1]     = g_out_text[i];
      g_out_cls[i - 1]      = g_out_cls[i];
      g_out_seq[i - 1]      = g_out_seq[i];
      g_out_ack[i - 1]      = g_out_ack[i];
      g_out_local[i - 1]    = g_out_local[i];
      g_out_notkept[i - 1]  = g_out_notkept[i];
      g_out_heldback[i - 1] = g_out_heldback[i];
     }
   g_out_count--;
   ArrayResize(g_out_text, g_out_count);
   ArrayResize(g_out_cls, g_out_count);
   ArrayResize(g_out_seq, g_out_count);
   ArrayResize(g_out_ack, g_out_count);
   ArrayResize(g_out_local, g_out_count);
   ArrayResize(g_out_notkept, g_out_count);
   ArrayResize(g_out_heldback, g_out_count);
  }

//+------------------------------------------------------------------+
//| SUPPRESSION, plan 6.4.2: the same class and key within 300 s is  |
//| suppressed and counted, and the count rides on the next message  |
//| of that class. Only the noisy classes take part: a start, a      |
//| stop, a lock, a release, a halt and a refusal always go.         |
//+------------------------------------------------------------------+
int AgSvcDedupClass(const string cls)
  {
   for(int i = 0; i < g_dd_cls_count; i++)
      if(g_dd_cls[i] == cls)
         return i;
   ArrayResize(g_dd_cls, g_dd_cls_count + 1);
   ArrayResize(g_dd_held, g_dd_cls_count + 1);
   g_dd_cls[g_dd_cls_count]  = cls;
   g_dd_held[g_dd_cls_count] = 0;
   g_dd_cls_count++;
   return g_dd_cls_count - 1;
  }

//--- true when the key was sent within the window, the class counted
bool AgSvcSuppressed(const string cls, const string key, const datetime now)
  {
   for(int i = 0; i < g_dd_count; i++)
      if(g_dd_key[i] == key)
        {
         if(now - g_dd_time[i] < AG_SVC_DEDUP_SECONDS)
           {
            g_dd_held[AgSvcDedupClass(cls)]++;
            return true;
           }
         g_dd_time[i] = now;
         return false;
        }
   ArrayResize(g_dd_key, g_dd_count + 1);
   ArrayResize(g_dd_time, g_dd_count + 1);
   g_dd_key[g_dd_count]  = key;
   g_dd_time[g_dd_count] = now;
   g_dd_count++;
   return false;
  }

long AgSvcTakeHeld(const string cls)
  {
   int i = AgSvcDedupClass(cls);
   long held = g_dd_held[i];
   g_dd_held[i] = 0;
   return held;
  }

//--- the suppression key of an event, "" for a class that always goes
string AgSvcDedupKey(const AgTgEvent &e)
  {
   switch(e.code)
     {
      case AG_TG_S6H: return "S6H|" + AgTgNum(e.x[0]);
      case AG_TG_S10: return "S10";
      case AG_TG_S12: return "S12|" + AgTgNum(e.x[0]) + "|" + AgTgNum(e.x[1]);
      case AG_TG_S17: return "S17|" + AgTgNum(e.x[0]) + "|" + AgTgNum(e.x[1]) + "|"
                             + TimeToString((datetime)e.local_t, TIME_DATE);
      case AG_TG_S19: return "S19|" + AgTgNum(e.x[0]);
      case AG_TG_S20: return "S20";
      case AG_TG_S21: return "S21";
      case AG_TG_S22: return "S22";
      case AG_TG_S24: return "S24";
     }
   return "";
  }

//+------------------------------------------------------------------+
//| RENDERING ONE EVENT. The Hebrew is AlertText.mqh's; the figures  |
//| are the event's, the symbol the service's own read.              |
//+------------------------------------------------------------------+
string AgSvcRender(const AgTgEvent &e)
  {
   AgTgCommon c;
   AgSvcCommonFromEvent(e, c);
   switch(e.code)
     {
      case AG_TG_S1:
         return AgTgTextS1(c, e.x[0], e.x[1], e.x[3]);
      case AG_TG_S2:
         return AgTgTextS2(c, (int)e.x[0]);
      case AG_TG_S3:
         if((int)e.x[0] == 1)
            return AgTgTextS3Crash(c, (long)e.x[2], (long)e.x[3]);
         return AgTgTextS3Persisted(c, (datetime)(long)e.x[1]);
      case AG_TG_S4:
         if((int)e.x[0] == 4)
            return AgTgTextS4Peak(c, (datetime)(long)e.x[1], e.x[5], e.x[5] - e.x[2], e.pnl,
                                  (long)e.x[6], (long)e.x[7]);
         return AgTgTextS4(c, (int)e.x[0], (datetime)(long)e.x[1], e.x[3], e.x[4], e.pnl,
                           (long)e.x[6], (long)e.x[7]);
      case AG_TG_S6C:
         return AgTgTextS6C(c, (long)e.x[0], (long)e.x[1], (long)e.x[2], (long)e.x[3], (long)e.x[4]);
      case AG_TG_S6H:
         return AgTgTextS6H(c, (ulong)e.x[0], e.x[1] > 0.5, (int)e.x[2],
                            AgSvcSymbolOf((ulong)e.x[0], e.x[1] > 0.5), (datetime)(long)e.x[3],
                            AG_SWEEP_HARD_STOP, AG_SWEEP_REARM_PASSES);
      case AG_TG_S6F:
         return AgTgTextS6F(c, (ulong)e.x[0], e.x[1] > 0.5, AgSvcSymbolOf((ulong)e.x[0], e.x[1] > 0.5));
      case AG_TG_S7:
         return AgTgTextS7(c, (ulong)e.x[0], AgSvcSymbolOf((ulong)e.x[0], false), (long)e.x[1]);
      case AG_TG_S8:
         if((int)e.x[0] == 1)
            return AgTgTextS8Released(c, (datetime)(long)e.x[1], e.x[2]);
         return AgTgTextS8Again(c, (datetime)(long)e.x[1]);
      case AG_TG_S9:
         return AgTgTextS9(c, (long)e.x[0], e.x[3]);
      case AG_TG_S10:
         return AgTgTextS10(c, (datetime)(long)e.x[0], (datetime)(long)e.x[1], (long)e.x[2]);
      case AG_TG_S12:
         if((int)e.x[0] == 1)
            return AgTgTextS12Blocked(c, (int)e.x[1]);
         return AgTgTextS12Restored(c);
      case AG_TG_S15:
         return AgTgTextS15(c);
      case AG_TG_S16:
         return AgTgTextS16(c, (datetime)(long)e.x[1], (int)e.x[0], (int)e.x[2], (long)e.x[4], (long)e.x[5], -1);
      case AG_TG_S17:
         return AgTgTextS17(c, (int)e.x[0], (int)e.x[1]);
      case AG_TG_S18:
         return AgTgTextS18(c, (long)e.x[0]);
      case AG_TG_S19:
         if((int)e.x[0] == 1)
            return AgTgTextS19Locked(c, (int)e.x[4], e.x[1], e.x[3], e.x[2]);
         return AgTgTextS19Raise(c, e.x[1], e.x[2]);
      case AG_TG_S20:
         return AgTgTextS20(c, (long)e.x[2]);
      case AG_TG_S21:
         return AgTgTextS21(c);
      case AG_TG_S22:
         return AgTgTextS22(c, (long)e.x[0], (int)e.x[1]);
      case AG_TG_S24:
         return AgTgTextS24(c);
     }
   return "";
  }

//--- a stop in place: recompile, chart change, inputs, account, template
bool AgSvcInPlace(const AgTgEvent &e)
  {
   if(e.code != AG_TG_S2)
      return false;
   int r = (int)e.x[0];
   return r == 2 || r == 3 || r == 5 || r == 6 || r == 7;
  }

//--- one event to a waiting message, or suppressed, or merged
void AgSvcConvertOne(const AgTgEvent &e, const datetime now, const long not_kept)
  {
   string cls = AgTgCodeText(e.code);
   string key = AgSvcDedupKey(e);
   if(key != "" && AgSvcSuppressed(cls, key, now))
     {
      AgSvcAdvance(e.seq);
      return;
     }
   if(e.code == AG_TG_S4 || e.code == AG_TG_S16)
     {
      ArrayResize(g_svc_lock_times, g_svc_lock_count + 1);
      g_svc_lock_times[g_svc_lock_count] = e.server_t;
      g_svc_lock_count++;
     }
   AgSvcEnqueue(AgSvcRender(e), cls, e.seq, e.seq, e.local_t, not_kept, AgSvcTakeHeld(cls));
  }

//--- the held stop and the start that follows it, one restarted message
void AgSvcMerge(const AgTgEvent &stop, const AgTgEvent &start)
  {
   AgTgCommon c;
   AgSvcCommonFromEvent(start, c);
   string text;
   string cls;
   if(start.code == AG_TG_S1)
     {
      text = AgTgTextS1Restarted(c, (int)stop.x[0], start.x[3]);
      cls  = "S2+S1";
     }
   else
     {
      text = AgTgTextS16(c, (datetime)(long)start.x[1], (int)start.x[0], (int)start.x[2],
                         (long)start.x[4], (long)start.x[5], (int)stop.x[0]);
      cls  = "S2+S16";
      ArrayResize(g_svc_lock_times, g_svc_lock_count + 1);
      g_svc_lock_times[g_svc_lock_count] = start.server_t;
      g_svc_lock_count++;
     }
   AgSvcEnqueue(text, cls, stop.seq, stop.seq, start.local_t, 0, 0);
   AgSvcConsume(start.seq);
  }

//+------------------------------------------------------------------+
//| THE CONVERSION OF NEW EVENTS, strictly in seq order (1.9). An    |
//| in place stop is held up to 60 s, and the events behind it with  |
//| it, for a start to merge with; a refusal ends the hold at once.  |
//+------------------------------------------------------------------+
void AgSvcConvert(const datetime now)
  {
   for(int i = 0; i < g_svc_event_count; i++)
     {
      AgTgEvent e = g_svc_events[i];
      if(e.seq <= g_svc_enq_upto)
         continue;
      if(AgSvcConsumed(e.seq))
        {
         AgSvcAdvance(e.seq);
         g_svc_enq_upto = e.seq;
         continue;
        }
      long not_kept = (g_svc_enq_upto > 0 && e.seq > g_svc_enq_upto + 1) ? e.seq - g_svc_enq_upto - 1 : 0;
      if(AgSvcInPlace(e))
        {
         int start_at = -1;
         for(int j = i + 1; j < g_svc_event_count; j++)
            if(g_svc_events[j].code == AG_TG_S1 || g_svc_events[j].code == AG_TG_S16)
              {
               start_at = j;
               break;
              }
         if(start_at >= 0)
           {
            AgSvcMerge(e, g_svc_events[start_at]);
            g_svc_hold     = false;
            g_svc_enq_upto = e.seq;
            continue;
           }
         if(now < e.local_t + AG_SVC_HOLD_SECONDS && !g_svc_refusal_new)
           {
            g_svc_hold       = true;
            g_svc_hold_seq   = e.seq;
            g_svc_hold_until = e.local_t + AG_SVC_HOLD_SECONDS;
            return;   // held, and every event behind it with it
           }
         g_svc_hold = false;   // the hold ends: the stop goes alone, item 4 applies from here
        }
      AgSvcConvertOne(e, now, not_kept);
      g_svc_enq_upto = e.seq;
     }
  }

//+------------------------------------------------------------------+
//| THE QUEUE READ (1.4): read only, the whole file, acted on only   |
//| when it parses and its checksum verifies (1.7).                  |
//+------------------------------------------------------------------+
void AgSvcSummary(const long old_anchor, const long new_anchor, const double old_peak)
  {
   bool     ok_old = true, ok_new = true;
   double   run_min = 0.0, run_max = 0.0;
   ulong    max_ticket = 0;
   datetime max_time = 0;
   double from_old = AgRealizedRunFold((datetime)old_anchor, ok_old, run_min, run_max, max_ticket, max_time);
   double from_new = AgRealizedRunFold((datetime)new_anchor, ok_new, run_min, run_max, max_ticket, max_time);
   if(!ok_old || !ok_new)
     {
      AgWarn("alerts summary not sent: the history read failed");
      return;
     }
   long locks = 0;
   for(int i = 0; i < g_svc_lock_count; i++)
      if(g_svc_lock_times[i] >= old_anchor && g_svc_lock_times[i] < new_anchor)
         locks++;
   AgTgCommon c;
   AgSvcCommonNow(c, true);
   AgSvcEnqueue(AgTgTextS14(c, (datetime)old_anchor, from_old - from_new, old_peak, locks,
                            g_svc_snap.enforced_limit),
                "S14", 0, 0, (long)TimeLocal(), 0, 0);
  }

void AgSvcReadQueue()
  {
   string text = "";
   if(!AgTgQueueReadText(AgTgQueuePath(g_svc_login), text))
      return;
   long         login = 0, next_seq = 0, latch = 0;
   int          mask = 0, count = 0;
   AgTgSnapshot snap;
   string       build = "", why = "";
   AgTgEvent    events[];
   if(!AgTgQueueParse(text, login, next_seq, latch, mask, snap, build, events, count, why))
      return;   // a read not taken, retried on the next loop
   if(login != g_svc_login)
      return;
   //--- the numbering went back: the file and the acknowledgement were both
   //--- lost, and every event the file holds is new (1.6)
   if(next_seq - 1 < g_svc_ack)
     {
      g_svc_ack      = 0;
      g_svc_enq_upto = 0;
     }
   g_svc_snap       = snap;
   g_svc_snap_build = build;
   g_svc_have_snap  = true;
   g_svc_event_count = 0;
   ArrayResize(g_svc_events, 0);
   for(int i = 0; i < count; i++)
     {
      if(events[i].code == AG_TG_S2 && events[i].local_t > g_svc_last_s2_local)
         g_svc_last_s2_local = events[i].local_t;
      if(events[i].seq <= g_svc_ack)
         continue;
      ArrayResize(g_svc_events, g_svc_event_count + 1);
      g_svc_events[g_svc_event_count] = events[i];
      g_svc_event_count++;
     }
   //--- S14 (TG-4 (B)): the snapshot's anchor advanced by exactly one day; the
   //--- EA's own anchors, so no second day boundary exists; more than a day is
   //--- S20 and no summary
   long a = snap.anchor;
   if(a > 0)
     {
      if(g_svc_s14_anchor == 0 || a == g_svc_s14_anchor)
         g_svc_s14_peak = snap.peak;
      else if(a == g_svc_s14_anchor + 86400)
        {
         AgSvcSummary(g_svc_s14_anchor, a, g_svc_s14_peak);
         g_svc_s14_peak = snap.peak;
        }
      else if(a > g_svc_s14_anchor)
         g_svc_s14_peak = snap.peak;
      if(a > g_svc_s14_anchor)
         g_svc_s14_anchor = a;
     }
  }

//+------------------------------------------------------------------+
//| THE GUARDIAN'S LIVENESS (item 4), read before the queue and      |
//| acted on after it, so a released mutex heartbeat is judged with  |
//| the stop event OnDeinit wrote before the release.                |
//+------------------------------------------------------------------+
int AgSvcReadLive(double &hb, double &id, const datetime now)
  {
   hb = 0.0;
   id = 0.0;
   GlobalVariableGet(AgGvInstance(), id);
   if(!GlobalVariableGet(AgGvHeartbeat(), hb))
      return AG_SVC_LIVE_MISSING;
   if(hb <= 0.5)
      return AG_SVC_LIVE_RELEASED;
   if((double)now - hb < AG_MUTEX_STALE_SECONDS)
      return AG_SVC_LIVE_FRESH;
   return AG_SVC_LIVE_STALE;
  }

void AgSvcLiveness(const int live, const double hb, const double id, const datetime now)
  {
   if(live != g_svc_live)
     {
      int prev = g_svc_live;
      int age  = (live == AG_SVC_LIVE_STALE) ? (int)((double)now - hb) : 0;
      AgInfo(AgTgGuardianLine(AgSvcLiveName(live), age));
      if(prev == AG_SVC_LIVE_FRESH && g_svc_ping_on)
         AgInfo(AgTgPingSkippedLine(AgSvcLiveName(live), age));
      if(live == AG_SVC_LIVE_FRESH)
        {
         //--- fresh again with the same instance after the episode's alert:
         //--- it responds again; a new instance is a new start, which the
         //--- queue reports as S1 or S16 instead
         if(prev == AG_SVC_LIVE_STALE && g_svc_alerted && id == g_svc_live_id)
           {
            AgTgCommon c;
            AgSvcCommonNow(c, true);
            if(!AgSvcSuppressed("LIVE_BACK", "LIVE_BACK", now))
               AgSvcEnqueue(AgTgTextRespondsAgain(c, (long)(now - g_svc_live_since)), "LIVE_BACK",
                            0, 0, (long)now, 0, AgSvcTakeHeld("LIVE_BACK"));
           }
         g_svc_alerted = false;
        }
      else
         g_svc_live_id = id;
      g_svc_live       = live;
      g_svc_live_since = now;
     }
   if(live == AG_SVC_LIVE_FRESH)
     {
      g_svc_seen_fresh    = true;
      g_svc_last_fresh_hb = hb;
      return;
     }
   //--- AMENDMENT 2 of 2026-10-21: while an in place stop is held for the
   //--- restart merge, a released mutex heartbeat raises no alert here; when
   //--- the hold ends with no start, this applies from that moment
   if(g_svc_alerted || g_svc_hold)
      return;
   AgTgCommon c;
   AgSvcCommonNow(c, false);
   if(!g_svc_seen_fresh)
     {
      //--- the terminal's start races the guardian's init: wait from the
      //--- service's own start before saying it does not run
      if(now - g_svc_started >= AG_SVC_START_GRACE)
        {
         g_svc_alerted = true;
         AgSvcEnqueue(AgTgTextNotRunning(c, (long)(now - g_svc_started)), "LIVE_NONE", 0, 0, (long)now, 0, 0);
        }
      return;
     }
   if(live == AG_SVC_LIVE_RELEASED)
     {
      //--- a release with its stop event on disk is a stop, which S2 reports;
      //--- the stop event's local time is at or after the last refresh
      bool has_stop = (g_svc_last_s2_local > 0 && (double)g_svc_last_s2_local >= g_svc_last_fresh_hb - 1.0);
      if(has_stop || now - g_svc_live_since < AG_SVC_RELEASE_GRACE)
         return;
      g_svc_alerted = true;
      AgSvcEnqueue(AgTgTextNotResponding(c, (long)((double)now - g_svc_last_fresh_hb), true, g_svc_ping_on),
                   "LIVE_STOP", 0, 0, (long)now, 0, 0);
      return;
     }
   //--- stale or missing after it ran: at once
   g_svc_alerted = true;
   double since = (live == AG_SVC_LIVE_STALE) ? hb : g_svc_last_fresh_hb;
   AgSvcEnqueue(AgTgTextNotResponding(c, (long)((double)now - since), false, g_svc_ping_on),
                "LIVE_STOP", 0, 0, (long)now, 0, 0);
  }

//+------------------------------------------------------------------+
//| A REFUSED START (1.10): one GV the refused instance sets, read   |
//| here, reported once; the service alone writes the seen value.    |
//+------------------------------------------------------------------+
void AgSvcReadRefusal()
  {
   g_svc_refusal_new = false;
   double v = 0.0;
   if(!GlobalVariableGet(AgGvTgRefused(g_svc_login), v))
      return;
   double seen = 0.0;
   GlobalVariableGet(AgGvTgRefSeen(g_svc_login), seen);
   if(v <= seen + 0.5)
      return;
   long raw = (long)MathRound(v);
   g_svc_refusal_new   = true;
   g_svc_refusal_code  = (int)(raw % 100);
   g_svc_refusal_local = raw / 100;
   GlobalVariableSet(AgGvTgRefSeen(g_svc_login), v);
   GlobalVariablesFlush();
  }

void AgSvcReportRefusal()
  {
   if(!g_svc_refusal_new)
      return;
   g_svc_refusal_new = false;
   AgTgCommon c;
   if(g_svc_refusal_code == 3)
     {
      //--- the live instance runs on: its state, the day's result not computed
      AgSvcCommonNow(c, g_svc_live == AG_SVC_LIVE_FRESH);
      c.pnl_mode = AG_TG_PNL_NONE;
      AgSvcEnqueue(AgTgTextS3Second(c), "S3", 0, 0, g_svc_refusal_local, 0, 0);
      return;
     }
   AgSvcCommonNow(c, false);
   AgSvcEnqueue(AgTgTextS3Refused(c), "S3", 0, 0, g_svc_refusal_local, 0, 0);
  }

//+------------------------------------------------------------------+
//| THE PERIODIC STATUS (item 6), also the command's reply           |
//+------------------------------------------------------------------+
string AgSvcStatusText(const datetime now)
  {
   double hb = 0.0, id = 0.0;
   int    live = AgSvcReadLive(hb, id, now);
   bool   runs = (live == AG_SVC_LIVE_FRESH);
   AgTgCommon c;
   AgSvcCommonNow(c, runs);
   long hb_age   = -1;
   long data_age = -1;
   if(runs)
     {
      hb_age = (long)((double)now - hb);
      if(g_svc_have_snap && now - (datetime)g_svc_snap.local_t > AG_SVC_DATA_OLD)
         data_age = (long)(now - (datetime)g_svc_snap.local_t);
     }
   else if(live == AG_SVC_LIVE_STALE)
      hb_age = (long)((double)now - hb);
   return AgTgTextStatus(c, hb_age, data_age,
                         g_svc_have_snap ? (datetime)g_svc_snap.locked_until : 0,
                         g_svc_have_snap ? g_svc_snap.enforced_limit : 0.0);
  }

//--- TG-15 (A): the local clock's 4 hour slots; a slot missed while the
//--- service did not run is not sent late
void AgSvcStatusSlot(const datetime now)
  {
   long slot = AgTgStatusSlot((long)now);
   if(g_svc_last_slot == 0)
     {
      g_svc_last_slot = slot;
      return;
     }
   if(slot == g_svc_last_slot)
      return;
   g_svc_last_slot = slot;
   AgSvcEnqueue(AgSvcStatusText(now), "STATUS", 0, 0, (long)now, 0, 0);
  }

//+------------------------------------------------------------------+
//| THE NETWORK. One request per loop at most, every one with the    |
//| timeout constant; the guardian waits on none of them.            |
//+------------------------------------------------------------------+
int AgSvcRequest(const string method, const string url, const string headers, const string body,
                 const int timeout_ms, string &answer, int &err, int &ms)
  {
   char data[];
   char result[];
   string result_headers = "";
   if(body != "")
      AgTgUtf8Bytes(body, data);
   ResetLastError();
   uint t0 = GetTickCount();
   int code = WebRequest(method, url, headers, timeout_ms, data, result, result_headers);
   ms  = (int)(GetTickCount() - t0);
   err = (code == -1) ? GetLastError() : 0;
   answer = AgTgUtf8ToString(result, ArraySize(result));
   return code;
  }

//--- one sendMessage; true when Telegram took it
bool AgSvcSendText(const string text, const long seq, const string cls, const int timeout_ms, const datetime now)
  {
   string url  = "https://api.telegram.org/bot" + TelegramToken + "/sendMessage";
   string body = "{\"chat_id\":\"" + TelegramChatId + "\",\"text\":\"" + AgJsonEscape(text)
               + "\",\"disable_web_page_preview\":true}";
   string answer = "";
   int    err = 0, ms = 0;
   int    http = AgSvcRequest("POST", url, "Content-Type: application/json; charset=utf-8\r\n",
                              body, timeout_ms, answer, err, ms);
   g_svc_next_send = now + AG_SVC_SEND_GAP;
   if(http == 200)
     {
      AgInfo(AgTgSentLine(seq, cls, http, ms));
      g_svc_fail_count    = 0;
      g_svc_backoff_until = 0;
      return true;
     }
   AgInfo(AgTgFailedLine(seq, cls, http, err, ms));
   if(http == 429)
      g_svc_retry_until = now + AgTgRetryAfter(answer) + 1;
   if(g_svc_fail_since == 0)
      g_svc_fail_since = now;
   g_svc_fail_count++;
   int wait = 1;
   for(int i = 0; i < g_svc_fail_count && wait < AG_SVC_BACKOFF_MAX; i++)
      wait *= 2;
   g_svc_backoff_until = now + MathMin(wait, AG_SVC_BACKOFF_MAX);
   return false;
  }

//--- the oldest waiting message, with its closing lines rendered now
bool AgSvcSendFirst(const datetime now, const int timeout_ms)
  {
   long delay = (long)now - g_out_local[0];
   string text = AgTgFinish(g_out_text[0], g_out_notkept[0], g_out_heldback[0],
                            delay > AG_SVC_DELAY_SECONDS ? delay : 0, AgSvcBuildLine());
   if(!AgSvcSendText(text, g_out_seq[0], g_out_cls[0], timeout_ms, now))
      return false;
   if(g_out_ack[0] > 0)
      AgSvcAck(g_out_ack[0]);
   AgSvcDropFirst();
   return true;
  }

void AgSvcPing(const datetime now)
  {
   g_svc_last_ping = now;
   string answer = "";
   int    err = 0, ms = 0;
   int    http = AgSvcRequest("GET", NetworkHeartbeatUrl, "", "", AG_SVC_TIMEOUT_MS, answer, err, ms);
   if(http != 200)
      AgInfo(AgTgFailedLine(0, "ping", http, err, ms));
   else if(g_svc_last_ping_log == 0 || now - g_svc_last_ping_log >= AG_SVC_PING_LOG_SECONDS)
     {
      AgInfo(AgTgPingLine(http, ms));
      g_svc_last_ping_log = now;
     }
  }

void AgSvcPoll(const datetime now)
  {
   g_svc_last_poll = now;
   string url = "https://api.telegram.org/bot" + TelegramToken + "/getUpdates?offset="
              + (string)g_svc_offset + "&timeout=0&allowed_updates=%5B%22message%22%5D";
   string answer = "";
   int    err = 0, ms = 0;
   int    http = AgSvcRequest("GET", url, "", "", AG_SVC_TIMEOUT_MS, answer, err, ms);
   if(http != 200)
     {
      //--- 409: a webhook on the bot or a second poller; clearing it is the
      //--- owner's act. Every failure backs the poll off, up to 300 s.
      AgInfo(AgTgFailedLine(0, "poll", http, err, ms));
      g_svc_poll_interval = MathMin(g_svc_poll_interval * 2, AG_SVC_BACKOFF_MAX);
      return;
     }
   g_svc_poll_interval = AG_SVC_POLL_SECONDS;
   long max_id  = -1;
   int  ignored = 0;
   bool ok      = false;
   int  matched = AgTgMatchCommands(answer, AgTgCommandText(), TelegramChatId, (long)TimeGMT(),
                                    AG_SVC_COMMAND_MAX_AGE, max_id, ignored, ok);
   if(!ok)
     {
      AgInfo(AgTgFailedLine(0, "poll", http, -1, ms));
      return;
     }
   if(max_id >= 0)
      g_svc_offset = max_id + 1;   // the next poll confirms everything returned
   if(matched + ignored > 0)
      AgInfo(AgTgInboundLine(matched, ignored));
   if(matched > 0)
      AgSvcEnqueue(AgSvcStatusText(now), "REPLY", 0, 0, (long)now, 0, 0);   // several commands, one reply
  }

void AgSvcNetwork(const datetime now)
  {
   bool send_ready = g_svc_tg_on && now >= g_svc_next_send && now >= g_svc_retry_until
                     && now >= g_svc_backoff_until;
   //--- after a Telegram outage of 60 s or more the S11 notice goes first,
   //--- then the backlog, oldest first; a shorter outage just resumes
   if(send_ready && g_svc_fail_since != 0 && now - g_svc_fail_since >= AG_SVC_S11_SECONDS)
     {
      AgTgCommon c;
      AgSvcCommonNow(c, g_svc_live == AG_SVC_LIVE_FRESH);
      string text = AgTgFinish(AgTgTextS11(c, g_svc_fail_since, now, g_out_count), 0, 0, 0, AgSvcBuildLine());
      if(AgSvcSendText(text, 0, "S11", AG_SVC_TIMEOUT_MS, now))
         g_svc_fail_since = 0;
      return;
     }
   if(send_ready && g_out_count > 0)
     {
      if(AgSvcSendFirst(now, AG_SVC_TIMEOUT_MS))
         g_svc_fail_since = 0;
      return;
     }
   //--- the network heartbeat, only while the guardian's timer runs (item 3)
   if(g_svc_ping_on && g_svc_live == AG_SVC_LIVE_FRESH && now - g_svc_last_ping >= AG_SVC_PING_SECONDS)
     {
      AgSvcPing(now);
      return;
     }
   if(g_svc_cmd_on && now - g_svc_last_poll >= g_svc_poll_interval)
      AgSvcPoll(now);
  }

//+------------------------------------------------------------------+
//| THE LOOP (1.13)                                                  |
//+------------------------------------------------------------------+
void AgSvcStartLogin(const long login)
  {
   g_svc_login        = login;
   g_ag_login         = login;   // Persist.mqh's names: AgGvHeartbeat, AgGvInstance
   double ack         = 0.0;
   GlobalVariableGet(AgGvTgAck(login), ack);
   g_svc_ack          = (long)ack;
   g_svc_enq_upto     = g_svc_ack;
   g_svc_have_snap    = false;
   g_svc_snap_build   = "";
   g_svc_event_count  = 0;
   ArrayResize(g_svc_events, 0);
   g_svc_consumed_count = 0;
   ArrayResize(g_svc_consumed, 0);
   g_svc_hold         = false;
   g_svc_last_s2_local = 0;
   g_out_count        = 0;
   ArrayResize(g_out_text, 0);
   ArrayResize(g_out_cls, 0);
   ArrayResize(g_out_seq, 0);
   ArrayResize(g_out_ack, 0);
   ArrayResize(g_out_local, 0);
   ArrayResize(g_out_notkept, 0);
   ArrayResize(g_out_heldback, 0);
   g_svc_live         = AG_SVC_LIVE_UNKNOWN;
   g_svc_seen_fresh   = false;
   g_svc_alerted      = false;
   g_svc_s14_anchor   = 0;
   g_svc_lock_count   = 0;
   ArrayResize(g_svc_lock_times, 0);
  }

void AgSvcLoop()
  {
   long login = AccountInfoInteger(ACCOUNT_LOGIN);
   if(login <= 0)
      return;   // not logged in yet
   if(login != g_svc_login)
      AgSvcStartLogin(login);
   datetime now = TimeLocal();
   double hb = 0.0, id = 0.0;
   int live = AgSvcReadLive(hb, id, now);   // the mutex heartbeat first, then the queue
   AgSvcReadQueue();
   //--- with Telegram off nothing is converted, reported or acknowledged, so
   //--- the guardian's queue keeps its own bound and a later start with
   //--- Telegram on still finds what it holds
   if(g_svc_tg_on)
     {
      AgSvcReadRefusal();
      AgSvcConvert(now);
     }
   AgSvcLiveness(live, hb, id, now);
   AgSvcReportRefusal();
   AgSvcStatusSlot(now);
   AgSvcNetwork(now);
  }

//--- at the stop signal, one last pass: an unsent stop at a terminal close,
//--- reason 9, gets one attempt with the option's own 1500 ms (TG-13 (B))
void AgSvcFinalPass()
  {
   if(!g_svc_tg_on || g_svc_login <= 0)
      return;
   datetime now = TimeLocal();
   if(now < g_svc_retry_until)
      return;
   AgSvcReadQueue();
   for(int i = 0; i < g_svc_event_count; i++)
     {
      AgTgEvent e = g_svc_events[i];
      if(e.code != AG_TG_S2 || (int)e.x[0] != 9 || e.seq <= g_svc_ack)
         continue;
      long delay = (long)now - e.local_t;
      string text = AgTgFinish(AgSvcRender(e), 0, 0, delay > AG_SVC_DELAY_SECONDS ? delay : 0, AgSvcBuildLine());
      //--- acknowledged only when nothing older waits, so nothing is skipped
      if(AgSvcSendText(text, e.seq, "S2", AG_SVC_FINAL_TIMEOUT_MS, now) && i == 0 && g_out_count == 0)
         AgSvcAck(e.seq);
      return;
     }
  }

void OnStart()
  {
   g_svc_started = TimeLocal();
   long login = AccountInfoInteger(ACCOUNT_LOGIN);
   bool token_empty = (TelegramToken == "");
   bool chat_empty  = (TelegramChatId == "");
   bool url_empty   = (NetworkHeartbeatUrl == "");
   bool token_ok    = AgTgTokenValid(TelegramToken);
   bool chat_ok     = AgTgChatIdValid(TelegramChatId);
   bool url_ok      = AgTgPingUrlValid(NetworkHeartbeatUrl);
   string telegram  = (token_empty || chat_empty) ? "off:empty"
                      : ((token_ok && chat_ok) ? "on" : "off:malformed");
   string heartbeat = AgTgChannelState(url_empty, url_ok);
   g_svc_tg_on   = (telegram == "on");
   g_svc_cmd_on  = g_svc_tg_on;
   g_svc_ping_on = (heartbeat == "on");
   if(!token_empty && !token_ok)
      AgWarn("alerts config|TelegramToken is malformed, Telegram is off; the guardian is unaffected");
   if(!chat_empty && !chat_ok)
      AgWarn("alerts config|TelegramChatId is malformed, Telegram is off; the guardian is unaffected");
   if(!url_empty && !url_ok)
      AgWarn("alerts config|NetworkHeartbeatUrl is malformed, the network heartbeat is off; the guardian is unaffected");
   AgInfo(AgTgServiceStartedLine(AG_SVC_BUILD_LABEL, login, telegram, heartbeat, g_svc_cmd_on ? "on" : "off"));

   while(!IsStopped())
     {
      AgSvcLoop();
      Sleep(1000);
     }
   AgSvcFinalPass();
   AgInfo(AgTgStoppingLine(g_out_count + g_svc_event_count));
  }
