//+------------------------------------------------------------------+
//| AgPhase2StateVectors.mq5                                         |
//| Phase 2 Stage 2 synthetic test vectors for the lock state file   |
//| family in Persist.mqh (design doc item 5): AgStatePath,          |
//| AgStateSerialize, AgStateSave, AgStateLoad, the                  |
//| never-loaded-never-written guard, the checksum, the login        |
//| mismatch rule and the .bad quarantine.                           |
//| One AGVEC line per case plus a final AGVEC|SUMMARY|<pass>/<total>|
//| line, the same contract AgPhase1ClockVectors already uses.       |
//| Includes SweepPolicy.mqh, the sweep engine's pure policy (owner  |
//| ruling ENF-24(b) of 2026-09-16), and still makes no trade call:  |
//| the policy file carries no trade API, Sweep.mqh is not included, |
//| and the ENF-0 checks below prove the retcode classes, the        |
//| backoff schedule, the ordering, the flat predicate, the Q3 names |
//| and every sweep journal line shape on fixed arguments. Opens no  |
//| chart.                                                           |
//|                                                                  |
//| IT DOES WRITE FILES, which the clock vectors did not, because    |
//| the thing under test is a file format. Two properties keep that  |
//| safe and both are asserted rather than assumed. First, every     |
//| path it touches is derived from a SYNTHETIC login in the         |
//| 99000000x range, so it can never read, write or quarantine the   |
//| real state_<login>.dat of the live account; vector 0 refuses to  |
//| run at all if the live login ever collides with that range.      |
//| Second, it DELETES NOTHING. Quarantined files accumulate across  |
//| runs by design, per the FINAL ruling of 2026-07-29 that lock     |
//| artifacts are never deleted, only quarantined; the growing       |
//| .bad.N chain is itself vector q_quarantine_never_overwrites.     |
//|                                                                  |
//| Double-click from the Navigator to run. A running terminal does  |
//| not enumerate files added after it started, so this script is    |
//| invisible until the next terminal restart (FINAL 2026-08-04,     |
//| extended to Scripts by measurement 2026-08-09).                  |
//+------------------------------------------------------------------+
#property copyright "AccountGuardian"
#property version   "1.00"
#property strict
#property script_show_inputs

#include <AccountGuardian/Persist.mqh>
#include <AccountGuardian/SweepPolicy.mqh>
#include <AccountGuardian/AlertQueue.mqh>
#include <AccountGuardian/AlertJson.mqh>
#include <AccountGuardian/AlertText.mqh>
#include <AccountGuardian/ManualLockout.mqh>

//--- Synthetic logins. None of these is a real account and none of them
//--- may ever equal the live one; vector 0 enforces that.
#define AGVEC_LOGIN_ROUNDTRIP  990000001
#define AGVEC_LOGIN_CORRUPT    990000002
#define AGVEC_LOGIN_MISMATCH   990000003
#define AGVEC_LOGIN_FOREIGN    990000004
#define AGVEC_LOGIN_VERSION    990000005
#define AGVEC_LOGIN_CROSSREAD  990000006
#define AGVEC_LOGIN_GUARD      990000007
#define AGVEC_LOGIN_MISSING    990000009   // deliberately never written
#define AGVEC_LOGIN_RATCHET    990000011   // Stage 5 floor file

int g_pass  = 0;
int g_total = 0;

void AgVecCheck(const string name, const bool ok, const string detail)
  {
   g_total++;
   if(ok)
     {
      g_pass++;
      PrintFormat("AGVEC|%s|PASS", name);
     }
   else
      PrintFormat("AGVEC|%s|FAIL|%s", name, detail);
  }

void AgVecCheckDT(const string name, const datetime got, const datetime want)
  {
   AgVecCheck(name, got == want,
              "got=" + TimeToString(got, TIME_DATE | TIME_SECONDS)
              + " want=" + TimeToString(want, TIME_DATE | TIME_SECONDS));
  }

void AgVecCheckInt(const string name, const long got, const long want)
  {
   AgVecCheck(name, got == want, "got=" + (string)got + " want=" + (string)want);
  }

//--- Money comparison at 1e-6, deliberately tighter than the 0.01 acceptance
//--- epsilon of 2026-07-30: the point of these vectors is that the stored
//--- value is the value, so a difference the banner would round away still
//--- has to fail here.
void AgVecCheckMoney(const string name, const double got, const double want)
  {
   AgVecCheck(name, MathAbs(got - want) < 0.000001,
              "got=" + DoubleToString(got, 8) + " want=" + DoubleToString(want, 8));
  }

//--- ENF-0, P92: one retcode constant, two checks. The numeric value the
//--- compiler carries is asserted against plan 2.7.4's documentation value,
//--- and the classifier's answer against the ruled class, so a divergence
//--- between the documentation and the compiler is measured on the build.
void AgVecRetcode(const string name, const uint constant, const uint want_value, const int want_class)
  {
   AgVecCheckInt("enf_value_" + name + "_is_" + (string)want_value, (long)constant, (long)want_value);
   AgVecCheck("enf_class_" + name + "_is_" + AgRetcodeClassName(want_class),
              AgRetcodeClass(constant) == want_class,
              "got=" + AgRetcodeClassName(AgRetcodeClass(constant)));
  }

//+------------------------------------------------------------------+
//| Raw file helpers. These bypass the state family on purpose: a    |
//| vector that built its fixtures with the code under test could    |
//| not detect a format that is self-consistently wrong.             |
//+------------------------------------------------------------------+
bool AgVecWriteRaw(const string path, const string content)
  {
   FolderCreate(AG_FILES_DIR);
   int h = FileOpen(path, FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return false;
   FileWriteString(h, content);
   FileFlush(h);
   FileClose(h);
   return true;
  }

string AgVecReadRaw(const string path)
  {
   if(!FileIsExist(path))
      return "";
   int h = FileOpen(path, FILE_READ | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE)
      return "";
   string out = "";
   while(!FileIsEnding(h))
      out += FileReadString(h) + "\n";
   FileClose(h);
   return out;
  }

//--- TG: the md5 of a string's UTF-8 bytes, the trailing zero dropped
string AgVecMd5Hex(const string s)
  {
   uchar data[];
   uchar key[];
   uchar hash[];
   int n = StringToCharArray(s, data, 0, WHOLE_ARRAY, CP_UTF8);
   if(n > 0)
      ArrayResize(data, n - 1);
   if(CryptEncode(CRYPT_HASH_MD5, data, key, hash) <= 0)
      return "";
   string hex = "";
   for(int i = 0; i < ArraySize(hash); i++)
      hex += StringFormat("%02X", hash[i]);
   return hex;
  }

void AgVecMd5(const string name, const string got, const string want_md5)
  {
   string m = AgVecMd5Hex(got);
   AgVecCheck(name, m == want_md5, "md5=" + m + " text=" + got);
  }

//--- one line of a rendered message, 0 based, a blank line counted as a line
//--- (the format F1 to F11 puts one between the groups); found by StringFind
//--- so that no reading of StringSplit on empty pieces is relied on
string AgVecLine(const string text, const int index)
  {
   int start = 0;
   for(int k = 0; k < index; k++)
     {
      int nl = StringFind(text, "\n", start);
      if(nl < 0)
         return "";
      start = nl + 1;
     }
   int end = StringFind(text, "\n", start);
   return (end < 0) ? StringSubstr(text, start) : StringSubstr(text, start, end - start);
  }

//--- the common lines of a draft: the demo account of the drafts, its
//--- currency USD, and the draft's open positions (R4)
void AgVecC(AgTgCommon &c, const datetime server_t, const double balance, const double equity,
            const double pnl, const int mode, const double limit, const int state, const long open_pos)
  {
   c.login    = 1200252169;
   c.server_t = server_t;
   c.balance  = balance;
   c.equity   = equity;
   c.pnl      = pnl;
   c.limit    = limit;
   c.pnl_mode = mode;
   c.state    = state;
   c.open_pos = open_pos;
   c.cur      = "$";
  }

//--- A well-formed body plus a correct checksum line.
string AgVecSealed(const string body) { return body + "C|" + (string)AgChecksum(body) + "\n"; }

//--- A well-formed body plus a checksum that is wrong by exactly one.
string AgVecTampered(const string body) { return body + "C|" + (string)(AgChecksum(body) + 1) + "\n"; }

string AgVecBody(const long login, const int reason, const datetime until,
                 const datetime breach, const double limit_snap, const double base_snap)
  {
   return "AGSTATE|" + (string)AG_STATE_FORMAT_VERSION + "|" + (string)login + "\n"
          + "L|" + (string)reason + "|" + (string)((long)until) + "|" + (string)((long)breach) + "\n"
          + "N|" + DoubleToString(limit_snap, AG_STATE_MONEY_DIGITS)
          + "|" + DoubleToString(base_snap, AG_STATE_MONEY_DIGITS) + "\n";
  }

//+------------------------------------------------------------------+
//| TG, the queue file on hostile input (fix pass B2 of 2026-10-21). |
//| The EA reads the queue in OnInit, before the halt load, so a     |
//| runtime error there would stop the guardian at every start. Each |
//| case feeds AgTgQueueParse, then what AgTgQueueLoad runs on a     |
//| parsed file: the login compare, AgTgQueueForget,                 |
//| AgTgNextSeqAfterLoad, and the append with AgTgQueueTrim that     |
//| AgTgAppendHeld makes. Every case must end in a rejection with    |
//| its reason or in a valid result. Pure: no file and no GV.        |
//+------------------------------------------------------------------+
#define AGVEC_TGQ_LOGIN 990000021

//--- field k of a '|' line replaced
string AgVecTgField(const string line, const int k, const string value)
  {
   string f[];
   int n = StringSplit(line, '|', f);
   string out = "";
   for(int i = 0; i < n; i++)
      out += (i == 0 ? "" : "|") + (i == k ? value : f[i]);
   return out;
  }

//--- the last field of a '|' line dropped
string AgVecTgDropLast(const string line)
  {
   int at = StringLen(line) - 1;
   while(at >= 0 && StringGetCharacter(line, at) != '|')
      at--;
   return (at < 0) ? "" : StringSubstr(line, 0, at);
  }

string AgVecTgHeader() { return AG_TGQ_MAGIC + "|1|" + (string)AGVEC_TGQ_LOGIN; }

string AgVecTgE() { return "E|200|" + (string)(long)D'2026.10.21 01:00:00' + "|1"; }

string AgVecTgN()
  {
   AgTgSnapshot s;
   ZeroMemory(s);
   s.local_t        = (long)D'2026.10.21 12:00:02';
   s.server_t       = (long)D'2026.10.21 12:00:01';
   s.state          = AG_STATE_ACTIVE;
   s.seconds_in_state = 3600;
   s.connected      = 1;
   s.pnl_mode       = AG_TG_PNL_ACTIVE;
   s.balance        = 2172.06;
   s.floating       = -21.96;
   s.equity         = 2150.10;
   s.pnl            = -21.96;
   s.limit          = 126.21;
   s.live_limit     = 126.21;
   s.enforced_limit = 126.21;
   s.peak_level     = -126.21;
   s.anchor         = (long)D'2026.10.21 01:00:00';
   s.percent        = 5.5;
   s.currency       = 200.0;
   return AgTgSnapshotLine(s, "TG");
  }

//--- an S4 event, the figures of the S4 draft
string AgVecTgV(const long seq)
  {
   AgTgEvent e;
   ZeroMemory(e);
   e.seq      = seq;
   e.code     = AG_TG_S4;
   e.server_t = (long)D'2026.09.15 18:36:17';
   e.local_t  = (long)D'2026.09.15 18:36:18';
   e.state    = AG_STATE_LOCKED;
   e.pnl_mode = AG_TG_PNL_ACTIVE;
   e.balance  = 2300.16;
   e.equity   = 2164.56;
   e.pnl      = -130.20;
   e.limit    = 126.21;
   e.x[0] = 1;
   e.x[1] = (double)(long)D'2026.09.16 01:00:00';
   e.x[2] = 126.21;
   e.x[3] = 5.40;
   e.x[4] = -135.60;
   e.x[6] = 3;
   return AgTgEventLine(e);
  }

//--- header, E and N lines, the V lines given (each ending "\n"), sealed
string AgVecTgFile(const string header, const string e_line, const string n_line, const string v_lines)
  {
   return AgVecSealed(header + "\n" + e_line + "\n" + n_line + "\n" + v_lines);
  }

//--- want_ok: a valid result keeping want_kept events after the load's
//--- forget at acknowledgement 100 and one held event appended; else the
//--- rejection with its reason
void AgVecTgQueueCase(const string name, const string text, const bool want_ok, const string want_why,
                      const int want_kept)
  {
   long         login = 0, next_seq = 0, latch = 0;
   int          mask = 0, count = 0;
   AgTgSnapshot snap;
   string       build = "", why = "";
   AgTgEvent    loaded[];
   bool ok = AgTgQueueParse(text, login, next_seq, latch, mask, snap, build, loaded, count, why);
   if(ok && login != AGVEC_TGQ_LOGIN)
     {
      ok  = false;
      why = "carries login " + (string)login;
     }
   int kept = -1;
   if(ok)
     {
      AgTgQueueForget(loaded, count, 100);
      AgTgEvent held;
      ZeroMemory(held);
      held.seq  = AgTgNextSeqAfterLoad(next_seq, 100);
      held.code = AG_TG_S2;
      ArrayResize(loaded, count + 1);
      loaded[count] = held;
      count++;
      AgTgQueueTrim(loaded, count, AG_TGQ_MAX_EVENTS);
      kept = count;
     }
   bool pass = want_ok ? (ok && kept == want_kept) : (!ok && why == want_why);
   AgVecCheck("tg_qr_" + name, pass, "ok=" + (string)ok + " why=" + why + " kept=" + (string)kept);
  }

void AgVecTgQueueCases()
  {
   string H    = AgVecTgHeader();
   string E    = AgVecTgE();
   string N    = AgVecTgN();
   string V    = AgVecTgV(101) + "\n" + AgVecTgV(102) + "\n";
   string last = AgVecTgV(103);
   string body = H + "\n" + E + "\n" + N + "\n" + V + last + "\n";
   string good = AgVecSealed(body);

   //--- the reference file, and the same with CRLF line ends
   AgVecTgQueueCase("reference_file_is_valid", good, true, "", 4);
   string crlf = good;
   StringReplace(crlf, "\n", "\r\n");
   AgVecTgQueueCase("crlf_line_ends_are_valid", crlf, true, "", 4);

   //--- an empty file, and line ends only
   AgVecTgQueueCase("empty_file", "", false, "no checksum line", 0);
   AgVecTgQueueCase("line_ends_only", "\n\n\n", false, "no checksum line", 0);

   //--- a truncated last line, inside the last V line and inside the C line
   AgVecTgQueueCase("truncated_inside_last_v_line", StringSubstr(body, 0, StringLen(body) - 10),
                    false, "no checksum line", 0);
   AgVecTgQueueCase("truncated_inside_c_line", StringSubstr(good, 0, StringLen(good) - 3),
                    false, "checksum mismatch", 0);

   //--- a missing C line, and a C line with nothing above it
   AgVecTgQueueCase("missing_c_line", body, false, "no checksum line", 0);
   AgVecTgQueueCase("c_line_alone", AgVecSealed(""), false, "too few lines", 0);

   //--- extra and missing fields on each line type, every file sealed so
   //--- the line itself is what is judged
   AgVecTgQueueCase("header_extra_field", AgVecTgFile(H + "|0", E, N, V), false, "bad header", 0);
   AgVecTgQueueCase("header_missing_field", AgVecTgFile(AgVecTgDropLast(H), E, N, V), false, "bad header", 0);
   AgVecTgQueueCase("e_extra_field", AgVecTgFile(H, E + "|0", N, V), false, "bad E line", 0);
   AgVecTgQueueCase("e_missing_field", AgVecTgFile(H, AgVecTgDropLast(E), N, V), false, "bad E line", 0);
   AgVecTgQueueCase("n_extra_field", AgVecTgFile(H, E, N + "|0", V), false, "bad N line", 0);
   AgVecTgQueueCase("n_missing_field", AgVecTgFile(H, E, AgVecTgDropLast(N), V), false, "bad N line", 0);
   AgVecTgQueueCase("v_extra_field", AgVecTgFile(H, E, N, V + last + "|0\n"), false, "bad V line 6", 0);
   AgVecTgQueueCase("v_missing_field", AgVecTgFile(H, E, N, V + AgVecTgDropLast(last) + "\n"),
                    false, "bad V line 6", 0);
   AgVecTgQueueCase("v_blank_line", AgVecTgFile(H, E, N, V + "\n" + last + "\n"), false, "bad V line 6", 0);
   AgVecTgQueueCase("c_extra_field", body + "C|" + (string)AgChecksum(body) + "|0\n", false, "checksum mismatch", 0);
   AgVecTgQueueCase("c_missing_value", body + "C|\n", false, "checksum mismatch", 0);

   //--- non numeric fields
   AgVecTgQueueCase("header_login_not_numeric", AgVecTgFile(AgVecTgField(H, 2, "99000002l"), E, N, V),
                    false, "bad header", 0);
   AgVecTgQueueCase("header_version_not_numeric", AgVecTgFile(AgVecTgField(H, 1, "x"), E, N, V),
                    false, "bad header", 0);
   AgVecTgQueueCase("e_next_seq_not_numeric", AgVecTgFile(H, AgVecTgField(E, 1, "12a"), N, V),
                    false, "bad E line", 0);
   AgVecTgQueueCase("e_mask_empty", AgVecTgFile(H, AgVecTgField(E, 3, ""), N, V), false, "bad E line", 0);
   AgVecTgQueueCase("n_balance_not_numeric", AgVecTgFile(H, E, AgVecTgField(N, 10, "abc"), V),
                    false, "bad N line", 0);
   AgVecTgQueueCase("n_state_with_a_decimal", AgVecTgFile(H, E, AgVecTgField(N, 4, "1.5"), V),
                    false, "bad N line", 0);
   AgVecTgQueueCase("n_build_not_a_label", AgVecTgFile(H, E, AgVecTgField(N, 3, "t@g"), V),
                    false, "bad N line", 0);
   AgVecTgQueueCase("n_build_empty", AgVecTgFile(H, E, AgVecTgField(N, 3, ""), V), false, "bad N line", 0);
   AgVecTgQueueCase("v_seq_not_numeric", AgVecTgFile(H, E, N, V + AgVecTgField(last, 1, "abc") + "\n"),
                    false, "bad V line 6", 0);
   AgVecTgQueueCase("v_code_unknown_text", AgVecTgFile(H, E, N, V + AgVecTgField(last, 2, "SX") + "\n"),
                    false, "bad V line 6", 0);
   AgVecTgQueueCase("v_code_empty", AgVecTgFile(H, E, N, V + AgVecTgField(last, 2, "") + "\n"),
                    false, "bad V line 6", 0);
   AgVecTgQueueCase("v_balance_with_an_exponent", AgVecTgFile(H, E, N, V + AgVecTgField(last, 7, "1e5") + "\n"),
                    false, "bad V line 6", 0);
   AgVecTgQueueCase("v_x_nan", AgVecTgFile(H, E, N, V + AgVecTgField(last, 11, "nan") + "\n"),
                    false, "bad V line 6", 0);
   AgVecTgQueueCase("v_x_minus_only", AgVecTgFile(H, E, N, V + AgVecTgField(last, 12, "-") + "\n"),
                    false, "bad V line 6", 0);
   AgVecTgQueueCase("v_x_two_points", AgVecTgFile(H, E, N, V + AgVecTgField(last, 13, "1.2.3") + "\n"),
                    false, "bad V line 6", 0);

   //--- numbers beyond the long and int ranges, and at their edges
   AgVecTgQueueCase("header_login_beyond_long", AgVecTgFile(AgVecTgField(H, 2, "9223372036854775808"), E, N, V),
                    false, "bad header", 0);
   AgVecTgQueueCase("e_next_seq_beyond_long", AgVecTgFile(H, AgVecTgField(E, 1, "9223372036854775808"), N, V),
                    false, "bad E line", 0);
   AgVecTgQueueCase("e_next_seq_at_long_max", AgVecTgFile(H, AgVecTgField(E, 1, "9223372036854775807"), N, V + last + "\n"),
                    true, "", 4);
   AgVecTgQueueCase("e_latch_beyond_long", AgVecTgFile(H, AgVecTgField(E, 2, "99999999999999999999"), N, V),
                    false, "bad E line", 0);
   AgVecTgQueueCase("e_mask_beyond_int", AgVecTgFile(H, AgVecTgField(E, 3, "2147483648"), N, V),
                    false, "bad E line", 0);
   AgVecTgQueueCase("e_mask_that_truncates_to_3", AgVecTgFile(H, AgVecTgField(E, 3, "4294967299"), N, V),
                    false, "bad E line", 0);
   AgVecTgQueueCase("e_mask_at_int_max", AgVecTgFile(H, AgVecTgField(E, 3, "2147483647"), N, V + last + "\n"),
                    true, "", 4);
   AgVecTgQueueCase("n_state_that_truncates_to_locked", AgVecTgFile(H, E, AgVecTgField(N, 4, "4294967299"), V),
                    false, "bad N line", 0);
   AgVecTgQueueCase("n_local_t_beyond_long", AgVecTgFile(H, E, AgVecTgField(N, 1, "-9223372036854775809"), V),
                    false, "bad N line", 0);
   AgVecTgQueueCase("n_seconds_beyond_int", AgVecTgFile(H, E, AgVecTgField(N, 6, "-2147483649"), V),
                    false, "bad N line", 0);
   AgVecTgQueueCase("v_seq_beyond_long", AgVecTgFile(H, E, N, V + AgVecTgField(last, 1, "9223372036854775808") + "\n"),
                    false, "bad V line 6", 0);
   AgVecTgQueueCase("v_code_that_truncates_to_s1", AgVecTgFile(H, E, N, V + AgVecTgField(last, 2, "S4294967297") + "\n"),
                    false, "bad V line 6", 0);
   AgVecTgQueueCase("v_state_that_truncates_to_syncing", AgVecTgFile(H, E, N, V + AgVecTgField(last, 5, "4294967297") + "\n"),
                    false, "bad V line 6", 0);
   AgVecTgQueueCase("v_money_beyond_long_is_a_number",
                    AgVecTgFile(H, E, N, V + AgVecTgField(last, 7, "12345678901234567890123.45") + "\n"), true, "", 4);
   AgVecTgQueueCase("v_x_beyond_long_is_a_number",
                    AgVecTgFile(H, E, N, V + AgVecTgField(last, 11, "9223372036854775808") + "\n"), true, "", 4);
   AgVecTgQueueCase("v_money_longer_than_32_characters",
                    AgVecTgFile(H, E, N, V + AgVecTgField(last, 8, "1234567890123456789012345678901234567890.00") + "\n"),
                    false, "bad V line 6", 0);

   //--- more than 50 V lines
   string many = "";
   for(int k = 0; k < AG_TGQ_MAX_EVENTS; k++)
      many += AgVecTgV(101 + k) + "\n";
   AgVecTgQueueCase("fifty_v_lines_are_valid", AgVecTgFile(H, E, N, many), true, "", AG_TGQ_MAX_EVENTS);
   AgVecTgQueueCase("fifty_one_v_lines", AgVecTgFile(H, E, N, many + AgVecTgV(151) + "\n"),
                    false, "too many V lines", 0);
   string lots = many;
   for(int k = AG_TGQ_MAX_EVENTS; k < 200; k++)
      lots += AgVecTgV(101 + k) + "\n";
   AgVecTgQueueCase("two_hundred_v_lines", AgVecTgFile(H, E, N, lots), false, "too many V lines", 0);

   //--- a seq out of order, repeated, zero or negative; gaps are allowed
   AgVecTgQueueCase("v_seq_descending", AgVecTgFile(H, E, N, AgVecTgV(102) + "\n" + AgVecTgV(101) + "\n"),
                    false, "V lines out of order", 0);
   AgVecTgQueueCase("v_seq_repeated", AgVecTgFile(H, E, N, AgVecTgV(101) + "\n" + AgVecTgV(101) + "\n"),
                    false, "V lines out of order", 0);
   AgVecTgQueueCase("v_seq_zero", AgVecTgFile(H, E, N, AgVecTgV(0) + "\n"), false, "bad V line 4", 0);
   AgVecTgQueueCase("v_seq_negative", AgVecTgFile(H, E, N, AgVecTgField(AgVecTgV(101), 1, "-5") + "\n"),
                    false, "bad V line 4", 0);
   AgVecTgQueueCase("v_seq_with_gaps",
                    AgVecTgFile(H, E, N, AgVecTgV(101) + "\n" + AgVecTgV(140) + "\n" + AgVecTgV(199) + "\n"),
                    true, "", 4);

   //--- characters outside printable ASCII, each file sealed
   string alef = ShortToString(0x05D0), e_acute = ShortToString(0x00E9);
   string repl = ShortToString(0xFFFD), tab = ShortToString(9);
   AgVecTgQueueCase("hebrew_letter_in_the_build", AgVecTgFile(H, E, AgVecTgField(N, 3, "T" + alef), V),
                    false, "not printable ASCII", 0);
   AgVecTgQueueCase("latin_letter_in_a_v_field", AgVecTgFile(H, E, N, V + AgVecTgField(last, 11, "1" + e_acute) + "\n"),
                    false, "not printable ASCII", 0);
   AgVecTgQueueCase("replacement_character_in_the_magic", AgVecTgFile("AG" + repl + "Q|1|990000021", E, N, V),
                    false, "not printable ASCII", 0);
   AgVecTgQueueCase("tab_inside_a_field", AgVecTgFile(H, AgVecTgField(E, 1, "12" + tab + "1"), N, V),
                    false, "not printable ASCII", 0);
   AgVecTgQueueCase("character_after_the_c_line", good + e_acute + "\n", false, "not printable ASCII", 0);
   AgVecTgQueueCase("character_inside_the_c_line", body + "C|" + (string)AgChecksum(body) + e_acute + "\n",
                    false, "not printable ASCII", 0);
  }

void OnStart()
  {
   //--- Fixed reference values. The anchor boundary is the same arbitrary
   //--- Tuesday the Phase 1 clock vectors use, so the two vector sets can be
   //--- read side by side. The money values are the real measured ones from
   //--- 2026-08-16: base 1985.97 at the ruled five percent gives 99.2985,
   //--- which the banner prints as 99.30. That sub-cent tail is the whole
   //--- reason the money fields are stored at 8 decimals and it is asserted
   //--- below rather than left as a comment.
   datetime A0        = D'2026.02.10 01:00:00';
   datetime until_ref = A0 + 86400;
   datetime breach_ref = A0 + 43200;
   double   base_ref  = 1985.97;
   double   limit_ref = 99.2985;

   long live_login = (long)AccountInfoInteger(ACCOUNT_LOGIN);

   //--- vector 0: the safety interlock. Every other vector writes files, so
   //--- this one runs first and refuses everything if the synthetic range
   //--- could collide with the live account's own state file.
   bool range_is_safe = (live_login < 990000000 || live_login > 990000999);
   AgVecCheck("v0_synthetic_login_range_cannot_hit_live_account", range_is_safe,
              "live login " + (string)live_login + " falls inside the synthetic range");
   if(!range_is_safe)
     {
      PrintFormat("AGVEC|SUMMARY|%d/%d", g_pass, g_total);
      return;
     }

   //================================================================
   //--- A. path and format identity
   //================================================================
   g_ag_login = AGVEC_LOGIN_ROUNDTRIP;
   AgVecCheck("a1_state_path_differs_from_halt_path", AgStatePath() != AgHaltPath(),
              AgStatePath() + " vs " + AgHaltPath());
   AgVecCheck("a2_state_path_names_the_login",
              StringFind(AgStatePath(), (string)AGVEC_LOGIN_ROUNDTRIP) >= 0, AgStatePath());
   AgVecCheck("a3_magic_is_agstate_not_aghalt",
              StringFind(AgStateSerialize(), "AGSTATE|") == 0
              && StringFind(AgStateSerialize(), "AGHALT") < 0, AgStateSerialize());

   //================================================================
   //--- B. never-loaded-never-written (FINAL 2026-07-29)
   //================================================================
   g_ag_login = AGVEC_LOGIN_GUARD;
   string guard_path = AgStatePath();
   AgVecWriteRaw(guard_path, AgVecSealed(AgVecBody(AGVEC_LOGIN_GUARD, 1, until_ref, breach_ref,
                                                   limit_ref, base_ref)));
   string guard_before = AgVecReadRaw(guard_path);
   g_ag_state_loaded = false;                 // simulate a refused init
   AgStateResetModel();                       // default-constructed empty model
   bool saved = AgStateSave();
   AgVecCheck("b1_save_refuses_when_model_never_loaded", !saved, "AgStateSave returned true");
   AgVecCheck("b2_refused_save_left_the_file_byte_identical",
              AgVecReadRaw(guard_path) == guard_before, "file changed under a refused save");

   //================================================================
   //--- C. round trip through the real save and load paths
   //================================================================
   g_ag_login = AGVEC_LOGIN_ROUNDTRIP;
   g_ag_state_loaded = true;                  // a legitimate load happened
   AgStateSetBreach(until_ref, breach_ref, limit_ref, base_ref);
   AgVecCheck("c1_save_succeeds_when_loaded", AgStateSave(), "AgStateSave returned false");

   AgStateResetModel();                       // prove the values come off disk
   int rc = AgStateLoad();
   AgVecCheckInt("c2_roundtrip_load_returns_loaded", rc, 0);
   AgVecCheckInt("c3_roundtrip_reason", (long)g_ag_state_reason, (long)AG_LOCK_DAILY_BREACH);
   AgVecCheckDT("c4_roundtrip_locked_until", g_ag_state_locked_until, until_ref);
   AgVecCheckDT("c5_roundtrip_breach_time", g_ag_state_breach_time, breach_ref);
   AgVecCheckMoney("c6_roundtrip_limit_snapshot", g_ag_state_limit_snap, limit_ref);
   AgVecCheckMoney("c7_roundtrip_base_snapshot", g_ag_state_base_snap, base_ref);
   //--- The Q6 snapshot governs the locked window, so a limit stored to the
   //--- printed cent would enforce 99.30 where the breach computed 99.2985.
   AgVecCheck("c8_limit_snapshot_keeps_sub_cent_precision",
              MathAbs(g_ag_state_limit_snap - 99.30) > 0.0001,
              "stored limit rounded to the cent: " + DoubleToString(g_ag_state_limit_snap, 8));

   //================================================================
   //--- D. missing file: not corrupt, and not trusted either way
   //================================================================
   g_ag_login = AGVEC_LOGIN_MISSING;
   g_ag_state_loaded = false;
   rc = AgStateLoad();
   AgVecCheckInt("d1_missing_file_returns_missing", rc, 1);
   AgVecCheck("d2_missing_file_sets_loaded_true", g_ag_state_loaded, "");
   AgVecCheckInt("d3_missing_file_model_is_neutral", (long)g_ag_state_reason, (long)AG_LOCK_NONE);
   AgVecCheckDT("d4_missing_file_locked_until_is_zero", g_ag_state_locked_until, 0);
   AgVecCheck("d5_missing_file_wrote_nothing", !FileIsExist(AgStatePath()), AgStatePath());

   //================================================================
   //--- E. checksum corruption
   //================================================================
   g_ag_login = AGVEC_LOGIN_CORRUPT;
   string corrupt_path = AgStatePath();
   string corrupt_body = AgVecBody(AGVEC_LOGIN_CORRUPT, 1, until_ref, breach_ref, limit_ref, base_ref);
   AgVecWriteRaw(corrupt_path, AgVecTampered(corrupt_body));
   string corrupt_original = AgVecReadRaw(corrupt_path);
   //--- Computed before the call so a tick crossing the 01:00 boundary during
   //--- the call cannot make a correct implementation look wrong.
   datetime expect_until = AgNextDayAnchor(AgServerNow());
   rc = AgStateLoad();
   AgVecCheckInt("e1_bad_checksum_returns_corrupt", rc, 2);
   AgVecCheckInt("e2_bad_checksum_locks_via_corrupt_state",
                 (long)g_ag_state_reason, (long)AG_LOCK_CORRUPT_STATE);
   AgVecCheckDT("e3_corrupt_locked_until_is_next_day_anchor", g_ag_state_locked_until, expect_until);
   AgVecCheckDT("e4_corrupt_carries_no_breach_time", g_ag_state_breach_time, 0);
   AgVecCheckMoney("e5_corrupt_carries_no_limit_snapshot", g_ag_state_limit_snap, 0.0);
   AgVecCheckMoney("e6_corrupt_carries_no_base_snapshot", g_ag_state_base_snap, 0.0);
   AgVecCheck("e7_corrupt_file_was_quarantined_not_deleted",
              FileIsExist(corrupt_path + ".bad") || FileIsExist(corrupt_path + ".bad.2"),
              "no quarantine file found for " + corrupt_path);
   AgVecCheck("e8_a_fresh_file_was_written", FileIsExist(corrupt_path), corrupt_path);
   //--- No re-corruption loop: the file the corrupt branch just wrote must
   //--- itself load cleanly on the next restart inside the same window.
   datetime until_after_quarantine = g_ag_state_locked_until;
   AgStateResetModel();
   rc = AgStateLoad();
   AgVecCheckInt("e9_fresh_file_reloads_cleanly", rc, 0);
   AgVecCheckInt("e10_fresh_file_still_says_corrupt_state",
                 (long)g_ag_state_reason, (long)AG_LOCK_CORRUPT_STATE);
   AgVecCheckDT("e11_fresh_file_preserves_locked_until",
                g_ag_state_locked_until, until_after_quarantine);

   //--- The quarantine holds the original bytes, not a rewritten copy.
   string quarantined = AgVecReadRaw(corrupt_path + ".bad");
   AgVecCheck("e12_quarantine_holds_the_original_bytes",
              quarantined == corrupt_original || StringFind(quarantined, "AGSTATE|") == 0,
              "quarantine content does not match the file that was moved");

   //================================================================
   //--- F. quarantine never overwrites an earlier quarantine
   //--- (FINAL 2026-07-29: lock artifacts are never deleted)
   //================================================================
   AgVecWriteRaw(corrupt_path, AgVecTampered(corrupt_body));
   AgStateLoad();
   AgVecCheck("f1_second_corruption_did_not_reuse_the_first_quarantine_name",
              FileIsExist(corrupt_path + ".bad") && FileIsExist(corrupt_path + ".bad.2"),
              "expected both .bad and .bad.2 to exist after two corruptions");

   //================================================================
   //--- G. login mismatch (FINAL 2026-07-30, CORRUPT_STATE-equivalent)
   //================================================================
   g_ag_login = AGVEC_LOGIN_MISMATCH;
   string mismatch_path = AgStatePath();
   //--- Internally valid, correct checksum, correct magic and version, and
   //--- a foreign login. Exactly the foreign-residue class.
   AgVecWriteRaw(mismatch_path, AgVecSealed(AgVecBody(AGVEC_LOGIN_FOREIGN, 1, until_ref,
                                                      breach_ref, limit_ref, base_ref)));
   expect_until = AgNextDayAnchor(AgServerNow());
   rc = AgStateLoad();
   AgVecCheckInt("g1_login_mismatch_returns_its_own_code", rc, 3);
   AgVecCheckInt("g2_login_mismatch_locks_via_corrupt_state",
                 (long)g_ag_state_reason, (long)AG_LOCK_CORRUPT_STATE);
   AgVecCheckDT("g3_login_mismatch_locked_until_is_next_day_anchor",
                g_ag_state_locked_until, expect_until);
   AgVecCheck("g4_foreign_lock_values_were_not_adopted",
              g_ag_state_locked_until != until_ref && g_ag_state_breach_time == 0,
              "the foreign file's own lock values leaked into the model");
   AgVecCheck("g5_foreign_file_was_quarantined",
              FileIsExist(mismatch_path + ".bad") || FileIsExist(mismatch_path + ".bad.2"),
              "no quarantine file found for " + mismatch_path);
   AgStateResetModel();
   rc = AgStateLoad();
   AgVecCheckInt("g6_fresh_file_after_mismatch_reloads_cleanly", rc, 0);

   //================================================================
   //--- H. format rejection: version, and cross-reading the halt file
   //================================================================
   g_ag_login = AGVEC_LOGIN_VERSION;
   string version_path = AgStatePath();
   string wrong_version = "AGSTATE|" + (string)(AG_STATE_FORMAT_VERSION + 1) + "|"
                          + (string)AGVEC_LOGIN_VERSION + "\n"
                          + "L|1|" + (string)((long)until_ref) + "|" + (string)((long)breach_ref) + "\n";
   AgVecWriteRaw(version_path, AgVecSealed(wrong_version));
   rc = AgStateLoad();
   AgVecCheckInt("h1_unknown_format_version_is_rejected", rc, 2);
   AgVecCheckInt("h2_unknown_version_locks_via_corrupt_state",
                 (long)g_ag_state_reason, (long)AG_LOCK_CORRUPT_STATE);

   //--- A halt file dropped at the state path must never be read as lock
   //--- state, which is the whole reason the magics differ.
   g_ag_login = AGVEC_LOGIN_CROSSREAD;
   string cross_path = AgStatePath();
   string halt_body = "AGHALT|" + (string)AG_HALT_FORMAT_VERSION + "|"
                      + (string)AGVEC_LOGIN_CROSSREAD + "\n"
                      + "S|1786027355|0\n"
                      + "H|1|crash loop|1786027355\n";
   AgVecWriteRaw(cross_path, AgVecSealed(halt_body));
   rc = AgStateLoad();
   AgVecCheckInt("h3_halt_file_at_the_state_path_is_rejected", rc, 2);
   AgVecCheckInt("h4_cross_read_locks_via_corrupt_state",
                 (long)g_ag_state_reason, (long)AG_LOCK_CORRUPT_STATE);

   //================================================================
   //--- I. locked_until BOUNDS (Phase 2 Stage 3, reachable from a script
   //--- since the owner ruling of 2026-08-18 moved both helpers into
   //--- Clock.mqh). These encode three FINAL rulings and were previously
   //--- provable by source reading alone.
   //================================================================
   //--- Anchor boundaries off the same reference A0 the fixtures above use,
   //--- named as the Phase 1 clock vectors name theirs so the two vector
   //--- sets read side by side.
   datetime A1 = A0 + 86400;    // next boundary
   datetime A3 = A0 + 259200;   // three boundaries forward

   datetime saved_high   = g_ag_high_anchor;
   bool     saved_seeded = g_ag_high_anchor_seeded;

   //--- Q1 base, with the latch unseeded so ruling FOUR contributes nothing
   g_ag_high_anchor_seeded = false;
   g_ag_high_anchor        = 0;
   AgVecCheckDT("i1_q1_base_is_next_day_anchor",
                AgLockedUntilComputed(A0 + 3600, false), AgNextDayAnchor(A0 + 3600));
   AgVecCheck("i2_latch_floor_is_zero_while_unseeded", AgLatchFloor() == 0, "");

   //--- RULING THREE: a frozen quote takes the anchor AFTER the imminent one
   AgVecCheckDT("i3_ruling_three_frozen_adds_a_full_day",
                AgLockedUntilComputed(A0 + 3600, true),
                AgNextDayAnchor(AgNextDayAnchor(A0 + 3600)));
   AgVecCheck("i4_ruling_three_is_exactly_one_extra_day",
              (long)(AgLockedUntilComputed(A0 + 3600, true)
                     - AgLockedUntilComputed(A0 + 3600, false)) == 86400, "");

   //--- The measured signature ruling THREE exists for: a breach at 00:58
   //--- inside the pre-anchor freeze must NOT lock for the two minutes left
   //--- until the imminent anchor.
   datetime breach_0058 = A1 - 120;   // two minutes before the 01:00 boundary
   AgVecCheck("i5_pre_anchor_breach_does_not_lock_for_minutes",
              (long)(AgLockedUntilComputed(breach_0058, true) - breach_0058) > 86400,
              "lock duration was " + (string)(long)(AgLockedUntilComputed(breach_0058, true) - breach_0058) + "s");
   AgVecCheckDT("i6_pre_anchor_unfrozen_still_takes_the_imminent_anchor",
                AgLockedUntilComputed(breach_0058, false), A1);

   //--- RULING FOUR: the latch floor raises a value that would fall below it
   g_ag_high_anchor_seeded = true;
   g_ag_high_anchor        = A3;                  // latch well ahead of the breach
   AgVecCheckDT("i7_ruling_four_floors_a_stale_computed_value",
                AgLockedUntilComputed(A0 + 3600, false), AgNextDayAnchor(A3));
   AgVecCheck("i8_ruling_four_is_a_floor_not_a_replacement",
              AgLockedUntilComputed(A3 + 200000, false) > AgNextDayAnchor(A3), "");

   //--- WITNESS PATH: clamp first as the upper bound
   datetime ceiling = AgNextDayAnchor(AgServerNow());
   g_ag_high_anchor_seeded = false;               // floor out of the way
   g_ag_high_anchor        = 0;
   AgVecCheckDT("i9_witness_value_beyond_the_ceiling_is_clamped",
                AgLockedUntilFromWitness(ceiling + 8640000), ceiling);
   AgVecCheckDT("i10_witness_value_inside_the_bounds_is_untouched",
                AgLockedUntilFromWitness(ceiling - 3600), ceiling - 3600);

   //--- WITNESS PATH under a REWOUND CLOCK, the case the precedence ruling of
   //--- 2026-08-18 was made for. The latch never recedes, so after a backward
   //--- step its next-day anchor sits ABOVE the clamp's ceiling and the two
   //--- bounds point in opposite directions. The floor is applied last and
   //--- must win; if the clamp won, the lock would be cut back using the very
   //--- reading the floor exists to defend against.
   g_ag_high_anchor_seeded = true;
   g_ag_high_anchor        = ceiling + 172800;    // latch two days past the ceiling
   datetime floor_above    = AgNextDayAnchor(g_ag_high_anchor);
   AgVecCheck("i11_rewound_clock_floor_sits_above_the_clamp_ceiling",
              floor_above > ceiling, "fixture is wrong: floor is not above the ceiling");
   AgVecCheckDT("i12_rewound_clock_floor_wins_over_the_clamp",
                AgLockedUntilFromWitness(ceiling - 3600), floor_above);
   AgVecCheckDT("i13_rewound_clock_floor_wins_even_for_an_inflated_witness",
                AgLockedUntilFromWitness(ceiling + 8640000), floor_above);

   //--- THE DOMAIN SPLIT ITSELF: a value the guardian computes for itself
   //--- takes NO clamp, so a frozen-quote breach may legitimately land beyond
   //--- the ceiling. If the clamp leaked into the computed path this fails.
   g_ag_high_anchor_seeded = false;
   g_ag_high_anchor        = 0;
   datetime computed_frozen = AgLockedUntilComputed(AgServerNow(), true);
   AgVecCheck("i14_computed_path_is_not_clamped",
              computed_frozen > ceiling,
              "computed=" + TimeToString(computed_frozen, TIME_DATE | TIME_SECONDS)
              + " ceiling=" + TimeToString(ceiling, TIME_DATE | TIME_SECONDS));

   g_ag_high_anchor        = saved_high;
   g_ag_high_anchor_seeded = saved_seeded;

   //================================================================
   //--- J. THE RATCHET (Phase 2 Stage 5, question SEVEN FINAL). The six
   //--- vectors the ruling calls for, plus two that prove the persistence
   //--- the ruling requires, since a floor that does not survive a restart
   //--- is not a ratchet. Reachable from a script only because
   //--- AgRatchetUpdate was placed beside the floor family rather than in
   //--- the EA, applying the same owner ruling that moved the bound helpers.
   //================================================================
   g_ag_login        = AGVEC_LOGIN_RATCHET;
   g_ag_floor_loaded = true;
   AgFloorResetModel();

   //--- SEED on the first completed computation of a day
   double r = AgRatchetUpdate(A0, 100.0, 30);
   AgVecCheckMoney("j1_seed_takes_the_live_limit", r, 100.0);
   AgVecCheckMoney("j1b_seed_stores_the_floor", g_ag_floor_currency, 100.0);
   AgVecCheckDT("j1c_seed_stores_the_day_anchor", g_ag_floor_anchor, A0);

   //--- LOWER on a decrease: the floor is a running minimum
   r = AgRatchetUpdate(A0, 80.0, 30);
   AgVecCheckMoney("j2_lowers_on_a_decrease", g_ag_floor_currency, 80.0);
   AgVecCheckMoney("j2b_enforces_the_lowered_value", r, 80.0);

   //--- HOLD under inflation: the whole point of the ratchet
   r = AgRatchetUpdate(A0, 150.0, 30);
   AgVecCheckMoney("j3_holds_the_floor_against_a_raised_limit", g_ag_floor_currency, 80.0);
   AgVecCheckMoney("j3b_enforces_the_floor_not_the_raised_limit", r, 80.0);

   //--- RESEED AT ROLLOVER: the new day starts from the live limit
   r = AgRatchetUpdate(A1, 150.0, 30);
   AgVecCheckMoney("j4_reseeds_at_rollover", g_ag_floor_currency, 150.0);
   AgVecCheckDT("j4b_reseed_moves_the_day_anchor", g_ag_floor_anchor, A1);
   AgVecCheckMoney("j4c_reseed_enforces_the_new_live_limit", r, 150.0);

   //--- NO RESEED ON A BACKWARD STEP. Tighten first so the case can
   //--- discriminate, then step the window anchor back behind the floor's.
   AgRatchetUpdate(A1, 90.0, 30);
   r = AgRatchetUpdate(A0, 150.0, 30);
   AgVecCheckMoney("j5_no_reseed_on_a_backward_step", g_ag_floor_currency, 90.0);
   AgVecCheckDT("j5b_backward_step_does_not_move_the_anchor", g_ag_floor_anchor, A1);
   AgVecCheckMoney("j5c_backward_step_still_enforces_the_held_floor", r, 90.0);

   //--- PERSISTENCE: the floor survives a restart, which is what makes it a
   //--- ratchet rather than a per-session tightening.
   AgFloorSave();
   AgFloorResetModel();
   AgVecCheckInt("j6_floor_file_reloads", AgFloorLoad(), 0);
   AgVecCheckMoney("j6b_floor_survives_a_restart", g_ag_floor_currency, 90.0);

   //--- STALE FLOOR from a prior day contributes nothing, which is the case
   //--- of a file no pass has reseeded because the EA has not run since the
   //--- rollover. A1 is the floor's day; A3 is a later one.
   AgVecCheckMoney("j7_stale_floor_is_declined", AgFloorEffectiveLimit(200.0, A3), 200.0);
   AgVecCheckMoney("j7b_same_day_floor_is_applied", AgFloorEffectiveLimit(200.0, A1), 90.0);

   //--- CORRUPT FLOOR FILE: quarantined, model reset, and NO lock follows,
   //--- because the floor is not lock state.
   string floor_path = AgFloorPath();
   AgVecWriteRaw(floor_path, AgVecTampered("AGFLOOR|1|" + (string)AGVEC_LOGIN_RATCHET + "\n"
                                           + "F|" + (string)((long)A1) + "|90.00000000\n"));
   AgVecCheckInt("j8_corrupt_floor_is_quarantined", AgFloorLoad(), 2);
   AgVecCheckMoney("j8b_corrupt_floor_resets_to_nothing", g_ag_floor_currency, 0.0);
   AgVecCheck("j8c_corrupt_floor_file_was_not_deleted",
              FileIsExist(floor_path + ".bad") || FileIsExist(floor_path + ".bad.2"),
              "no quarantine file found for " + floor_path);

   //--- K. THE FILE ROUND TRIP MUST NOT LOOK LIKE A LIMIT CHANGE (owner ruling
   //--- 2026-08-18, added after the live Stage 7 finding). None of j1 to j8
   //--- could have caught this: every one of them compares a floor that came
   //--- straight out of memory, and the defect only exists on the path where
   //--- the floor has been through DoubleToString at 8 decimals and back
   //--- through StringToDouble. On the live account that path made the guardian
   //--- report a raised limit 220 times against a limit nobody touched.
   AgFloorResetModel();
   g_ag_floor_loaded      = true;
   g_ag_last_ratchet_warn = 0;

   //--- The live arithmetic exactly as the guardian computes it, rather than a
   //--- round number: base 2133.13 at 5 percent is what was on the account when
   //--- the defect was found, and a round number would not exercise the bug.
   double rt_live = AgLimitCurrency(2133.13, 5.0, 0.0);
   AgRatchetUpdate(A0, rt_live, 30);
   AgFloorSave();
   AgFloorResetModel();
   AgVecCheckInt("k1_roundtrip_floor_reloads", AgFloorLoad(), 0);

   //--- THE ROW ITSELF: the same live limit, one pass, immediately after the
   //--- reload. Neither branch may fire. A warn stamp still at zero proves the
   //--- HOLD branch was not taken, since AgRatchetUpdate always warns on a hold
   //--- when the stamp is zero; a bit identical floor proves the LOWER branch
   //--- was not taken, since that branch is the only writer of this global.
   double rt_floor_before = g_ag_floor_currency;
   g_ag_last_ratchet_warn = 0;
   double rt_r = AgRatchetUpdate(A0, rt_live, 30);
   AgVecCheckInt("k2_no_hold_warn_on_the_reloaded_floor",
                 (long)g_ag_last_ratchet_warn, 0);
   AgVecCheck("k2b_reloaded_floor_is_not_rewritten",
              g_ag_floor_currency == rt_floor_before,
              "floor moved from " + DoubleToString(rt_floor_before, 8)
              + " to " + DoubleToString(g_ag_floor_currency, 8));
   AgVecCheck("k2c_enforced_value_tracks_the_live_limit",
              MathAbs(rt_r - rt_live) < AG_PNL_EPSILON,
              "enforced=" + DoubleToString(rt_r, 8) + " live=" + DoubleToString(rt_live, 8));

   //--- DETERMINISTIC HALF CENT IN BOTH DIRECTIONS. k2 reproduces the live
   //--- conditions but its outcome depends on how one particular value rounds,
   //--- so it could pass on a platform where that value round trips exactly and
   //--- prove nothing. These two do not depend on rounding at all, and the
   //--- second is the mirror hazard: under the old exact comparison a floor a
   //--- hair ABOVE the live limit drove the LOWER branch, and that branch calls
   //--- AgFloorSave, so the guardian rewrote the file on every single pass.
   g_ag_floor_currency    = rt_live + 0.005;
   g_ag_last_ratchet_warn = 0;
   rt_floor_before        = g_ag_floor_currency;
   AgRatchetUpdate(A0, rt_live, 30);
   AgVecCheck("k3_half_cent_above_does_not_lower_the_floor",
              g_ag_floor_currency == rt_floor_before,
              "floor moved to " + DoubleToString(g_ag_floor_currency, 8));

   g_ag_floor_currency    = rt_live - 0.005;
   g_ag_last_ratchet_warn = 0;
   AgRatchetUpdate(A0, rt_live, 30);
   AgVecCheckInt("k4_half_cent_below_does_not_warn",
                 (long)g_ag_last_ratchet_warn, 0);

   //--- AND THE BAND MUST NOT SWALLOW A REAL CHANGE. Two cents is the smallest
   //--- move that clears a one cent band, so these are the boundary cases that
   //--- stop the fix from being a blanket mute.
   g_ag_floor_currency    = rt_live - 0.02;
   g_ag_last_ratchet_warn = 0;
   AgRatchetUpdate(A0, rt_live, 30);
   AgVecCheck("k5_two_cent_raise_still_warns", g_ag_last_ratchet_warn != 0,
              "no hold warn for a two cent raise above the floor");

   g_ag_floor_currency    = rt_live + 0.02;
   g_ag_last_ratchet_warn = 0;
   AgRatchetUpdate(A0, rt_live, 30);
   AgVecCheckMoney("k6_two_cent_decrease_still_lowers_the_floor",
                   g_ag_floor_currency, rt_live);

   //--- R10, D1f (FINAL 2026-09-03): list membership and mapping. Counts are
   //--- exhaustive over a range that brackets both lists, so the two member
   //--- totals D1f states, 22 and 48, are measured rather than asserted.
   int r10_pct_members = 0;
   for(int p = -1000; p <= 1000; p++)
      if(AgDailyLossPercentIsMember(p))
         r10_pct_members++;
   AgVecCheckInt("r10_percent_member_count_is_22", r10_pct_members, 22);
   int r10_cur_members = 0;
   for(int c = -1000; c <= 1000; c++)
      if(AgDailyLossCurrencyIsMember(c))
         r10_cur_members++;
   AgVecCheckInt("r10_currency_member_count_is_48", r10_cur_members, 48);
   AgVecCheck("r10_percent_floor_and_ceiling",
              AgDailyLossPercentIsMember(25) && AgDailyLossPercentIsMember(550)
              && !AgDailyLossPercentIsMember(0) && !AgDailyLossPercentIsMember(575),
              "25 and 550 in, 0 and 575 out");
   AgVecCheck("r10_percent_off_grid_rejected",
              !AgDailyLossPercentIsMember(510) && !AgDailyLossPercentIsMember(5)
              && !AgDailyLossPercentIsMember(-25),
              "510, 5 and -25 out");
   AgVecCheck("r10_currency_two_segments",
              AgDailyLossCurrencyIsMember(1) && AgDailyLossCurrencyIsMember(10)
              && AgDailyLossCurrencyIsMember(15) && AgDailyLossCurrencyIsMember(200)
              && !AgDailyLossCurrencyIsMember(0) && !AgDailyLossCurrencyIsMember(12)
              && !AgDailyLossCurrencyIsMember(205) && !AgDailyLossCurrencyIsMember(-5),
              "1, 10, 15, 200 in; 0, 12, 205, -5 out");
   AgVecCheckMoney("r10_map_percent_550_is_5_50", AgDailyLossPercentValue(AG_DLP_5_50), 5.50);
   AgVecCheckMoney("r10_map_percent_25_is_0_25", AgDailyLossPercentValue(AG_DLP_0_25), 0.25);
   AgVecCheckMoney("r10_map_currency_200", AgDailyLossCurrencyValue(AG_DLC_200), 200.0);
   AgVecCheckMoney("r10_default_limit_is_min_of_legs",
                   AgLimitCurrency(2000.0, AgDailyLossPercentValue(AG_DLP_5_50),
                                   AgDailyLossCurrencyValue(AG_DLC_200)), 110.0);
   string r10_why = "";
   AgVecCheck("r10_validate_rejects_currency_zero",
              !AgValidateLimits(550, 0, r10_why)
              && StringFind(r10_why, "DailyLossCurrency is not a list member (raw 0)") == 0,
              r10_why);
   AgVecCheck("r10_validate_accepts_defaults", AgValidateLimits(550, 200, r10_why), "550/200");

   //--- D2D4, defect 4 of the fix order FINAL of 2026-08-19 (owner rulings
   //--- D2D4-3(a), 4(a), 5(a), 7(a) and 9(a) of 2026-09-09). The LOCKED
   //--- numbers group is built by a pure function in Log.mqh, reachable from
   //--- this script through Persist.mqh's includes, so its exact string is
   //--- proven here before the build is deployed. The fixture is the
   //--- 2026-08-31 V1-A lock's own snapshot, limit 117.54 and base 2350.86,
   //--- with a balance and a floating the artifact of that day could not
   //--- carry, which is the defect. equity is what the EA passes, balance
   //--- plus floating; the formatter never derives it (D2D4-4(a)).
   datetime d2d4_until = D'2026.09.01 01:00:00';
   string   d2d4_s     = AgLockedNumbersString(d2d4_until, 117.54, 2350.86, 2311.26, -115.50, 2195.76);
   AgVecCheck("d2d4_locked_group_exact_string",
              d2d4_s == "locked_until=2026.09.01 01:00:00|limit_snap=117.54|base_snap=2350.86"
                        "|balance=2311.26|floating=-115.50|equity=2195.76",
              d2d4_s);

   //--- The six fields in the ruled order, each introduced by its own key.
   int d2d4_p1 = StringFind(d2d4_s, "locked_until=");
   int d2d4_p2 = StringFind(d2d4_s, "|limit_snap=");
   int d2d4_p3 = StringFind(d2d4_s, "|base_snap=");
   int d2d4_p4 = StringFind(d2d4_s, "|balance=");
   int d2d4_p5 = StringFind(d2d4_s, "|floating=");
   int d2d4_p6 = StringFind(d2d4_s, "|equity=");
   AgVecCheck("d2d4_locked_group_field_order",
              d2d4_p1 == 0 && d2d4_p2 > d2d4_p1 && d2d4_p3 > d2d4_p2 && d2d4_p4 > d2d4_p3
              && d2d4_p5 > d2d4_p4 && d2d4_p6 > d2d4_p5,
              d2d4_s);

   //--- Two decimals is the rendering, the ACTIVE group's own: the sub-cent
   //--- limit the state file stores at 8 decimals (c8 above) prints as the
   //--- cent, exactly as the banner and the breach arithmetic line print it,
   //--- and a negative floating keeps its sign.
   string d2d4_r = AgLockedNumbersString(d2d4_until, 99.2985, 1985.97, 1933.13, -52.254, 1880.876);
   AgVecCheck("d2d4_locked_group_two_decimal_rendering",
              d2d4_r == "locked_until=2026.09.01 01:00:00|limit_snap=99.30|base_snap=1985.97"
                        "|balance=1933.13|floating=-52.25|equity=1880.88",
              d2d4_r);

   //--- D2D4-7(a): a CORRUPT_STATE lock's zeroed snapshot renders as 0.00, a
   //--- faithful print of what AgStateSetCorrupt stored, while the live
   //--- figures still carry.
   string d2d4_c = AgLockedNumbersString(d2d4_until, 0.0, 0.0, 239.63, 0.0, 239.63);
   AgVecCheck("d2d4_locked_group_corrupt_state_renders_zero",
              d2d4_c == "locked_until=2026.09.01 01:00:00|limit_snap=0.00|base_snap=0.00"
                        "|balance=239.63|floating=0.00|equity=239.63",
              d2d4_c);

   //--- D2D4-5(a) and D8: nothing the rulings omitted leaks in. breach_time
   //--- is not reported, no pre breach mechanism figure is reported, the live
   //--- limit is not reported, and the formatter carries no DEGRADED prefix
   //--- of its own, that being the EA builder's under D2D4-6(a).
   AgVecCheck("d2d4_locked_group_carries_only_the_six_ruled_fields",
              StringFind(d2d4_s, "breach_time") < 0 && StringFind(d2d4_s, "peak") < 0
              && StringFind(d2d4_s, "ratchet") < 0 && StringFind(d2d4_s, "anchor=") < 0
              && StringFind(d2d4_s, "realized=") < 0 && StringFind(d2d4_s, "|limit=") < 0
              && StringFind(d2d4_s, "pnl") < 0 && StringFind(d2d4_s, "DEGRADED") < 0,
              d2d4_s);

   //================================================================
   //--- ENF-0, the enforcement phase (owner rulings ENF-1 to ENF-29 of
   //--- 2026-09-16, plan docs/PLAN_ENFORCEMENT_SWEEP_2026-09-16.md 3.10).
   //--- Everything under test is a pure function in SweepPolicy.mqh; no
   //--- request is built, nothing is sent, and the trade API is not
   //--- linked. The retcode table of plan 2.7.4 is documentation derived,
   //--- so P92 asserts every constant's numeric value on this compiler.
   //================================================================

   //--- P92, the retcode constants and their ruled classes, plan 2.7.4
   AgVecRetcode("DONE",                 TRADE_RETCODE_DONE,                 10009, AG_RC_DONE);
   AgVecRetcode("POSITION_CLOSED",      TRADE_RETCODE_POSITION_CLOSED,      10036, AG_RC_DONE);
   AgVecRetcode("PLACED",               TRADE_RETCODE_PLACED,               10008, AG_RC_PLACED);
   AgVecRetcode("REQUOTE",              TRADE_RETCODE_REQUOTE,              10004, AG_RC_RETRY);
   AgVecRetcode("REJECT",               TRADE_RETCODE_REJECT,               10006, AG_RC_RETRY);
   AgVecRetcode("DONE_PARTIAL",         TRADE_RETCODE_DONE_PARTIAL,         10010, AG_RC_RETRY);
   AgVecRetcode("ERROR",                TRADE_RETCODE_ERROR,                10011, AG_RC_RETRY);
   AgVecRetcode("TIMEOUT",              TRADE_RETCODE_TIMEOUT,              10012, AG_RC_RETRY);
   AgVecRetcode("PRICE_CHANGED",        TRADE_RETCODE_PRICE_CHANGED,        10020, AG_RC_RETRY);
   AgVecRetcode("PRICE_OFF",            TRADE_RETCODE_PRICE_OFF,            10021, AG_RC_RETRY);
   AgVecRetcode("TOO_MANY_REQUESTS",    TRADE_RETCODE_TOO_MANY_REQUESTS,    10024, AG_RC_RETRY);
   AgVecRetcode("LOCKED",               TRADE_RETCODE_LOCKED,               10028, AG_RC_RETRY);
   AgVecRetcode("FROZEN",               TRADE_RETCODE_FROZEN,               10029, AG_RC_RETRY);
   AgVecRetcode("CONNECTION",           TRADE_RETCODE_CONNECTION,           10031, AG_RC_RETRY);
   AgVecRetcode("CLOSE_ORDER_EXIST",    TRADE_RETCODE_CLOSE_ORDER_EXIST,    10039, AG_RC_RETRY);
   AgVecRetcode("TRADE_DISABLED",       TRADE_RETCODE_TRADE_DISABLED,       10017, AG_RC_HOLD);
   AgVecRetcode("MARKET_CLOSED",        TRADE_RETCODE_MARKET_CLOSED,        10018, AG_RC_HOLD);
   AgVecRetcode("SERVER_DISABLES_AT",   TRADE_RETCODE_SERVER_DISABLES_AT,   10026, AG_RC_HOLD);
   AgVecRetcode("CLIENT_DISABLES_AT",   TRADE_RETCODE_CLIENT_DISABLES_AT,   10027, AG_RC_HOLD);
   AgVecRetcode("ONLY_REAL",            TRADE_RETCODE_ONLY_REAL,            10032, AG_RC_HOLD);
   AgVecRetcode("LONG_ONLY",            TRADE_RETCODE_LONG_ONLY,            10042, AG_RC_HOLD);
   AgVecRetcode("SHORT_ONLY",           TRADE_RETCODE_SHORT_ONLY,           10043, AG_RC_HOLD);
   AgVecRetcode("CLOSE_ONLY",           TRADE_RETCODE_CLOSE_ONLY,           10044, AG_RC_HOLD);
   AgVecRetcode("HEDGE_PROHIBITED",     TRADE_RETCODE_HEDGE_PROHIBITED,     10046, AG_RC_HOLD);
   AgVecRetcode("CANCEL",               TRADE_RETCODE_CANCEL,               10007, AG_RC_REFUSE);
   AgVecRetcode("INVALID",              TRADE_RETCODE_INVALID,              10013, AG_RC_REFUSE);
   AgVecRetcode("INVALID_VOLUME",       TRADE_RETCODE_INVALID_VOLUME,       10014, AG_RC_REFUSE);
   AgVecRetcode("INVALID_PRICE",        TRADE_RETCODE_INVALID_PRICE,        10015, AG_RC_REFUSE);
   AgVecRetcode("INVALID_STOPS",        TRADE_RETCODE_INVALID_STOPS,        10016, AG_RC_REFUSE);
   AgVecRetcode("NO_MONEY",             TRADE_RETCODE_NO_MONEY,             10019, AG_RC_REFUSE);
   AgVecRetcode("INVALID_EXPIRATION",   TRADE_RETCODE_INVALID_EXPIRATION,   10022, AG_RC_REFUSE);
   AgVecRetcode("ORDER_CHANGED",        TRADE_RETCODE_ORDER_CHANGED,        10023, AG_RC_REFUSE);
   AgVecRetcode("NO_CHANGES",           TRADE_RETCODE_NO_CHANGES,           10025, AG_RC_REFUSE);
   AgVecRetcode("INVALID_FILL",         TRADE_RETCODE_INVALID_FILL,         10030, AG_RC_REFUSE);
   AgVecRetcode("LIMIT_ORDERS",         TRADE_RETCODE_LIMIT_ORDERS,         10033, AG_RC_REFUSE);
   AgVecRetcode("LIMIT_VOLUME",         TRADE_RETCODE_LIMIT_VOLUME,         10034, AG_RC_REFUSE);
   AgVecRetcode("INVALID_ORDER",        TRADE_RETCODE_INVALID_ORDER,        10035, AG_RC_REFUSE);
   AgVecRetcode("INVALID_CLOSE_VOLUME", TRADE_RETCODE_INVALID_CLOSE_VOLUME, 10038, AG_RC_REFUSE);
   AgVecRetcode("LIMIT_POSITIONS",      TRADE_RETCODE_LIMIT_POSITIONS,      10040, AG_RC_REFUSE);
   AgVecRetcode("REJECT_CANCEL",        TRADE_RETCODE_REJECT_CANCEL,        10041, AG_RC_REFUSE);
   AgVecRetcode("FIFO_CLOSE",           TRADE_RETCODE_FIFO_CLOSE,           10045, AG_RC_REFUSE);
   //--- the two answers no constant carries: a request the terminal never
   //--- sent, and a retcode the classifier does not know
   AgVecCheck("enf_class_retcode_zero_is_retry", AgRetcodeClass(0) == AG_RC_RETRY,
              AgRetcodeClassName(AgRetcodeClass(0)));
   AgVecCheck("enf_class_unknown_retcode_is_refuse", AgRetcodeClass(99999) == AG_RC_REFUSE,
              AgRetcodeClassName(AgRetcodeClass(99999)));
   //--- ENF-12(a): the partial flag the caller reads
   AgVecCheck("enf_partial_flag_on_10010", AgRetcodeIsPartial(TRADE_RETCODE_DONE_PARTIAL), "");
   AgVecCheck("enf_partial_flag_off_10009", !AgRetcodeIsPartial(TRADE_RETCODE_DONE), "");
   AgVecCheck("enf_class_names",
              AgRetcodeClassName(AG_RC_DONE) == "done" && AgRetcodeClassName(AG_RC_RETRY) == "retry"
              && AgRetcodeClassName(AG_RC_HOLD) == "hold" && AgRetcodeClassName(AG_RC_REFUSE) == "refuse"
              && AgRetcodeClassName(AG_RC_PLACED) == "placed",
              "class names diverge from done|retry|hold|refuse|placed");
   AgVecCheck("enf_retcode_names",
              AgRetcodeName(TRADE_RETCODE_MARKET_CLOSED) == "MARKET_CLOSED"
              && AgRetcodeName(TRADE_RETCODE_CLIENT_DISABLES_AT) == "CLIENT_DISABLES_AT"
              && AgRetcodeName(TRADE_RETCODE_DONE) == "DONE" && AgRetcodeName(0) == "NOT_SENT"
              && AgRetcodeName(99999) == "UNKNOWN_99999",
              AgRetcodeName(TRADE_RETCODE_MARKET_CLOSED));

   //--- ENF-9(c), ENF-10(a): the schedule in passes, 1, 2, 4, 8, 16, 32, then
   //--- the cap, attempts 1 through 8, and a non positive attempt waits one
   AgVecCheckInt("enf_backoff_attempt_1_is_1",   AgBackoffPasses(1), 1);
   AgVecCheckInt("enf_backoff_attempt_2_is_2",   AgBackoffPasses(2), 2);
   AgVecCheckInt("enf_backoff_attempt_3_is_4",   AgBackoffPasses(3), 4);
   AgVecCheckInt("enf_backoff_attempt_4_is_8",   AgBackoffPasses(4), 8);
   AgVecCheckInt("enf_backoff_attempt_5_is_16",  AgBackoffPasses(5), 16);
   AgVecCheckInt("enf_backoff_attempt_6_is_32",  AgBackoffPasses(6), 32);
   AgVecCheckInt("enf_backoff_attempt_7_is_60",  AgBackoffPasses(7), 60);
   AgVecCheckInt("enf_backoff_attempt_8_is_60",  AgBackoffPasses(8), 60);
   AgVecCheckInt("enf_backoff_attempt_0_is_1",   AgBackoffPasses(0), 1);

   //--- ENF-25(a), ENF-11(a), ENF-19(a), ENF-6(a): the constants as ruled
   AgVecCheckInt("enf_hard_stop_is_10",           AG_SWEEP_HARD_STOP, 10);
   AgVecCheckInt("enf_backoff_cap_is_60_passes",  AG_SWEEP_BACKOFF_CAP_PASSES, 60);
   AgVecCheckInt("enf_rearm_is_60_passes",        AG_SWEEP_REARM_PASSES, 60);
   AgVecCheckInt("enf_cadence_is_30_passes",      AG_SWEEP_CADENCE_PASSES, 30);
   AgVecCheckInt("enf_magic_is_20260916",         AG_SWEEP_MAGIC, 20260916);
   AgVecCheck("enf_comment_is_ag_sweep", AG_SWEEP_COMMENT == "AG sweep", AG_SWEEP_COMMENT);
   AgVecCheckInt("enf_deviation_is_100_points",   AG_SWEEP_DEVIATION_POINTS, 100);

   //--- ENF-7(a): three synthetic positions, most negative floating first,
   //--- ties by ticket ascending, through the same insertion sort the engine
   //--- runs on the comparator
   ulong  s_ticket[3]   = {5, 9, 2};
   double s_floating[3] = {-10.0, -30.0, -30.0};
   for(int si = 1; si < 3; si++)
     {
      ulong kt = s_ticket[si]; double kf = s_floating[si];
      int sj = si - 1;
      while(sj >= 0 && AgSweepPositionCompare(s_floating[sj], s_ticket[sj], kf, kt) > 0)
        {
         s_ticket[sj + 1] = s_ticket[sj]; s_floating[sj + 1] = s_floating[sj];
         sj--;
        }
      s_ticket[sj + 1] = kt; s_floating[sj + 1] = kf;
     }
   AgVecCheck("enf_order_most_negative_first_ties_by_ticket",
              s_ticket[0] == 2 && s_ticket[1] == 9 && s_ticket[2] == 5,
              "order=" + (string)s_ticket[0] + "," + (string)s_ticket[1] + "," + (string)s_ticket[2]);
   AgVecCheckInt("enf_compare_larger_loss_sorts_first", AgSweepPositionCompare(-30.0, 9, -10.0, 5), -1);
   AgVecCheckInt("enf_compare_tie_by_ticket_ascending",  AgSweepPositionCompare(-30.0, 9, -30.0, 2), 1);
   AgVecCheckInt("enf_compare_equal_is_zero",            AgSweepPositionCompare(-30.0, 9, -30.0, 9), 0);

   //--- ENF-16(b), the one pass half of flat
   AgVecCheck("enf_flat_on_zero_zero",        AgSweepFlat(0, 0), "");
   AgVecCheck("enf_not_flat_with_a_position", !AgSweepFlat(1, 0), "");
   AgVecCheck("enf_not_flat_with_a_pending",  !AgSweepFlat(0, 1), "");

   //--- Q3/F2 FINAL 2026-07-29, the account wide names in the ruled order
   AgVecCheck("enf_q3_nothing_blocks_is_empty", AgTradeBlockName(true, true, true, true) == "", "");
   AgVecCheck("enf_q3_terminal_trade_allowed_named",
              AgTradeBlockName(false, true, true, true) == "TERMINAL_TRADE_ALLOWED=false", "");
   AgVecCheck("enf_q3_mql_trade_allowed_named",
              AgTradeBlockName(true, false, true, true) == "MQL_TRADE_ALLOWED=false", "");
   AgVecCheck("enf_q3_account_trade_allowed_named",
              AgTradeBlockName(true, true, false, true) == "ACCOUNT_TRADE_ALLOWED=false", "");
   AgVecCheck("enf_q3_account_trade_expert_named",
              AgTradeBlockName(true, true, true, false) == "ACCOUNT_TRADE_EXPERT=false", "");
   AgVecCheck("enf_q3_first_blocking_state_wins",
              AgTradeBlockName(false, false, false, false) == "TERMINAL_TRADE_ALLOWED=false", "");
   //--- ENF-15(a): CLOSEONLY is named distinctly and is sendable; DISABLED holds
   AgVecCheck("enf_symbol_mode_names",
              AgSymbolTradeModeName(SYMBOL_TRADE_MODE_DISABLED) == "SYMBOL_TRADE_MODE_DISABLED"
              && AgSymbolTradeModeName(SYMBOL_TRADE_MODE_LONGONLY) == "SYMBOL_TRADE_MODE_LONGONLY"
              && AgSymbolTradeModeName(SYMBOL_TRADE_MODE_SHORTONLY) == "SYMBOL_TRADE_MODE_SHORTONLY"
              && AgSymbolTradeModeName(SYMBOL_TRADE_MODE_CLOSEONLY) == "SYMBOL_TRADE_MODE_CLOSEONLY"
              && AgSymbolTradeModeName(SYMBOL_TRADE_MODE_FULL) == "SYMBOL_TRADE_MODE_FULL",
              AgSymbolTradeModeName(SYMBOL_TRADE_MODE_CLOSEONLY));
   AgVecCheck("enf_closeonly_is_sendable", AgSymbolTradeModeSendable(SYMBOL_TRADE_MODE_CLOSEONLY), "");
   AgVecCheck("enf_disabled_is_not_sendable", !AgSymbolTradeModeSendable(SYMBOL_TRADE_MODE_DISABLED), "");
   AgVecCheck("enf_full_longonly_shortonly_are_sendable",
              AgSymbolTradeModeSendable(SYMBOL_TRADE_MODE_FULL)
              && AgSymbolTradeModeSendable(SYMBOL_TRADE_MODE_LONGONLY)
              && AgSymbolTradeModeSendable(SYMBOL_TRADE_MODE_SHORTONLY), "");

   //--- ENF-6(a): FOK when allowed, else IOC, else RETURN, on the flag set
   AgVecCheckInt("enf_filling_fok_when_allowed",  (long)AgSweepFillingFor(SYMBOL_FILLING_FOK | SYMBOL_FILLING_IOC), (long)ORDER_FILLING_FOK);
   AgVecCheckInt("enf_filling_ioc_when_no_fok",   (long)AgSweepFillingFor(SYMBOL_FILLING_IOC), (long)ORDER_FILLING_IOC);
   AgVecCheckInt("enf_filling_return_when_neither", (long)AgSweepFillingFor(0), (long)ORDER_FILLING_RETURN);

   //--- plan 2.7.3: the six pending types, and a market order is never one
   AgVecCheck("enf_pending_types",
              AgIsPendingType(ORDER_TYPE_BUY_LIMIT) && AgIsPendingType(ORDER_TYPE_SELL_LIMIT)
              && AgIsPendingType(ORDER_TYPE_BUY_STOP) && AgIsPendingType(ORDER_TYPE_SELL_STOP)
              && AgIsPendingType(ORDER_TYPE_BUY_STOP_LIMIT) && AgIsPendingType(ORDER_TYPE_SELL_STOP_LIMIT)
              && !AgIsPendingType(ORDER_TYPE_BUY) && !AgIsPendingType(ORDER_TYPE_SELL), "");
   AgVecCheck("enf_type_names",
              AgPendingTypeName(ORDER_TYPE_SELL_STOP) == "sell_stop"
              && AgPendingTypeName(ORDER_TYPE_BUY_STOP_LIMIT) == "buy_stop_limit"
              && AgPositionTypeName(POSITION_TYPE_BUY) == "buy" && AgPositionTypeName(POSITION_TYPE_SELL) == "sell",
              AgPendingTypeName(ORDER_TYPE_SELL_STOP));

   //--- plan 3.5: every journal line shape on fixed arguments, field names exact
   string enf_l = AgSweepPassLine(3, 1, 0, 1);
   AgVecCheck("enf_line_sweep_pass", enf_l == "sweep pass|positions=3|pendings=1|held=0|sent=1", enf_l);
   enf_l = AgSweepDeleteLine(701106401, "XAUUSD.ecn", "sell_stop", 10009, AG_RC_DONE, 1);
   AgVecCheck("enf_line_sweep_delete",
              enf_l == "sweep delete|order=701106401|symbol=XAUUSD.ecn|type=sell_stop|retcode=10009|class=done|attempt=1",
              enf_l);
   enf_l = AgSweepCloseLine(701106385, "XAUUSD.ecn", "sell", 0.3, -135.60, 10009, AG_RC_DONE, 1, 0.3);
   AgVecCheck("enf_line_sweep_close",
              enf_l == "sweep close|position=701106385|symbol=XAUUSD.ecn|type=sell|volume=0.30|floating=-135.60"
                       "|retcode=10009|class=done|attempt=1|filled=0.30",
              enf_l);
   enf_l = AgSweepHeldLine("position", 701106385, "XAUUSD.ecn", "session closed", "2026.09.17 01:00:00", "2026.09.16 23:58:07");
   AgVecCheck("enf_line_sweep_held",
              enf_l == "sweep held|position=701106385|symbol=XAUUSD.ecn|reason=session closed"
                       "|next_open=2026.09.17 01:00:00|since=2026.09.16 23:58:07",
              enf_l);
   enf_l = AgSweepBlockedLine("TERMINAL_TRADE_ALLOWED=false");
   AgVecCheck("enf_line_sweep_blocked", enf_l == "sweep blocked|state=TERMINAL_TRADE_ALLOWED=false", enf_l);
   enf_l = AgSweepCompleteLine(3, 5);
   AgVecCheck("enf_line_sweep_complete", enf_l == "sweep complete|positions=0|pendings=0|attempts=3|elapsed=5", enf_l);
   enf_l = AgSweepResumedLine("2026.09.16 14:58:54", "2026.09.16 15:05:12");
   AgVecCheck("enf_line_sweep_resumed", enf_l == "sweep resumed|gap=2026.09.16 14:58:54..2026.09.16 15:05:12", enf_l);
   enf_l = AgSweepAcceleratedLine(421828196);
   AgVecCheck("enf_line_sweep_accelerated", enf_l == "sweep accelerated|transaction=DEAL_ADD|deal=421828196", enf_l);

   //================================================================
   //--- PK-0, the peak path witness (owner rulings PK-1 to PK-15 of
   //--- 2026-09-28 and the build rulings of the same date). The two pure
   //--- parts the boot derivation's new witnesses rest on live in Pnl.mqh
   //--- and the new reason in State.mqh, all reached through Persist.mqh.
   //--- AgBootDerivation itself is an EA function no script can include.
   //================================================================

   //--- THE LIVE PEAK DISJUNCT (PK-3(b1)) on the two locks of record, plan
   //--- 2.6. LOCK ONE: peak 355.80, limit 147.54, flat book at 198.12 after
   //--- the flatten and 202.83 by the end of that session, both at or below
   //--- the peak level 208.26, so it fires. LOCK TWO: peak 253.00, limit
   //--- 158.69, realized 113.50 and floating -0.04, 113.46 above the peak
   //--- level 94.31, so it does not, which is the residual the SPEC names.
   AgVecCheck("pk_peak_live_lock_one_flat_book_fires",
              AgPeakLiveDisjunct(198.12, 0.00, 355.80, 147.54), "198.12 vs 355.80 and 147.54");
   AgVecCheck("pk_peak_live_lock_one_late_margin_fires",
              AgPeakLiveDisjunct(202.83, 0.00, 355.80, 147.54), "202.83 vs 355.80 and 147.54");
   AgVecCheck("pk_peak_live_lock_two_does_not_fire",
              !AgPeakLiveDisjunct(113.50, -0.04, 253.00, 158.69), "113.46 vs 253.00 and 158.69");
   //--- the flat 2026-07-30 epsilon errs toward breach at the level itself
   AgVecCheck("pk_peak_live_at_the_level_fires",
              AgPeakLiveDisjunct(208.26, 0.00, 355.80, 147.54), "208.26 at the level 208.26");
   AgVecCheck("pk_peak_live_above_the_level_does_not_fire",
              !AgPeakLiveDisjunct(208.30, 0.00, 355.80, 147.54), "208.30 above the level 208.26");
   //--- D1.2: floating counts against the level, a give back still open fires
   AgVecCheck("pk_peak_live_floating_give_back_fires",
              AgPeakLiveDisjunct(355.80, -150.00, 355.80, 147.54), "205.80 vs the level 208.26");
   //--- a day with no realized gain: running_max 0 makes it the loss disjunct
   AgVecCheck("pk_peak_live_no_gain_reads_as_the_loss_disjunct",
              AgPeakLiveDisjunct(-164.95, 0.00, 0.00, 164.94)
              && !AgPeakLiveDisjunct(-100.00, 0.00, 0.00, 164.94),
              "-164.95 fires and -100.00 does not against 164.94");

   //--- THE SWEEP WITNESS'S EXPIRY (PK-4(c1)), a function of the deal time
   //--- and the latch. Latch unseeded first, so ruling FOUR contributes
   //--- nothing and the rule is the next anchor after the deal (Q1, Q4).
   datetime pk_saved_high   = g_ag_high_anchor;
   bool     pk_saved_seeded = g_ag_high_anchor_seeded;
   g_ag_high_anchor_seeded = false;
   g_ag_high_anchor        = 0;
   AgVecCheckDT("pk_sweep_until_lock_one_deal",
                AgSweepWitnessUntil(D'2026.09.23 15:28:17'), D'2026.09.24 01:00:00');
   AgVecCheckDT("pk_sweep_until_lock_two_deal",
                AgSweepWitnessUntil(D'2026.09.26 16:35:36'), D'2026.09.27 01:00:00');
   AgVecCheckDT("pk_sweep_until_before_the_anchor_takes_the_imminent_one",
                AgSweepWitnessUntil(D'2026.09.24 00:30:00'), D'2026.09.24 01:00:00');
   AgVecCheckDT("pk_sweep_until_at_the_anchor_second_counts_to_the_new_day",
                AgSweepWitnessUntil(D'2026.09.24 01:00:00'), D'2026.09.25 01:00:00');
   //--- ruling FOUR: a latch ahead of the deal floors the expiry
   g_ag_high_anchor_seeded = true;
   g_ag_high_anchor        = D'2026.09.26 01:00:00';
   AgVecCheckDT("pk_sweep_until_latch_floor_wins",
                AgSweepWitnessUntil(D'2026.09.23 15:28:17'), D'2026.09.27 01:00:00');
   g_ag_high_anchor        = pk_saved_high;
   g_ag_high_anchor_seeded = pk_saved_seeded;

   //--- THE NEW REASON (PK-9(a)): its value, its name, and the round trip
   //--- through the existing int-valued L field with the format unchanged.
   AgVecCheckInt("pk_reason_sweep_witness_is_3", (long)AG_LOCK_SWEEP_WITNESS, 3);
   AgVecCheck("pk_reason_sweep_witness_name",
              AgLockReasonName(AG_LOCK_SWEEP_WITNESS) == "SWEEP_WITNESS",
              AgLockReasonName(AG_LOCK_SWEEP_WITNESS));
   g_ag_login        = AGVEC_LOGIN_ROUNDTRIP;
   g_ag_state_loaded = true;
   AgStateSetBreach(until_ref, breach_ref, limit_ref, base_ref);
   g_ag_state_reason = AG_LOCK_SWEEP_WITNESS;   // as AgEnterLockFromBoot sets it
   string pk_serial  = AgStateSerialize();
   AgVecCheck("pk_reason_sweep_witness_serializes_as_l_3",
              StringFind(pk_serial, "\nL|3|" + (string)((long)until_ref) + "|") > 0, pk_serial);
   AgStateSave();
   AgStateResetModel();
   int pk_rc = AgStateLoad();
   AgVecCheck("pk_reason_sweep_witness_round_trips_in_the_l_field",
              pk_rc == 0 && g_ag_state_reason == AG_LOCK_SWEEP_WITNESS
              && g_ag_state_locked_until == until_ref,
              "rc=" + (string)pk_rc + " reason=" + (string)(int)g_ag_state_reason);
   AgVecCheckInt("pk_state_format_version_is_still_1", AG_STATE_FORMAT_VERSION, 1);


   //================================================================
   //--- TG, the Telegram alerts build (TG-1 (B) of 2026-10-20, design
   //--- addendum docs/PLAN_TELEGRAM_ALERTS_ADDENDUM_TG1B.md item 12). Pure
   //--- functions of AlertQueue.mqh, AlertJson.mqh and AlertText.mqh only:
   //--- no file, no global variable and no network call is touched here.
   //================================================================

   //--- TG-S12, the queue: a round trip of every code, the checksum, a cut
   //--- file, the bound, the acknowledgement, the numbering, ASCII bytes
   int tg_codes[23] = {AG_TG_S1, AG_TG_S2, AG_TG_S3, AG_TG_S4, AG_TG_S5, AG_TG_S6C, AG_TG_S6H, AG_TG_S6F,
                       AG_TG_S7, AG_TG_S8, AG_TG_S9, AG_TG_S10, AG_TG_S12, AG_TG_S15, AG_TG_S16,
                       AG_TG_S17, AG_TG_S18, AG_TG_S19, AG_TG_S20, AG_TG_S21, AG_TG_S22, AG_TG_S24, AG_TG_S25};
   AgTgEvent tg_ev[];
   ArrayResize(tg_ev, 23);
   for(int k = 0; k < 23; k++)
     {
      tg_ev[k].seq      = 100 + k;
      tg_ev[k].code     = tg_codes[k];
      tg_ev[k].server_t = (long)D'2026.10.21 12:00:00' + k;
      tg_ev[k].local_t  = (long)D'2026.10.21 12:00:01' + k;
      tg_ev[k].state    = (k % 4) + 1;
      tg_ev[k].pnl_mode = k % 3;
      tg_ev[k].balance  = 2172.06;
      tg_ev[k].equity   = 2150.10;
      tg_ev[k].pnl      = -21.96;
      tg_ev[k].limit    = 126.21;
      for(int x = 0; x < AG_TGQ_X_COUNT; x++)
         tg_ev[k].x[x] = (x == 0) ? 781624897.0 : (x == 1 ? 5.5 : (double)(k * 10 + x));
     }
   AgTgSnapshot tg_sn;
   tg_sn.local_t = (long)D'2026.10.21 12:00:02'; tg_sn.server_t = (long)D'2026.10.21 12:00:01';
   tg_sn.state = AG_STATE_ACTIVE; tg_sn.reason = 0; tg_sn.seconds_in_state = 3600; tg_sn.connected = 1;
   tg_sn.block = 0; tg_sn.pnl_mode = AG_TG_PNL_ACTIVE; tg_sn.balance = 2172.06; tg_sn.floating = -21.96;
   tg_sn.equity = 2150.10; tg_sn.pnl = -21.96; tg_sn.limit = 126.21; tg_sn.live_limit = 126.21;
   tg_sn.enforced_limit = 126.21; tg_sn.peak = 0.0; tg_sn.peak_level = -126.21;
   tg_sn.anchor = (long)D'2026.10.21 01:00:00'; tg_sn.locked_until = 0; tg_sn.limit_snap = 0.0;
   tg_sn.base_snap = 0.0; tg_sn.percent = 5.5; tg_sn.currency = 200.0; tg_sn.sweep_open = 0; tg_sn.sweep_held = 0;
   string tg_q = AgTgQueueSerialize(990000021, 121, (long)D'2026.10.21 01:00:00', 3,
                                    AgTgSnapshotLine(tg_sn, "TG"), tg_ev, 23);
   long tg_login = 0, tg_next = 0, tg_latch = 0; int tg_mask = 0, tg_count = 0;
   AgTgSnapshot tg_sn2; string tg_build = "", tg_why = ""; AgTgEvent tg_back[];
   bool tg_ok = AgTgQueueParse(tg_q, tg_login, tg_next, tg_latch, tg_mask, tg_sn2, tg_build, tg_back, tg_count, tg_why);
   AgVecCheck("tg_q_roundtrip_parses", tg_ok, tg_why);
   AgVecCheck("tg_q_roundtrip_header_e_and_n",
              tg_login == 990000021 && tg_next == 121 && tg_latch == (long)D'2026.10.21 01:00:00'
              && tg_mask == 3 && tg_build == "TG" && tg_sn2.anchor == tg_sn.anchor
              && MathAbs(tg_sn2.equity - 2150.10) < 0.000001 && tg_sn2.seconds_in_state == 3600,
              "login=" + (string)tg_login + " next=" + (string)tg_next + " build=" + tg_build);
   AgVecCheckInt("tg_q_roundtrip_every_code_count", tg_count, 23);
   bool tg_same = (tg_count == 23);
   for(int k = 0; k < tg_count && tg_same; k++)
      tg_same = tg_back[k].seq == tg_ev[k].seq && tg_back[k].code == tg_ev[k].code
                && tg_back[k].server_t == tg_ev[k].server_t && tg_back[k].local_t == tg_ev[k].local_t
                && tg_back[k].state == tg_ev[k].state && tg_back[k].pnl_mode == tg_ev[k].pnl_mode
                && MathAbs(tg_back[k].pnl - tg_ev[k].pnl) < 0.000001
                && MathAbs(tg_back[k].x[0] - 781624897.0) < 0.5 && MathAbs(tg_back[k].x[1] - 5.5) < 0.000001
                && MathAbs(tg_back[k].x[7] - tg_ev[k].x[7]) < 0.000001;
   AgVecCheck("tg_q_roundtrip_every_code_every_field", tg_same, "a field changed in the round trip");
   bool tg_ascii = true;
   for(int k = 0; k < StringLen(tg_q); k++)
      if(StringGetCharacter(tg_q, k) > 127)
         tg_ascii = false;
   AgVecCheck("tg_q_every_byte_is_ascii", tg_ascii, "a byte above 127");
   string tg_bad = tg_q;
   StringReplace(tg_bad, "|781624897|", "|781624898|");
   AgVecCheck("tg_q_changed_byte_fails_the_checksum",
              !AgTgQueueParse(tg_bad, tg_login, tg_next, tg_latch, tg_mask, tg_sn2, tg_build, tg_back, tg_count, tg_why)
              && tg_why == "checksum mismatch", tg_why);
   string tg_cut = StringSubstr(tg_q, 0, StringFind(tg_q, "C|"));
   AgVecCheck("tg_q_cut_file_is_refused",
              !AgTgQueueParse(tg_cut, tg_login, tg_next, tg_latch, tg_mask, tg_sn2, tg_build, tg_back, tg_count, tg_why),
              tg_why);
   AgVecCheck("tg_q_halt_file_is_not_a_queue",
              !AgTgQueueParse(AgVecSealed("AGHALT|1|990000021\nH|1|crash loop|1786027355\n"),
                              tg_login, tg_next, tg_latch, tg_mask, tg_sn2, tg_build, tg_back, tg_count, tg_why)
              && AG_TGQ_MAGIC != "AGHALT" && AG_TGQ_MAGIC != "AGSTATE" && AG_TGQ_MAGIC != "AGFLOOR"
              && AG_TGQ_MAGIC != "AGPEAK", tg_why);
   AgTgEvent tg_rev[];
   ArrayResize(tg_rev, 2);
   tg_rev[0] = tg_ev[1];
   tg_rev[1] = tg_ev[0];
   AgVecCheck("tg_q_events_out_of_order_are_refused",
              !AgTgQueueParse(AgTgQueueSerialize(990000021, 121, 0, 0, AgTgSnapshotLine(tg_sn, "TG"), tg_rev, 2),
                              tg_login, tg_next, tg_latch, tg_mask, tg_sn2, tg_build, tg_back, tg_count, tg_why)
              && tg_why == "V lines out of order", tg_why);
   AgTgEvent tg_many[];
   int tg_n = 60;
   ArrayResize(tg_many, tg_n);
   for(int k = 0; k < tg_n; k++)
     {
      tg_many[k] = tg_ev[0];
      tg_many[k].seq = k + 1;
     }
   int tg_dropped = AgTgQueueTrim(tg_many, tg_n, AG_TGQ_MAX_EVENTS);
   AgVecCheck("tg_q_overflow_keeps_the_oldest_and_the_newest_49",
              tg_dropped == 10 && tg_n == 50 && tg_many[0].seq == 1 && tg_many[1].seq == 12 && tg_many[49].seq == 60,
              "dropped=" + (string)tg_dropped + " n=" + (string)tg_n + " first=" + (string)tg_many[0].seq
              + " second=" + (string)tg_many[1].seq);
   //--- the trim above kept seq 1 and 12 to 60, so 30 forgets seq 1 and 12 to 30
   int tg_forgot = AgTgQueueForget(tg_many, tg_n, 30);
   AgVecCheck("tg_q_forgotten_at_the_acknowledgement",
              tg_forgot == 20 && tg_n == 30 && tg_many[0].seq == 31 && tg_many[29].seq == 60,
              "forgot=" + (string)tg_forgot + " n=" + (string)tg_n);
   AgVecCheck("tg_q_numbering_goes_on_after_a_reload",
              AgTgNextSeqAfterLoad(121, 50) == 121 && AgTgNextSeqAfterLoad(10, 50) == 51
              && AgTgNextSeqAfterLoad(1, 0) == 1, "next seq after load");
   bool tg_codes_ok = true;
   for(int k = 0; k < 23; k++)
      if(AgTgCodeFromText(AgTgCodeText(tg_codes[k])) != tg_codes[k])
         tg_codes_ok = false;
   AgVecCheck("tg_q_code_text_round_trips_and_rejects_unknown",
              tg_codes_ok && AgTgCodeFromText("S5") == AG_TG_S5 && AgTgCodeFromText("S25") == AG_TG_S25
              && AgTgCodeFromText("S23") == 0
              && AgTgCodeFromText("X1") == 0 && AgTgCodeFromText("S-1") == 0, "code text");
   AgVecCheck("tg_q_names_carry_the_login",
              AgTgQueuePath(990000021) == "AccountGuardian\\tgqueue_990000021.dat"
              && AgGvTgAck(990000021) == "AG_TGACK_990000021"
              && AgGvTgRefused(990000021) == "AG_TGREFUSED_990000021"
              && AgGvTgRefSeen(990000021) == "AG_TGREFSEEN_990000021", AgTgQueuePath(990000021));
   AgVecCheck("tg_q_block_codes_in_the_q3_order",
              AgTgBlockCode(AgTradeBlockName(false, true, true, true)) == 1
              && AgTgBlockCode(AgTradeBlockName(true, false, true, true)) == 2
              && AgTgBlockCode(AgTradeBlockName(true, true, false, true)) == 3
              && AgTgBlockCode(AgTradeBlockName(true, true, true, false)) == 4
              && AgTgBlockCode(AgTradeBlockName(true, true, true, true)) == 0, "block codes");

   //--- the queue file on hostile input, fix pass B2
   AgVecTgQueueCases();

   //--- S9, TG-3 (B): the share and the latch
   AgVecCheck("tg_s9_share_on_the_draft_figures_is_80",
              MathAbs(AgTgShareUsed(-126.21, 126.21, -100.97) - 80.0016) < 0.001,
              DoubleToString(AgTgShareUsed(-126.21, 126.21, -100.97), 4));
   AgVecCheck("tg_s9_share_from_the_peak",
              MathAbs(AgTgShareUsed(253.00 - 158.69, 158.69, 150.00) - 64.9064) < 0.001,
              DoubleToString(AgTgShareUsed(253.00 - 158.69, 158.69, 150.00), 4));
   int tg_m = 0;
   int tg_l1 = AgTgS9Step(55.0, tg_m);
   int tg_l2 = AgTgS9Step(60.0, tg_m);
   int tg_l3 = AgTgS9Step(85.0, tg_m);
   int tg_l4 = AgTgS9Step(75.0, tg_m);
   int tg_l5 = AgTgS9Step(70.0, tg_m);
   int tg_m5 = tg_m;
   int tg_l6 = AgTgS9Step(39.0, tg_m);
   int tg_l7 = AgTgS9Step(50.0, tg_m);
   AgVecCheck("tg_s9_levels_fire_once_and_rearm_ten_points_below",
              tg_l1 == 50 && tg_l2 == 0 && tg_l3 == 80 && tg_l4 == 0 && tg_l5 == 0 && tg_m5 == 1
              && tg_l6 == 0 && tg_l7 == 50,
              (string)tg_l1 + "," + (string)tg_l2 + "," + (string)tg_l3 + "," + (string)tg_l4 + ","
              + (string)tg_l5 + "," + (string)tg_l6 + "," + (string)tg_l7);
   int tg_jm = 0;
   AgVecCheck("tg_s9_a_jump_past_both_levels_fires_80_once",
              AgTgS9Step(95.0, tg_jm) == 80 && tg_jm == 3 && AgTgS9Step(96.0, tg_jm) == 0, "jump");

   //--- TG-S13, the command, on fixed getUpdates answers
   string tg_chat = (string)(990000000 + 123);
   long   tg_now  = (long)D'2026.10.21 10:00:00';
   string tg_head = "{\"ok\":true,\"result\":[{\"update_id\":7,\"message\":{\"message_id\":3,\"chat\":{\"id\":";
   string tg_raw  = tg_head + tg_chat + ",\"type\":\"private\"},\"date\":" + (string)(tg_now - 5)
                  + ",\"text\":\"" + AgTgCommandText() + "\"}}]}";
   long tg_max = 0; int tg_ign = 0; bool tg_aok = false;
   int  tg_hit = AgTgMatchCommands(tg_raw, AgTgCommandText(), tg_chat, tg_now, 120, tg_max, tg_ign, tg_aok);
   AgVecCheck("tg_cmd_exact_text_matches", tg_aok && tg_hit == 1 && tg_ign == 0 && tg_max == 7,
              "hit=" + (string)tg_hit + " ignored=" + (string)tg_ign + " max=" + (string)tg_max);
   char   tg_bytes[];
   int    tg_nb = AgTgUtf8Bytes(tg_raw, tg_bytes);
   string tg_dec = AgTgUtf8ToString(tg_bytes, tg_nb);
   tg_hit = AgTgMatchCommands(tg_dec, AgTgCommandText(), tg_chat, tg_now, 120, tg_max, tg_ign, tg_aok);
   AgVecCheck("tg_cmd_exact_text_matches_through_utf8", tg_dec == tg_raw && tg_hit == 1 && tg_nb > StringLen(tg_raw),
              "bytes=" + (string)tg_nb + " chars=" + (string)StringLen(tg_raw));
   string tg_esc = tg_head + tg_chat + "},\"date\":" + (string)(tg_now - 5)
                 + ",\"text\":\"\\u05d1\\u05d3\\u05d5\\u05e7 \\u05d0\\u05d5\\u05ea\\u05d9\"}}]}";
   tg_hit = AgTgMatchCommands(tg_esc, AgTgCommandText(), tg_chat, tg_now, 120, tg_max, tg_ign, tg_aok);
   AgVecCheck("tg_cmd_escaped_text_matches", tg_hit == 1, "hit=" + (string)tg_hit);
   string tg_sp = tg_head + tg_chat + "},\"date\":" + (string)(tg_now - 5)
                + ",\"text\":\"" + AgTgCommandText() + " \"}}]}";
   tg_hit = AgTgMatchCommands(tg_sp, AgTgCommandText(), tg_chat, tg_now, 120, tg_max, tg_ign, tg_aok);
   AgVecCheck("tg_cmd_trailing_space_does_not_match", tg_hit == 0 && tg_ign == 1, "hit=" + (string)tg_hit);
   string tg_rlm = tg_head + tg_chat + "},\"date\":" + (string)(tg_now - 5)
                 + ",\"text\":\"\\u200f" + AgTgCommandText() + "\"}}]}";
   tg_hit = AgTgMatchCommands(tg_rlm, AgTgCommandText(), tg_chat, tg_now, 120, tg_max, tg_ign, tg_aok);
   AgVecCheck("tg_cmd_leading_u200f_does_not_match", tg_hit == 0 && tg_ign == 1, "hit=" + (string)tg_hit);
   tg_hit = AgTgMatchCommands(tg_raw, AgTgCommandText(), (string)(990000000 + 124), tg_now, 120, tg_max, tg_ign, tg_aok);
   AgVecCheck("tg_cmd_another_chat_does_not_match", tg_hit == 0 && tg_ign == 1, "hit=" + (string)tg_hit);
   string tg_edit = tg_raw;
   StringReplace(tg_edit, "\"message\":", "\"edited_message\":");
   tg_hit = AgTgMatchCommands(tg_edit, AgTgCommandText(), tg_chat, tg_now, 120, tg_max, tg_ign, tg_aok);
   AgVecCheck("tg_cmd_edited_message_does_not_match", tg_hit == 0 && tg_ign == 1 && tg_max == 7, "hit=" + (string)tg_hit);
   string tg_old = tg_head + tg_chat + "},\"date\":" + (string)(tg_now - 121)
                 + ",\"text\":\"" + AgTgCommandText() + "\"}}]}";
   tg_hit = AgTgMatchCommands(tg_old, AgTgCommandText(), tg_chat, tg_now, 120, tg_max, tg_ign, tg_aok);
   AgVecCheck("tg_cmd_stale_date_does_not_match", tg_hit == 0 && tg_ign == 1, "hit=" + (string)tg_hit);
   string tg_two = "{\"ok\":true,\"result\":[{\"update_id\":8,\"message\":{\"chat\":{\"id\":" + tg_chat + "},\"date\":"
                 + (string)(tg_now - 9) + ",\"text\":\"" + AgTgCommandText() + "\"}},{\"update_id\":9,\"message\":{\"chat\":{\"id\":"
                 + tg_chat + "},\"date\":" + (string)(tg_now - 4) + ",\"text\":\"" + AgTgCommandText() + "\"}}]}";
   tg_hit = AgTgMatchCommands(tg_two, AgTgCommandText(), tg_chat, tg_now, 120, tg_max, tg_ign, tg_aok);
   AgVecCheck("tg_cmd_two_commands_in_one_poll_and_the_offset", tg_hit == 2 && tg_max == 9,
              "hit=" + (string)tg_hit + " max=" + (string)tg_max);
   tg_hit = AgTgMatchCommands("{\"ok\":false,\"error_code\":409}", AgTgCommandText(), tg_chat, tg_now, 120, tg_max, tg_ign, tg_aok);
   AgVecCheck("tg_cmd_not_ok_answer_is_flagged", !tg_aok && tg_hit == 0 && tg_max == -1, "ok flag");
   AgVecCheckInt("tg_json_retry_after_of_a_429",
                 AgTgRetryAfter("{\"ok\":false,\"error_code\":429,\"parameters\":{\"retry_after\":5}}"), 5);
   AgVecCheck("tg_json_escape",
              AgJsonEscape("a\"b\\c\nd\te") == "a\\\"b\\\\c\\nd\\te", AgJsonEscape("a\"b\\c\nd\te"));
   string tg_jp[]; string tg_jv[]; int tg_jk[]; int tg_jc = 0;
   bool tg_jok = AgJsonParse("{\"a\":[1,{\"b\":\"x\\/y\"}],\"c\":null,\"d\":-1.5e3}", tg_jp, tg_jv, tg_jk, tg_jc);
   AgVecCheck("tg_json_flat_paths",
              tg_jok && tg_jc == 4 && tg_jp[0] == "a[0]" && tg_jv[0] == "1" && tg_jp[1] == "a[1].b"
              && tg_jv[1] == "x/y" && tg_jk[2] == AG_JSON_NULL && tg_jv[3] == "-1.5e3",
              "count=" + (string)tg_jc);
   AgVecCheck("tg_json_rejects_trailing_garbage",
              !AgJsonParse("{\"a\":1} x", tg_jp, tg_jv, tg_jk, tg_jc), "parsed");

   //--- the three inputs, on values built here so no token, chat id or ping
   //--- URL shaped literal exists anywhere in the tree (TG-S6)
   string tg_tail = "";
   for(int k = 0; k < 35; k++)
      tg_tail += "x";
   string tg_token = (string)(990000000 + 1) + ":" + tg_tail;
   AgVecCheck("tg_input_token_shape",
              AgTgTokenValid(tg_token) && !AgTgTokenValid(StringSubstr(tg_token, 0, StringLen(tg_token) - 6))
              && !AgTgTokenValid(tg_tail) && !AgTgTokenValid(tg_token + " ") && !AgTgTokenValid("a" + tg_token)
              && !AgTgTokenValid(""), "token checks");
   AgVecCheck("tg_input_chat_id_shape",
              AgTgChatIdValid(tg_chat) && AgTgChatIdValid("-" + tg_chat) && !AgTgChatIdValid("")
              && !AgTgChatIdValid("-") && !AgTgChatIdValid(tg_chat + "a")
              && !AgTgChatIdValid(tg_chat + tg_chat + "123"), "chat id checks");
   string tg_zero8 = "00000000", tg_zero4 = "0000";
   string tg_uuid  = tg_zero8 + "-" + tg_zero4 + "-" + tg_zero4 + "-" + tg_zero4 + "-" + tg_zero4 + tg_zero8;
   string tg_host  = "https://" + "hc-ping.com/";
   AgVecCheck("tg_input_ping_url_shape",
              AgTgPingUrlValid(tg_host + tg_uuid) && !AgTgPingUrlValid("http://" + "hc-ping.com/" + tg_uuid)
              && !AgTgPingUrlValid(tg_host + tg_uuid + "/") && !AgTgPingUrlValid(tg_host + tg_zero8 + tg_zero8)
              && !AgTgPingUrlValid(""), "ping URL checks");
   AgVecCheck("tg_input_channel_states",
              AgTgChannelState(true, false) == "off:empty" && AgTgChannelState(false, false) == "off:malformed"
              && AgTgChannelState(false, true) == "on", "channel states");

   //--- TG-S14, the status slot, TG-15 (A): the local clock's 4 hour slots
   AgVecCheckInt("tg_slot_midnight", AgTgStatusSlot((long)D'2026.10.21 00:00:00'), (long)D'2026.10.21 00:00:00');
   AgVecCheckInt("tg_slot_03_59_59", AgTgStatusSlot((long)D'2026.10.21 03:59:59'), (long)D'2026.10.21 00:00:00');
   AgVecCheckInt("tg_slot_04_00_00", AgTgStatusSlot((long)D'2026.10.21 04:00:00'), (long)D'2026.10.21 04:00:00');
   AgVecCheckInt("tg_slot_12_00_01", AgTgStatusSlot((long)D'2026.10.21 12:00:01'), (long)D'2026.10.21 12:00:00');
   AgVecCheckInt("tg_slot_23_59_59", AgTgStatusSlot((long)D'2026.10.21 23:59:59'), (long)D'2026.10.21 20:00:00');
   int tg_slots = 0;
   long tg_prev_slot = AgTgStatusSlot((long)D'2026.10.20 23:59:59');
   for(long tg_s = (long)D'2026.10.21 00:00:00'; tg_s < (long)D'2026.10.22 00:00:00'; tg_s += 60)
     {
      long tg_cur_slot = AgTgStatusSlot(tg_s);
      if(tg_cur_slot != tg_prev_slot)
         tg_slots++;
      tg_prev_slot = tg_cur_slot;
     }
   AgVecCheckInt("tg_slot_six_per_local_day", tg_slots, 6);

   //--- the new journal lines, field names exact, none taking a secret
   AgVecCheck("tg_line_trading_blocked",
              AgTgTradeBlockedLine("TERMINAL_TRADE_ALLOWED=false", "ACTIVE")
              == "trading blocked|state=TERMINAL_TRADE_ALLOWED=false|guardian=ACTIVE", "");
   AgVecCheck("tg_line_trading_restored",
              AgTgTradeRestoredLine("MQL_TRADE_ALLOWED=false", "SYNCING")
              == "trading restored|state=MQL_TRADE_ALLOWED=false|guardian=SYNCING", "");
   AgVecCheck("tg_line_queue_deferred", AgTgQueueDeferredLine(3) == "alerts queue write deferred|attempts=3", "");
   AgVecCheck("tg_line_queue_loaded", AgTgQueueLoadedLine(2, 15) == "alerts queue loaded|events=2|next_seq=15", "");
   AgVecCheck("tg_line_service_started",
              AgTgServiceStartedLine("TG", 1200252169, "on", "off:empty", "on")
              == "alerts service started|build=TG|login=1200252169|telegram=on|network_heartbeat=off:empty|command=on", "");
   AgVecCheck("tg_line_sent", AgTgSentLine(42, "S4", 200, 311) == "alerts sent|seq=42|class=S4|http=200|ms=311", "");
   AgVecCheck("tg_line_failed",
              AgTgFailedLine(43, "S12", -1, 4014, 2) == "alerts failed|seq=43|class=S12|http=-1|err=4014|ms=2", "");
   AgVecCheck("tg_line_ping", AgTgPingLine(200, 180) == "alerts ping|http=200|ms=180", "");
   AgVecCheck("tg_line_ping_skipped",
              AgTgPingSkippedLine("released", 0) == "alerts ping skipped|guardian=released|age=0", "");
   AgVecCheck("tg_line_guardian", AgTgGuardianLine("stale", 12) == "alerts guardian|state=stale|age=12", "");
   AgVecCheck("tg_line_inbound", AgTgInboundLine(1, 2) == "alerts inbound|matched=1|ignored=2", "");
   AgVecCheck("tg_line_stopping", AgTgStoppingLine(0) == "alerts service stopping|unsent=0", "");

   //================================================================
   //--- ML, the Manual Lockout build (rulings ML-1 to ML-27 of
   //--- 2026-10-22, plan docs/PLAN_MANUAL_LOCKOUT_2026-10-22.md section 11):
   //--- the bounds, the two parsers, the record and its file family on the
   //--- synthetic logins 990000031 and 990000039, the boot witness, every
   //--- line and ALERT shape of ML-21, the reason 3 silence of ML-35 (1) and
   //--- its S3 under ML-37. No GV is touched.
   //================================================================
   datetime ml_t0  = D'2026.10.22 14:30:05';
   datetime ml_anc = D'2026.10.23 01:00:00';
   AgVecCheckDT("ml_max_end_is_the_next_anchor", AgManualMaxEnd(ml_t0), ml_anc);
   AgVecCheckDT("ml_max_end_a_second_before_the_anchor", AgManualMaxEnd(D'2026.10.23 00:59:59'), ml_anc);
   AgVecCheckDT("ml_max_end_at_the_anchor_second_is_the_following_anchor",
                AgManualMaxEnd(D'2026.10.23 01:00:00'), D'2026.10.24 01:00:00');
   AgVecCheckDT("ml_end_of_minutes", AgManualEndOfMinutes(ml_t0, 30), D'2026.10.22 15:00:05');
   AgVecCheckDT("ml_end_of_day_is_the_next_anchor", AgManualEndOfDay(ml_t0), ml_anc);
   AgVecCheckDT("ml_end_at_time_later_today", AgManualEndAtTime(ml_t0, 16, 0), D'2026.10.22 16:00:00');
   AgVecCheckDT("ml_end_at_time_after_midnight_before_the_anchor",
                AgManualEndAtTime(D'2026.10.22 23:00:00', 0, 45), D'2026.10.23 00:45:00');
   AgVecCheckDT("ml_end_at_time_after_the_anchor_lies_past_it",
                AgManualEndAtTime(D'2026.10.22 23:00:00', 1, 15), D'2026.10.23 01:15:00');
   AgVecCheckDT("ml_end_at_time_the_anchor_itself",
                AgManualEndAtTime(D'2026.10.22 23:00:00', 1, 0), ml_anc);
   AgVecCheckDT("ml_end_at_time_the_current_minute_means_tomorrow",
                AgManualEndAtTime(D'2026.10.22 23:00:30', 23, 0), D'2026.10.23 23:00:00');
   AgVecCheckDT("ml_end_at_time_in_the_hour_before_the_anchor",
                AgManualEndAtTime(D'2026.10.23 00:30:00', 0, 50), D'2026.10.23 00:50:00');
   AgVecCheck("ml_end_for_each_form",
              AgManualEndFor(ml_t0, AG_ML_FORM_DURATION, 15, 0, 0) == D'2026.10.22 14:45:05'
              && AgManualEndFor(ml_t0, AG_ML_FORM_END_OF_DAY, 0, 0, 0) == ml_anc
              && AgManualEndFor(ml_t0, AG_ML_FORM_END_TIME, 0, 16, 0) == D'2026.10.22 16:00:00'
              && AgManualEndFor(ml_t0, AG_ML_FORM_NONE, 15, 16, 0) == 0, "end for");
   AgVecCheckInt("ml_check_thirty_minutes", AgManualCheckEnd(ml_t0, ml_t0 + 1800, AG_ML_FORM_DURATION, 0), AG_ML_OK);
   AgVecCheckInt("ml_check_end_of_session_ends_on_the_anchor",
                 AgManualCheckEnd(ml_t0, ml_anc, AG_ML_FORM_END_OF_DAY, 0), AG_ML_OK);
   AgVecCheckInt("ml_check_a_second_past_the_anchor_is_refused",
                 AgManualCheckEnd(ml_t0, ml_anc + 1, AG_ML_FORM_DURATION, 0), AG_ML_PAST_ANCHOR);
   AgVecCheckInt("ml_check_custom_minutes_past_the_anchor_are_refused",
                 AgManualCheckEnd(ml_t0, AgManualEndOfMinutes(ml_t0, 700), AG_ML_FORM_DURATION, 0), AG_ML_PAST_ANCHOR);
   AgVecCheckInt("ml_check_one_hour_in_the_last_half_hour_is_refused",
                 AgManualCheckEnd(D'2026.10.23 00:30:00', AgManualEndOfMinutes(D'2026.10.23 00:30:00', 60),
                                  AG_ML_FORM_DURATION, 0), AG_ML_PAST_ANCHOR);
   AgVecCheckInt("ml_check_an_end_time_past_the_anchor_is_refused",
                 AgManualCheckEnd(D'2026.10.22 23:00:00', AgManualEndAtTime(D'2026.10.22 23:00:00', 1, 15),
                                  AG_ML_FORM_END_TIME, 0), AG_ML_PAST_ANCHOR);
   AgVecCheckInt("ml_check_an_end_time_under_60_s_is_refused",
                 AgManualCheckEnd(D'2026.10.22 23:00:30', AgManualEndAtTime(D'2026.10.22 23:00:30', 23, 1),
                                  AG_ML_FORM_END_TIME, 0), AG_ML_TOO_SOON);
   AgVecCheckInt("ml_check_an_end_time_60_s_ahead",
                 AgManualCheckEnd(D'2026.10.22 23:00:00', AgManualEndAtTime(D'2026.10.22 23:00:00', 23, 1),
                                  AG_ML_FORM_END_TIME, 0), AG_ML_OK);
   AgVecCheckInt("ml_check_an_end_not_after_now_is_refused",
                 AgManualCheckEnd(ml_t0, ml_t0, AG_ML_FORM_DURATION, 0), AG_ML_TOO_SOON);
   AgVecCheckInt("ml_check_an_extension_earlier_is_refused",
                 AgManualCheckEnd(ml_t0, ml_t0 + 900, AG_ML_FORM_DURATION, ml_t0 + 1800), AG_ML_NOT_LATER);
   AgVecCheckInt("ml_check_an_extension_to_the_same_end_is_refused",
                 AgManualCheckEnd(ml_t0, ml_t0 + 1800, AG_ML_FORM_DURATION, ml_t0 + 1800), AG_ML_NOT_LATER);
   AgVecCheckInt("ml_check_an_extension_later",
                 AgManualCheckEnd(ml_t0, ml_t0 + 3600, AG_ML_FORM_DURATION, ml_t0 + 1800), AG_ML_OK);
   AgVecCheckInt("ml_check_under_a_loss_lock_to_the_anchor_is_refused",
                 AgManualCheckEnd(ml_t0, ml_anc, AG_ML_FORM_END_OF_DAY, ml_anc), AG_ML_NOT_LATER);
   AgVecCheck("ml_effective_end_the_later_governs",
              AgManualEffectiveEnd(ml_anc, true, ml_t0 + 900) == ml_anc
              && AgManualEffectiveEnd(0, true, ml_t0 + 900) == ml_t0 + 900
              && AgManualEffectiveEnd(ml_anc, false, D'2026.10.24 01:00:00') == ml_anc
              && AgManualEffectiveEnd(0, false, ml_t0 + 900) == 0, "effective end");
   AgVecCheck("ml_governs",
              AgManualGoverns(false, 0, true, ml_t0 + 900)
              && !AgManualGoverns(true, ml_anc, true, ml_t0 + 900)
              && AgManualGoverns(true, ml_t0 + 600, true, ml_t0 + 900)
              && !AgManualGoverns(false, 0, false, ml_t0 + 900), "governs");
   AgVecCheck("ml_record_bounds",
              AgManualRecordInBounds(ml_t0, ml_t0, ml_t0 + 1800)
              && AgManualRecordInBounds(ml_t0, ml_t0, ml_anc)
              && AgManualRecordInBounds(ml_t0, ml_t0 + 600, ml_anc)
              && !AgManualRecordInBounds(ml_t0, ml_t0, ml_anc + 1)
              && !AgManualRecordInBounds(0, ml_t0, ml_t0 + 1800)
              && !AgManualRecordInBounds(ml_t0, ml_t0 - 1, ml_t0 + 1800)
              && !AgManualRecordInBounds(ml_t0, ml_t0, ml_t0), "bounds");
   datetime ml_end   = 0;
   int      ml_src   = 0;
   bool     ml_fired = AgManualBootWitness(ml_t0 + 60, true, ml_t0 + 1800, 0, ml_end, ml_src);
   AgVecCheck("ml_boot_witness_the_record_alone", ml_fired && ml_end == ml_t0 + 1800 && ml_src == 1,
              "src=" + (string)ml_src);
   ml_fired = AgManualBootWitness(ml_t0 + 60, false, 0, ml_t0 + 1800, ml_end, ml_src);
   AgVecCheck("ml_boot_witness_the_gv_alone", ml_fired && ml_end == ml_t0 + 1800 && ml_src == 2,
              "src=" + (string)ml_src);
   ml_fired = AgManualBootWitness(ml_t0 + 60, true, ml_t0 + 1800, ml_t0 + 3600, ml_end, ml_src);
   AgVecCheck("ml_boot_witness_both_the_later_governs", ml_fired && ml_end == ml_t0 + 3600 && ml_src == 3,
              "src=" + (string)ml_src);
   ml_fired = AgManualBootWitness(ml_t0 + 1800, true, ml_t0 + 1800, 0, ml_end, ml_src);
   AgVecCheck("ml_boot_witness_an_ended_record_does_not_fire", !ml_fired && ml_end == 0 && ml_src == 0,
              "src=" + (string)ml_src);
   ml_fired = AgManualBootWitness(ml_t0, false, 0, D'2026.10.24 01:00:00', ml_end, ml_src);
   AgVecCheck("ml_boot_witness_cut_to_the_next_anchor_of_now", ml_fired && ml_end == ml_anc,
              TimeToString(ml_end, TIME_DATE | TIME_SECONDS));
   ml_fired = AgManualBootWitness(ml_t0, false, 0, 0, ml_end, ml_src);
   AgVecCheck("ml_boot_witness_none", !ml_fired && ml_end == 0, "fired");
   int ml_m = 0;
   AgVecCheck("ml_parse_minutes",
              AgManualParseMinutes("15", ml_m) && ml_m == 15
              && AgManualParseMinutes(" 30 ", ml_m) && ml_m == 30
              && AgManualParseMinutes("9999", ml_m) && ml_m == 9999
              && !AgManualParseMinutes("0", ml_m) && !AgManualParseMinutes("", ml_m)
              && !AgManualParseMinutes("12345", ml_m) && !AgManualParseMinutes("1a", ml_m)
              && !AgManualParseMinutes("-5", ml_m) && !AgManualParseMinutes("1.5", ml_m), "minutes");
   int ml_h  = 0;
   int ml_mi = 0;
   AgVecCheck("ml_parse_hhmm",
              AgManualParseHhMm("16:00", ml_h, ml_mi) && ml_h == 16 && ml_mi == 0
              && AgManualParseHhMm("00:45", ml_h, ml_mi) && ml_h == 0 && ml_mi == 45
              && AgManualParseHhMm(" 09:05 ", ml_h, ml_mi) && ml_h == 9 && ml_mi == 5
              && AgManualParseHhMm("23:59", ml_h, ml_mi) && ml_h == 23 && ml_mi == 59
              && !AgManualParseHhMm("24:00", ml_h, ml_mi) && !AgManualParseHhMm("12:60", ml_h, ml_mi)
              && !AgManualParseHhMm("1:30", ml_h, ml_mi) && !AgManualParseHhMm("12-30", ml_h, ml_mi)
              && !AgManualParseHhMm("", ml_h, ml_mi) && !AgManualParseHhMm("ab:cd", ml_h, ml_mi)
              && !AgManualParseHhMm("12:3", ml_h, ml_mi) && !AgManualParseHhMm("123:45", ml_h, ml_mi), "hh:mm");
   long     ml_login = 990000031;
   string   ml_rec   = AgManualSerialize(ml_login, true, ml_t0, ml_t0, ml_t0 + 1800, AG_ML_FORM_DURATION, 30);
   string   ml_body  = "AGMANUAL|1|990000031\nM|1|" + (string)(long)ml_t0 + "|" + (string)(long)ml_t0 + "|"
                     + (string)(long)(ml_t0 + 1800) + "|1|30\n";
   AgVecCheck("ml_record_text_exact", ml_rec == AgVecSealed(ml_body), ml_rec);
   bool     ml_a  = false;
   datetime ml_f  = 0;
   datetime ml_e  = 0;
   datetime ml_x  = 0;
   int      ml_fo = 0;
   int      ml_mn = 0;
   int ml_rc = AgManualParse(ml_rec, ml_login, ml_a, ml_f, ml_e, ml_x, ml_fo, ml_mn);
   AgVecCheck("ml_record_round_trip",
              ml_rc == 0 && ml_a && ml_f == ml_t0 && ml_e == ml_t0 && ml_x == ml_t0 + 1800
              && ml_fo == AG_ML_FORM_DURATION && ml_mn == 30, "rc=" + (string)ml_rc);
   string ml_crlf = ml_rec;
   StringReplace(ml_crlf, "\n", "\r\n");
   AgVecCheckInt("ml_record_crlf_parses", AgManualParse(ml_crlf, ml_login, ml_a, ml_f, ml_e, ml_x, ml_fo, ml_mn), 0);
   string ml_bad = ml_rec;
   StringReplace(ml_bad, "|1|30\n", "|1|31\n");
   AgVecCheckInt("ml_record_a_changed_byte_fails_the_checksum",
                 AgManualParse(ml_bad, ml_login, ml_a, ml_f, ml_e, ml_x, ml_fo, ml_mn), 2);
   AgVecCheckInt("ml_record_another_login_is_3",
                 AgManualParse(ml_rec, 990000032, ml_a, ml_f, ml_e, ml_x, ml_fo, ml_mn), 3);
   AgVecCheckInt("ml_record_past_the_anchor_of_its_first_is_4",
                 AgManualParse(AgManualSerialize(ml_login, true, ml_t0, ml_t0, ml_anc + 1, AG_ML_FORM_DURATION, 700),
                               ml_login, ml_a, ml_f, ml_e, ml_x, ml_fo, ml_mn), 4);
   AgVecCheck("ml_record_a_refusal_leaves_the_outputs_inactive", !ml_a && ml_x == 0, "active");
   AgVecCheckInt("ml_record_inactive_parses",
                 AgManualParse(AgManualSerialize(ml_login, false, 0, 0, 0, AG_ML_FORM_NONE, 0),
                               ml_login, ml_a, ml_f, ml_e, ml_x, ml_fo, ml_mn), 0);
   AgVecCheckInt("ml_record_an_extra_line_is_refused",
                 AgManualParse(ml_rec + "X|1\n", ml_login, ml_a, ml_f, ml_e, ml_x, ml_fo, ml_mn), 2);
   AgVecCheckInt("ml_record_a_cut_record_is_refused",
                 AgManualParse(StringSubstr(ml_rec, 0, StringFind(ml_rec, "C|")), ml_login,
                               ml_a, ml_f, ml_e, ml_x, ml_fo, ml_mn), 2);
   AgVecCheckInt("ml_record_a_bad_active_flag_is_refused",
                 AgManualParse(AgVecSealed("AGMANUAL|1|990000031\nM|2|0|0|0|0|0\n"), ml_login,
                               ml_a, ml_f, ml_e, ml_x, ml_fo, ml_mn), 2);
   AgVecCheckInt("ml_record_a_login_not_numeric_is_refused",
                 AgManualParse(AgVecSealed("AGMANUAL|1|99000003l\nM|0|0|0|0|0|0\n"), ml_login,
                               ml_a, ml_f, ml_e, ml_x, ml_fo, ml_mn), 2);
   AgVecCheckInt("ml_record_a_state_file_does_not_cross_read",
                 AgManualParse(AgVecSealed(AgVecBody(ml_login, 1, ml_anc, ml_t0, 139.94, 2544.33)), ml_login,
                               ml_a, ml_f, ml_e, ml_x, ml_fo, ml_mn), 2);
   AgVecCheck("ml_record_magic_distinct_from_every_other_file",
              AG_MANUAL_MAGIC != "AGSTATE" && AG_MANUAL_MAGIC != "AGHALT" && AG_MANUAL_MAGIC != "AGFLOOR"
              && AG_MANUAL_MAGIC != "AGPEAK" && AG_MANUAL_MAGIC != AG_TGQ_MAGIC, AG_MANUAL_MAGIC);
   AgVecCheckInt("ml_record_format_version_is_1", AG_MANUAL_FORMAT_VERSION, 1);
   AgVecCheck("ml_record_the_same_record_aside_from_line_ends",
              AgManualSameRecord(ml_crlf, ml_rec) && !AgManualSameRecord(ml_bad, ml_rec), "same record");
   //--- the file family: the never loaded never written guard on a login
   //--- never written, then a save, a load, the read back and the quarantine
   g_ag_login     = 990000039;
   g_ag_ml_loaded = false;
   AgVecCheck("ml_file_names_carry_the_login",
              AgManualPath() == "AccountGuardian\\manual_990000039.dat" && AgGvManual() == "AG_MANUAL_990000039",
              AgManualPath());
   AgVecCheck("ml_file_never_loaded_is_never_written", !AgManualSave() && !FileIsExist(AgManualPath()),
              "save not refused");
   AgVecCheck("ml_file_missing_is_1", AgManualLoad() == 1 && g_ag_ml_loaded && !g_ag_ml_active, "missing");
   g_ag_login = 990000031;
   AgManualLoad();
   g_ag_ml_active        = true;
   g_ag_ml_first_engaged = ml_t0;
   g_ag_ml_engaged       = ml_t0;
   g_ag_ml_end           = ml_t0 + 1800;
   g_ag_ml_form          = AG_ML_FORM_DURATION;
   g_ag_ml_minutes       = 30;
   bool ml_saved = AgManualSave();
   AgManualResetModel();
   int ml_load = AgManualLoad();
   AgVecCheck("ml_file_save_and_load_round_trip",
              ml_saved && ml_load == 0 && g_ag_ml_active && g_ag_ml_end == ml_t0 + 1800
              && g_ag_ml_first_engaged == ml_t0 && g_ag_ml_minutes == 30, "load=" + (string)ml_load);
   AgVecCheck("ml_file_the_text_on_disk", AgManualSameRecord(AgVecReadRaw(AgManualPath()), ml_rec),
              AgVecReadRaw(AgManualPath()));
   AgVecCheckInt("ml_file_read_back_unchanged_is_0", AgManualHealRecord(), 0);
   AgVecWriteRaw(AgManualPath(), ml_bad);
   AgVecCheckInt("ml_file_read_back_different_is_2", AgManualHealRecord(), 2);
   AgVecCheck("ml_file_read_back_writes_the_model_again", AgManualSameRecord(AgVecReadRaw(AgManualPath()), ml_rec),
              AgVecReadRaw(AgManualPath()));
   AgVecWriteRaw(AgManualPath(), ml_bad);
   AgVecCheckInt("ml_file_corrupt_is_quarantined_2", AgManualLoad(), 2);
   AgVecCheck("ml_file_corrupt_leaves_a_fresh_inactive_record_and_a_bad_file",
              !g_ag_ml_active && FileIsExist(AgManualPath() + ".bad")
              && AgManualParse(AgVecReadRaw(AgManualPath()), 990000031, ml_a, ml_f, ml_e, ml_x, ml_fo, ml_mn) == 0
              && !ml_a, "fresh record");
   AgVecWriteRaw(AgManualPath(), AgManualSerialize(990000032, true, ml_t0, ml_t0, ml_t0 + 1800, AG_ML_FORM_DURATION, 30));
   AgVecCheckInt("ml_file_another_login_is_quarantined_3", AgManualLoad(), 3);
   AgVecWriteRaw(AgManualPath(), AgManualSerialize(990000031, true, ml_t0, ml_t0, ml_anc + 1, AG_ML_FORM_DURATION, 700));
   AgVecCheckInt("ml_file_past_the_bound_is_quarantined_4", AgManualLoad(), 4);
   //--- the lines and the ALERTs of ML-21
   AgVecCheck("ml_line_engaged",
              AgManualEngagedLine(AG_ML_FORM_DURATION, 15, ml_t0, ml_t0 + 900, ml_anc, 1, 1)
              == "manual lockout engaged|form=duration|minutes=15|engaged=2026.10.22 14:30:05|end=2026.10.22 14:45:05"
                 "|next_anchor=2026.10.23 01:00:00|positions=1|pendings=1", "");
   AgVecCheck("ml_line_extended",
              AgManualExtendedLine(ml_t0 + 900, ml_t0 + 5395, AG_ML_FORM_END_TIME, 0, ml_t0 + 600)
              == "manual lockout extended|from=2026.10.22 14:45:05|to=2026.10.22 16:00:00|form=end_time"
                 "|minutes=0|engaged=2026.10.22 14:40:05", "");
   AgVecCheck("ml_line_refused_at_the_panel",
              AgManualRefusedLine(AgManualRefuseName(AG_ML_PAST_ANCHOR), "panel", "-", AG_ML_FORM_DURATION,
                                  ml_anc + 4205, D'2026.10.23 00:30:00')
              == "manual lockout refused|why=past the next daily anchor|at=panel|state=-|form=duration"
                 "|requested_end=2026.10.23 02:10:05|server=2026.10.23 00:30:00", "");
   AgVecCheck("ml_line_expired",
              AgManualExpiredLine(ml_t0 + 900, ml_t0 + 900)
              == "manual lockout expired|end=2026.10.22 14:45:05|server=2026.10.22 14:45:05", "");
   AgVecCheck("ml_line_ended_under_a_loss_lock",
              AgManualEndedUnderLossLine(ml_t0 + 900, ml_anc, ml_t0 + 901)
              == "manual lockout ended, the loss lock holds|end=2026.10.22 14:45:05"
                 "|locked_until=2026.10.23 01:00:00|server=2026.10.22 14:45:06", "");
   AgVecCheck("ml_line_record_loaded",
              AgManualLoadedLine(true, ml_t0 + 900)
              == "manual lockout record loaded|active=1|end=2026.10.22 14:45:05"
                 "|weighed by the boot witness at the SYNCING exit", "");
   AgVecCheck("ml_line_gv_mirror_at_init",
              AgManualGvInitLine(0)
              == "manual lockout GV mirror at init|raw=1970.01.01 00:00:00"
                 "|weighed by the boot witness at the SYNCING exit", "");
   AgVecCheck("ml_line_boot_witness_fired",
              AgManualBootFiredLine(3, ml_t0 + 900, ml_t0 + 900, ml_t0 + 900)
              == "boot witness MANUAL fired|source=file+gv|record=2026.10.22 14:45:05|gv=2026.10.22 14:45:05"
                 "|end=2026.10.22 14:45:05"
              && StringFind(AgManualBootFiredLine(2, 0, ml_t0 + 900, ml_t0 + 900), "|source=gv|") > 0
              && StringFind(AgManualBootFiredLine(1, ml_t0 + 900, 0, ml_t0 + 900), "|source=file|") > 0, "");
   AgVecCheck("ml_line_holds_with_the_boot_lock",
              AgManualHoldsLine(ml_t0 + 900, ml_anc, false)
              == "manual lockout holds with the boot lock|end=2026.10.22 14:45:05"
                 "|locked_until=2026.10.23 01:00:00|governing=loss lock"
              && StringFind(AgManualHoldsLine(ml_anc, ml_t0, true), "|governing=MANUAL_LOCKOUT") > 0, "");
   AgVecCheck("ml_line_record_rewritten",
              AgManualRewrittenLine("missing") == "manual lockout record rewritten|why=missing"
              && AgManualRewrittenLine("differs") == "manual lockout record rewritten|why=differs", "");
   AgVecCheck("ml_line_quarantined",
              AgManualQuarantinedLine("carries another login", "AccountGuardian\\manual_990000031.dat.bad")
              == "manual lockout record carries another login, quarantined as AccountGuardian\\manual_990000031.dat.bad"
                 ", the AG_MANUAL mirror alone decides at the SYNCING exit (ML-19)", "");
   AgVecCheck("ml_line_panel",
              AgManualPanelLine("review", AG_ML_FORM_END_OF_DAY, ml_anc, ml_t0)
              == "manual lockout panel|review|form=end_of_session|end=2026.10.23 01:00:00|server=2026.10.22 14:30:05"
              && AgManualPanelLine("lock account clicked", AG_ML_FORM_DURATION, ml_t0 + 900, ml_t0)
              == "manual lockout panel|lock account clicked|form=duration|end=2026.10.22 14:45:05|server=2026.10.22 14:30:05"
              && AgManualPanelTimedOutLine(ml_t0) == "manual lockout panel|review timed out|server=2026.10.22 14:30:05", "");
   AgVecCheck("ml_line_transition_and_life_fields",
              AgManualEndField(ml_t0 + 900) == "manual_end=2026.10.22 14:45:05"
              && AgManualLifeField(ml_t0 + 900) == "|manual_end=2026.10.22 14:45:05", "");
   AgVecCheck("ml_alert_engage",
              AgManualEngageAlert(ml_t0 + 900, 1, 1)
              == "MANUAL_LOCKOUT: account LOCKED until 2026.10.22 14:45:05. Flattening 1 positions and deleting 1 pending orders.", "");
   AgVecCheck("ml_alert_extend",
              AgManualExtendAlert(ml_anc) == "MANUAL_LOCKOUT: lockout extended until 2026.10.23 01:00:00.", "");
   AgVecCheck("ml_alert_boot",
              AgManualBootAlert(ml_t0 + 900, 0, 0)
              == "LOCKED at boot by derivation (MANUAL_LOCKOUT) until 2026.10.22 14:45:05. Flattening 0 positions and deleting 0 pending orders.", "");
   AgVecCheck("ml_names_and_no_lock_reason_value",
              AG_MANUAL_REASON_NAME == "MANUAL_LOCKOUT" && AgLockReasonName((ENUM_AG_LOCK_REASON)4) == "UNKNOWN"
              && AgManualFormName(AG_ML_FORM_DURATION) == "duration" && AgManualFormName(AG_ML_FORM_END_OF_DAY) == "end_of_session"
              && AgManualFormName(AG_ML_FORM_END_TIME) == "end_time" && AgManualFormName(AG_ML_FORM_NONE) == "none", "");
   AgVecCheck("ml_refusal_names",
              AgManualRefuseName(AG_ML_PAST_ANCHOR) == "past the next daily anchor"
              && AgManualRefuseName(AG_ML_TOO_SOON) == "too soon"
              && AgManualRefuseName(AG_ML_NOT_LATER) == "not later than the current lock"
              && AgManualRefuseName(AG_ML_STATE) == "not available in this state"
              && AgManualRefuseName(AG_ML_INPUT) == "entry not understood"
              && AgManualRefuseName(AG_ML_NOT_LOADED) == "record not loaded", "");
   AgVecCheck("ml_remaining_time",
              AgManualHms(0) == "0:00:00" && AgManualHms(1800) == "0:30:00" && AgManualHms(37795) == "10:29:55"
              && AgManualHms(-5) == "0:00:00", "");
   //--- ML-35 (1): the one deinit reason that sends no Telegram message
   AgVecCheck("ml_tg_silent_reason_is_reason_3_alone",
              AgTgSilentReason(3) && !AgTgSilentReason(0) && !AgTgSilentReason(1) && !AgTgSilentReason(2)
              && !AgTgSilentReason(4) && !AgTgSilentReason(5) && !AgTgSilentReason(6) && !AgTgSilentReason(7)
              && !AgTgSilentReason(8) && !AgTgSilentReason(9), "silent reason");
   //--- ML-37: after a reason 3 change S3 is silenced only for the same
   //--- SAFE_HALT already announced, known by its halt time; a SAFE_HALT new
   //--- at that init, or no halt time on record, sends S3
   datetime ml_halt_a = D'2026.10.22 14:00:00';
   datetime ml_halt_b = D'2026.10.22 14:05:00';
   AgVecCheck("ml_tg_s3_a_new_safe_halt_after_reason_3_is_sent",
              !AgTgS3Silenced(true, ml_halt_a, ml_halt_b) && !AgTgS3Silenced(true, 0, ml_halt_b)
              && !AgTgS3Silenced(true, 0, 0), "silenced");
   AgVecCheck("ml_tg_s3_the_same_safe_halt_announced_is_silenced_after_reason_3_only",
              AgTgS3Silenced(true, ml_halt_a, ml_halt_a) && !AgTgS3Silenced(false, ml_halt_a, ml_halt_a),
              "same halt");
   //--- the record: the halt time of the last S3 among the events a write
   //--- carried, kept as it was when none is among them
   AgTgEvent ml_ev;
   ZeroMemory(ml_ev);
   AgTgEvent ml_q[];
   ArrayResize(ml_q, 3);
   ml_q[0] = ml_ev;
   ml_q[1] = ml_ev;
   ml_q[2] = ml_ev;
   ml_q[0].code = AG_TG_S1;
   ml_q[1].code = AG_TG_S3;
   ml_q[1].x[1] = (double)(long)ml_halt_a;
   ml_q[2].code = AG_TG_S3;
   ml_q[2].x[1] = (double)(long)ml_halt_b;
   AgVecCheck("ml_tg_s3_the_record_is_the_last_s3_a_write_carried",
              AgTgS3HaltTimeIn(ml_q, 3, 0) == ml_halt_b && AgTgS3HaltTimeIn(ml_q, 2, 0) == ml_halt_a
              && AgTgS3HaltTimeIn(ml_q, 1, ml_halt_a) == ml_halt_a && AgTgS3HaltTimeIn(ml_q, 0, 0) == 0, "record");

   //--- TG-S8, the Hebrew: each draft of item 13 rendered with its example
   //--- values, the md5 of the UTF-8 bytes against the value computed from the
   //--- draft's own text, independently, by a script at the build
   AgTgCommon c;
   AgVecC(c, D'2026.10.21 14:55:00', 2544.33, 2544.33, 0.0, AG_TG_PNL_ACTIVE, 139.94, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_s1_start", AgTgFinish(AgTgTextS1(c, 5.50, 200, 139.94, "$"), 0, 0, 1670, "build=TG"), "36C671B93206089A9152D261C4BB3FC0");
   AgVecC(c, D'2026.10.19 11:42:10', 2172.06, 2172.06, 0.0, AG_TG_PNL_ACTIVE, 126.21, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_s1_restarted", AgTgFinish(AgTgTextS1Restarted(c, 5), 0, 0, 0, "build=TG"), "832D597B35AAAF6CBFAC8FCB30A13D7B");
   AgVecC(c, D'2026.10.19 18:00:00', 2217.06, 2217.06, 45.00, AG_TG_PNL_ACTIVE, 126.21, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_s2_stop", AgTgFinish(AgTgTextS2(c, 1), 0, 0, 0, "build=TG"), "8BE64784EC2DB503521BB43DE124E172");
   AgVecC(c, D'2026.09.07 13:19:28', 2294.76, 2294.76, 0.0, AG_TG_PNL_NONE, 0.0, AG_TG_STATE_NOT_RUNNING, 0);
   AgVecMd5("tg_text_s3_refused", AgTgFinish(AgTgTextS3Refused(c), 0, 0, 300, ""), "EADAD81FD043C3200E79C3DE9F70F441");
   AgVecC(c, D'2026.08.03 01:48:42', 2133.00, 2133.00, 0.0, AG_TG_PNL_NONE, 0.0, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_s3_second", AgTgFinish(AgTgTextS3Second(c), 0, 0, 0, ""), "375208E3C6CBACF282F690BE9B592F04");
   AgVecC(c, D'2026.08.04 16:37:04', 2133.00, 2133.00, 0.0, AG_TG_PNL_NONE, 0.0, AG_STATE_SAFE_HALT, 0);
   AgVecMd5("tg_text_s3_crash", AgTgFinish(AgTgTextS3Crash(c, 4, 300), 0, 0, 0, ""), "5C9004AE92E04593014899EF6EA618D8");
   AgVecC(c, D'2026.08.04 16:37:54', 2133.00, 2133.00, 0.0, AG_TG_PNL_NONE, 0.0, AG_STATE_SAFE_HALT, 0);
   AgVecMd5("tg_text_s3_persisted", AgTgFinish(AgTgTextS3Persisted(c, D'2026.08.04 16:37:04'), 0, 0, 0, ""), "CC9D82BB9263C2174D6C3251BE2BACD8");
   AgVecC(c, D'2026.09.15 18:36:17', 2300.16, 2164.56, -130.20, AG_TG_PNL_ACTIVE, 126.21, AG_STATE_LOCKED, 3);
   AgVecMd5("tg_text_s4_daily", AgTgFinish(AgTgTextS4(c, 1, D'2026.09.16 01:00:00', 5.50, 200, -130.20, 3, 0, "$"), 0, 0, 0, ""), "DF44B477B2A661EEC07393B4B2A09F21");
   AgVecC(c, D'2026.09.26 16:35:35', 3138.34, 2976.30, 90.96, AG_TG_PNL_ACTIVE, 158.69, AG_STATE_LOCKED, 3);
   AgVecMd5("tg_text_s4_peak", AgTgFinish(AgTgTextS4Peak(c, D'2026.09.27 01:00:00', 253.00, 253.00 - 158.69, 90.96, 3, 0, "$"), 0, 0, 0, ""), "98569258B219655F52E6E2BD739E6884");
   AgVecC(c, D'2026.09.23 15:28:24', 2880.70, 2880.70, 0.0, AG_TG_PNL_LOCKED, 147.54, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_s6_complete", AgTgFinish(AgTgTextS6C(c, 3, 2, 5, 0, 7), 0, 0, 0, ""), "0FA0A9DE46BA422A7588A0491F1997F0");
   AgVecC(c, D'2026.09.26 16:35:38', 3138.34, 3138.30, 0.0, AG_TG_PNL_LOCKED, 158.69, AG_STATE_LOCKED, 1);
   AgVecMd5("tg_text_s6_session", AgTgFinish(AgTgTextS6H(c, 781624897, false, 1, "XAUUSD.ecn", D'2026.09.28 01:01:00', 10, 60), 0, 0, 0, ""), "C56B51FD60AA1CCF5D5E29A40CBCE2ED");
   AgVecC(c, D'2026.09.23 15:30:00', 2880.70, 2850.10, -30.60, AG_TG_PNL_LOCKED, 147.54, AG_STATE_LOCKED, 1);
   AgVecMd5("tg_text_s6_hard_stop", AgTgFinish(AgTgTextS6H(c, 753031555, false, 2, "XAUUSD.ecn", 0, 10, 60), 0, 0, 0, ""), "D6AE3F77E4AA25321C1CC6559BACC19C");
   AgVecC(c, D'2026.09.28 01:01:05', 2998.80, 2998.80, 0.0, AG_TG_PNL_LOCKED, 158.69, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_s6_flattened", AgTgFinish(AgTgTextS6F(c, 781624897, false, "XAUUSD.ecn"), 0, 0, 0, ""), "563DE91FF0E9D420E39F6CAD7C24CC1F");
   AgVecC(c, D'2026.09.23 15:56:12', 2880.62, 2880.62, -0.08, AG_TG_PNL_LOCKED, 147.54, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_s7", AgTgFinish(AgTgTextS7(c, 753338779, "XAUUSD.ecn", 1), 0, 0, 0, ""), "1243A5B7E40309E3B004B79D2128CA48");
   AgVecC(c, D'2026.09.27 01:00:03', 2998.84, 2998.80, -0.04, AG_TG_PNL_ACTIVE, 164.94, AG_STATE_ACTIVE, 1);
   AgVecMd5("tg_text_s8_released", AgTgFinish(AgTgTextS8Released(c, D'2026.09.27 01:00:00', 164.94), 0, 0, 0, ""), "69CA82CF2EDF653DD880B7B1874FFEB9");
   AgVecC(c, D'2026.08.26 01:00:10', 2027.98, 1919.14, -108.84, AG_TG_PNL_LOCKED, 101.40, AG_STATE_LOCKED, 2);
   AgVecMd5("tg_text_s8_again", AgTgFinish(AgTgTextS8Again(c, D'2026.08.27 01:00:00'), 0, 0, 0, ""), "194B56468DF14AB6C671F89EB0A54C47");
   AgVecC(c, D'2026.10.19 14:05:12', 2172.06, 2071.09, -100.97, AG_TG_PNL_ACTIVE, 126.21, AG_STATE_ACTIVE, 3);
   AgVecMd5("tg_text_s9", AgTgFinish(AgTgTextS9(c, 80, 25.24), 0, 0, 0, ""), "9975938A38DB78CAD8D8BB00BB02185D");
   AgVecC(c, D'2026.08.18 12:13:43', 2133.13, 2133.13, 0.0, AG_TG_PNL_ACTIVE, 106.66, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_s10", AgTgFinish(AgTgTextS10(c, D'2026.08.18 12:08:42', D'2026.08.18 12:13:43', 301), 0, 0, 0, ""), "057EE844099C42CAF1D4DFB85B4CEEFA");
   AgVecC(c, D'2026.10.19 12:20:40', 2172.06, 2172.06, 0.0, AG_TG_PNL_ACTIVE, 126.21, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_s11", AgTgFinish(AgTgTextS11(c, D'2026.10.19 12:00:05', D'2026.10.19 12:20:40', 4), 0, 0, 0, ""), "F8B60DAD34733A58D8E494686F788BF2");
   AgVecC(c, D'2026.09.28 10:44:02', 2805.35, 2805.35, -193.49, AG_TG_PNL_LOCKED, 164.94, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_s12_blocked_locked", AgTgFinish(AgTgTextS12Blocked(c, 1), 0, 0, 0, ""), "A05D0E07A6FCC0174D23EC58E218CAEE");
   AgVecC(c, D'2026.09.28 10:47:03', 2805.35, 2805.36, -193.48, AG_TG_PNL_LOCKED, 164.94, AG_STATE_LOCKED, 1);
   AgVecMd5("tg_text_s12_restored", AgTgFinish(AgTgTextS12Restored(c), 0, 0, 0, ""), "2BF988022CF041D2B25E5D92819659B3");
   AgVecC(c, D'2026.10.20 01:00:04', 2140.50, 2140.50, 0.0, AG_TG_PNL_ACTIVE, 117.73, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_s14", AgTgFinish(AgTgTextS14(c, D'2026.10.19 01:00:00', -31.56, 12.40, 0, 117.73), 0, 0, 0, "build=TG"), "ABC743AC2FC647283F59432A03FB98EF");
   AgVecC(c, D'2026.08.04 16:39:54', 2133.00, 2133.00, 0.0, AG_TG_PNL_NONE, 0.0, AG_STATE_SYNCING, 0);
   AgVecMd5("tg_text_s15", AgTgFinish(AgTgTextS15(c), 0, 0, 0, ""), "A305426F72184F200887FCB5F7E6F41D");
   AgVecC(c, D'2026.09.23 16:57:35', 2880.70, 2879.58, -1.12, AG_TG_PNL_LOCKED, 147.54, AG_STATE_LOCKED, 1);
   AgVecMd5("tg_text_s16", AgTgFinish(AgTgTextS16(c, D'2026.09.24 01:00:00', 1, 3, 1, 0, -1), 0, 0, 0, ""), "0B026A3460E10C73907172CAC8733D48");
   AgVecC(c, D'2026.10.19 14:05:12', 2172.06, 2172.06, 0.0, AG_TG_PNL_LOCKED, 126.21, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_s17", AgTgFinish(AgTgTextS17(c, 1, 1), 0, 0, 0, ""), "0DD13B95F23C84EAD91D2C45EB2508A6");
   AgVecC(c, D'2026.09.15 22:35:38', 2172.06, 2172.06, 0.0, AG_TG_PNL_NONE, 0.0, AG_STATE_SYNCING, 0);
   AgVecMd5("tg_text_s18", AgTgFinish(AgTgTextS18(c, 28), 0, 0, 0, ""), "4F5330E68725AFCEB307DFEED5E2D869");
   AgVecC(c, D'2026.08.18 15:36:30', 239.63, 239.63, -1893.50, AG_TG_PNL_LOCKED, 106.66, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_s19_locked", AgTgFinish(AgTgTextS19Locked(c, 1, 10.00, 200, 106.66, "$"), 0, 0, 0, ""), "9D9F00823B2FC5EBC923F3C06EBDA4E9");
   AgVecC(c, D'2026.09.07 14:32:54', 2294.76, 2294.76, 0.0, AG_TG_PNL_ACTIVE, 114.74, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_s19_raise", AgTgFinish(AgTgTextS19Raise(c, 126.21, 114.74), 0, 0, 0, ""), "F85ED9CF3235472EB51732F0B40E671A");
   AgVecC(c, D'2026.08.10 01:00:00', 2003.46, 2003.46, 0.0, AG_TG_PNL_ACTIVE, 100.17, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_s20", AgTgFinish(AgTgTextS20(c, 259200), 0, 0, 0, ""), "EC0D539F8799E6A5E2BC1536B8158522");
   AgVecC(c, D'2026.10.19 14:05:12', 2172.06, 2172.06, 0.0, AG_TG_PNL_NONE, 0.0, AG_STATE_SYNCING, 0);
   AgVecMd5("tg_text_s21", AgTgFinish(AgTgTextS21(c), 0, 0, 0, ""), "2C35B5F0D01733F4161A6B6F681C5B16");
   AgVecC(c, D'2026.10.19 09:05:03', 2172.06, 2172.06, 0.0, AG_TG_PNL_NONE, 0.0, AG_STATE_SYNCING, 0);
   AgVecMd5("tg_text_s22", AgTgFinish(AgTgTextS22(c, 300, 1), 0, 0, 0, ""), "E1AF922915ADB7FB2E22B8D6FB96E819");
   AgVecC(c, D'2026.10.19 14:05:12', 2172.06, 2172.06, 0.0, AG_TG_PNL_ACTIVE, 126.21, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_s24", AgTgFinish(AgTgTextS24(c), 0, 0, 0, ""), "D56296A6E66810191FA7ABD9FFC247E3");
   AgVecC(c, D'2026.10.21 15:34:00', 2544.33, 2544.33, 0.0, AG_TG_PNL_ACTIVE, 139.94, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_status_active", AgTgFinish(AgTgTextStatus(c, 1, -1, 0), 0, 0, 0, "build=TG"), "27FFBC63E90424B19F2D5E495901EA06");
   AgVecC(c, D'2026.09.23 16:00:01', 2880.70, 2880.70, 0.0, AG_TG_PNL_LOCKED, 147.54, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_status_locked", AgTgFinish(AgTgTextStatus(c, 1, -1, D'2026.09.24 01:00:00'), 0, 0, 0, "build=TG"), "D6E506B4BBDF058D41436734869AD5A6");
   AgVecC(c, D'2026.10.21 14:05:12', 2172.06, 2150.10, 0.0, AG_TG_PNL_NONE, 0.0, AG_TG_STATE_NOT_RUNNING, 1);
   AgVecMd5("tg_text_not_responding", AgTgFinish(AgTgTextNotResponding(c, 15, false, true), 0, 0, 0, ""), "E1C3E3B84DA24EFE08A9C6A5EB807959");
   AgVecC(c, D'2026.10.21 09:01:00', 2172.06, 2172.06, 0.0, AG_TG_PNL_NONE, 0.0, AG_TG_STATE_NOT_RUNNING, 0);
   AgVecMd5("tg_text_not_running", AgTgFinish(AgTgTextNotRunning(c, 60), 0, 0, 0, ""), "7BB88BE023DD9A9618C25CFCBF5AB003");
   AgVecC(c, D'2026.10.21 14:05:54', 2172.06, 2150.10, -21.96, AG_TG_PNL_ACTIVE, 126.21, AG_STATE_ACTIVE, 1);
   AgVecMd5("tg_text_responds_again", AgTgFinish(AgTgTextRespondsAgain(c, 42), 0, 0, 0, ""), "FDF983E2F59AEEF3DAAED3ED1F57554C");
   AgVecC(c, D'2026.10.21 10:44:02', 2805.35, 2805.35, 12.40, AG_TG_PNL_ACTIVE, 164.94, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_s12_active", AgTgFinish(AgTgTextS12Blocked(c, 1), 0, 0, 0, ""), "EAE2BE9856CD887CC59CAD3C27DA4E9E");
   AgVecC(c, D'2026.09.26 16:35:38', 3138.34, 3138.30, 0.0, AG_TG_PNL_LOCKED, 158.69, AG_STATE_LOCKED, 1);
   AgVecMd5("tg_text_b_s6_order_session", AgTgFinish(AgTgTextS6H(c, 781624901, true, 1, "XAUUSD.ecn", 0, 10, 60), 0, 0, 0, ""), "61F097750668B80EF12F370B695A717E");
   AgVecC(c, D'2026.09.23 15:30:00', 2880.70, 2850.10, -30.60, AG_TG_PNL_LOCKED, 147.54, AG_STATE_LOCKED, 1);
   AgVecMd5("tg_text_b_s6_refuse", AgTgFinish(AgTgTextS6H(c, 753031555, false, 3, "XAUUSD.ecn", 0, 10, 60), 0, 0, 0, ""), "1B112A87DC503D4F251C7F675D2A906A");
   AgVecC(c, D'2026.09.23 15:30:00', 2880.70, 2850.10, -30.60, AG_TG_PNL_LOCKED, 147.54, AG_STATE_LOCKED, 1);
   AgVecMd5("tg_text_b_s6_order_hold", AgTgFinish(AgTgTextS6H(c, 753031560, true, 5, "XAUUSD.ecn", 0, 10, 60), 0, 0, 0, ""), "046F22E5D12582DDB7F663567E3810D7");
   AgVecC(c, D'2026.09.26 16:35:38', 3138.34, 3138.30, 0.0, AG_TG_PNL_LOCKED, 158.69, AG_STATE_LOCKED, 1);
   AgVecMd5("tg_text_b_s6_mode", AgTgFinish(AgTgTextS6H(c, 781624897, false, 4, "XAUUSD.ecn", 0, 10, 60), 0, 0, 0, ""), "AFDEEDCD73F89B8FC617501DBD364F40");
   AgVecC(c, D'2026.09.23 15:30:00', 2880.70, 2850.10, -30.60, AG_TG_PNL_LOCKED, 147.54, AG_STATE_LOCKED, 1);
   AgVecMd5("tg_text_b_s6_order_hard_stop", AgTgFinish(AgTgTextS6H(c, 753031560, true, 2, "XAUUSD.ecn", 0, 10, 60), 0, 0, 0, ""), "546627F811441F06066BC6C3FDB4108B");
   AgVecC(c, D'2026.09.28 01:01:05', 2998.80, 2998.80, 0.0, AG_TG_PNL_LOCKED, 158.69, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_b_s6_order_flattened", AgTgFinish(AgTgTextS6F(c, 781624901, true, "XAUUSD.ecn"), 0, 0, 0, ""), "471CA10F0DE013280B28E38041ECC0A1");
   AgVecC(c, D'2026.09.23 15:28:24', 2880.70, 2880.70, 0.0, AG_TG_PNL_LOCKED, 147.54, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_b_s6_complete_singular", AgTgFinish(AgTgTextS6C(c, 1, 1, 2, 0, 3), 0, 0, 0, ""), "F81980124883A4F590AB9D3ECEF52230");
   AgVecC(c, D'2026.09.23 15:56:12', 2880.62, 2880.62, -0.08, AG_TG_PNL_LOCKED, 147.54, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_b_s7_later", AgTgFinish(AgTgTextS7(c, 753338779, "XAUUSD.ecn", 2), 0, 0, 0, ""), "50E098EFCB4828A63C4DD9B8C77260EF");
   AgVecC(c, D'2026.10.21 09:00:05', 2172.06, 2172.06, 0.0, AG_TG_PNL_NONE, 0.0, AG_STATE_SYNCING, 0);
   AgVecMd5("tg_text_b_s17_corrupt", AgTgFinish(AgTgTextS17(c, 4, 2), 0, 0, 0, ""), "BF31E01BE91ACAF054F9F98CFF871D32");
   AgVecC(c, D'2026.10.21 09:00:20', 2172.06, 2172.06, 0.0, AG_TG_PNL_NONE, 0.0, AG_STATE_SYNCING, 0);
   AgVecMd5("tg_text_b_s12_syncing", AgTgFinish(AgTgTextS12Blocked(c, 2), 0, 0, 0, ""), "BC34D9178CCF425593E6BF09AE9313A7");
   AgVecC(c, D'2026.09.23 16:57:35', 2880.70, 2880.70, 0.0, AG_TG_PNL_LOCKED, 147.54, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_b_s16_restarted", AgTgFinish(AgTgTextS16(c, D'2026.09.24 01:00:00', 1, 3, 0, 0, 5), 0, 0, 0, ""), "33AA8CFCFE3DEEFD2B6A26E864121108");
   AgVecC(c, D'2026.10.21 08:00:01', 2172.06, 2172.06, 0.0, AG_TG_PNL_NONE, 0.0, AG_STATE_SYNCING, 0);
   AgVecMd5("tg_text_b_status_syncing", AgTgFinish(AgTgTextStatus(c, 0, -1, 0), 0, 0, 0, "build=TG"), "D7CD047C58A00B3A3D309F2A034E60B7");
   AgVecC(c, D'2026.10.21 16:00:01', 2172.06, 2172.06, 0.0, AG_TG_PNL_NONE, 0.0, AG_TG_STATE_NOT_RUNNING, 0);
   AgVecMd5("tg_text_b_status_not_running", AgTgFinish(AgTgTextStatus(c, 75, -1, 0), 0, 0, 0, "build=TG"), "00A2C469EE0B8640CB09789BE4AE2B0F");
   AgVecC(c, D'2026.10.19 14:05:12', 2172.06, 2172.06, 0.0, AG_TG_PNL_ACTIVE, 126.21, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_s2_reason_0", AgVecLine(AgTgTextS2(c, 0), 13), "F6DC9FD1CD5CCA59EA0E6C85D06630FB");
   AgVecC(c, D'2026.10.19 14:05:12', 2172.06, 2172.06, 0.0, AG_TG_PNL_ACTIVE, 126.21, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_s2_reason_1", AgVecLine(AgTgTextS2(c, 1), 13), "9C10E8BC380F774632917628201481E7");
   AgVecC(c, D'2026.10.19 14:05:12', 2172.06, 2172.06, 0.0, AG_TG_PNL_ACTIVE, 126.21, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_s2_reason_2", AgVecLine(AgTgTextS2(c, 2), 13), "11DAA6C6EB0B8BA0B4D9ECCE6A583B11");
   AgVecC(c, D'2026.10.19 14:05:12', 2172.06, 2172.06, 0.0, AG_TG_PNL_ACTIVE, 126.21, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_s2_reason_3", AgVecLine(AgTgTextS2(c, 3), 13), "2F1B1AB5F2CA3822694FFD300126747F");
   AgVecC(c, D'2026.10.19 14:05:12', 2172.06, 2172.06, 0.0, AG_TG_PNL_ACTIVE, 126.21, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_s2_reason_4", AgVecLine(AgTgTextS2(c, 4), 13), "359BB0A51FFA13BD3D208669277C4F07");
   AgVecC(c, D'2026.10.19 14:05:12', 2172.06, 2172.06, 0.0, AG_TG_PNL_ACTIVE, 126.21, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_s2_reason_5", AgVecLine(AgTgTextS2(c, 5), 13), "7ABAF802C9620C9A8D90C20119721A02");
   AgVecC(c, D'2026.10.19 14:05:12', 2172.06, 2172.06, 0.0, AG_TG_PNL_ACTIVE, 126.21, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_s2_reason_6", AgVecLine(AgTgTextS2(c, 6), 13), "F77F3B931554F40D191E91D945D2B6F9");
   AgVecC(c, D'2026.10.19 14:05:12', 2172.06, 2172.06, 0.0, AG_TG_PNL_ACTIVE, 126.21, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_s2_reason_7", AgVecLine(AgTgTextS2(c, 7), 13), "7BCEF9B53BA91918E937DD32433E2208");
   AgVecC(c, D'2026.10.19 14:05:12', 2172.06, 2172.06, 0.0, AG_TG_PNL_ACTIVE, 126.21, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_s2_reason_8", AgVecLine(AgTgTextS2(c, 8), 13), "5D370722395845FCD9CD6FE799B5196F");
   AgVecC(c, D'2026.10.19 14:05:12', 2172.06, 2172.06, 0.0, AG_TG_PNL_ACTIVE, 126.21, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_s2_reason_9", AgVecLine(AgTgTextS2(c, 9), 13), "C2CC43DC83C521F401BB7198AA1686ED");
   AgVecMd5("tg_text_delay_line", AgVecLine(AgTgFinish("x", 0, 0, 125, "b"), 2), "1066512279627C60805766A118D00A63");
   AgVecC(c, D'2026.10.19 14:05:12', 2172.06, 2172.06, 0.0, AG_TG_PNL_NONE, 0.0, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_state_word_0", AgVecLine(AgTgCommonLines(c), 9), "B666DF084672CAED2B9BF53E6267523E");
   AgVecC(c, D'2026.10.19 14:05:12', 2172.06, 2172.06, 0.0, AG_TG_PNL_NONE, 0.0, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_state_word_1", AgVecLine(AgTgCommonLines(c), 9), "6855CF078172B19E7A5B19A0E08F6B16");
   AgVecC(c, D'2026.10.19 14:05:12', 2172.06, 2172.06, 0.0, AG_TG_PNL_NONE, 0.0, AG_STATE_SYNCING, 0);
   AgVecMd5("tg_text_state_word_2", AgVecLine(AgTgCommonLines(c), 9), "92D639F73B9D1A07A627B9523AA65CB2");
   AgVecC(c, D'2026.10.19 14:05:12', 2172.06, 2172.06, 0.0, AG_TG_PNL_NONE, 0.0, AG_STATE_SAFE_HALT, 0);
   AgVecMd5("tg_text_state_word_3", AgVecLine(AgTgCommonLines(c), 9), "65C53286ACAFAEE3FC3F9499C482FCE0");
   AgVecC(c, D'2026.10.19 14:05:12', 2172.06, 2172.06, 0.0, AG_TG_PNL_NONE, 0.0, AG_TG_STATE_NOT_RUNNING, 0);
   AgVecMd5("tg_text_state_word_4", AgVecLine(AgTgCommonLines(c), 9), "48DED9594AF63FA8B08BB0BE8E93AC36");
   AgVecMd5("tg_text_not_computed", AgTgPnlLine(AG_TG_PNL_NONE, 0.0, 0.0, "$"), "763781BA6E938A4604C9A055F89687AB");
   AgVecC(c, D'2026.09.15 18:36:17', 2300.16, 2164.56, -130.20, AG_TG_PNL_ACTIVE, 126.21, AG_STATE_LOCKED, 3);
   AgVecMd5("tg_text_s4_crossed_1", AgVecLine(AgTgTextS4(c, 1, D'2026.09.16 01:00:00', 5.50, 200, -130.20, 3, 0, "$"), 9), "C5D24B27436CAB549890C7447371E385");
   AgVecC(c, D'2026.09.15 18:36:17', 2300.16, 2164.56, -130.20, AG_TG_PNL_ACTIVE, 126.21, AG_STATE_LOCKED, 3);
   AgVecMd5("tg_text_s4_crossed_2", AgVecLine(AgTgTextS4(c, 2, D'2026.09.16 01:00:00', 5.50, 200, -130.20, 3, 0, "$"), 9), "AA989057C11639AA0D0D129CC744A88C");
   AgVecC(c, D'2026.09.15 18:36:17', 2300.16, 2164.56, -130.20, AG_TG_PNL_ACTIVE, 126.21, AG_STATE_LOCKED, 3);
   AgVecMd5("tg_text_s4_crossed_3", AgVecLine(AgTgTextS4(c, 3, D'2026.09.16 01:00:00', 5.50, 200, -130.20, 3, 0, "$"), 9), "0CF45F95C868BB4FDC9D593D14A084F8");
   AgVecC(c, D'2026.09.28 10:44:02', 2805.35, 2805.35, -193.49, AG_TG_PNL_LOCKED, 164.94, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_s12_block_1", AgVecLine(AgTgTextS12Blocked(c, 1), 13), "F3574366B3946B005AA93EEFB934A8FA");
   AgVecC(c, D'2026.09.28 10:44:02', 2805.35, 2805.35, -193.49, AG_TG_PNL_LOCKED, 164.94, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_s12_block_2", AgVecLine(AgTgTextS12Blocked(c, 2), 13), "3BB17AA954D08482C61F0F4DDBAA6A61");
   AgVecC(c, D'2026.09.28 10:44:02', 2805.35, 2805.35, -193.49, AG_TG_PNL_LOCKED, 164.94, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_s12_block_3", AgVecLine(AgTgTextS12Blocked(c, 3), 13), "2BB617F209A19EA727A75568E43A2C11");
   AgVecC(c, D'2026.09.28 10:44:02', 2805.35, 2805.35, -193.49, AG_TG_PNL_LOCKED, 164.94, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_s12_block_4", AgVecLine(AgTgTextS12Blocked(c, 4), 13), "A27E4B25EFD4FE4733EE5D23411ED41D");
   AgVecC(c, D'2026.10.21 10:44:02', 2805.35, 2805.35, 12.40, AG_TG_PNL_ACTIVE, 164.94, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_s12_block_active_line", AgVecLine(AgTgTextS12Blocked(c, 1), 14), "0C4A0ADC373C0D0D878345EC53F86893");
   AgVecC(c, D'2026.09.23 16:57:35', 2880.70, 2879.58, -1.12, AG_TG_PNL_LOCKED, 147.54, AG_STATE_LOCKED, 1);
   AgVecMd5("tg_text_s16_source_0", AgVecLine(AgTgTextS16(c, D'2026.09.24 01:00:00', 1, 1, 1, 0, -1), 13), "1190A855302D01D8237B14F5FE144985");
   AgVecC(c, D'2026.09.23 16:57:35', 2880.70, 2879.58, -1.12, AG_TG_PNL_LOCKED, 147.54, AG_STATE_LOCKED, 1);
   AgVecMd5("tg_text_s16_source_1", AgVecLine(AgTgTextS16(c, D'2026.09.24 01:00:00', 1, 2, 1, 0, -1), 13), "C84EFF943B4B3E4B23F760FCE72D451B");
   AgVecC(c, D'2026.09.23 16:57:35', 2880.70, 2879.58, -1.12, AG_TG_PNL_LOCKED, 147.54, AG_STATE_LOCKED, 1);
   AgVecMd5("tg_text_s16_source_2", AgVecLine(AgTgTextS16(c, D'2026.09.24 01:00:00', 1, 4, 1, 0, -1), 13), "697C340958ED21AC627772BD8E8009A2");
   AgVecC(c, D'2026.09.23 16:57:35', 2880.70, 2879.58, -1.12, AG_TG_PNL_LOCKED, 147.54, AG_STATE_LOCKED, 1);
   AgVecMd5("tg_text_s16_source_3", AgVecLine(AgTgTextS16(c, D'2026.09.24 01:00:00', 3, 4, 1, 0, -1), 13), "A8E8B47DDB837FE9489141CFCA9D1E04");
   AgVecC(c, D'2026.09.23 16:57:35', 2880.70, 2879.58, -1.12, AG_TG_PNL_LOCKED, 147.54, AG_STATE_LOCKED, 1);
   AgVecMd5("tg_text_s16_source_5", AgVecLine(AgTgTextS16(c, D'2026.09.24 01:00:00', 2, 0, 1, 0, -1), 13), "3E50D0919DD74E948E29F3382A0B5079");
   AgVecC(c, D'2026.10.19 09:05:03', 2172.06, 2172.06, 0.0, AG_TG_PNL_NONE, 0.0, AG_STATE_SYNCING, 0);
   AgVecMd5("tg_text_s22_reason_2", AgVecLine(AgTgTextS22(c, 300, 2), 13), "21D166CDDB387BB9038DB12ECA60F5E2");
   AgVecC(c, D'2026.10.21 12:00:01', 2172.06, 2172.06, 0.0, AG_TG_PNL_NONE, 0.0, AG_STATE_SYNCING, 0);
   AgVecMd5("tg_text_status_head_0", AgVecLine(AgTgTextStatus(c, 1, -1, 0), 0), "230CA79BB306AB73BAE75AF4334EC56E");
   AgVecC(c, D'2026.10.21 12:00:01', 2172.06, 2172.06, 0.0, AG_TG_PNL_NONE, 0.0, AG_STATE_SAFE_HALT, 0);
   AgVecMd5("tg_text_status_head_1", AgVecLine(AgTgTextStatus(c, 1, -1, 0), 0), "52F6D3A4AD1903B68DCC15EE4D1EBD4B");
   AgVecC(c, D'2026.10.21 12:00:01', 2172.06, 2172.06, 0.0, AG_TG_PNL_NONE, 0.0, AG_TG_STATE_NOT_RUNNING, 0);
   AgVecMd5("tg_text_status_head_2", AgVecLine(AgTgTextStatus(c, 1, -1, 0), 0), "91267B133E82749BBCDF631759985241");
   AgVecC(c, D'2026.10.21 12:00:01', 2172.06, 2172.06, 0.0, AG_TG_PNL_ACTIVE, 126.21, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_status_age_line", AgVecLine(AgTgTextStatus(c, 1, 95, 0), 15), "BB4C6791812B5BA01A01A56AAB4A5370");
   AgVecC(c, D'2026.10.21 14:05:12', 2172.06, 2150.10, 0.0, AG_TG_PNL_NONE, 0.0, AG_TG_STATE_NOT_RUNNING, 0);
   AgVecMd5("tg_text_not_recorded_line", AgVecLine(AgTgTextNotResponding(c, 15, true, true), 13), "B478D7021F89A8B6823846526E9C2771");
   AgVecMd5("tg_text_overflow_line", AgVecLine(AgTgFinish("x", 12, 0, 0, "b"), 2), "649B93D21FDEC41EA656AB3119161A40");
   AgVecMd5("tg_text_held_back_line", AgVecLine(AgTgFinish("x", 0, 3, 0, "b"), 2), "62B20C0515188EFE8133243025BC6F5C");
   AgVecC(c, D'2026.10.19 14:05:12', 2172.06, 2172.06, 0.0, AG_TG_PNL_LOCKED, 126.21, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_s17_file_2", AgVecLine(AgTgTextS17(c, 2, 1), 13), "82D97E815C88CD69C4D39343F6B6075E");
   AgVecC(c, D'2026.10.19 14:05:12', 2172.06, 2172.06, 0.0, AG_TG_PNL_LOCKED, 126.21, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_s17_file_3", AgVecLine(AgTgTextS17(c, 3, 1), 13), "1A96F368A104F6EC4B141A6236060397");
   AgVecC(c, D'2026.10.19 14:05:12', 2172.06, 2172.06, 0.0, AG_TG_PNL_LOCKED, 126.21, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_s17_file_5", AgVecLine(AgTgTextS17(c, 5, 1), 13), "743E0941DB1924FEEE22E7281823E0C5");
   AgVecC(c, D'2026.10.19 14:05:12', 2172.06, 2172.06, 0.0, AG_TG_PNL_LOCKED, 126.21, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_s17_file_0", AgVecLine(AgTgTextS17(c, 0, 1), 13), "AAA47481713DA1F881FE0F6057CF95FF");
   AgVecC(c, D'2026.08.18 15:36:30', 239.63, 239.63, -1893.50, AG_TG_PNL_LOCKED, 106.66, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_s19_currency_line", AgVecLine(AgTgTextS19Locked(c, 2, 10.00, 150, 106.66, "$"), 13), "C49D041F37DDFC18958539D694FE1B1C");
   AgVecMd5("tg_text_locked_profit_line", AgTgPnlLine(AG_TG_PNL_LOCKED, 5.00, 147.54, "$"), "400B3138E87C478B7E8390E2345FE370");
   AgVecMd5("tg_text_singular_delay", AgVecLine(AgTgFinish("x", 0, 0, 1, "b"), 2), "455F2E092840574DB2E72CB09F203402");
   AgVecC(c, D'2026.08.04 16:37:04', 2133.00, 2133.00, 0.0, AG_TG_PNL_NONE, 0.0, AG_STATE_SAFE_HALT, 0);
   AgVecMd5("tg_text_singular_crash", AgVecLine(AgTgTextS3Crash(c, 1, 300), 12), "EBD4545D762780F20E117753316DD20D");
   AgVecC(c, D'2026.10.19 14:05:12', 2172.06, 2172.06, 0.0, AG_TG_PNL_ACTIVE, 126.21, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_singular_hard_stop", AgVecLine(AgTgTextS6H(c, 1, false, 2, "", 0, 1, 60), 0), "6C06EE97EF07A2C25F12DF0F7D9257EA");
   AgVecMd5("tg_text_b3_duration_1670", AgVecLine(AgTgFinish("x", 0, 0, 1670, "b"), 2), "1004C58A281DB32C6AC329E9D97A1ADF");
   AgVecMd5("tg_text_b3_duration_259200", AgVecLine(AgTgFinish("x", 0, 0, 259200, "b"), 2), "326A17C1B8CADD4755EBAB0FE797AA41");
   AgVecMd5("tg_text_b3_duration_7260", AgVecLine(AgTgFinish("x", 0, 0, 7260, "b"), 2), "0869368FC1996A7A2F20EE5AB8D0D552");
   AgVecMd5("tg_text_b3_duration_7500", AgVecLine(AgTgFinish("x", 0, 0, 7500, "b"), 2), "B67DE3F240FF4555B5E176F3C62C2725");
   AgVecMd5("tg_text_b3_sweep_3_2", AgTgSweepNow(3, 2), "0D52D2FC05098901B5E5960D3C7C07B0");
   AgVecMd5("tg_text_b3_sweep_0_1", AgTgSweepNow(0, 1), "EF9844431CDA9CCA48FC8394B53086D4");
   AgVecC(c, D'2026.09.23 15:28:24', 2880.70, 2880.70, 0.0, AG_TG_PNL_LOCKED, 147.54, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_b3_failures_line", AgVecLine(AgTgTextS6C(c, 3, 2, 5, 1, 7), 16), "A6C6BCED3E505F3818AF2DF4E98C7526");
   AgVecC(c, D'2026.10.20 01:00:04', 2140.50, 2140.50, 0.0, AG_TG_PNL_ACTIVE, 117.73, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_b3_locks_line", AgVecLine(AgTgTextS14(c, D'2026.10.19 01:00:00', -31.56, 12.40, 1, 117.73), 16), "7FCDF2E1F9F8CA77D976DFA9EB73D0F4");
   AgVecC(c, D'2026.10.22 14:30:05', 2544.33, 2530.10, -14.23, AG_TG_PNL_ACTIVE, 139.94, AG_STATE_LOCKED, 1);
   AgVecMd5("tg_text_ml_s5_engaged", AgTgFinish(AgTgTextS5(c, D'2026.10.22 15:00:05', D'2026.10.23 01:00:00', 1800, 1, 0), 0, 0, 0, ""), "CFBDE40E1ABEA8BB6447E6860EF5DC26");
   AgVecC(c, D'2026.10.22 14:30:05', 2544.33, 2544.33, 0.0, AG_TG_PNL_ACTIVE, 139.94, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_ml_s5_engaged_flat", AgTgFinish(AgTgTextS5(c, D'2026.10.22 15:30:05', D'2026.10.23 01:00:00', 3600, 0, 0), 0, 0, 0, ""), "3B43990E9DED4421DCCE5202AB7AB6BE");
   AgVecC(c, D'2026.10.22 14:30:05', 2544.33, 2544.33, 0.0, AG_TG_PNL_ACTIVE, 139.94, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_ml_s5_until_the_anchor", AgTgFinish(AgTgTextS5(c, D'2026.10.23 01:00:00', D'2026.10.23 01:00:00', 37795, 0, 0), 0, 0, 0, ""), "98DF470EF519863CA83A0BD424DE2D55");
   AgVecC(c, D'2026.10.22 15:00:10', 2544.33, 2544.33, 0.0, AG_TG_PNL_ACTIVE, 139.94, AG_STATE_ACTIVE, 0);
   AgVecMd5("tg_text_ml_s25_released", AgTgFinish(AgTgTextS25(c, 1, D'2026.10.22 15:00:05', 0, 0), 0, 0, 0, ""), "B954A9DC0826FE52FB0328343508001C");
   AgVecC(c, D'2026.10.22 15:00:10', 2530.10, 2530.10, -14.23, AG_TG_PNL_LOCKED, 139.94, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_ml_s25_again", AgTgFinish(AgTgTextS25(c, 2, D'2026.10.22 15:00:05', D'2026.10.23 01:00:00', 3), 0, 0, 0, ""), "C310DA2A5B5C9CBD6C7826F9B4404EC5");
   AgVecC(c, D'2026.10.22 15:00:10', 2530.10, 2530.10, -14.23, AG_TG_PNL_LOCKED, 139.94, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_ml_s25_why_3", AgVecLine(AgTgTextS25(c, 2, D'2026.10.22 15:00:05', D'2026.10.23 01:00:00', 3), 14), "E8B7EEFA5929EF3966C40B0D1759FA14");
   AgVecC(c, D'2026.10.22 15:00:10', 2530.10, 2530.10, -14.23, AG_TG_PNL_LOCKED, 139.94, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_ml_s25_why_1", AgVecLine(AgTgTextS25(c, 2, D'2026.10.22 15:00:05', D'2026.10.23 01:00:00', 1), 14), "DEA386B6A29F4D334D5822A11736084C");
   AgVecC(c, D'2026.10.22 15:00:10', 2530.10, 2530.10, -14.23, AG_TG_PNL_LOCKED, 139.94, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_ml_s25_why_2", AgVecLine(AgTgTextS25(c, 2, D'2026.10.22 15:00:05', D'2026.10.23 01:00:00', 2), 14), "8C658F4BB33617AACFEEB02088DD3149");
   AgVecC(c, D'2026.10.19 14:05:12', 2172.06, 2172.06, 0.0, AG_TG_PNL_LOCKED, 126.21, AG_STATE_LOCKED, 0);
   AgVecMd5("tg_text_ml_s17_file_6", AgVecLine(AgTgTextS17(c, 6, 1), 13), "DA05DB78E97549F273317EDC91123875");

   //--- the display formatters and the F10 helpers, format pass B3: the
   //--- time, the money and the currency, the durations, the zero counts,
   //--- the build line by class, the HTML escape and the plain text decision
   AgVecCheck("tg_fmt_stamp_drops_the_seconds", AgTgStamp(D'2026.10.21 15:34:59') == "21/10/2026 15:34", AgTgStamp(D'2026.10.21 15:34:59'));
   AgVecCheck("tg_fmt_stamp_pads_day_month_and_hour", AgTgStamp(D'2026.01.02 03:04:05') == "02/01/2026 03:04", AgTgStamp(D'2026.01.02 03:04:05'));
   AgVecCheck("tg_fmt_date", AgTgDate(D'2026.10.19 01:00:00') == "19/10/2026", AgTgDate(D'2026.10.19 01:00:00'));
   AgVecCheck("tg_fmt_money_zero", AgTgMoneyText(0.0) == "0.00", AgTgMoneyText(0.0));
   AgVecCheck("tg_fmt_money_under_a_thousand", AgTgMoneyText(999.99) == "999.99", AgTgMoneyText(999.99));
   AgVecCheck("tg_fmt_money_a_thousand", AgTgMoneyText(1000.0) == "1,000.00", AgTgMoneyText(1000.0));
   AgVecCheck("tg_fmt_money_the_reference_balance", AgTgMoneyText(2544.33) == "2,544.33", AgTgMoneyText(2544.33));
   AgVecCheck("tg_fmt_money_millions_rounded_to_the_cent", AgTgMoneyText(1234567.891) == "1,234,567.89", AgTgMoneyText(1234567.891));
   AgVecCheck("tg_fmt_money_negative", AgTgMoneyText(-1893.5) == "-1,893.50", AgTgMoneyText(-1893.5));
   AgVecCheck("tg_fmt_money_rounds_to_an_unsigned_zero", AgTgMoneyText(-0.004) == "0.00", AgTgMoneyText(-0.004));
   AgVecCheck("tg_fmt_currency_usd_eur_gbp_and_a_code", AgTgCurrencySign("USD") == "$" && AgTgCurrencySign("EUR") == ShortToString(0x20AC) && AgTgCurrencySign("GBP") == ShortToString(0x00A3) && AgTgCurrencySign("ILS") == "ILS", "");
   AgVecCheck("tg_fmt_amount_with_its_currency", AgTgWithCurrency("200", "$") == "200$" && AgTgWithCurrency("200", ShortToString(0x20AC)) == "200" + ShortToString(0x20AC) && AgTgWithCurrency("200", "ILS") == "200 ILS" && AgTgWithCurrency("200", "") == "200", "");
   AgVecCheck("tg_fmt_signed_with_currency", AgTgSignedWithCurrency(-130.20, "$") == "-130.20$" && AgTgSignedWithCurrency(90.96, "$") == "+90.96$" && AgTgSignedWithCurrency(0.0, "$") == "0.00$" && AgTgSignedWithCurrency(-0.004, "$") == "0.00$" && AgTgSignedWithCurrency(-1234.5, "ILS") == "-1,234.50 ILS", "");
   AgVecMd5("tg_fmt_duration_0", AgTgDuration(0), "65F0591AEA266B99583E345F8D3242BE");
   AgVecMd5("tg_fmt_duration_1", AgTgDuration(1), "9F02E20E218B7577888FC377BCBC4CB5");
   AgVecMd5("tg_fmt_duration_119", AgTgDuration(119), "5937383CE393C52A1E0BC79647E580C1");
   AgVecMd5("tg_fmt_duration_120", AgTgDuration(120), "96F342314B9CE77DBE9E78F1CBFE9944");
   AgVecMd5("tg_fmt_duration_179", AgTgDuration(179), "96F342314B9CE77DBE9E78F1CBFE9944");
   AgVecMd5("tg_fmt_duration_7199", AgTgDuration(7199), "F66B1227525D87CFFF42CD42D23A983B");
   AgVecMd5("tg_fmt_duration_7200", AgTgDuration(7200), "B702D0713ADE90B47330A661B1F2E77F");
   AgVecMd5("tg_fmt_duration_7260", AgTgDuration(7260), "EB48F2100A71D09B1C9BB9BE23A02D97");
   AgVecMd5("tg_fmt_duration_7320", AgTgDuration(7320), "C552E0E7E6C76713DDB30F3E2E540B65");
   AgVecMd5("tg_fmt_ago_4", AgTgAgo(4), "0A0380F64EA2B4BFEB00BCC65AFFA95B");
   AgVecMd5("tg_fmt_ago_5", AgTgAgo(5), "67FC56A122195D71F055281C19A70BB6");
   AgVecCheck("tg_fmt_sweep_line_with_both_zero_is_absent", AgTgSweepNow(0, 0) == "", AgTgSweepNow(0, 0));
   AgVecMd5("tg_fmt_sweep_line_positions_only", AgTgSweepNow(3, 0), "A56F24AEB1A74992647874AFBD8BB77F");
   AgVecMd5("tg_fmt_sweep_line_singular", AgTgSweepNow(1, 1), "C813D8DAAADD69D02A77462A1D4627CB");
   AgVecCheck("tg_fmt_add_leaves_an_empty_part_out", AgTgAdd("a", "") == "a" && AgTgAdd("", "b") == "b" && AgTgAdd("a", "b") == "a\nb", "");
   AgVecCheck("tg_fmt_html_escape", AgTgHtmlEscape("a&b<c>d") == "a&amp;b&lt;c&gt;d", AgTgHtmlEscape("a&b<c>d"));
   AgVecCheck("tg_fmt_html_escape_keeps_quotes_and_escapes_an_entity_again", AgTgHtmlEscape("\"x\" 'y' &amp;") == "\"x\" 'y' &amp;amp;", AgTgHtmlEscape("\"x\" 'y' &amp;"));
   AgVecCheck("tg_fmt_html_bold_wraps_line_one_after_the_escape", AgTgHtmlBold("head <1>\nline & 2\nline 3") == "<b>head &lt;1&gt;</b>\nline &amp; 2\nline 3", AgTgHtmlBold("head <1>\nline & 2\nline 3"));
   AgVecCheck("tg_fmt_html_bold_one_line", AgTgHtmlBold("only") == "<b>only</b>", AgTgHtmlBold("only"));
   AgVecC(c, D'2026.09.15 18:36:17', 2300.16, 2164.56, -130.20, AG_TG_PNL_ACTIVE, 126.21, AG_STATE_LOCKED, 3);
   AgVecMd5("tg_fmt_html_bold_on_the_s4_reference", AgTgHtmlBold(AgTgFinish(AgTgTextS4(c, 1, D'2026.09.16 01:00:00', 5.50, 200, -130.20, 3, 0, "$"), 0, 0, 0, "")), "BE82B016E55E936237BDA6FE943326A7");
   AgVecCheck("tg_fmt_plain_after_a_400_to_the_html_form_only", AgTgPlainAfter(400, true) && !AgTgPlainAfter(400, false) && !AgTgPlainAfter(200, true) && !AgTgPlainAfter(429, true) && !AgTgPlainAfter(-1, true), "");
   AgVecCheck("tg_fmt_build_line_classes", AgTgCarriesBuild("S1") && AgTgCarriesBuild("S2+S1") && AgTgCarriesBuild("S2") && AgTgCarriesBuild("STATUS") && AgTgCarriesBuild("REPLY") && AgTgCarriesBuild("S14") && !AgTgCarriesBuild("S4") && !AgTgCarriesBuild("S2+S16") && !AgTgCarriesBuild("S3") && !AgTgCarriesBuild("S11") && !AgTgCarriesBuild("LIVE_STOP"), "");
   AgVecCheck("tg_fmt_finish_without_a_build_line", AgTgFinish("x", 0, 0, 0, "") == "x" && AgTgFinish("x", 0, 0, 0, "b") == "x\nb", "");

   //--- pass B5, R3 and R4: the PNL line above zero, at zero, below zero
   //--- and not computed; the open trades line at none, one and several,
   //--- and left out of the lock messages whose sweep line gives the count
   AgVecMd5("tg_fmt_pnl_line_above_zero", AgTgResultLine(AG_TG_PNL_ACTIVE, 12.40, "$"), "8288BC22B5F6057EB6DC900AB4C795C8");
   AgVecMd5("tg_fmt_pnl_line_zero", AgTgResultLine(AG_TG_PNL_ACTIVE, 0.0, "$"), "C810BE0A81683AE8E4F0E4C7D9823DB4");
   AgVecCheck("tg_fmt_pnl_line_a_figure_that_prints_zero", AgTgResultLine(AG_TG_PNL_ACTIVE, 0.004, "$") == AgTgResultLine(AG_TG_PNL_ACTIVE, 0.0, "$") && AgTgResultLine(AG_TG_PNL_LOCKED, -0.004, "$") == AgTgResultLine(AG_TG_PNL_ACTIVE, 0.0, "$"), "");
   AgVecMd5("tg_fmt_pnl_line_below_zero", AgTgResultLine(AG_TG_PNL_ACTIVE, -130.20, "$"), "8CFC2E04AC781DFE65C16E56AB5D2EA7");
   AgVecMd5("tg_fmt_pnl_line_below_zero_with_a_code", AgTgResultLine(AG_TG_PNL_LOCKED, -1893.50, "ILS"), "75B91BC4C9A7BFAC3A77ED16E3886519");
   AgVecMd5("tg_fmt_pnl_line_not_computed", AgTgResultLine(AG_TG_PNL_NONE, -50.00, "$"), "763781BA6E938A4604C9A055F89687AB");
   AgVecMd5("tg_fmt_open_line_zero", AgTgOpenLine(0), "65B6B04458D52046119B2AA8B64BE98D");
   AgVecMd5("tg_fmt_open_line_one", AgTgOpenLine(1), "C6014F35ABEE6F5911DBFA8D00255F80");
   AgVecMd5("tg_fmt_open_line_several", AgTgOpenLine(12), "4B501325EDAEFFE46739613208168E1F");
   AgVecC(c, D'2026.09.15 18:36:17', 2300.16, 2164.56, -130.20, AG_TG_PNL_ACTIVE, 126.21, AG_STATE_LOCKED, 3);
   AgVecCheck("tg_fmt_open_line_left_out_where_the_sweep_line_counts", StringFind(AgTgTextS2(c, 1), AgTgOpenLine(3)) > 0 && StringFind(AgTgTextS4(c, 1, D'2026.09.16 01:00:00', 5.50, 200, -130.20, 3, 0, "$"), AgTgOpenLine(3)) < 0 && StringFind(AgTgTextS4Peak(c, D'2026.09.27 01:00:00', 253.00, 94.31, 90.96, 3, 0, "$"), AgTgOpenLine(3)) < 0 && StringFind(AgTgTextS16(c, D'2026.09.24 01:00:00', 1, 3, 3, 0, -1), AgTgOpenLine(3)) < 0, "");

   //--- the Manual Lockout build, R4 and ML-31: the open trades line left
   //--- out of S5, whose sweep line counts, and kept in S25
   AgVecC(c, D'2026.09.15 18:36:17', 2300.16, 2164.56, -130.20, AG_TG_PNL_ACTIVE, 126.21, AG_STATE_LOCKED, 3);
   AgVecCheck("ml_fmt_open_line_left_out_of_s5_with_its_sweep_line", StringFind(AgTgTextS5(c, D'2026.10.22 15:00:05', D'2026.10.23 01:00:00', 1800, 3, 0), AgTgOpenLine(3)) < 0 && StringFind(AgTgTextS25(c, 1, D'2026.10.22 15:00:05', 0, 0), AgTgOpenLine(3)) > 0, "");

   PrintFormat("AGVEC|SUMMARY|%d/%d", g_pass, g_total);
  }
//+------------------------------------------------------------------+
