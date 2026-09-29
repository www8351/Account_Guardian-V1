//+------------------------------------------------------------------+
//| AccountGuardian - State.mqh                                      |
//| State machine per SPEC v0.1 section 2.                           |
//| No trade calls in this file (static-structure rule, SPEC 1).     |
//+------------------------------------------------------------------+
#ifndef AG_STATE_MQH
#define AG_STATE_MQH

#include <AccountGuardian/Log.mqh>

enum ENUM_AG_STATE
  {
   AG_STATE_BOOT      = 0, // pseudo-state: before the first real transition
   AG_STATE_SYNCING   = 1,
   AG_STATE_ACTIVE    = 2,
   AG_STATE_LOCKED    = 3,
   AG_STATE_SAFE_HALT = 4
  };

//--- AG_LOCK_SWEEP_WITNESS (ruling PK-9(a) of 2026-09-28): the reason
//--- a boot derivation names when the guardian's own AG_SWEEP_MAGIC deals in
//--- today's server history are what re-derive the lock. It travels inside
//--- the state file's existing int-valued L field, so there is no format
//--- change and AG_STATE_FORMAT_VERSION stays 1.
enum ENUM_AG_LOCK_REASON
  {
   AG_LOCK_NONE          = 0,
   AG_LOCK_DAILY_BREACH  = 1,
   AG_LOCK_CORRUPT_STATE = 2,
   AG_LOCK_SWEEP_WITNESS = 3
  };

ENUM_AG_STATE       g_ag_state        = AG_STATE_BOOT;
ENUM_AG_LOCK_REASON g_ag_lock_reason  = AG_LOCK_NONE;
datetime            g_ag_locked_until = 0;
datetime            g_ag_state_since  = 0;   // wall clock, for seconds-in-state

string AgStateName(const ENUM_AG_STATE s)
  {
   switch(s)
     {
      case AG_STATE_BOOT:      return "BOOT";
      case AG_STATE_SYNCING:   return "SYNCING";
      case AG_STATE_ACTIVE:    return "ACTIVE";
      case AG_STATE_LOCKED:    return "LOCKED";
      case AG_STATE_SAFE_HALT: return "SAFE_HALT";
     }
   return "UNKNOWN";
  }

string AgLockReasonName(const ENUM_AG_LOCK_REASON r)
  {
   switch(r)
     {
      case AG_LOCK_NONE:          return "-";
      case AG_LOCK_DAILY_BREACH:  return "DAILY_BREACH";
      case AG_LOCK_CORRUPT_STATE: return "CORRUPT_STATE";
      case AG_LOCK_SWEEP_WITNESS: return "SWEEP_WITNESS";
     }
   return "UNKNOWN";
  }

//+------------------------------------------------------------------+
//| Seconds spent in the current state, wall clock so it advances in |
//| a dead market (proof of life, SPEC A3).                          |
//+------------------------------------------------------------------+
int AgSecondsInState()
  {
   if(g_ag_state_since == 0)
      return 0;
   return (int)(TimeLocal() - g_ag_state_since);
  }

//+------------------------------------------------------------------+
//| Single choke point for every transition. Exactly one log line.   |
//+------------------------------------------------------------------+
void AgTransition(const ENUM_AG_STATE to_state, const string reason, const string numbers)
  {
   ENUM_AG_STATE from_state = g_ag_state;
   g_ag_state       = to_state;
   g_ag_state_since = TimeLocal();
   AgLogTransition(AgStateName(from_state), AgStateName(to_state), reason, numbers);
  }

//+------------------------------------------------------------------+
//| Dynamic waiting-on detail for SYNCING and ACTIVE, set by the     |
//| caller each pass before AgProofOfLife (Phase 1, A6 4.4): the     |
//| live poll count while SYNCING, and the Q8 anchor-sanity or Q10   |
//| DEGRADED condition while ACTIVE, when either holds. One tick of  |
//| lag versus the pass that set it, same as every other proof-of-   |
//| life field, since AgProofOfLife runs before the state dispatch.  |
//+------------------------------------------------------------------+
string g_ag_dynamic_waiting_on = "";

//+------------------------------------------------------------------+
//| What a transitional state is waiting on, for the A3 life line.   |
//+------------------------------------------------------------------+
string AgWaitingOn()
  {
   switch(g_ag_state)
     {
      case AG_STATE_SYNCING:
         return (g_ag_dynamic_waiting_on != "")
                ? g_ag_dynamic_waiting_on
                : "history stability poll not yet run this session";
      case AG_STATE_ACTIVE:
         return g_ag_dynamic_waiting_on; // "" when no Q8/Q10 condition holds
      case AG_STATE_LOCKED:
         return "expiry: TimeCurrent >= locked_until";
      case AG_STATE_SAFE_HALT:
         return "manual resume: delete the halt file while the EA is stopped, then restart";
     }
   return "";
  }

#endif // AG_STATE_MQH
