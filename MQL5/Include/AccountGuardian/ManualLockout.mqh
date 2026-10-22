//+------------------------------------------------------------------+
//| AccountGuardian - ManualLockout.mqh                              |
//| The Manual Lockout, rulings ML-1 to ML-27 of 2026-10-22: a lock  |
//| the trader engages on demand from the chart. A SECOND LOCK       |
//| COMPONENT beside the loss lock, with its own model, record and   |
//| GV mirror. Nothing here writes locked_until, the lock reason,    |
//| the state file or any bound of the loss lock (ML-9): the account |
//| is LOCKED while either holds, and the later end governs (ML-7).  |
//| The only bound of a lockout's end is the next day anchor (ML-4,  |
//| ML-11). Pure helpers, the record's own file I/O, and the journal |
//| line and ALERT formatters (ML-21). No GV call and no trade call. |
//| It reads no clock: every instant is an argument, from            |
//| AgServerNow in the caller (Q7). Shared by the EA, the panel and  |
//| the vectors script.                                              |
//+------------------------------------------------------------------+
#ifndef AG_MANUAL_LOCKOUT_MQH
#define AG_MANUAL_LOCKOUT_MQH

//--- AgAtomicWrite, AgChecksum, AgStateQuarantinePath, AG_FILES_DIR and
//--- g_ag_login; Persist.mqh pulls in Log, Clock, State and Pnl
#include <AccountGuardian/Persist.mqh>

#define AG_MANUAL_MAGIC              "AGMANUAL"
#define AG_MANUAL_FORMAT_VERSION     1
#define AG_MANUAL_REASON_NAME        "MANUAL_LOCKOUT"   // a display name, never a lock reason value
#define AG_MANUAL_MIN_AHEAD_SECONDS  60                 // ML-14: an end time under 60 s ahead is refused
#define AG_MANUAL_REVIEW_TICKS       60                 // ML-15: the review cancels itself after 60 timer ticks

//--- how the trader set the end (ML-5, ML-13, ML-14)
#define AG_ML_FORM_NONE        0
#define AG_ML_FORM_DURATION    1   // a preset or custom whole minutes, from the confirmation
#define AG_ML_FORM_END_OF_DAY  2   // End of session: the next daily anchor
#define AG_ML_FORM_END_TIME    3   // HH:MM server time

//--- the outcome of a check; each refusal has its journal name (ML-21)
#define AG_ML_OK           0
#define AG_ML_PAST_ANCHOR  1
#define AG_ML_TOO_SOON     2
#define AG_ML_NOT_LATER    3
#define AG_ML_STATE        4
#define AG_ML_INPUT        5
#define AG_ML_NOT_LOADED   6

//--- the model, in memory. The record is written only after a load or an
//--- engagement: never loaded never written, applied to this record by name.
bool     g_ag_ml_loaded         = false;
bool     g_ag_ml_active         = false;
datetime g_ag_ml_first_engaged  = 0;   // the confirmation that started this lockout
datetime g_ag_ml_engaged        = 0;   // the latest confirmation, an extension included
datetime g_ag_ml_end            = 0;
int      g_ag_ml_form           = AG_ML_FORM_NONE;
int      g_ag_ml_minutes        = 0;

string AgManualPath() { return AG_FILES_DIR + "\\manual_" + (string)g_ag_login + ".dat"; }
//--- the mirror carries the bare end, 0 when no lockout holds
string AgGvManual()   { return "AG_MANUAL_" + (string)g_ag_login; }

//+------------------------------------------------------------------+
//| THE BOUNDS. Pure functions of their arguments. The one bound is  |
//| AgNextDayAnchor, so no second day boundary exists here and no    |
//| bound of the loss lock is reached (ML-4, ML-9).                  |
//+------------------------------------------------------------------+
datetime AgManualMaxEnd(const datetime t) { return AgNextDayAnchor(t); }

datetime AgManualEndOfMinutes(const datetime t, const int minutes) { return t + minutes * 60; }

datetime AgManualEndOfDay(const datetime t) { return AgNextDayAnchor(t); }

//--- ML-14: the first instant at HH:MM:00 server after t, counted from the
//--- day anchor, so that no midnight arithmetic exists
datetime AgManualEndAtTime(const datetime t, const int hh, const int mm)
  {
   int      offset    = (hh * 3600 + mm * 60 - AG_DAY_ANCHOR_OFFSET_SECONDS + 86400) % 86400;
   datetime candidate = AgDayAnchor(t) + offset;
   if(candidate <= t)
      candidate += 86400;
   return candidate;
  }

datetime AgManualEndFor(const datetime t, const int form, const int minutes, const int hh, const int mm)
  {
   if(form == AG_ML_FORM_DURATION)
      return AgManualEndOfMinutes(t, minutes);
   if(form == AG_ML_FORM_END_OF_DAY)
      return AgManualEndOfDay(t);
   if(form == AG_ML_FORM_END_TIME)
      return AgManualEndAtTime(t, hh, mm);
   return 0;
  }

//--- every check an end takes, against the confirmation instant t: after t,
//--- at least 60 s after it for an end time (ML-14), no later than the next
//--- daily anchor of t (ML-4, ML-11), and later than the current effective
//--- end while any lock holds (ML-10); current_end is 0 when none holds
int AgManualCheckEnd(const datetime t, const datetime end, const int form, const datetime current_end)
  {
   if(end <= t)
      return AG_ML_TOO_SOON;
   if(form == AG_ML_FORM_END_TIME && end - t < AG_MANUAL_MIN_AHEAD_SECONDS)
      return AG_ML_TOO_SOON;
   if(end > AgManualMaxEnd(t))
      return AG_ML_PAST_ANCHOR;
   if(current_end > 0 && end <= current_end)
      return AG_ML_NOT_LATER;
   return AG_ML_OK;
  }

//--- ML-7: the later end governs
datetime AgManualEffectiveEnd(const datetime loss_until, const bool ml_active, const datetime ml_end)
  {
   datetime manual = ml_active ? ml_end : (datetime)0;
   return (manual > loss_until) ? manual : loss_until;
  }

//--- the lockout governs while it holds and no loss lock ends later
bool AgManualGoverns(const bool loss_holds, const datetime loss_until, const bool ml_active, const datetime ml_end)
  {
   return ml_active && (!loss_holds || ml_end > loss_until);
  }

//--- an active record is in bounds when its end lies after its latest
//--- confirmation and no later than the next anchor of its first (ML-11)
bool AgManualRecordInBounds(const datetime first, const datetime engaged, const datetime end)
  {
   return first > 0 && engaged >= first && end > engaged && end <= AgNextDayAnchor(first);
  }

//--- the lockout's boot witness, pure. The record fires when it is active
//--- and ends after now, the mirror when its end is after now; the later
//--- end governs, cut to the next anchor of now, the clamp's own ceiling,
//--- with no floor after it (ML-9). source: bit 1 the record, bit 2 the GV.
bool AgManualBootWitness(const datetime now, const bool rec_active, const datetime rec_end,
                         const datetime gv_end, datetime &end_out, int &source_out)
  {
   end_out    = 0;
   source_out = 0;
   if(rec_active && rec_end > now)
     {
      end_out    = rec_end;
      source_out = 1;
     }
   if(gv_end > now)
     {
      if(gv_end > end_out)
         end_out = gv_end;
      source_out |= 2;
     }
   if(source_out == 0)
      return false;
   datetime ceiling = AgNextDayAnchor(now);
   if(end_out > ceiling)
      end_out = ceiling;
   return true;
  }

//+------------------------------------------------------------------+
//| THE TWO FIELD PARSERS. Character codes only: no entry indexes an |
//| array or divides, so nothing a trader types can raise a runtime  |
//| error, which would stop the timer and the sweep with it.         |
//+------------------------------------------------------------------+
bool AgManualIsDigit(const ushort ch) { return ch >= '0' && ch <= '9'; }

//--- custom whole minutes: 1 to 4 digits, at least 1 (ML-13)
bool AgManualParseMinutes(const string text, int &minutes)
  {
   minutes = 0;
   string s = text;
   StringTrimLeft(s);
   StringTrimRight(s);
   int n = StringLen(s);
   if(n < 1 || n > 4)
      return false;
   int value = 0;
   for(int i = 0; i < n; i++)
     {
      ushort ch = StringGetCharacter(s, i);
      if(!AgManualIsDigit(ch))
         return false;
      value = value * 10 + (int)(ch - '0');
     }
   if(value < 1)
      return false;
   minutes = value;
   return true;
  }

//--- an end time: exactly HH:MM, hours 00 to 23, minutes 00 to 59 (ML-14)
bool AgManualParseHhMm(const string text, int &hh, int &mm)
  {
   hh = 0;
   mm = 0;
   string s = text;
   StringTrimLeft(s);
   StringTrimRight(s);
   if(StringLen(s) != 5 || StringGetCharacter(s, 2) != ':')
      return false;
   ushort h1 = StringGetCharacter(s, 0);
   ushort h2 = StringGetCharacter(s, 1);
   ushort m1 = StringGetCharacter(s, 3);
   ushort m2 = StringGetCharacter(s, 4);
   if(!AgManualIsDigit(h1) || !AgManualIsDigit(h2) || !AgManualIsDigit(m1) || !AgManualIsDigit(m2))
      return false;
   int hours   = (int)(h1 - '0') * 10 + (int)(h2 - '0');
   int minutes = (int)(m1 - '0') * 10 + (int)(m2 - '0');
   if(hours > 23 || minutes > 59)
      return false;
   hh = hours;
   mm = minutes;
   return true;
  }

//+------------------------------------------------------------------+
//| THE LINES AND THE ALERTS (ML-21), pure functions of their        |
//| arguments, server time as YYYY.MM.DD HH:MM:SS                    |
//+------------------------------------------------------------------+
string AgManualStamp(const datetime t) { return TimeToString(t, TIME_DATE | TIME_SECONDS); }

//--- the remaining time on the panel, h:mm:ss, never below zero (ML-16)
string AgManualHms(const long seconds)
  {
   long s = (seconds < 0) ? (long)0 : seconds;
   long h = s / 3600;
   long m = (s % 3600) / 60;
   long x = s % 60;
   return (string)h + ":" + (m < 10 ? "0" : "") + (string)m + ":" + (x < 10 ? "0" : "") + (string)x;
  }

string AgManualFormName(const int form)
  {
   switch(form)
     {
      case AG_ML_FORM_DURATION:   return "duration";
      case AG_ML_FORM_END_OF_DAY: return "end_of_session";
      case AG_ML_FORM_END_TIME:   return "end_time";
     }
   return "none";
  }

string AgManualRefuseName(const int outcome)
  {
   switch(outcome)
     {
      case AG_ML_PAST_ANCHOR: return "past the next daily anchor";
      case AG_ML_TOO_SOON:    return "too soon";
      case AG_ML_NOT_LATER:   return "not later than the current lock";
      case AG_ML_STATE:       return "not available in this state";
      case AG_ML_INPUT:       return "entry not understood";
      case AG_ML_NOT_LOADED:  return "record not loaded";
     }
   return "-";
  }

string AgManualPanelLine(const string what, const int form, const datetime end, const datetime now)
  {
   return "manual lockout panel|" + what + "|form=" + AgManualFormName(form)
        + "|end=" + AgManualStamp(end) + "|server=" + AgManualStamp(now);
  }

string AgManualPanelTimedOutLine(const datetime now)
  {
   return "manual lockout panel|review timed out|server=" + AgManualStamp(now);
  }

string AgManualRefusedLine(const string why, const string at, const string state, const int form,
                           const datetime requested_end, const datetime now)
  {
   return "manual lockout refused|why=" + why + "|at=" + at + "|state=" + state
        + "|form=" + AgManualFormName(form) + "|requested_end=" + AgManualStamp(requested_end)
        + "|server=" + AgManualStamp(now);
  }

string AgManualEngagedLine(const int form, const int minutes, const datetime engaged, const datetime end,
                           const datetime next_anchor, const int positions, const int pendings)
  {
   return "manual lockout engaged|form=" + AgManualFormName(form) + "|minutes=" + (string)minutes
        + "|engaged=" + AgManualStamp(engaged) + "|end=" + AgManualStamp(end)
        + "|next_anchor=" + AgManualStamp(next_anchor) + "|positions=" + (string)positions
        + "|pendings=" + (string)pendings;
  }

string AgManualExtendedLine(const datetime from, const datetime to, const int form, const int minutes,
                            const datetime engaged)
  {
   return "manual lockout extended|from=" + AgManualStamp(from) + "|to=" + AgManualStamp(to)
        + "|form=" + AgManualFormName(form) + "|minutes=" + (string)minutes
        + "|engaged=" + AgManualStamp(engaged);
  }

string AgManualEndedUnderLossLine(const datetime end, const datetime locked_until, const datetime now)
  {
   return "manual lockout ended, the loss lock holds|end=" + AgManualStamp(end)
        + "|locked_until=" + AgManualStamp(locked_until) + "|server=" + AgManualStamp(now);
  }

string AgManualExpiredLine(const datetime end, const datetime now)
  {
   return "manual lockout expired|end=" + AgManualStamp(end) + "|server=" + AgManualStamp(now);
  }

string AgManualLoadedLine(const bool active, const datetime end)
  {
   return "manual lockout record loaded|active=" + (active ? "1" : "0") + "|end=" + AgManualStamp(end)
        + "|weighed by the boot witness at the SYNCING exit";
  }

string AgManualGvInitLine(const datetime raw)
  {
   return "manual lockout GV mirror at init|raw=" + AgManualStamp(raw)
        + "|weighed by the boot witness at the SYNCING exit";
  }

string AgManualBootFiredLine(const int source, const datetime record, const datetime gv, const datetime end)
  {
   string from = (source == 3) ? "file+gv" : ((source == 2) ? "gv" : "file");
   return "boot witness MANUAL fired|source=" + from + "|record=" + AgManualStamp(record)
        + "|gv=" + AgManualStamp(gv) + "|end=" + AgManualStamp(end);
  }

string AgManualHoldsLine(const datetime end, const datetime locked_until, const bool manual_governs)
  {
   return "manual lockout holds with the boot lock|end=" + AgManualStamp(end)
        + "|locked_until=" + AgManualStamp(locked_until)
        + "|governing=" + (manual_governs ? AG_MANUAL_REASON_NAME : "loss lock");
  }

string AgManualRewrittenLine(const string why) { return "manual lockout record rewritten|why=" + why; }

string AgManualQuarantinedLine(const string why, const string bad)
  {
   return "manual lockout record " + why + ", quarantined as " + bad
        + ", the AG_MANUAL mirror alone decides at the SYNCING exit (ML-19)";
  }

//--- the transition's numbers, and the LOCKED LIFE field appended after the
//--- sweep field, outside the six D2D4 fields (ML-16)
string AgManualEndField(const datetime end) { return "manual_end=" + AgManualStamp(end); }
string AgManualLifeField(const datetime end) { return "|" + AgManualEndField(end); }

string AgManualEngageAlert(const datetime end, const int positions, const int pendings)
  {
   return AG_MANUAL_REASON_NAME + ": account LOCKED until " + AgManualStamp(end)
        + ". Flattening " + (string)positions + " positions and deleting "
        + (string)pendings + " pending orders.";
  }

string AgManualExtendAlert(const datetime end)
  {
   return AG_MANUAL_REASON_NAME + ": lockout extended until " + AgManualStamp(end) + ".";
  }

string AgManualBootAlert(const datetime end, const int positions, const int pendings)
  {
   return "LOCKED at boot by derivation (" + AG_MANUAL_REASON_NAME + ") until " + AgManualStamp(end)
        + ". Flattening " + (string)positions + " positions and deleting "
        + (string)pendings + " pending orders.";
  }

//+------------------------------------------------------------------+
//| THE RECORD, manual_<login>.dat (ML-18). Magic AGMANUAL, distinct |
//| from every other file's, so no two formats can cross-read:       |
//|   AGMANUAL|1|<login>                                             |
//|   M|<active 0 or 1>|<first>|<engaged>|<end>|<form>|<minutes>     |
//|   C|<FNV-1a of the two lines above>                              |
//+------------------------------------------------------------------+
string AgManualSerialize(const long login, const bool active, const datetime first, const datetime engaged,
                         const datetime end, const int form, const int minutes)
  {
   string body = AG_MANUAL_MAGIC + "|" + (string)AG_MANUAL_FORMAT_VERSION + "|" + (string)login + "\n";
   body += "M|" + (active ? "1" : "0") + "|" + (string)((long)first) + "|" + (string)((long)engaged)
         + "|" + (string)((long)end) + "|" + (string)form + "|" + (string)minutes + "\n";
   body += "C|" + (string)AgChecksum(body) + "\n";
   return body;
  }

string AgManualSerializeModel()
  {
   return AgManualSerialize(g_ag_login, g_ag_ml_active, g_ag_ml_first_engaged, g_ag_ml_engaged,
                            g_ag_ml_end, g_ag_ml_form, g_ag_ml_minutes);
  }

//--- 0 parsed; 2 corrupt: cut, an extra line, the checksum, the header or the
//--- M line; 3 another login; 4 active and past the next anchor of its first
//--- confirmation. Every refusal leaves the outputs inactive.
int AgManualParse(const string text, const long login, bool &active, datetime &first, datetime &engaged,
                  datetime &end, int &form, int &minutes)
  {
   active  = false;
   first   = 0;
   engaged = 0;
   end     = 0;
   form    = AG_ML_FORM_NONE;
   minutes = 0;
   string t = text;
   StringReplace(t, "\r", "");
   string lines[];
   int count = StringSplit(t, '\n', lines);
   if(count < 3)
      return 2;
   for(int i = 3; i < count; i++)
      if(lines[i] != "")
         return 2;
   string body = lines[0] + "\n" + lines[1] + "\n";
   if(lines[2] != "C|" + (string)AgChecksum(body))
      return 2;
   string header[];
   if(StringSplit(lines[0], '|', header) != 3 || header[0] != AG_MANUAL_MAGIC
      || header[1] != (string)AG_MANUAL_FORMAT_VERSION
      || (string)StringToInteger(header[2]) != header[2])
      return 2;
   string f[];
   if(StringSplit(lines[1], '|', f) != 7 || f[0] != "M" || (f[1] != "0" && f[1] != "1"))
      return 2;
   if(StringToInteger(header[2]) != login)
      return 3;
   bool     a  = (f[1] == "1");
   datetime fi = (datetime)StringToInteger(f[2]);
   datetime en = (datetime)StringToInteger(f[3]);
   datetime ed = (datetime)StringToInteger(f[4]);
   if(a && !AgManualRecordInBounds(fi, en, ed))
      return 4;
   active  = a;
   first   = fi;
   engaged = en;
   end     = ed;
   form    = (int)StringToInteger(f[5]);
   minutes = (int)StringToInteger(f[6]);
   return 0;
  }

//--- the record's text, its lines joined with "\n", read as the state file's
//--- loader reads its own; false when the file cannot be opened
bool AgManualReadText(const string path, string &text)
  {
   text = "";
   int handle = FileOpen(path, FILE_READ | FILE_TXT | FILE_ANSI);
   if(handle == INVALID_HANDLE)
      return false;
   while(!FileIsEnding(handle))
      text += FileReadString(handle) + "\n";
   FileClose(handle);
   return true;
  }

//--- the same record, line ends aside
bool AgManualSameRecord(const string a, const string b)
  {
   string x = a;
   string y = b;
   StringReplace(x, "\r", "");
   StringReplace(y, "\r", "");
   return x == y;
  }

void AgManualResetModel()
  {
   g_ag_ml_active        = false;
   g_ag_ml_first_engaged = 0;
   g_ag_ml_engaged       = 0;
   g_ag_ml_end           = 0;
   g_ag_ml_form          = AG_ML_FORM_NONE;
   g_ag_ml_minutes       = 0;
  }

//--- the record through the atomic path, loud on failure (SPEC 3); refused,
//--- loudly, while the model was never loaded this session
bool AgManualSave()
  {
   if(!g_ag_ml_loaded)
     {
      AgWarn("manual lockout record NOT written: the model was never loaded this session,"
             " so writing it would overwrite a real lockout with an empty one");
      return false;
     }
   return AgAtomicWrite(AgManualPath(), AgManualSerializeModel());
  }

//--- ML-19 (A): a record that cannot be trusted is moved aside under a free
//--- quarantine name, never deleted; the model is reset and a fresh inactive
//--- record written, and the GV mirror alone decides at the SYNCING exit
int AgManualQuarantine(const string path, const int code, const string why)
  {
   string bad = AgStateQuarantinePath(path);
   if(!FileMove(path, 0, bad, FILE_REWRITE))
      AgWarn("manual lockout record quarantine move FAILED onto " + bad + ", error " + (string)GetLastError()
             + "; the fresh record below overwrites it in place");
   AgManualResetModel();
   AgWarn(AgManualQuarantinedLine(why, bad));
   AgManualSave();
   return code;
  }

//--- 0 loaded, 1 missing, 2 unreadable or corrupt, 3 another login, 4 past
//--- the bound; 2 to 4 are quarantined. Loaded is set first, as for the
//--- state file: every exit leaves a deliberately initialized model.
int AgManualLoad()
  {
   AgManualResetModel();
   g_ag_ml_loaded = true;
   string path = AgManualPath();
   if(!FileIsExist(path))
      return 1;
   string text = "";
   if(!AgManualReadText(path, text))
      return AgManualQuarantine(path, 2, "cannot be opened");
   bool     active  = false;
   datetime first   = 0;
   datetime engaged = 0;
   datetime end     = 0;
   int      form    = AG_ML_FORM_NONE;
   int      minutes = 0;
   int code = AgManualParse(text, g_ag_login, active, first, engaged, end, form, minutes);
   if(code == 2)
      return AgManualQuarantine(path, 2, "failed checksum or does not parse");
   if(code == 3)
      return AgManualQuarantine(path, 3, "carries another login");
   if(code == 4)
      return AgManualQuarantine(path, 4, "lies past the next anchor of its first confirmation");
   g_ag_ml_active        = active;
   g_ag_ml_first_engaged = first;
   g_ag_ml_engaged       = engaged;
   g_ag_ml_end           = end;
   g_ag_ml_form          = form;
   g_ag_ml_minutes       = minutes;
   return 0;
  }

//--- ML-18 (A), the read back: 0 the record on disk is the model; 1 it was
//--- missing and is written again; 2 it differed, was moved aside under a
//--- free quarantine name, and is written again. The caller sets the cadence.
int AgManualHealRecord()
  {
   string path = AgManualPath();
   if(!FileIsExist(path))
     {
      AgWarn(AgManualRewrittenLine("missing"));
      AgManualSave();
      return 1;
     }
   string text = "";
   if(AgManualReadText(path, text) && AgManualSameRecord(text, AgManualSerializeModel()))
      return 0;
   string bad = AgStateQuarantinePath(path);
   if(!FileMove(path, 0, bad, FILE_REWRITE))
      AgWarn("manual lockout record move aside FAILED onto " + bad + ", error " + (string)GetLastError()
             + "; the record below overwrites it in place");
   AgWarn(AgManualRewrittenLine("differs"));
   AgManualSave();
   return 2;
  }

#endif // AG_MANUAL_LOCKOUT_MQH
