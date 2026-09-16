# Plan, the enforcement phase, the Sweep.mqh flatten engine

Dated 2026-09-16. Written on branch `worktree-enforcement-plan-20260916`, cut from main at `6a44dbaac4ef0ba752db27ee44f97ed6d39adf97`, and every line citation below is against that commit. NO CODE WAS WRITTEN, NO COMPILE WAS RUN, NO VECTOR WAS EDITED, NOTHING WAS DEPLOYED, and nothing under the MetaTrader Terminal data folder was read, written or approached, per RULE A (`LEDGER.md:2039-2041`). No command named a path inside that folder, so RULE B's alias audit was not reached.

## Scope and what this document is not

This is the plan for the phase the ISSUES head names as the next best action: "THE NEXT BEST ACTION IS THE ENFORCEMENT PHASE KICKOFF, `Sweep.mqh`, the flatten engine" (`LEDGER.md:11`). It is the phase every earlier ruling deferred enforcement to: "SWEEP, FLATTEN AND PENDING ORDER DELETION REMAIN PHASE 3 and no Phase 2 work may reach for them" (`LEDGER.md:1987`). The instruction that produced this document names it the last gate before COMPLETE; what the SPEC's own Definition of Done lists beyond it is quoted in section 3.9 rather than assumed away.

**NO SHAPE IS RECOMMENDED HERE.** Section 4 is a ruling sheet of closed questions, ENF-1 onward, with the consequence of each option, and nothing in it leans. The owner reserves the design, per the process ruling of 2026-07-29: "Only the owner marks an entry FINAL. The executor proposes; the owner rules" (`LEDGER.md:2130`). This document is not an authorization to write code and gives none.

Notation. `EA:<n>` is `MQL5/Experts/AccountGuardian/AccountGuardian.mq5` line `<n>` at `6a44dba`; `Sweep.mqh:<n>`, `Pnl.mqh:<n>`, `Persist.mqh:<n>`, `State.mqh:<n>`, `Log.mqh:<n>`, `Clock.mqh:<n>` are the includes under `MQL5/Include/AccountGuardian/`; `Vectors:<n>` is `MQL5/Scripts/AccountGuardian/AgPhase2StateVectors.mq5`; `SPEC:<n>` is `docs/SPEC_v0.1.md`; `REVIEW:<n>` is `docs/REVIEW_v0.md`; `D2D4PLAN:<n>` is `docs/FIXPLAN_PHASE3_DEFECTS_2_4_2026-09-08.md`. `<...>` marks a field whose value depends on the run. Predictions continue the numbering of `docs/FIXPLAN_PHASE3_DEFECTS_2_4_2026-09-08.md`, which ended at P75 (`D2D4PLAN:432`), so this document runs from P76. Ruling questions are ENF-1 onward. Acceptance rows are ENF-S<n> (static), ENF-D (deploy), ENF-0 (synthetic) and ENF-L<n> (live).

Source identity at `6a44dba`, measured this session by `Get-FileHash` in the repository, standing rule 7 (`LEDGER.md:1897`): `AccountGuardian.mq5` `4A66E125E7FE1C1D3C2EE3DDDAED8CAA` at 73271 bytes, `Log.mqh` `C29F4DE91B7FD43D5E2EA3A9BE2BDB46` at 7347, `Persist.mqh` `0728E30210CAB55C7F83FD46E4F8D0A6` at 60174, `Pnl.mqh` `B961E6F70B3EC270FF776E21F307D69F` at 20877, `State.mqh` `34792807C6B6B548943215866193EB3F` at 4066, `Clock.mqh` `DC5A04004F0CB7BDB9D6C602E944CEC1` at 10151, `Sweep.mqh` `600B083C69C7D4B121303C2590685414` at 1913, `AgPhase2StateVectors.mq5` `7CBAC4F6489C9D01BD71A2E3C7EF4199` at 36405, `AgPhase1ClockVectors.mq5` `26E7AD2E8A3AC6EDD283CFC2BD7C31CF` at 7033. Every value except `Sweep.mqh` equals the D2D4 build identity at `LEDGER.md:116`, and `Sweep.mqh` differs from the `CF7D355A7C52265A7AFF5C465DA33C46` recorded there by line endings only, 1913 bytes against 1944, which `LEDGER.md:1201` established on the same two values. So the source this plan cites is the source of the binary deployed on 2026-09-15 and guarding the account now, `AccountGuardian.ex5` `A070D9D1B6C0536F325BCCFC6986F7EB` (`LEDGER.md:105`).

---

## TASK 1, what is already ruled

### 1.1 The interim posture, Phase 2 open question TWO, FINAL 2026-08-18, quoted whole

`LEDGER.md:1987-1989`:

> Decision: (owner ruling 2026-08-18, Phase 2 open question TWO) THE PHASE 2 INTERIM POSTURE IS SANCTIONED EXPLICITLY. A Phase 2 build LOCKS THE STATE MACHINE BUT SENDS NO ORDER. On a real breach the account shows LOCKED with Alerts, and the positions stay open until the owner closes them by hand; the floating loss keeps moving in the meantime and that is accepted, not a defect to be fixed inside Phase 2. Accepted for the demo build window and on the same footing as the Phase 1 alert only sanction ruled under Q2 on 2026-08-08. SWEEP, FLATTEN AND PENDING ORDER DELETION REMAIN PHASE 3 and no Phase 2 work may reach for them, including as a convenience or a safety net.
> Reason: Owner's ruling. The gap is real and was raised precisely because a locked account with open positions is not what "enforcement" sounds like: Phase 2 can refuse to let the state machine leave LOCKED, but the capability to close a position lands in Phase 3, so between breach and the owner's manual close the loss is unbounded by the guardian. The precedent is exact rather than approximate, which is why this is sanctioned on the same footing: Phase 1 shipped a window where a real breach could only alert, the owner sanctioned that window explicitly under Q2 instead of letting it be an unstated consequence, and this is the same shape one stage later with more of the machine present. Naming it FINAL means no later session treats the open positions as a bug against Phase 2 or quietly adds an order send to close the gap. Rejected: pulling sweep or flatten forward into Phase 2 to make enforcement complete, which would put order sending into a build whose state machine is itself the thing under test.
> Status: FINAL

Tag: MUST BE SUPERSEDED. Every option in section 3 sends an order from a LOCKED guardian. The entry's own words scope it to "a Phase 2 build" and to "the demo build window", and name Phase 3 as the home of the capability, so the supersession is the one the entry anticipates. What survives it untouched: the Q2 Phase 1 precedent at `LEDGER.md:2241-2243`, which sanctioned a window that has since closed, and the ruling's rejection of order sending inside "a build whose state machine is itself the thing under test", which the D2/D4 acceptance of 2026-09-15 closed on quoted lines (`LEDGER.md:105-112`).

### 1.2 "Ruling TWO" is this same entry, and where the ledger uses that name

The instruction names "ruling TWO that put enforcement out of Phase 2" as a second item. In this ledger "ruling TWO" is the name the Stage 7 session gave Phase 2 open question TWO, and it resolves to the entry quoted in 1.1 everywhere it appears:

- `LEDGER.md:1267`: "RULING TWO HOLDS, AND THE EXECUTOR IS NOT THE WITNESS FOR IT. Owner reported that thirteen XAUUSD sell positions of 0.5 lot each were open at 13:02 ... that the broker force closed all of them on margin, and that the guardian closed nothing."
- `LEDGER.md:1193`: "ruling TWO, on the broker's own `0 positions, 0 orders` line".
- `LEDGER.md:68` (the max position size input): "it sits in tension with ruling TWO, which keeps positions open when a lock is declared."
- `EA:415-419`, the comment above `AgDeclareLock`: "Ruling TWO (FINAL 2026-08-18): the state machine locks and NO ORDER IS SENT. Positions stay open until the owner closes them by hand, the floating loss keeps moving, and that is sanctioned rather than a defect. Sweep, flatten and pending deletion are Phase 3 and nothing here may reach for them."

Two other entries carry the number TWO and are not this ruling: the 2026-08-19 Phase 3 opening session's ruling TWO, the reseed on reload (`LEDGER.md:1935-1937`), and the 2026-08-31 ruling TWO on build identity (`LEDGER.md:1909`). Neither touches enforcement and both are INHERITED (section 1.9).

The Phase 1 precursor the interim posture stands "on the same footing" as, quoted whole, `LEDGER.md:2241-2243`:

> Decision: (Q2, owner ruling 2026-08-08) Interim breach posture for the Phase 1 deployed build, before Phase 2 enforcement exists: on a computed breach, the guardian raises a loud ALERT plus a journal arithmetic line, stays in ACTIVE, and repeats the ALERT and journal line at a bounded cadence while the condition holds. No lock, no sweep, no state change; Phase 1 detects and shouts, it does not enforce.
> Reason: Owner explicitly sanctions the no-enforcement window this creates until Phase 2 lands; a real breach during Phase 1 is visible and loud rather than either silent or falsely locked by code that does not yet exist to unlock correctly.
> Status: FINAL

Tag: INHERITED. Its window closed when Phase 2 shipped the lock; nothing here reopens it.

### 1.3 "The D8b ruling of 2026-08-24" resolves to no DECISIONS entry

The ISSUES head says the phase was "named at the D8b ruling of 2026-08-24" (`LEDGER.md:11`) and the 2026-09-15 ACTIONS entry repeats it (`LEDGER.md:112`). Checked rather than assumed: the string `D8b` occurs in DECISIONS at `LEDGER.md:2310` and `:2315` only, both the R10 ruling of 2026-09-03 on retired a9 vectors, which has nothing to do with enforcement. The 2026-08-24 version 1 FINAL runs D1 through D8 with D6, D7 and D8 as amendments (`LEDGER.md:2237`, "D1 through D5 in chat on this date and then D6, D7 and D8 as amendments"), and carries no D8b. What that FINAL does say about enforcement is one sentence inside element NINE (D8), `LEDGER.md:1913`:

> Under the Phase 2 open question TWO interim posture those locks still send no order, so between the lock and the owner's manual close the floating loss remains unbounded by the guardian; version 1 tightens WHEN the state machine locks and changes nothing about what the guardian can do once it has.

That sentence names the gap and defers to question TWO; it does not name a phase. The phase is named, as Phase 3, by the interim posture FINAL itself (`LEDGER.md:1987`), by the max enforcement FINAL of 2026-07-29 (`LEDGER.md:2055`), by Q3/F2 and Q5/F16 of the same date (`LEDGER.md:2070`, `:2078`), by SPEC section 8 (`SPEC:170-175`), and by the `Sweep.mqh` header (`Sweep.mqh:9-11`). RECORDED AS A CITATION DEFECT in the ISSUES head, to be corrected there by appending, never by editing the 2026-09-15 ACTIONS line, which is append only. The D8 cost clause quoted above is the descriptive sentence this phase makes untrue, the same class of clause as the version 1 Reason's "NO Equity read is introduced anywhere" (`LEDGER.md:1916`, cited as `:1883` by `D2D4PLAN:466` against `bd61a0f`) under D2D4-4: a FINAL's description of the tree stops describing the tree, and the build entry must say so. It is not a ruling clause and needs no unlock.

### 1.4 "SPEC section 2.4 CloseAll" resolves to no SPEC text, and what the SPEC does say, quoted whole

`docs/SPEC_v0.1.md` has no section 2.4 and the string `CloseAll` occurs nowhere in the tree. The sweep obligations the instruction paraphrases (loop positions and pendings, close and delete, verify empty, retry with backoff, hard stop count, event) sit in five places, and each is quoted so the design below is worked against words rather than a memory of them.

The product statement, `SPEC:8`:

> Single account-level lockout EA for MetaTrader 5, one JustMarkets terminal, Windows. Daily loss breach: flatten every position and delete every pending order on the account (every symbol, magic, origin, including mobile and manual), then lock until expiry. While locked, anything newly opened is flattened within seconds of the platform accepting a close for that symbol. Weekly PnL is measured and reported only; no weekly code path may lock, close, or sweep. Unlock is time expiry only. No manual override of any kind.

The state machine, `SPEC:41`, `SPEC:50`, `SPEC:56`:

> lock_reason in {DAILY_BREACH, CORRUPT_STATE}. Sweeping is a behavior of LOCKED, not a state. CANNOT_TRADE is a tracked and logged sub-condition inside LOCKED (section 4.4), not a state.

> | ACTIVE | LOCKED (DAILY_BREACH) | daily PnL <= -(limit) | snapshot limit and base into state file (Q6), set locked_until = next day anchor (Q1), persist, delete pendings, begin sweep |

> SAFE_HALT is not a lock: excluded from expiry, cleared only by manual restart. SAFE_HALT while a lock exists leaves the account unswept by design (guardian code presumed broken); this shadow is documented and drilled, not hidden.

Section 4.4, breach and sweep, `SPEC:93-99`, quoted whole:

> ### 4.4 Breach and sweep
> - Breach: daily PnL <= -(limit_currency), epsilon 0.01 account-currency units errs toward breach. On breach: snapshot, persist, lock, delete all pending orders, flatten all positions. **Phase 1 interim posture (A6, Q2 FINAL):** enforcement lands in Phase 2; the deployed Phase 1 build takes no lock action on breach. It raises a loud ALERT plus a per-pass journal arithmetic line, repeated at `AG_LIFE_INTERVAL_SECONDS` (30 s) while the condition holds, and stays ACTIVE. Owner-sanctioned no-enforcement window.
> - Breach-declaration deferral (A6, Q9 FINAL): a pass where the result crosses the limit with no new deal visible in the selected history (HistoryDealsTotal() unchanged from the prior pass) defers its declaration by exactly one timer pass; the following pass declares unconditionally regardless of deal count. Guards Balance-versus-history coherence; never suppresses two passes running.
> - DEGRADED (A6, Q10 FINAL, amended by the 2026-08-09 owner ruling below): while TERMINAL_INFO_CONNECTED is false, ACTIVE performs no breach evaluation and raises no breach ALERT; the LIFE line and banner mark the state DEGRADED, prefixing the governing-numbers field group itself with `DEGRADED|` (not only the waiting_on field), and continue showing the last-known figures. The instant the connection returns, evaluation does not resume immediately: it re-enters gated on history stability, the same discipline as the SYNCING exit condition (2026-08-09 owner ruling, reconnect coherence). No state transition; the LIFE line shows the live poll count prefixed RESYNC while gated, distinct from initial SYNCING. Q9's one-pass coherence deferral is unchanged and applies only once evaluation has resumed.
> - Sweep (behavior of LOCKED): every timer tick while anything is open, one pass over all positions and pendings; per-position backoff; a distinct log line per failure retcode; no unbounded tight retry.
> - Trade-disallowed states (Q3, FINAL), each enumerated and logged distinctly: TERMINAL_TRADE_ALLOWED false, MQL_TRADE_ALLOWED false, ACCOUNT_TRADE_ALLOWED false, ACCOUNT_TRADE_EXPERT false, investor-password login, symbol session closed or close-only. All are kill-equivalent: detect-only, continuous loud alerting (journal + Alert + chart banner), immediate sweep the moment trading is restored. The formal promise: flattened within seconds of the platform accepting a close for that symbol.
> - Disconnection: mobile trades run unswept while the terminal is offline. Kill-equivalent, accepted. On reconnect: SYNCING, then immediate sweep, and the coverage gap logged with timestamps.

The logging contract, `SPEC:132-133`:

> - Sweep: one line per close or delete attempt with retcode; failure reasons distinct; trade-disallowed states enumerated by name.
> - Alert popups mandatory for: breach, lock, unlock, state-write failure, cannot-trade-while-locked, SAFE_HALT.

The threat model's guardian clause, `SPEC:144`:

> The guardian must never be the hazard: no spurious flatten from deposits or withdrawals (4.3), no flatten from a half-loaded history (SYNCING), no order storms (bounded retries), SAFE_HALT closes nothing.

The Phase 3 matrix, `SPEC:170-175`:

> ### Phase 3, sweep engine
> - Breach flattens EA, manual, and mobile positions, and deletes pendings.
> - New mobile position while locked closed within seconds; both timer and OnTradeTransaction paths exercised.
> - AutoTrading toggled off while locked: continuous alert, no crash, sweep resumes on re-enable.
> - Closed-session symbol: bounded retries, distinct logs, no order storm.
> - Partial close and hedging-account matrix.

And the review findings the SPEC condensed, which carry the reasoning: F2 on the trade disallowed states, `REVIEW:23-29`; F10 on retry, `REVIEW:71-75`, "the sweep engine runs a pass over all open positions every timer tick while LOCKED, with per-position backoff, a distinct log line per failure retcode, and no unbounded tight retry. 'Within seconds' is redefined as: within seconds of the platform being able to accept a close for that symbol."; F14 on disconnection, `REVIEW:89-91`, "on reconnect, enter SYNCING then sweep immediately, and log the coverage gap with timestamps"; F16 on pendings, `REVIEW:97-99`, "Breach flatten and the lock sweep should also delete pending orders, else a resting stop fills straight into a flatten with spread and commission churn ... All blocking is reactive closing."; and F6, `REVIEW:51`, "In SYNCING the guardian enforces any persisted or GV lock (sweeping allowed) but makes no unlock decision and no new-breach decision until TERMINAL_CONNECTED is true and HistoryDealsTotal is stable across N consecutive polls."

Three things the SPEC does NOT contain, stated so the ruling sheet does not pretend otherwise: no attempt count, no backoff schedule, and no ordering between positions and pendings beyond the transition table's "delete pendings, begin sweep" (`SPEC:50`) against the review skeleton's "Positions first, pendings per Q5" (`REVIEW:153`), which disagree. "Verify empty" and "hard stop count" are the instruction's words and are ruled in section 4, not read out of the SPEC.

### 1.5 `Sweep.mqh`, quoted whole

`Sweep.mqh:1-31`:

```
//+------------------------------------------------------------------+
//| AccountGuardian - Sweep.mqh                                      |
//| Flatten engine, pending deletion, retry policy. SPEC v0.1 4.4.   |
//|                                                                  |
//| STATIC-STRUCTURE RULE (SPEC 1): this is the ONLY file in the     |
//| project permitted to reach the trade API. Every other file must  |
//| grep clean for OrderSend, CTrade, PositionClose, OrderDelete.    |
//|                                                                  |
//| PHASE 0: deliberately empty of trading calls. The Phase 0        |
//| acceptance matrix requires the whole build, this file included,  |
//| to contain no trade API reference at all. Bodies land in Phase 3.|
//+------------------------------------------------------------------+
#ifndef AG_SWEEP_MQH
#define AG_SWEEP_MQH

//+------------------------------------------------------------------+
//| Phase 3 obligations, declared here so the contract is visible:   |
//|                                                                  |
//| bool AgTradeAllowed(string &blocking_state)                      |
//|   Enumerate and name each disallowed state distinctly (Q3):      |
//|   TERMINAL_TRADE_ALLOWED, MQL_TRADE_ALLOWED,                     |
//|   ACCOUNT_TRADE_ALLOWED, ACCOUNT_TRADE_EXPERT, investor login,   |
//|   symbol session closed or close-only.                           |
//|                                                                  |
//| void AgSweepPass()                                               |
//|   One pass per timer tick while LOCKED: delete all pendings,     |
//|   close all positions, per-position backoff, one log line per    |
//|   attempt carrying the retcode, no unbounded tight retry.        |
//+------------------------------------------------------------------+

#endif // AG_SWEEP_MQH
```

The file is a contract and nothing else: two declared obligations, `AgTradeAllowed` and `AgSweepPass`, no function body, no include, no global. The header's static structure rule at `:5-7` is INHERITED and is the rule the new static rows in 3.10 enforce; the Phase 0 clause at `:9-11` is the clause this phase retires.

### 1.6 The D2D4-S2 no trade API static row

The row as last run, `LEDGER.md:117`:

> STATIC ROWS. D2D4-S2, no trade API: the grep for `OrderSend`, `CTrade`, `PositionClose`, `OrderDelete` and `Trade.mqh` over `MQL5/` returns exactly one line, `MQL5/Include/AccountGuardian/Sweep.mqh:7`, the header comment `grep clean for OrderSend, CTrade, PositionClose, OrderDelete.`, CLOSED.

Its definition, `D2D4PLAN:381`: "| D2D4-S2 no trade API | grep `OrderSend`, `CTrade`, `PositionClose`, `OrderDelete`, `Trade.mqh` over `MQL5/` | exactly one hit, `Sweep.mqh` header comment | grep output quoted |". Its ancestry is the Phase 0 matrix, `LEDGER.md:1806-1807`: "S1 no trade API anywhere in the build PASS static grep, only hit is the rule comment inside Sweep.mqh" and "S2 trade API confined to Sweep.mqh PASS static grep, scaffold in place, zero call sites". The max position size ISSUES entry already named what this phase does to the row, `LEDGER.md:68`: "S1 and S2 have held at literally zero calls since Phase 0 ... A size gate that closes positions changes the meaning of those rows from 'no call exists' to 'calls exist and are confined to `Sweep.mqh`', which is a different and weaker invariant, and the kickoff should decide the rows' new wording deliberately rather than let them quietly degrade." Re measured this session at `6a44dba`: the same grep returns `Sweep.mqh:7` and nothing else. Tag: the row itself is an acceptance row, not a FINAL; the SPEC rule it measures, `SPEC:34` "the trade API (OrderSend and relatives) is reachable only from Sweep.mqh", is INHERITED and is what the replacement rows in 3.10 keep true. Also relevant and INHERITED: `LEDGER.md:1794` "A5 stands as PASS-BY-CONSTRUCTION, not PASS: no trade API exists in this build, so the row proves nothing about Phase 3 and carries forward to the sweep engine." A5 is "SAFE_HALT closes nothing" (`LEDGER.md:1814`), and this phase is where it stops being by construction.

### 1.7 The hedge account facts on record

The account is a hedging account, stated by the terminal itself on every authorization: `docs/evidence/terminal-20260915-d2d4-restarts-and-kills.txt:6` `'1200252169': trading has been enabled, demo account - hedging mode`, and again at `:31`, `:83` and `:93` of the same file; `docs/evidence/terminal-20260830-zero-positions.txt:28` the same line; `docs/evidence/terminal-journal-20260811-manual-trades.txt:9` the same line. The ledger never writes the word: a search of `LEDGER.md` for `hedg` returns zero hits, so this document is the first place the fact is written into the record rather than left in the artifacts.

What hedging mode means for a flatten engine, measured on this account rather than argued: same direction positions on one symbol stay separate positions. On 2026-08-18 "thirteen XAUUSD sell positions of 0.5 lot each were open at 13:02" (`LEDGER.md:1267`), thirteen tickets `#279906117` through `#279906181` closed by the broker at one price inside 65 milliseconds; a netting account would have carried one 6.5 lot position. On 2026-09-15 three separate `market sell 0.3 XAUUSD.ecn` orders at `terminal-20260915-d2d4-restarts-and-kills.txt:52`, `:56` and `:60` produced three separate deals `#421828196` at 4284.80 (`:54`), `#421828561` at 4284.95 (`:58`) and `#421828835` at 4284.78 (`:62`), and three separate closing deals `#421845000`, `#421845001` and `#421845028` at `:64-66`. A close on this account therefore names a position ticket, and the terminal's own close request form shows it: `:44` `market sell 0.3 XAUUSD.ecn, close #701106385 buy 0.3 XAUUSD.ecn 4284.72`. The Q7 specification read carries the hedged margin figures, `docs/evidence/phase1-manual-trades-2026-08-11.md:185` "Hedged margin 5000" for XAGUSD.ecn and `:196` "Hedged margin 1" for US100.ecn. The SPEC's Phase 3 matrix names a "Partial close and hedging-account matrix" row (`SPEC:175`) and defines nothing further for it.

What is NOT on record: no code in the tree reads `ACCOUNT_MARGIN_MODE` (grep this session, zero hits), so the guardian has never confirmed the mode from inside MQL5; no close by opposite position has ever been exercised on this account; the BTCUSD.ecn specification has never been read, the Q7 read having covered the three symbols of the 2026-08-01 composition before BTCUSD returned on 2026-09-01 (`LEDGER.md:1905`); and the filling mode of XAUUSD.ecn was not transcribed, the only filling mode on record being US100.ecn's "Filling Fill or Kill" (`phase1-manual-trades-2026-08-11.md:197`).

### 1.8 The instrument scope FINAL and its 2026-09-01 supersession, quoted whole

`LEDGER.md:2191-2193`:

> Decision: (owner ruling 2026-08-01) Account instrument scope and Market Watch composition. The account trades gold, NASDAQ, and possibly silver, nothing else. Market Watch is XAUUSD.ecn, US100.ecn and XAGUSD.ecn only. BTCUSD.ecn is removed and never returns. All subscribed instruments are 24/5, so the weekend close is a reliable no-tick window by design. Consequence recorded with the ruling: the frozen-upper-bound finding is downgraded from blocker class to a Phase 1 correctness obligation, not closed, and its crypto example is struck as no longer operative.
> Reason: A 24/7 instrument in Market Watch keeps TimeCurrent advancing through the weekend, which destroys the A8 no-tick window and is the only route by which a deal could execute inside a frozen PnL window on this account. Removing it makes both impossible by construction here, while the general upper-bound defect remains a Phase 1 obligation because it does not need a 24/7 instrument.
> Status: FINAL

`LEDGER.md:1905-1907`:

> Decision: (owner ruling 2026-09-01, given in chat, recorded verbatim) "THE ACCOUNT TRADES EVERYTHING AND EVERYTHING IS LOCKED. The guardian's scope is the whole account, every symbol, every source, mobile included, which the 2026-08-29 and 2026-08-31 evidence proves. BTCUSD.ecn STAYS IN MARKET WATCH PERMANENTLY, so that the guardian's clock, TimeCurrent, follows the account's real trading hours including weekends. The weekend is a trading day: day anchors roll at 01:00 every day including Saturday and Sunday. The weekend is no longer a guaranteed no-tick window, and any earlier test or entry that assumed one is read under this ruling from now on. The 2026-08-01 FINAL's removal of BTCUSD.ecn is superseded in that clause; its frozen-quote protections stand unchanged for any freeze that still occurs." What this entry supersedes, by name and exactly how far: THE 2026-08-01 INSTRUMENT SCOPE FINAL (owner ruling 2026-08-01), its instrument list clause, "Market Watch is XAUUSD.ecn, US100.ecn and XAGUSD.ecn only. BTCUSD.ecn is removed and never returns.", and its weekend no-tick assumption clause, "All subscribed instruments are 24/5, so the weekend close is a reliable no-tick window by design.", AND THOSE TWO CLAUSES ONLY. Every other clause of that FINAL stands untouched and is reaffirmed here: the account still trades gold, NASDAQ and silver among whatever else this ruling adds under "everything", XAUUSD.ecn, US100.ecn and XAGUSD.ecn remain in Market Watch, and the frozen-upper-bound consequence clause is not argued here in either direction.
> Reason: The mechanism the owner ruled on: with a 24/7 instrument absent from Market Watch, a weekend trade placed from the mobile app would run against a guardian whose clock, TimeCurrent, is frozen for the whole weekend, since nothing ticks to advance it, so the guardian's day anchors and its enforcement would sit stale exactly when a mobile trade could move the account. That is the configuration to avoid, not the one to keep. BTCUSD.ecn's continuous quote is what keeps TimeCurrent advancing through the weekend, which is why it stays in Market Watch permanently rather than being treated as an incidental presence.
> Status: FINAL

Tag: INHERITED by every option except scope option (b) in 3.2, which MUST SUPERSEDE "THE ACCOUNT TRADES EVERYTHING AND EVERYTHING IS LOCKED. The guardian's scope is the whole account, every symbol, every source, mobile included" and `SPEC:126` "No symbol filter, no magic filter. Scope is everything on the account." What the two rulings together fix for the sweep: four symbols in Market Watch, three of them 24/5 with a nightly trade session gap and a weekend gap (`phase1-manual-trades-2026-08-11.md:180-181`, `:190-192`, `:202-203`) and one, BTCUSD.ecn, trading through the weekend on an unread specification.

### 1.9 Every FINAL a flatten engine touches, tagged INHERITED or MUST BE SUPERSEDED

Method: the DECISIONS section (`LEDGER.md:1835-2355`) was read whole this session and every entry whose clause a sweep would read, write, print, bypass or contradict is listed. A clause is INHERITED when every option in section 3 satisfies it as written. A clause is MUST BE SUPERSEDED when at least one option cannot ship without the owner reopening it, and that option is named. Two entries are superseded by every option; the rest are superseded by named options only or by none.

| FINAL | Location | Quoted clause | Tag |
|---|---|---|---|
| Interim posture, question TWO | `LEDGER.md:1987` | "A Phase 2 build LOCKS THE STATE MACHINE BUT SENDS NO ORDER ... SWEEP, FLATTEN AND PENDING ORDER DELETION REMAIN PHASE 3" | MUST BE SUPERSEDED by every option, section 1.1. The entry scopes itself to Phase 2 and names Phase 3 as the home. |
| The `Sweep.mqh` Phase 0 clause and the S1/S2 row wording | `Sweep.mqh:9-11`, `LEDGER.md:1806-1807`, `LEDGER.md:117` | "PHASE 0: deliberately empty of trading calls" and "no trade API anywhere in the build" | MUST BE SUPERSEDED by every option; not a DECISIONS entry but the row the instruction names, replaced by ENF-S2 and ENF-S3 in 3.10 per `LEDGER.md:68`. The SPEC rule behind it, `SPEC:34`, is INHERITED. |
| Version 1, element NINE, D8 cost clause | `LEDGER.md:1913` | "those locks still send no order, so between the lock and the owner's manual close the floating loss remains unbounded by the guardian" | Descriptive clause, superseded in effect by every option; not a ruling clause, no unlock, the build entry says so (section 1.3). Element NINE itself, "THE PEAK DOES NOT ENTER THE LOCK SNAPSHOT ... PRE BREACH ONLY", INHERITED: the sweep is post breach only and reads no peak. |
| Max enforcement | `LEDGER.md:2055` | "EA cannot close terminal or disconnect from broker. Max enforcement is closing positions, deleting pending orders, blocking new opens." | INHERITED. Every option closes and deletes; "blocking new opens" is reactive closing per `REVIEW:99`, and no option pretends otherwise. |
| Target stack | `LEDGER.md:2051` | "account-level Expert Advisor (not per-trade, not per-strategy)" | INHERITED. |
| Q3/F2 trade disallowed states | `LEDGER.md:2070` | "All trade-disallowed states (AutoTrading off, MQL_TRADE_ALLOWED false, ACCOUNT_TRADE_ALLOWED or ACCOUNT_TRADE_EXPERT false, investor login, symbol closed or close-only) are kill-equivalent: detect-only, continuous loud alerting (journal + Alert + chart banner), immediate sweep on restoration, each state enumerated and logged distinctly. The flatten promise is formally: within seconds of the platform accepting a close for that symbol." | INHERITED and implemented by every option; ENF-14 rules the alert cadence and ENF-15 rules how "close-only" is read, since a close-only symbol accepts closes (2.7.8). Neither option supersedes the clause; one reads its letter, the other its ground. |
| Q5/F16 pendings | `LEDGER.md:2078` | "Breach flatten and the locked sweep delete pending orders as well as positions." | INHERITED, implemented by every option. |
| Q6/F7 snapshot | `LEDGER.md:2082` | "the locked window is judged by the snapshot, never by live inputs" | INHERITED. The sweep reads no limit at all. |
| Q7/F5 clock | `LEDGER.md:2086` | "All expiry and anchor decisions use TimeCurrent exclusively. Never TimeTradeServer, never TimeLocal." | INHERITED. A backoff clock is neither an expiry nor an anchor decision; ENF-10 rules which clock it uses, and options (a) and (b) both stay outside Q7's domain (a pass counter, or TimeLocal in the A1/A3 class `LEDGER.md:2134`, the class the existing cadences at `EA:571`, `:738` and `:849` already occupy per `LEDGER.md:1401`). |
| Clock exemption A1/A3 | `LEDGER.md:2134-2137` | "Crash-loop session timestamps and the mutex heartbeat timestamp use the local clock ... Amendment A3 extends the same exemption to the proof-of-life interval and the seconds-in-state counter." | INHERITED. A backoff timer under ENF-10(b) is an executor reading of the same class, not a supersession; recorded as a reading, like `LEDGER.md:1401`. |
| Q1 locked_until | `LEDGER.md:2062` | "DAILY_BREACH locked_until = next day anchor." | INHERITED. ENF-22(b), holding the lock until flat, MUST SUPERSEDE this and the expiry only unlock (`EA:536-540`, `SPEC:102`); named there and nowhere else. |
| Q2/F1 base, the 2026-08-05 base ruling | `LEDGER.md:2066`, `:2233` | "Base = current balance minus the sum of ALL deals since the day anchor" and "never Equity and never cached" | INHERITED. A flatten converts floating to realized; the Q2 identity absorbs the closing deals and the base does not move. |
| Q8 dual limits, D1f, D6a, defaults | `LEDGER.md:2090`, `:2286`, `:2302`, `:2329` | mandatory list inputs, min of the two legs | INHERITED. The sweep reads no limit. |
| Q4/F9 config classes | `LEDGER.md:2074` | core malformed refuses init | INHERITED. ENF-25(b), new inputs for sweep constants, would add core inputs and their A9 vectors under this ruling; (a) adds none. |
| AG_LIFE_INTERVAL and AG_MUTEX_STALE as constants | `LEDGER.md:2139`, `:2143` | "a config value that can disable the fail-visible guarantee belongs to the core class or nowhere. Nowhere is simpler." | INHERITED, the precedent ENF-25 is ruled against; neither option supersedes a clause of either entry, which name their own constants only. |
| D7b sweep period constant | `LEDGER.md:2306` | "`SweepPeriodSeconds = 1` ... become compile-time constants" | INHERITED. The sweep runs at `AG_SWEEP_PERIOD_SECONDS` (`EA:45`), one pass per tick, and no option changes the period. |
| F11 double count, F12 whitelist | `LEDGER.md:2094`, `:2098` | carried position counts twice; realized is BUY and SELL deals only | INHERITED. The sweep's own closing deals are DEAL_TYPE_BUY or SELL and enter realized, which is what "burns the loss into server history" (`SPEC:105`). |
| F13 timer driven | `LEDGER.md:2102` | "Timer-driven architecture, EventSetTimer(1). OnTradeTransaction is acceleration only. OnTick unused." | INHERITED. The sweep runs from `OnTimer`; ENF-2 rules whether the accelerator is built, and under either option correctness never depends on it. |
| Q9 deferral | `LEDGER.md:2274` | one pass deferral | INHERITED, pre breach only. |
| Q10 DEGRADED and the reconnect amendment | `LEDGER.md:2282`, `:2278` | "no enforcement action is possible without a connection regardless of what the numbers say"; recovery gated on history stability | INHERITED. Every option sends nothing while `TERMINAL_CONNECTED` is false (3.7). ENF-20 rules whether the first post reconnect sweep waits on `AgHistoryStable`; the amendment's clause governs "breach evaluation", which the sweep is not, so neither option supersedes it. |
| Stale quote | `LEDGER.md:2003` | "must never suppress, delay, or gate a breach decision" | INHERITED. The sweep does not gate on quote age either; a send into a frozen but connected market returns a retcode and the retcode governs (2.7.6). |
| Ruling THREE, ruling FOUR, floor wins, clamp | `LEDGER.md:1963`, `:1967`, `:1959`, `:2175` | the `locked_until` bounds | INHERITED, untouched. |
| Question FIVE, total exposure | `LEDGER.md:1971` | "RE LOCKING EACH DAY ON A HELD LOSER IS INTENDED BEHAVIOUR" | INHERITED. After a sweep the held loser no longer exists except where the platform refused the close (market closed all night); the re lock at the next anchor then re arms the sweep, which is 3.6 and P89. |
| Question SIX, observability | `LEDGER.md:1975` | Stage 6 lines "may log, and it may never suppress, delay or gate a decision" | INHERITED. The sweep reads no Stage 6 global; ENF-S5 reruns the static row (`LEDGER.md:117` D2D4-S4 wording). |
| Question SEVEN, ratchet | `LEDGER.md:1979` | pre breach only | INHERITED, unread by the sweep. |
| AG_QUOTE_FROZEN_SECONDS | `LEDGER.md:1951` | 120 s, a constant | INHERITED. |
| Ruling C, helpers into Clock.mqh | `LEDGER.md:1955` | pure functions moved into an include so scripts can reach them | INHERITED as the precedent ENF-24 is ruled against. |
| Ruling ONE, deploy hand, and the 2026-09-06 script shape | `LEDGER.md:1983`, `:2341` | owner performs every copy; one script of `Copy-Item` and `Get-FileHash` lines, the owner runs it | INHERITED. ENF-27(a) needs the 2026-09-06 ruling extended to a new file name, exactly as D2D4-11(a) extended it (`LEDGER.md:2349`). |
| Deploy procedure 2026-09-07 | `LEDGER.md:2345` | attach and confirm a healthy init BEFORE any restart; no vector for the dialog rendering | INHERITED; ENF-D is its second exercise. |
| RULE A and RULE B | `LEDGER.md:2039` | the Terminal data folder is read only territory; plain inline cmdlets only | INHERITED. Live rows are owner performed; the executor harvests read only. |
| Session report is not evidence; citation rule | `LEDGER.md:2043`, `:1840` | artifacts only; file name and line number | INHERITED; every row in 3.10 closes on quoted lines. |
| Only the owner marks FINAL | `LEDGER.md:2130` | | INHERITED; section 4 is answered by the owner. |
| Merge gate | `LEDGER.md:2203` | a branch merges on its own proven work, owner instruction required | INHERITED. |
| Worktrees and branches kept | `LEDGER.md:2353` | never removed by any session; executor never merges, pushes or deletes | INHERITED. |
| Fix order 2026-08-19, shape A, the 1 plus 3 coupling | `LEDGER.md:1931`, `:1927` | four defects, all now CLOSED (`LEDGER.md:44`, `:50`, and `LEDGER.md:14-17`) | INHERITED. Expiry enters SYNCING (`EA:618`); a sweep is a behaviour of LOCKED and stops at that transition. |
| Reseed on reload | `LEDGER.md:1935` | | INHERITED, untouched. |
| Lock artifacts never deleted | `LEDGER.md:2110` | | INHERITED. No option adds or removes an artifact. |
| Never loaded never written | `LEDGER.md:2147` | | INHERITED. No option persists sweep state; a persisted hard stop was examined and closed in 3.3. |
| Amendments 2a/2b/2c, SAFE_HALT | `LEDGER.md:2122`, `:2126` | SAFE_HALT is not a lock; manual resume by deleting the halt file | INHERITED. `OnTimer` returns before the dispatch in SAFE_HALT (`EA:1189-1190`), so no option can sweep there; ENF-S3 proves it structurally. |
| Crash loop R1/R2, backward steps | `LEDGER.md:2155`, `:2159`, `:2212` | | INHERITED. ENF-L5's hard kill advances the chain as P3-2's did (`LEDGER.md:110`). |
| Login mismatch | `LEDGER.md:2179` | | INHERITED. |
| Q6 clarification, ratchet build | `LEDGER.md:2195`, `:2199` | | INHERITED, pre breach. |
| Refusal banner | `LEDGER.md:2208` | | INHERITED. |
| Vectors in the repository, sync direction | `LEDGER.md:2216` | | INHERITED. |
| SweepPeriodSeconds wording | `LEDGER.md:2220` | | INHERITED, closed by D7b. |
| Repository outside the data folder | `LEDGER.md:2224` | | INHERITED. |
| Remote state owner managed | `LEDGER.md:2229` | | INHERITED; this document makes no claim about the remote. |
| Naming discipline | `LEDGER.md:2106` | the bare word "heartbeat" is never used | INHERITED; every journal line proposed in 3.5 avoids it. |
| Epsilon | `LEDGER.md:2187` | | INHERITED, pre breach. |
| Proof of life A3 | `LEDGER.md:2171` | every state emits the line at a fixed interval | INHERITED. ENF-17(b) appends a field to the LOCKED line outside the D2D4 formatter and amends `SPEC:253`; (a) leaves the line alone. Neither supersedes A3. |
| D2D4 rulings, the LOCKED group | `LEDGER.md:2349` | six fields, pure formatter in `Log.mqh` | INHERITED. `AgLockedNumbersString` (`Log.mqh:113-123`) is untouched by every option; the vector `d2d4_locked_group_carries_only_the_six_ruled_fields` (`docs/vectors/README.md:62`) tests the formatter's output and is unaffected by a field the EA appends outside it under ENF-17(b). |
| D2D4-1(a), the GV state gate | `LEDGER.md:2349`, `EA:1159` | mirror written in ACTIVE and LOCKED only | INHERITED. |
| D10a, D11a, D8b of R10 | `LEDGER.md:2321`, `:2325`, `:2310` | hardening shipped first; constants; retired vectors | INHERITED. |
| SPEC amendment series closed at A6 | `LEDGER.md:2337` | "Future SPEC changes are recorded by the ruling that causes them, not by the series." | INHERITED; 3.12 writes no A7. |
| Hardening before COMPLETE | `LEDGER.md:1864` | "hardening of the limit inputs against runtime widening is a mandatory stage before COMPLETE" | INHERITED, discharged by R10. Nothing here reopens what COMPLETE requires. |
| VPS, R8 | `LEDGER.md:1858` | the real account runs on an always on VPS, deployment by git sync | INHERITED, out of this phase (3.9). |
| Public repository | `LEDGER.md:1855` | files from the terminal folder never enter git as is | INHERITED. |
| ISSUES holds open items only, R6 | `LEDGER.md:1852` | | INHERITED. |
| 2026-08-31 rulings ONE to FOUR | `LEDGER.md:1909` | ruling FOUR: the boot derived lock "is EXPLAINED AND ACCEPTED ... the guardian catches trades made while it was offline" | INHERITED. The 2026-08-30 boot is the second lock every option is worked against (3.0). |
| Max position size, UNRULED | `LEDGER.md:67-70` | "Formula and fraction are to be ruled at Phase 3 kickoff" | Not a FINAL. Out of this phase by the instruction (3.9); its consequence ONE is discharged by ENF-S2/ENF-S3 and its consequence TWO is what section 1.1 supersedes. |

Count: sixty rows listed, several bundling entries ruled together, two MUST BE SUPERSEDED by every option (the interim posture and the Phase 0 no trade call clause), one descriptive clause superseded in effect (the D8 cost clause), and two superseded by one named option each (the instrument scope by ENF-3(b); Q1 together with the expiry only unlock by ENF-22(b)). ENF-25(b) goes against a precedent and supersedes no clause; ENF-17(b) amends the SPEC and not a ruling.

---

## TASK 2, source map at `6a44dba`

### 2.1 The include graph and the static structure rule

The EA includes six files in this order: `Log.mqh`, `Clock.mqh`, `State.mqh`, `Persist.mqh`, `Pnl.mqh`, `Sweep.mqh` (`EA:11-16`). `Sweep.mqh` includes nothing (`Sweep.mqh:1-31`). `Persist.mqh` includes `Log.mqh`, `Clock.mqh`, `State.mqh` and `Pnl.mqh` (`Persist.mqh:19-25`). The vectors script includes `Persist.mqh` alone (`Vectors:34`) and states of itself "Makes no trade calls and opens no chart" (`Vectors:10`). So `Sweep.mqh` is reachable from the EA only, and a vector can reach nothing inside it unless the script gains an include, which is ENF-24. The static structure rule, `SPEC:34`: "the trade API (OrderSend and relatives) is reachable only from Sweep.mqh. Pnl.mqh, Clock.mqh, Log.mqh, State.mqh, Persist.mqh contain no trade calls."

### 2.2 Every point where a lock is declared or entered

`AgDeclareLock(breach_time, limit, base, pnl, realized, floating)` at `EA:421-455`, the ACTIVE path. It computes `until` (`EA:424-425`), sets `g_ag_lock_reason`, `g_ag_locked_until` and the Q6 input witness (`EA:427-431`), persists the snapshot (`EA:433-436`), prints `breach arithmetic` and `lock bounds` (`EA:438-444`), transitions with `AgTransition(AG_STATE_LOCKED, "DAILY_BREACH", ...)` (`EA:446-448`), and raises the ALERT whose text this phase retires, `EA:449-453`: `"DAILY_BREACH: account LOCKED until " ... ". Phase 2 locks the state machine and sends no order:" " open positions stay open until you close them by hand."`. Its single call site is `EA:887` inside the breach tail of `AgEvaluateActive`, followed by `return;` at `EA:888` "LOCKED from this pass on; nothing further is ACTIVE work". The transition happens on the ACTIVE tick; the first LOCKED tick is the next `OnTimer`.

`AgEnterLockFromBoot(reason, until, have_snapshot, derived_breach_time, derived_limit, derived_base)` at `EA:489-533`, the SYNCING exit path. It sets the two lock globals (`EA:493-494`), seeds the input witness (`EA:500-502`), persists per the three way branch (`EA:504-524`), transitions with `"boot derivation: " + AgLockReasonName(reason)` (`EA:526-527`) and raises the boot ALERT carrying the same "sends no order" sentence at `EA:528-531`. Its single call site is `EA:1220-1221`, reached when `AgBootDerivation` returns 1 (`EA:1218`). The CORRUPT_STATE reason arrives by the same function (`EA:504-508`).

`AgBootDerivation` at `EA:268-410` ORs three witnesses: FILE at `EA:289-298`, GV at `EA:302-313`, DERIVED at `EA:320-398`, and reads `AgFloating()` at `EA:376` for the live disjunct. It is called only from the SYNCING branch of `OnTimer` after `AgHistoryStable` returns true (`EA:1196`, `:1212-1213`).

The LOCKED dispatch is `EA:1235-1236`: `else if(g_ag_state == AG_STATE_LOCKED) AgEvaluateLocked();` with the comment "Phase 2 Stage 3: expiry only. Stage 4 adds witness reconciliation."

`AgEvaluateLocked` at `EA:563-626`: the Q6 input change WARN at `EA:568-584`, then the expiry test `if(now_server >= g_ag_locked_until)` at `EA:587`, which zeroes the lock (`EA:591-593`), resets the Q9 and stability counters (`EA:601-602`, `:616-617`) and transitions to SYNCING (`EA:618-620`). The header contract, `EA:536-540`: "EXPIRY IS THE ONLY UNLOCK PATH and the comparison is TimeCurrent >= locked_until ... Nothing else here may leave LOCKED: no input, no absence of evidence, no reconnect, no operator convenience."

`g_ag_state`, `g_ag_lock_reason`, `g_ag_locked_until` are `State.mqh:27-29`; `AgTransition` is the single choke point at `State.mqh:70-76`; the LOCKED `waiting_on` string is `State.mqh:101-102`, `"expiry: TimeCurrent >= locked_until"`.

### 2.3 `OnTimer`, the order of operations on every tick

`EA:1105-1259`, in order: `g_timer_ticks++` (`:1107`); the mutex refresh, "first, unconditionally, in every state" (`:1112-1113`); the quote freshness sample (`:1124-1129`); the GV mirror write under the state gate (`:1159-1163`); the connection sample `g_ag_obs_connected` (`:1175`); the LIFE line with `AgPnlNumbersString()`, which in LOCKED reads `ACCOUNT_BALANCE` and calls `AgFloating()` every tick (`:1177-1186`, `EA:181-189`); the banner (`:1187`); the SAFE_HALT early return, "closes nothing, sweeps nothing, no expiry" (`:1189-1190`); the per state dispatch (`:1194-1236`); the RESYNC edge lines (`:1248-1256`); and the last line of the function, the comment `// Phase 3 adds: sweep acceleration on OnTradeTransaction.` (`:1258`). `OnTradeTransaction` is a stub at `EA:1264-1269` with the comment `// Phase 3: trigger an immediate sweep pass while LOCKED.`; `OnTick` is empty by design (`EA:1274`). Everything the sweep does therefore happens after the LIFE line of the same tick and is reported by the LIFE line of the next, the same one tick lag the rest of the proof of life contract carries (`EA:686-689`).

### 2.4 `AgFloating`, the enumeration precedent

`Pnl.mqh:262-281`:

```
double AgFloating()
  {
   double sum = 0.0;
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
     {
      //--- PositionGetTicket(i) both returns the ticket AND selects that
      //--- position for the PositionGetDouble calls below (MQL5 semantics,
      //--- same pattern as HistoryDealGetTicket). PositionsTotal() can
      //--- shrink between this call and the loop's start if a position
      //--- closes mid-iteration, and PositionGetTicket then legitimately
      //--- returns 0 for the now-stale index; skipping it is correct, not
      //--- a bug to "fix" into a re-fetch or an index-shift correction.
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      sum += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
     }
   return sum;
  }
```

Three properties the sweep inherits from it: enumeration by index with selection as a side effect of `PositionGetTicket`; the ticket zero skip for a position that vanished mid loop, ruled correct on 2026-08-09 (`LEDGER.md:1671`); and the fact that this loop already runs every LOCKED tick from the LIFE builder (`EA:184`), so a sweep pass that enumerates positions adds a second loop of the same cost and not a new class of cost. There is no pending order enumeration anywhere in the tree: `OrdersTotal` and `OrderGetTicket` have zero occurrences (grep this session).

### 2.5 What the tree does not contain

Measured by grep over `MQL5/` this session, each zero hits in code: `OrderSend`, `OrderSendAsync`, `CTrade`, `PositionClose`, `OrderDelete`, `Trade.mqh`, `TRADE_ACTION_`, `OrdersTotal`, `OrderGetTicket`, `ACCOUNT_MARGIN_MODE`, `SymbolInfoSessionTrade`, `MQL_TRADE_ALLOWED`, `TERMINAL_TRADE_ALLOWED`, `ACCOUNT_TRADE_ALLOWED`, `ACCOUNT_TRADE_EXPERT`. The only textual hits are the `Sweep.mqh` header (`Sweep.mqh:7`, `:21-22`) and the two `OnTradeTransaction` lines (`EA:1258`, `:1264`). `SymbolInfoSessionQuote` is read once, for `_Symbol` only, in `AgQuoteSessionOpen` (`EA:644-661`), which is the pattern a per symbol trade session check would mirror with `SymbolInfoSessionTrade`.

### 2.6 The mutex heartbeat and the blocking hazard, measured

`AG_MUTEX_STALE_SECONDS` is 10 (`Persist.mqh:31`). `AgMutexAcquire` refuses while the heartbeat is younger than that and takes over when it is older: `if(age < AG_MUTEX_STALE_SECONDS) return false; // live instance holds it` then `AgWarn("stale mutex heartbeat (" ... "), taking over crashed-instance mutex")` (`Persist.mqh:1230-1232`). `AgMutexRefresh` writes `TimeLocal()` once per `OnTimer` (`Persist.mqh:1262-1275`, called at `EA:1112-1113`). The LIFE line is emitted from the same `OnTimer` at a 30 s cadence (`Log.mqh:66-87`).

MQL5 runs every handler of one program on one thread, so a synchronous trade call inside `OnTimer` delays the next timer event, the next heartbeat write and the next LIFE line by its own latency. The latency on this demo is on the record, `terminal-20260915-d2d4-restarts-and-kills.txt:39` `done in 2246.876 ms`, `:43` `1548.904 ms`, `:49` `3437.508 ms`, `:51` `2244.761 ms`, `:55` `3174.139 ms`, `:59` `3334.442 ms`, `:63` `78.573 ms`, `:70` `74.010 ms`, `:74` `2104.537 ms`. Taking 3.4 s as the worst measured value: a synchronous pass over the thirteen positions of 2026-08-18 (`LEDGER.md:1267`) would hold `OnTimer` for about 44 s, the heartbeat would read stale after the third position, and a second instance attaching inside that window would take the mutex from a guardian that is busy rather than dead, which is the exact false takeover the 2026-08-05 sleep entry describes (`LEDGER.md:80-81`). The LIFE lattice would show a gap above 31 s, which every harvest to date reads as a stall. This is why 3.8 exists as a design dimension the instruction did not list.

### 2.7 What the MQL5 trade API offers on a hedging account

EVERYTHING IN THIS SECTION IS DOCUMENTATION DERIVED AND NOT MEASURED. The standard library does not exist under the program folder (`C:\Program Files\MetaTrader 5\MQL5\Include\Trade\` returned no files this session), it lives under the Terminal data folder, which this session did not touch, and no trade call has ever run on this account from this project. Every numeric retcode below is a prediction that ENF-0's classifier vector prints and asserts at build time (P92), and every behavioural claim is a prediction a live row measures. Nothing here is evidence.

#### 2.7.1 Two ways in

Raw: fill an `MqlTradeRequest`, call `OrderSend(request, result)` and read `result.retcode`. The bool return says the terminal accepted the request for sending, not that the server executed it; a false return sets `GetLastError` (the trade errors of the 4752 to 4758 family, `ERR_TRADE_SEND_FAILED` among them) and `result.retcode` may still carry a server code. `OrderSendAsync(request, result)` returns at once with `result.retcode` `TRADE_RETCODE_PLACED` (10008) and `result.request_id`; the outcome arrives in `OnTradeTransaction` as `TRADE_TRANSACTION_REQUEST` carrying the same `request_id`, and as `TRADE_TRANSACTION_DEAL_ADD` when a deal lands.

`CTrade`, `#include <Trade\Trade.mqh>` from the standard library: `PositionClose(ulong ticket, ulong deviation)`, `PositionCloseBy(ulong ticket, ulong ticket_by)`, `PositionClosePartial(ulong ticket, double volume, ulong deviation)`, `OrderDelete(ulong ticket)`, `ResultRetcode()`, `ResultRetcodeDescription()`, `SetDeviationInPoints`, `SetTypeFillingBySymbol`, `SetExpertMagicNumber`, `SetAsyncMode`. `PositionClose` selects the position by ticket, builds the opposite `TRADE_ACTION_DEAL` with the `position` field set, and sends it. Its bool return is true for `TRADE_RETCODE_DONE`, `TRADE_RETCODE_DONE_PARTIAL` and `TRADE_RETCODE_PLACED` alike, so under `CTrade` a partial fill reads as success to a caller that trusts the bool; the retcode must be read either way.

#### 2.7.2 Closing a position on a hedging account

`request.action = TRADE_ACTION_DEAL`, `request.position = <ticket>`, `request.symbol = POSITION_SYMBOL`, `request.volume = POSITION_VOLUME`, `request.type = ORDER_TYPE_SELL` for a long and `ORDER_TYPE_BUY` for a short, `request.price` the current bid or ask, `request.deviation` in points, `request.type_filling` a mode the symbol allows (`SYMBOL_FILLING_MODE` is a flag set of `SYMBOL_FILLING_FOK` and `SYMBOL_FILLING_IOC`), `request.magic` and `request.comment` free. On a hedging account the `position` field is what makes the deal a close of that ticket rather than a new opposite position; without it the same request opens a hedge. `TRADE_ACTION_CLOSE_BY` with `request.position` and `request.position_by` closes two opposite positions on one symbol in a single deal at no spread, hedging accounts only and only where `SYMBOL_ORDER_MODE` carries the close by flag; the terminal journal's own close request form on 2026-09-15, `market sell 0.3 XAUUSD.ecn, close #701106385 buy 0.3 XAUUSD.ecn 4284.72` (`terminal-20260915-d2d4-restarts-and-kills.txt:44`), is the position bound close and not a close by.

Position identity: `POSITION_TICKET` is stable across a partial close on a hedging account and `POSITION_IDENTIFIER` equals it; a position closed by another route between enumeration and send returns `TRADE_RETCODE_POSITION_CLOSED` (10036), which is a success for the sweep's purpose and not a failure.

#### 2.7.3 Deleting a pending order

`request.action = TRADE_ACTION_REMOVE`, `request.order = <ticket>`. Enumeration is `OrdersTotal()` and `OrderGetTicket(i)`, which select the order for `OrderGetInteger(ORDER_TYPE)` and `ORDER_STATE`. Pending types are `ORDER_TYPE_BUY_LIMIT`, `SELL_LIMIT`, `BUY_STOP`, `SELL_STOP`, `BUY_STOP_LIMIT`, `SELL_STOP_LIMIT`; a market order in flight, the sweep's own close among them, appears briefly in the same list as `ORDER_TYPE_BUY` or `ORDER_TYPE_SELL` with state `ORDER_STATE_STARTED` or `ORDER_STATE_PLACED`, and a delete aimed at it returns `TRADE_RETCODE_INVALID_ORDER` (10035). A pending in `ORDER_STATE_REQUEST_CANCEL` or `ORDER_STATE_REQUEST_MODIFY` is already moving and a second remove returns `TRADE_RETCODE_ORDER_CHANGED` (10023) or `REJECT_CANCEL` (10041).

#### 2.7.4 Retcodes, three classes

Retry class, the condition is transient and the same request may succeed on a later pass: `TRADE_RETCODE_REQUOTE` 10004, `REJECT` 10006, `TIMEOUT` 10012, `PRICE_CHANGED` 10020, `PRICE_OFF` 10021, `TOO_MANY_REQUESTS` 10024, `LOCKED` 10028 (request processing locked), `FROZEN` 10029 (order or position frozen), `CONNECTION` 10031, `CLOSE_ORDER_EXIST` 10039 (a close order for this position is already in flight, wait), and `DONE_PARTIAL` 10010, which is a success on the filled part and a retry on the remainder.

Hold class, the condition will not change by retrying and the sweep re arms when it does: `TRADE_DISABLED` 10017, `MARKET_CLOSED` 10018, `SERVER_DISABLES_AT` 10026 (server side algo trading disabled), `CLIENT_DISABLES_AT` 10027 (the terminal's AutoTrading button or the EA's own permission), `ONLY_REAL` 10032, `LONG_ONLY` 10042, `SHORT_ONLY` 10043, `CLOSE_ONLY` 10044, `HEDGE_PROHIBITED` 10046. These are the Q3 states in retcode form and each maps onto a name the pre check in 2.7.8 already reports.

Refuse class, the request itself is wrong and resending it unchanged is an order storm: `INVALID` 10013, `INVALID_VOLUME` 10014, `INVALID_PRICE` 10015, `INVALID_STOPS` 10016, `INVALID_EXPIRATION` 10022, `ORDER_CHANGED` 10023, `NO_CHANGES` 10025, `INVALID_FILL` 10030, `LIMIT_ORDERS` 10033, `LIMIT_VOLUME` 10034, `INVALID_ORDER` 10035, `INVALID_CLOSE_VOLUME` 10038, `LIMIT_POSITIONS` 10040, `REJECT_CANCEL` 10041, `FIFO_CLOSE` 10045, `NO_MONEY` 10019 (should not arise on a close). `POSITION_CLOSED` 10036 and `DONE` 10009 are successes; `PLACED` 10008 is the asynchronous acknowledgement and is neither.

The classification is a pure function of an integer and is what ENF-0 can prove without an account: a vector that feeds each constant and asserts the class, plus one that asserts the numeric value of every constant the classifier names, so the documentation values above become measured on the compiler that builds the binary (P92).

#### 2.7.5 Requotes and execution mode

`TRADE_RETCODE_REQUOTE` arises under instant execution when the price moved beyond `deviation`; under market execution the server fills at its own price and `deviation` is ignored, so a requote is not expected. The one execution mode on record is US100.ecn "Execution Market" (`phase1-manual-trades-2026-08-11.md:197`); XAUUSD.ecn's was not transcribed and BTCUSD.ecn's was never read. A requote is retry class either way; the schedule in 3.3 bounds it.

#### 2.7.6 Market closed on the symbol

A close sent while the symbol's trade session is closed returns `TRADE_RETCODE_MARKET_CLOSED` 10018 and nothing the guardian does before the session opens can change that; it is F2's "within seconds of the platform accepting a close for that symbol". The sessions on record: XAUUSD.ecn trade Monday 01:01 to 23:58, Tuesday to Friday 01:00 to 23:58, no Saturday or Sunday session (`phase1-manual-trades-2026-08-11.md:180-181`); XAGUSD.ecn trade Monday 01:02 to 23:57, Tuesday to Friday 01:01 to 23:57 (`:190-192`); US100.ecn trade Monday to Friday 01:02 to 23:58 (`:202-203`). So for the three 24/5 symbols a close is impossible from 23:57 or 23:58 to the next 01:00 to 01:02 every night and from Friday 23:58 to Monday 01:01 or 01:02, and a breach declared inside the nightly break, which ruling THREE gives a full extra day (`LEDGER.md:1963`), leaves those positions unswept until the reopen. BTCUSD.ecn's sessions are unread; the 2026-09-01 FINAL treats it as trading through the weekend (`LEDGER.md:1905`). `SymbolInfoSessionTrade(symbol, day, index, from, to)` reports the same table the owner read, and `SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE)` reports `SYMBOL_TRADE_MODE_DISABLED`, `LONGONLY`, `SHORTONLY`, `CLOSEONLY` or `FULL`.

#### 2.7.7 What a partial close returns

Under fill or kill (`SYMBOL_FILLING_FOK`, the mode US100.ecn reports at `phase1-manual-trades-2026-08-11.md:197`) a close either fills whole with `DONE` or does not fill at all, so no partial state exists. Under immediate or cancel (`SYMBOL_FILLING_IOC`) the server may fill part of the volume and return `DONE_PARTIAL` 10010 with `result.volume` the filled part; on a hedging account the remainder stays open under the same ticket with a reduced `POSITION_VOLUME`, and the next enumeration finds it. Under `CTrade` the bool reads true in both cases (2.7.1). The consequence for the engine is one rule: a send result is never the evidence that a position is gone; only the next enumeration is (3.5).

#### 2.7.8 The trade disallowed states, Q3, and how each is read

`TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)`, the AutoTrading button; `MQLInfoInteger(MQL_TRADE_ALLOWED)`, the EA's own permission checkbox; `AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)`, broker side, also false on an investor password login; `AccountInfoInteger(ACCOUNT_TRADE_EXPERT)`, broker side algo permission; `SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE)` and `SymbolInfoSessionTrade` per symbol. The first four are account wide and one read per pass names the blocking state; the last two are per position. `SYMBOL_TRADE_MODE_CLOSEONLY` permits closes and forbids opens, so a flatten engine can proceed on such a symbol although Q3 lists "close-only" among the disallowed states; ENF-15 rules which reading governs. `LONGONLY` and `SHORTONLY` restrict the direction of new positions and their effect on a close of the opposite side is not documented unambiguously; the classifier treats 10042 and 10043 as hold class and ENF-L4's harvest may measure it for free. `common.ini` `[Experts] Account=1` is the same family (`SPEC:268`) and reads as `MQL_TRADE_ALLOWED` false after a login switch.

#### 2.7.9 `OnTradeTransaction`

Delivered per transaction with `MqlTradeTransaction.type`: `TRADE_TRANSACTION_DEAL_ADD` with `deal_entry == DEAL_ENTRY_IN` is a new position opened from any source, including the mobile app; `TRADE_TRANSACTION_ORDER_ADD` is a new order, pending or market; `TRADE_TRANSACTION_REQUEST` carries the result of an asynchronous send with its `request_id`. Delivery is not guaranteed (`SPEC:30`, `REVIEW:87`), the handler runs on the same single thread as `OnTimer`, and it fires for the guardian's own deals too, so an accelerated pass that does not filter on `DEAL_ENTRY_IN` would re enter the sweep once per close it just made. F13 fixes its role as acceleration only.

#### 2.7.10 The standard library and the worktree compile

Every compile since Stage 2 runs inside the worktree with `/include` rooted at the worktree's own `MQL5` tree, and the ledger records that under that switch "the log then names the worktree's own include paths" (`LEDGER.md:1429`). Whether the switch replaces or extends the standard include root is not on the record. If it replaces it, `#include <Trade\Trade.mqh>` fails to resolve in the worktree compile unless a copy of the standard library sits under the worktree, which puts MetaQuotes' files into this public repository; if it extends it, the compile binds to whatever `Trade.mqh` the terminal's data folder carries at build time, which a LiveUpdate can move (`LEDGER.md:141`, build 6180 to 6182 on 2026-09-07). A raw `OrderSend` engine needs no include at all. This is the measurable consequence ENF-5 carries, to be measured by the build session before the first compile and not assumed here.

---

## TASK 3, design space

### 3.0 The two locks every option is worked against

LOCK A, the 2026-09-15 ACTIVE breach, `docs/evidence/journal-20260915-d2d4-deploy-attach.txt:4574-4581`. `:4574` `WARN|breach deferred one pass: no new deal visible, count=7`; `:4575` `INFO|lock level|enforced_limit=126.21|peak=11.70|ratchet_level=-126.21|peak_level=-114.51|chosen=peak|pnl=-130.20|realized=5.40|floating=-135.60`; `:4576` `INFO|breach arithmetic|realized=5.40|floating=-135.60|base=2294.76|limit=126.21|pnl=-130.20`; `:4577` `INFO|lock bounds|breach_time=2026.09.15 18:36:17|quote_frozen=0|latch_floor=2026.09.16 01:00:00|locked_until=2026.09.16 01:00:00`; `:4578` `TRANSITION|ACTIVE->LOCKED|DAILY_BREACH|pnl=-130.20|limit=126.21|locked_until=2026.09.16 01:00:00`; `:4579` the ALERT; `:4581` the first LOCKED LIFE line, `balance=2127.06|floating=0.00|equity=2127.06`. The book at the breach: three separate 0.3 lot sells on XAUUSD.ecn, opened at `terminal-20260915-d2d4-restarts-and-kills.txt:52-63` (18:33:10, 18:33:18, 18:33:19) and still open at 18:36:17, since `:4575` carries `floating=-135.60`; closed by hand three seconds later at `:64-66` (18:36:20.154, 18:36:20.156, 18:36:20.228), which is why `:4581` already reads `floating=0.00`. No pending orders. Trade session open (18:36 on a Tuesday). Connected. Under this plan the hand closes at `:64-66` would not have been needed, and every option below is asked what it does between `:4578` and `:4581`.

LOCK B, the 2026-08-30 battery outage boot, `docs/evidence/journal-20260830-rollover-and-boot-breach.txt:3663-3670`. `:3663` `TRANSITION|BOOT->SYNCING|boot|weekly=on|timer=1s` at 15:45:56; `:3666` `INFO|boot witness DERIVED fired|live=1|replay=1|realized=-192.00|floating=0.00|running_min=-192.00|limit_cmp=127.14|tier=floor|bounded=2026.08.31 01:00:00` at 15:45:59; `:3667` `TRANSITION|SYNCING->LOCKED|boot derivation: DAILY_BREACH|locked_until=2026.08.31 01:00:00`; `:3668` the boot ALERT; `:3670` the first LOCKED LIFE line. The book at the derivation: `docs/evidence/terminal-20260830-zero-positions.txt:27` `terminal synchronized with Just Global Markets Ltd.: 0 positions, 0 orders` at 15:45:55.966, one second before the boot; the loss had been made and closed from the mobile app inside the 31 minute outage between `:19` `terminal stopped due to system shutdown` at 15:14:10 and `:20` `MetaTrader 5 x64 build 6140 started` at 15:45:54 (`LEDGER.md:185`). Ruling FOUR of 2026-08-31 accepts the catch (`LEDGER.md:1909`). Under this plan a sweep on this lock has nothing to close, and every option is asked what it emits when the book is already flat, and what it would do if a mobile position were opened at 16:00 while the lock ran.

### 3.1 (a) Trigger

**Option (a), flatten once at the breach only.** One pass, run from the tick that declared the lock or the tick after it, and nothing afterwards. LOCK A: three `sweep close` lines at 18:36:17 to 18:36:2<n>, then `sweep complete`, then the LOCKED LIFE line at `:4581` reads `floating=0.00` from the guardian's own closes. LOCK B: one `sweep complete|positions=0|pendings=0` at 15:45:59 and nothing else; a mobile position opened at 16:00 stays open until the owner closes it, and the LOCKED LIFE group shows its floating loss moving. Cost: `SPEC:8` "While locked, anything newly opened is flattened within seconds" is not met and the SPEC must be amended to say so; `SPEC:172` and `SPEC:173` become unreachable rows; a position the platform refused at the breach (market closed, AutoTrading off) is never retried, so "immediate sweep the moment trading is restored" (`SPEC:98`, Q3 FINAL `LEDGER.md:2070`) is not met either, which makes this option contradict Q3 as written. Risk: lowest order count, no per tick enumeration beyond the LIFE builder's, no retry logic at all.

**Option (b), flatten at the breach and on every LOCKED tick while any position or pending exists.** The `Sweep.mqh` contract as declared (`Sweep.mqh:25-28`) and `SPEC:97`. LOCK A as (a) on the first tick; on every later tick the pass enumerates, finds nothing, sends nothing and emits nothing. LOCK B: `sweep complete` on the first LOCKED tick; a mobile position opened at 16:00 is enumerated on the next tick and closed within one latency, about 0.1 to 3.4 s on the measured values (2.6). Cost: one enumeration of positions and pendings per tick while LOCKED, the same shape the LIFE builder already pays for positions (`EA:184`); a retry policy is mandatory, since a refused position is retried every tick otherwise (3.3); a position on a closed symbol gets an attempt per backoff interval all night unless the pre check holds it (ENF-13). Risk: an order storm is possible only through a defect in the backoff, which is why ENF-S rows and ENF-0 test the policy before any live row.

Named and not proposed as a third option: sweeping on the LOCKED tick only when `AgFloating()` is nonzero. A position at exactly zero floating is still a position and a pending order carries no floating at all, so the trigger would miss both; closed on those two counts.

### 3.2 (b) Scope

**Option (a), every position and pending on the account regardless of origin, symbol or magic.** `SPEC:8` "every symbol, magic, origin, including mobile and manual", `SPEC:126` "No symbol filter, no magic filter. Scope is everything on the account.", the 2026-09-01 FINAL "EVERYTHING IS LOCKED ... every symbol, every source, mobile included" (`LEDGER.md:1905`). LOCK A: all three XAUUSD.ecn positions, which happen to be on the chart symbol. LOCK B: the flat book; a BTCUSD.ecn position opened at 16:00 from the mobile app is in scope, as the four 2026-08-29 weekend BTCUSD.ecn deals (`LEDGER.md:183`) show the account does trade it. Cost: the engine must read four symbols' trade sessions, filling modes and trade modes at run time; BTCUSD.ecn's specification has never been read by a human (1.7); a symbol whose session is closed while another's is open needs per symbol holding (3.3).

**Option (b), the guardian's chart symbol only, `_Symbol`.** LOCK A: identical outcome, all three positions being on XAUUSD.ecn. LOCK B: a BTCUSD.ecn position opened at 16:00 stays open; a lock declared on a BTCUSD.ecn loss over a weekend sweeps nothing at all. Cost: MUST SUPERSEDE the 2026-09-01 FINAL's scope clause and `SPEC:8`, `SPEC:126`; the guardian becomes a per chart tool on an account that trades four symbols from the mobile app; every acceptance row with a second symbol becomes unreachable. What it buys: one session table, one filling mode, the one symbol whose specification has been read.

### 3.3 (c) Retry, backoff, hard stop, and the market closed case

Three quantities and one state, each ruled separately in section 4 because they are independent.

**Attempts.** Under trigger (b) an attempt is one send for one ticket on one pass. The retry class in 2.7.4 is bounded by a per ticket attempt counter; the hold class does not consume attempts, since nothing was tried against a condition that cannot change by trying; the refuse class stops that ticket at once, a resend of an invalid request being the storm `SPEC:144` forbids. Options for the bound: ENF-11 offers a hard count H, or no count and a rate cap only.

**Backoff.** Per ticket, between retry class attempts. ENF-9 offers a flat one attempt per tick (the tightest schedule `SPEC:97` permits, "no unbounded tight retry" being about the bound and not the interval), a doubling schedule 1, 2, 4, 8, 16, 32 s capped at 60 s, or a class based schedule where the retry class doubles and the hold class waits on the condition. ENF-10 rules the clock the schedule reads.

**The hard stop and the state at it.** When a ticket reaches H with the position still open, three states are available and only one of them is a state: (i) stay LOCKED, mark the ticket held, emit one ALERT naming it and repeat at the cadence, show a CANNOT_FLATTEN sub condition on the banner (the `SPEC:41` shape, "CANNOT_TRADE is a tracked and logged sub-condition inside LOCKED, not a state"), and re arm the ticket when its blocking condition changes or at a slow cadence; (ii) stay LOCKED and stop for good for that ticket until a manual act, which contradicts "immediate sweep the moment trading is restored" (`SPEC:98`); (iii) SAFE_HALT, which contradicts SAFE_HALT's own meaning, "guardian code presumed broken ... closes nothing" (`SPEC:56`), makes resume a manual file deletion (`LEDGER.md:2126`), and would hand a stuck close to a state that by ruling sweeps nothing. (iii) is examined and closed here on those three clauses and does not appear in the ruling sheet. A persisted hard stop, so a restart does not reset the counter, was examined and closed too: it would be a new artifact carrying lock adjacent state under never loaded never written (`LEDGER.md:2147`) and lock artifacts never deleted (`LEDGER.md:2110`), for a counter a restart legitimately resets, since a restart re enumerates the book from the server.

**Market closed on the symbol, the named case.** LOCK A's three positions were on an open session; the case arises when a breach lands between 23:58 and 01:00 on a metals or index position, or over a weekend, or when a BTCUSD.ecn loss breaches while a XAUUSD.ecn position is held past 23:58. Under ENF-13(a) the pass reads `SymbolInfoSessionTrade` and `SYMBOL_TRADE_MODE` before sending and holds the ticket with one `sweep held` line per cadence naming the symbol and the next session open, no send at all, re arming at the open; under ENF-13(b) the pass sends and the 10018 classifies into the hold class, one line per attempt at the backoff cadence, the platform being the authority on its own session table; under (c) both, the pre check for the name and the retcode for the truth. Under any of the three the position carries its floating loss until the reopen, the lock expires at 01:00 (Q1) with the position still open if the session opens at 01:01 or 01:02 (2.7.6), the guardian enters SYNCING then ACTIVE, the carried loss counts against the new day under question FIVE, and if it still breaches the new day's limit the account re locks on the first ACTIVE pass and the sweep fires when the session opens seconds later. That chain is 3.6's boot case in miniature and is P89.

### 3.4 (d) Ordering

**Pendings before positions.** The transition table's own order, "delete pendings, begin sweep" (`SPEC:50`), and F16's reason, "else a resting stop fills straight into a flatten with spread and commission churn" (`REVIEW:99`): a pending that fills while positions are being closed becomes a new position the pass has not enumerated, which the next pass then closes at a second spread. Cost: none beyond the order of two loops.

**Positions before pendings.** The review skeleton's wording, "Positions first, pendings per Q5" (`REVIEW:153`). Buys the earliest possible stop to floating loss by one loop's duration; risks the fill F16 names. The two documents disagree and ENF-7 settles it.

**Among positions.** Three deterministic orders: by floating loss, most negative first, which stops the largest bleed first and needs `POSITION_PROFIT` read during enumeration, already read by `AgFloating`; by ticket ascending, oldest first, which needs nothing and reproduces the terminal's own list order; by volume descending. LOCK A's three positions differ by cents, so the order is invisible there; the 2026-08-18 thirteen would have been closed in one order or another over 44 s under a synchronous engine (2.6), and the order decides which loss kept moving longest.

**Close by pairing.** On a hedging account two opposite positions on one symbol can close each other in one `TRADE_ACTION_CLOSE_BY` deal at no spread (2.7.2). Option (a) never uses it, every position getting its own close; option (b) pairs opposite positions on the same symbol first when `SYMBOL_ORDER_MODE` allows it, then closes the rest. (b) saves one spread per pair and adds a second request type, a second retcode surface (`HEDGE_PROHIBITED`, `INVALID_ORDER` for an unpaired volume) and a matching step. Neither lock on record had opposite positions.

### 3.5 (e) Verification, journal, ALERT and event lines

**What counts as flat.** `PositionsTotal() == 0` and the count of pending type orders in `OrdersTotal()` is 0, both read on a pass that sent nothing, since a send result is not evidence a position is gone (2.7.7). ENF-16 offers one such pass or two consecutive passes, the second guarding the tick in which a filled close has not yet left the position list.

**Journal lines**, each a proposal for the owner's wording and each avoiding the banned bare word (`LEDGER.md:2106`):

- `sweep pass|positions=<n>|pendings=<m>|held=<h>|sent=<s>` once per pass that sent anything, and once when the book first reads flat.
- `sweep delete|order=<t>|symbol=<s>|type=<pending type>|retcode=<r>|class=<retry|hold|refuse|done>|attempt=<k>` one per attempt (`SPEC:132`).
- `sweep close|position=<t>|symbol=<s>|type=<buy|sell>|volume=<v>|floating=<f>|retcode=<r>|class=<...>|attempt=<k>|filled=<v'>` one per attempt.
- `sweep held|position=<t>|symbol=<s>|reason=<Q3 name or session closed>|next_open=<t>|since=<t>` one per cadence per held ticket.
- `sweep blocked|state=<Q3 name>` one per cadence while an account wide state blocks every send, the CANNOT_TRADE sub condition (`SPEC:41`).
- `sweep complete|positions=0|pendings=0|attempts=<n>|elapsed=<s>` once per lock, and again after each later resweep episode that started from a non flat book.
- `sweep resumed|gap=<disconnect stamp>..<reconnect stamp>` the coverage gap line (`SPEC:99`).

**ALERT lines** (`SPEC:133`): the existing lock ALERT at `EA:449-453` and boot ALERT at `EA:528-531` lose the "sends no order" sentence, ENF-18 rules the replacement text; a cannot trade while locked ALERT at the cadence ENF-14 rules; a `sweep complete` ALERT is offered as an option and not assumed, the LOCKED state already having its popup. `AgAlertEvent` (`Log.mqh:43-47`) is the only route and every ALERT is a journal line too.

**The LIFE line.** ENF-17 rules whether the LOCKED LIFE line gains a `sweep=<open>/<held>` field appended by the EA builder outside the D2D4 formatter (`EA:186-188`); the six ruled fields are untouched under both options.

**Magic and comment.** ENF-19 rules whether the guardian's own requests carry a constant magic and a comment so the terminal journal and `DEAL_MAGIC` attribute the closes to the guardian; today the thirteen deals of 2026-08-18 "carry no expert attribution in the terminal journal" (`LEDGER.md:1267`), which is how the ledger proved the guardian sent nothing, and the same field is how a future harvest proves it did.

### 3.6 (f) Boot path, a boot derived lock with positions open at boot

Neither lock on record had positions open at a boot derivation: LOCK B's book was flat (`terminal-20260830-zero-positions.txt:27`), and the 2026-08-18 relaunches followed the 13:38:07 liquidation (`LEDGER.md:1267`, `:1273`). The case is produced on demand by ENF-L5 (3.10): AutoTrading off holds positions through a lock, a hard kill, and a relaunch.

Ruled at ENF-21. **Option (a), the sweep starts at the SYNCING exit.** `AgEnterLockFromBoot` transitions to LOCKED (`EA:526`) on the tick `AgHistoryStable` first returns true, the third tick at the earliest (`Pnl.mqh:426-449`, `EA:1196`), and the first sweep pass runs on the LOCKED dispatch of the next tick. Positions open at boot stay open for those three to four seconds. Consistent with `SPEC:144` "no flatten from a half-loaded history (SYNCING)" read broadly and with the state machine as built, where LOCKED is the only state whose dispatch may sweep (`Sweep.mqh:26`).

**Option (b), the sweep also runs in SYNCING when the FILE or GV witness read at init is unexpired.** `AgStateLoad` runs in `OnInit` (`EA:991`) and the GV is read there too (`EA:1012-1013`); both are reported and deliberately not acted on (`EA:987-990`, `:1007-1008`). Under (b) a SYNCING tick whose loaded file carries `locked_until > now`, or whose GV does, runs a sweep pass before stability, which is F6's own text, "In SYNCING the guardian enforces any persisted or GV lock (sweeping allowed) but makes no unlock decision and no new-breach decision" (`REVIEW:51`). The DERIVED witness never qualifies, since it needs the replay. Cost: a sweep call outside the LOCKED dispatch, which ENF-S3 must then permit by name; three seconds sooner; a forged or stale witness is bounded by the same clamp the derivation applies (`Clock.mqh:174-181`) and an expired one reads as not locked (`EA:289`), so the risk (b) adds is a sweep on a witness the derivation would have declined only when the derivation finds the account NOT breached, which the OR structure makes impossible for FILE and GV since neither can be overruled by DERIVED (`EA:239-243`, "The OR can only ADD a lock, never subtract one").

SAFE_HALT with a persisted lock sweeps nothing under both options (`SPEC:56`, `EA:1189-1190`).

### 3.7 (g) SYNCING and DEGRADED, and reconnect while LOCKED with positions open

**Never send from a disconnected pass.** Q10's ground, "no enforcement action is possible without a connection regardless of what the numbers say" (`LEDGER.md:2282`). The sweep pass reads `TerminalInfoInteger(TERMINAL_CONNECTED)` fresh, the read `AgEvaluateActive` makes at `EA:694` and `AgHistoryStable` at `Pnl.mqh:428`, and returns before enumerating when false; it does not read `g_ag_obs_connected`, which is a Stage 6 logging global no decision path may read (`EA:114-121`) and which ENF-S5 greps for. The LOCKED LIFE line already carries `DEGRADED|` on the group and `DEGRADED: disconnected` in `waiting_on` while disconnected (`EA:185`, `EA:1182-1183`, `LEDGER.md:1281`), so the sweep adds no marker of its own; a `sweep held|reason=disconnected` line per cadence is offered under ENF-17 and not assumed.

**A pass that cannot evaluate.** The sweep evaluates nothing from history and needs no `HistorySelect`; the platform position list is the terminal's own synchronized copy (`terminal-20260915-d2d4-restarts-and-kills.txt:30` "terminal synchronized ... 0 positions, 0 orders" precedes `:31` "trading has been enabled" on every authorization), so the SYNCING "not evaluable" return of `AgBootDerivation` (`EA:324-336`) has no sweep analogue.

**Reconnect while LOCKED with positions open.** LOCKED has no RESYNC gate: `g_ag_resyncing` is set only inside `AgEvaluateActive` (`EA:697`), the 2026-08-18 P2-C run held LOCKED through a six minute disconnect with zero transitions (`LEDGER.md:1281`, `:1287`), and the gap the ledger derived from that, "a disconnect that begins AND ends inside a locked window arms no resync gate at all" (`LEDGER.md:1289`), was closed for expiry by shape A and is untouched for the sweep. ENF-20 offers: (a) the sweep resumes on the first connected tick, with the `sweep resumed|gap=...` line, which is `SPEC:99`'s "then immediate sweep, and the coverage gap logged with timestamps" read against the machine as built, where no SYNCING re entry exists on reconnect; (b) the first post reconnect pass waits on `AgHistoryStable(AG_HISTORY_STABLE_POLLS)`, the RESYNC discipline, at the cost of three seconds and of a stability poll whose subject, deal history, the sweep does not read. The mobile position opened while offline, the 2026-08-30 shape, is closed under both on reconnect, three seconds apart.

### 3.8 The send mode, synchronous or asynchronous

Raised by 2.6 and not listed in the instruction. **Option (a), synchronous `OrderSend`, every due ticket on every pass.** Simplest engine; the pass blocks for the sum of latencies; on the measured 3.4 s worst case a book of four positions holds `OnTimer` past the 10 s mutex staleness (`Persist.mqh:31`), a book of nine past the 30 s LIFE cadence, and a second instance attaching during the pass takes the mutex from a live guardian. LOCK A's three positions: about 7 to 10 s inside one tick, no heartbeat write in that window, the LIFE line of 18:36:28 delayed. **Option (b), `OrderSendAsync`, results through `OnTradeTransaction`.** The pass returns in milliseconds; each ticket carries an in flight flag with its `request_id`, cleared on the `TRADE_TRANSACTION_REQUEST` that answers it or on the next enumeration that no longer finds the position; a ticket with a request in flight is not resent, which also covers `CLOSE_ORDER_EXIST` (10039). Cost: correctness now depends on `OnTradeTransaction` delivery for the in flight flag's clearing, which F13 forbids for the sweep itself (`LEDGER.md:2102` "OnTradeTransaction is acceleration only"); the enumeration on the next pass is what actually clears the flag when delivery fails, so the dependence is on latency and not on correctness, and the build entry must argue that in terms. **Option (c), synchronous, at most K sends per pass.** K equals 1 bounds one pass to one latency, 3.4 s measured, under the 10 s staleness with margin; a book of N positions takes N passes, LOCK A's three positions three ticks, the thirteen of 2026-08-18 thirteen ticks or about 13 to 44 s, each pass returning to `OnTimer` in time for the heartbeat. Cost: the slowest full flatten of the three by wall clock on a large book, the only engine of the three with no in flight tracking at all, and the LIFE line still shifts by up to one latency per tick.

### 3.9 (h) What stays out of this phase

By the instruction and by the record, each with the entry that keeps it open: the pre trade gate and maximum position size, UNRULED Phase 3 input at `LEDGER.md:67-70`, whose formula and fraction "are to be ruled at Phase 3 kickoff" and are not ruled here; alerts delivery beyond `Alert()`, the network heartbeat and the dead man drill of the deferred visibility phase (`SPEC:10`, `LEDGER.md:2114`, `:93-95`); VPS hosting, R8 (`LEDGER.md:1858`) and the zero enforcement window while the terminal is down (`LEDGER.md:32-34`); weekly reporting, Phase 4 (`SPEC:177-179`); the `common.ini` `Account=1` production posture, "a later ruling" (`SPEC:268`); the REFUSED banner's survival across an unload, DEFERRED 2026-09-07 (`LEDGER.md:2345`); the `market closed` observability branch, OPEN at `LEDGER.md:62-65` and unchanged by a sweep that reads `SymbolInfoSessionTrade` rather than the quote session; P2-A and P2-H, OPEN rows that a lock produced for ENF-L1 may supply for free and that only the owner declares (`LEDGER.md:52-60`); the Definition of Done's own remaining items after every phase matrix is green, "Controlled breach drill on demo ... Bypass drills ... One-week demo soak with daily reconciliation" (`SPEC:183-186`), which are what stands between this phase and COMPLETE and are not this plan's rows.

### 3.10 Acceptance rows

Evidence standard for every row, unchanged from `D2D4PLAN:372`: artifact file name and line number, banked as a transcoded `.txt` under `docs/evidence/`, owner copies out, executor reads the copy only, an owner dialog, banner or Trade tab reading is eyewitness fact for what was displayed, a session report counts for nothing. Build identity for every live row, standing rule 7: the md5 of every source file against the committed tip, the ex5 mtime, and the `init|build=<label>` journal line (ENF-26).

Static rows, worktree only. ENF-S2 and ENF-S3 together replace D2D4-S2, per `LEDGER.md:68`.

| Row | Procedure | Expected | Evidence |
|---|---|---|---|
| ENF-S1 compile | `metaeditor64.exe /compile:<wt>\MQL5\Experts\AccountGuardian\AccountGuardian.mq5 /include:<wt>\MQL5 /log:<jobtmp>\metaeditor.log`, and both vector scripts | `Result: 0 errors, 0 warnings` three times; every `including` line under the worktree, and under ENF-5(b) the one standard library line named and its origin recorded | log lines quoted; exit code ignored, standing rule 6 |
| ENF-S2 trade API confined | grep `OrderSend`, `OrderSendAsync`, `CTrade`, `PositionClose`, `OrderDelete`, `Trade.mqh`, `TRADE_ACTION_` over `MQL5/` | every hit in `MQL5/Include/AccountGuardian/Sweep.mqh`; ZERO hits in the EA, the other five includes and both scripts, except the `#include` line the vectors script gains under ENF-24(a), named | grep output quoted with counts per file |
| ENF-S3 no sweep reachable outside LOCKED | enumerate every call site of `AgSweepPass` and of any trade sending helper | exactly one call site in the LOCKED dispatch (`EA:1235-1236` region), plus the `OnTradeTransaction` site under ENF-2(a) gated on `g_ag_state == AG_STATE_LOCKED`, plus the SYNCING site under ENF-21(b); ZERO inside `AgEvaluateActive`, `AgBootDerivation`, `AgDeclareLock`, `AgEnterLockFromBoot`, `AgEnterSafeHalt`, `OnInit`, `OnDeinit`; every site below the SAFE_HALT return at `EA:1189-1190` or guarded by state | call sites quoted by line |
| ENF-S4 scoped diff | `git diff 6a44dba HEAD -- MQL5/` | `AgEvaluateActive` byte identical at md5 `1F5EB03BB1992B5ACBD2E502E060D9BD` (`LEDGER.md:117`) and its breach tail at `A3176C1C0E9F2D03586EAD6CBB175AA3`; `AgBootDerivation` at `53A720E00434A149E0105003FCE229E8`; `AgEvaluateLocked` at `91CC9E9F668DAE2420117FE34FF2DA68` unless ENF-22(b); `Clock.mqh`, `Pnl.mqh`, `Persist.mqh`, `State.mqh` identical by md5; `Log.mqh` touched only under ENF-24 for a formatter | hashes quoted |
| ENF-S5 Stage 6 static row rerun | enumerate every reference to `g_ag_obs_connected` and `g_ag_obs_resync_prev` | ZERO inside `Sweep.mqh` and inside every function ENF-S3 names (`LEDGER.md:117` D2D4-S4 wording) | grep output by line range |
| ENF-S6 clock discipline | grep `TimeLocal`, `TimeGMT`, `TimeTradeServer` over the added lines | ZERO `TimeGMT` and `TimeTradeServer`; `TimeLocal` only in cadence and backoff sites under ENF-10(b), each named; ZERO under ENF-10(a) | grep output quoted |
| ENF-S7 the retired sentence | grep `sends no order` and `no trading calls` over `MQL5/`, `README.md`, `docs/SPEC_v0.1.md` | ZERO in the EA's ALERT strings and `#property description` (`EA:9`); README and SPEC per ENF-28 | grep output quoted |

Deploy row, owner performs every copy, the second exercise of the 2026-09-07 procedure (`LEDGER.md:2345`):

| Row | Procedure | Expected | Evidence |
|---|---|---|---|
| ENF-D deploy | RULE B alias audit first. Executor records worktree md5 and size of `AccountGuardian.ex5` and, if the vectors changed, `AgPhase2StateVectors.ex5`. Owner copies per ENF-27. Executor `Get-FileHash` on each landed file. THEN, BEFORE ANY RESTART: owner removes and re attaches the EA on the running chart with `a9_defaults.set`, reads the dialog, clicks OK, and the executor reads the `limits accepted` line of that init. Only then the terminal restart. | every landed md5 equals the worktree md5; the pre restart init reads `INFO\|init\|build=<label>\|account=1200252169\|server=JustMarkets-Demo3` and `INFO\|limits accepted\|percent=5.50\|currency=200.00\|raw=550/200\|both list members (D1f), effective limit is the min of the two legs` with no ALERT; the post restart boot reads `BOOT->SYNCING` then `SYNCING->ACTIVE\|history stable\|polls=3/3`; ZERO sweep lines on a flat unlocked account | hashes quoted; both inits quoted with file and line; owner dialog reading |

Synthetic row, what a script proves without an account:

| Row | Procedure | Expected | Evidence |
|---|---|---|---|
| ENF-0 synthetic run | owner runs `AgPhase2StateVectors` after the restart | `AGVEC\|SUMMARY\|<n>/<n>`, `<n>` = 100 under ENF-24(c) or 100 plus the added checks under (a) or (b): the retcode classifier on every named constant and the numeric value of each (P92); the backoff schedule as a pure function of attempt count; the ordering comparator on three synthetic positions; the flat predicate on counts; the Q3 name mapping from a flag set; the `sweep close` and `sweep held` formatters on fixed arguments; and the five `d2d4_*` checks still PASS | journal lines quoted; ZERO `AGVEC` lines carrying FAIL |

What only a live row can prove: a close accepted by the server and the retcode it returns; a partial fill; 10018 on a closed session; a mobile position closed while locked; AutoTrading off holding the sweep and releasing it; the boot with positions open; the disconnect gap. Live rows:

| Row | Precondition and how the lock is produced on the demo | Expected journal lines | Evidence |
|---|---|---|---|
| ENF-L1 breach flatten | ACTIVE, session open, connected. Owner opens at least two positions on at least two symbols (the 2026-09-15 shape, 0.3 lot XAUUSD.ecn sells, plus one position on XAGUSD.ecn or US100.ecn) and places at least one pending order, and lets the loss clear the enforced limit, as on 2026-09-15 where 0.3 lot positions cleared 126.21 within three minutes (`journal-20260915-d2d4-deploy-attach.txt:4560-4578`). Nothing touched between the first open and the LOCKED LIFE lines, the P2-A discipline (`LEDGER.md:53`). | `TRANSITION\|ACTIVE->LOCKED\|DAILY_BREACH\|...`; on the next tick `sweep delete` for every pending with `retcode=10009`, then `sweep close` for every position in the ENF-7 order with `retcode=10009`, then `sweep complete\|positions=0\|pendings=0`; the first LOCKED LIFE line after it reads `floating=0.00`; the terminal journal's closing deals carry the guardian's magic under ENF-19(a); ZERO owner close requests in the terminal journal inside the window | journal and terminal lines quoted; counts over the window; owner Trade tab reading of zero positions at a stamped instant |
| ENF-L2 mobile position while locked | LOCKED from ENF-L1, connected, session open. Owner opens one position from the mobile app. | one `sweep close\|...\|retcode=10009` within 1 s of the position's deal, plus under ENF-2(a) one `sweep accelerated\|...` line before it; the LOCKED LIFE `floating` field never carries the position on two consecutive lines | lines quoted with the terminal journal's deal stamp beside the close stamp |
| ENF-L3 AutoTrading off while locked | LOCKED, connected. Owner turns the AutoTrading button off, opens one position from the mobile app, waits at least two cadences, turns AutoTrading on. | `sweep blocked\|state=TERMINAL_TRADE_ALLOWED=false` at the cadence and the ALERT at the ENF-14 cadence while off; ZERO `sweep close` lines while off; one `sweep close\|...\|retcode=10009` within 1 s of the button; no `init`, `deinit` or `TRANSITION` lines anywhere in the window | lines quoted; counts over the window; owner reading of the button state at two stamped instants |
| ENF-L4 market closed on the symbol | Night or weekend. Owner holds one small XAUUSD.ecn position open past 23:58 and, after the metals session closes, produces the breach on BTCUSD.ecn, whose session is open, from the mobile app. | `sweep close` for the BTCUSD.ecn position with `retcode=10009`; for the XAUUSD.ecn position, under ENF-13(a) `sweep held\|...\|reason=session closed\|next_open=<t>` at the cadence and ZERO sends, under (b) `sweep close\|...\|retcode=10018` at the backoff cadence; ZERO lines closer than the backoff interval for one ticket; at the reopen one `sweep close\|...\|retcode=10009` or, if the lock expired first, the P89 chain | lines quoted; the count of sends per ticket over the closed window against the schedule |
| ENF-L5 boot with positions open | LOCKED, AutoTrading off holding at least one position (ENF-L3's setup). Owner runs `taskkill /F /IM terminal64.exe`, waits more than 15 s (`LEDGER.md:1743`), relaunches, turns AutoTrading on after the boot. | `BOOT->SYNCING`, the three witness lines, `SYNCING->LOCKED`; under ENF-21(a) the first `sweep` line follows `SYNCING->LOCKED`, under (b) a `sweep blocked` line precedes it; after the button, one `sweep close\|...\|retcode=10009` per position; `stale mutex heartbeat` WARN on the boot proving the kill was hard (`LEDGER.md:110`) | lines quoted; halt file record for the unclean session |
| ENF-L6 disconnect while locked | LOCKED, flat, connected. Owner disables the network adapter, opens one position from the mobile app on a separate network, waits at least two cadences, re enables the adapter. | LOCKED LIFE lines carrying `DEGRADED\|` and ZERO `sweep close` lines while disconnected; on reconnect `sweep resumed\|gap=<t1>..<t2>` under ENF-20(a) then one `sweep close\|...\|retcode=10009` within 1 s, or after `polls=3/3` under (b) | lines quoted; the terminal journal's `connection ... lost` and `authorized` stamps beside the guardian's |
| ENF-L7 expiry with a held position | The ENF-L4 lock reaching 01:00 with the XAUUSD.ecn position still held. | `lock expired` and `LOCKED->SYNCING` at 01:00 with ZERO sweep lines after them until a new lock; `SYNCING->ACTIVE`; if the carried loss still breaches, `ACTIVE->LOCKED` on the first ACTIVE pass and `sweep close\|...\|retcode=10009` at the session open, P89; if not, the position stays open under ACTIVE with its floating loss on the ACTIVE LIFE line | lines quoted in order |

How many live locks. ENF-L1, L2, L3, L5 and L6 can all run inside one daytime locked window in that order, each row starting from the state the previous one left, since every one of them leaves the account LOCKED and flat or LOCKED with a held position that the next row consumes; ENF-L4 and L7 need a lock produced after a metals session close and carried to 01:00, a second lock on a different day. So the minimum is TWO genuine locks, and ENF-29 offers that or one lock per row, seven. A lock with no losing trade available is not produced on demand: every lock to date came from 0.3 to 0.5 lot XAUUSD.ecn positions and adverse movement inside minutes (`LEDGER.md:108`, `:1255`, `:173`), and the P2-A procedure's sizing note stands, "0.01 lot is roughly one account unit per one unit of price" (`docs/PROCEDURE_P2A_OBSERVATION_2026-08-19.md:91-93`). Each live lock also supplies the P2-A row's own criteria for free (`LEDGER.md:54`), which only the owner declares.

### 3.11 Predictions, P76 onward

**P76.** TRIGGER (a) OR (b), LOCK A shape. Within one timer tick of `TRANSITION|ACTIVE->LOCKED|DAILY_BREACH|...`, N `sweep close` lines, one per open position, each carrying `retcode=10009` and a `position=` equal to a ticket the terminal journal opened, then `sweep complete|positions=0|pendings=0`; the first LOCKED LIFE line after them carries `floating=0.00`; the terminal journal carries N closing deals inside the same second or seconds and ZERO `market sell ... close #` request lines from the owner in the window.

**P77.** TRIGGER (a) OR (b), LOCK B shape. On the first LOCKED tick after `SYNCING->LOCKED|boot derivation: DAILY_BREACH|...`, ZERO `sweep close` and ZERO `sweep delete` lines and exactly ONE `sweep complete|positions=0|pendings=0|attempts=0`, counted over the boot.

**P78.** TRIGGER (b). A position opened from the mobile app while LOCKED produces exactly ONE `sweep close|...|retcode=10009` whose stamp is within 1 s plus one latency of the terminal journal's `deal #<n> ... done` line for the open; under trigger (a) ZERO such lines and the LOCKED LIFE `floating` field carries the position on every line until the owner closes it.

**P79.** ACCELERATOR (a). Every `sweep close` that answers a mobile open is preceded, inside the same second, by ONE `sweep accelerated|transaction=DEAL_ADD|deal=<n>` line; under (b) ZERO such lines exist anywhere.

**P80.** SCOPE (a). A position on a symbol other than the chart symbol produces a `sweep close` line naming that symbol; under (b) ZERO `sweep close` lines name any symbol but `XAUUSD.ecn`.

**P81.** SEND MODE (a). With N open positions and the measured 2.2 to 3.4 s latency, the LIFE line following the sweep tick is late by about N times the latency, and for N at or above 4 the mutex heartbeat is not written for more than 10 s; under (b) and (c) ZERO LIFE gaps above 31 s over the window.

**P82.** ORDERING (a). On a book with at least one pending and at least one position, every `sweep delete` line precedes every `sweep close` line inside the first pass; under (c) the reverse.

**P83.** RETRY. For one ticket in the retry class, the stamps of consecutive `sweep close` lines carrying that ticket follow the ENF-9 schedule, and their count never exceeds H under ENF-11(a); ZERO `sweep close` lines for a ticket whose last line carried `class=refuse`.

**P84.** MARKET CLOSED, ENF-13(a). While the trade session is closed, ZERO `sweep close` lines for that symbol and one `sweep held|...|reason=session closed|next_open=<t>` per cadence, `<t>` equal to the next `from` the owner's session table carries; under (b) `sweep close|...|retcode=10018` lines at the backoff cadence and no `sweep held` lines; at the session open, one `sweep close|...|retcode=10009` within 1 s plus one latency of the `from` instant.

**P85.** Q3 STATES. With AutoTrading off while LOCKED and a position open, `sweep blocked|state=TERMINAL_TRADE_ALLOWED=false` at the cadence, an ALERT at the ENF-14 cadence, and ZERO `sweep close` lines, all counted over the window; within 1 s plus one latency of the button being turned on, one `sweep close|...|retcode=10009` per position.

**P86.** DEGRADED. While the LOCKED LIFE line carries `DEGRADED|`, ZERO `sweep close` and ZERO `sweep delete` lines; the first `sweep` line after reconnect is `sweep resumed|gap=<t1>..<t2>` with `<t1>` and `<t2>` inside one second of the terminal journal's `connection ... lost` and `authorized` stamps.

**P87.** BOOT WITH POSITIONS OPEN, ENF-21(a). The first `sweep` line of the session follows `TRANSITION|SYNCING->LOCKED` and precedes the first LOCKED LIFE line; under (b) a `sweep` line precedes `SYNCING->LOCKED` and follows `lock state file loaded|reason=DAILY_BREACH|locked_until=<future>`.

**P88.** THE RETIRED SENTENCE. The string `sends no order` occurs ZERO times in any journal written by the new build; the lock ALERT and the boot ALERT carry the ENF-18 text.

**P89.** EXPIRY WITH A HELD POSITION. `lock expired|...` then `LOCKED->SYNCING|lock expired|...` then `SYNCING->ACTIVE|history stable|polls=3/3`, ZERO `sweep` lines between them, then either `ACTIVE->LOCKED|DAILY_BREACH|...` on the first ACTIVE pass with `sweep close|...|retcode=10009` following at the session open, or an ACTIVE LIFE line whose `floating=` carries the held position.

**P90.** NEGATIVE CONTROL. Over a whole day in ACTIVE, ZERO lines beginning `sweep`, counted over the file; over a SAFE_HALT occupancy with a persisted lock, ZERO likewise.

**P91.** THE DERIVED WITNESS AFTER A FLATTEN. The first boot after ENF-L1's flatten fires `boot witness DERIVED fired|live=0|replay=1|...` with `realized=` at or below the negative of the snapshot limit, because the closing deals are in history; under the interim posture the same boot fired `live=1|replay=0` when the loss was still floating (`LEDGER.md:1255`).

**P92.** ENF-0. The classifier vector prints and asserts, among others, `TRADE_RETCODE_DONE=10009`, `TRADE_RETCODE_MARKET_CLOSED=10018`, `TRADE_RETCODE_CLIENT_DISABLES_AT=10027`, `TRADE_RETCODE_POSITION_CLOSED=10036`, `TRADE_RETCODE_DONE_PARTIAL=10010`; a mismatch between the compiler's value and 2.7.4 is a defect in this document and not in the build, and the build entry corrects 2.7.4 by appending.

**P93.** NO REGRESSION. `AGVEC|SUMMARY|<n>/<n>` with all five `d2d4_*` checks PASS; `TRANSITION`, `lock level`, `breach arithmetic`, `lock bounds` lines byte identical in shape to `6a44dba`'s; the LOCKED LIFE group's six fields unchanged, with a seventh appended only under ENF-17(b).

**P94.** DEPLOY. The pre restart re attach logs `limits accepted|percent=5.50|currency=200.00|raw=550/200` and NO ALERT, and the post restart flat boot emits ZERO `sweep` lines.

### 3.12 Documentation surfaces the build session touches

| Surface | Edit |
|---|---|
| `EA:9` `#property description` | "Locks the state machine and sends no order; open positions stay open until closed by hand. No trading calls anywhere in the build." retired |
| `EA:415-419`, `:449-453`, `:528-531` | the ruling TWO comment and the two ALERT sentences, per ENF-18 |
| `EA:1235-1236`, `:1258`, `:1264-1269` | the LOCKED dispatch gains the sweep call; the two Phase 3 comments retire; the accelerator body under ENF-2(a) |
| `Sweep.mqh:9-11` | the Phase 0 clause retires; the contract at `:16-29` becomes bodies |
| `docs/SPEC_v0.1.md:34` | unchanged, now measured by ENF-S2 |
| `docs/SPEC_v0.1.md:41`, `:50` | unchanged, now true |
| `docs/SPEC_v0.1.md:94` | the Phase 1 interim posture sentence and the Phase 2 window it implies, replaced by the ruled sweep text; recorded under the ruling, no A7 (`LEDGER.md:2337`) |
| `docs/SPEC_v0.1.md:97-99` | gains the ruled attempt bound, backoff schedule, hard stop state, ordering, send mode and reconnect rule |
| `docs/SPEC_v0.1.md:132-134` | the sweep line names of 3.5 and the CANNOT_TRADE alert cadence |
| `docs/SPEC_v0.1.md:170-175` | the Phase 3 matrix rows mapped to ENF-L1 to L7, "Partial close" recorded as not producible on demand under FOK |
| `README.md:10` | the badge `enforcement-detect and lock only` |
| `README.md:31-35` and Hebrew `:298-300` | "What it does not do yet" rewritten, both languages, never naming this ledger |
| `README.md:63` and its Hebrew mirror | the SAFE_HALT row, unchanged, "closes nothing, sweeps nothing" |
| `README.md:115` and `:380` | "The advisor sends no order today" retired |
| `README.md:212-214` and `:477-479` | "Your positions stay open. No order is sent." rewritten |
| `README.md:237` and `:502` | the Later row moves to a done row |
| `README.md:243-244` and `:509` | the FAQ answer rewritten |
| `docs/vectors/README.md:47-65` | the ENF-0 checks listed under ENF-24(a) or (b) |
| `docs/DESIGN_PHASE1_2.md` | left as written, a design record |

---

## TASK 4, ruling sheet

Closed options, a and b, c only where a third is genuinely distinct. Consequence per option. NO RECOMMENDATION. Each answer is recorded FINAL in DECISIONS by the owner, per the process ruling of 2026-07-29 (`LEDGER.md:2130`).

**ENF-1. Trigger.**
(a) Once at the breach only. Consequence: `SPEC:8`'s "anything newly opened is flattened within seconds" is amended away, `SPEC:172-173` become unreachable, and the Q3 clause "immediate sweep on restoration" (`LEDGER.md:2070`) is not met, which touches a FINAL; no retry policy is needed.
(b) At the breach and on every LOCKED tick while any position or pending exists. Consequence: the `Sweep.mqh` contract as declared and `SPEC:97`; one enumeration per LOCKED tick; ENF-9 to ENF-13 become mandatory.

**ENF-2. The `OnTradeTransaction` accelerator.**
(a) Built, one sweep pass on `TRADE_TRANSACTION_DEAL_ADD` with `DEAL_ENTRY_IN` while LOCKED, one `sweep accelerated` line per firing. Consequence: `SPEC:172`'s "both timer and OnTradeTransaction paths exercised" is rowable (P79); the guardian's own closes fire the handler and are filtered by entry type; ENF-S3 names a second call site.
(b) Not built, the stub at `EA:1264-1269` stays. Consequence: the timer alone, 1 s worst case added; `SPEC:172` amended to the timer path.

**ENF-3. Scope.**
(a) Every position and pending on the account regardless of origin, symbol or magic. Consequence: four symbols' sessions and filling modes read at run time; BTCUSD.ecn on an unread specification; ENF-L4 producible.
(b) The chart symbol only. Consequence: MUST SUPERSEDE the 2026-09-01 FINAL's scope clause (`LEDGER.md:1905`) and `SPEC:8`, `SPEC:126`; ENF-L4 and any second symbol row unreachable.

**ENF-4. Send mode.**
(a) Synchronous `OrderSend`, every due ticket per pass. Consequence: the blocking hazard of 2.6, a false mutex takeover possible from four positions up at the measured latency, LIFE gaps above 31 s on a large book.
(b) `OrderSendAsync` with per ticket in flight tracking cleared by `OnTradeTransaction` or by the next enumeration. Consequence: the pass never blocks; the build entry must argue that correctness rests on the enumeration and not on delivery, per F13; the most code of the three.
(c) Synchronous, at most one send per pass. Consequence: one latency per tick, under the 10 s staleness with margin on every measured value; N ticks to flatten N positions; no in flight tracking; the LIFE line shifts by up to one latency.

**ENF-5. API surface.**
(a) Raw `OrderSend` on `MqlTradeRequest`, no standard library. Consequence: no include outside the project's own tree, so the worktree compile question of 2.7.10 does not arise; the request fields, filling mode and position binding are written by hand and vector tested.
(b) `CTrade`. Consequence: `#include <Trade\Trade.mqh>` resolved from the Terminal data folder or from a vendored copy, measured before the first compile; the bool return must be ignored in favour of `ResultRetcode()` (2.7.1); less request code.

**ENF-6. Filling mode and deviation.**
(a) Per symbol from `SYMBOL_FILLING_MODE`, FOK when allowed, else IOC, else RETURN; deviation a compile time constant in points. Consequence: works on all four symbols without a per symbol table; a partial fill is possible only on IOC symbols.
(b) FOK always. Consequence: `INVALID_FILL` (10030) on any symbol that does not allow it, which is refuse class and holds that ticket for good; the only mode on record is US100.ecn's FOK.

**ENF-7. Ordering between pendings and positions, and among positions.**
(a) Pendings first, then positions by floating loss, most negative first. Consequence: `SPEC:50`'s order and F16's reason honoured; the largest bleed stopped first; `POSITION_PROFIT` read during enumeration, which `AgFloating` already does.
(b) Pendings first, then positions by ticket ascending. Consequence: deterministic and reproducible from the terminal's own list; the order of stopping the bleed is age, not size.
(c) Positions first, then pendings, per `REVIEW:153`. Consequence: a pending may fill into the pass and be closed a pass later at a second spread.

**ENF-8. Close by pairing on opposite positions.**
(a) Not used. Consequence: one close per position, one request type, one spread per position.
(b) Used first where `SYMBOL_ORDER_MODE` allows it. Consequence: one spread saved per pair; a second request type, a matching step, and `HEDGE_PROHIBITED` on the retcode surface; no lock on record had a pair to test it on.

**ENF-9. Backoff schedule per ticket, retry class.**
(a) One attempt per tick, flat. Consequence: the tightest bounded schedule; H attempts in H seconds.
(b) Doubling, 1, 2, 4, 8, 16, 32 s, capped at 60 s. Consequence: a transient condition gets seven attempts in about two minutes; a requote storm is impossible by construction.
(c) Class based, (b) for the retry class and no attempts for the hold class until its condition changes. Consequence: the hold class costs nothing while it holds; the re arm needs the condition to be re read each pass.

**ENF-10. The backoff clock.**
(a) A timer pass counter, no clock. Consequence: no clock enters `Sweep.mqh` at all, ENF-S6 reads zero; a pass is 1 s by D7b's constant, so the schedule is in ticks and holds under a frozen quote.
(b) `TimeLocal`, the A1/A3 class. Consequence: the class the existing cadences occupy (`LEDGER.md:1401`); recorded as an executor reading of the clock exemption FINAL (`LEDGER.md:2134`), not a supersession.
(c) `TimeCurrent`. Consequence: Q7 pure; the schedule freezes with the quote, so a held ticket in a frozen but connected market is never retried until a tick arrives, which is also when a retry could first succeed.

**ENF-11. The hard stop and the state at it.**
(a) A hard count H per ticket for the retry class; at H the ticket is held with one ALERT naming it and the cadence line thereafter, the CANNOT_FLATTEN sub condition on the banner, and a re arm when the retcode class changes or every 60 s. Consequence: bounded attempts, a visible held state, no manual act needed to resume; H ruled as 5, 10 or 20 in the same answer.
(b) No count, the rate cap of ENF-9(b) or (c) alone. Consequence: a ticket in the retry class is retried once a minute for the life of the lock; "no unbounded tight retry" satisfied by rate and not by count; no held state exists and the banner shows nothing for a stuck ticket.
(c) A hard count H, then stop for that ticket until a manual act. Consequence: contradicts "immediate sweep the moment trading is restored" (`SPEC:98`); the manual act would be a new mechanism the SPEC does not have.

**ENF-12. Partial close.**
(a) A `DONE_PARTIAL` resets the ticket's attempt counter and the remainder is a fresh ticket for the schedule. Consequence: a symbol that fills in pieces is flattened piece by piece with no risk of reaching H on successes.
(b) A `DONE_PARTIAL` counts as an attempt. Consequence: a large position on an IOC symbol with thin liquidity can reach H with volume still open.

**ENF-13. Market closed on the symbol.**
(a) Pre check `SymbolInfoSessionTrade` and `SYMBOL_TRADE_MODE` before every send, hold with `sweep held|...|next_open=<t>` and send nothing while closed. Consequence: ZERO requests into a closed session; the guardian's session reading is the authority, and the one symbol whose table is unread, BTCUSD.ecn, is read at run time.
(b) No pre check, send and classify 10018 into the hold class. Consequence: the platform is the authority on its own session; one request per backoff interval into a closed session all night; the `next_open` field is absent.
(c) Both. Consequence: the name from the pre check and the truth from the retcode; the most code.

**ENF-14. The cannot trade while locked ALERT cadence.**
(a) `AG_LIFE_INTERVAL_SECONDS`, 30 s, the Q2 breach ALERT precedent (`EA:35`, `LEDGER.md:2241`). Consequence: "continuous loud alerting" (`SPEC:98`) as one popup every 30 s while blocked; on a weekend with AutoTrading off, about 5760 popups.
(b) One ALERT at entry to the blocked state and one at exit, the journal line at the cadence. Consequence: two popups per episode; `SPEC:98`'s "continuous" reads as the journal and the banner, not the popup, and the SPEC says so.

**ENF-15. How "close-only" is read under Q3.**
(a) `SYMBOL_TRADE_MODE_CLOSEONLY` is sendable: the state is enumerated and logged distinctly as ruled, and closes are sent, since the platform accepts them. Consequence: a close only symbol is flattened; the Q3 FINAL's list is honoured for logging and its ground, "MQL5 cannot trade in these states", is read as the reason the list exists.
(b) Held per the letter of the list. Consequence: a close only symbol keeps its positions until the mode changes although the platform would have accepted the close.

**ENF-16. What counts as flat.**
(a) `PositionsTotal() == 0` and zero pending type orders on one pass that sent nothing. Consequence: `sweep complete` one tick after the last accepted close at the earliest; a position whose close filled but has not yet left the list makes the pass send once more, which returns `POSITION_CLOSED` and costs one line.
(b) The same on two consecutive passes. Consequence: one more tick before `sweep complete`; no spurious resend.

**ENF-17. The LOCKED LIFE line.**
(a) Unchanged, the sweep speaks through its own event lines only. Consequence: the D2D4 group and `SPEC:253` untouched; a reader holding one LIFE line cannot see whether a sweep is holding a ticket.
(b) A `sweep=<open>/<held>` field appended by the EA builder outside `AgLockedNumbersString`. Consequence: every LOCKED line says how many positions remain and how many are held; `SPEC:253` amended under the ruling; the formatter and its five vectors untouched.

**ENF-18. The lock and boot ALERT text.**
(a) "DAILY_BREACH: account LOCKED until <t> (pnl=<p> limit=<l>). Flattening <n> positions and deleting <m> pending orders." Consequence: the popup names the count the sweep is about to act on, read from one enumeration before the transition.
(b) "DAILY_BREACH: account LOCKED until <t> (pnl=<p> limit=<l>)." and nothing else. Consequence: the shortest true sentence; the counts live in the sweep lines.

**ENF-19. Magic and comment on the guardian's own requests.**
(a) A compile time magic constant and the comment `AG sweep`. Consequence: `DEAL_MAGIC` and the terminal journal attribute every guardian close, the negative the 2026-08-18 harvest used (`LEDGER.md:1267`) becomes a positive for ENF-L1.
(b) Magic 0 and no comment. Consequence: the guardian's closes are indistinguishable from manual ones in history.

**ENF-20. Reconnect while LOCKED with positions open.**
(a) The sweep resumes on the first connected tick with the `sweep resumed|gap=...` line. Consequence: `SPEC:99` read against the machine as built, where no SYNCING re entry exists on reconnect; the position list is the terminal's synchronized copy.
(b) The first post reconnect pass waits on `AgHistoryStable(AG_HISTORY_STABLE_POLLS)`. Consequence: three seconds; a stability poll on deal history the sweep does not read; consistent in shape with the RESYNC gate.

**ENF-21. Boot path, a lock witnessed at init with positions open.**
(a) The sweep starts at the SYNCING exit, on the first LOCKED dispatch after `AgEnterLockFromBoot`. Consequence: LOCKED is the only state whose dispatch sweeps; positions open at boot stay open for the three to four seconds of history stability; `SPEC:144` read broadly.
(b) The sweep also runs in SYNCING when the FILE or GV witness read at init carries an unexpired `locked_until`, F6's own text (`REVIEW:51`). Consequence: three seconds sooner; a sweep call outside the LOCKED dispatch that ENF-S3 must name; the DERIVED witness never qualifies; a stale or forged witness is bounded by the same clamp the derivation applies and an expired one reads as not locked.

**ENF-22. Expiry with a position still held.**
(a) The lock expires on `TimeCurrent >= locked_until` regardless, the sweep stops, and the P89 chain governs. Consequence: Q1, Q7 and "EXPIRY IS THE ONLY UNLOCK PATH" (`EA:536`) untouched; a held position rides into the new day under question FIVE.
(b) The lock holds until the book is flat. Consequence: MUST SUPERSEDE Q1 (`LEDGER.md:2062`), the expiry only unlock (`SPEC:102`, `EA:536-540`) and shape A's expiry path; a position the platform never accepts a close for holds the account locked indefinitely.

**ENF-23. The static rows replacing D2D4-S2.**
(a) Two rows, ENF-S2 (trade API confined to `Sweep.mqh`) and ENF-S3 (no sweep reachable outside LOCKED and the ruled sites). Consequence: the weaker invariant `LEDGER.md:68` names is stated as two checkable properties; every later build reruns both.
(b) One combined row. Consequence: one grep and one call site listing under one name.

**ENF-24. Vector reach for the sweep policy.**
(a) The pure helpers, the classifier, the schedule, the comparator, the flat predicate, the Q3 name mapping and the line formatters, live in `Sweep.mqh`, and the vectors script gains `#include <AccountGuardian/Sweep.mqh>`. Consequence: ENF-0 proves the policy before deploy on the ruling C precedent (`LEDGER.md:1955`); the vectors ex5 links the trade API without calling it, and ENF-S2 names the script's include line as the one permitted hit outside `Sweep.mqh`; `Vectors:10` "Makes no trade calls" stays true and is reworded to say the include exists.
(b) The pure helpers in a new include, `SweepPolicy.mqh`, with no trade API, included by `Sweep.mqh` and by the script. Consequence: the vectors ex5 links no trade API; a new file in the layout at `SPEC:16-25`, amended under the ruling; the static structure rule gains a file to name.
(c) No vector reach, the policy is proven live only. Consequence: every include stays byte identical except `Sweep.mqh`; the denominator stays 100; the retcode table of 2.7.4 is never asserted on the compiler (P92 unrun).

**ENF-25. The new constants, backoff cap, H, deviation, magic.**
(a) Compile time constants, the AG_LIFE_INTERVAL and AG_MUTEX_STALE precedent (`LEDGER.md:2139`, `:2143`, D7b `:2306`). Consequence: no dialog surface, no A9 vectors, no D1f style lists; a change is a build.
(b) Inputs. Consequence: core class under Q4 (`LEDGER.md:2074`), each needing its refusal vector and its ceiling, and a value able to loosen the sweep becomes a dialog edit.

**ENF-26. The runtime build label.**
(a) `init|build=ENF`. Consequence: names the phase.
(b) `init|build=SWEEP`. Consequence: names the file.
(c) `init|build=Phase3`. Consequence: continues the `Phase1`, `Phase2` series the R10 and D2D4 labels departed from.

**ENF-27. The deploy hand.**
(a) `scripts/deploy-enf.ps1` under the 2026-09-06 shape, the ruling at `LEDGER.md:2341` extended to name it as D2D4-11(a) did. Consequence: the mechanism of two deploys reused; one ruling clause.
(b) Dictation, one file at a time, per ruling ONE of 2026-08-18 (`LEDGER.md:1983`). Consequence: no new script; two files at most.

**ENF-28. SPEC and README edits.**
(a) In the build session, per 3.12, SPEC in place under the ruling with no A7, README both languages, never naming this ledger. Consequence: the build's diff touches `docs/SPEC_v0.1.md` and `README.md`; `README.md:33` and `:298` stop being false the day the build lands.
(b) Deferred to the acceptance session. Consequence: a build whose README says it sends no order, for the length of the acceptance window.

**ENF-29. Live locks.**
(a) Two locks: a daytime lock serving ENF-L1, L2, L3, L5 and L6 in that order, and a night or weekend lock serving ENF-L4 and L7. Consequence: two losing sequences to produce; rows chained inside one locked window, each starting from the state the previous left; one row's defect holds the rows after it on the same lock.
(b) One lock per row, seven. Consequence: seven losing sequences; every row on a clean book; the acceptance runs over as many days as it takes.

---

## TASK 5, LEDGER entries the build would create, drafted, not written

### 5.1 ISSUES, build session, added at the top

```
Issue:  ENFORCEMENT BUILD, ACCEPTANCE PENDING. The Sweep.mqh flatten engine is implemented on branch `<branch>` at commit `<hash>` per `docs/PLAN_ENFORCEMENT_SWEEP_2026-09-16.md` and the owner rulings ENF-1 to ENF-29 of `<date>` in DECISIONS. Trigger <once at breach / every LOCKED tick>, scope <whole account / chart symbol>, send mode <sync / async / one per pass>, API <raw OrderSend / CTrade>, ordering <...>, backoff <...>, hard stop <H=<n>, held state / rate cap>, market closed <pre check / retcode / both>. The interim posture FINAL of 2026-08-18 is SUPERSEDED by this build in its "sends no order" clause and the build carries the retired sentence nowhere (ENF-S7). Static rows ENF-S1 to ENF-S7 <closed on measured values / open>; ENF-S2 and ENF-S3 replace D2D4-S2 per `LEDGER.md:68`. Deploy row ENF-D, synthetic row ENF-0 and live rows ENF-L1 to ENF-L7 are NOT RUN. The live rows need <two / seven> genuine locks, each needing a losing position clearing the enforced limit.
Action: OWNER DEPLOYS per RULE A and ENF-27, attaches and confirms a healthy init with its `limits accepted` line BEFORE any restart per the 2026-09-07 procedure (ENF-D), runs the vectors for `AGVEC|SUMMARY|<n>/<n>` (ENF-0), then produces the first lock with at least two positions on two symbols and one pending resting (ENF-L1) and runs ENF-L2, L3, L5 and L6 on it in order, and on a later night the second lock for ENF-L4 and L7. Executor harvests read only and closes each row on quoted lines. Merging is a separate decision under the merge gate ruling and is not authorised here.
Status: OPEN
```

Plus one UPDATED paragraph on the NEXT BEST ACTION entry at `LEDGER.md:5-12`, pointing at this entry.

### 5.2 ACTIONS, this plan session, written this session as the second commit

Written into LEDGER.md by this session with the real hashes; the text is the entry itself and is not duplicated here.

### 5.3 ACTIONS, build session template, every angle bracket field a measured value

```
<date>. ENFORCEMENT BUILD IMPLEMENTED PER THE RULINGS ENF-1 TO ENF-29 OF <date>, on branch `<branch>` at `<hash>`, <n> files, <ins> insertions and <del> deletions, `Sweep.mqh` gaining its bodies at `<hash>` and the EA its dispatch, ALERT text and accelerator at `<hash>`. RULE A held. The standard library question of plan 2.7.10 MEASURED: <the worktree compile resolved `Trade.mqh` from <path> / no standard library include exists under ENF-5(a)>. Compile inside the worktree: `Result: 0 errors, 0 warnings, <ms> ms elapsed` for the EA and both vector scripts, exit code ignored per standing rule 6, every `including` line under the worktree <plus the one standard library line at <path>>. Build identity per standing rule 7: `AccountGuardian.mq5` `<md5>`, `Sweep.mqh` `<md5>`, <other changed files with md5>, and the unchanged includes `<md5 each>`; ex5 `<md5>` at <bytes> bytes, mtime <ts>, recorded and not identity. Static rows: ENF-S1 to ENF-S7 <values>; `AgEvaluateActive` byte identical at md5 `1F5EB03BB1992B5ACBD2E502E060D9BD`; the ENF-S2 grep returns <n> hits, all in `Sweep.mqh` <plus the vectors include line>. ENF-0 checks added: <n>, denominator <n>; P92 measured: <every constant equal to plan 2.7.4 / the divergences, appended to the plan by a dated note>. SPEC `:94`, `:97-99`, `:132-134`, `:170-175` and README `:10`, `:31-35`, `:115`, `:212-214`, `:237`, `:243-244` with their Hebrew mirrors amended per ENF-28, README never naming this ledger, <n> Hebrew characters read by the decoder, zero em dashes. `scripts/deploy-enf.ps1` written and NOT run. The interim posture FINAL of 2026-08-18 and the D8 cost clause of the 2026-08-24 FINAL now describe a build that no longer exists; both entries are left as written and are superseded by the ENF rulings. Nothing deployed, nothing merged, no push.
```

### 5.4 ACTIONS, acceptance session template

```
<date>. ENFORCEMENT ACCEPTANCE, <k> OF <n> ROWS CLOSED. ENF-D: landed md5 `<md5>` equals worktree; pre restart attach `limits accepted|percent=5.50|currency=200.00|raw=550/200` at `<file>:<line>` with no ALERT, second exercise of the 2026-09-07 procedure; post restart `BOOT->SYNCING` at `:<line>`, ZERO `sweep` lines on the flat boot. ENF-0: `AGVEC|SUMMARY|<n>/<n>` at `<file>:<line>`. LOCK ONE: `TRANSITION|ACTIVE->LOCKED|DAILY_BREACH|...` at `:<line>` with <n> positions and <m> pendings open per `<terminal file>:<lines>`. ENF-L1: `sweep delete` lines `:<lines>` retcode 10009, `sweep close` lines `:<lines>` retcode 10009 in the ENF-7 order, `sweep complete` at `:<line>`, first LOCKED LIFE `floating=0.00` at `:<line>`; terminal closing deals `<terminal file>:<lines>` carrying magic <n>; ZERO owner close requests in the window. ENF-L2: mobile open at `<terminal file>:<line>`, `sweep close` at `:<line>` <n> ms later. ENF-L3: `sweep blocked` lines `:<lines>`, ALERT count <n> over <s> s, ZERO `sweep close` while off, `sweep close` at `:<line>` after the button. ENF-L5: kill at <ts>, `stale mutex heartbeat` at `:<line>`, `SYNCING->LOCKED` at `:<line>`, first `sweep` line at `:<line>`, closes at `:<lines>`. ENF-L6: `DEGRADED|` lines `:<lines>` with ZERO `sweep close` inside, `sweep resumed|gap=<t1>..<t2>` at `:<line>`, `sweep close` at `:<line>`. LOCK TWO: `<transition line>` at `:<line>` with the XAUUSD.ecn position held past 23:58. ENF-L4: `sweep held` lines `:<lines>` at the cadence, <n> sends for the held ticket over <s> s against the schedule, `sweep close` at the reopen `:<line>`. ENF-L7: `lock expired` `:<line>`, `LOCKED->SYNCING` `:<line>`, `SYNCING->ACTIVE` `:<line>`, then <the re lock and the close / the ACTIVE LIFE line carrying the position> at `:<line>`. Evidence banked at `docs/evidence/<files>` md5 `<md5 each>`. Nothing merged, no push, worktree and branch kept.
```

### 5.5 DECISIONS, the ruling sheet answers, template in the D2D4 shape (`LEDGER.md:2349-2351`)

```
Decision: (owner ruling <date>, enforcement phase, ruling sheet ENF-1 to ENF-29 of `docs/PLAN_ENFORCEMENT_SWEEP_2026-09-16.md`, section 4) Answers, recorded as given, rulings only, no interpretation. ENF-1: (<a|b>). ENF-2: (<a|b>). ... ENF-29: (<a|b>). What this entry supersedes, by name and exactly how far: THE PHASE 2 INTERIM POSTURE (owner ruling 2026-08-18, Phase 2 open question TWO), its clause "A Phase 2 build LOCKS THE STATE MACHINE BUT SENDS NO ORDER ... SWEEP, FLATTEN AND PENDING ORDER DELETION REMAIN PHASE 3", AND THAT CLAUSE ONLY; <and, under ENF-3(b), the scope clause of the 2026-09-01 instrument scope FINAL; under ENF-22(b), Q1 and the expiry only unlock>. Every other clause of every FINAL the plan's section 1.9 tags INHERITED stands unchanged.
Reason: Owner's ruling, recorded as given, <date>.
Status: FINAL
```

## What closes none of this

No option, prediction or row in this document is closed by reading source, and none of section 2.7 is evidence of anything: it is documentation read into a plan so that the rows can name what to measure. Each row names a journal line, a terminal journal line, a file content or a count over a named window, and closes on the artifact only, the standing evidence rule of 2026-08-05 (`LEDGER.md:2043`) applied in advance. This document is a plan. It recommends nothing and authorises nothing.
