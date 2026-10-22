# AccountGuardian: Manual Lockout, plan, ruling sheet ML ruled, and build section

Date of the request: 2026-10-22. Written: 2026-10-22. Plan only. This document authorizes no code, no build, no deploy and no change under any MetaTrader terminal data folder. The build follows section 11 and starts only on the owner's instruction.

Branch `feature/manual-lockout`, cut from main at `cce862a` ("evidence: ledger-compaction.md quotes the owner's authorization of 2026-10-22 ..."), worktree `.claude/worktrees/feature-manual-lockout`. LEDGER.md was read in full before any other step, 600 lines, md5 `02A03154AE3F04BBE16CCF7B3BBA7567`, equal in the main checkout and in this branch's worktree. The owner rulings ML-1 to ML-27 of 2026-10-22 stand FINAL in DECISIONS at `7d2bf10`, `LEDGER.md:581-608` as at that commit, and are cited by name. The owner rulings ML-28 to ML-33 of the same date, on the six points section 12 raised, stand FINAL at `bcb71cc`, `LEDGER.md:616-632` as at that commit, and ML-34 to ML-36, on the two gaps ML-30 left and on the reach of ML-29, at `e1a931a`, `LEDGER.md:634-641` as at that commit. ML-37, on the S3 silence the plan had chosen under ML-35 (1), stands FINAL at `dd46b03`, `LEDGER.md:645-646` as at that commit.

Citations. `LEDGER.md:<n>` is a line as at `cce862a` unless a commit is named. `EA:<n>` is `MQL5/Experts/AccountGuardian/AccountGuardian.mq5`; `State.mqh:<n>`, `Clock.mqh:<n>`, `Log.mqh:<n>`, `Persist.mqh:<n>`, `Pnl.mqh:<n>`, `Sweep.mqh:<n>`, `SweepPolicy.mqh:<n>`, `AlertQueue.mqh:<n>` and `AlertText.mqh:<n>` are the includes under `MQL5/Include/AccountGuardian/`; `SVC:<n>` is `MQL5/Services/AccountGuardian/AccountGuardianAlerts.mq5`; `VEC:<n>` is `MQL5/Scripts/AccountGuardian/AgPhase2StateVectors.mq5`; `SPEC:<n>` is `docs/SPEC_v0.1.md`; `TGPLAN:<n>` is `docs/PLAN_TELEGRAM_ALERTS_2026-10-19.md`; `ADD:<n>` is `docs/PLAN_TELEGRAM_ALERTS_ADDENDUM_TG1B.md`; `ROWS:<n>` is `scripts/rows/static_rows.py`; `GEN:<n>` is `scripts/rows/gen_vectors.py`. Every file under `MQL5/`, `scripts/` and `docs/` is as at `cce862a`.

This session changed no source, include, script, vector, preset or installer file, compiled nothing, and read or wrote nothing under any terminal data folder. No merge, no push, no branch or worktree deleted.

Section 11 was checked without a build. Its steps B1 to B10 and B12 were applied, from this document's own code blocks, to scratch copies outside the repository, and the anchors of B13 and B14 were looked up: every old text and anchor occurs exactly once. The repository's `gen_vectors.py` and `tg_s7.py`, run on the scratch copy, give `TG-S7 HOLDS`, all 9 Manual Lockout templates equal to their drafts character for character and 97 new vector checks, as rerun after the plan was amended to ML-37. The source checks of ML-S4, ML-S5, ML-S8 to ML-S11 and ML-S14 to ML-S18 hold on the scratch EA, the scratch service and the scratch includes. Nothing was compiled, so ML-S1 stays open until the build.

## 1. The request and the rulings

### 1.1 The request

The owner's instruction of 2026-10-22: "new AccountGuardian feature, Manual Lockout. The trader engages a lock on demand from the chart. While active, the existing lock state and the existing enforcement (sweep) apply exactly as for a loss lock."

### 1.2 The rulings, FINAL at `7d2bf10`

- ML-1 (`LEDGER.md:583`): "Feature name: Manual Lockout."
- ML-2 (`:586`): "Irreversible. Once engaged, no trader action can cancel or shorten it."
- ML-3 (`:589`): "A confirmation step before engaging, modelled on Tradovate Manual Lockout."
- ML-4 (`:592`): "Maximum lock: until the start of the next server day (the next daily anchor). Refined by the owner on 2026-10-22 from an earlier 24 hours wording."
- ML-5 (`:595`): "Two ways to set the end, the trader picks one in the dialog: a duration from confirmation, or an end time in server time."
- ML-6 (`:598`): "The server day rollover and daily reset never release a Manual Lockout. Only its own end time releases it."
- ML-7 (`:601`): "When a loss lock and a Manual Lockout are active together, the later end time governs."
- ML-8 (`:604`): "The stricter governs. If the guardian closes a position during a Manual Lockout and that close locks the account to the next daily anchor, that lock applies."
- ML-9 to ML-27 (`:607`): option (A) of the ruling sheet, each item shown in section 9 with the owner's choice.
- ML-28 to ML-33, FINAL at `bcb71cc`: the owner's answers to the six points of section 12, each shown there as given.
- ML-34 to ML-36, FINAL at `e1a931a`: the two gaps ML-30 left and the reach of ML-29, shown in section 12 as given. ML-35 (1) supersedes TG-13 (B) (`LEDGER.md:536`) for deinit reason 3 only.
- ML-37, FINAL at `dd46b03`: the owner's ruling on the S3 silence the plan had chosen under ML-35 (1), shown in section 12 as given.

The daily anchor is 01:00:00 server time, every day including Saturday and Sunday: `AG_DAY_ANCHOR_OFFSET_SECONDS 3600` (`Clock.mqh:26`), `AgNextDayAnchor` (`Clock.mqh:45`), Q1 of 2026-08-08 (`LEDGER.md:287`), the weekend clause of 2026-09-01 (`LEDGER.md:187`). "The start of the next server day" in ML-4 is that anchor, as its own parenthetical says, and never server midnight, which the base ruling of 2026-08-05 replaced (`LEDGER.md:284`). Every bound below comes from `AgNextDayAnchor` alone, one clock (element SIX, `LEDGER.md:373`), so the scheduled revisit of Q1 after the 2026-10-25 to 2026-11-01 harvest (`LEDGER.md:9-11`, `:287-288`) carries through with no change here.

### 1.3 The owner's directions of 2026-10-22, not rulings

1. The feature mirrors Tradovate Manual Lockout one to one wherever Tradovate documents its behavior. Where a ruling differs, the ruling stands and the difference is listed (section 10).
2. The plan is reworked for the amended ML-4: a lockout never crosses the anchor.
3. Section 9 is ruled.
4. A build section for a lighter executor (section 11).
5. ISSUES names the build session as the next action.

### 1.4 Tradovate's documented behavior, as read on 2026-10-22

Read in full:
- prop.tradovate.com/blogs/manual-lockout-tradovate-prop: find the Lockout option (in the main interface on web and desktop, in the navigation drawer on mobile), select the account, choose a duration, click Lock Account. Durations 15 minutes, 30 minutes, 1 hour, end of session, or a custom duration up to 24 hours. Each locked account runs its own timer. "Once a lockout is triggered, you can't cancel it early"; the trader waits for it to expire or contacts the evaluation provider. Positions on the account are flattened, working orders cancelled, new orders rejected across platforms; other accounts are unaffected. A separate Risk Settings Lock resets at 4:00 pm CT.
- prop.ninjatrader.com/blogs/manual-lockout-ninjatrader-prop/: the same flow and options, and "Max lockout duration is 24 hours".
- prop.tradovate.com/blogs/manual-lockout-risk-strategies-prop-trading: "15 minutes, 30 minutes, an hour, or even the rest of the session"; the lockout "flattens all open positions, cancels working orders, and blocks new trades across your accounts and platforms".

Not readable: support.tradovate.com's Trader Lockout article (the page returned a loading error), help.tradeify.co and an algotradingsystems help page (both HTTP 403). What a search summary said of them is not used as fact. None of the pages read shows a confirmation dialog's wording, so the panel mirrors the documented flow and labels, not a dialog text.

## 2. FINAL decisions this plan follows

Every FINAL and REVISIT entry of DECISIONS was read and checked against ML-1 to ML-27 before they were recorded: 156 entries, no contradiction. None is reopened, and nothing below acts against one.

| FINAL | Location | What it requires of this work |
|---|---|---|
| Q7/F5, TimeCurrent only | `LEDGER.md:281` | every lockout end, bound, release and countdown reads `AgServerNow`; no `TimeLocal`, `TimeGMT`, `TimeTradeServer` or `GetTickCount` in either new include |
| Q1 and the 01:00 server anchor | `:240`, `:284`, `:287` | the loss lock's `locked_until` untouched; the lockout's bound is `AgNextDayAnchor` |
| Question FOUR floor, precedence, the 2026-07-30 clamp, ruling THREE | `:234`, `:228`, `:249`, `:231` | they keep governing the loss lock's `locked_until` (ML-9); no lockout end passes through `AgLockedUntilComputed`, `AgLockedUntilFromWitness` or `AgApplyLatchFloor` |
| Shape A, expiry enters SYNCING | `:219` | the lockout's release goes through the existing expiry path into SYNCING |
| No state file format change; defect 3 shape 1 | `:213`, `:216` | `state_<login>.dat`, its writers and `AG_STATE_FORMAT_VERSION` untouched; the lockout never goes through `AgEnterLockFromBoot` or `AgStateSetBreach` |
| Q6/F7, its clarification, element NINE | `:243`, `:255`, `:373`, `:375` | no snapshot for a lockout; the breach snapshot judges the loss lock only |
| Lock artifacts never deleted | `:246` | the record and its mirror are kept, rewritten or quarantined, never deleted |
| Never loaded never written | `:405` | the record saves only after a load or an engagement |
| F13, timer driven | `:196` | every lockout decision runs in OnTimer; OnChartEvent runs the panel only |
| AG_MUTEX_STALE_SECONDS = 10 | `:402` | no blocking call: `MessageBox` is out (section 5.2) |
| D1f, D4a, D5a, D6a, D7b, D9a, D11a, the defaults | `:344-365` | no input added, no limit touched (section 7) |
| Q3/F2, Q5/F16, ENF-1 to ENF-31, ENF-DEF-1 | `:422`, `:425`, `:428`, `:431`, `:434`, `:437` | the sweep runs unchanged on every LOCKED tick, whatever holds the lock; every close carries the magic and the comment of ENF-19(a); the sweep starts at the first LOCKED dispatch (ENF-21(a)); the release comes at the end regardless of the book (ENF-22(a)) |
| ENF-18(a) and the boot ALERT head | `:428`, `:440` | both texts unchanged on their own paths; the lockout has its own ALERTs (ML-21) |
| PK-1 to PK-15 | `:261`, `:264` | the SWEEP witness unchanged; ML-8 is what it produces after a close during a lockout |
| D2D4-1 to D2D4-15, ENF-17(b) | `:258`, `:428` | the six LOCKED LIFE fields and their formatter untouched; the lockout's end appended outside it; the banner's last line keeps the snapshot limit and the balance; the new mirror takes the state gate |
| Q8 and its amendment, Q9, Q10 and its amendment | `:293`, `:297`, `:324`, `:328`, `:332` | a request meeting a pending Q9 deferral waits one tick; eligibility reads `TERMINAL_CONNECTED` fresh and `g_ag_resyncing`, never `g_ag_obs_*` (question SIX, `:272`) |
| Q4, a deal on the anchor second | `:290` | counts to the new day (section 3.2, F1) |
| Reseed on reload | `:222` | an input change during a lockout reinitializes the EA; the lockout returns from its record |
| TG-1 (B), TG-4 (B), TG-5 (B), TG-10 (A), F1 to F11, R3, R4 | `:503`, `:518`, `:521`, `:533`, `:566`, `:575`, `:578` | the new messages follow F1 to F11 and R3, R4; the queue format and the snapshot line stay as they are |
| TG-13 (B), superseded for deinit reason 3 alone by ML-35 (1) | `:536` | S2 for every other reason as before, an in place re-init held and merged; for reason 3 no stop, no start and no merged message |
| S12 in every state | `:542`, `:545`, `:563` | the lockout reads no `g_ag_tp_*` global |
| RULE A and RULE B, the deploy hand rulings | `:159`, `:156`, `:171`, `:174` | the owner performs every copy and every drill act under the terminal folder |
| Evidence rules, R1 | `:75`, `:96`, `:102`, `:111`, `:114` | every live row closes on an artifact file and line, or in the deployment phase on the owner's attestation; standing rules 6 and 7 for compiles and identity |
| Naming discipline | `:105` | never the bare word in LEDGER or SPEC |
| R5, the ACTIONS length | `:117` | each ACTIONS entry at most 1,500 characters |
| Merge gate, worktrees kept, the branch plan | `:137`, `:148`, `:151` | the branch merges on its own proven work, by owner instruction; nothing deleted |
| README Hebrew only, IN-16 (a), IN-22 (b), IN-25 (b), the export secrecy ruling | `:492`, `:445`, `:448` | Hebrew README steps that never name the ledger; nothing shipped deletes a customer file; the secrecy patterns find nothing in the new files; `#property version` unchanged |
| SPEC series closed at A6 | `:489` | SPEC changes recorded under ML-26, no A7 |

## 3. Code survey at `cce862a`

### 3.1 The lock core

| What | Where |
|---|---|
| States, reasons | `State.mqh:11-18`; `State.mqh:25-31` (NONE 0, DAILY_BREACH 1, CORRUPT_STATE 2, SWEEP_WITNESS 3); `AgLockReasonName` `State.mqh:51-61` returns UNKNOWN for any other value |
| Lock globals | `g_ag_lock_reason`, `g_ag_locked_until` `State.mqh:33-35`; the state file model `Persist.mqh:75-85` |
| Entries into LOCKED | two only: `AgDeclareLock` `EA:570-610` (transition `EA:600`) and `AgEnterLockFromBoot` `EA:644-700` (transition `EA:692`) |
| The LOCKED dispatch | `EA:2091-2100`: `AgEvaluateLocked`, then `AgSweepPass("timer")` while still LOCKED |
| The release | `AgEvaluateLocked` `EA:730-793`: `now_server >= g_ag_locked_until` (`EA:753-754`), the `lock expired` line, model reset and save, poll counter reset, `AgTransition(AG_STATE_SYNCING, "lock expired", ...)` `EA:785` |
| The SYNCING exit | `EA:2050-2088`: `AgBootDerivation` `EA:362-553` on every exit, after a boot and after every expiry |
| Witnesses | FILE `EA:383`, GV `EA:395`, DERIVED `EA:480`, SWEEP `EA:504-521`, PEAK `EA:523-541`; the strictest end wins |
| Bounds | `AgLatchFloor`, `AgApplyLatchFloor` `Clock.mqh:134-143`; `AgLockedUntilComputed` `Clock.mqh:157-163`; `AgLockedUntilFromWitness` `Clock.mqh:174-181` |
| Persistence | `AgAtomicWrite` `Persist.mqh:129-160`; `AgChecksum` `:101-112`; `AgStateQuarantinePath` `:357-369`; the state record `:377-387`; its loader `:495-580` |
| GV lock mirror and its state gate | `EA:1999-2003`, ACTIVE and LOCKED only |
| Banner | `AgRefreshBanner` `EA:277-300`; `AgBanner` `Log.mqh:128-137`, Comment in the upper left |
| LOCKED LIFE group | `AgPnlNumbersString` `EA:242-257`; `AgLockedNumbersString` `Log.mqh:113-123`; the sweep field appended at `EA:256` |
| waiting_on while LOCKED | `State.mqh:108-109` |
| Q6 input witness | `EA:99-113`, seeded at `EA:578-580` and `EA:655-657` only |
| The sweep | `Sweep.mqh:427`; no read of any lock reason or end in `Sweep.mqh` or `SweepPolicy.mqh`; magic and comment `SweepPolicy.mqh:58`, `:60`; call sites `EA:2099`, `EA:2156` |
| Chart surface | `Comment` and `Alert` only (`Log.mqh:46`, `:132`, `:139`); no OnChartEvent and no chart object anywhere under `MQL5/` |
| The alert producer | `AgTgProduce` `EA:1477-1679`: S4 on any ACTIVE to LOCKED edge `EA:1583-1596`; S16 or S8 on SYNCING to LOCKED `EA:1506-1520`; S8 pending at LOCKED to SYNCING `EA:1521-1525` |
| Queue codes | `AlertQueue.mqh:31-51`, known list `:128-141`; no S5; the catalog row "S5 Locked on demand" `TGPLAN:187` |
| The service | render switch `SVC:393-457`; lock count `SVC:478-483`; the in place merge `SVC:531-555` and `SVC:488-510`; S14 `SVC:625-642`; status `SVC:779-797` |
| Static row TG-S15 | `ROWS:85-110`, six functions pinned against `00c7237` |

### 3.2 Findings, restated for the amended ML-4

F1, the SWEEP witness, ruled by ML-8. Every guardian close carries `AG_SWEEP_MAGIC` (`SweepPolicy.mqh:58`, ENF-19(a)). A lockout's release goes through SYNCING (shape A), and the SYNCING exit runs `AgBootDerivation`, whose SWEEP witness fires on any such deal since today's anchor (`Pnl.mqh:208-214`, `EA:508-521`) and locks until the next anchor after it (`Pnl.mqh:297-300`). So a lockout during which the guardian closed a position, the flatten at the engagement included, is followed at its end, and at any restart or in place reinit that day, by a SWEEP_WITNESS lock to the next daily anchor. ML-8 rules that this lock applies. With ML-4 the lockout itself never passes the anchor, so the account is held to that anchor at most, with one edge: a close stamped on the anchor second counts to the new day (Q4, `LEDGER.md:290`; vector `VEC:1242-1243`), and its SWEEP lock then runs to the following anchor, which ML-8 also lets apply. A lockout that ends exactly at the anchor is therefore not promised to be the last lock of the night. Pending deletions make no deals.

F2, the producer. S4 fires on any ACTIVE to LOCKED edge (`EA:1583-1596`) and would announce a lockout as a breach; S16's source word would read server deal history for a lockout (`AlertText.mqh:344-357`); S8's release text says a new trading day (`AlertText.mqh:540-545`); the status message reads the snapshot's `locked_until` (`EA:1229`, `SVC:796`), which a lockout alone leaves at 0, shown as 01/01/1970 00:00; S17 knows five file kinds (`EA:1376-1383`, `AlertText.mqh:360-371`); S14 counts S4 and S16 only (`SVC:478-483`); and an in place stop waits for an S1 or S16 to merge with (`SVC:531-555`), which a restart into a lockout alone would never send, so the stop message would go out alone and say the guardian stopped. ML-17 (A), with ML-30 to ML-32, settles each but the last and the start before it: under ML-30 a start into a lockout alone sends no start message, so an in place stop finds nothing to merge with. ML-34 and ML-35 rule those two (section 4.8).

F3, the store. The lockout's end lives outside `g_ag_locked_until`, the state file and `AG_LOCK_<login>`: ruling FOUR's floor (`Clock.mqh:139-143`) would lift a 15 minute lockout to the next anchor once the latch is seeded, which any ACTIVE pass does and an in place reinit keeps; and `AgEnterLockFromBoot` writes DAILY_BREACH into the state file (`EA:659-684`, `Persist.mqh:425`), which the next boot would read as a breach that never happened. Under ML-4 the clamp of 2026-07-30 would not cut a lockout read back on its own day, its ceiling being the same anchor; the floor still would, so the separate store stands (ML-9, ML-18).

F4, the end of day summary. No lockout crosses the anchor, so S14 comes, as on any day, at the first completed ACTIVE pass after 01:00 server (`SVC:625-642`, `EA:949`). An ML-8 relock delays nothing the summary reads.

F5, the queue. A V line with a code the service does not know fails the whole parse (`AlertQueue.mqh:349-351`, `:482-486`), and an older service then takes no queue read at all (`SVC:599-600`). The service therefore deploys first (ML-17, ML-25). The reverse holds too: returning to the TG EA after the ML EA wrote S5 or S25 makes the TG EA quarantine the queue at its load (`EA:1321-1343`), losing the events not yet acknowledged and the day's S9 latch. The N line and the queue format version stay as they are, so the ML EA's first load of a TG era queue succeeds.

F6, the static row TG-S15 (`ROWS:85-110`) reads CHANGED for `AgEvaluateLocked` on an ML build by design; ML-S4 replaces it, as ENF-23 (a) replaced D2D4-S2.

### 3.3 Observed and not acted on

- `SPEC:58` still reads LOCKED to ACTIVE, while the code enters SYNCING under shape A (`EA:785`). The SPEC amendment of ML-26 rewrites that row for the lockout and writes it as the code is.
- `SPEC:145` lists an unlock popup; the expiry path raises none (`EA:756` is an INFO line). The lockout's release follows the loss lock's path and raises none either.
- The poll counter OPEN issue (`LEDGER.md:13-15`): after an in place reinit the SYNCING exit can pass on its first poll. The lockout's boot witness sits after that gate and the build does not touch the reset.
- After an unclean stop during a loss lock, the next boot loads the expired record into the state model (`Persist.mqh:552-562`), and the banner's last line and the LOCKED LIFE snapshot fields print the model as it stands. A lockout alone on that day shows those stale snapshot figures there, a faithful print of the model; the Telegram result line does not use them (section 4.8).

## 4. Design

Every behavior here is fixed by a ruling or a FINAL entry cited in place. The four readings section 12 raised as points 3 to 6 are ruled by ML-30 to ML-33, the two gaps ML-30 left by ML-34 and ML-35, and the reach of the reason 3 silence over S3 by ML-37. The names, constants and formats the executor chose are fixed in section 11.

### 4.1 Two lock components, one LOCKED state

The loss lock keeps its globals, its state file and `AG_LOCK_<login>`, with no change in meaning. The lockout is a second component with its own model (`g_ag_ml_*`), its own record and its own mirror. The account is LOCKED while either holds. The effective end is the later of the two (ML-7): `AgManualEffectiveEnd(g_ag_locked_until, g_ag_ml_active, g_ag_ml_end)`. Under ML-4 a lockout ends no later than the next anchor, while every loss lock ends at the next anchor or later (Q1, FOUR, the SWEEP witness, CORRUPT_STATE), so when both hold the loss lock governs; the code still takes the maximum, so a clock that steps back cannot make the lockout end early.

No new `ENUM_AG_LOCK_REASON` member. `MANUAL_LOCKOUT` is a display name of the lockout on the banner, in the journal and in the ALERTs. The state file's reason field keeps its domain 0 to 3, so a record forged with `L|4` reads as UNKNOWN and never as a lockout.

### 4.2 The record and its mirror (ML-18, ML-19)

`MQL5\Files\AccountGuardian\manual_<login>.dat`, magic `AGMANUAL`, version 1:

```text
AGMANUAL|1|<login>
M|<active 0 or 1>|<first_engaged>|<engaged>|<end>|<form>|<minutes>
C|<FNV-1a of the two lines above>
```

It is written through `AgAtomicWrite`, loud on failure (SPEC 6 lists the state write failure popup), and loaded in OnInit before any write; the model is never saved before that load or an engagement (`LEDGER.md:405`). A record that does not parse, fails its checksum, carries another login, or lies outside the ML-4 bound (an active record whose end is not after its latest confirmation, or passes the next anchor of its first) is quarantined under `AgStateQuarantinePath`, journaled, reported by S17 kind 6, and replaced by a fresh inactive record; the mirror alone then decides (ML-19 (A)). The record is never deleted. At the lockout's end it is left as written, inert since its end has passed.

The mirror `AG_MANUAL_<login>` holds the bare end, 0 when no lockout holds. It is written every tick in ACTIVE and LOCKED beside `AG_LOCK_<login>`, under the same state gate (D2D4-1(a), `EA:1999-2003`): in SYNCING and SAFE_HALT nothing writes it, so a fresh image never zeroes it before the boot read. It is never deleted.

While a lockout holds, the record is read back every `AG_LIFE_INTERVAL_SECONDS` timer ticks, the LIFE cadence at the 1 s timer. Missing: rewritten. Present and different from the model: first moved aside under a quarantine name, keeping the evidence, then rewritten (ML-18 (A)).

ML-19 (A) makes the record the first lock artifact that errs unlocked when it is corrupt and its mirror is gone; the state file errs locked (`LEDGER.md:252`). That is the ruled behavior, and the threat model amendment states it (section 11, B13).

### 4.3 Engagement and extension (ML-5, ML-10 to ML-15)

OnChartEvent runs the panel (section 5) and, on Lock Account, records one request: the form, the minutes, the confirmation instant (`AgServerNow` at the click) and the end computed at that instant. It decides nothing.

OnTimer applies the request right after the state dispatch:
1. While ACTIVE with `g_ag_breach_deferred_once` set, the request waits one tick, so a breach Q9 deferred is declared first, with its snapshot, its ALERT and S4 (`LEDGER.md:324-326`). The request then meets a loss lock and is refused as not later than it.
2. Eligibility is tested again (ML-12 (A)): the record loaded, `TERMINAL_CONNECTED` read fresh, then ACTIVE outside RESYNC (`g_ag_resyncing` false) or LOCKED.
3. The end is checked against the confirmation instant: after it, at least 60 s after it for the end time form (ML-14), no later than its next daily anchor (ML-11), later than the current effective end while any lock holds (ML-10), and after the server time of the apply.
4. Refused: one `manual lockout refused` line and a panel note, nothing else.
5. Accepted: the model, the record, and the mirror at once (GlobalVariableSet and a flush). From ACTIVE: the Q6 input witness seeded (D4a), the counts read, `AgTransition(AG_STATE_LOCKED, "MANUAL_LOCKOUT", "manual_end=<t>")`, `AgSweepReset`, the engage ALERT; the sweep starts on the next LOCKED dispatch, as after a breach (ENF-21(a)). From LOCKED, which can only be a lockout alone, since no end can be later than a loss lock and still within ML-11: the end moves later, an extended line and its ALERT, no transition.

Durations count from the confirmation instant (ML-5): the review shows the end moving with the clock until the click.

### 4.4 The LOCKED dispatch and the release (ML-6, ML-7, ML-8)

Before `AgEvaluateLocked`, on each LOCKED tick:
- When the lockout's end has come and a loss lock still holds: the line `manual lockout ended, the loss lock holds`, the lockout model inactive, S25 kind 2; the account stays LOCKED under the loss lock (ML-7).
- When the lockout's end has come and nothing else holds: the line `manual lockout expired`; `AgEvaluateLocked` then releases on the same tick.

`AgEvaluateLocked` changes in two named lines: its test reads the effective end, and its `lock expired` line prints it. Everything else in it, the Q6 witness, the resets, the poll counter reset and the transition to SYNCING, stays byte identical. In ENF-22's terms the lockout releases at its end even with a held position, the sweep stops with the state, and the P89 chain into SYNCING governs. The rollover and the daily reset (the Q8 latch, the rollover line, the ratchet reseed, the peak reset) run only in ACTIVE (`EA:895-935`, `EA:965`, `EA:992`), so nothing at 01:00 can release a lockout (ML-6), and ML-4 keeps every lockout's end at or before that instant.

At the SYNCING exit after a lockout's release, `AgBootDerivation` runs unchanged: after a close by the guardian, the SWEEP witness locks to the next daily anchor (ML-8); after flattening losses past the limit, the DERIVED or PEAK witness locks as DAILY_BREACH; otherwise the account goes ACTIVE.

### 4.5 Boot, restart and reinit

OnInit loads the record after the peak file and before the SAFE_HALT branches, the state file's own order (`EA:1811` before `EA:1901`), and reports the mirror it read. At the SYNCING exit, after `AgBootDerivation` and outside it, the lockout's boot witness weighs the record and the mirror:
- the record fires when it loaded active with an end after now; the mirror fires when its end is after now;
- the later of the two governs, cut to the next anchor of now, the clamp's own ceiling, with no floor after it (ML-9): a forged end or a clock that stepped back across an anchor cannot carry a lockout past it;
- a mirror alone, a later mirror, or a cut end becomes the model, as a confirmation of now, and the record is rewritten to match;
- a derivation not evaluable (`EA:2070-2073`) keeps SYNCING, and the lockout waits with it.

Then, when a loss witness fired, `AgEnterLockFromBoot` runs unchanged and a firing lockout joins it with one line. When the lockout fired alone, a new entry, `AgEnterManualLockFromBoot`, the fourth LOCKED entry site after `EA:600`, `EA:692` and the engagement: the Q6 witness seeded, the counts, `AgTransition(AG_STATE_LOCKED, "boot derivation: MANUAL_LOCKOUT", ...)`, `AgSweepReset`, the boot ALERT. It never touches the state model. When nothing fired, the model goes inactive and the account ACTIVE.

OnInit also clears the pending request and the panel's state, since globals survive an in place reinit (reasons 3 and 5) and OnInit has no branch on the reason. The halt file's resume logic, where a GV and file mismatch means a human act (`EA:1890-1899`, the REVISIT at `LEDGER.md:408`), is not reused: for the lockout a mismatch keeps the lock.

### 4.6 What the trader and the journal see (ML-16)

- The banner while LOCKED: "Lock reason:" reads `MANUAL_LOCKOUT` when the lockout governs, and "Locked until:" the effective end (ML-16 (A)); its last line keeps "locked: snapshot limit <l>, balance <b>" (D2D4-8(b)).
- The LOCKED LIFE line: the six D2D4 fields untouched, `locked_until` the loss lock's own, 1970.01.01 00:00:00 for a lockout alone, a faithful print of the model; then the sweep field; then `|manual_end=<t>` while a lockout holds, appended outside `AgLockedNumbersString` as ENF-17(b) appended the sweep field.
- waiting_on while a lockout governs: `expiry: TimeCurrent >= manual_end`, the condition actually waited on (A3, `LEDGER.md:414`).
- The panel line: `Manual Lockout until <t> server` and `<h:mm:ss> left`, counted on `AgServerNow`, so a frozen feed freezes the countdown just as the release waits on the same clock (Q7).
- The status message and the command reply: the snapshot's existing `locked_until` field carries the effective end, with no format change.

### 4.7 The journal lines and the ALERTs (ML-21 (A), as listed)

```text
manual lockout panel|review|form=<f>|end=<t>|server=<t>
manual lockout panel|lock account clicked|form=<f>|end=<t>|server=<t>
manual lockout panel|review timed out|server=<t>
manual lockout refused|why=<why>|at=<panel|apply>|state=<state>|form=<f>|requested_end=<t>|server=<t>
manual lockout engaged|form=<f>|minutes=<n>|engaged=<t>|end=<t>|next_anchor=<t>|positions=<n>|pendings=<m>
TRANSITION|ACTIVE->LOCKED|MANUAL_LOCKOUT|manual_end=<t>
manual lockout extended|from=<t>|to=<t>|form=<f>|minutes=<n>|engaged=<t>
manual lockout ended, the loss lock holds|end=<t>|locked_until=<t>|server=<t>
manual lockout expired|end=<t>|server=<t>
manual lockout record loaded|active=<0|1>|end=<t>|weighed by the boot witness at the SYNCING exit
manual lockout GV mirror at init|raw=<t>|weighed by the boot witness at the SYNCING exit
boot witness MANUAL fired|source=<file|gv|file+gv>|record=<t>|gv=<t>|end=<t>
manual lockout holds with the boot lock|end=<t>|locked_until=<t>|governing=<MANUAL_LOCKOUT|loss lock>
TRANSITION|SYNCING->LOCKED|boot derivation: MANUAL_LOCKOUT|manual_end=<t>
manual lockout record rewritten|why=<missing|differs>
the LOCKED LIFE field |manual_end=<t>
```

`<f>` is `duration`, `end_of_session` or `end_time`. A click on the greyed Extend writes no journal line; the panel note alone states its refusal (ML-33). `<why>` is `past the next daily anchor`, `too soon`, `not later than the current lock`, `not available in this state`, `entry not understood` or `record not loaded`. `<state>` is the guardian's state name, or `-` for a refusal at the panel. Times are `YYYY.MM.DD HH:MM:SS` server time.

The ALERTs:
- engage: `MANUAL_LOCKOUT: account LOCKED until <t>. Flattening <n> positions and deleting <m> pending orders.`
- extend: `MANUAL_LOCKOUT: lockout extended until <t>.`
- boot: `LOCKED at boot by derivation (MANUAL_LOCKOUT) until <t>. Flattening <n> positions and deleting <m> pending orders.`, the ratified boot head of `LEDGER.md:440` carrying the lockout's name.

The error paths reuse the existing shapes: a failed record write raises the state write failure ALERT of `AgAtomicWrite` and S17 kind 6; a write refused before the load is the never loaded WARN; and the quarantine ML-19 (A) names is one WARN, `manual lockout record <why>, quarantined as <path>, the AG_MANUAL mirror alone decides at the SYNCING exit (ML-19)`.

### 4.8 Telegram (ML-17 (A))

- S5, "Locked on demand", the catalog's own row (`TGPLAN:187`): at the engagement only, with the engaging pass's limit and result (ML-30). No S5 at a restore at start and none at an extension. So a start into a lockout alone sends no start message, and the lockout shows in the next periodic status, the command reply, or S25 at its end (ML-34 (A)). An in place stop before such a start, which waits for an S1 or S16 to merge with (`SVC:531-555`), goes out alone when its 60 s hold ends (ML-35 (2), option (A)), for every in place reason but 3.
- ML-35 (1), a chart timeframe or symbol change, deinit reason 3, sends no Telegram message in any state: no stop, no start, no merged restart message. One pure helper, `AgTgSilentReason` in `AlertQueue.mqh`, true for reason 3 alone, is shared by the EA, the service and the vectors. OnDeinit queues no S2 for that reason and still writes the queue, so nothing pending is lost. It sets `g_ag_tgp_quiet_start` from the same helper for every reason, so any other reason clears it. An in place re-init keeps the program's globals (measured on reasons 3 and 5, `LEDGER.md:13-15`) and a fresh image starts the flag false. `AgTgInitReset` leaves it alone, and the producer reads it once, at the first SYNCING exit or the first SAFE_HALT tick of that init: no S1 and no S16 then, none for a lockout alone already (ML-34), S3 only as ML-37 below allows, and the flag cleared. Events that report a condition the init finds are not the change's own and send as at any init: S15, S17, S18, S21, S22, S24, S12, a breach, a lock, a release. The service, for a queue an earlier build wrote, acknowledges an S2 of reason 3 without a message, and with it, inside its hold, the S1 or S16 it would have merged with. S14 counts no lock for that start, there being no S16. A reason 3 change that falls inside the SYNCING window of an attach or a terminal start, before that start's S1 or S16 went out, leaves that start untold as well. TG-13 (B) stands for every other reason, its hold and merge unchanged for reasons 2, 5, 6 and 7.
- ML-37 narrows that silence for S3: after a reason 3 change, S3 is silenced only when the same SAFE_HALT was already announced before the change, and a SAFE_HALT new at the init after the change always sends S3. A SAFE_HALT is known by its halt time, `g_ag_halt_time`: the halt file carries it (`Persist.mqh:170`) and every init reads it back (`Persist.mqh:249`), so the same halt keeps its time across the change, while a chain trip at the init after it takes a new one (`Persist.mqh:329`). A SAFE_HALT counts as announced once a queue write that carried its S3 has succeeded. The EA makes no network call (TG-1 (B)); writing the queue is how it announces, and the written queue survives the in place re-init, so the service sends that S3 whether the change came before the send or after it (TG-5 (B)). The record is one global, `g_ag_tgp_s3_announced`: the halt time of the last S3 among the events a successful write in `AgTgQueueWrite` carried, read by the pure helper `AgTgS3HaltTimeIn`, and kept as it was by a write that carries no S3. Like the quiet flag it survives the in place re-init, a second change in a row included, and `AgTgInitReset` leaves it alone; a fresh image starts it at 0, which announces nothing. At the first SAFE_HALT tick the producer asks the pure helper `AgTgS3Silenced`, true only after a reason 3 change with a halt time on record equal to this init's. So a reason 3 change never queues the S3 of a halt a second time, and the init after it sends S3 for a new halt and for one whose S3 never reached the file: pushed but not written, forgotten by the queue's bound, or not yet pushed because the change came before the first SAFE_HALT tick. A queue quarantined at the load after the change loses its unacknowledged events, such an S3 among them, as at any load, and S17 kind 5 reports it. A SAFE_HALT new at the init after a reason 3 change needs that change's own halt file write to fail: its OnDeinit marks the session clean and writes the halt file from memory (`EA:2176-2180`, `Persist.mqh:319-323`), which ends any unclean chain and overwrites a halt flag set by hand. It is not produced on demand, so static row ML-S18 and three vectors of B9 prove it.
- S25, the lockout's own end: kind 1 released, at the first completed ACTIVE pass after the release, as S8 released is; kind 2 locked again, at the SYNCING exit that relocks, with the new lock's end and reason, or at once when the lockout ends under a loss lock.
- S4, S8 and S16 never describe a lockout: the producer pushes S5 in place of S4 when the lock is a lockout alone, nothing in place of S16 (ML-30), and S25 in place of S8 for a lockout's end. S16 still describes a loss lock found at a boot where a lockout also holds.
- S17 gains kind 6, the lockout's record. S14 counts S5 as a lock, as it counts S4 and S16; S25 is not counted, as S8 locked again is not.
- The result line uses a breach snapshot only while a loss lock holds. While a lockout alone holds, the result line of the status, S6, S7, S12 and S17 reads "not computed yet" (R3); S5 carries the last ACTIVE pass's figures.
- When the lockout and a loss lock end on the same tick, S8 alone is sent (ML-32): it describes the release, the loss lock having governed, and no S25 follows.
- The drafts are in section 11, B4, under F1 to F11 and R3, R4. S5 carries the sweep line and leaves the open trades line out, as S4 and S16 do (ML-31); S25 carries no sweep line and keeps it (R4). Neither S5 nor S25 carries the build line (F9); no Latin text but PNL and the currency sign (F11).

### 4.9 Code layout and build mechanics (ML-22 to ML-27)

- `ManualLockout.mqh`: the model, the record's I/O, the bounds, the two field parsers, the line and ALERT formatters. It includes `Persist.mqh` only, so the vectors script still links no trade API (ENF-24(b)); the pending count for the ALERT is read in the EA, where `Sweep.mqh` is.
- `LockoutPanel.mqh`: the chart objects and the request; English text, ASCII source.
- Both join the installer manifest through `scripts/make-manifest.ps1`, and the export with it; the vectors script includes the first.
- Build label `ML`, for the EA and for the service (ML-24); `#property version` unchanged (IN-25 (b)).
- `scripts/deploy-ml.ps1` under the 2026-09-06 shape: the service first, then the EA, then the vectors script (ML-25); the venue is the demo terminal first, as TG-10 (A).
- SPEC and README amended in the build session (ML-26); the release carries the feature after its acceptance closes, with Hebrew panel steps in the README (ML-27).
- Comments in every shipped file avoid the export secrecy patterns of `scripts/secrecy-patterns.txt` (the ruling of 2026-09-29, `LEDGER.md:448`): they cite "rulings ML-1 to ML-27", never the two words "owner ruling" together.

## 5. Chart UI

### 5.1 What MT5 allows

- An Expert Advisor can draw chart objects on its own chart only: `OBJ_BUTTON`, `OBJ_EDIT`, `OBJ_LABEL`, `OBJ_RECTANGLE_LABEL`, placed in pixels from a chosen corner with `OBJPROP_CORNER`, `OBJPROP_XDISTANCE` and `OBJPROP_YDISTANCE`, so they stay put when the chart scrolls. A button, an edit field and a rectangle label anchor at their upper left corner, so in the right upper corner `OBJPROP_XDISTANCE` is the distance from the chart's right edge to the object's left edge.
- Events reach `OnChartEvent`: `CHARTEVENT_OBJECT_CLICK` with the object's name, `CHARTEVENT_OBJECT_ENDEDIT` from an edit field, and `CHARTEVENT_OBJECT_DELETE` once `CHART_EVENT_OBJECT_DELETE` is set on the chart. A pressed button stays pressed until the program resets `OBJPROP_STATE`. A label with empty text shows the word Label, so an empty line is written as one space.
- An EA cannot add a toolbar button, a menu item or a window to the terminal itself. The control lives on the one chart where the EA runs, and the instance mutex allows one EA per account on a terminal (`Persist.mqh:1252-1285`).
- `OnChartEvent` and `OnTimer` run on the EA's one thread, one at a time. A handler that returns quickly delays the next timer event by its own length only; a timer event is not queued while one is queued or running (the MQL5 documentation of `EventSetTimer`). An EA has one timer, so the panel adds no `EventSetTimer` call (F13).
- Chart objects are saved with the chart and outlive the program unless deleted. The panel deletes only its own objects, by prefix, in OnDeinit, and recreates them in OnInit.

### 5.2 Rejected surfaces

- `MessageBox`: the MQL5 documentation says the call "suspends the thread of execution" for the whole time it waits. While it is open there is no timer: no evaluation, no sweep, and the mutex heartbeat goes stale after `AG_MUTEX_STALE_SECONDS`, 10 s, handing the mutex to another instance. A dialog left open would be a disable path, against R10 and F13.
- The inputs dialog: any input change reinitializes the EA and persists as the last used value, so an input that engaged a lockout could be set back, against ML-2. R10 adds no input.
- The Standard Library dialog classes (`Controls\Dialog.mqh` and its family): a large include in every shipped tree and its own event plumbing, for nothing the plain objects lack here.
- Keyboard shortcuts: a stray key press could start a lock.

### 5.3 The panel

In the upper right corner, clear of the Comment banner in the upper left. Its stages:
- IDLE: one button, Manual Lockout.
- CHOOSE: 15 minutes, 30 minutes, 1 hour, End of session (the next daily anchor), a custom minutes field with its Custom button, an end time field (HH:MM server) with its End time button, and Close. A preset whose end would pass the next anchor, or would not be later than the current end during an extension, is greyed and refused on a click.
- REVIEW (ML-15): the account number, `Lock until <YYYY.MM.DD HH:MM:SS> server`, `Length <h:mm:ss> from now`, the positions to close and the pending orders to delete, `This lockout cannot be cancelled or shortened.`, the ML-8 line when the end comes before the anchor, then Lock Account and Back. It cancels itself after 60 timer ticks (`AG_MANUAL_REVIEW_TICKS`), counted in OnTimer: TimeCurrent would never count it out in a frozen feed, and no other clock is needed.
- WAIT: one tick, until OnTimer applies the request.
- LOCKED: `Manual Lockout until <t> server` or `Locked until <t> server (<reason>)`, `<h:mm:ss> left`, and Extend while a lockout alone holds, the trader is eligible, and its end is before the next anchor.
- UNAVAILABLE: `Manual Lockout unavailable: <why>` in BOOT, SYNCING, SAFE_HALT, during RESYNC, while disconnected, or with the record not loaded (ML-12 (A)), all outside LOCKED. While LOCKED the panel keeps the lock's lines and greys Extend, a click on it refused with the reason in the panel note and no journal line (ML-33).

Stage changes run in OnChartEvent: they are the panel's own presentation and decide nothing for the guardian, while the engagement itself runs in OnTimer. The two fields are read only when their buttons are clicked, in OnChartEvent, never in OnTimer, so OnTimer makes no synchronous chart read and never writes into a field the trader is typing in. No mouse move events are enabled. The two parsers read character codes only, so no entry can index an array or divide: a critical runtime error would stop the program, and with it the timer, the sweep and the mutex heartbeat.

### 5.4 The Tradovate mirror

Mirrored as documented: choose a duration, then Lock Account; the presets 15 minutes, 30 minutes, 1 hour, End of session and Custom, by their Tradovate names; the account shown before the lock; positions flattened and working orders deleted at the lock; no early cancel; one timer per account. The differences are in section 10.

## 6. Failure cases

ML-4 keeps every lockout inside one server day, so no case below crosses the anchor.

- Terminal restart, clean, by a hard kill, or by an OS shutdown. The record was written at the engagement and the mirror is flushed every tick, so the boot witness restores the lockout with its own end (`boot witness MANUAL fired`). Time while the terminal was down counts toward the end, an absolute server time. A trade opened from the mobile app meanwhile is swept at the first LOCKED pass, and ML-8 then holds the account to the anchor.
- EA removed and attached again. OnDeinit releases the mutex and deletes the panel; the record and the mirror stay; the attach restores the lockout. While the EA is off nothing enforces, kill equivalent as SPEC 7 lists.
- In place reinit (reasons 3 and 5). The model is loaded again in OnInit, so no in memory value survives into a decision; SYNCING may exit on its first poll (the OPEN issue); the restore follows. An input change during a lockout takes effect after it: the reseed on reload ruling recaptures the inputs, and nothing about the lockout reads them. On Telegram a reason 3 change sends nothing (ML-35 (1)); a reason 5 change during a lockout alone sends S2 alone after the 60 s hold (ML-35 (2)) and no start message (ML-34).
- Account switch (reason 6). The record is per login: the other account sees no lockout, and switching back restores it if its end has not passed.
- Reconnect. While disconnected the LOCKED LIFE line carries DEGRADED, the sweep sends nothing, the panel greys Extend and refuses it as not available in this state, and the release waits on TimeCurrent, frozen meanwhile. On reconnect the sweep resumes with `sweep resumed|gap=...` (ENF-20(a)); a request in flight across a disconnect is refused at the apply.
- The server day rollover. A lockout ends at or before 01:00 server. The End of session preset ends exactly there and is released by its own end; the rollover line, the ratchet reseed and the peak reset come at the first ACTIVE pass after it. ML-8's anchor second edge (F1) can relock one more server day.
- A frozen server clock. A lockout counts on TimeCurrent (Q7). Confirmed while quotes are frozen, it counts from the last known server time, so it runs shorter in real time by the freeze, and its bound is the anchor that clock gives. Confirmed in the pre anchor break, it ends at the imminent anchor and releases at the first update after it: ruling THREE's extra day applies to a declared breach only. With BTCUSD.ecn in Market Watch the server clock moves through the weekend (`LEDGER.md:187`).
- The broker's DST step. The end is a server time value; a step of the server clock moves its real time length by the step. Which calendar the broker follows is not measured yet (`LEDGER.md:9-11`); an acceptance run inside 2026-10-25 to 2026-11-01 records the offset it saw.
- HH:MM. The first instant at that time of day after the confirmation, counted from the anchor so that no second day boundary exists: at 23:00 server, 00:45 is accepted and 01:15 refused; the current minute means tomorrow and is refused as past the anchor.
- An end on the anchor second: the release and the anchor fall on the same tick; F1's edge applies.
- SAFE_HALT. Entered only in OnInit (`EA:1905`, `EA:1923`); it closes and sweeps nothing (SPEC 2). The record and the mirror survive; after the halt file is deleted by hand, the lockout returns if its end has not passed.
- A position held at the end (market closed, a refused close): released regardless (ENF-22(a)), the P89 chain, and ML-8's relock if a close happened that day.
- Two terminals on one account: each guardian has its own record and mirror, files and GVs being per terminal. A lockout on one is enforced by that one; the other relocks at its next boot through the SWEEP witness if the first closed anything.
- A Q9 deferral on the engaging tick: the request waits one tick, the breach declares, and the request is then refused as not later than the loss lock.
- A forged or future record: an active record past the next anchor of its own first confirmation is quarantined; a record or mirror end past the next anchor of now is cut to that anchor.
- The record deleted or altered while the EA runs: rewritten within 30 timer ticks, an altered one first moved aside. Deleted with the EA stopped and the mirror cleared too: the lockout is gone at the next start, unless the guardian closed a position that day (ML-20, accepted).
- A record write failure: the ALERT; the lockout holds in memory and in the mirror; the 30 tick check retries.
- A stale state model after an unclean stop during a loss lock: section 3.3.
- Rollback: an ML EA replaced by the TG EA meets S5 or S25 in the queue and quarantines it at its load (F5). Deploy in the order of ML-25, and do not roll back during a lockout.

## 7. No path that widens or disables the loss limits (R10 stays as is)

- No input is added. Both limit inputs, their lists, ceilings and defaults (D1f, `LEDGER.md:344`, `:365`) are untouched, and `Pnl.mqh` is byte identical (ML-S2).
- The lockout writes no limit, no ratchet floor, no peak and no snapshot; the state file is written at its release only by the existing expiry code, which resets an expired record there exactly as at any expiry. `Clock.mqh`, `State.mqh`, `Persist.mqh`, `Log.mqh`, `Pnl.mqh`, `Sweep.mqh` and `SweepPolicy.mqh` are byte identical (ML-S3); the five protected functions other than `AgEvaluateLocked` are byte identical (ML-S4).
- The only new control can add a lock or move a lockout's end later. Nothing shortens or removes a loss lock: the later end governs (ML-7), and engagement during a loss lock is refused (ML-10, ML-11).
- A lockout's release enters SYNCING and the full evaluation: the derivation with its snapshot, floor and live tiers and its PEAK and SWEEP witnesses, then Q8, Q9 and Q10 and the breach test in ACTIVE. A loss accrued during a lockout, on a position the sweep could not close, locks at its end.
- During a lockout the loss limits are not evaluated, as during any lock: the same sweep holds the account flat (ENF-1(b)), and the breach test resumes at the release.
- D4a: an input change while a lockout holds is a reinit, the inputs recaptured and the lockout restored; after the release the ratchet holds a raised limit for the rest of the day (D9a), and a new day reseeds as on any day.
- No blocking call: zero `MessageBox`, zero `Sleep` in the EA and its includes, no Standard Library dialog (ML-S6); nothing deleted (ML-S7).
- The one new event handler, OnChartEvent, calls the panel only (ML-S11), and the panel writes chart objects only.

## 8. Acceptance rows

Every row closes on quoted journal lines, each with its artifact file name and line number (`LEDGER.md:75`), carrying the build: the `init|build=ML` line of the same journal and the build hash, which is the source commit of the build with the md5 of every compiled source against that commit (standing rule 7, `LEDGER.md:96`). The landed ex5 md5 the owner pastes from `Get-FileHash` is recorded beside it and is not identity by itself. In the deployment phase the owner's attestation closes a row instead (R1, `LEDGER.md:114`, under the ruling of 2026-09-30, `LEDGER.md:111`). Every live row is the owner's, on the demo terminal first and then on the live account's computer (TG-10 (A)); the executor reads only what the owner pastes or banks under `docs/evidence/`, and at ML-D the landed files' md5 by a plain `Get-FileHash`. Every write, move or deletion under the terminal folder in a drill is the owner's hand, never the executor's (RULE A), and a drill moves a file aside rather than deleting it (PK-13 (b)). Any failed live row is reported at once as a numbered defect.

Static rows, at the build, by the executor:
- ML-S1. Four compiles, the EA, the service and both vectors scripts: the log's `Result: 0 errors, 0 warnings`, every `including` line inside the build worktree, and the ex5 present with a fresh timestamp (standing rule 6).
- ML-S2. `Pnl.mqh` byte identical to `cce862a`; every `input` line in `MQL5/` identical.
- ML-S3. `Clock.mqh`, `State.mqh`, `Persist.mqh`, `Log.mqh`, `Pnl.mqh`, `Sweep.mqh`, `SweepPolicy.mqh`, `AlertJson.mqh` and `AgPhase1ClockVectors.mq5` byte identical.
- ML-S4. `AgEvaluateActive`, `AgBootDerivation`, `AgDeclareLock`, `AgEnterLockFromBoot` and `AgTransition` byte identical; `AgEvaluateLocked` equal to its `cce862a` text with the two lines of B5.7 changed. Replaces TG-S15 (F6).
- ML-S5. The trade API family: the same lines as at `cce862a`; `AgSweepPass` keeps its two call sites (ENF-S2, ENF-S3).
- ML-S6. Zero `MessageBox`, zero `Sleep` outside the service, zero `#include <Controls`, zero `CHART_EVENT_MOUSE_MOVE`.
- ML-S7. Zero `FileDelete`, `FolderDelete`, `GlobalVariableDel`, `GlobalVariablesDeleteAll`.
- ML-S8. Zero `TimeLocal`, `TimeGMT`, `TimeTradeServer`, `GetTickCount` in the two new includes.
- ML-S9. No line that names a lockout global also writes `g_ag_locked_until` or a `g_ag_state_` field, or calls a `locked_until` bound or a state file writer; `AG_LOCK_<login>` is written at one site.
- ML-S10. The transitions by function: into LOCKED only from `AgDeclareLock`, `AgEnterLockFromBoot`, `AgManualApplyPending` and `AgEnterManualLockFromBoot`; into SYNCING only from `AgEvaluateLocked` and `OnInit`; into ACTIVE only from `OnTimer`.
- ML-S11. `OnChartEvent` calls `AgPanelOnEvent` only; `LockoutPanel.mqh` holds no file or GV write, no transition, no state write, no sweep call and no trade name.
- ML-S12. The TG and installer rows rerun by `scripts/rows/static_rows.py`: TG-S2, TG-S3, TG-S10, TG-S11, TG-S16, TG-S6, IN-S5, IN-S3, IN-S6, the naming rule and the PowerShell parse, each as before; TG-S15 reads CHANGED for `AgEvaluateLocked` alone, by design.
- ML-S13. TG-S7 (`scripts/rows/tg_s7.py`) holds, and TG-S8 (`scripts/rows/gen_vectors.py`) regenerated, after the drafts of B4.
- ML-S14. The EA and both new includes ASCII after any byte order mark (ML-22).
- ML-S15. The manifest lists both new includes; `scripts/secrecy-patterns.txt` finds nothing in any shipped file (IN-22 (b)).
- ML-S16. `AgManualApplyPending` holds a request while `g_ag_breach_deferred_once` is set in ACTIVE (Q9). A breach and a click on the same tick are not producible on demand, so this row reads the source.
- ML-S17. ML-35 (1), the reason 3 silence: in OnDeinit the S2 push stands under `if(!AgTgSilentReason(reason))` and `g_ag_tgp_quiet_start` is set from the same helper; the flag is named only in its declaration, OnDeinit and `AgTgProduce`, never in `AgTgInitReset`; in `AgTgProduce` it guards the S1 and the S16 of the first start, and the S3 through the helper of ML-37 (ML-S18); in the service `AgSvcConvertOne` and `AgSvcMerge` call `AgTgSilentReason`. That the helper is true for reason 3 alone is the vector `ml_tg_silent_reason_is_reason_3_alone` of B9.
- ML-S18. ML-37, a SAFE_HALT new at the init after a reason 3 change sends S3: in `AgTgProduce` the one S3 push of the EA stands under `if(!AgTgS3Silenced(g_ag_tgp_quiet_start, g_ag_tgp_s3_announced, g_ag_halt_time))`; `g_ag_tgp_s3_announced` is assigned at one site, the successful write of `AgTgQueueWrite`, from `AgTgS3HaltTimeIn` over the events that write carried, and is named only in its declaration, `AgTgQueueWrite` and `AgTgProduce`, never in `AgTgInitReset`; both helpers are defined once, in `AlertQueue.mqh`. That the decision sends S3 for a new SAFE_HALT and for one with no halt time on record, silences it for the same SAFE_HALT after reason 3 alone, and that the record is the last S3 a write carried, are the vectors `ml_tg_s3_a_new_safe_halt_after_reason_3_is_sent`, `ml_tg_s3_the_same_safe_halt_announced_is_silenced_after_reason_3_only` and `ml_tg_s3_the_record_is_the_last_s3_a_write_carried` of B9. A static row, since such a SAFE_HALT is not produced on demand (section 4.8).

Vectors and deploy, by the owner at dictation:
- ML-0. `AgPhase2StateVectors` on the demo terminal: `AGVEC|SUMMARY|619/619`, the 522 of `LEDGER.md:6`, the 87 checks of B9 and the 10 of B10.
- ML-D. `scripts/deploy-ml.ps1`, run by the owner: the service first, then the EA, then the vectors script, each landed md5 pasted. After the owner reports the run, the executor verifies each landed file with a plain `Get-FileHash`, read only (`LEDGER.md:171`, RULE B), against B15's record. Before any restart the attach gives `init|build=ML`, `limits accepted|...` and `manual lockout GV mirror at init|raw=1970.01.01 00:00:00|weighed by the boot witness at the SYNCING exit`, a missing record writing no line, and no ALERT between them (`LEDGER.md:174`).

Live rows, stage 1, on the demo terminal (TG-10 (A)). The run order, by server day. A lockout during which the guardian closes a position leaves the account locked to the next anchor after its end (ML-8), and a lockout until End of session holds it there too. So each server day first runs the rows whose lockouts close nothing, engaged with nothing open: ML-L2, ML-L3, ML-L5 with ML-L19, ML-L7, ML-L11, ML-L12, ML-L13, ML-L15, ML-L16 and ML-L17, each walked forward to the ACTIVE state it leaves (`LEDGER.md:91`). Then exactly one row that ends the day: ML-L4 with ML-L8, its refusals in the hour before 01:00 server and End of session accepted last; or ML-L1 with ML-L9; or ML-L6; or ML-L10 with ML-L18. ML-L14 collects the Telegram messages of all of them. The open TG rows of R2 (`LEDGER.md:5-7`) share this terminal and may close on the ML binaries (ML-28), as the ENF-31 precedent allowed (`LEDGER.md:434`). TG-SV-L2 (`ADD:411`) reads a reason 3 restarted message, which ML-35 (1) withdraws: on the ML binaries a chart period change sends nothing, so that row as written closes on the TG binaries only.
- ML-L1. Engage a preset from ACTIVE with one open position and one pending order: `manual lockout engaged|form=duration|minutes=15|...|positions=1|pendings=1`, `TRANSITION|ACTIVE->LOCKED|MANUAL_LOCKOUT|manual_end=<t>`, the engage ALERT, then `sweep close|...`, `sweep delete|...` and `sweep complete|...`; a LOCKED LIFE line whose numbers group ends `|sweep=<o>/<h>|manual_end=<t>`, before its `|server=` and `|local=` fields. At its end: `manual lockout expired`, `lock expired|locked_until=<t>`, `LOCKED->SYNCING`, `boot witness SWEEP fired|...|bounded=<the next 01:00>` and `SYNCING->LOCKED|boot derivation: SWEEP_WITNESS|...`. This proves ML-8.
- ML-L2. The confirmation step: Back from the review, and a review left 60 timer ticks: `manual lockout panel|review|...` and `manual lockout panel|review timed out|...`, no engaged line, the next LIFE line `state=ACTIVE`.
- ML-L3. Engage by an end time HH:MM with nothing open: `form=end_time`, the end the first such instant after the click; at the end `manual lockout expired`, `LOCKED->SYNCING` and `SYNCING->ACTIVE|history stable|...`: released by its own end, nothing following.
- ML-L4. THE NEXT ANCHOR BOUND: custom minutes ending past the next anchor; 1 hour clicked within the hour before 01:00 server; an HH:MM past 01:00 server; an HH:MM under 60 s ahead. Each gives `manual lockout refused|why=past the next daily anchor|at=panel|...` or `why=too soon`, and no engaged line. Then End of session is accepted with `end=<the next 01:00>`.
- ML-L5. Irreversibility: during a lockout, every panel control tried; a chart timeframe change (reason 3), a parameter change (reason 5), the EA removed and attached again (reason 1). Each time: `manual lockout record loaded|active=1|end=<same>`, `boot witness MANUAL fired|source=file+gv|...|end=<same>` and `TRANSITION|...->LOCKED|boot derivation: MANUAL_LOCKOUT|manual_end=<same>`.
- ML-L6. A clean terminal close and reopen, then a hard kill and relaunch, during one lockout, with a mobile trade opened only during the second downtime: after each start the lines of ML-L5, and after the relaunch `sweep close|...` at the first LOCKED pass. That close holds the account to the next anchor after the lockout's end (ML-8), so this row ends the server day.
- ML-L7. Network off for at least 60 s during a lockout: LOCKED LIFE lines with `DEGRADED|`; the panel keeps the lockout's lines and greys Extend, a click on it giving the panel note `Refused: not available in this state` and no journal line (ML-33), a screenshot with the LIFE line of the same second; `sweep resumed|gap=...` on reconnect; the release at the lockout's own end.
- ML-L8. ML-6: a lockout engaged with End of session: LOCKED LIFE lines up to 01:00 server with `manual_end=<01:00>`; at 01:00 `manual lockout expired|end=<01:00>|...`, `lock expired|locked_until=<01:00>|...`, `LOCKED->SYNCING` and `SYNCING->ACTIVE`, then `day rollover|...` on the first ACTIVE pass. The rollover released nothing; the lockout's own end did.
- ML-L9. ML-7 at a boot: during the ML-L1 lockout, before its end, a terminal restart: `boot witness SWEEP fired|...|bounded=<01:00>`, `boot witness MANUAL fired|...|end=<t>`, `manual lockout holds with the boot lock|end=<t>|locked_until=<01:00>|governing=loss lock`, the banner reading SWEEP_WITNESS until 01:00; at the lockout's end `manual lockout ended, the loss lock holds|...`; the release at 01:00.
- ML-L10. ML-10 during a loss lock: a demo position past the limit gives DAILY_BREACH until 01:00; Extend stays greyed, and a click on it gives the panel note `Refused: not later than the current lock` and no journal line (ML-33), a screenshot with the LIFE line of the same second, and no `manual lockout engaged` line follows.
- ML-L11. Extension: during a lockout alone, Extend to a later end: `manual lockout extended|from=<t1>|to=<t2>|...`, its ALERT, `manual_end` moving on the LIFE line; an equal or earlier end refused with `why=not later than the current lock`.
- ML-L12. Self heal: the mirror cleared in the F3 dialog during a lockout is back within one tick, read by the F3 protocol of standing rule (2) (`LEDGER.md:96`); the record moved aside by the owner is back within 30 ticks: `manual lockout record rewritten|why=missing`.
- ML-L13. A corrupt record at load, ML-19 (A): with the EA stopped, the owner puts a corrupt copy in place at dictation. At the attach: the quarantine WARN and S17 kind 6; then, with the mirror holding the end, `boot witness MANUAL fired|source=gv|...`; with the mirror also cleared, no lockout.
- ML-L14. Telegram, ML-17 (A), ML-30, ML-34 and ML-35: S5 (ML-L1), S25 kind 1 (ML-L3), S25 kind 2 (ML-L1 and ML-L9). Each received text pasted with its `alerts sent|seq=<n>|class=<S>|http=200|...` line; no S4, S8 or S16 for any lockout, and no S5 at the restores of ML-L5 and ML-L6 or at the extension of ML-L11. At those restores no start message (ML-34); the reason 5 change of ML-L5 sends S2 alone after the 60 s hold, `class=S2` (ML-35 (2)); its reason 1 removal sends S2 at once; its reason 3 change sends nothing (ML-L19).
- ML-L15. ML-16: a screenshot of the panel and the banner during a lockout with the LIFE line of the same second: the reason, the effective end and the remaining time agree.
- ML-L16. ML-12: the panel unavailable in SYNCING after an attach, during RESYNC after a reconnect, and while disconnected, each a screenshot with the LIFE line of the same second. SAFE_HALT is not produced on demand and rests on ML-S10 and the source.
- ML-L17. ML-35 (1) in ACTIVE: a chart timeframe change with no lock: `deinit|reason=3|...`, `init|build=ML|...` and `SYNCING->ACTIVE|...`, then no `alerts sent|...` line in the service's journal from the deinit to 120 s after that exit, a window clear of a TG-15 slot, and nothing received in the chat over it. Then a parameter change (reason 5): one restarted message, `alerts sent|...|class=S2+S1|http=200|...`, so the channel ran across the window and the hold and merge stand for the other in place reasons.
- ML-L18. ML-35 (1) in a loss lock: during the DAILY_BREACH of ML-L10, a chart timeframe change: `deinit|reason=3|...`, `init|build=ML|...` and `SYNCING->LOCKED|boot derivation: DAILY_BREACH|...`, then no `alerts sent|...` line over the same window and nothing received: no S2, no S16 and no merged message.
- ML-L19. ML-35 (1) in a lockout: the chart timeframe change of ML-L5: its lines there, then no `alerts sent|...` line over the same window and nothing received: no S2 and no start message (ML-34).

Live rows, stage 2, after stage 1 closes: the live account's computer, by the installer from an export of the build commit (`scripts/export-release.ps1`), for the rows that need no lock (TG-10 (A), `LEDGER.md:533`). No lockout is engaged there.
- ML-I1. The installer's check 9 passes with 16 files, and both compiles finish with no errors.
- ML-I2. The attach gives `init|build=ML` and the mirror line of ML-D, and the panel shows its Manual Lockout button in the upper right corner.
- ML-I3. ML-L2 there: Back from the review, and a review left 60 timer ticks, with no engaged line.
- ML-I4. ML-L4's four refusals there, End of session not accepted.
- ML-I5. The panel unavailable in SYNCING right after the attach, the first part of ML-L16.

The release of ML-27 (A) waits for both stages.

## 9. Ruling sheet ML, ruled

RULED 2026-10-22 by the owner: ML-1 to ML-8 as given, and ML-9 to ML-27 option (A), with "(owner proposal)" removed from ML-10 and new texts for ML-11, ML-13 and ML-14, FINAL at `7d2bf10` (`LEDGER.md:581-608`). The options were drafted by the executor; each choice is the owner's. The options not chosen are kept for the record.

- ML-8. The posture after a close by the guardian during a lockout. Owner's ruling, as given: "The stricter governs. If the guardian closes a position during a Manual Lockout and that close locks the account to the next daily anchor, that lock applies." Drafted, and replaced by it: (A) accept, with the review stage stating it; (B) engage only while flat.
- ML-9. Ratify the reading that the lockout end is its own quantity bounded by ML-4 only, while Q1, THREE, FOUR, the clamp and the precedence ruling keep governing the loss lock's locked_until unchanged. Owner's choice: (A) "ratified". Not chosen: (B) not ratified, the plan returns. Element NINE and `LEDGER.md:375` stay with the breach snapshot, which judges the loss lock only.
- ML-10. Engaging while any lock holds. Owner's choice: (A) "only to extend, the end later than the current effective end, else refused". Not chosen: (B) any end, recorded, the later governs; (C) not while locked.
- ML-11. The ML-4 bound on an extension. Owner's choice: (A), as the owner worded it, "no engagement or extension can set an end past the next daily anchor". Drafted and replaced: (A) from the engagement that started the current lockout; (B) from each confirmation, with no bound on a chain.
- ML-12. Eligible states. Owner's choice: (A) "ACTIVE connected outside RESYNC, LOCKED for an extension, the panel unavailable in SYNCING, SAFE_HALT and while disconnected". Not chosen: (B) as (A), and also while disconnected, the end from the last server time.
- ML-13. Presets. Owner's choice: (A), as the owner worded it, "15 min, 30 min, 1 h, until the next daily anchor, custom whole minutes ending no later than the next daily anchor". Not chosen: (B) custom as hours and minutes; (C) (A) plus 2 h and 4 h.
- ML-14. End time entry. Owner's choice: (A), as the owner worded it, "HH:MM server time, the first such instant after now, refused if under 60 s from now or past the next daily anchor". Not chosen: (B) a full date and time; (C) both.
- ML-15. Confirmation. Owner's choice: (A) "review stage then one click on Lock, Back, self cancel after 60 s". Not chosen: (B) (A) plus a typed word; (C) (A) with Lock armed 3 s after the review opens.
- ML-16. Remaining time. Owner's choice: (A) "panel line plus banner reason and effective end". Not chosen: (B) banner only; (C) panel only.
- ML-17. Telegram. Owner's choice: (A) "S5 "Locked on demand" at engage and a new code at the lockout's own end (released or locked again), S4, S8, S16 never describe a lockout, drafts in F1 to F11 added to addendum item 13 first, the service deploys first (F5)". Not chosen: (B) S5 only; (C) no new code, only the producer's gating and the effective end in the snapshot.
- ML-18. Persistence. Owner's choice: (A) "own record and GV, record checked at the LIFE cadence while a lockout holds and rewritten if missing or different, SPEC 3's single lock file sentence amended". Not chosen: (B) as (A) without the check.
- ML-19. A corrupt or login mismatched record at load. Owner's choice: (A) "quarantine, WARN, S17, the GV alone decides, none without it". Not chosen: (B) as (A), and with no valid GV a lockout to the next day anchor.
- ML-20. The residual, the record and the GV deleted by hand with the EA stopped. Owner's choice: (A) "accepted friction in SPEC 7 beside the file plus GV residual". Not chosen: (B) a third copy under FILE_COMMON.
- ML-21. Journal and ALERT shapes. Owner's choice: (A) "as listed", the list of section 4.7. Not chosen: (B) the engage ALERT carrying the day's pnl and limit.
- ML-22. Panel language. Owner's choice: (A) "English like the banner, EA stays ASCII". Not chosen: (B) Hebrew, its rendering on a chart object unverified.
- ML-23. Code layout. Owner's choice: (A) "`ManualLockout.mqh` and `LockoutPanel.mqh`, manifest and export regenerated, vectors include the first". Not chosen: (B) one include; (C) all in the EA.
- ML-24. Build label. Owner's choice: (A) "`ML`, the service too when it changes". Not chosen: (B) `MANUAL`.
- ML-25. Deploy and venue. Owner's choice: (A) "`scripts/deploy-ml.ps1` under the 2026-09-06 shape, the ruling extended to name it, service first, demo terminal first as TG-10 (A)". Not chosen: (B) live first.
- ML-26. SPEC and README. Owner's choice: (A) "amended in the build session under the ruling, README Hebrew only, never naming the ledger". Not chosen: (B) a later docs pass.
- ML-27. The customer release. Owner's choice: (A) "the feature ships in the release repository after its acceptance closes, the README gaining Hebrew panel steps, IN-22 (b) secrecy over the new files". Not chosen: (B) owner copy only.

## 10. Tradovate comparison

Mirrored where Tradovate documents its behavior: the flow, choose a duration and then Lock Account; the five presets by their Tradovate names, 15 minutes, 30 minutes, 1 hour, End of session and Custom; the account shown before the lock; positions flattened and working orders deleted at the lock; no early cancel; one timer per account.

Differences, each from a ruling or a FINAL entry that stands:
1. Length: Tradovate allows up to 24 hours; here a lockout ends no later than the next daily anchor, 01:00 server (ML-4, ML-11, ML-13).
2. End of session: Tradovate's ends its trading session; here it ends at the next daily anchor (ML-13).
3. An end time: Tradovate documents durations only; here the trader can also enter an HH:MM server time (ML-5, ML-14).
4. Confirmation: Tradovate documents the Lock Account click after the choice; here a review stage comes between, with Back and a 60 tick self cancel (ML-15).
5. New orders: Tradovate rejects them server side on every platform; here a new trade opens and the sweep closes it within seconds, at the spread (`LEDGER.md:193`, ENF-1(b), ENF-2(a)).
6. Where it runs: Tradovate's lock is server side; here it is enforced only while the terminal runs the EA, restored from its record at a restart, and kill equivalent while down (SPEC 7).
7. After a close: Tradovate's lockout ends at its time; here a close by the guardian during the lockout holds the account to the next daily anchor (ML-8).
8. Override: Tradovate refers an early release to the evaluation provider; here there is none (ML-2), and the hand deletion of the record and the mirror with the EA stopped is an accepted residual for a lockout that closed nothing (ML-20).
9. Extension: Tradovate's documentation does not mention one; here a lockout can be extended to a later end within the same server day (ML-10, ML-11).
10. Access: Tradovate on web, desktop and the mobile drawer; here only on the chart the EA runs on (section 5.1).
11. Scope: Tradovate locks one account, or every account of a user in its older form; here one guarded account.
12. Accounts: Tradovate offers the lockout on evaluation accounts; here on any account the EA guards.
13. Clock: Tradovate's documentation names no time zone for the lockout; here every time is server time (Q7).
14. Notice: Tradovate's documentation names none; here Telegram S5 and S25 (ML-17).
15. Flatten speed: Tradovate flattens at once as documented; here one send per timer pass, positions first (ENF-4(c), ENF-31).
16. The loss limits keep applying (ML-7, R10); a search summary of the unreadable support article says Tradovate's lockout overrides active risk settings.
17. The entry's name: Tradovate's option is called Lockout; here the button reads Manual Lockout, the name of ML-1 and of Tradovate's own announcement.

## 11. Build section, for a lighter executor

UNRULED 2026-10-22 until the owner's build instruction adopts this section; the marker covers no ML item. It covers what the executor chose to carry out ML-1 to ML-37: the names, the constants, the record format, the journal and ALERT wording inside the shapes of section 4.7, the Hebrew drafts and the code below. Every behavior the code implements is ruled and cited in sections 4 to 7. The four readings section 12 raised as points 3 to 6 are ruled by ML-30 to ML-33, and the code follows them: S5 at the engagement only (B5.11 (b) and (d), B6, B7), the open trades line left out of S5 (B6, the helper of B10), S8 alone when both locks end on one tick (B5.11), and no journal line for a click on the greyed Extend (B3). The two gaps ML-30 left are ruled by ML-34 (A) and ML-35 (2), which the code follows as written: no start message for a start into a lockout alone, and an in place stop before it sent alone after the hold. ML-35 (1), the reason 3 silence, is carried by B1, B5.3, B5.11, B5.17, B7, B9, B11 and B13. ML-37, which keeps S3 out of that silence unless the same SAFE_HALT was already announced, is carried by B1, B5.3, B5.9, B5.11, B5.17, B9 and B11.

### 11.1 How to read a step

Each step names the file, the place (a function, or an anchor line), the exact change and the check that closes it. "Replace" gives the old text exactly as it stands at `cce862a` and the new text; the old text occurs once in the file unless the step says otherwise. "Insert before" and "insert after" give an exact anchor. A code block is the text to write, character for character: ASCII, except the Hebrew string literals of B4 and the drafts of B7, which are UTF-8. Indentation is the files' own, three spaces. Byte order marks: the EA and `AlertText.mqh` carry one and keep it; every other source has none, the two new includes none. Line ends: the repository normalizes text files (`.gitattributes` `* text=auto`, LF in git, CRLF in a Windows working tree), so a file may be written with either; `README.md` alone is also read in the working tree by IN-S6, which needs its CR count equal to its LF count.

Rules for the whole build:
1. Work on branch `feature/manual-lockout`, at the commit that carries this plan's ledger entry, in the worktree the owner's build instruction names.
2. Commit after each step with the message the step gives, written to a file and passed with `git commit -F`, with no trailer of any kind.
3. Write, move or delete nothing under any terminal data folder (RULE A, `LEDGER.md:159`); a read there is a plain read only cmdlet under RULE B, and the build itself needs none. The owner runs `scripts/deploy-ml.ps1` and every live row. Compiling through `scripts/rows/compile.py` is allowed (ML-29). The one `Compile` line MetaEditor appends per compile to `logs\metaeditor.log` of the data folder `D0E8209F77C8CF37AD8BF550E51FF075`, whatever `/log` names (`docs/evidence/tg-b5.md:76`), is an accepted side effect, stated in every compile report. No other write there. ML-29 is a narrow exception for that one compile log line; RULE A and its wording stay as they are (ML-36).
4. Stop at the first compile error, failed check or old text not found: report the step and the exact output, and change nothing further. A typo that changes no behavior may be fixed and reported; anything else waits for the owner.
5. Run the steps in order and skip none. B12 runs again after any later change to a shipped file.
6. Comments follow the repository's style rules: no em dash, no hyphen used as a separator, and in a shipped file none of the patterns of `scripts/secrecy-patterns.txt`, the two words "owner ruling" side by side included. Comments cite "rulings ML-1 to ML-27" or an ML number. No comment names a trade API word of the TG-S2 pattern (`OrderSend`, `CTrade`, `PositionClose`, `OrderDelete`, `Trade.mqh`, `TRADE_ACTION_`), since that row reads comments too.

### B0. Preconditions

- File: none. Change: none.
- Check: `git rev-parse --abbrev-ref HEAD` prints `feature/manual-lockout`; `git status --porcelain` prints nothing; `git diff --name-only cce862a HEAD` prints exactly two lines, `LEDGER.md` and `docs/PLAN_MANUAL_LOCKOUT_2026-10-22.md`, so no source, script, vector or installer file has changed since the base; `git log --oneline --reverse cce862a..HEAD` lists ten commits and no merge, the first seven `7d2bf10`, `be15da2`, `7740b3f`, `bcb71cc`, `e1a931a`, `2f0282b` and `eddfc99`, then three whose subjects begin `ledger:`, `docs:` and `ledger:`, the last of them HEAD, which carries this plan's ledger entry, and the one before it the commit that last changed this plan (`git log -1 --format=%H -- docs/PLAN_MANUAL_LOCKOUT_2026-10-22.md` equals `git rev-parse HEAD~1`); `LEDGER.md` is read in full; the owner's build instruction is quoted verbatim in the session's first report.

### B1. AlertQueue.mqh: the codes S5 and S25, the reason 3 silence, and its S3 under ML-37

File `MQL5/Include/AccountGuardian/AlertQueue.mqh`; the code defines (`AlertQueue.mqh:31-51`), `AgTgCodeKnown` (`:128-141`) and the comment line after it (`:143`).

Replace
```
#define AG_TG_S4    4
```
with
```
#define AG_TG_S4    4
#define AG_TG_S5    5    // Manual Lockout engaged, at the engagement only (ML-17 (A), ML-30)
```
Replace
```
#define AG_TG_S24   24
```
with
```
#define AG_TG_S24   24
#define AG_TG_S25   25   // Manual Lockout's own end, released or locked again (ML-17 (A))
```
Replace
```
      case AG_TG_S6F:
         return true;
```
with
```
      case AG_TG_S6F: case AG_TG_S5:  case AG_TG_S25:
         return true;
```
Replace
```
//--- digits only, with an optional leading minus
```
with
```
//--- ML-35 (1): the deinit reasons that send no Telegram message of their
//--- own, no stop, no start and no merged restart message: a chart timeframe
//--- or symbol change, reason 3, alone. The EA, the service and the vectors
//--- share this one definition.
bool AgTgSilentReason(const int reason) { return reason == REASON_CHARTCHANGE; }

//--- ML-37: after such a change, S3 is silenced only for the same SAFE_HALT
//--- an S3 already announced, known by its halt time on record; a SAFE_HALT
//--- new at that init, or no halt time on record (0), always sends S3
bool AgTgS3Silenced(const bool quiet_start, const datetime announced, const datetime halt_time)
  {
   return quiet_start && announced != 0 && announced == halt_time;
  }

//--- ML-37: the halt time, x[1], of the last S3 among the events, or none
//--- when no S3 is among them; the EA reads it over the events a successful
//--- queue write carried
datetime AgTgS3HaltTimeIn(const AgTgEvent &events[], const int count, const datetime none)
  {
   datetime t = none;
   for(int i = 0; i < count; i++)
      if(events[i].code == AG_TG_S3)
         t = (datetime)(long)events[i].x[1];
   return t;
  }

//--- digits only, with an optional leading minus
```
- Check: each new define occurs once; `AgTgCodeKnown` names both; `AgTgSilentReason`, `AgTgS3Silenced` and `AgTgS3HaltTimeIn` are defined once each; the compiles of B5 and B7 pass.
- Commit: `queue: event codes S5 and S25 of the Manual Lockout, known to the parser, AgTgSilentReason for ML-35 (1), and AgTgS3Silenced and AgTgS3HaltTimeIn for ML-37`

### B2. ManualLockout.mqh, new

File `MQL5/Include/AccountGuardian/ManualLockout.mqh`, new, no byte order mark, this text:

```
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
```

- Check: the file is ASCII with no byte order mark; it names none of `TimeLocal`, `TimeGMT`, `TimeTradeServer`, `GetTickCount` (ML-S8); it compiles inside the EA at B5 and inside the vectors at B10.
- Commit: `include: ManualLockout.mqh, the Manual Lockout model, record, bounds, parsers and line formats`

### B3. LockoutPanel.mqh, new

File `MQL5/Include/AccountGuardian/LockoutPanel.mqh`, new, no byte order mark. The layout, in pixels from the chart's right edge to each object's left edge (x) and from the top (y), the panel 320 wide:

| Object | Type | Text | x | y | w x h | Shown in |
|---|---|---|---|---|---|---|
| BG | rectangle label | | 332 | 24 | 320 x stage | every stage but IDLE |
| TITLE | label | stage text | 326 | 30 | | CHOOSE, WAIT, UNAVAILABLE |
| OPEN | button | `Manual Lockout`, `Extend` while LOCKED | 162 | 24, 94 while LOCKED | 150 x 22 | IDLE, LOCKED |
| P15, P30 | button | `15 minutes`, `30 minutes` | 326, 170 | 52 | 150 x 22 | CHOOSE |
| P60, PEOD | button | `1 hour`, `End of session` | 326, 170 | 78 | 150 x 22 | CHOOSE |
| CUST_L, CUST_E, CUST_B | label, edit, button | `Custom minutes:`, empty, `Custom` | 326, 170, 96 | 108, 104, 104 | edit 70 x 22, button 78 x 22 | CHOOSE |
| TIME_L, TIME_E, TIME_B | label, edit, button | `End time HH:MM server:`, empty, `End time` | 326, 170, 96 | 138, 134, 134 | as above | CHOOSE |
| CLOSE | button | `Close` | 170 | 164 | 150 x 22 | CHOOSE |
| L1 to L6 | label | review or lock lines | 326 | 30, 48, 66, 84, 102, 120 | | REVIEW (all), LOCKED (L1, L2) |
| LOCK, BACK | button | `Lock Account`, `Back` | 326, 170 | 146 | 150 x 24 | REVIEW |
| NOTE | label | the last refusal or time out | 326 | below the panel | | while a note stands |

The stage heights of BG: CHOOSE 196, REVIEW 176, LOCKED 100, WAIT and UNAVAILABLE 28.

```
//+------------------------------------------------------------------+
//| AccountGuardian - LockoutPanel.mqh                               |
//| The Manual Lockout panel, rulings ML-1 to ML-27 of 2026-10-22:   |
//| chart objects on the EA's own chart, in the upper right corner,  |
//| clear of the banner in the upper left. ITS ONLY WRITES ARE CHART |
//| OBJECTS AND ITS OWN g_ag_panel_ GLOBALS. It decides nothing for  |
//| the guardian: Lock Account records one request, and the EA       |
//| applies it in OnTimer (F13). No file, no GV, no transition, no   |
//| sweep call, no trade call. English text, ASCII source (ML-22).   |
//| The synchronous chart reads, ObjectFind, ObjectGetString and     |
//| ObjectGetInteger, run in OnInit and OnChartEvent only; OnTimer   |
//| reaches AgPanelRefresh, which sets properties and reads none.    |
//+------------------------------------------------------------------+
#ifndef AG_LOCKOUT_PANEL_MQH
#define AG_LOCKOUT_PANEL_MQH

#include <AccountGuardian/ManualLockout.mqh>

#define AG_PANEL_PREFIX      "AG_ML_"
#define AG_PANEL_TOP         24
#define AG_PANEL_WIDTH       320
#define AG_PANEL_FONT        "Arial"
#define AG_PANEL_FONT_SIZE   9
#define AG_PANEL_PART_COUNT  23

#define AG_PANEL_IDLE         0
#define AG_PANEL_CHOOSE       1
#define AG_PANEL_REVIEW       2
#define AG_PANEL_WAIT         3
#define AG_PANEL_LOCKED       4
#define AG_PANEL_UNAVAILABLE  5

//--- the one request Lock Account records; the EA applies it in OnTimer
struct AgManualRequest
  {
   bool     pending;
   int      form;
   int      minutes;
   datetime clicked;   // AgServerNow at the click, the confirmation instant (ML-5)
   datetime end;
  };

AgManualRequest g_ag_panel_request;
bool     g_ag_panel_created      = false;
int      g_ag_panel_stage        = AG_PANEL_IDLE;
int      g_ag_panel_drawn_stage  = -1;
bool     g_ag_panel_note_shown   = false;
int      g_ag_panel_form         = AG_ML_FORM_NONE;
int      g_ag_panel_minutes      = 0;
int      g_ag_panel_hh           = 0;
int      g_ag_panel_mm           = 0;
int      g_ag_panel_review_ticks = 0;
string   g_ag_panel_note         = "";
//--- what the last AgPanelRefresh said, read by the render and the clicks
long     g_ag_panel_login        = 0;
datetime g_ag_panel_current_end  = 0;     // the effective end while LOCKED, else 0
string   g_ag_panel_governing    = "";    // MANUAL_LOCKOUT, or the loss lock reason name
bool     g_ag_panel_can_extend   = false;
string   g_ag_panel_extend_why   = "";
string   g_ag_panel_why          = "";
int      g_ag_panel_positions    = 0;
int      g_ag_panel_pendings     = 0;

string g_ag_panel_parts[AG_PANEL_PART_COUNT] =
  {
   "BG", "TITLE", "OPEN", "P15", "P30", "P60", "PEOD", "CUST_L", "CUST_E", "CUST_B", "TIME_L", "TIME_E",
   "TIME_B", "CLOSE", "L1", "L2", "L3", "L4", "L5", "L6", "LOCK", "BACK", "NOTE"
  };

string AgPanelName(const string part) { return AG_PANEL_PREFIX + part; }

//--- one object, created hidden; x is the distance from the chart's right
//--- edge to the object's left edge, the anchor rule of the right upper
//--- corner. The text is set only when the object is new, so a field the
//--- trader is typing in is never written over.
void AgPanelMake(const string part, const ENUM_OBJECT type, const int x, const int y,
                 const int w, const int h, const string text)
  {
   string name  = AgPanelName(part);
   bool   fresh = (ObjectFind(0, name) < 0);
   if(fresh)
      ObjectCreate(0, name, type, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   if(type != OBJ_LABEL)
     {
      ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
     }
   else
      ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 10);
   ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
   if(type == OBJ_RECTANGLE_LABEL)
     {
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, C'32,32,32');
      ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrDimGray);
      return;
     }
   ObjectSetString(0, name, OBJPROP_FONT, AG_PANEL_FONT);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, AG_PANEL_FONT_SIZE);
   ObjectSetInteger(0, name, OBJPROP_COLOR, (type == OBJ_EDIT) ? clrBlack : clrWhite);
   if(fresh)
      ObjectSetString(0, name, OBJPROP_TEXT, text);
   if(type == OBJ_BUTTON)
     {
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, C'70,70,70');
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrDimGray);
      ObjectSetInteger(0, name, OBJPROP_STATE, false);
     }
   if(type == OBJ_EDIT)
     {
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrWhite);
      ObjectSetInteger(0, name, OBJPROP_READONLY, false);
      ObjectSetInteger(0, name, OBJPROP_ALIGN, ALIGN_CENTER);
     }
  }

//--- every object, hidden until the next render; run again on a deletion,
//--- so a panel deleted from the object list comes back at once
void AgPanelCreate()
  {
   ChartSetInteger(0, CHART_EVENT_OBJECT_DELETE, true);
   AgPanelMake("BG",     OBJ_RECTANGLE_LABEL, 332, AG_PANEL_TOP, AG_PANEL_WIDTH, 28, "");
   AgPanelMake("TITLE",  OBJ_LABEL,  326,  30,   0,  0, " ");
   AgPanelMake("OPEN",   OBJ_BUTTON, 162,  24, 150, 22, "Manual Lockout");
   AgPanelMake("P15",    OBJ_BUTTON, 326,  52, 150, 22, "15 minutes");
   AgPanelMake("P30",    OBJ_BUTTON, 170,  52, 150, 22, "30 minutes");
   AgPanelMake("P60",    OBJ_BUTTON, 326,  78, 150, 22, "1 hour");
   AgPanelMake("PEOD",   OBJ_BUTTON, 170,  78, 150, 22, "End of session");
   AgPanelMake("CUST_L", OBJ_LABEL,  326, 108,   0,  0, "Custom minutes:");
   AgPanelMake("CUST_E", OBJ_EDIT,   170, 104,  70, 22, "");
   AgPanelMake("CUST_B", OBJ_BUTTON,  96, 104,  78, 22, "Custom");
   AgPanelMake("TIME_L", OBJ_LABEL,  326, 138,   0,  0, "End time HH:MM server:");
   AgPanelMake("TIME_E", OBJ_EDIT,   170, 134,  70, 22, "");
   AgPanelMake("TIME_B", OBJ_BUTTON,  96, 134,  78, 22, "End time");
   AgPanelMake("CLOSE",  OBJ_BUTTON, 170, 164, 150, 22, "Close");
   AgPanelMake("L1",     OBJ_LABEL,  326,  30,   0,  0, " ");
   AgPanelMake("L2",     OBJ_LABEL,  326,  48,   0,  0, " ");
   AgPanelMake("L3",     OBJ_LABEL,  326,  66,   0,  0, " ");
   AgPanelMake("L4",     OBJ_LABEL,  326,  84,   0,  0, " ");
   AgPanelMake("L5",     OBJ_LABEL,  326, 102,   0,  0, " ");
   AgPanelMake("L6",     OBJ_LABEL,  326, 120,   0,  0, " ");
   AgPanelMake("LOCK",   OBJ_BUTTON, 326, 146, 150, 24, "Lock Account");
   AgPanelMake("BACK",   OBJ_BUTTON, 170, 146, 150, 24, "Back");
   AgPanelMake("NOTE",   OBJ_LABEL,  326,  54,   0,  0, " ");
   ObjectSetInteger(0, AgPanelName("LOCK"), OBJPROP_BGCOLOR, clrFireBrick);
   g_ag_panel_created     = true;
   g_ag_panel_drawn_stage = -1;   // the next render sets every visibility
   g_ag_panel_note_shown  = false;
  }

//--- OnDeinit: the panel's own objects, by prefix, and nothing else
void AgPanelDelete()
  {
   if(!g_ag_panel_created)
      return;
   g_ag_panel_created = false;   // first, so the delete events recreate nothing
   ObjectsDeleteAll(0, AG_PANEL_PREFIX);
   ChartRedraw(0);
  }

//--- OnInit: an in place re-init keeps every global, so the stage and any
//--- request start afresh here; a request never crosses an init
void AgPanelInitReset()
  {
   g_ag_panel_request.pending = false;
   g_ag_panel_request.form    = AG_ML_FORM_NONE;
   g_ag_panel_request.minutes = 0;
   g_ag_panel_request.clicked = 0;
   g_ag_panel_request.end     = 0;
   g_ag_panel_stage        = AG_PANEL_IDLE;
   g_ag_panel_drawn_stage  = -1;
   g_ag_panel_note_shown   = false;
   g_ag_panel_form         = AG_ML_FORM_NONE;
   g_ag_panel_minutes      = 0;
   g_ag_panel_hh           = 0;
   g_ag_panel_mm           = 0;
   g_ag_panel_review_ticks = 0;
   g_ag_panel_note         = "";
   g_ag_panel_login        = 0;
   g_ag_panel_current_end  = 0;
   g_ag_panel_governing    = "";
   g_ag_panel_can_extend   = false;
   g_ag_panel_extend_why   = "";
   g_ag_panel_why          = "";
   g_ag_panel_positions    = 0;
   g_ag_panel_pendings     = 0;
  }

bool AgPanelShown(const string part, const int stage)
  {
   if(stage == AG_PANEL_IDLE)
      return part == "OPEN";
   if(stage == AG_PANEL_CHOOSE)
      return part == "BG" || part == "TITLE" || part == "P15" || part == "P30" || part == "P60"
          || part == "PEOD" || part == "CUST_L" || part == "CUST_E" || part == "CUST_B"
          || part == "TIME_L" || part == "TIME_E" || part == "TIME_B" || part == "CLOSE";
   if(stage == AG_PANEL_REVIEW)
      return part == "BG" || part == "L1" || part == "L2" || part == "L3" || part == "L4"
          || part == "L5" || part == "L6" || part == "LOCK" || part == "BACK";
   if(stage == AG_PANEL_LOCKED)
      return part == "BG" || part == "L1" || part == "L2" || part == "OPEN";
   return part == "BG" || part == "TITLE";   // WAIT and UNAVAILABLE
  }

int AgPanelHeight(const int stage)
  {
   if(stage == AG_PANEL_CHOOSE)
      return 196;
   if(stage == AG_PANEL_REVIEW)
      return 176;
   if(stage == AG_PANEL_LOCKED)
      return 100;
   return 28;
  }

//--- a label's text; an empty label would show the word Label, so a space
void AgPanelText(const string part, const string text)
  {
   ObjectSetString(0, AgPanelName(part), OBJPROP_TEXT, (text == "") ? " " : text);
  }

//--- a button greyed when a click on it would be refused
void AgPanelEnabled(const string part, const bool enabled)
  {
   ObjectSetInteger(0, AgPanelName(part), OBJPROP_COLOR, enabled ? clrWhite : clrGray);
  }

bool AgPanelAllowed(const int form, const int minutes, const datetime now)
  {
   datetime end = AgManualEndFor(now, form, minutes, 0, 0);
   return AgManualCheckEnd(now, end, form, g_ag_panel_current_end) == AG_ML_OK;
  }

//--- every property from the panel's own globals; sets, never reads
void AgPanelRender(const datetime now)
  {
   if(!g_ag_panel_created)
      return;
   int stage = g_ag_panel_stage;
   if(stage != g_ag_panel_drawn_stage)
     {
      for(int i = 0; i < AG_PANEL_PART_COUNT; i++)
         if(g_ag_panel_parts[i] != "NOTE")
            ObjectSetInteger(0, AgPanelName(g_ag_panel_parts[i]), OBJPROP_TIMEFRAMES,
                             AgPanelShown(g_ag_panel_parts[i], stage) ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS);
      ObjectSetInteger(0, AgPanelName("BG"), OBJPROP_YSIZE, AgPanelHeight(stage));
      ObjectSetInteger(0, AgPanelName("OPEN"), OBJPROP_YDISTANCE, (stage == AG_PANEL_LOCKED) ? 94 : AG_PANEL_TOP);
      ObjectSetInteger(0, AgPanelName("NOTE"), OBJPROP_YDISTANCE,
                       AG_PANEL_TOP + ((stage == AG_PANEL_IDLE) ? 26 : AgPanelHeight(stage)) + 4);
      g_ag_panel_drawn_stage = stage;
     }
   datetime anchor = AgNextDayAnchor(now);
   if(stage == AG_PANEL_IDLE)
     {
      AgPanelText("OPEN", "Manual Lockout");
      AgPanelEnabled("OPEN", true);
     }
   else if(stage == AG_PANEL_CHOOSE)
     {
      AgPanelText("TITLE", (g_ag_panel_current_end > 0) ? "Extend: choose a later end"
                                                        : "Manual Lockout: choose the end");
      AgPanelEnabled("P15", AgPanelAllowed(AG_ML_FORM_DURATION, 15, now));
      AgPanelEnabled("P30", AgPanelAllowed(AG_ML_FORM_DURATION, 30, now));
      AgPanelEnabled("P60", AgPanelAllowed(AG_ML_FORM_DURATION, 60, now));
      AgPanelEnabled("PEOD", AgPanelAllowed(AG_ML_FORM_END_OF_DAY, 0, now));
     }
   else if(stage == AG_PANEL_REVIEW)
     {
      datetime end = AgManualEndFor(now, g_ag_panel_form, g_ag_panel_minutes, g_ag_panel_hh, g_ag_panel_mm);
      AgPanelText("L1", "Account " + (string)g_ag_panel_login);
      AgPanelText("L2", "Lock until " + AgManualStamp(end) + " server");
      AgPanelText("L3", "Length " + AgManualHms((long)(end - now)) + " from now");
      AgPanelText("L4", "Open positions " + (string)g_ag_panel_positions + ", pending orders "
                  + (string)g_ag_panel_pendings);
      AgPanelText("L5", "This lockout cannot be cancelled or shortened.");
      AgPanelText("L6", (end < anchor) ? "A close by the guardian locks until " + AgManualStamp(anchor) : "");
     }
   else if(stage == AG_PANEL_WAIT)
      AgPanelText("TITLE", "Locking...");
   else if(stage == AG_PANEL_LOCKED)
     {
      if(g_ag_panel_governing == AG_MANUAL_REASON_NAME)
         AgPanelText("L1", "Manual Lockout until " + AgManualStamp(g_ag_panel_current_end) + " server");
      else
         AgPanelText("L1", "Locked until " + AgManualStamp(g_ag_panel_current_end) + " server ("
                     + g_ag_panel_governing + ")");
      AgPanelText("L2", AgManualHms((long)(g_ag_panel_current_end - now)) + " left");
      AgPanelText("OPEN", "Extend");
      AgPanelEnabled("OPEN", g_ag_panel_can_extend);
     }
   else
      AgPanelText("TITLE", "Manual Lockout unavailable: " + g_ag_panel_why);
   bool note = (g_ag_panel_note != "");
   AgPanelText("NOTE", g_ag_panel_note);
   if(note != g_ag_panel_note_shown)
     {
      ObjectSetInteger(0, AgPanelName("NOTE"), OBJPROP_TIMEFRAMES, note ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS);
      g_ag_panel_note_shown = note;
     }
   ChartRedraw(0);
  }

void AgPanelRefuse(const string why, const int form, const datetime end, const datetime now)
  {
   g_ag_panel_note = "Refused: " + why;
   AgInfo(AgManualRefusedLine(why, "panel", "-", form, end, now));
  }

//--- a preset, a custom number or an end time chosen: checked now, then the
//--- review (ML-15), whose end moves with the clock until Lock Account
void AgPanelChoose(const int form, const int minutes, const int hh, const int mm, const datetime now)
  {
   datetime end     = AgManualEndFor(now, form, minutes, hh, mm);
   int      outcome = AgManualCheckEnd(now, end, form, g_ag_panel_current_end);
   if(outcome != AG_ML_OK)
     {
      AgPanelRefuse(AgManualRefuseName(outcome), form, end, now);
      return;
     }
   g_ag_panel_form         = form;
   g_ag_panel_minutes      = minutes;
   g_ag_panel_hh           = hh;
   g_ag_panel_mm           = mm;
   g_ag_panel_review_ticks = 0;
   g_ag_panel_note         = "";
   g_ag_panel_stage        = AG_PANEL_REVIEW;
   AgInfo(AgManualPanelLine("review", form, end, now));
  }

//--- OnChartEvent. Stage changes, and on Lock Account the one request
void AgPanelOnEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(!g_ag_panel_created)
      return;
   if(id == CHARTEVENT_OBJECT_DELETE)
     {
      if(StringFind(sparam, AG_PANEL_PREFIX) == 0)
         AgPanelCreate();
      return;
     }
   if(id != CHARTEVENT_OBJECT_CLICK || StringFind(sparam, AG_PANEL_PREFIX) != 0)
      return;
   if((ENUM_OBJECT)ObjectGetInteger(0, sparam, OBJPROP_TYPE) == OBJ_BUTTON)
      ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
   string   part  = StringSubstr(sparam, StringLen(AG_PANEL_PREFIX));
   datetime now   = AgServerNow();
   int      stage = g_ag_panel_stage;
   if(stage == AG_PANEL_IDLE && part == "OPEN")
     {
      g_ag_panel_note  = "";
      g_ag_panel_stage = AG_PANEL_CHOOSE;
     }
   else if(stage == AG_PANEL_LOCKED && part == "OPEN")
     {
      if(g_ag_panel_can_extend)
        {
         g_ag_panel_note  = "";
         g_ag_panel_stage = AG_PANEL_CHOOSE;
        }
      else
         g_ag_panel_note = "Refused: " + g_ag_panel_extend_why;   // ML-33: the note only, no journal line
     }
   else if(stage == AG_PANEL_CHOOSE)
     {
      if(part == "P15")
         AgPanelChoose(AG_ML_FORM_DURATION, 15, 0, 0, now);
      else if(part == "P30")
         AgPanelChoose(AG_ML_FORM_DURATION, 30, 0, 0, now);
      else if(part == "P60")
         AgPanelChoose(AG_ML_FORM_DURATION, 60, 0, 0, now);
      else if(part == "PEOD")
         AgPanelChoose(AG_ML_FORM_END_OF_DAY, 0, 0, 0, now);
      else if(part == "CUST_B")
        {
         int minutes = 0;
         if(AgManualParseMinutes(ObjectGetString(0, AgPanelName("CUST_E"), OBJPROP_TEXT), minutes))
            AgPanelChoose(AG_ML_FORM_DURATION, minutes, 0, 0, now);
         else
            AgPanelRefuse(AgManualRefuseName(AG_ML_INPUT), AG_ML_FORM_DURATION, 0, now);
        }
      else if(part == "TIME_B")
        {
         int hh = 0;
         int mm = 0;
         if(AgManualParseHhMm(ObjectGetString(0, AgPanelName("TIME_E"), OBJPROP_TEXT), hh, mm))
            AgPanelChoose(AG_ML_FORM_END_TIME, 0, hh, mm, now);
         else
            AgPanelRefuse(AgManualRefuseName(AG_ML_INPUT), AG_ML_FORM_END_TIME, 0, now);
        }
      else if(part == "CLOSE")
        {
         g_ag_panel_note  = "";
         g_ag_panel_stage = (g_ag_panel_current_end > 0) ? AG_PANEL_LOCKED : AG_PANEL_IDLE;
        }
     }
   else if(stage == AG_PANEL_REVIEW)
     {
      if(part == "BACK")
        {
         g_ag_panel_note  = "";
         g_ag_panel_stage = AG_PANEL_CHOOSE;
        }
      else if(part == "LOCK")
        {
         datetime end     = AgManualEndFor(now, g_ag_panel_form, g_ag_panel_minutes, g_ag_panel_hh, g_ag_panel_mm);
         int      outcome = AgManualCheckEnd(now, end, g_ag_panel_form, g_ag_panel_current_end);
         if(outcome != AG_ML_OK)
           {
            AgPanelRefuse(AgManualRefuseName(outcome), g_ag_panel_form, end, now);
            g_ag_panel_stage = AG_PANEL_CHOOSE;
           }
         else
           {
            g_ag_panel_request.pending = true;
            g_ag_panel_request.form    = g_ag_panel_form;
            g_ag_panel_request.minutes = (g_ag_panel_form == AG_ML_FORM_DURATION) ? g_ag_panel_minutes : 0;
            g_ag_panel_request.clicked = now;
            g_ag_panel_request.end     = end;
            AgInfo(AgManualPanelLine("lock account clicked", g_ag_panel_form, end, now));
            g_ag_panel_note  = "";
            g_ag_panel_stage = AG_PANEL_WAIT;
           }
        }
     }
   AgPanelRender(now);
  }

//--- OnTimer, every tick after the banner: what the guardian allows now
//--- (ML-12), the review's self cancel after 60 ticks (ML-15), the render
void AgPanelRefresh(const long login, const bool eligible, const string why, const bool locked,
                    const datetime current_end, const string governing, const bool can_extend,
                    const string extend_why, const int positions, const int pendings, const datetime now)
  {
   if(!g_ag_panel_created)
      return;
   g_ag_panel_login       = login;
   g_ag_panel_current_end = locked ? current_end : (datetime)0;
   g_ag_panel_governing   = governing;
   g_ag_panel_can_extend  = can_extend;
   g_ag_panel_extend_why  = extend_why;
   g_ag_panel_why         = why;
   g_ag_panel_positions   = positions;
   g_ag_panel_pendings    = pendings;
   if(g_ag_panel_stage != AG_PANEL_WAIT)
     {
      if(locked)
        {
         if((g_ag_panel_stage != AG_PANEL_CHOOSE && g_ag_panel_stage != AG_PANEL_REVIEW) || !can_extend)
            g_ag_panel_stage = AG_PANEL_LOCKED;
        }
      else if(!eligible)
         g_ag_panel_stage = AG_PANEL_UNAVAILABLE;
      else if(g_ag_panel_stage == AG_PANEL_LOCKED || g_ag_panel_stage == AG_PANEL_UNAVAILABLE)
         g_ag_panel_stage = AG_PANEL_IDLE;
     }
   if(g_ag_panel_stage == AG_PANEL_REVIEW)
     {
      g_ag_panel_review_ticks++;
      if(g_ag_panel_review_ticks >= AG_MANUAL_REVIEW_TICKS)
        {
         g_ag_panel_stage = locked ? AG_PANEL_LOCKED : AG_PANEL_IDLE;
         g_ag_panel_note  = "Review timed out";
         AgInfo(AgManualPanelTimedOutLine(now));
        }
     }
   AgPanelRender(now);
  }

//--- the EA's answer to the request, from OnTimer; the next refresh draws it
void AgPanelApplied(const bool ok, const string why)
  {
   g_ag_panel_note  = ok ? "" : "Refused: " + why;
   g_ag_panel_stage = ok ? AG_PANEL_LOCKED : AG_PANEL_CHOOSE;
  }

#endif // AG_LOCKOUT_PANEL_MQH
```

- Check: ASCII, no byte order mark; no `TimeLocal`, `TimeGMT`, `TimeTradeServer` or `GetTickCount` (ML-S8); no file, GV, transition, record write, sweep or trade name, and every assignment to a `g_ag_` global names a `g_ag_panel_` one (ML-S11); compiles inside the EA at B5.
- Commit: `include: LockoutPanel.mqh, the Manual Lockout panel on the EA's chart, chart objects only`

### B4. The Hebrew drafts, addendum item 13

File `docs/PLAN_TELEGRAM_ALERTS_ADDENDUM_TG1B.md`, UTF-8, its own line ends kept. ML-17 (A): the drafts are added to item 13 before any code renders them.

Replace, at the end of the paragraph `ADD:427`,
```
and figures taken under a lock carry the locked wording, now on the limit line.
```
with
```
and figures taken under a lock carry the locked wording, now on the limit line. The Manual Lockout build of 2026-10-22 (ML-17 (A)) adds, under labels that begin `ML:`, S5 at the engagement (ML-30), S25 at the lockout's own end, its wording list, and the S17 name of the lockout's record, in the format F1 to F11 with R3 and R4: S5 carries the sweep line and leaves the open trades line out, as S4 and S16 do (ML-31); S25 carries no sweep line and keeps it; the result line of a lockout alone reads not computed yet, there being no day result under it.
```
Insert after the line `🔐 מספר הנעילות ביום שהסתיים: 1` (`ADD:1410`, the last line of the block, just before its closing fence) one blank line and then this text:
```
=== ML: S5 Manual Lockout engaged, a position open ===
🔒 נעילה ידנית: החשבון ננעל לבקשתך

👤 מס׳ חשבון: 1200252169
🕒 זמן: 22/10/2026 14:30

💰 גודל תיק: 2,544.33
💵 הון: 2,530.10

⚙️ מגבלה יומית: 139.94
📉 סה״כ PNL: -14.23$

🛡️ מצב: נעול
⏳ נעול עד: 22/10/2026 15:00
⌛ משך: 30 דקות
🧹 סוגר עכשיו פוזיציה אחת
❗ אי אפשר לבטל או לקצר את הנעילה
ℹ️ השומר סוגר עכשיו את העסקאות הפתוחות, ולכן החשבון יישאר נעול עד תחילת יום המסחר הבא

=== ML: S5 Manual Lockout engaged, nothing open ===
🔒 נעילה ידנית: החשבון ננעל לבקשתך

👤 מס׳ חשבון: 1200252169
🕒 זמן: 22/10/2026 14:30

💰 גודל תיק: 2,544.33
💵 הון: 2,544.33

⚙️ מגבלה יומית: 139.94
📉 סה״כ PNL: 0.00$

🛡️ מצב: נעול
⏳ נעול עד: 22/10/2026 15:30
⌛ משך: 60 דקות
❗ אי אפשר לבטל או לקצר את הנעילה
ℹ️ אם השומר יסגור עסקה בזמן הנעילה, החשבון יישאר נעול עד תחילת יום המסחר הבא

=== ML: S5 Manual Lockout until the next daily anchor ===
🔒 נעילה ידנית: החשבון ננעל לבקשתך

👤 מס׳ חשבון: 1200252169
🕒 זמן: 22/10/2026 14:30

💰 גודל תיק: 2,544.33
💵 הון: 2,544.33

⚙️ מגבלה יומית: 139.94
📉 סה״כ PNL: 0.00$

🛡️ מצב: נעול
⏳ נעול עד: 23/10/2026 01:00
⌛ משך: 10 שעות ו 29 דקות
❗ אי אפשר לבטל או לקצר את הנעילה

=== ML: S25 Manual Lockout ended ===
🔓 הנעילה הידנית הסתיימה

👤 מס׳ חשבון: 1200252169
🕒 זמן: 22/10/2026 15:00

💰 גודל תיק: 2,544.33
💵 הון: 2,544.33
📂 עסקאות פתוחות: אין

⚙️ מגבלה יומית: 139.94
📉 סה״כ PNL: 0.00$

🛡️ מצב: פעיל
⏰ הנעילה הסתיימה בשעה 22/10/2026 15:00

=== ML: S25 Manual Lockout ended, the account stays locked ===
🔒 הנעילה הידנית הסתיימה, החשבון נשאר נעול

👤 מס׳ חשבון: 1200252169
🕒 זמן: 22/10/2026 15:00

💰 גודל תיק: 2,530.10
💵 הון: 2,530.10
📂 עסקאות פתוחות: אין

⚙️ מגבלה יומית נעולה: 139.94
📉 סה״כ PNL: -14.23$

🛡️ מצב: נעול
⏰ הנעילה הסתיימה בשעה 22/10/2026 15:00
ℹ️ השומר סגר עסקה בזמן הנעילה הידנית, ולכן החשבון נעול עד תחילת יום המסחר הבא
⏳ נעול עד: 23/10/2026 01:00

=== ML: S25 why the account stays locked, in order: a close by the guardian, the daily loss, a corrupt state file ===
ℹ️ השומר סגר עסקה בזמן הנעילה הידנית, ולכן החשבון נעול עד תחילת יום המסחר הבא
ℹ️ ההפסד של היום חוצה את המגבלה היומית
ℹ️ קובץ מצב הנעילה פגום, הנעילה נמשכת עד תחילת יום המסחר הבא

=== ML: S17 the name of the lockout's record ===
📁 הקובץ: קובץ הנעילה הידנית
```
The emoji map below the block needs no new entry: every emoji of these drafts stands in it for the same field.
- Check: the block still opens with its fence line and closes with its fence line; no U+2013, U+2014 or U+05BE in the text added. TG-S7 at B10 closes the drafts against the code.
- Commit: `docs: the Hebrew drafts of S5 and S25 and the S17 file name of the Manual Lockout, addendum item 13`

### B5. The EA

File `MQL5/Experts/AccountGuardian/AccountGuardian.mq5`, its byte order mark kept. Seventeen changes, in file order.

B5.1, the includes (`EA:17`). Replace
```
#include <AccountGuardian/AlertQueue.mqh>
```
with
```
#include <AccountGuardian/AlertQueue.mqh>
#include <AccountGuardian/ManualLockout.mqh>
#include <AccountGuardian/LockoutPanel.mqh>
```

B5.2, the build label (`EA:138` and `EA:1751-1753`, ML-24 (A)). Replace
```
#define AG_BUILD_LABEL "TG"
```
with
```
#define AG_BUILD_LABEL "ML"
```
Replace
```
   //--- build label, standing rule 7's identity channel: TG names the
   //--- content of this build, the Telegram alerts (TG-1 (B) of
   //--- 2026-10-20, design addendum item 10).
```
with
```
   //--- build label, standing rule 7's identity channel: ML names the
   //--- content of this build, the Manual Lockout (rulings ML-1 to ML-27
   //--- of 2026-10-22, ML-24 (A)), on top of the Telegram alerts.
```

B5.3, the producer's globals (`EA:184` and `EA:189`). Replace
```
int      g_ag_tgp_dispatch_fails  = 0;
```
with
```
int      g_ag_tgp_dispatch_fails  = 0;
//--- Manual Lockout (ML-17 (A)): the producer's memory of the lockout's model,
//--- read from the globals ManualLockout.mqh keeps, and the lockout's own end
//--- waiting for its outcome, as an expiry waits for S8
bool     g_ag_tgp_prev_ml_active  = false;
datetime g_ag_tgp_prev_ml_end     = 0;
bool     g_ag_tgp_prev_ml_only    = false;  // LOCKED by the lockout alone on the last tick
bool     g_ag_tgp_s25_pending     = false;
datetime g_ag_tgp_s25_end         = 0;
//--- ML-35 (1): set by OnDeinit, true after a chart timeframe or symbol
//--- change, reason 3. An in place re-init keeps it, a fresh image starts it
//--- false, AgTgInitReset leaves it alone, and the producer clears it at the
//--- first start of the init, which it silences: no S1 or S16, and S3 only
//--- as ML-37 allows.
bool     g_ag_tgp_quiet_start     = false;
//--- ML-37: the halt time of the SAFE_HALT whose S3 last reached the queue
//--- file, set by each successful queue write that carried an S3. Kept like
//--- the quiet flag: an in place re-init keeps it, a fresh image starts it at
//--- 0, which announces nothing, and AgTgInitReset leaves it alone.
datetime g_ag_tgp_s3_announced    = 0;
```
Replace
```
int      g_ag_tg_init_quarantine  = 0;      // S17 at load: bit 0 state, 1 halt, 2 floor, 3 peak, 4 queue
```
with
```
int      g_ag_tg_init_quarantine  = 0;      // S17 at load: bit 0 state, 1 halt, 2 floor, 3 peak, 4 queue, 5 the lockout's record
```

B5.4, `AgPnlNumbersString` (`EA:256`, ML-16, ENF-17(b)). Replace
```
           + "|sweep=" + (string)AgSweepOpenCount() + "/" + (string)AgSweepHeldCount();
```
with
```
           + "|sweep=" + (string)AgSweepOpenCount() + "/" + (string)AgSweepHeldCount()
           + (g_ag_ml_active ? AgManualLifeField(g_ag_ml_end) : "");   // ML-16, outside the six D2D4 fields
```

B5.5, `AgRefreshBanner` (`EA:299`, ML-16). Replace
```
   AgBanner(AgStateName(g_ag_state), AgLockReasonName(g_ag_lock_reason), g_ag_locked_until, pnl);
```
with
```
   //--- ML-16: while LOCKED with a Manual Lockout, the effective end, and the
   //--- lockout's name while it governs (ML-7)
   string   banner_reason = AgLockReasonName(g_ag_lock_reason);
   datetime banner_until  = g_ag_locked_until;
   if(g_ag_state == AG_STATE_LOCKED && g_ag_ml_active)
     {
      banner_until = AgManualEffectiveEnd(g_ag_locked_until, g_ag_ml_active, g_ag_ml_end);
      if(AgManualGoverns(g_ag_lock_reason != AG_LOCK_NONE, g_ag_locked_until, g_ag_ml_active, g_ag_ml_end))
         banner_reason = AG_MANUAL_REASON_NAME;
     }
   AgBanner(AgStateName(g_ag_state), banner_reason, banner_until, pnl);
```

B5.6, the lockout's functions, new, between `AgEnterLockFromBoot` and the header of `AgEvaluateLocked` (after `EA:700`). Insert before the two lines
```
//+------------------------------------------------------------------+
//| LOCKED-state dispatch. EXPIRY IS THE ONLY UNLOCK PATH and the    |
```
this text, followed by one blank line:
```
//+------------------------------------------------------------------+
//| MANUAL LOCKOUT, rulings ML-1 to ML-27 of 2026-10-22. The second  |
//| lock component's decisions, all in OnTimer (F13): the request    |
//| the panel recorded, applied after the state dispatch; the        |
//| lockout's boot witness at the SYNCING exit; its own end, before  |
//| AgEvaluateLocked on every LOCKED tick. None of these writes      |
//| locked_until, the lock reason or the state file (ML-9). The      |
//| sweep runs unchanged on every LOCKED tick, whatever holds it.    |
//+------------------------------------------------------------------+

//--- ML-12 (A): who may engage or extend. why is the refusal name of the
//--- journal, detail the panel's own words. TERMINAL_CONNECTED is read here
//--- fresh, never through an observability global (question SIX).
bool AgManualEligibility(string &why, string &detail)
  {
   why    = AgManualRefuseName(AG_ML_STATE);
   detail = "";
   if(!g_ag_ml_loaded)
     {
      why    = AgManualRefuseName(AG_ML_NOT_LOADED);
      detail = why;
      return false;
     }
   if(!(bool)TerminalInfoInteger(TERMINAL_CONNECTED))
     {
      detail = "disconnected";
      return false;
     }
   if(g_ag_state == AG_STATE_LOCKED)
      return true;
   if(g_ag_state == AG_STATE_ACTIVE && !g_ag_resyncing)
      return true;
   detail = (g_ag_state == AG_STATE_ACTIVE) ? "reconnecting" : AgStateName(g_ag_state);
   return false;
  }

//--- the effective end while LOCKED, 0 in every other state (ML-7, ML-10)
datetime AgManualCurrentEnd()
  {
   if(g_ag_state != AG_STATE_LOCKED)
      return 0;
   return AgManualEffectiveEnd(g_ag_locked_until, g_ag_ml_active, g_ag_ml_end);
  }

//--- the one request the panel recorded, applied right after the state
//--- dispatch. Q9: while ACTIVE holds a deferred breach the request waits one
//--- tick, so the breach is declared first and the request then meets it.
//--- Every check is taken again here, against the confirmation instant.
void AgManualApplyPending()
  {
   if(!g_ag_panel_request.pending)
      return;
   if(g_ag_state == AG_STATE_ACTIVE && g_ag_breach_deferred_once)
      return;
   AgManualRequest r = g_ag_panel_request;
   g_ag_panel_request.pending = false;
   datetime now     = AgServerNow();
   string   why     = "";
   string   detail  = "";
   int      outcome = AG_ML_OK;
   if(!AgManualEligibility(why, detail))
      outcome = g_ag_ml_loaded ? AG_ML_STATE : AG_ML_NOT_LOADED;
   else
     {
      outcome = AgManualCheckEnd(r.clicked, r.end, r.form, AgManualCurrentEnd());
      if(outcome == AG_ML_OK && r.end <= now)
         outcome = AG_ML_TOO_SOON;
     }
   if(outcome != AG_ML_OK)
     {
      AgInfo(AgManualRefusedLine(AgManualRefuseName(outcome), "apply", AgStateName(g_ag_state),
                                 r.form, r.end, now));
      AgPanelApplied(false, AgManualRefuseName(outcome));
      return;
     }
   bool     from_active = (g_ag_state == AG_STATE_ACTIVE);
   datetime from_end    = g_ag_ml_end;
   if(!g_ag_ml_active)
      g_ag_ml_first_engaged = r.clicked;
   g_ag_ml_active  = true;
   g_ag_ml_engaged = r.clicked;
   g_ag_ml_end     = r.end;
   g_ag_ml_form    = r.form;
   g_ag_ml_minutes = r.minutes;
   AgManualSave();   // a failed write is loud in AgAtomicWrite and reported by S17
   GlobalVariableSet(AgGvManual(), (double)(long)g_ag_ml_end);
   GlobalVariablesFlush();
   if(from_active)
     {
      //--- D4a, the Q6 input witness, seeded as at every lock entry
      g_ag_locked_in_percent    = AgInputPercent();
      g_ag_locked_in_currency   = AgInputCurrency();
      g_ag_lock_inputs_captured = true;
      //--- ENF-18(a): the counts the sweep is about to act on, one enumeration
      //--- before the transition; the sweep starts on the next LOCKED dispatch
      int positions = PositionsTotal();
      int pendings  = AgSweepCountPendings();
      AgInfo(AgManualEngagedLine(r.form, r.minutes, r.clicked, r.end, AgNextDayAnchor(r.clicked),
                                 positions, pendings));
      AgTransition(AG_STATE_LOCKED, AG_MANUAL_REASON_NAME, AgManualEndField(r.end));
      AgSweepReset();
      AgAlertEvent(AgManualEngageAlert(r.end, positions, pendings));
      g_ag_dynamic_waiting_on = "";
     }
   else
     {
      AgInfo(AgManualExtendedLine(from_end, r.end, r.form, r.minutes, r.clicked));
      AgAlertEvent(AgManualExtendAlert(r.end));
     }
   AgPanelApplied(true, "");
  }

//--- ML-18, ML-19: the lockout's boot witness at the SYNCING exit. The record
//--- as loaded in OnInit and the AG_MANUAL mirror read now; the later end
//--- governs, cut to the next anchor of now with no floor after it (ML-9). A
//--- mirror alone, a later mirror or a cut end becomes the model, confirmed
//--- now, and the record is written to match. Returns whether a lockout holds.
bool AgManualBootFire(datetime &end_out)
  {
   end_out = 0;
   datetime now    = AgServerNow();
   double   gv_raw = 0.0;
   datetime gv_end = 0;
   if(GlobalVariableGet(AgGvManual(), gv_raw))
      gv_end = (datetime)(long)gv_raw;
   int  source = 0;
   bool fired  = AgManualBootWitness(now, g_ag_ml_active, g_ag_ml_end, gv_end, end_out, source);
   if(!fired)
     {
      g_ag_ml_active = false;   // an ended record stays on disk as written, inert
      return false;
     }
   AgInfo(AgManualBootFiredLine(source, g_ag_ml_active ? g_ag_ml_end : (datetime)0, gv_end, end_out));
   if(!g_ag_ml_active || end_out != g_ag_ml_end)
     {
      g_ag_ml_active        = true;
      g_ag_ml_first_engaged = now;
      g_ag_ml_engaged       = now;
      g_ag_ml_end           = end_out;
      AgManualSave();
     }
   return true;
  }

//--- a lockout alone at the SYNCING exit: the fourth LOCKED entry, beside
//--- AgDeclareLock, AgEnterLockFromBoot and AgManualApplyPending. It never
//--- touches the state model (ML-9).
void AgEnterManualLockFromBoot(const datetime end)
  {
   g_ag_locked_in_percent    = AgInputPercent();
   g_ag_locked_in_currency   = AgInputCurrency();
   g_ag_lock_inputs_captured = true;
   int sweep_positions = PositionsTotal();
   int sweep_pendings  = AgSweepCountPendings();
   AgTransition(AG_STATE_LOCKED, "boot derivation: " + AG_MANUAL_REASON_NAME, AgManualEndField(end));
   AgSweepReset();
   AgAlertEvent(AgManualBootAlert(end, sweep_positions, sweep_pendings));
   g_ag_dynamic_waiting_on = "";
  }

//--- a lockout and a loss lock at the SYNCING exit together: the loss lock
//--- entered unchanged, the lockout held beside it, the later end governing
void AgManualHoldWithBootLock(const datetime end)
  {
   AgInfo(AgManualHoldsLine(end, g_ag_locked_until,
                            AgManualGoverns(g_ag_lock_reason != AG_LOCK_NONE, g_ag_locked_until, true, end)));
  }

//--- ML-6, ML-7: the lockout's own end, before AgEvaluateLocked on every
//--- LOCKED tick. Ended while a loss lock still holds: the lockout goes and
//--- the loss lock stays. Ended with nothing else holding: journaled here,
//--- released by AgEvaluateLocked on this same tick, the model cleared after.
void AgManualLockedPass()
  {
   if(!g_ag_ml_active)
      return;
   datetime now = AgServerNow();
   if(now < g_ag_ml_end)
      return;
   if(now < g_ag_locked_until)
     {
      AgInfo(AgManualEndedUnderLossLine(g_ag_ml_end, g_ag_locked_until, now));
      g_ag_ml_active = false;
      return;
     }
   AgInfo(AgManualExpiredLine(g_ag_ml_end, now));
  }

//--- the tick AgEvaluateLocked released the account: the lockout's model goes
//--- with it; the record stays on disk as written, inert, its end passed
void AgManualAfterExpiry()
  {
   if(g_ag_ml_active && AgServerNow() >= g_ag_ml_end)
      g_ag_ml_active = false;
  }

//--- ML-18 (A): the record read back at the LIFE cadence while a lockout holds
void AgManualHeal()
  {
   if(!g_ag_ml_active || !g_ag_ml_loaded || g_timer_ticks % AG_LIFE_INTERVAL_SECONDS != 0)
      return;
   AgManualHealRecord();
  }
```

B5.7, `AgEvaluateLocked` (`EA:753-756`), its two lines and nothing else (ML-7; ML-S4). Replace
```
   datetime now_server = AgServerNow();
   if(now_server >= g_ag_locked_until)
     {
      AgInfo("lock expired|locked_until=" + TimeToString(g_ag_locked_until, TIME_DATE | TIME_SECONDS)
```
with
```
   datetime now_server = AgServerNow();
   datetime lock_end   = AgManualEffectiveEnd(g_ag_locked_until, g_ag_ml_active, g_ag_ml_end);   // ML-7
   if(now_server >= lock_end)
     {
      AgInfo("lock expired|locked_until=" + TimeToString(lock_end, TIME_DATE | TIME_SECONDS)
```

B5.8, `AgTgPnlNow` (`EA:1125`, R3, section 4.8). Replace
```
   if(g_ag_state == AG_STATE_LOCKED && g_ag_state_limit_snap > 0.0)
```
with
```
   //--- the breach snapshot while a loss lock holds; a Manual Lockout alone
   //--- has no day result to show and reads not computed yet (R3)
   if(g_ag_state == AG_STATE_LOCKED && g_ag_lock_reason != AG_LOCK_NONE && g_ag_state_limit_snap > 0.0)
```

B5.9, `AgTgSnapshotNow` (`EA:1229`, ML-16) and `AgTgQueueWrite` (`EA:1254-1260`, ML-37), two changes. Replace
```
   s.locked_until     = (long)g_ag_locked_until;
```
with
```
   s.locked_until     = (long)AgManualEffectiveEnd(g_ag_locked_until, g_ag_ml_active, g_ag_ml_end);   // ML-16
```
and replace, in the successful write of `AgTgQueueWrite`,
```
      g_ag_tgq_deferred   = 0;
      return;
```
with
```
      g_ag_tgq_deferred   = 0;
      //--- ML-37: the file now holds every event of the model, so the last S3
      //--- among them has reached it; a write that carries none keeps the record
      g_ag_tgp_s3_announced = AgTgS3HaltTimeIn(g_ag_tgq_events, g_ag_tgq_count, g_ag_tgp_s3_announced);
      return;
```

B5.10, `AgTgFileKind` (`EA:1375-1383`). Replace
```
//--- which lock, halt, floor or peak file a loud write failure named (S17)
```
with
```
//--- which lock, halt, floor, peak or lockout file a loud write failure named (S17)
```
and replace
```
   if(path == AgPeakPath())  return 4;
   return 0;
```
with
```
   if(path == AgPeakPath())  return 4;
   if(path == AgManualPath()) return 6;
   return 0;
```

B5.11, `AgTgProduce` (`EA:1477-1679`, ML-17 (A), ML-35 (1), ML-37), five changes.

(a) Replace
```
                         && g_ag_history_fail_count == g_ag_tgp_dispatch_fails;
```
with
```
                         && g_ag_history_fail_count == g_ag_tgp_dispatch_fails;
   //--- Manual Lockout (ML-17 (A)): LOCKED by the lockout alone, no loss lock reason
   bool ml_only = (st == AG_STATE_LOCKED && g_ag_lock_reason == AG_LOCK_NONE && g_ag_ml_active);
```
and replace (`EA:1491-1497`)
```
   //--- S3, SAFE_HALT: once per init, on its first tick
   if(st == AG_STATE_SAFE_HALT && !g_ag_tgp_s3_sent)
     {
      g_ag_tgp_s3_sent = true;
      AgTgPush(AG_TG_S3, g_ag_tg_halt_kind, (double)(long)g_ag_halt_time, g_ag_tg_halt_chain,
               AG_CRASH_LOOP_WINDOW_SECONDS);
     }
```
with
```
   //--- S3, SAFE_HALT: once per init, on its first tick. After a chart
   //--- timeframe or symbol change none for the same SAFE_HALT an earlier S3
   //--- already announced; a SAFE_HALT new at this init always sends it
   //--- (ML-35 (1), ML-37)
   if(st == AG_STATE_SAFE_HALT && !g_ag_tgp_s3_sent)
     {
      g_ag_tgp_s3_sent = true;
      if(!AgTgS3Silenced(g_ag_tgp_quiet_start, g_ag_tgp_s3_announced, g_ag_halt_time))
         AgTgPush(AG_TG_S3, g_ag_tg_halt_kind, (double)(long)g_ag_halt_time, g_ag_tg_halt_chain,
                  AG_CRASH_LOOP_WINDOW_SECONDS);
      g_ag_tgp_quiet_start = false;
     }
```

(b) Replace `EA:1499-1525`,
```
   //--- the SYNCING exits: the first after this init is S1 or S16, an exit
   //--- after an expiry is S8
   if(prev == AG_STATE_SYNCING && st == AG_STATE_ACTIVE && !g_ag_tgp_first_exit_done)
     {
      g_ag_tgp_first_exit_done = true;
      g_ag_tgp_s1_pending      = true;   // the figures come with the first completed pass
     }
   if(prev == AG_STATE_SYNCING && st == AG_STATE_LOCKED)
     {
      if(g_ag_tgp_first_exit_done && g_ag_tgp_s8_pending)
        {
         g_ag_tgp_s8_pending = false;
         AgTgPush(AG_TG_S8, 2, (double)(long)g_ag_locked_until, g_ag_state_limit_snap);
        }
      else
        {
         g_ag_tgp_first_exit_done = true;
         int mask = (g_ag_tg_init_source_mask != 0) ? g_ag_tg_init_source_mask : 4;
         AgTgPush(AG_TG_S16, (int)g_ag_lock_reason, (double)(long)g_ag_locked_until, mask,
                  g_ag_state_limit_snap, PositionsTotal(), AgSweepCountPendings());
        }
     }
   if(prev == AG_STATE_LOCKED && st == AG_STATE_SYNCING)
     {
      g_ag_tgp_s8_pending       = true;
      g_ag_tgp_s8_expired_until = g_ag_tgp_prev_locked_until;
     }
```
with
```
   //--- the SYNCING exits: the first after this init is S1 or S16, none into
   //--- a Manual Lockout alone (ML-30, ML-34) and none after a chart timeframe
   //--- or symbol change (ML-35 (1)); an exit after an expiry is S8, or S25
   //--- after a lockout's own end (ML-17 (A))
   if(prev == AG_STATE_SYNCING && st == AG_STATE_ACTIVE && !g_ag_tgp_first_exit_done)
     {
      g_ag_tgp_first_exit_done = true;
      g_ag_tgp_s1_pending      = !g_ag_tgp_quiet_start;   // the figures come with the first completed pass
      g_ag_tgp_quiet_start     = false;
     }
   if(prev == AG_STATE_SYNCING && st == AG_STATE_LOCKED)
     {
      if(g_ag_tgp_first_exit_done && g_ag_tgp_s25_pending)
        {
         g_ag_tgp_s25_pending = false;
         AgTgPush(AG_TG_S25, 2, (double)(long)g_ag_tgp_s25_end, (double)(long)g_ag_locked_until,
                  (int)g_ag_lock_reason);
        }
      else if(g_ag_tgp_first_exit_done && g_ag_tgp_s8_pending)
        {
         g_ag_tgp_s8_pending = false;
         AgTgPush(AG_TG_S8, 2, (double)(long)g_ag_locked_until, g_ag_state_limit_snap);
        }
      else
        {
         g_ag_tgp_first_exit_done = true;
         if(!ml_only && !g_ag_tgp_quiet_start)
           {
            int mask = (g_ag_tg_init_source_mask != 0) ? g_ag_tg_init_source_mask : 4;
            AgTgPush(AG_TG_S16, (int)g_ag_lock_reason, (double)(long)g_ag_locked_until, mask,
                     g_ag_state_limit_snap, PositionsTotal(), AgSweepCountPendings());
           }
         g_ag_tgp_quiet_start = false;
        }
     }
   if(prev == AG_STATE_LOCKED && st == AG_STATE_SYNCING)
     {
      //--- one release, one outcome pending: the other flag is cleared, so an
      //--- outcome an earlier release left unsent never doubles or replaces this one
      g_ag_tgp_s25_pending = g_ag_tgp_prev_ml_only;
      g_ag_tgp_s8_pending  = !g_ag_tgp_prev_ml_only;
      if(g_ag_tgp_prev_ml_only)
         g_ag_tgp_s25_end = g_ag_tgp_prev_ml_end;
      else
         g_ag_tgp_s8_expired_until = g_ag_tgp_prev_locked_until;
     }
```

(c) Replace
```
   //--- the completed ACTIVE pass: S1, S8 released, S9, S19 held raise, S20
```
with
```
   //--- the completed ACTIVE pass: S1, S8 released, S25 released, S9, S19 held raise, S20
```
and replace
```
         AgTgPushFull(AG_TG_S8, AG_TG_PNL_ACTIVE, g_ag_last_pnl, enforced,
                      1, (double)(long)g_ag_tgp_s8_expired_until, enforced);
        }
```
with
```
         AgTgPushFull(AG_TG_S8, AG_TG_PNL_ACTIVE, g_ag_last_pnl, enforced,
                      1, (double)(long)g_ag_tgp_s8_expired_until, enforced);
        }
      if(g_ag_tgp_s25_pending && st == AG_STATE_ACTIVE)
        {
         g_ag_tgp_s25_pending = false;
         AgTgPushFull(AG_TG_S25, AG_TG_PNL_ACTIVE, g_ag_last_pnl, enforced,
                      1, (double)(long)g_ag_tgp_s25_end);
        }
```

(d) Replace
```
   //--- of the two legs.
   if(prev == AG_STATE_ACTIVE && st == AG_STATE_LOCKED)
     {
```
with
```
   //--- of the two legs. A Manual Lockout alone is S5 instead, with the
   //--- engaging pass's figures, sent at the engagement only (ML-17 (A), ML-30).
   if(prev == AG_STATE_ACTIVE && st == AG_STATE_LOCKED && ml_only)
     {
      double ml_enforced = AgFloorEffectiveLimit(g_ag_last_limit, g_ag_last_anchor);
      AgTgPushFull(AG_TG_S5, g_ag_have_pnl_numbers ? AG_TG_PNL_ACTIVE : AG_TG_PNL_NONE,
                   g_ag_have_pnl_numbers ? g_ag_last_pnl : 0.0, g_ag_have_pnl_numbers ? ml_enforced : 0.0,
                   (double)(long)g_ag_ml_end, (double)(long)AgNextDayAnchor(g_ag_ml_engaged),
                   (double)((long)g_ag_ml_end - (long)g_ag_ml_engaged), PositionsTotal(), AgSweepCountPendings());
     }
   else if(prev == AG_STATE_ACTIVE && st == AG_STATE_LOCKED)
     {
```
and replace
```
                   g_ag_peak_currency, PositionsTotal(), AgSweepCountPendings());
     }
```
with
```
                   g_ag_peak_currency, PositionsTotal(), AgSweepCountPendings());
     }
   //--- ML-17 (A): a lockout that ended while a loss lock holds the account;
   //--- an extension sends nothing (ML-30)
   if(prev == AG_STATE_LOCKED && st == AG_STATE_LOCKED && !g_ag_ml_active && g_ag_tgp_prev_ml_active)
      AgTgPush(AG_TG_S25, 2, (double)(long)g_ag_tgp_prev_ml_end, (double)(long)g_ag_locked_until,
               (int)g_ag_lock_reason);
```

(e) Replace
```
   g_ag_tgp_prev_state        = st;
   g_ag_tgp_prev_locked_until = g_ag_locked_until;
```
with
```
   g_ag_tgp_prev_state        = st;
   g_ag_tgp_prev_locked_until = g_ag_locked_until;
   g_ag_tgp_prev_ml_active    = g_ag_ml_active;
   g_ag_tgp_prev_ml_end       = g_ag_ml_end;
   g_ag_tgp_prev_ml_only      = ml_only;
```

The producer reads the lockout's model and writes none of it: every global the lockout's decisions write is a `g_ag_ml_` one, and every global the producer writes is a `g_ag_tgp_` or `g_ag_tgq_` one, as before.

B5.12, `AgTgInitReset` (`EA:1724`). Replace
```
   g_ag_tgp_dispatch_fails  = g_ag_history_fail_count;
```
with
```
   g_ag_tgp_dispatch_fails  = g_ag_history_fail_count;
   g_ag_tgp_prev_ml_active  = false;
   g_ag_tgp_prev_ml_end     = 0;
   g_ag_tgp_prev_ml_only    = false;
   g_ag_tgp_s25_pending     = false;
   g_ag_tgp_s25_end         = 0;
```
`g_ag_tgp_quiet_start` stays out of this reset on purpose (ML-35 (1)): OnDeinit sets it and the init that follows reads it. So does `g_ag_tgp_s3_announced` (ML-37): a successful queue write sets it and the init after a reason 3 change reads it.

B5.13, `AgTgInitEvents` (`EA:1740`). Replace
```
   for(int kind = 1; kind <= 5; kind++)
```
with
```
   for(int kind = 1; kind <= 6; kind++)
```

B5.14, `OnInit`, three changes. Replace (`EA:1760`)
```
   AgTgInitReset();
```
with
```
   AgTgInitReset();
   //--- Manual Lockout: the panel's stage and any request start afresh, an
   //--- in place re-init included
   AgPanelInitReset();
```
Replace (`EA:1795-1797`)
```
   AgTgQueueLoad();

   //--- crash-loop evidence, persisted across process death (A1)
```
with
```
   AgTgQueueLoad();
   //--- Manual Lockout panel (ML-3, ML-15), drawn by the instance that owns
   //--- the mutex only, and hidden until the first timer tick renders it
   AgPanelCreate();

   //--- crash-loop evidence, persisted across process death (A1)
```
Replace (`EA:1890`)
```
   double gv_halt = 0.0;
```
with
```
   //--- Manual Lockout record (ML-18, ML-19). Loaded for the same reason the
   //--- state file is, so that it can ever be written; what it says is weighed
   //--- at the SYNCING exit by the lockout's own boot witness, never here.
   int ml_result = AgManualLoad();
   if(ml_result == 0)
      AgInfo(AgManualLoadedLine(g_ag_ml_active, g_ag_ml_end));
   else if(ml_result >= 2)
      g_ag_tg_init_quarantine |= 32;   // Telegram alerts, S17 at load, kind 6
   double ml_gv_init = 0.0;
   GlobalVariableGet(AgGvManual(), ml_gv_init);
   AgInfo(AgManualGvInitLine((datetime)(long)ml_gv_init));

   double gv_halt = 0.0;
```

B5.15, `OnTimer`, five changes. Replace (`EA:2001-2002`)
```
      GlobalVariableSet(AgGvLock(), (double)(long)g_ag_locked_until);
      GlobalVariablesFlush();
```
with
```
      GlobalVariableSet(AgGvLock(), (double)(long)g_ag_locked_until);
      //--- ML-18 (A): the lockout's mirror, the bare end, under the same gate
      if(g_ag_ml_loaded)
         GlobalVariableSet(AgGvManual(), (double)(long)(g_ag_ml_active ? g_ag_ml_end : (datetime)0));
      GlobalVariablesFlush();
```
Replace (`EA:2021`)
```
   string waiting_on = AgWaitingOn();
```
with
```
   string waiting_on = AgWaitingOn();
   //--- ML-16: while the lockout governs, the condition actually waited on
   if(g_ag_state == AG_STATE_LOCKED
      && AgManualGoverns(g_ag_lock_reason != AG_LOCK_NONE, g_ag_locked_until, g_ag_ml_active, g_ag_ml_end))
      waiting_on = "expiry: TimeCurrent >= manual_end";
```
Replace (`EA:2034-2036`)
```
   AgRefreshBanner();

   //--- Telegram alerts: what the dispatch below starts from, so the producer
```
with
```
   AgRefreshBanner();
   //--- Manual Lockout panel (ML-12, ML-15, ML-16): what the trader may do now,
   //--- and the remaining time. Display only; the request is applied below,
   //--- after the dispatch.
   string   ml_why      = "";
   string   ml_detail   = "";
   bool     ml_eligible = AgManualEligibility(ml_why, ml_detail);
   bool     ml_locked   = (g_ag_state == AG_STATE_LOCKED);
   datetime ml_now      = AgServerNow();
   bool     ml_governs  = ml_locked && AgManualGoverns(g_ag_lock_reason != AG_LOCK_NONE, g_ag_locked_until,
                                                       g_ag_ml_active, g_ag_ml_end);
   string   ml_ext_why  = "";
   if(!ml_eligible)
      ml_ext_why = ml_why;
   else if(g_ag_lock_reason != AG_LOCK_NONE)
      ml_ext_why = AgManualRefuseName(AG_ML_NOT_LATER);
   else if(!g_ag_ml_active || g_ag_ml_end >= AgNextDayAnchor(ml_now))
      ml_ext_why = AgManualRefuseName(AG_ML_PAST_ANCHOR);
   AgPanelRefresh(g_ag_login, ml_eligible, ml_detail, ml_locked, AgManualCurrentEnd(),
                  ml_governs ? AG_MANUAL_REASON_NAME : AgLockReasonName(g_ag_lock_reason),
                  ml_locked && ml_ext_why == "", ml_ext_why, PositionsTotal(), AgSweepCountPendings(), ml_now);

   //--- Telegram alerts: what the dispatch below starts from, so the producer
```
Replace (`EA:2068-2078`)
```
         int derived = AgBootDerivation(boot_reason, boot_until, boot_have_snapshot,
                                        boot_breach_time, boot_limit, boot_base);
         if(derived == 2)
           {
            g_ag_dynamic_waiting_on = "boot derivation not evaluable, retrying";
           }
         else if(derived == 1)
           {
            AgEnterLockFromBoot(boot_reason, boot_until, boot_have_snapshot,
                                boot_breach_time, boot_limit, boot_base);
           }
```
with
```
         int derived = AgBootDerivation(boot_reason, boot_until, boot_have_snapshot,
                                        boot_breach_time, boot_limit, boot_base);
         //--- Manual Lockout (ML-9, ML-18, ML-19): its own boot witness, weighed
         //--- after the derivation and outside it, never on a pass the
         //--- derivation could not evaluate
         datetime ml_boot_end   = 0;
         bool     ml_boot_fired = false;
         if(derived != 2)
            ml_boot_fired = AgManualBootFire(ml_boot_end);
         if(derived == 2)
           {
            g_ag_dynamic_waiting_on = "boot derivation not evaluable, retrying";
           }
         else if(derived == 1)
           {
            AgEnterLockFromBoot(boot_reason, boot_until, boot_have_snapshot,
                                boot_breach_time, boot_limit, boot_base);
            if(ml_boot_fired)
               AgManualHoldWithBootLock(ml_boot_end);
           }
         else if(ml_boot_fired)
            AgEnterManualLockFromBoot(ml_boot_end);
```
Replace (`EA:2091-2100`)
```
   else if(g_ag_state == AG_STATE_LOCKED)
     {
      AgEvaluateLocked();
```
with
```
   else if(g_ag_state == AG_STATE_LOCKED)
     {
      //--- ML-6, ML-7: the lockout's own end first, then the one expiry path
      AgManualLockedPass();
      AgEvaluateLocked();
```
and replace
```
      if(g_ag_state == AG_STATE_LOCKED)
         AgSweepPass("timer");
     }
```
with
```
      if(g_ag_state == AG_STATE_LOCKED)
         AgSweepPass("timer");
      //--- ML-18 (A) while still LOCKED; the lockout's model cleared on the
      //--- tick that released the account
      if(g_ag_state == AG_STATE_LOCKED)
         AgManualHeal();
      else
         AgManualAfterExpiry();
     }

   //--- Manual Lockout (ML-10 to ML-15): the request the panel recorded,
   //--- applied after the dispatch, so this tick's breach decision comes first
   AgManualApplyPending();
```

B5.16, `OnChartEvent`, new (F13 read onto the panel). Replace (`EA:2162`)
```
void OnTick() { }
```
with
```
void OnTick() { }

//+------------------------------------------------------------------+
//| The Manual Lockout panel's events (ML-3, ML-15). Presentation    |
//| only: a click changes the panel's own stage or records the one   |
//| request OnTimer applies (F13); nothing here decides, writes a    |
//| file or a GV, or reaches the sweep.                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   AgPanelOnEvent(id, lparam, dparam, sparam);
  }
```

B5.17, `OnDeinit`, two changes. Replace (`EA:2193-2196`)
```
      AgTgAckRead();
      AgTgPush(AG_TG_S2, reason);
      AgTgQueueWrite(true);
     }
```
with
```
      AgTgAckRead();
      //--- ML-35 (1): a chart timeframe or symbol change, reason 3, sends no
      //--- stop; the queue is still written, so nothing pending is lost
      if(!AgTgSilentReason(reason))
         AgTgPush(AG_TG_S2, reason);
      AgTgQueueWrite(true);
     }
   //--- ML-35 (1): the init that follows a reason 3 change sends no start
   //--- message, and under ML-37 no S3 for a SAFE_HALT whose S3 a queue write,
   //--- the one above included, already carried. An in place re-init keeps
   //--- this global, a fresh image starts it false, and every other reason
   //--- clears it here.
   g_ag_tgp_quiet_start = AgTgSilentReason(reason);
```
and replace (`EA:2206`)
```
   if(g_init_refused)
      AgInfo("deinit|banner NOT cleared: init was refused, dated REFUSED banner stays on the chart");
```
with
```
   //--- Manual Lockout panel: its own objects only, by prefix; none were drawn
   //--- after a refused init
   AgPanelDelete();
   if(g_init_refused)
      AgInfo("deinit|banner NOT cleared: init was refused, dated REFUSED banner stays on the chart");
```

- Check: `python -I scripts/rows/compile.py MQL5/Experts/AccountGuardian/AccountGuardian.mq5 ml-ea <log folder>`, the log folder being the build session's job temporary folder, outside the repository, prints `Result: 0 errors, 0 warnings`, no including line outside the worktree, and the ex5 FRESH (standing rule 6). The EA stays ASCII after its byte order mark.
- Commit: `ea: the Manual Lockout, a second lock component applied in OnTimer, its boot witness, its own end before the one expiry path, the panel, S5 and S25 in the producer, no Telegram message for a reason 3 change and S3 after it only for a SAFE_HALT not yet announced, label ML`

### B6. AlertText.mqh: the file word of kind 6, S5 and S25

File `MQL5/Include/AccountGuardian/AlertText.mqh`, UTF-8 with its byte order mark kept. Every Hebrew literal below stands verbatim in a draft added at B4, which TG-S7 checks.

Replace, in `AgTgFileWord` (`AlertText.mqh:360-371`),
```
      case 5: return "קובץ תור ההתראות";
```
with
```
      case 5: return "קובץ תור ההתראות";
      case 6: return "קובץ הנעילה הידנית";
```

Insert before the line `string AgTgTextS6C(const AgTgCommon &c, const long closed, const long deleted, const long attempts,` (`AlertText.mqh:480`):
```
//--- the Manual Lockout's note (ML-8): a lockout that ends before the next
//--- daily anchor says what a close by the guardian does; none at the anchor
string AgTgManualNote(const datetime end, const datetime anchor, const long positions)
  {
   if(end >= anchor)
      return "";
   if(positions > 0)
      return "ℹ️ השומר סוגר עכשיו את העסקאות הפתוחות, ולכן החשבון יישאר נעול עד תחילת יום המסחר הבא";
   return "ℹ️ אם השומר יסגור עסקה בזמן הנעילה, החשבון יישאר נעול עד תחילת יום המסחר הבא";
  }

//--- S5, the Manual Lockout engaged (ML-17 (A)), sent at the engagement only
//--- (ML-30). It carries the sweep line and leaves the open trades line out,
//--- as S4 and S16 do (R4, ML-31).
string AgTgTextS5(const AgTgCommon &c, const datetime end, const datetime anchor, const long length,
                  const long positions, const long pendings)
  {
   string lines = "⏳ נעול עד: " + AgTgStamp(end) + "\n⌛ משך: " + AgTgDuration(length);
   lines = AgTgAdd(lines, AgTgSweepNow(positions, pendings));
   lines += "\n❗ אי אפשר לבטל או לקצר את הנעילה";
   lines = AgTgAdd(lines, AgTgManualNote(end, anchor, positions));
   return AgTgMessageWith("🔒 נעילה ידנית: החשבון ננעל לבקשתך", c, AgTgPnlLine(c.pnl_mode, c.pnl, c.limit, c.cur),
                          lines, false);
  }

```

Insert before the two lines
```
//+------------------------------------------------------------------+
//| THE PERIODIC STATUS, also the command's reply (item 6). hb_age   |
```
(`AlertText.mqh:691-692`):
```
//--- S25's why line: the lock that holds the account after the lockout's
//--- own end, by its reason (ML-7, ML-8)
string AgTgManualAgainWord(const int reason)
  {
   if(reason == AG_LOCK_SWEEP_WITNESS)
      return "ℹ️ השומר סגר עסקה בזמן הנעילה הידנית, ולכן החשבון נעול עד תחילת יום המסחר הבא";
   if(reason == AG_LOCK_DAILY_BREACH)
      return "ℹ️ ההפסד של היום חוצה את המגבלה היומית";
   if(reason == AG_LOCK_CORRUPT_STATE)
      return "ℹ️ קובץ מצב הנעילה פגום, הנעילה נמשכת עד תחילת יום המסחר הבא";
   return "";
  }

//--- S25, the Manual Lockout's own end (ML-17 (A)): outcome 1 released, 2
//--- the account stays locked by the lock that holds it now, until its end
string AgTgTextS25(const AgTgCommon &c, const int outcome, const datetime end, const datetime until,
                   const int reason)
  {
   if(outcome == 1)
      return AgTgMessage("🔓 הנעילה הידנית הסתיימה", c, "⏰ הנעילה הסתיימה בשעה " + AgTgStamp(end));
   string lines = AgTgAdd("⏰ הנעילה הסתיימה בשעה " + AgTgStamp(end), AgTgManualAgainWord(reason));
   return AgTgMessage("🔒 הנעילה הידנית הסתיימה, החשבון נשאר נעול", c, lines + "\n⏳ נעול עד: " + AgTgStamp(until));
  }

```
- Check: the file still starts EF BB BF and decodes as strict UTF-8; no Hebrew outside a string literal; the service compile of B7 passes; TG-S7 holds at B10.
- Commit: `text: S5 and S25 of the Manual Lockout, and the file name of its record for S17`

### B7. The alerts service

File `MQL5/Services/AccountGuardian/AccountGuardianAlerts.mq5`, six changes (ML-17 (A), ML-24 (A), ML-30, ML-35).

Replace (`SVC:40`)
```
#define AG_SVC_BUILD_LABEL       "TG"
```
with
```
#define AG_SVC_BUILD_LABEL       "ML"
```
In `AgSvcRender` (`SVC:393-457`), replace
```
      case AG_TG_S6C:
         return AgTgTextS6C(
```
with
```
      case AG_TG_S5:
         return AgTgTextS5(c, (datetime)(long)e.x[0], (datetime)(long)e.x[1], (long)e.x[2], (long)e.x[3],
                           (long)e.x[4]);
      case AG_TG_S6C:
         return AgTgTextS6C(
```
and replace
```
      case AG_TG_S24:
         return AgTgTextS24(c);
```
with
```
      case AG_TG_S24:
         return AgTgTextS24(c);
      case AG_TG_S25:
         return AgTgTextS25(c, (int)e.x[0], (datetime)(long)e.x[1], (datetime)(long)e.x[2], (int)e.x[3]);
```
In `AgSvcConvertOne` (`SVC:469-478`), two changes. ML-35 (1), replace (`SVC:471`)
```
   string cls = AgTgCodeText(e.code);
```
with
```
   //--- ML-35 (1): a stop for a chart timeframe or symbol change, reason 3,
   //--- is acknowledged and sends nothing; this build's EA queues none, a
   //--- queue an earlier build wrote may hold one
   if(e.code == AG_TG_S2 && AgTgSilentReason((int)e.x[0]))
     {
      AgSvcAdvance(e.seq);
      return;
     }
   string cls = AgTgCodeText(e.code);
```
and the S14 lock count, replace (`SVC:478`)
```
   if(e.code == AG_TG_S4 || e.code == AG_TG_S16)
```
with
```
   if(e.code == AG_TG_S4 || e.code == AG_TG_S16 || e.code == AG_TG_S5)
```
In `AgSvcMerge` (`SVC:488-490`), ML-35 (1), replace
```
void AgSvcMerge(const AgTgEvent &stop, const AgTgEvent &start)
  {
   AgTgCommon c;
```
with
```
void AgSvcMerge(const AgTgEvent &stop, const AgTgEvent &start)
  {
   //--- ML-35 (1): a reason 3 stop merges into nothing; the stop and its
   //--- start are both acknowledged without a message, and no lock is counted
   if(AgTgSilentReason((int)stop.x[0]))
     {
      AgSvcAdvance(stop.seq);
      AgSvcConsume(start.seq);
      return;
     }
   AgTgCommon c;
```
`AgSvcConvert` and `AgSvcInPlace` stay as they are. An in place stop still merges with an S1 or an S16 only, and during a lockout alone the stop of every other in place reason goes out alone after the hold (ML-30, ML-35 (2)). Reason 3 stays among the in place reasons, so a reason 3 stop an earlier build queued is held for its start, and both are then acknowledged without a message.
- Check: `python -I scripts/rows/compile.py MQL5/Services/AccountGuardian/AccountGuardianAlerts.mq5 ml-svc <log folder>` prints `Result: 0 errors, 0 warnings`, no including line outside the worktree, the ex5 FRESH. `AgTgCarriesBuild` is unchanged, so S5 and S25 carry no build line (F9).
- Commit: `service: S5 and S25 rendered, S5 counted as a lock in S14, a reason 3 stop and its start acknowledged without a message, label ML`

### B8. The vectors: the include and the queue's code list

File `MQL5/Scripts/AccountGuardian/AgPhase2StateVectors.mq5`.

Replace (`VEC:44`)
```
#include <AccountGuardian/AlertText.mqh>
```
with
```
#include <AccountGuardian/AlertText.mqh>
#include <AccountGuardian/ManualLockout.mqh>
```
Replace (`VEC:1284-1286`)
```
   int tg_codes[21] = {AG_TG_S1, AG_TG_S2, AG_TG_S3, AG_TG_S4, AG_TG_S6C, AG_TG_S6H, AG_TG_S6F,
                       AG_TG_S7, AG_TG_S8, AG_TG_S9, AG_TG_S10, AG_TG_S12, AG_TG_S15, AG_TG_S16,
                       AG_TG_S17, AG_TG_S18, AG_TG_S19, AG_TG_S20, AG_TG_S21, AG_TG_S22, AG_TG_S24};
```
with
```
   int tg_codes[23] = {AG_TG_S1, AG_TG_S2, AG_TG_S3, AG_TG_S4, AG_TG_S5, AG_TG_S6C, AG_TG_S6H, AG_TG_S6F,
                       AG_TG_S7, AG_TG_S8, AG_TG_S9, AG_TG_S10, AG_TG_S12, AG_TG_S15, AG_TG_S16,
                       AG_TG_S17, AG_TG_S18, AG_TG_S19, AG_TG_S20, AG_TG_S21, AG_TG_S22, AG_TG_S24, AG_TG_S25};
```
Then the count 21 becomes 23 at its six other sites: replace `   ArrayResize(tg_ev, 21);` (`VEC:1288`) with `   ArrayResize(tg_ev, 23);`; replace both lines `   for(int k = 0; k < 21; k++)` (`VEC:1289` and `VEC:1382`, the one text that occurs twice; replace both) with `   for(int k = 0; k < 23; k++)`; replace `                                    AgTgSnapshotLine(tg_sn, "TG"), tg_ev, 21);` (`VEC:1313`) with `                                    AgTgSnapshotLine(tg_sn, "TG"), tg_ev, 23);`; replace `   AgVecCheckInt("tg_q_roundtrip_every_code_count", tg_count, 21);` (`VEC:1323`) with `   AgVecCheckInt("tg_q_roundtrip_every_code_count", tg_count, 23);`; replace `   bool tg_same = (tg_count == 21);` (`VEC:1324`) with `   bool tg_same = (tg_count == 23);`.

Replace (`VEC:1386`)
```
              tg_codes_ok && AgTgCodeFromText("S5") == 0 && AgTgCodeFromText("S23") == 0
```
with
```
              tg_codes_ok && AgTgCodeFromText("S5") == AG_TG_S5 && AgTgCodeFromText("S25") == AG_TG_S25
              && AgTgCodeFromText("S23") == 0
```
- Check: the code count reads 23 at its seven sites, `int tg_codes[23]`, `ArrayResize(tg_ev, 23);`, both `for(int k = 0; k < 23; k++)`, `tg_ev, 23);`, `tg_count, 23);` and `(tg_count == 23)`, and none of `[21]`, `tg_ev, 21`, `k < 21`, `tg_count, 21` or `tg_count == 21` is left in the file; `AG_TG_S21` and the date, money and login literals that hold 21 stay as they are. The check names are unchanged, so the count of checks is unchanged by this step.
- Commit: `vectors: the queue round trip over the 23 codes, S5 and S25 known`

### B9. The vectors: the Manual Lockout block

Same file. Insert after the line (`VEC:1549`)
```
   AgVecCheck("tg_line_stopping", AgTgStoppingLine(0) == "alerts service stopping|unsent=0", "");
```
one blank line and then this text, which lies above the generated block of TG-S8 and is not touched by `gen_vectors.py`:
```
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
```
- Check: the block adds 87 checks, each name beginning `ml_`; no `GlobalVariable` call in it; it lies above the TG-S8 head comment.
- Commit: `vectors: the Manual Lockout block, 87 checks on the bounds, the parsers, the record family, the boot witness, the line shapes, the reason 3 silence and its S3 under ML-37`

### B10. gen_vectors.py, and the vectors regenerated

File `scripts/rows/gen_vectors.py`, five changes, then a run.

Replace
```
# helpers gain the PNL line and the open trades line.
```
with
```
# helpers gain the PNL line and the open trades line.
#
# The Manual Lockout build of 2026-10-22 (ML-17 (A)): the drafts under labels
# that begin "ML:", S5 at the engagement (ML-30), S25 at the lockout's own end,
# its wording list and the S17 name of the lockout's record; and one helper,
# R4 and ML-31 for S5.
```
Insert before the line `def esc_html(s):`:
```
# the Manual Lockout build: S5 at the engagement, S25 outcomes 1 and 2, the
# S25 wording list and the S17 file name of kind 6
s5c = C("2026.10.22 14:30:05", "2544.33", "2544.33", "0.0", A, "139.94", SL)
s25a = C("2026.10.22 15:00:10", "2530.10", "2530.10", "-14.23", L, "139.94", SL)
cases += [
 ("ml_s5_engaged", "ML: S5 Manual Lockout engaged, a position open", None,
  C("2026.10.22 14:30:05", "2544.33", "2530.10", "-14.23", A, "139.94", SL, 1),
  NOB % "AgTgTextS5(c, D'2026.10.22 15:00:05', D'2026.10.23 01:00:00', 1800, 1, 0)"),
 ("ml_s5_engaged_flat", "ML: S5 Manual Lockout engaged, nothing open", None, s5c,
  NOB % "AgTgTextS5(c, D'2026.10.22 15:30:05', D'2026.10.23 01:00:00', 3600, 0, 0)"),
 ("ml_s5_until_the_anchor", "ML: S5 Manual Lockout until the next daily anchor", None, s5c,
  NOB % "AgTgTextS5(c, D'2026.10.23 01:00:00', D'2026.10.23 01:00:00', 37795, 0, 0)"),
 ("ml_s25_released", "ML: S25 Manual Lockout ended", None,
  C("2026.10.22 15:00:10", "2544.33", "2544.33", "0.0", A, "139.94", SA),
  NOB % "AgTgTextS25(c, 1, D'2026.10.22 15:00:05', 0, 0)"),
 ("ml_s25_again", "ML: S25 Manual Lockout ended, the account stays locked", None, s25a,
  NOB % "AgTgTextS25(c, 2, D'2026.10.22 15:00:05', D'2026.10.23 01:00:00', 3)"),
]
for i, reason in enumerate([3, 1, 2]):
    cases.append(("ml_s25_why_%d" % reason, "ML: S25 why the account stays locked, in order: a close by the guardian, the daily loss, a corrupt state file", i,
                  s25a, "AgVecLine(AgTgTextS25(c, 2, D'2026.10.22 15:00:05', D'2026.10.23 01:00:00', %d), %d)" % (reason, EV + 1)))
cases.append(("ml_s17_file_6", "ML: S17 the name of the lockout's record", 0, s17c,
              "AgVecLine(AgTgTextS17(c, 6, 1), %d)" % EV))


```
Insert before the line `def mql_str(s):`:
```
# the Manual Lockout build, R4 and ML-31: S5 leaves the open trades line out,
# its sweep line giving the count; S25 keeps it
helpers_ml = [
 ("ml_fmt_open_line_left_out_of_s5_with_its_sweep_line", "truec",
  "StringFind(AgTgTextS5(c, D'2026.10.22 15:00:05', D'2026.10.23 01:00:00', 1800, 3, 0), AgTgOpenLine(3)) < 0"
  " && StringFind(AgTgTextS25(c, 1, D'2026.10.22 15:00:05', 0, 0), AgTgOpenLine(3)) > 0", s4c),
]


```
Replace
```
emit(helpers_b5)
```
with
```
emit(helpers_b5)
code.append("")
code.append("   //--- the Manual Lockout build, R4 and ML-31: the open trades line left")
code.append("   //--- out of S5, whose sweep line counts, and kept in S25")
emit(helpers_ml)
```
Replace
```
sys.stdout.buffer.write(("render vectors %d, helper vectors %d, of which pass B5 %d, drafts not rendered by any vector: %s\n"
                         % (len(cases), len(helpers) + len(helpers_b5), len(helpers_b5), unused)).encode("utf-8"))
```
with
```
sys.stdout.buffer.write(("render vectors %d, helper vectors %d, of which pass B5 %d and the Manual Lockout build %d,"
                         " drafts not rendered by any vector: %s\n"
                         % (len(cases), len(helpers) + len(helpers_b5) + len(helpers_ml), len(helpers_b5),
                            len(helpers_ml), unused)).encode("utf-8"))
```
Then run `python -I scripts/rows/gen_vectors.py` from the repository root.
- Check: the run prints the Manual Lockout build count as 1, and its list of drafts not rendered names no `ML:` label; `git diff --stat` on the vectors file shows the generated block only; `python -I scripts/rows/tg_s7.py` exits 0 with `TG-S7 HOLDS`, and every per template line of a `tg_text_ml_` case ends `identical`; `python -I scripts/rows/compile.py MQL5/Scripts/AccountGuardian/AgPhase2StateVectors.mq5 ml-vec2 <log folder>` and the same for `MQL5/Scripts/AccountGuardian/AgPhase1ClockVectors.mq5` with tag `ml-vec1` print `Result: 0 errors, 0 warnings`, no including line outside the worktree, and fresh ex5 files. The vectors script now carries 619 checks: the 522 of `LEDGER.md:6`, the 87 of B9, and the 10 of this step (9 render cases and 1 helper).
- Commit: `vectors: TG-S8 regenerated with the Manual Lockout drafts, 619 checks`

### B11. scripts/rows/ml_rows.py, new

File `scripts/rows/ml_rows.py`, new, this text:

```
# Static rows ML-S2 to ML-S18 of the Manual Lockout build, plan
# docs/PLAN_MANUAL_LOCKOUT_2026-10-22.md section 8, measured on the committed
# tree at HEAD against cce862a, the commit the plan was cut from. ML-S1 is the
# compiles of compile.py. ML-S12 runs static_rows.py; ML-S13 runs
# gen_vectors.py and tg_s7.py.
#
# Usage: python -I scripts/rows/ml_rows.py [repository root]
# Exit code 0 when every check holds, 1 otherwise.
import os, re, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
WT = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(HERE))
BASE = "cce862a"
EA = "MQL5/Experts/AccountGuardian/AccountGuardian.mq5"
INC = "MQL5/Include/AccountGuardian/"
ML = INC + "ManualLockout.mqh"
PANEL = INC + "LockoutPanel.mqh"
SVC = "MQL5/Services/AccountGuardian/AccountGuardianAlerts.mq5"
VEC = "MQL5/Scripts/AccountGuardian/AgPhase2StateVectors.mq5"


def git(*args):
    return subprocess.run(["git", "-C", WT] + list(args), capture_output=True).stdout


def show(rev, path):
    return git("show", rev + ":" + path).decode("utf-8", "replace").replace("\r\n", "\n")


def now(path):
    return open(os.path.join(WT, path), "rb").read().decode("utf-8", "replace").replace("\r\n", "\n")


def code_only(line):
    return re.sub(r'"(?:[^"\\]|\\.)*"', '""', line).split("//")[0]


def code_of(src):
    return "\n".join(code_only(l) for l in src.split("\n"))


def func(src, sig):
    i = src.find(sig)
    if i < 0:
        return None
    j = src.index("{", i)
    depth = 0
    for k in range(j, len(src)):
        if src[k] == "{":
            depth += 1
        elif src[k] == "}":
            depth -= 1
            if depth == 0:
                return src[i:k + 1]
    return None


FDEF = re.compile(r"^(?:void|int|bool|string|double|long|ulong|uint|datetime)\s+(\w+)\s*\(")


def function_of_lines(src):
    """As static_rows.py: for each line number, the top level function it lies in, or '-'."""
    cur, depth, pending, out = "-", 0, False, {}
    for n, l in enumerate(src.split("\n"), 1):
        m = FDEF.match(l)
        if m and depth == 0:
            cur, pending = m.group(1), True
        out[n] = cur if (depth > 0 or pending) else "-"
        c = code_only(l)
        opened = "{" in c
        depth += c.count("{") - c.count("}")
        if pending and opened:
            pending = False
        elif pending and depth == 0 and ";" in c:
            pending = False
        if not pending and depth == 0:
            cur = "-"
    return out


out, bad = [], []


def check(name, ok, detail=""):
    out.append("%-4s %s%s" % ("OK" if ok else "FAIL", name, (": " + detail) if detail and not ok else ""))
    if not ok:
        bad.append(name)


def hits(pattern, paths, code=True):
    rx = re.compile(pattern)
    return ["%s:%d" % (f.split("/")[-1], n) for f in paths for n, l in enumerate(now(f).split("\n"), 1)
            if rx.search(code_only(l) if code else l)]


out.append("HEAD " + git("rev-parse", "HEAD").decode().strip() + ", compared with " + BASE)
files = [l for l in git("ls-files", "MQL5").decode().split("\n") if l.strip()]
base_files = [l for l in git("ls-tree", "-r", "--name-only", BASE, "MQL5").decode().split("\n") if l.strip()]

# ---- ML-S2: Pnl.mqh byte identical; every input line identical
check("ML-S2 Pnl.mqh identical to " + BASE, show(BASE, INC + "Pnl.mqh") == now(INC + "Pnl.mqh"))
INPUT = re.compile(r"^\s*input\s")
inputs_base = sorted((f, l.strip()) for f in base_files for l in show(BASE, f).split("\n") if INPUT.match(l))
inputs_now = sorted((f, l.strip()) for f in files for l in now(f).split("\n") if INPUT.match(l))
check("ML-S2 every input line in MQL5/ identical", inputs_base == inputs_now,
      "%d at the base, %d now" % (len(inputs_base), len(inputs_now)))

# ---- ML-S3: the files the build leaves alone
for p in ("Clock.mqh", "State.mqh", "Persist.mqh", "Log.mqh", "Pnl.mqh", "Sweep.mqh", "SweepPolicy.mqh",
          "AlertJson.mqh"):
    check("ML-S3 %s identical" % p, show(BASE, INC + p) == now(INC + p))
p = "MQL5/Scripts/AccountGuardian/AgPhase1ClockVectors.mq5"
check("ML-S3 AgPhase1ClockVectors.mq5 identical", show(BASE, p) == now(p))

# ---- ML-S4: five protected functions identical; AgEvaluateLocked the base with its two lines
for path, sig in ((EA, "void AgEvaluateActive()"), (EA, "int AgBootDerivation("), (EA, "void AgDeclareLock("),
                  (EA, "void AgEnterLockFromBoot("), (INC + "State.mqh", "void AgTransition(")):
    a, b = func(show(BASE, path), sig), func(now(path), sig)
    check("ML-S4 %s identical" % sig.split("(")[0].split()[-1], a is not None and a == b)
OLD = ('   datetime now_server = AgServerNow();\n'
       '   if(now_server >= g_ag_locked_until)\n'
       '     {\n'
       '      AgInfo("lock expired|locked_until=" + TimeToString(g_ag_locked_until, TIME_DATE | TIME_SECONDS)\n')
NEW = ('   datetime now_server = AgServerNow();\n'
       '   datetime lock_end   = AgManualEffectiveEnd(g_ag_locked_until, g_ag_ml_active, g_ag_ml_end);   // ML-7\n'
       '   if(now_server >= lock_end)\n'
       '     {\n'
       '      AgInfo("lock expired|locked_until=" + TimeToString(lock_end, TIME_DATE | TIME_SECONDS)\n')
b = func(show(BASE, EA), "void AgEvaluateLocked()")
check("ML-S4 AgEvaluateLocked is the base with its two lines changed and nothing else",
      b is not None and b.count(OLD) == 1 and b.replace(OLD, NEW) == func(now(EA), "void AgEvaluateLocked()"))

# ---- ML-S5: the trade API family on the same lines as at the base; AgSweepPass at its two sites
TRADE = re.compile(r"OrderSend|OrderSendAsync|CTrade|PositionClose|OrderDelete|Trade\.mqh|TRADE_ACTION_")
t_base = sorted((f, l.strip()) for f in base_files for l in show(BASE, f).split("\n") if TRADE.search(l))
t_now = sorted((f, l.strip()) for f in files for l in now(f).split("\n") if TRADE.search(l))
check("ML-S5 the trade API lines are the base's", t_base == t_now, "%d at the base, %d now" % (len(t_base), len(t_now)))
sites = sorted(l.strip() for f in files for l in now(f).split("\n")
               if re.search(r"\bAgSweepPass\s*\(", code_only(l)) and "void AgSweepPass" not in l)
check("ML-S5 AgSweepPass at its two call sites", sites == ['AgSweepPass("accelerated");', 'AgSweepPass("timer");'],
      str(sites))

# ---- ML-S6: no blocking call, no dialog library, no mouse move events
for name, pattern, paths, code in (("MessageBox", r"\bMessageBox\b", files, False),
                                   ("Sleep outside the service", r"\bSleep\s*\(", [f for f in files if f != SVC], True),
                                   ("Controls include", r"#include\s*<Controls", files, False),
                                   ("CHART_EVENT_MOUSE_MOVE", r"CHART_EVENT_MOUSE_MOVE", files, False)):
    h = hits(pattern, paths, code)
    check("ML-S6 zero " + name, not h, str(h))

# ---- ML-S7: nothing deleted
h = hits(r"\b(FileDelete|FolderDelete|GlobalVariableDel|GlobalVariablesDeleteAll)\b", files)
check("ML-S7 zero deletes", not h, str(h))

# ---- ML-S8: no clock but TimeCurrent in the two new includes, comments included
h = hits(r"\b(TimeLocal|TimeGMT|TimeTradeServer|GetTickCount)\b", [ML, PANEL], False)
check("ML-S8 no other clock named in the two new includes", not h, str(h))

# ---- ML-S9: the lockout never writes the loss lock
LOSS_W = re.compile(r"\b(g_ag_locked_until|g_ag_lock_reason|g_ag_state_\w+)\s*(=(?!=)|\+=|-=)")
BOUNDS = re.compile(r"\b(AgLockedUntilComputed|AgLockedUntilFromWitness|AgApplyLatchFloor|AgLatchFloor|AgStateSave|"
                    r"AgStateSetBreach|AgStateSetCorrupt|AgStateResetModel|AgStateQuarantine|AgEnterLockFromBoot|"
                    r"AgDeclareLock|AgFloorSave|AgPeakSave|AgHaltSave)\s*\(")
h = ["%s:%d" % (f.split("/")[-1], n) for f in (ML, PANEL) for n, l in enumerate(now(f).split("\n"), 1)
     if LOSS_W.search(code_only(l)) or BOUNDS.search(code_only(l))]
check("ML-S9 the two new includes write no loss lock field and call no bound or loss lock writer", not h, str(h))
h = ["EA:%d" % n for n, l in enumerate(now(EA).split("\n"), 1)
     if re.search(r"\bg_ag_ml_\w+", code_only(l)) and (LOSS_W.search(code_only(l)) or BOUNDS.search(code_only(l)))]
check("ML-S9 no EA line naming a lockout global writes the loss lock or calls its bounds", not h, str(h))
h = hits(r"GlobalVariableSet\s*\(\s*AgGvLock\s*\(", files)
check("ML-S9 AG_LOCK_<login> written at one site", len(h) == 1, str(h))

# ---- ML-S10: the transitions by function
ea = now(EA)
where = function_of_lines(ea)
trans = {}
for n, l in enumerate(ea.split("\n"), 1):
    m = re.search(r"\bAgTransition\s*\(\s*(AG_STATE_\w+)", code_only(l))
    if m:
        trans.setdefault(m.group(1), set()).add(where[n])
out.append("     ML-S10 transitions by target state: %s" % {k: sorted(v) for k, v in sorted(trans.items())})
check("ML-S10 into LOCKED only from the four entries", trans.get("AG_STATE_LOCKED") ==
      {"AgDeclareLock", "AgEnterLockFromBoot", "AgManualApplyPending", "AgEnterManualLockFromBoot"})
check("ML-S10 into SYNCING only from AgEvaluateLocked and OnInit",
      trans.get("AG_STATE_SYNCING") == {"AgEvaluateLocked", "OnInit"})
check("ML-S10 into ACTIVE only from OnTimer", trans.get("AG_STATE_ACTIVE") == {"OnTimer"})

# ---- ML-S11: OnChartEvent calls the panel only; the panel writes chart objects and its own globals
body = func(ea, "void OnChartEvent(")
calls = set(re.findall(r"\b([A-Za-z_]\w*)\s*\(", code_of(body).split("{", 1)[1])) if body else {"<missing>"}
check("ML-S11 OnChartEvent calls AgPanelOnEvent only", calls == {"AgPanelOnEvent"}, str(sorted(calls)))
panel = code_of(now(PANEL))
FORBID = re.compile(r"\b(FileOpen|FileMove|FileWrite\w*|FileFlush|AgAtomicWrite|GlobalVariableSet\w*|"
                    r"GlobalVariablesFlush|AgTransition|AgManualSave|AgManualLoad|AgManualQuarantine|"
                    r"AgManualHealRecord|AgSweep\w*|AgStateSave|OrderSend\w*|OrderDelete|PositionClose|CTrade)\b")
f = sorted(set(FORBID.findall(panel)))
check("ML-S11 the panel holds no file or GV write, transition, record write, sweep or trade name", not f, str(f))
targets = sorted(set(re.findall(r"\b(g_ag_\w+)(?:\.\w+)?(?:\[[^\]]*\])?\s*(?:[+\-*/|&]?=)(?!=)", panel)))
check("ML-S11 the panel assigns its own g_ag_panel_ globals only",
      targets != [] and all(t.startswith("g_ag_panel_") for t in targets), str(targets))

# ---- ML-S12: the TG and installer rows, run again
r = subprocess.run([sys.executable, "-I", os.path.join(HERE, "static_rows.py"), WT], capture_output=True)
sr = r.stdout.decode("utf-8", "replace")
out.append("     ML-S12 static_rows.py:")
out.extend("       " + l for l in sr.splitlines())
tg15 = [l for l in sr.splitlines() if l.startswith("TG-S15 ")]
check("ML-S12 TG-S15: AgEvaluateLocked CHANGED by design, the other five IDENTICAL",
      len(tg15) == 6 and all(l.endswith("IDENTICAL") != (" AgEvaluateLocked " in l) for l in tg15), str(tg15))
for e in ("the same line texts: True", "TG-S3 AgSweepPass call sites 2:",
          "in the EA and the includes it compiles: 0 []",
          "GlobalVariableSet on the two names aside: 0 []",
          "calls from the service's own four files into those writers: 0 []",
          "TG-S16 outside the allowed sites: []; in a protected function: []",
          "TG-S6 token shaped literals in the tree: 0", "TG-S6 UUID shaped literals in the tree: 0",
          "TG-S6 a non empty default on the three inputs: 0",
          "TG-S6 a journal, Alert or chart call carrying an input: 0",
          "naming rule LEDGER.md: bare uses 0", "naming rule docs/SPEC_v0.1.md: bare uses 0"):
    check("ML-S12 " + e, e in sr)
m = re.search(r"IN-S5 manifest lines (\d+), matching the HEAD blobs (\d+)", sr)
check("ML-S12 IN-S5 every manifest line matches its HEAD blob, 16 lines",
      m is not None and m.group(1) == m.group(2) == "16", m.group(0) if m else "not found")
m = re.search(r"IN-S6 README.md CR (\d+) LF (\d+), em dashes (\d+), secrecy hits (\d+) \{\}, development names \[\]", sr)
check("ML-S12 IN-S6 the README: CR equals LF, no em dash, no secrecy hit, no development name",
      m is not None and m.group(1) == m.group(2) and m.group(3) == "0" and m.group(4) == "0",
      m.group(0) if m else "not found")
check("ML-S12 the four PowerShell files of static_rows.py parse", sr.count(": errors 0") == 4)
cmd = ("$t=$null; $e=$null; [void][System.Management.Automation.Language.Parser]::ParseFile('"
       + os.path.join(WT, "scripts", "deploy-ml.ps1") + "', [ref]$t, [ref]$e); $e.Count")
r = subprocess.run(["pwsh", "-NoProfile", "-NonInteractive", "-Command", cmd], capture_output=True)
check("ML-S12 scripts/deploy-ml.ps1 parses", r.stdout.decode().strip() == "0",
      r.stdout.decode().strip() or r.stderr.decode().strip())

# ---- ML-S13: TG-S8 regenerated equals the committed vectors; TG-S7 on the new drafts
g = subprocess.run([sys.executable, "-I", os.path.join(HERE, "gen_vectors.py"), WT], capture_output=True)
gtext = g.stdout.decode("utf-8", "replace").strip()
out.append("     ML-S13 gen_vectors.py: " + gtext)
st = git("status", "--porcelain", "--", VEC).decode().strip()
check("ML-S13 the committed vectors are what gen_vectors.py writes", g.returncode == 0 and st == "", st)
check("ML-S13 every ML draft rendered by a vector",
      "drafts not rendered by any vector:" in gtext and "'ML: " not in gtext.split("drafts not rendered by any vector:")[-1])
t = subprocess.run([sys.executable, "-I", os.path.join(HERE, "tg_s7.py"), WT], capture_output=True)
ttext = t.stdout.decode("utf-8", "replace")
check("ML-S13 TG-S7 holds", t.returncode == 0 and "TG-S7 HOLDS" in ttext)
ml_lines = [l for l in ttext.splitlines() if " tg_text_ml_" in l]
check("ML-S13 every Manual Lockout template renders its draft character for character",
      len(ml_lines) == 9 and all(l.rstrip().endswith("identical") for l in ml_lines),
      "%d lines: %s" % (len(ml_lines), [l for l in ml_lines if not l.rstrip().endswith("identical")]))

# ---- ML-S14: the EA and the two new includes ASCII after any byte order mark; the new ones carry none
for p in (EA, ML, PANEL):
    raw = open(os.path.join(WT, p), "rb").read()
    body = raw[3:] if raw[:3] == b"\xef\xbb\xbf" else raw
    check("ML-S14 %s ASCII" % p.split("/")[-1], all(x < 128 for x in body))
for p in (ML, PANEL):
    raw = open(os.path.join(WT, p), "rb").read()
    check("ML-S14 %s has no byte order mark" % p.split("/")[-1], raw[:3] != b"\xef\xbb\xbf")

# ---- ML-S15: the manifest lists both new includes; no secrecy pattern in a shipped file
listed = [l.split("  ", 1)[1] for l in now("installer/manifest.txt").strip().split("\n")]
check("ML-S15 the manifest lists ManualLockout.mqh and LockoutPanel.mqh", ML in listed and PANEL in listed, str(listed))
pats = [p.strip() for p in now("scripts/secrecy-patterns.txt").split("\n") if p.strip()]
sec = ["%s: %s" % (f, p) for f in listed for p in pats if re.search(p, now(f), re.IGNORECASE)]
check("ML-S15 no secrecy pattern in any shipped file", not sec, str(sec))

# ---- ML-S16: the Q9 hold
body = func(ea, "void AgManualApplyPending(")
check("ML-S16 a request waits while ACTIVE holds a deferred breach",
      body is not None and re.search(r"if\(g_ag_state == AG_STATE_ACTIVE && g_ag_breach_deferred_once\)\s*\n\s*return;",
                                     body) is not None)

# ---- ML-S17: ML-35 (1), the reason 3 silence
body = func(ea, "void OnDeinit(")
check("ML-S17 OnDeinit queues S2 only for a reason that is not silent, and sets the quiet flag from the same helper",
      body is not None
      and re.search(r"if\(!AgTgSilentReason\(reason\)\)\s*\n\s*AgTgPush\(AG_TG_S2, reason\);", body) is not None
      and "g_ag_tgp_quiet_start = AgTgSilentReason(reason);" in body)
named = sorted(set(where[n] for n, l in enumerate(ea.split("\n"), 1)
                   if re.search(r"\bg_ag_tgp_quiet_start\b", code_only(l))))
check("ML-S17 the quiet flag named only in its declaration, OnDeinit and AgTgProduce",
      named == ["-", "AgTgProduce", "OnDeinit"], str(named))
body = func(ea, "void AgTgProduce(")
check("ML-S17 the S1 and the S16 of the first start wait on the quiet flag",
      body is not None and "g_ag_tgp_s1_pending      = !g_ag_tgp_quiet_start;" in body
      and "if(!ml_only && !g_ag_tgp_quiet_start)" in body)
svc = now(SVC)
check("ML-S17 the service acknowledges a reason 3 stop and its start without a message",
      all(f is not None and "AgTgSilentReason(" in f
          for f in (func(svc, "void AgSvcConvertOne("), func(svc, "void AgSvcMerge("))))
check("ML-S17 AgTgSilentReason defined once, true for reason 3 alone",
      now(INC + "AlertQueue.mqh").count(
          "bool AgTgSilentReason(const int reason) { return reason == REASON_CHARTCHANGE; }") == 1)

# ---- ML-S18: ML-37, S3 after a reason 3 change unless the same SAFE_HALT was announced
body = func(ea, "void AgTgProduce(")
check("ML-S18 the S3 push waits on AgTgS3Silenced with the quiet flag, the record and the halt time",
      body is not None
      and re.search(r"if\(!AgTgS3Silenced\(g_ag_tgp_quiet_start, g_ag_tgp_s3_announced, g_ag_halt_time\)\)\s*\n"
                    r"\s*AgTgPush\(AG_TG_S3,", body) is not None)
h = hits(r"\bAgTgPush\s*\(\s*AG_TG_S3\b", [EA])
check("ML-S18 one S3 push in the EA", len(h) == 1, str(h))
wq = func(ea, "void AgTgQueueWrite(")
check("ML-S18 the successful queue write sets the record from the S3 it carried",
      wq is not None
      and re.search(r"if\(AgAtomicWrite\(AgTgQueuePath\(g_ag_login\), text, true\)\)\s*\n\s*\{[^}]*"
                    r"g_ag_tgp_s3_announced = AgTgS3HaltTimeIn\(g_ag_tgq_events, g_ag_tgq_count, "
                    r"g_ag_tgp_s3_announced\);[^}]*\}", wq) is not None)
named = sorted(set(where[n] for n, l in enumerate(ea.split("\n"), 1)
                   if re.search(r"\bg_ag_tgp_s3_announced\b", code_only(l))))
assigned = sorted(set(where[n] for n, l in enumerate(ea.split("\n"), 1)
                      if re.search(r"\bg_ag_tgp_s3_announced\s*=(?!=)", code_only(l))))
check("ML-S18 the record named only in its declaration, AgTgQueueWrite and AgTgProduce, assigned in AgTgQueueWrite alone",
      named == ["-", "AgTgProduce", "AgTgQueueWrite"] and assigned == ["-", "AgTgQueueWrite"],
      "named %s, assigned %s" % (named, assigned))
defs = [f for f in files for l in now(f).split("\n")
        if l.startswith("bool AgTgS3Silenced(") or l.startswith("datetime AgTgS3HaltTimeIn(")]
check("ML-S18 AgTgS3Silenced and AgTgS3HaltTimeIn defined once each, in AlertQueue.mqh",
      defs == [INC + "AlertQueue.mqh"] * 2
      and "   return quiet_start && announced != 0 && announced == halt_time;" in now(INC + "AlertQueue.mqh"),
      str(defs))

out.append("")
out.append("ML static rows " + ("HOLD" if not bad else "DO NOT HOLD: " + ", ".join(bad)))
sys.stdout.buffer.write(("\n".join(out) + "\n").encode("utf-8"))
sys.exit(1 if bad else 0)
```
- Check: `python -I -c "import ast; ast.parse(open('scripts/rows/ml_rows.py', encoding='utf-8').read())"` prints nothing and writes no file; the script itself runs at B17.
- Commit: `scripts: rows/ml_rows.py, the static rows ML-S2 to ML-S18 of the Manual Lockout build`

### B12. The installer manifest (ML-23 (A), ML-27 (A))

File `scripts/make-manifest.ps1`, the list `$shippedFiles` (`:22-37`), kept in name order. Replace
```
    'MQL5/Include/AccountGuardian/Log.mqh',
```
with
```
    'MQL5/Include/AccountGuardian/LockoutPanel.mqh',
    'MQL5/Include/AccountGuardian/Log.mqh',
    'MQL5/Include/AccountGuardian/ManualLockout.mqh',
```
Commit `scripts: make-manifest.ps1 ships ManualLockout.mqh and LockoutPanel.mqh`. Then, from the repository root, run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\make-manifest.ps1`, which reads the blobs at HEAD and writes `installer\manifest.txt` alone.
- Check: the manifest has 16 lines, both new includes among them; `installer/install.ps1` and `installer/install.cmd` are unchanged, since the installer compiles in the downloaded folder and copies the two compiled files only (`install.ps1:572`, `:581`).
- Commit: `installer: manifest regenerated, 16 shipped files`
- Rerun B12 after any later change to a shipped file, before B15.

### B13. SPEC (ML-26 (A), recorded under the ruling and not as a new amendment, the series being closed at A6)

File `docs/SPEC_v0.1.md`. Sixteen changes; "append" adds the text, after one space, to the end of the line named by its first words.

1. Append to the line beginning `Single account-level lockout EA for MetaTrader 5`: `A trader may also lock the account on demand from the EA's chart, the Manual Lockout, until a chosen end no later than the next day anchor; it cannot be cancelled or shortened, and while it holds the same sweep applies (rulings ML-1 to ML-27 of 2026-10-22, SPEC changes of the Manual Lockout build).`
2. Insert after the line beginning `MQL5/Include/AccountGuardian/AlertText.mqh` the two lines `MQL5/Include/AccountGuardian/ManualLockout.mqh     the Manual Lockout: model, record, bounds, parsers, line formats` and `MQL5/Include/AccountGuardian/LockoutPanel.mqh      the Manual Lockout panel on the EA's chart, chart objects only`, each description starting in the column the others start in.
3. Insert after the line beginning `MQL5/Files/AccountGuardian/tgqueue_<login>.dat` the line `MQL5/Files/AccountGuardian/manual_<login>.dat      the Manual Lockout's own record`, its description in the same column.
4. Append to the line beginning `- OnTimer at 1 s:`: `The Manual Lockout's request, its boot witness and its own end are decided here too (ML-1 to ML-27).`
5. Insert after the line `- OnTick: unused.` the line `- OnChartEvent: the Manual Lockout panel only. A click changes the panel's own stage or records one request, which OnTimer applies after the state dispatch; nothing here decides, writes a file or a GV, or reaches the sweep (F13 read onto the panel, rulings ML-1 to ML-27 of 2026-10-22, SPEC changes of the Manual Lockout build).`; and append to the line beginning `- OnDeinit:`: `A chart timeframe or symbol change, deinit reason 3, writes no stop event, the queue still written, and the init that follows sends no start message: reason 3 sends no Telegram message in any state (ML-35 (1), which supersedes TG-13 (B) for that reason alone).`
6. Append to the line beginning `Static-structure rule, checkable without running`: `ManualLockout.mqh and LockoutPanel.mqh contain no trade calls either (static row ML-S5).`
7. Append to the line beginning `lock_reason in {DAILY_BREACH, CORRUPT_STATE, SWEEP_WITNESS}.`: `The Manual Lockout is a second lock component beside lock_reason, never a lock_reason value: the account is LOCKED while either holds, the later end governs (ML-7), and the banner names it MANUAL_LOCKOUT while it governs.`
8. Replace the table row `| SYNCING | LOCKED | state file, GV mirror, or derived breach (4.6) says locked | adopt strictest witness |` with `| SYNCING | LOCKED | state file, GV mirror, or derived breach (4.6) says locked, or the Manual Lockout's record or GV mirror holds an end after now | adopt strictest witness; the lockout's end, cut to the next day anchor of now, is held beside it |`.
9. Insert after the table row beginning `| ACTIVE | LOCKED (DAILY_BREACH) |` the row `| ACTIVE | LOCKED (Manual Lockout) | the trader confirms a Manual Lockout on the panel; OnTimer applies it after the dispatch, a breach the Q9 deferral holds being declared first | record and GV mirror written, the end after the confirmation and no later than the next day anchor, the Q6 input witness seeded, the sweep as for DAILY_BREACH; an extension, to a later end only, stays in LOCKED (ML-1 to ML-27) |`.
10. Replace the table row `| LOCKED | ACTIVE | TimeCurrent >= locked_until | log unlock; never any other cause |` with `| LOCKED | SYNCING | TimeCurrent >= the effective end, the later of locked_until and the Manual Lockout's end (ML-7) | log unlock; never any other cause; history stability and the boot derivation run before the next breach decision (shape A of 2026-08-20) |`.
11. Append to the line beginning `Rollover resets counters; it never unlocks by itself.`: `A Manual Lockout is released by its own end alone, never by the rollover or the daily reset (ML-6), and its end is never later than the next day anchor (ML-4).`
12. Replace the line `Single file MQL5/Files/AccountGuardian/state_<login>.dat carrying lock state only:` with `The state file MQL5/Files/AccountGuardian/state_<login>.dat carries the loss lock's state only:`, and insert after the line beginning `magic, format version, account login, lock_reason` one blank line and the paragraph `The Manual Lockout has its own record, MQL5/Files/AccountGuardian/manual_<login>.dat (ML-18 (A)): magic AGMANUAL, format version 1, account login, the active flag, the first and the latest confirmation, the end, the form and the minutes, then the same checksum, written through the same atomic path. Its GV mirror AG_MANUAL_<login> holds the bare end, 0 when no lockout holds, written each tick in ACTIVE and LOCKED under the same state gate as AG_LOCK_<login>. While a lockout holds, the record is read back every AG_LIFE_INTERVAL_SECONDS timer ticks and written again when missing or different, a different one first moved aside under a quarantine name. A record that fails its checksum or its parse, carries another login, or ends past the next day anchor of its first confirmation is quarantined with a WARN and S17, and the GV mirror alone decides; with neither, no lockout (ML-19 (A)). Nothing is ever deleted.`
13. Append to the line beginning `- TimeCurrent >= locked_until. No other unlock path exists.`: `The Manual Lockout ends at TimeCurrent >= its own end, and the account leaves LOCKED when the effective end, the later of the two components, has passed, through the same expiry path into SYNCING (ML-6, ML-7).`
14. Append to the line beginning `LOCKED at boot = OR over four witnesses`: `The Manual Lockout's own boot witness is weighed after the derivation and outside it: the valid record or the GV mirror, the later end, cut to the next day anchor of now with no floor after it (ML-9); it never changes locked_until or lock_reason.`
15. Append to the line beginning `- Alert popups mandatory for:`: ``The Manual Lockout's ALERTs read `MANUAL_LOCKOUT: account LOCKED until <t>. Flattening <n> positions and deleting <m> pending orders.` at the engagement, `MANUAL_LOCKOUT: lockout extended until <t>.` at an extension, and `LOCKED at boot by derivation (MANUAL_LOCKOUT) until <t>. Flattening <n> positions and deleting <m> pending orders.` at a restore (ML-21).``; append to the line beginning `- Chart banner always shows:`: `While a Manual Lockout governs, the lock reason reads MANUAL_LOCKOUT and locked_until the effective end; the Manual Lockout panel in the upper right corner shows the end and the time left (ML-16).`; append to the line beginning `- Proof-of-life journal line in every state`: ``While a Manual Lockout holds, the LOCKED numbers group ends `|manual_end=<t>`, after the sweep field and outside the six D2D4 fields, as ENF-17(b) appended the sweep field, and waiting_on reads `expiry: TimeCurrent >= manual_end` while the lockout governs (ML-16, ML-21).``; and insert after the line beginning `- Alerts (owner ruling of 2026-10-21` the line ``- Manual Lockout (ML-21): the lines of plan docs/PLAN_MANUAL_LOCKOUT_2026-10-22.md section 4.7, among them `manual lockout engaged|...`, `manual lockout refused|why=<why>|at=<panel|apply>|...`, `manual lockout expired|...`, `boot witness MANUAL fired|...` and `manual lockout record rewritten|why=<missing|differs>`.``
16. Append to the line beginning `Prevented (with layered witnesses):`: `The Manual Lockout's record and GV mirror carry it across detach and re-attach, recompile, an input change and a terminal restart (ML-18).`; and append to the line beginning `Accepted residuals, documented:`: `The Manual Lockout holds only while the EA runs on its chart, kill equivalent while it does not; with the EA stopped, deleting both its record and its GV mirror by hand removes a lockout during which the guardian closed nothing (ML-20 (A), accepted friction beside the file plus GV residual), while one during which it closed a position is rebuilt to the next day anchor by the SWEEP witness (ML-8); a corrupt record with no GV mirror errs unlocked (ML-19 (A)).`

- Check: no U+2014 or U+2013 added; the naming rule's bare count for the SPEC stays 0 at B17; every change cites its ML number.
- Commit: `spec: the Manual Lockout under rulings ML-1 to ML-27, layout, event model, state table, persistence, expiry, boot witness, logging and threat model`

### B14. README, Hebrew only (ML-26 (A), ML-27 (A))

File `README.md`, CRLF in the working tree kept. Insert before the line `## ❓ שאלות ותשובות` this text and one blank line:
```
## ⏸️ נעילה ידנית

אפשר לנעול את החשבון ביוזמתך, לזמן שתבחר, מהגרף שעליו השומר פועל. נעילה ידנית סוגרת את הפוזיציות ומוחקת את הפקודות הממתינות בדיוק כמו נעילה על הפסד, ואי אפשר לבטל אותה או לקצר אותה.

איך נועלים:

1. בפינה הימנית העליונה של הגרף לוחצים על `Manual Lockout`.
2. בוחרים מתי הנעילה תסתיים: `15 minutes`, `30 minutes`, `1 hour`, או `End of session` עד תחילת יום המסחר הבא. אפשר גם לרשום מספר דקות וללחוץ על `Custom`, או לרשום שעת סיום בשעון השרת בצורה `HH:MM` וללחוץ על `End time`.
3. בודקים את הסיכום: מספר החשבון, שעת הסיום ומה ייסגר. לוחצים על `Lock Account` כדי לנעול, או על `Back` כדי לחזור. אם לא לוחצים תוך דקה, הסיכום נסגר מעצמו.

מה חשוב לדעת:

* נעילה ידנית מסתיימת לכל המאוחר בתחילת יום המסחר הבא, בשעה 01:00 בשעון השרת.
* אפשר להאריך נעילה ידנית שכבר פועלת, עם `Extend`, רק לשעה מאוחרת יותר ורק עד תחילת יום המסחר הבא. אי אפשר לקצר אותה.
* אם השומר סוגר פוזיציה בזמן הנעילה, החשבון נשאר נעול עד תחילת יום המסחר הבא.
* אם יש באותו זמן גם נעילה על הפסד, הנעילה שמסתיימת מאוחר יותר היא הקובעת.
* הנעילה נשמרת גם אחרי סגירה והפעלה מחדש של הטרמינל, ועל הגרף רואים כמה זמן נשאר.
* השומר אוכף את הנעילה רק כל עוד הטרמינל פתוח והשומר פועל על הגרף.
* אם השומר כבוי ומוחקים ביד גם את קובץ הנעילה הידנית וגם את המשתנה הגלובלי שלה, נעילה ידנית שבזמנה השומר לא סגר שום פוזיציה לא חוזרת.
```
Then, in the answer of the same file's question on releasing a lock by deleting files (`README.md:113`), replace
```
חוץ מהמקרה האחד שכתוב למעלה.
```
with
```
חוץ משני המקרים שכתובים למעלה.
```
- Check: the README's CR count equals its LF count; no em dash; no pattern of `scripts/secrecy-patterns.txt`; no development name of IN-S6 (`docs/`, `scripts/`, `LEDGER`, `PLAN_`, `deploy-`, and the rest of that row's list). IN-S6 at B17 closes it.
- Commit: `readme: the Manual Lockout, Hebrew panel steps`

### B15. The build identity (standing rules 6 and 7, ML-S1)

No file changes. At HEAD, with every source committed, run the four compiles: `python -I scripts/rows/compile.py <source> <tag> <log folder>` for `MQL5/Experts/AccountGuardian/AccountGuardian.mq5` (`ml-ea`), `MQL5/Services/AccountGuardian/AccountGuardianAlerts.mq5` (`ml-svc`), `MQL5/Scripts/AccountGuardian/AgPhase2StateVectors.mq5` (`ml-vec2`) and `MQL5/Scripts/AccountGuardian/AgPhase1ClockVectors.mq5` (`ml-vec1`).
- Check: each prints `Result: 0 errors, 0 warnings`, no including line outside the worktree, and its ex5 FRESH; the report states the `metaeditor.log` side effect of rule 3, as ML-29 requires of every compile report. Record for the report: HEAD's full hash as the source commit; the md5 of the EA, the service, both vectors sources and every include under `MQL5/Include/AccountGuardian/`, each against its HEAD blob; each ex5's md5, bytes and timestamp, the md5 recorded and not identity.

### B16. scripts/deploy-ml.ps1, new (ML-25 (A))

File `scripts/deploy-ml.ps1`, new, the 2026-09-06 shape, this text with the five values filled from B15 and the build worktree's absolute path in place of `<WORKTREE>`:
```
# deploy-ml.ps1
# ML deploy, the Manual Lockout build, rulings ML-1 to ML-27 of 2026-10-22, to the demo terminal of TG-10 (A), under the 2026-09-06 deploy hand shape as ML-25 (A) extends it. THE OWNER RUNS THIS. The executor never runs it.
# Three Copy-Item lines from the worktree into the Terminal data folder, each followed by Get-FileHash of the landed path, in the order of ML-25 (A): the alerts service first (F5 of the plan), then the EA, then the vectors script.
# No deletes, no renames, no variables, no functions. Every path literal. No folder is created.
# Expected md5 of each file as compiled in the worktree on <DATE> from source commit <SOURCE COMMIT>, standing rule 7: recorded, not identity.
#   AccountGuardianAlerts.ex5    <MD5>  <BYTES> bytes
#   AccountGuardian.ex5          <MD5>  <BYTES> bytes
#   AgPhase2StateVectors.ex5     <MD5>  <BYTES> bytes
# Before running: stop the running AccountGuardianAlerts instance (Navigator, Services, right click, Stop), so the service file is not in use. The terminal and the guardian keep running; whether the guardian reloads from its new file by itself or is attached again by hand, its init line names build=ML (row ML-D).
# After running: start the service again (Navigator, Services, right click, Start).

Copy-Item -LiteralPath '<WORKTREE>\MQL5\Services\AccountGuardian\AccountGuardianAlerts.ex5' -Destination 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Services\AccountGuardianAlerts.ex5' -Force
Get-FileHash -Algorithm MD5 -LiteralPath 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Services\AccountGuardianAlerts.ex5' | Format-List Algorithm, Hash, Path

Copy-Item -LiteralPath '<WORKTREE>\MQL5\Experts\AccountGuardian\AccountGuardian.ex5' -Destination 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\AccountGuardian\AccountGuardian.ex5' -Force
Get-FileHash -Algorithm MD5 -LiteralPath 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\AccountGuardian\AccountGuardian.ex5' | Format-List Algorithm, Hash, Path

Copy-Item -LiteralPath '<WORKTREE>\MQL5\Scripts\AccountGuardian\AgPhase2StateVectors.ex5' -Destination 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Scripts\AccountGuardian\AgPhase2StateVectors.ex5' -Force
Get-FileHash -Algorithm MD5 -LiteralPath 'C:\Users\www83\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Scripts\AccountGuardian\AgPhase2StateVectors.ex5' | Format-List Algorithm, Hash, Path
```
- Check: no placeholder in angle brackets is left; the script parses (ML-S12 at B17); the executor does not run it.
- Commit: `scripts: deploy-ml.ps1, the Manual Lockout deploy for the owner, service first`

### B17. The static rows, the ledger, the hand-off

Run `python -I scripts/rows/ml_rows.py` from the repository root.
- Check: it prints `ML static rows HOLD` and exits 0; ML-S1 is B15's four compile results. Any FAIL stops the build under rule 4.
- LEDGER: one ACTIONS entry of at most 1,500 characters for the build, with its commits and the ML-S results; the ISSUES entry of this plan replaced by one naming the next acts in this order: the owner stops the service and runs `scripts/deploy-ml.ps1` (ML-D); the executor verifies each landed file with a plain `Get-FileHash`, read only; the owner starts the service, attaches or lets the EA reload, and pastes the init lines; the owner runs the vectors (ML-0, `AGVEC|SUMMARY|619/619`); then the live rows of stage 1 in section 8's run order, then stage 2 on the live account's computer, and only then the release of ML-27 (A). Commit `ledger: the Manual Lockout build recorded, the owner's deploy and acceptance rows named in ISSUES`.
- STOP. No deploy, no live row, no push, no merge: those are the owner's.

## 12. What this plan does not do

- No source, include, script, vector, preset, installer or SPEC change; no README change; no compile; no MetaEditor run; no deploy.
- Nothing under any terminal data folder read or written by the executor.
- No network use but reading the public Tradovate and NinjaTrader pages of section 1.4.
- No merge, no push, no branch or worktree deleted.
- No ruling added: section 9 shows the owner's rulings; the executor's details of section 11 are marked as such.

Points for the owner, raised on 2026-10-22 and ruled the same day, ML-28 to ML-33, FINAL at `bcb71cc` (`LEDGER.md:616-632` as at that commit), each ruling as given:
1. The open TG rows of R2 (`LEDGER.md:5-7`) run on the same demo terminal: whether they close before the ML deploy or may close on the ML binaries, as the ENF-31 precedent allowed (`LEDGER.md:434`). ML-28: "Section 12 point 1: the open TG rows of R2 may close on the ML binaries, as the ENF-31 precedent allowed." The run order note of section 8 follows it.
2. RULE A and the compiles. Every compile by `scripts/rows/compile.py` makes MetaEditor append one `Compile` line to `logs\metaeditor.log` of the data folder `D0E8209F77C8CF37AD8BF550E51FF075`, whatever `/log` names, measured and disclosed at `docs/evidence/tg-b5.md:76`; the executor writes nothing there itself. RULE A forbids any write under that folder by any means (`LEDGER.md:159`), and the 2026-09-06 hand forbids invoking anything that writes there (`LEDGER.md:171`). ML-29: "Section 12 point 2: compiling through scripts/rows/compile.py is allowed. The one Compile line MetaEditor appends to logs\metaeditor.log in the terminal data folder is an accepted side effect, stated in every compile report. No other write there." Rule 3 of section 11.1 and B15 follow it; the first compile no longer waits.
3. ML-17 (A) says S5 "at engage". The plan had read it as covering three starts of a lockout: the engagement, a restore at a start, and an extension. ML-30: "Section 12 point 3: S5 is sent at the engagement only. No S5 at a restore at start and none at an extension." Sections 4.8, 8 and 11 follow it. It leaves two gaps, ML-34 and ML-35 below.
4. R4 leaves the open trades line out of "the lock messages that carry the sweep line (S4, its daily peak variant, and S16)". ML-31: "Section 12 point 4: every S5 that carries the sweep line leaves the open trades line out, as S4 and S16 do." Under ML-30 that is every S5 (B6, the helper of B10).
5. When a lockout and a loss lock end on the same tick, which message describes the release. ML-32: "Section 12 point 5: when a lockout and a loss lock end on the same tick, S8 alone is sent." Section 4.8 and B5.11 follow it.
6. A click on the greyed Extend journaled `manual lockout refused` with `form=none`, there being no end chosen. ML-33: "Section 12 point 6: a click on the greyed Extend writes no journal line." The panel note stays (B3); section 4.7 names no form `none`; ML-L7 and ML-L10 read the note.

Gaps ML-30 left, raised 2026-10-22 and ruled the same day, ML-34 and ML-35, FINAL at `e1a931a` (`LEDGER.md:634-641` as at that commit), each ruling as given below its options, which stay for the record.

ML-34. A start into a lockout alone: a terminal restart, a hard kill, the EA removed and attached again, or an in place reinit, while a lockout alone holds. At the first SYNCING exit after an init the producer sends S1 into ACTIVE and S16 into a loss lock (`EA:1499-1525`). S16 never describes a lockout (ML-17 (A)) and no S5 is sent at a restore (ML-30), so this start sends nothing.
- (A) Nothing at such a start. No new text and no new code. Telegram says nothing of the start until the next periodic status slot, at most four hours (TG-15 (A)), the command reply, or S25 at the lockout's end; the status and the reply carry the lockout's effective end (B5.9). A stop for reasons 1, 4 and 9 still sends S2 (TG-13 (B)), so a stop can stand with no start after it until then.
- (B) A start message for this case: a new S1 form whose lock line gives the lockout's end, where S1's reads none today (`AlertText.mqh:384`). A new Hebrew draft added to addendum item 13 first, under F1 to F11 (ML-17 (A)), a new render, its vector case, and a producer push at the first SYNCING exit into a lockout alone. S1 is none of S4, S8 and S16, so ML-17 (A) and ML-30 hold; the build line follows F9 as for S1.
- (C) S1 deferred to the lockout's release: the start told at the first completed ACTIVE pass after it, beside S25 released. No new text; the producer leaves the first exit open across a start into a lockout alone. Telegram says nothing of the start until the lockout ends; if ML-8 relocks at that release, the open first exit takes the relock as the start, so S16 goes out in place of S25 locked again.
- Ruled, ML-34: "Option (A): a start into a lockout alone sends no start message. The lockout shows in the next periodic status, the command reply, or S25 at its end." Sections 4.8, 8 and 11 follow it as written.

ML-35. An in place stop before such a start, reasons 2, 3, 5, 6 and 7 (`SVC:460-466`). The service holds the stop up to `AG_SVC_HOLD_SECONDS`, 60 s, with every event behind it, for an S1 or S16 to merge with (`SVC:531-555`). None comes, so the stop goes out alone when the hold ends.
- (A) As written: S2 alone after the 60 s hold, its restart reason read as a stop, the events behind it delayed those 60 s. The message says the guardian stopped while it runs and holds the lockout.
- (B) The merge takes the start message ML-34 chooses, as "S2+S1" and "S2+S16" merge today. Open only with ML-34 (B); under ML-34 (C) the start comes after the hold, so the stop still goes alone.
- (C) S2 sent alone after the hold with a lock line from the queue's snapshot, the effective end of B5.9 when the snapshot reads LOCKED. A new line in S2's draft in addendum item 13 and a render change in the service; the line is only as fresh as the snapshot the EA wrote before the hold ended.
- Ruled, ML-35: "(1) A chart timeframe or symbol change, deinit reason 3, sends no Telegram message in any state: no stop, no start, no merged restart message. This supersedes, for reason 3 only, the earlier Telegram ruling that sends the in place restart message. (2) For the other in place reasons during a lockout alone, S2 goes out alone after the hold, option (A)." The earlier ruling is TG-13 (B) (`LEDGER.md:536`), read under TG-1 (B) at `ADD:288` as the in place stop held up to 60 s and merged into one "restarted" message; it stands for every other reason. Part (2) is the code as written. Part (1) is designed in section 4.8 and carried by B1, B5.3, B5.11, B5.17, B7, B9, B11 and B13, with the static row ML-S17 and the live rows ML-L17 to ML-L19. No draft changes: no text is added, and the reason words and drafts left unused stay in place, no check requiring their removal. Its reach over S3 is ruled by ML-37 below.

ML-36, on the reach of ML-29 (point 2), as given: "ML-29 is a narrow exception for the one compile log line. RULE A and its wording stay as they are." Rule 3 of section 11.1 follows it.

ML-37, on the S3 silence the plan had chosen under ML-35 (1), ruled by the owner on 2026-10-22, FINAL at `dd46b03` (`LEDGER.md:645-646` as at that commit), as given: "After a chart timeframe or symbol change, S3 is silenced only when the same SAFE_HALT was already announced before the change. A SAFE_HALT that is new at the init after the change always sends S3." With it, as given: "It replaces the plan's reading that silenced every S3 after reason 3." That reading stood in section 4.8 and in B5.11 (a), which pushed no S3 at the first SAFE_HALT tick after any reason 3 change. Section 4.8 now designs the ruling: a SAFE_HALT is known by its halt time, and it counts as announced once a queue write that carried its S3 has succeeded, recorded in a global the in place re-init keeps. B1, B5.3, B5.9, B5.11, B5.17, B9 and B11 carry it, with the static row ML-S18 and three vectors of B9; a SAFE_HALT new at the init after a reason 3 change is not produced on demand, so no live row is added. No further decision was needed: the EA announces only by writing the queue (TG-1 (B)), and the written queue is delivered across the in place re-init (TG-5 (B)).
