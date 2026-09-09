//+------------------------------------------------------------------+
//| AccountGuardian - Log.mqh                                        |
//| Logging contract implementation per SPEC v0.1 sections 6 and 9   |
//| (amendment A3, proof of life).                                   |
//| No trade calls in this file (static-structure rule, SPEC 1).     |
//+------------------------------------------------------------------+
#ifndef AG_LOG_MQH
#define AG_LOG_MQH

enum ENUM_AG_LOG_VERBOSITY
  {
   AG_LOG_NORMAL  = 0, // Normal
   AG_LOG_VERBOSE = 1  // Verbose
  };

ENUM_AG_LOG_VERBOSITY g_ag_verbosity     = AG_LOG_NORMAL;
datetime              g_ag_last_life_log = 0;

//+------------------------------------------------------------------+
//| One structured journal line. Level: INFO/WARN/ALERT/TRANSITION.  |
//+------------------------------------------------------------------+
void AgLog(const string level, const string message)
  {
   PrintFormat("AG|%s|%s|%s", TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS), level, message);
  }

void AgInfo(const string message)  { AgLog("INFO", message); }
void AgWarn(const string message)  { AgLog("WARN", message); }

//+------------------------------------------------------------------+
//| Verbose-only line. Transitions and proof of life never route     |
//| through this: they must survive any verbosity setting.           |
//+------------------------------------------------------------------+
void AgVerbose(const string message)
  {
   if(g_ag_verbosity == AG_LOG_VERBOSE)
      AgLog("DEBUG", message);
  }

//+------------------------------------------------------------------+
//| Mandatory popup events (SPEC 6): journal line plus Alert().      |
//+------------------------------------------------------------------+
void AgAlertEvent(const string message)
  {
   AgLog("ALERT", message);
   Alert("AccountGuardian: ", message);
  }

//+------------------------------------------------------------------+
//| Exactly one line per state transition, with governing numbers.   |
//+------------------------------------------------------------------+
void AgLogTransition(const string from_state, const string to_state,
                     const string reason, const string numbers)
  {
   AgLog("TRANSITION", from_state + "->" + to_state + "|" + reason + "|" + numbers);
  }

//+------------------------------------------------------------------+
//| Proof of life (SPEC amendment A3). Every state emits this at a   |
//| fixed interval, SYNCING and LOCKED included, carrying the state, |
//| seconds in state, and what a transitional state waits on. A      |
//| stuck guardian and a healthy one must never look identical from  |
//| outside, which is exactly the failure this closes.               |
//| Never suppressed by verbosity, never rate-limited away.          |
//+------------------------------------------------------------------+
void AgProofOfLife(const string state_name, const int seconds_in_state,
                   const string waiting_on, const int interval_seconds,
                   const string numbers = "")
  {
   datetime now = TimeLocal();   // wall clock: must tick in a dead market too
   if(g_ag_last_life_log != 0 && now - g_ag_last_life_log < interval_seconds)
      return;
   g_ag_last_life_log = now;
   //--- Both clocks are sampled here on purpose. TimeCurrent is expected to
   //--- freeze in a dead market while TimeLocal keeps advancing; that is the
   //--- premise the A1/A3 clock exemption rests on, and it is inference until
   //--- a no-tick window puts it on the record.
   //--- numbers (A6, 4.5): the ACTIVE governing figures, anchor/realized/
   //--- floating/base/limit/pnl_vs_limit, appended when non-empty. Every
   //--- other state passes "" and the field is simply absent.
   AgLog("LIFE", "state=" + state_name
         + "|seconds_in_state=" + (string)seconds_in_state
         + "|waiting_on=" + (waiting_on == "" ? "-" : waiting_on)
         + (numbers == "" ? "" : "|" + numbers)
         + "|server=" + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS)
         + "|local=" + TimeToString(now, TIME_DATE | TIME_SECONDS));
  }

//+------------------------------------------------------------------+
//| LOCKED governing numbers as a LIFE-line field group. Defect 4 of |
//| the fix order FINAL of 2026-08-19, owner rulings D2D4-3(a),      |
//| D2D4-4(a), D2D4-5(a), D2D4-7(a) and D2D4-9(a) of 2026-09-09,     |
//| plan docs/FIXPLAN_PHASE3_DEFECTS_2_4_2026-09-08.md section 3.4.  |
//| A PURE FUNCTION OF ITS ARGUMENTS, placed here rather than in the |
//| EA so the vectors script can assert the exact string (ruling C   |
//| precedent of 2026-08-18): it reads no global, takes no platform  |
//| read and touches no clock. The EA's builder supplies the values: |
//| locked_until and the two Q6 snapshot fields from the state model |
//| the locked window is judged by, balance from ACCOUNT_BALANCE,    |
//| floating from AgFloating, and equity as balance plus floating,   |
//| never an ACCOUNT_EQUITY read (D2D4-4(a)). Deliberately ABSENT:   |
//| breach_time, which the shape 1 FINAL of 2026-08-20 requires be   |
//| reported with its provenance and is therefore not reported at    |
//| all (D2D4-5(a)); the live limit, which governs nothing under Q6; |
//| and peak, peak_level or ratchet_level, PRE BREACH ONLY under D8. |
//| A CORRUPT_STATE lock renders its zeroed snapshot as 0.00, a      |
//| faithful print of the model (D2D4-7(a)). The DEGRADED| prefix is |
//| the caller's (D2D4-6(a)), keyed on the Stage 6 connection sample |
//| inside the EA's builder, which keeps this function pure and the  |
//| Stage 6 static row clean. Two decimals throughout, the ACTIVE    |
//| group's own rendering.                                           |
//+------------------------------------------------------------------+
string AgLockedNumbersString(const datetime locked_until, const double limit_snap,
                             const double base_snap, const double balance,
                             const double floating, const double equity)
  {
   return "locked_until=" + TimeToString(locked_until, TIME_DATE | TIME_SECONDS)
        + "|limit_snap=" + DoubleToString(limit_snap, 2)
        + "|base_snap=" + DoubleToString(base_snap, 2)
        + "|balance=" + DoubleToString(balance, 2)
        + "|floating=" + DoubleToString(floating, 2)
        + "|equity=" + DoubleToString(equity, 2);
  }

//+------------------------------------------------------------------+
//| Chart banner: state, lock reason, locked_until, PnL vs limit.    |
//+------------------------------------------------------------------+
void AgBanner(const string state_name, const string lock_reason,
              const datetime locked_until, const string pnl_vs_limit)
  {
   string until = (locked_until > 0) ? TimeToString(locked_until, TIME_DATE | TIME_SECONDS) : "-";
   Comment("AccountGuardian\n",
           "State: ",        state_name,   "\n",
           "Lock reason: ",  lock_reason,  "\n",
           "Locked until: ", until,        "\n",
           "Daily PnL vs limit: ", pnl_vs_limit);
  }

void AgBannerClear() { Comment(""); }

#endif // AG_LOG_MQH
