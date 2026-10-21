//+------------------------------------------------------------------+
//| AccountGuardian - AlertQueue.mqh                                 |
//| The alert queue between the guardian and the alerts service,     |
//| TG-1 (B), design addendum items 1 and 2: the event codes, the    |
//| event and snapshot records, the serializer and the parser, the   |
//| pure producer helpers and the new journal line formatters.       |
//| Shared by the EA, the alerts service and the vectors script.     |
//|                                                                  |
//| CODES AND NUMBERS ONLY. No Hebrew, no secret and no URL passes   |
//| through this file or the queue it describes: the Hebrew lives in |
//| AlertText.mqh and is rendered by the service at send time.       |
//| THIS FILE WRITES NOTHING. The one file call here opens the queue |
//| for reading; the EA's writer and its quarantine live in the EA,  |
//| so nothing the service includes from here can write a file.      |
//| No trade calls (static-structure rule, SPEC 1).                  |
//+------------------------------------------------------------------+
#ifndef AG_ALERT_QUEUE_MQH
#define AG_ALERT_QUEUE_MQH

//--- AgChecksum, the checksum convention of the other four files, and
//--- AG_FILES_DIR. Persist.mqh pulls in Log, Clock, State and Pnl.
#include <AccountGuardian/Persist.mqh>

#define AG_TGQ_MAGIC          "AGTGQ"
#define AG_TGQ_FORMAT_VERSION 1
#define AG_TGQ_MAX_EVENTS     50     // plan 6.4.4
#define AG_TGQ_X_COUNT        8

//--- event codes, the plan's catalog rows (addendum 1.11)
#define AG_TG_S1    1
#define AG_TG_S2    2
#define AG_TG_S3    3
#define AG_TG_S4    4
#define AG_TG_S7    7
#define AG_TG_S8    8
#define AG_TG_S9    9
#define AG_TG_S10   10
#define AG_TG_S12   12
#define AG_TG_S15   15
#define AG_TG_S16   16
#define AG_TG_S17   17
#define AG_TG_S18   18
#define AG_TG_S19   19
#define AG_TG_S20   20
#define AG_TG_S21   21
#define AG_TG_S22   22
#define AG_TG_S24   24
#define AG_TG_S6C   61
#define AG_TG_S6H   62
#define AG_TG_S6F   63

//--- the guardian state on the queue is the ENUM_AG_STATE value; the
//--- service adds one more for a guardian that is not running
#define AG_TG_STATE_NOT_RUNNING 5

//--- how the common result line reads (addendum 1.2)
#define AG_TG_PNL_ACTIVE 0   // pnl is the day result, limit the enforced limit
#define AG_TG_PNL_LOCKED 1   // pnl is equity minus base_snap, limit is limit_snap
#define AG_TG_PNL_NONE   2   // not computed yet

//--- one event, a V line. A simple structure: numbers only.
struct AgTgEvent
  {
   long     seq;
   int      code;
   long     server_t;   // TimeCurrent at the event
   long     local_t;    // TimeLocal at the event
   int      state;
   int      pnl_mode;
   double   balance;
   double   equity;
   double   pnl;
   double   limit;
   double   x[8];       // AG_TGQ_X_COUNT, per code (addendum 1.11), unused fields 0
  };

//--- the guardian's state as the service sees it, the N line (addendum 2)
struct AgTgSnapshot
  {
   long     local_t;
   long     server_t;
   int      state;
   int      reason;
   int      seconds_in_state;
   int      connected;
   int      block;
   int      pnl_mode;
   double   balance;
   double   floating;
   double   equity;
   double   pnl;
   double   limit;
   double   live_limit;
   double   enforced_limit;
   double   peak;
   double   peak_level;
   long     anchor;
   long     locked_until;
   double   limit_snap;
   double   base_snap;
   double   percent;
   double   currency;
   int      sweep_open;
   int      sweep_held;
  };

//+------------------------------------------------------------------+
//| Names. The login is a parameter so the service, which follows    |
//| the account, and the vectors use the same helpers as the EA.     |
//+------------------------------------------------------------------+
string AgTgQueuePath(const long login) { return AG_FILES_DIR + "\\tgqueue_" + (string)login + ".dat"; }
string AgGvTgAck(const long login)     { return "AG_TGACK_" + (string)login; }
string AgGvTgRefused(const long login) { return "AG_TGREFUSED_" + (string)login; }
string AgGvTgRefSeen(const long login) { return "AG_TGREFSEEN_" + (string)login; }

string AgTgCodeText(const int code)
  {
   switch(code)
     {
      case AG_TG_S6C: return "S6C";
      case AG_TG_S6H: return "S6H";
      case AG_TG_S6F: return "S6F";
     }
   return "S" + (string)code;
  }

bool AgTgCodeKnown(const int code)
  {
   switch(code)
     {
      case AG_TG_S1:  case AG_TG_S2:  case AG_TG_S3:  case AG_TG_S4:
      case AG_TG_S7:  case AG_TG_S8:  case AG_TG_S9:  case AG_TG_S10:
      case AG_TG_S12: case AG_TG_S15: case AG_TG_S16: case AG_TG_S17:
      case AG_TG_S18: case AG_TG_S19: case AG_TG_S20: case AG_TG_S21:
      case AG_TG_S22: case AG_TG_S24: case AG_TG_S6C: case AG_TG_S6H:
      case AG_TG_S6F:
         return true;
     }
   return false;
  }

//--- digits only, with an optional leading minus
bool AgTgIsInteger(const string s)
  {
   int n = StringLen(s);
   if(n == 0)
      return false;
   int start = (StringGetCharacter(s, 0) == '-') ? 1 : 0;
   if(start == n)
      return false;
   for(int i = start; i < n; i++)
     {
      ushort ch = StringGetCharacter(s, i);
      if(ch < '0' || ch > '9')
         return false;
     }
   return true;
  }

//--- an integer, or digits with one decimal point, optional leading minus
bool AgTgIsNumber(const string s)
  {
   int n = StringLen(s);
   if(n == 0)
      return false;
   int  start  = (StringGetCharacter(s, 0) == '-') ? 1 : 0;
   bool dot    = false;
   int  digits = 0;
   for(int i = start; i < n; i++)
     {
      ushort ch = StringGetCharacter(s, i);
      if(ch == '.')
        {
         if(dot)
            return false;
         dot = true;
         continue;
        }
      if(ch < '0' || ch > '9')
         return false;
      digits++;
     }
   return digits > 0;
  }

int AgTgCodeFromText(const string t)
  {
   if(t == "S6C") return AG_TG_S6C;
   if(t == "S6H") return AG_TG_S6H;
   if(t == "S6F") return AG_TG_S6F;
   if(StringLen(t) < 2 || StringGetCharacter(t, 0) != 'S')
      return 0;
   string digits = StringSubstr(t, 1);
   if(!AgTgIsInteger(digits) || StringGetCharacter(digits, 0) == '-')
      return 0;
   int code = (int)StringToInteger(digits);
   return AgTgCodeKnown(code) ? code : 0;
  }

//--- money at 2 decimals, never a non finite token
string AgTgMoney(const double v)
  {
   if(!MathIsValidNumber(v))
      return "0.00";
   string s = DoubleToString(v, 2);
   if(s == "-0.00")
      s = "0.00";
   return s;
  }

//--- an x field: an integer when the value is whole, else 2 decimals
string AgTgNum(const double v)
  {
   if(!MathIsValidNumber(v))
      return "0";
   double r = MathRound(v);
   if(MathAbs(v - r) < 0.000001 && MathAbs(r) < 1000000000000000.0)
      return (string)(long)r;
   return AgTgMoney(v);
  }

//+------------------------------------------------------------------+
//| THE SERIALIZER, format version 1 (addendum 1.2).                 |
//+------------------------------------------------------------------+
string AgTgEventLine(const AgTgEvent &e)
  {
   string s = "V|" + (string)e.seq + "|" + AgTgCodeText(e.code)
            + "|" + (string)e.server_t + "|" + (string)e.local_t
            + "|" + (string)e.state + "|" + (string)e.pnl_mode
            + "|" + AgTgMoney(e.balance) + "|" + AgTgMoney(e.equity)
            + "|" + AgTgMoney(e.pnl) + "|" + AgTgMoney(e.limit);
   for(int i = 0; i < AG_TGQ_X_COUNT; i++)
      s += "|" + AgTgNum(e.x[i]);
   return s;
  }

//--- build is the label token, capital ASCII letters
string AgTgSnapshotLine(const AgTgSnapshot &n, const string build)
  {
   return "N|" + (string)n.local_t + "|" + (string)n.server_t + "|" + build
        + "|" + (string)n.state + "|" + (string)n.reason + "|" + (string)n.seconds_in_state
        + "|" + (string)n.connected + "|" + (string)n.block + "|" + (string)n.pnl_mode
        + "|" + AgTgMoney(n.balance) + "|" + AgTgMoney(n.floating) + "|" + AgTgMoney(n.equity)
        + "|" + AgTgMoney(n.pnl) + "|" + AgTgMoney(n.limit) + "|" + AgTgMoney(n.live_limit)
        + "|" + AgTgMoney(n.enforced_limit) + "|" + AgTgMoney(n.peak) + "|" + AgTgMoney(n.peak_level)
        + "|" + (string)n.anchor + "|" + (string)n.locked_until
        + "|" + AgTgMoney(n.limit_snap) + "|" + AgTgMoney(n.base_snap)
        + "|" + AgTgMoney(n.percent) + "|" + AgTgMoney(n.currency)
        + "|" + (string)n.sweep_open + "|" + (string)n.sweep_held;
  }

string AgTgQueueSerialize(const long login, const long next_seq, const long latch_anchor,
                          const int s9_mask, const string snapshot_line,
                          const AgTgEvent &events[], const int count)
  {
   string body = AG_TGQ_MAGIC + "|" + (string)AG_TGQ_FORMAT_VERSION + "|" + (string)login + "\n";
   body += "E|" + (string)next_seq + "|" + (string)latch_anchor + "|" + (string)s9_mask + "\n";
   body += snapshot_line + "\n";
   for(int i = 0; i < count; i++)
      body += AgTgEventLine(events[i]) + "\n";
   body += "C|" + (string)AgChecksum(body) + "\n";
   return body;
  }

//+------------------------------------------------------------------+
//| THE PARSER. Acts only on a whole file: the header, E, N and C    |
//| lines must parse and the checksum must verify, else nothing is   |
//| taken (addendum 1.7). Pure on the text the reader returns.       |
//+------------------------------------------------------------------+
bool AgTgEventParse(const string line, AgTgEvent &e)
  {
   string f[];
   if(StringSplit(line, '|', f) != 11 + AG_TGQ_X_COUNT || f[0] != "V")
      return false;
   int code = AgTgCodeFromText(f[2]);
   if(code == 0)
      return false;
   for(int i = 1; i < ArraySize(f); i++)
      if(i != 2 && !AgTgIsNumber(f[i]))
         return false;
   if(!AgTgIsInteger(f[1]) || !AgTgIsInteger(f[3]) || !AgTgIsInteger(f[4])
      || !AgTgIsInteger(f[5]) || !AgTgIsInteger(f[6]))
      return false;
   e.seq      = StringToInteger(f[1]);
   e.code     = code;
   e.server_t = StringToInteger(f[3]);
   e.local_t  = StringToInteger(f[4]);
   e.state    = (int)StringToInteger(f[5]);
   e.pnl_mode = (int)StringToInteger(f[6]);
   e.balance  = StringToDouble(f[7]);
   e.equity   = StringToDouble(f[8]);
   e.pnl      = StringToDouble(f[9]);
   e.limit    = StringToDouble(f[10]);
   for(int i = 0; i < AG_TGQ_X_COUNT; i++)
      e.x[i] = StringToDouble(f[11 + i]);
   return e.seq > 0;
  }

bool AgTgSnapshotParse(const string line, AgTgSnapshot &n, string &build)
  {
   string f[];
   if(StringSplit(line, '|', f) != 27 || f[0] != "N")
      return false;
   for(int i = 1; i < 27; i++)
      if(i != 3 && !AgTgIsNumber(f[i]))
         return false;
   build              = f[3];
   n.local_t          = StringToInteger(f[1]);
   n.server_t         = StringToInteger(f[2]);
   n.state            = (int)StringToInteger(f[4]);
   n.reason           = (int)StringToInteger(f[5]);
   n.seconds_in_state = (int)StringToInteger(f[6]);
   n.connected        = (int)StringToInteger(f[7]);
   n.block            = (int)StringToInteger(f[8]);
   n.pnl_mode         = (int)StringToInteger(f[9]);
   n.balance          = StringToDouble(f[10]);
   n.floating         = StringToDouble(f[11]);
   n.equity           = StringToDouble(f[12]);
   n.pnl              = StringToDouble(f[13]);
   n.limit            = StringToDouble(f[14]);
   n.live_limit       = StringToDouble(f[15]);
   n.enforced_limit   = StringToDouble(f[16]);
   n.peak             = StringToDouble(f[17]);
   n.peak_level       = StringToDouble(f[18]);
   n.anchor           = StringToInteger(f[19]);
   n.locked_until     = StringToInteger(f[20]);
   n.limit_snap       = StringToDouble(f[21]);
   n.base_snap        = StringToDouble(f[22]);
   n.percent          = StringToDouble(f[23]);
   n.currency         = StringToDouble(f[24]);
   n.sweep_open       = (int)StringToInteger(f[25]);
   n.sweep_held       = (int)StringToInteger(f[26]);
   return true;
  }

bool AgTgQueueParse(const string text, long &login, long &next_seq, long &latch_anchor,
                    int &s9_mask, AgTgSnapshot &snap, string &build,
                    AgTgEvent &events[], int &count, string &why)
  {
   count = 0;
   ArrayResize(events, 0);
   why   = "";
   string lines[];
   int n = StringSplit(text, '\n', lines);
   string body = "";
   int c_index = -1;
   for(int i = 0; i < n; i++)
     {
      string l = lines[i];
      int len = StringLen(l);
      if(len > 0 && StringGetCharacter(l, len - 1) == '\r')
         l = StringSubstr(l, 0, len - 1);
      lines[i] = l;
      if(StringFind(l, "C|") == 0)
        {
         c_index = i;
         break;
        }
      body += l + "\n";
     }
   if(c_index < 0)
     {
      why = "no checksum line";
      return false;
     }
   if(lines[c_index] != "C|" + (string)AgChecksum(body))
     {
      why = "checksum mismatch";
      return false;
     }
   if(c_index < 3)
     {
      why = "too few lines";
      return false;
     }
   string h[];
   if(StringSplit(lines[0], '|', h) != 3 || h[0] != AG_TGQ_MAGIC
      || h[1] != (string)AG_TGQ_FORMAT_VERSION || !AgTgIsInteger(h[2]))
     {
      why = "bad header";
      return false;
     }
   login = StringToInteger(h[2]);
   string e[];
   if(StringSplit(lines[1], '|', e) != 4 || e[0] != "E"
      || !AgTgIsInteger(e[1]) || !AgTgIsInteger(e[2]) || !AgTgIsInteger(e[3]))
     {
      why = "bad E line";
      return false;
     }
   next_seq     = StringToInteger(e[1]);
   latch_anchor = StringToInteger(e[2]);
   s9_mask      = (int)StringToInteger(e[3]);
   if(!AgTgSnapshotParse(lines[2], snap, build))
     {
      why = "bad N line";
      return false;
     }
   for(int i = 3; i < c_index; i++)
     {
      AgTgEvent ev;
      if(!AgTgEventParse(lines[i], ev))
        {
         why = "bad V line " + (string)(i + 1);
         return false;
        }
      if(count > 0 && ev.seq <= events[count - 1].seq)
        {
         why = "V lines out of order";
         return false;
        }
      ArrayResize(events, count + 1);
      events[count] = ev;
      count++;
     }
   return true;
  }

//+------------------------------------------------------------------+
//| The reader, shared by the EA's load and the service's loop. Read |
//| only, shared flags, the handle closed at once (addendum 1.4).    |
//| false when the file cannot be opened this moment.                |
//+------------------------------------------------------------------+
bool AgTgQueueReadText(const string path, string &text)
  {
   text = "";
   int handle = FileOpen(path, FILE_READ | FILE_TXT | FILE_ANSI | FILE_SHARE_READ | FILE_SHARE_WRITE);
   if(handle == INVALID_HANDLE)
      return false;
   while(!FileIsEnding(handle))
      text += FileReadString(handle) + "\n";
   FileClose(handle);
   return true;
  }

//+------------------------------------------------------------------+
//| The queue model's pure operations.                               |
//+------------------------------------------------------------------+
//--- forget every event at or below the acknowledgement (addendum 1.6)
int AgTgQueueForget(AgTgEvent &events[], int &count, const long ack)
  {
   int keep = 0;
   for(int i = 0; i < count; i++)
     {
      if(events[i].seq <= ack)
         continue;
      if(keep != i)
         events[keep] = events[i];
      keep++;
     }
   int forgotten = count - keep;
   count = keep;
   ArrayResize(events, count);
   return forgotten;
  }

//--- the bound (addendum 1.12): keep the oldest unacknowledged event and the
//--- newest max_events - 1, forget the ones between; returns how many
int AgTgQueueTrim(AgTgEvent &events[], int &count, const int max_events)
  {
   if(max_events < 2 || count <= max_events)
      return 0;
   int drop = count - max_events;
   for(int i = 1; i < max_events; i++)
      events[i] = events[i + drop];
   count = max_events;
   ArrayResize(events, count);
   return drop;
  }

//--- the Q3 name of an account wide block as its code, 1 to 4 in the
//--- AgTradeBlockName order, 0 when nothing blocks
int AgTgBlockCode(const string name)
  {
   if(name == "TERMINAL_TRADE_ALLOWED=false") return 1;
   if(name == "MQL_TRADE_ALLOWED=false")      return 2;
   if(name == "ACCOUNT_TRADE_ALLOWED=false")  return 3;
   if(name == "ACCOUNT_TRADE_EXPERT=false")   return 4;
   return 0;
  }

//+------------------------------------------------------------------+
//| S9, TG-3 (B): two levels, 50 and 80 percent, each fired once,    |
//| re-armed when the share falls to 10 points below it; every level |
//| re-arms when the anchor advances (the caller clears the mask).   |
//| The share is the plan's: the day reference minus pnl, over the   |
//| enforced limit, the day reference being the peak level plus the  |
//| enforced limit, so 100 percent is exactly the lock level.        |
//+------------------------------------------------------------------+
double AgTgShareUsed(const double peak_level, const double enforced_limit, const double pnl)
  {
   if(enforced_limit <= 0.0)
      return 0.0;
   return (peak_level + enforced_limit - pnl) / enforced_limit * 100.0;
  }

//--- mask bit 1 is the 50 level, bit 2 the 80 level, a set bit meaning
//--- fired and not yet re-armed. Returns the level that fires this pass, or 0.
int AgTgS9Step(const double share_pct, int &mask)
  {
   if((mask & 1) != 0 && share_pct <= 40.0)
      mask &= ~1;
   if((mask & 2) != 0 && share_pct <= 70.0)
      mask &= ~2;
   if(share_pct >= 80.0 && (mask & 2) == 0)
     {
      mask |= 3;
      return 80;
     }
   if(share_pct >= 50.0 && (mask & 1) == 0)
     {
      mask |= 1;
      return 50;
     }
   return 0;
  }

//+------------------------------------------------------------------+
//| THE NEW JOURNAL LINES, pure formatters. None carries a secret or |
//| a URL (plan 6.2.2): no formatter here takes one as an argument.  |
//+------------------------------------------------------------------+
//--- the EA (addendum 1.3, item 8)
string AgTgTradeBlockedLine(const string name, const string guardian)
  {
   return "trading blocked|state=" + name + "|guardian=" + guardian;
  }

string AgTgTradeRestoredLine(const string name, const string guardian)
  {
   return "trading restored|state=" + name + "|guardian=" + guardian;
  }

string AgTgQueueDeferredLine(const int attempts)
  {
   return "alerts queue write deferred|attempts=" + (string)attempts;
  }

string AgTgQueueLoadedLine(const int events, const long next_seq)
  {
   return "alerts queue loaded|events=" + (string)events + "|next_seq=" + (string)next_seq;
  }

string AgTgQueueQuarantinedLine(const string bad_path, const string why)
  {
   return "alerts queue quarantined|as=" + bad_path + "|why=" + why + "|an empty queue starts";
  }

string AgTgQueueOverflowLine(const int forgotten)
  {
   return "alerts queue overflow|forgotten=" + (string)forgotten + "|kept=the oldest and the newest";
  }

//--- the service (addendum 0.4)
string AgTgServiceStartedLine(const string build, const long login, const string telegram,
                              const string network_heartbeat, const string command)
  {
   return "alerts service started|build=" + build + "|login=" + (string)login
        + "|telegram=" + telegram + "|network_heartbeat=" + network_heartbeat
        + "|command=" + command;
  }

string AgTgSentLine(const long seq, const string cls, const int http, const int ms)
  {
   return "alerts sent|seq=" + (string)seq + "|class=" + cls + "|http=" + (string)http
        + "|ms=" + (string)ms;
  }

string AgTgFailedLine(const long seq, const string cls, const int http, const int err, const int ms)
  {
   return "alerts failed|seq=" + (string)seq + "|class=" + cls + "|http=" + (string)http
        + "|err=" + (string)err + "|ms=" + (string)ms;
  }

string AgTgPingLine(const int http, const int ms)
  {
   return "alerts ping|http=" + (string)http + "|ms=" + (string)ms;
  }

string AgTgPingSkippedLine(const string guardian, const int age)
  {
   return "alerts ping skipped|guardian=" + guardian + "|age=" + (string)age;
  }

string AgTgGuardianLine(const string state, const int age)
  {
   return "alerts guardian|state=" + state + "|age=" + (string)age;
  }

string AgTgInboundLine(const int matched, const int ignored)
  {
   return "alerts inbound|matched=" + (string)matched + "|ignored=" + (string)ignored;
  }

string AgTgStoppingLine(const int unsent)
  {
   return "alerts service stopping|unsent=" + (string)unsent;
  }

#endif // AG_ALERT_QUEUE_MQH
