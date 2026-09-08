# Fix plan, defects 2 and 4, the GV lock mirror self erase and the number free LOCKED LIFE line

Dated 2026-09-08. Written on branch `worktree-d2d4-plan-20260908`, cut from main at `bd61a0f3a44e1ff3f80ebb4dafdc7040846d376b`, and every line citation below is against that commit. NO CODE WAS WRITTEN, NO COMPILE WAS RUN, NO VECTOR WAS EDITED, NOTHING WAS DEPLOYED, and nothing under the MetaTrader Terminal data folder was read, written or approached, per RULE A (`LEDGER.md:2006-2008`).

## Scope and what this document is not

Defects 2 and 4 are the second and fourth items of the fix order ruled 2026-08-19 and FINAL in DECISIONS (`LEDGER.md:1898`): "(1) disconnect straddling lock expiry leaves the first post expiry pass ungated, (2) GV lock mirror self erases on cold boot, (3) boot derived lock persists an empty Q6 snapshot and loses the breach timestamp, (4) LOCKED LIFE lines carry no numbers." Defects 1 and 3 are CLOSED on live acceptance, `LEDGER.md:174` "The phase 3 defect fix branch reached main", and their rows P3-1, P49 and P53 closed on the build `1C88C4A1` (`LEDGER.md:180-187`). The same FINAL says of itself "IT IS NOT AN AUTHORIZATION TO WRITE CODE" (`LEDGER.md:1898`), and this document is not one either.

**NO SHAPE IS RECOMMENDED HERE.** Both ISSUES entries reserve the design to the owner: defect 2 "Fix shape named and NOT RULED, since the owner reserves the design" (`LEDGER.md:32`), defect 4 "Naming the obvious scope WITHOUT RULING IT, since the owner reserves the design" (`LEDGER.md:36`). Section 4 is a ruling sheet of closed questions with the consequence of each option, and nothing in it leans.

Notation. `EA:<n>` is `MQL5/Experts/AccountGuardian/AccountGuardian.mq5` line `<n>` at `bd61a0f`; `Persist.mqh:<n>`, `Pnl.mqh:<n>`, `State.mqh:<n>`, `Log.mqh:<n>`, `Clock.mqh:<n>` are the includes under `MQL5/Include/AccountGuardian/` at the same commit. `<...>` marks a field whose value depends on the run. A prediction of ZERO occurrences is a prediction about a whole named window and closes only on a count over it. Predictions continue the numbering of `docs/FIXPLAN_PHASE3_DEFECT3_2026-08-20.md`, which ended at P60 (`docs/FIXPLAN_PHASE3_DEFECT3_2026-08-20.md:348` "**P60.**"), so this document runs from P61.

Source identity at `bd61a0f`, measured this session by `Get-FileHash`, standing rule 7 (`LEDGER.md:1864`): `AccountGuardian.mq5` `4F2939FD092711C9391A5F763F8ACA8A` at 68001 bytes, `Persist.mqh` `0728E30210CAB55C7F83FD46E4F8D0A6`, `Pnl.mqh` `B961E6F70B3EC270FF776E21F307D69F`, `State.mqh` `34792807C6B6B548943215866193EB3F`, `Clock.mqh` `DC5A04004F0CB7BDB9D6C602E944CEC1`, `Log.mqh` `C4E803FB81EBE7F521CC020E8FA1CE82`, `Sweep.mqh` `600B083C69C7D4B121303C2590685414`, `AgPhase2StateVectors.mq5` `16CF643735B9966312860753154BD74E`. The first six equal the R10 build identity banked at `LEDGER.md:121` ("`AccountGuardian.mq5` `4F2939FD092711C9391A5F763F8ACA8A` at 68001 bytes, `Pnl.mqh` `B961E6F70B3EC270FF776E21F307D69F`" and the five includes), so the source this plan cites is the source of the running binary `842C6E52483A9D3469E1AD8A12266ACD` (`LEDGER.md:93`). `Sweep.mqh` differs from the terminal copy by line endings only, as `LEDGER.md:1168` records.

---

## TASK 1, the two defects as recorded

### 1.1 Defect 2, quoted from ISSUES

`LEDGER.md:31`, the Issue line, quoted whole:

> Issue:  DEFECT 2 OF 4 IN THE FIX ORDER RULED 2026-08-19. THE GV LOCK MIRROR ERASES ITSELF ON EVERY COLD BOOT, BEFORE ITS OWN WITNESS CAN READ IT. The mechanism is three lines of source in one callback. `OnTimer` writes the mirror at `AccountGuardian.mq5:881`, `GlobalVariableSet(AgGvLock(), (double)(long)g_ag_locked_until)` followed by `GlobalVariablesFlush()`, guarded only by `if(g_owns_mutex)`, and the boot derivation that READS that mirror runs at `AccountGuardian.mq5:926`, in the SAME `OnTimer`, AFTER the write. On a cold boot `g_ag_locked_until` is 0, because the only thing that sets it is `AgEnterLockFromBoot`, which does not run until the SYNCING exit several ticks later, so the first ticks flush a zero over the persisted mirror and the witness then fails the `(datetime)(long)gv_raw > now` test. LIVE EVIDENCE, `docs/evidence/journal-20260818-stage7-forced-kill.txt`, 2026-08-18, build `74D666E9`, three boots in one file and the split is exact. Cold boot one, `AG|2026.08.18 13:46:41|TRANSITION|BOOT->SYNCING|boot|weekly=on|timer=1s`, fired FILE and DERIVED at 13:46:44 and NO GV line. Cold boot two, `AG|2026.08.18 16:01:24|TRANSITION|BOOT->SYNCING|boot|weekly=on|timer=1s`, fired FILE and DERIVED at 16:01:27 and NO GV line. The ONLY GV firing in the whole day is `AG|2026.08.18 15:36:27|INFO|boot witness GV fired|raw=2026.08.19 01:00:00|bounded=2026.08.19 01:00:00`, on the one boot whose transition reads `LOCKED->SYNCING` and which therefore preserved its memory.

`LEDGER.md:32`, the Action line, quoted whole:

> Action: FIX SECOND, per the ruled order, and the fix itself is not written in this session. Fix shape named and NOT RULED, since the owner reserves the design: the write is unconditional on state and could be gated, or ordered after the dispatch, or the boot read could be taken once in `OnInit` before any timer tick. SEVERITY, stated so the fix is scoped against what is actually lost: the GV witness fires only when the EA RETAINED ITS MEMORY, which is exactly the case where a mirror is redundant, and it is guaranteed zeroed in the case it was built for, a genuine restart. So the independent third recovery path does not exist in practice, and with the state file deleted a restart recovery rests on the derived history witness ALONE, making the strictest wins OR over three witnesses an OR over two. This does NOT weaken any lock the file and derived witnesses carry, and it does weaken the deletion resistance argument that justified building three.

`LEDGER.md:33`: `Status: OPEN`.

The two line numbers inside the Issue line, `:881` and `:926`, are the 2026-08-19 tree. At `bd61a0f` the write is `EA:1083-1087` and the read is `EA:260` inside `AgBootDerivation`, called from `EA:1136-1137`; section 2.1 re-derives both. The evidence line numbers inside the banked file, added here under the 2026-09-02 citation FINAL (`LEDGER.md:1807`): the 13:46:41 cold boot transition is `docs/evidence/journal-20260818-stage7-forced-kill.txt:1359`, its FILE and DERIVED witnesses `:1362-1363` with no GV line between them; the 16:01:24 cold boot transition is `:1653`, witnesses `:1656-1657`; the single GV firing is `:1595`, inside the block `:1594-1596` on the `LOCKED->SYNCING` boot at `:1592`.

### 1.2 Defect 4, quoted from ISSUES

`LEDGER.md:35`, the Issue line, quoted whole:

> Issue:  DEFECT 4 OF 4 IN THE FIX ORDER RULED 2026-08-19. LOCKED LIFE LINES CARRY NO NUMBERS. A LOCKED LIFE line prints state, `seconds_in_state` and `waiting_on` and nothing else, while an ACTIVE LIFE line prints anchor, realized, floating, base, limit and `pnl_vs_limit`. LIVE EVIDENCE, `docs/evidence/journal-20260818-stage7-forced-kill.txt`, 2026-08-18, build `74D666E9`, and the cost was paid the same day rather than being hypothetical: at 13:38:07 the broker force closed thirteen positions on this account, and the line the guardian emitted across that event is `AG|2026.08.18 13:38:02|LIFE|state=LOCKED|seconds_in_state=2121|waiting_on=expiry: TimeCurrent >= locked_until|server=2026.08.18 13:38:02|local=2026.08.18 13:38:03`, carrying not one figure. Seventy six consecutive LOCKED LIFE lines from 13:03:03 to 13:40:33 are identical apart from the counter and the two clocks.

`LEDGER.md:36`, the Action line, quoted whole:

> Action: FIX FOURTH, per the ruled order, and the fix itself is not written in this session. WHAT THIS ACTUALLY COST, recorded so the fix is scoped against evidence rather than against a feeling: when the owner asked for balance and equity at the moment of the liquidation the executor could supply NEITHER from any readable artifact, because no artifact carries them, and the same gap blocked a direct answer three further times in one session, on the input value the EA booted with, on the 2133 deposit landing while locked, and on the account state through the P2-C disconnect. Naming the obvious scope WITHOUT RULING IT, since the owner reserves the design: the numbers block already exists and is already computed for the ACTIVE path, so the question is which fields still mean anything under a lock rather than what to compute.

`LEDGER.md:37`: `Status: OPEN`.

Evidence line numbers for the Issue line's quotes: the liquidation line is `docs/evidence/journal-20260818-stage7-forced-kill.txt:1338`, the first LOCKED LIFE line of that window is `:1268` (13:03:03) and the last `:1343` (13:40:33).

### 1.3 The fix order FINAL, quoted from DECISIONS

`LEDGER.md:1898-1900`, quoted whole:

> Decision: (owner ruling 2026-08-19, Phase 3 opening session) THE DEFECT FIX ORDER FOR THIS BUILD IS RULED AND IS NOT THE EXECUTOR'S TO REORDER. Quoted as given: "Defect fix order for this build: (1) disconnect straddling lock expiry leaves the first post expiry pass ungated, (2) GV lock mirror self erases on cold boot, (3) boot derived lock persists an empty Q6 snapshot and loses the breach timestamp, (4) LOCKED LIFE lines carry no numbers." These are the same four defects the ACTIONS entry of 2026-08-19 recorded as waiting on the next build, and the ruling settles the order they are fixed in and nothing else. IT IS NOT AN AUTHORIZATION TO WRITE CODE and none has been given, so a later session finding this order recorded must still wait for a separate build instruction.
> Reason: Owner's ruling, recorded as given. No rationale was supplied with it and none is invented here. PROVENANCE, recorded in the discipline the provenance correction FINAL of 2026-08-18 requires: the owner marked ruling TWO of this session FINAL in terms and said nothing about a marker for this one. The protocol offers a DECISIONS entry only FINAL or REVISIT, so FINAL is applied here by transcription rather than by explicit owner words, and that distinction is written down rather than left for a later session to assume.
> Status: FINAL

The FINAL of 2026-08-19 was confirmed by the owner's one word ruling "FINAL" on the same date (`LEDGER.md:1024-1025` "IT CONFIRMS THE FINAL MARKER ON RULINGS ONE AND THREE OF 2026-08-19", the sentence wrapping across the two lines).

What the order settles and what it does not: "the ruling settles the order they are fixed in and nothing else" (`LEDGER.md:1898`). It does not settle how many builds carry the four, which the 2026-08-20 coupling ruling settled for defects 1 and 3 only: "NEITHER SHIPS ALONE. The two reach the terminal in ONE BUILD and ONE DEPLOYMENT" (`LEDGER.md:1894`). No ruling couples 2 and 4 to each other or to anything, which is why D2D4-10 in the ruling sheet exists.

### 1.4 Every FINAL either fix touches, tagged INHERITED or MUST BE SUPERSEDED

Method: the DECISIONS section (`LEDGER.md:1802-2314`) was read whole this session and every entry whose clause a fix would read, write, print or bypass is listed. A clause is INHERITED when every option in section 3 satisfies it as written. A clause is MUST BE SUPERSEDED when at least one option cannot ship without the owner reopening it, and that option is named. The result, stated up front so it is not hunted for: ZERO FINAL CLAUSES ARE SUPERSEDED BY ANY OPTION IN THIS PLAN. Every supersession either fix needs is at the SPEC, README or design document level, and those are listed in section 3.9, not here.

| FINAL | Location | Quoted clause | Defect | Tag |
|---|---|---|---|---|
| Fix order | `LEDGER.md:1898` | "(2) GV lock mirror self erases on cold boot ... (4) LOCKED LIFE lines carry no numbers" and "settles the order they are fixed in and nothing else" | both | INHERITED. Every option implements 2 before 4 in commit order; D2D4-10 asks whether one build or two, which the order does not settle. |
| D10a, R10 scope | `LEDGER.md:2288` | "The defect 2 ... and defect 4 ... fixes, per the fix order FINAL of 2026-08-19, are not part of this build." | both | INHERITED. This plan is for the build after R10; R10 is merged (`LEDGER.md:7`). |
| Defect 1 shape A and the 1+3 coupling | `LEDGER.md:1894` | "Fix order unchanged: 1 implemented first, 3 second, one build." | both | INHERITED. Nothing here touches the expiry path `EA:544-583` or the boot snapshot path `EA:462-482`. |
| Lock artifacts never deleted | `LEDGER.md:2077` | "Lock artifacts are never deleted, only quarantined. Standing principle, applies to state files, lock mirrors, and any future artifact carrying lock state" | 2 | INHERITED. The defect is that the guardian itself writes 0 over the mirror before reading it (`EA:1085`); both options stop that. Neither option deletes a GV. |
| Never loaded never written | `LEDGER.md:2114` | "A persistence model that was never loaded is never written." | 2 | INHERITED. The mirror is not a loaded model and has no load gate; no option adds a file write. Option 2a is the same discipline applied to the mirror, a value the image has not yet read is not overwritten. |
| Witness clamp | `LEDGER.md:2142` | "Any witness-supplied locked_until (file or GV) is clamped to AgNextDayAnchor(current TimeCurrent) at evaluation time" | 2 | INHERITED. The GV witness still passes `AgLockedUntilFromWitness` at `EA:262`; `Clock.mqh:174-181` is untouched. |
| Floor wins, question FOUR floor | `LEDGER.md:1926`, `:1934` | "for a witness supplied value the two apply in order, clamp first as the upper bound, floor second as the lower bound" | 2 | INHERITED. `Clock.mqh:180` `return AgApplyLatchFloor(until);` untouched. |
| Q7, TimeCurrent only | `LEDGER.md:2053` | "All expiry and anchor decisions use TimeCurrent exclusively." | both | INHERITED. The witness compares against `now = AgServerNow()` (`EA:239`); the LIFE line already samples both clocks (`Log.mqh:85-86`) and no option adds a clock to a decision. |
| Question SIX, observability ships inside Phase 2, logging never gates | `LEDGER.md:1942` | "it may log, and it may never suppress, delay or gate a decision" | both | INHERITED. Defect 4 is logging only. Option 2a gates a WRITE on state, not a decision. |
| Stage 6 static row (acceptance row, not a DECISIONS entry, listed because the build reruns it) | `LEDGER.md:1320` | "ZERO references inside `AgEvaluateActive`, `AgEvaluateLocked`, `AgBootDerivation`, `AgDeclareLock`, `AgEnterLockFromBoot` or `AgRatchetUpdate`" to the two observability globals | 4 | INHERITED under every option provided the LOCKED numbers builder, which is a logger, is where `g_ag_obs_connected` is read if D2D4-6(a) is taken, and not `AgEvaluateLocked`. |
| Standing observation rules 1 and 2 | `LEDGER.md:1864` | "(1) External reads of bases\gvariables.dat are never evidence while the terminal runs. (2) The F3 dialog is a snapshot; a GV reading is admissible only as open, read, fully close, wait, reopen, read." | 2 | INHERITED. Every GV prediction below closes on journal lines; F3 readings are corroboration only, per P14 (`docs/PREDICTIONS_PHASE3_DEFECTS_2026-08-19.md:108-112`). |
| Standing rules 6 and 7 | `LEDGER.md:1864` | exit code "inverted in practice"; "the ex5 SIZE AND HASH ARE NOT BUILD IDENTITY" | both | INHERITED. Acceptance rows quote the Result line and the source md5s. |
| Proof of life A3 | `LEDGER.md:2138` | "Every state, SYNCING and LOCKED included, emits a periodic proof-of-life journal line at a fixed interval carrying current state, seconds in state, and the specific condition being waited on" | 4 | INHERITED and extended. The three named fields stay; a numbers group is appended, exactly as A6 appended one to ACTIVE (`Log.mqh:78-80` "numbers (A6, 4.5) ... appended when non-empty"). |
| AG_LIFE_INTERVAL_SECONDS constant | `LEDGER.md:2106` | "stays a compile-time constant at 30 s and does not become an input" | 4 | INHERITED. Option 4b's recompute cadence reuses the constant (`EA:35`). |
| Q6/F7 snapshot governs the locked window | `LEDGER.md:2049` | "the locked window is judged by the snapshot, never by live inputs. An input change while locked is logged loudly." | 4 | INHERITED. Every option prints the snapshot limit as the governing figure and never the live limit; the Q6 WARN at `EA:533-539` is untouched. |
| D4a, within the ceiling while LOCKED | `LEDGER.md:2261` | "an input change is rejected and journaled, current Q6 behaviour ... unchanged" | 4 | INHERITED. |
| Reseed on reload | `LEDGER.md:1902` | "On reload the state takes the current input values. A record of an input change made while locked is not required." | 4 | INHERITED. `EA:458-460` untouched. |
| P2-H not closable by code | `LEDGER.md:1906` | "NO FIX IN THIS BUILD MAY BE REPORTED AS CLOSING IT" | 4 | INHERITED. A LOCKED line carrying numbers is not a Q6 WARN and this plan does not report it as one. |
| Day anchor base is Balance, never Equity | `LEDGER.md:2200` | "the base is the anchor-moment balance, reconstructed live as current Balance minus the sum of all deals since the day anchor, all deal types alike, never Equity and never cached" | 4 | INHERITED. No option changes the base or reads Equity INTO a base. D2D4-4 asks whether a LOGGED equity figure is a platform read or a derivation; the FINAL governs the base and is silent on logging. The descriptive clause of the V1 Reason at `LEDGER.md:1883`, "NO Equity read is introduced anywhere", would stop describing the tree under D2D4-4(b) and is named in that question. |
| V1 ruling set D1 to D8 | `LEDGER.md:1880` | "NINE, THE PEAK DOES NOT ENTER THE LOCK SNAPSHOT (D8). The peak is PRE BREACH ONLY, EXACTLY AS THE RATCHET IS. The locked window is judged by the snapshot alone" | 4 | INHERITED. No option prints `peak`, `peak_level` or `ratchet_level` on a LOCKED line; the `lock level` line (`EA:799-806`) stays ACTIVE only. |
| Ratchet, question SEVEN | `LEDGER.md:1946` | "`min(limit, floor)` applying PRE BREACH ONLY" | 4 | INHERITED. `Persist.mqh:710-711` "Nothing in LOCKED calls this." stays true; no option calls `AgFloorEffectiveLimit` or `AgRatchetUpdate` from LOCKED. |
| Third ruling 2026-08-20, no state file format change | `LEDGER.md:1886` | "The state file record layout at `Persist.mqh:352-359` is UNCHANGED, `AG_STATE_FORMAT_VERSION` stays 1, and no field is added" | 4 | INHERITED. Every option READS the model at `Persist.mqh:69-73` and writes nothing; the layout at `Persist.mqh:352-362` is untouched. |
| Shape 1, "recorded as such" | `LEDGER.md:1890` | "the field carries a derivation instant on this path and a true breach instant on the `AgDeclareLock` path, and any artifact, document or later entry that reports it must say which of the two it is rather than letting the field's name imply the stronger meaning" | 4 | INHERITED, and it is the reason D2D4-5 exists: a LOCKED line that prints `breach_time` REPORTS it and must say which instant it is, or must not print it. |
| Amendment 2a, state file lock state only | `LEDGER.md:2089` | "The state file is charter-constrained to lock state only" | 4 | INHERITED. No field is added to any file. |
| A5, from state of a transition | `LEDGER.md:2014` | "the from-state of a transition line is the state the program image was actually in, BOOT in a fresh image and the surviving prior state in an in-place re-init" | 2 | INHERITED. P3-2 discriminates a cold boot from a reload on exactly this, `BOOT->SYNCING` against `LOCKED->SYNCING`. |
| Stale quote ruling | `LEDGER.md:1970` | "it must never suppress, delay, or gate a breach decision" | both | INHERITED. |
| Q10 DEGRADED and the 2026-08-09 amendment | `LEDGER.md:2249`, `:2245` | "the LIFE line and banner show a DEGRADED marker alongside the last-known figures" | 4 | INHERITED. The ruling is about ACTIVE; D2D4-6 asks whether the LOCKED group carries a prefix keyed on the Stage 6 connection sample, which the ruling neither requires nor forbids. |
| Naming discipline | `LEDGER.md:2073` | "The once-per-minute journal line, which is neither, is the 'liveness journal line'." | 4 | INHERITED. |
| F13 timer architecture | `LEDGER.md:2069` | "Timer-driven architecture, EventSetTimer(1). ... OnTick unused." | both | INHERITED. Both fixes live in `OnInit`, `OnTimer` and functions they call. |
| RULE A and RULE B | `LEDGER.md:2006` | "the MetaTrader Terminal data folder is READ ONLY territory for every executor session, without exception" | both | INHERITED. The build session compiles inside the worktree with `/include` rooted there, as `LEDGER.md:121` records for R10. |
| Deploy hand, `scripts/deploy-r10.ps1` | `LEDGER.md:2308` | "The executor may write ONE PowerShell script inside the repository, `scripts/deploy-r10.ps1`, containing only `Copy-Item` lines ... THE OWNER RUNS THE SCRIPT" | both | INHERITED as to the hand. The ruling names one file for one build; D2D4-11 asks whether a second script under the same shape is covered or whether this build deploys by dictation (`LEDGER.md:1950`). |
| Deploy procedure amended 2026-09-07 | `LEDGER.md:2312` | "after any build upgrade, the EA is attached and a healthy init is confirmed on the chart, its `limits accepted` line read, BEFORE any terminal restart. A refused init is corrected while the EA is still attached." | both | INHERITED and EXERCISED. This build is a build upgrade, so the step is mandatory; D2D4-12 asks only what the deploy row records. |
| Ruling ONE 2026-08-18, owner performs every copy | `LEDGER.md:1950` | "for each file the executor names the SOURCE FILE, its DESTINATION PATH and its MD5, and the owner performs the copy and confirms" | both | INHERITED. |
| Evidence citation rule | `LEDGER.md:1807` | "no LEDGER entry may cite an observation of live behaviour without the artifact file name and the line number it was read from" | both | INHERITED. Every acceptance row below closes on `<file>:<line>`. |
| Session report is not evidence | `LEDGER.md:2010` | "No LEDGER entry may assert a commit, a merge, a deploy, a compile ... without the writing session re-deriving it" | both | INHERITED. |
| Merge gate | `LEDGER.md:2170` | "A branch merges to main when the work in that branch is complete and proven" | both | INHERITED. The build branch merges only after its rows close. |
| Remote state owner managed | `LEDGER.md:2196` | "the executor never pushes" | both | INHERITED. |
| SPEC series closed at A6 | `LEDGER.md:2304` | "Future SPEC changes are recorded by the ruling that causes them, not by the series." | both | INHERITED. The SPEC edits in 3.9 are in place edits with no A7. |
| Vectors committed, sync direction | `LEDGER.md:2183` | "Sync direction is repository to terminal, never back" | both | INHERITED. Applies if D2D4-9(a) adds checks to `AgPhase2StateVectors.mq5`. |
| Weekend is a trading day | `LEDGER.md:1872` | "The weekend is a trading day: day anchors roll at 01:00 every day including Saturday and Sunday." | both | INHERITED. Bears on when a locked window can be produced for acceptance. |
| Interim posture, no order sent | `LEDGER.md:1954` | "A Phase 2 build LOCKS THE STATE MACHINE BUT SENDS NO ORDER." | both | INHERITED. S1 and S2 rerun in the build. |

---

## TASK 2, source map per defect at `bd61a0f`

### 2.1 Defect 2, every read, write and journal site

The mirror's name: `Persist.mqh:89` `string AgGvLock()      { return "AG_LOCK_" + (string)g_ag_login; }`, with the comment above it at `:86-88` "Lock mirror (design doc item 4). Carries a bare locked_until and no reason, which is why the GV witness defaults to DAILY_BREACH". The in memory value it mirrors: `State.mqh:29` `datetime            g_ag_locked_until = 0;`.

THE WRITE, one site in the tree. `EA:1083-1087`:

```
   if(g_owns_mutex)
     {
      GlobalVariableSet(AgGvLock(), (double)(long)g_ag_locked_until);
      GlobalVariablesFlush();
     }
```

Its comment at `EA:1072-1082` states the design intent verbatim: "Rewritten from the authoritative in-memory lock state every tick, unconditionally, mirroring the mutex-heartbeat pattern directly above. That is what makes it SELF-HEALING against live tampering". `g_owns_mutex` is `EA:29` `bool g_owns_mutex          = false;`, set true at `EA:932` after `AgMutexAcquire()` at `EA:926`. The write is the third block of `OnTimer` (`EA:1046`), after the tick counter `EA:1048` and the mutex refresh `EA:1053-1054`, and BEFORE the proof of life at `EA:1109-1110` and the per state dispatch at `EA:1118-1160`.

THE READ, one site in the tree. `EA:259-271`, inside `AgBootDerivation` (`EA:226-368`):

```
   //--- WITNESS 2, the GV mirror. Bare timestamp, no reason, so DAILY_BREACH.
   double gv_raw = 0.0;
   if(GlobalVariableGet(AgGvLock(), gv_raw) && (datetime)(long)gv_raw > now)
     {
      datetime u = AgLockedUntilFromWitness((datetime)(long)gv_raw);
      AgInfo("boot witness GV fired|raw=" + TimeToString((datetime)(long)gv_raw, TIME_DATE | TIME_SECONDS)
             + "|bounded=" + TimeToString(u, TIME_DATE | TIME_SECONDS));
      if(!fired || u > until_out)   // strictest wins
        {
         until_out  = u;
         reason_out = AG_LOCK_DAILY_BREACH;
        }
      fired = true;
     }
```

`now` is `EA:239` `datetime now = AgServerNow();`. The witness bounds through `Clock.mqh:174-181`, clamp then floor. `AgBootDerivation` has exactly one call site, `EA:1136-1137` `int derived = AgBootDerivation(boot_reason, boot_until, boot_have_snapshot, boot_breach_time, boot_limit, boot_base);`, inside the SYNCING branch, reached only when `EA:1120` `if(AgHistoryStable(AG_HISTORY_STABLE_POLLS))` is true.

THE JOURNAL SITE for the witness is the `AgInfo` at `EA:263-264`. No other line names the mirror. `OnInit` (`EA:899-1041`) contains no read of `AgGvLock()`; its only GV read is the halt flag at `EA:999` `bool   was_halted_before = (GlobalVariableGet(AgGvHaltFlag(), gv_halt) && gv_halt > 0.5);`. Every `GlobalVariable` call in the tree outside the two sites above belongs to the mutex family (`Persist.mqh:1227`, `:1240-1242`, `:1265`, `:1271`, `:1274`, `:1280-1283`) or the halt flag (`EA:890-891`, `EA:1003-1004`), measured by grep over `MQL5/` this session. The vectors script contains no `GlobalVariable` call at all (grep over `MQL5/Scripts/AccountGuardian/` returned no match).

THE SETTERS of `g_ag_locked_until`, three in the tree, confirmed by grep this session: `EA:386` `g_ag_locked_until     = until;` in `AgDeclareLock`; `EA:452` `g_ag_locked_until = until;` in `AgEnterLockFromBoot`; `EA:550` `g_ag_locked_until = 0;` at expiry in `AgEvaluateLocked`. NOTHING IN `OnInit` WRITES IT, which is the fact the chart re init path below turns on.

THE STABILITY GATE that decides which tick the read happens on. `Pnl.mqh:426-449` `AgHistoryStable`: on the first connected poll `total != g_ag_last_history_total` (`:441`) sets `g_ag_stable_polls = 1` (`:444`); each later unchanged poll increments (`:447`); `:448` `return g_ag_stable_polls >= required_polls;` with `required_polls` = `AG_HISTORY_STABLE_POLLS` = 3 (`EA:46`). The earliest SYNCING exit is therefore the THIRD timer tick, and the `EA:1085` write has run on ticks one and two before it. Live figure: `TRANSITION|SYNCING->ACTIVE|history stable|polls=3/3` three seconds after `BOOT->SYNCING` on every banked cold boot, for example `docs/evidence/journal-20260830-rollover-and-boot-breach.txt:3663` at 15:45:56 to `:3667` at 15:45:59.

#### 2.1.1 The cold boot path

1. Fresh image: `g_ag_locked_until` initialises to 0 (`State.mqh:29`), `g_owns_mutex` to false (`EA:29`).
2. `OnInit`: `EA:903` init line; `EA:926-932` mutex acquired, `g_owns_mutex = true`; `EA:946` `AgStateLoad()` populates the state file MODEL (`Persist.mqh:69-73`), which is a separate model from `g_ag_locked_until` by design (`Persist.mqh:63-68` "Its own model ... rather than writing State.mqh's live globals straight to disk"); `EA:1036-1037` `AgTransition(AG_STATE_SYNCING, "boot", ...)`, journal `TRANSITION|BOOT->SYNCING|boot|weekly=on|timer=1s`; `EA:1039` `AgArmTimer()`.
3. Tick 1, `OnTimer`: `EA:1085` writes `(double)(long)0` over `AG_LOCK_<login>`, `EA:1086` flushes. `EA:1120` first poll, `g_ag_stable_polls = 1`, no exit.
4. Tick 2: `EA:1085` writes 0 again. Second poll, 2, no exit.
5. Tick 3: `EA:1085` writes 0 again. Third poll, 3, exit reached, `EA:1136` runs `AgBootDerivation`. `EA:260` reads `gv_raw = 0.0`; `(datetime)0 > now` is false; the GV witness abstains. FILE (`EA:247`) and DERIVED (`EA:337`) decide alone.

That is P11 of the predictions document, "ZERO `boot witness GV fired` lines on that cold boot ... because `OnTimer` has already flushed a zero over the mirror before the read" (`docs/PREDICTIONS_PHASE3_DEFECTS_2026-08-19.md:95-97`), and it is what the banked file shows on both cold boots, `journal-20260818-stage7-forced-kill.txt:1359-1364` and `:1653-1658`.

#### 2.1.2 The chart re init path (reason 3 chart change, reason 5 input change)

1. `OnDeinit` (`EA:1204-1234`) runs in the SAME image: `EA:1221-1222` releases the mutex (`Persist.mqh:1282` writes heartbeat 0). Globals survive, per A5 (`LEDGER.md:2015` "in-place re-inits, each preceded within 13 milliseconds by a deinit reason=5 carrying timer_armed=1"). `g_ag_locked_until` keeps its value because nothing in `OnDeinit` or `OnInit` writes it.
2. `OnInit`: mutex re acquired (`EA:926`); `AgStateLoad()` (`EA:946`) reloads the file model; `EA:1036` transitions from the surviving state, journal `TRANSITION|LOCKED->SYNCING|boot|weekly=on|timer=1s` (`journal-20260818-stage7-forced-kill.txt:1592`).
3. Tick 1: `EA:1085` writes the RETAINED `g_ag_locked_until` over the mirror. Ticks 2 and 3 likewise.
4. Tick 3: `EA:260` reads the retained value, `> now` holds, the witness fires: `journal-20260818-stage7-forced-kill.txt:1595` `boot witness GV fired|raw=2026.08.19 01:00:00|bounded=2026.08.19 01:00:00`.

This is the only route on which the witness has ever fired (`LEDGER.md:1266` "GV fired ONCE, at 15:36:27 only"), and it is the route where the mirror is redundant, since memory already holds the lock (`LEDGER.md:32`).

#### 2.1.3 The 01:00 rollover path while LOCKED (expiry)

1. `AgEvaluateLocked` (`EA:521-584`), dispatched from `EA:1159-1160` on every LOCKED tick. `EA:544-545` `datetime now_server = AgServerNow(); if(now_server >= g_ag_locked_until)`.
2. On expiry: `EA:547-548` journal `lock expired|locked_until=<t>|server=<t>`; `EA:549-550` `g_ag_lock_reason  = AG_LOCK_NONE; g_ag_locked_until = 0;`; `EA:551` `AgStateResetModel();`; `EA:552` `AgStateSave()`; `EA:574-575` stability reset; `EA:576-578` `AgTransition(AG_STATE_SYNCING, "lock expired", ...)`.
3. Next tick: `EA:1085` writes 0 over the mirror. This zero is CORRECT: the lock is over. Ticks 1 to 3 of the post expiry SYNCING occupancy write 0; at the exit `EA:260` reads 0, abstains; FILE reads the reset model (`L|0|0|0`, `LEDGER.md:1147`), abstains; DERIVED replays the new day and either re locks (`README.md:65` "the boot-derived re-lock: `LOCKED -> SYNCING -> LOCKED`") or `SYNCING->ACTIVE`.

Live instance: `docs/evidence/journal-20260901-v1a-lock-expiry.txt:121` `lock expired|locked_until=2026.09.01 01:00:00|server=2026.09.01 01:00:00`, `:122` `TRANSITION|LOCKED->SYNCING|lock expired|...|polls=0/3`, `:123` `TRANSITION|SYNCING->ACTIVE|history stable|polls=3/3` two seconds later, with no `boot witness` line between them.

A day rollover that happens while LOCKED WITHOUT expiry, the ruling THREE extra day case (`LEDGER.md:1930`), touches none of the sites above: `AgEvaluateLocked` takes no rollover action and the mirror keeps carrying the unexpired `locked_until`.

#### 2.1.4 The cases the current write erases, enumerated

Under `bd61a0f` the mirror is zeroed before it is read on every FRESH image that reaches SYNCING with `g_ag_locked_until` at its initialiser: a terminal restart, a hard kill and relaunch, a fresh attach from the Navigator, and a recompile (the fresh image routes listed at `docs/SPEC_v0.1.md:265`). It is ALSO zeroed under SAFE_HALT in a fresh image, because `EA:1083` gates on `g_owns_mutex` alone and the SAFE_HALT return at `EA:1113-1114` sits AFTER the write. The mirror is preserved only across an in place re init.

### 2.2 Defect 4, every LIFE line emitter and what each carries in LOCKED

THE EMITTER, one in the tree. `Log.mqh:66-87` `AgProofOfLife(const string state_name, const int seconds_in_state, const string waiting_on, const int interval_seconds, const string numbers = "")`. Line assembly at `Log.mqh:81-86`:

```
   AgLog("LIFE", "state=" + state_name
         + "|seconds_in_state=" + (string)seconds_in_state
         + "|waiting_on=" + (waiting_on == "" ? "-" : waiting_on)
         + (numbers == "" ? "" : "|" + numbers)
         + "|server=" + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS)
         + "|local=" + TimeToString(now, TIME_DATE | TIME_SECONDS));
```

The comment at `Log.mqh:78-80`: "numbers (A6, 4.5): the ACTIVE governing figures, anchor/realized/floating/base/limit/pnl_vs_limit, appended when non-empty. Every other state passes "" and the field is simply absent." Cadence gate at `Log.mqh:70-73` on `TimeLocal()`.

THE CALL, one in the tree. `EA:1109-1110` `AgProofOfLife(AgStateName(g_ag_state), AgSecondsInState(), waiting_on, AG_LIFE_INTERVAL_SECONDS, AgPnlNumbersString());`, in every state, before the dispatch.

WHAT EACH ARGUMENT CARRIES IN LOCKED:

| Argument | Source | Value in LOCKED |
|---|---|---|
| `state_name` | `State.mqh:32-43` `AgStateName` | `LOCKED` (`State.mqh:39`) |
| `seconds_in_state` | `State.mqh:60-65` `AgSecondsInState`, `TimeLocal() - g_ag_state_since` | wall clock since the `AgTransition` that entered LOCKED (`State.mqh:74`) |
| `waiting_on` | `State.mqh:91-107` `AgWaitingOn`; LOCKED case `State.mqh:101-102` `case AG_STATE_LOCKED: return "expiry: TimeCurrent >= locked_until";` | the fixed string, plus the Stage 6 note appended at `EA:1101-1108` when non empty: `EA:1106-1107` `if(!is_degraded_note \|\| g_ag_state == AG_STATE_SYNCING \|\| g_ag_state == AG_STATE_LOCKED) waiting_on = (waiting_on == "") ? obs_note : (waiting_on + "\|" + obs_note);`, so LOCKED lines can read `...locked_until\|DEGRADED: disconnected` (`journal-20260818-stage7-p2c-locked-disconnect.txt:1512`) or `...locked_until\|quote_age=149s` (`journal-20260831-flat-expiry-and-v1a-lock.txt:5`) or `market closed` (never observed, `LEDGER.md:48-51`) |
| `numbers` | `EA:156-167` `AgPnlNumbersString` | EMPTY. `EA:158-159` `if(g_ag_state != AG_STATE_ACTIVE \|\| !g_ag_have_pnl_numbers) return "";` |

`AgPnlNumbersString` in full, `EA:156-167`:

```
string AgPnlNumbersString()
  {
   if(g_ag_state != AG_STATE_ACTIVE || !g_ag_have_pnl_numbers)
      return "";
   string prefix = g_ag_degraded ? "DEGRADED|" : "";
   return prefix + "anchor=" + TimeToString(g_ag_last_anchor, TIME_DATE | TIME_SECONDS)
        + "|realized=" + DoubleToString(g_ag_last_realized, 2)
        + "|floating=" + DoubleToString(g_ag_last_floating, 2)
        + "|base=" + DoubleToString(g_ag_last_base, 2)
        + "|limit=" + DoubleToString(g_ag_last_limit, 2)
        + "|pnl_vs_limit=" + DoubleToString(g_ag_last_pnl, 2) + " vs -" + DoubleToString(g_ag_last_limit, 2);
  }
```

It reads the six `g_ag_last_*` globals at `EA:63-68` and `g_ag_have_pnl_numbers` at `EA:61`, all written at `EA:736-742` inside `AgEvaluateActive` and nowhere else (grep this session). NOTHING RESETS THEM AT A LOCK: `AgDeclareLock` (`EA:379-413`) and `AgEnterLockFromBoot` (`EA:447-491`) do not touch them. So under a lock declared from ACTIVE they hold the declaring pass's figures, stale from that instant on; under a boot derived lock they are at their initialisers and `g_ag_have_pnl_numbers` is false.

THE SECOND CONSUMER OF THE SAME NUMBERS, the banner. `EA:170-179` `AgRefreshBanner`: `EA:172` `string pnl = "n/a (Phase 1, no ACTIVE pass has completed yet)";`, overridden at `EA:173-174` for SAFE_HALT and at `EA:175-177` for `g_ag_state == AG_STATE_ACTIVE && g_ag_have_pnl_numbers` only, so under LOCKED the banner's last line reads the Phase 1 placeholder. `AgBanner` at `Log.mqh:92-101` does print `locked_until` (`Log.mqh:95`) and the lock reason. Called at `EA:1111` every tick.

WHAT THE GUARDIAN HOLDS IN MEMORY UNDER LOCKED AND DOES NOT PRINT, the candidate field set for section 3:

| Quantity | Where it lives | How it got there under LOCKED | Cost to print |
|---|---|---|---|
| `g_ag_locked_until` | `State.mqh:29` | `EA:386` or `EA:452` | none, already on the banner (`Log.mqh:95`) and on the transition line (`EA:406`, `EA:485`) |
| `g_ag_lock_reason` | `State.mqh:28` | `EA:385` or `EA:451` | none |
| `g_ag_state_limit_snap`, `g_ag_state_base_snap`, `g_ag_state_breach_time` | `Persist.mqh:72-73`, `:71` | `AgStateSetBreach` `Persist.mqh:397-405` from `EA:391` (declared), `EA:473` (file preserved) or `EA:480` (derived, shape 1); zeroed by `AgStateSetCorrupt` `Persist.mqh:412-419` from `EA:466` or the quarantine at `Persist.mqh:445` | none, model reads. These are the Q6 snapshot the window is judged by (`EA:537-539` already prints two of them inside the Q6 WARN) |
| `AccountInfoDouble(ACCOUNT_BALANCE)` | platform | the only balance read in the tree is `Pnl.mqh:254` inside `AgDayBase` | one platform read per call; not currently taken under LOCKED |
| `AgFloating()` | `Pnl.mqh:262-281`, `PositionsTotal()` loop summing `POSITION_PROFIT + POSITION_SWAP` | not called under LOCKED today; called at `EA:334` (derivation) and `EA:732` (ACTIVE) | one loop over open positions per call |
| `ACCOUNT_EQUITY` | platform | ZERO occurrences in the tree (grep over `MQL5/` this session) | a new read class if taken directly; otherwise `balance + floating` |
| `AgRealized(anchor)` | `Pnl.mqh:205-209` | not called under LOCKED | one `HistorySelect` walk over the day (`Pnl.mqh:113` `AgRealizedRunFold`) per call |
| `AgDayBase(anchor)` | `Pnl.mqh:249-255` | not called under LOCKED | one `HistorySelect` walk (`Pnl.mqh:218-239`) per call |
| `g_ag_last_*` | `EA:63-68` | stale at the declaring pass, absent on a boot derived lock | none, but stale and sometimes absent |
| `g_ag_obs_connected` | `EA:122` | sampled every tick at `EA:1099` | none, already read by the note at `EA:625` |

LIVE LINES THE FIX IS SCOPED AGAINST, quoted with line numbers:

- The V1-A lock, `docs/evidence/journal-20260831-flat-expiry-and-v1a-lock.txt:3939` `AG|2026.08.31 16:52:46|INFO|breach arithmetic|realized=75.90|floating=-115.50|base=2350.86|limit=117.54|pnl=-39.60`, `:3941` `TRANSITION|ACTIVE->LOCKED|DAILY_BREACH|pnl=-39.60|limit=117.54|locked_until=2026.09.01 01:00:00`, then the first LOCKED LIFE line `:3944` `AG|2026.08.31 16:52:59|LIFE|state=LOCKED|seconds_in_state=13|waiting_on=expiry: TimeCurrent >= locked_until|server=2026.08.31 16:52:59|local=2026.08.31 16:52:57`. The 0.3 lot position the breach was judged against was closed at `docs/evidence/terminal-20260831-v1a-lock.txt:43` `16:52:53.012 ... deal #348784021 sell 0.3 XAUUSD.ecn at 4420.11 done`, six seconds before `:3944`, and no line in either file carries the balance after that close.
- The battery outage boot lock, `docs/evidence/journal-20260830-rollover-and-boot-breach.txt:3666` `boot witness DERIVED fired|live=1|replay=1|realized=-192.00|floating=0.00|running_min=-192.00|limit_cmp=127.14|tier=floor|bounded=2026.08.31 01:00:00`, `:3667` `TRANSITION|SYNCING->LOCKED|boot derivation: DAILY_BREACH|locked_until=2026.08.31 01:00:00`, first LOCKED LIFE `:3670` `AG|2026.08.30 15:46:25|LIFE|state=LOCKED|seconds_in_state=28|waiting_on=expiry: TimeCurrent >= locked_until|server=2026.08.30 15:46:25|local=2026.08.30 15:46:27`. The 192.00 the owner lost from the mobile app (`LEDGER.md:1876` ruling FOUR) appears on the DERIVED line once and on no LIFE line for the next 9 hours 14 minutes of the lock.

---

## TASK 3, design space per defect

### 3.1 Defect 2, option 2a, THE STATE GATE

MECHANISM. `EA:1083` `if(g_owns_mutex)` becomes `if(g_owns_mutex && (g_ag_state == AG_STATE_ACTIVE || g_ag_state == AG_STATE_LOCKED))`. One condition, one site. The mirror is written from memory only in the two states whose memory is authoritative for it. In SYNCING nothing is written, so the value the previous image left is still there when `EA:260` reads it. In SAFE_HALT nothing is written, so a persisted lock's mirror outlives a halt. `g_ag_state` is `State.mqh:27`, not a Stage 6 global.

WHAT IT CHANGES ON THE RUNNING PATH. Cold boot: ticks 1 to 3 skip the write; tick 3's `EA:260` reads the pre kill value; if `> now`, the witness fires and joins the strictest wins OR at `EA:265-269`; on entering LOCKED (`EA:484`) the next tick writes the BOUNDED `locked_until` over the raw one. Cold boot with no lock: the mirror already held 0 from the previous ACTIVE image's ticks, the witness abstains as today, ACTIVE writes 0. Chart re init: unchanged, memory carries the value and SYNCING leaves the mirror alone for three seconds. Expiry: `EA:550` zeroes memory, the post expiry SYNCING occupancy writes nothing, the mirror holds the now expired `until`, `EA:260` reads it, `> now` is false, abstains; ACTIVE then writes 0. A boot derived re lock at the SYNCING exit writes the new `until` from LOCKED.

WHAT IT DOES NOT CHANGE. The witness code `EA:259-271`, the clamp and floor `Clock.mqh:174-181`, the file witness, the derived witness, `AgEnterLockFromBoot`, `AgDeclareLock`, `AgEvaluateLocked`, `AgEvaluateActive`, every include. Self healing against live tampering stays in force in ACTIVE and LOCKED, the two states in which a human could be tampering during a lock.

PERSISTED STATE TOUCHED. `AG_LOCK_<login>` semantics only: it now survives a fresh image until the SYNCING exit. No file, no format version, no new artifact.

JOURNAL LINES EMITTED. None new by the mechanism itself. D2D4-2 asks whether one INFO line is added at boot naming the value read; without it, P3-2 closes on the PRESENCE of `boot witness GV fired` on a cold boot and on nothing else, which is a positive artifact only when a lock exists.

FINALS SUPERSEDED. None (section 1.4). Text to amend: `docs/SPEC_v0.1.md:71` "both written each timer tick" becomes "written each timer tick in ACTIVE and LOCKED"; `README.md:70` and its Hebrew mirror `README.md:320` "rewritten from memory every tick"; `docs/DESIGN_PHASE1_2.md:104` is a design record and is left as written with the ledger recording the change.

SYNTHETIC VECTORS ADDED. NONE CAN REACH IT. The gate is inside `OnTimer` and `AgBootDerivation` is an EA function; the vectors script has one direct include, `Persist.mqh` (`AgPhase2StateVectors.mq5:34`), which pulls `Log.mqh`, `Clock.mqh`, `State.mqh` and `Pnl.mqh` transitively (`Persist.mqh:19-25`) and nothing from the EA, and "a script cannot include an EA" (`LEDGER.md:996`). The same constraint defect 3 recorded at `LEDGER.md:991-999` applies unchanged, and a GV round trip vector on a synthetic login would test `GlobalVariableSet` and `GlobalVariableGet`, not the defect.

ACCEPTANCE ROWS NEEDED. P3-2 as written (`docs/PREDICTIONS_PHASE3_DEFECTS_2026-08-19.md:116-120`), quoted in section 3.7, plus the static rows of section 3.7.

WORKED AGAINST THE 2026-08-31 LOCK. Hypothetical hard kill at 17:00 local inside the window opened at `journal-20260831-flat-expiry-and-v1a-lock.txt:3941`. At the kill the mirror holds `1788224400`, which is `2026.09.01 01:00:00` (arithmetic from the decoded `L|1|1787792400|1787706010` at `LEDGER.md:182`, where `1787792400` is `2026.08.27 01:00:00`, plus five days of 86400 s). Under `bd61a0f` the relaunch would emit `BOOT->SYNCING`, then FILE and DERIVED only, P11. Under 2a the relaunch emits `BOOT->SYNCING`, three ticks with no mirror write, then `boot witness FILE fired|reason=DAILY_BREACH|raw=2026.09.01 01:00:00|bounded=2026.09.01 01:00:00`, `boot witness GV fired|raw=2026.09.01 01:00:00|bounded=2026.09.01 01:00:00`, `boot witness DERIVED fired|live=<0|1>|replay=1|...`, `SYNCING->LOCKED`. The DERIVED `replay=1` holds because the 0.3 lot close at `terminal-20260831-v1a-lock.txt:43` burned the loss into history (`LEDGER.md:1242` "with `replay=1` the lock is now derivable from broker deal history ALONE").

WORKED AGAINST THE 2026-08-30 BATTERY OUTAGE BOOT. `journal-20260830-rollover-and-boot-breach.txt:3659` `lock state file loaded|reason=-|locked_until=1970.01.01 00:00:00`: the account was ACTIVE and unlocked when power failed, so the last ACTIVE tick before 15:14:10 had written 0 to the mirror at `EA:1085`. Under 2a the relaunch at `:3663` reads 0 at tick 3, the GV witness abstains exactly as it did at `:3666-3667`, and the boot block is BYTE IDENTICAL to the banked one. THE OPTION CHANGES NOTHING ON THAT BOOT, and that is the correct result: there was no lock to mirror. What it would change is the boot AFTER it: had a second outage struck between `:3667` (15:45:59) and 01:00 the next day, `bd61a0f` would relaunch on FILE and DERIVED alone; 2a would relaunch on all three, the GV carrying `raw=2026.08.31 01:00:00`.

COST, stated. For the three seconds of every SYNCING occupancy a GV cleared by hand is not restored. The derivation reads it once inside that window, so the exposure is one read of a value a tamperer had three seconds to clear, against a witness the same tamperer can already clear at any time in ACTIVE by holding the F3 dialog open longer than a tick, which the OR over three witnesses was built to absorb (`docs/DESIGN_PHASE1_2.md:95` "witnesses (accelerators), not authority").

### 3.2 Defect 2, option 2b, THE BOOT CAPTURE

MECHANISM. A new EA global `datetime g_ag_gv_lock_at_init = 0;`, written ONCE in `OnInit` after `g_ag_login` is set (`EA:902`) and after the mutex is acquired (`EA:932`), before the timer is armed (`EA:1039`): `double gv_boot = 0.0; if(GlobalVariableGet(AgGvLock(), gv_boot)) g_ag_gv_lock_at_init = (datetime)(long)gv_boot;`. The witness at `EA:260` reads `g_ag_gv_lock_at_init` instead of the live GV: `if(g_ag_gv_lock_at_init > now)`. The write at `EA:1083-1087` stays unconditional.

WHAT IT CHANGES ON THE RUNNING PATH. Cold boot: `OnInit` captures the pre kill value; ticks 1 to 3 still write 0 over the live mirror; tick 3's witness reads the capture and fires if `> now`. Chart re init: `OnInit` captures the value the previous image's last tick wrote, which equals `g_ag_locked_until` in memory, same result as today. Expiry: unchanged from `bd61a0f`, the capture is not consulted after the boot occupancy and the live mirror is zeroed after `EA:550` as today. A NOT EVALUABLE retry loop (`EA:282-294` return 2) keeps re reading the capture, which does not decay.

WHAT IT DOES NOT CHANGE. `EA:1083-1087`, so `docs/SPEC_v0.1.md:71` stays literally true; the clamp and floor; every include.

PERSISTED STATE TOUCHED. None. The mirror on disk is zeroed during SYNCING exactly as today.

JOURNAL LINES EMITTED. One INFO line at capture is the natural witness of the capture and is what D2D4-2 asks about: `lock GV mirror at init|raw=<t>|weighed by the boot derivation at the SYNCING exit`, placed beside `lock state file loaded` (`EA:948-950`) so the two witnesses report at the same point.

FINALS SUPERSEDED. None. Text to amend: `docs/SPEC_v0.1.md:47` "read GV mirror" gains "at init"; `README.md:70` and `:320` stay true.

SYNTHETIC VECTORS ADDED. NONE CAN REACH IT, same ground as 2a: both the capture and the witness are EA code.

ACCEPTANCE ROWS NEEDED. P3-2 as written, plus a negative control that the capture does not fire on a fresh account (P63 below), plus the static rows.

WORKED AGAINST THE 2026-08-31 LOCK. Same boot block as 2a, the GV line carrying `raw=2026.09.01 01:00:00`, because the capture at `OnInit` reads the pre kill mirror before any tick zeroes it. One difference visible only through F3 (rule 2, corroboration): during the three second SYNCING window the live mirror reads 0 under 2b and `2026.09.01 01:00:00` under 2a.

WORKED AGAINST THE 2026-08-30 BATTERY OUTAGE BOOT. The capture reads 0, the witness abstains, the block is byte identical to `:3663-3667`, as under 2a. Same second outage argument.

COST, stated, and it is the asymmetry between the options. The live mirror is still zeroed on ticks 1 to 3 of every cold boot and on every tick of a NOT EVALUABLE retry loop. A SECOND hard kill inside that window, before the SYNCING exit rewrites the mirror from LOCKED, leaves 0 on disk for the boot after it, and the witness is lost for that boot. Under 2a nothing is written until a decision has been taken, so no window of that shape exists. The window is three seconds on a clean boot and unbounded on a boot whose `HistorySelect` keeps failing.

### 3.3 Defect 2, examined and closed, ordering the write after the dispatch

The ISSUES entry names "ordered after the dispatch" as a candidate (`LEDGER.md:32`). It does not fix the defect and is closed here by the tick arithmetic of 2.1: moving `EA:1083-1087` below `EA:1160` changes the order within one tick, but the derivation runs on tick 3 at the earliest (`Pnl.mqh:448`, `EA:46`) and the write has already run on ticks 1 and 2, each writing 0 from the fresh image's `g_ag_locked_until` before any decision. Only a read on tick 1 before the first write would be saved, and `AgHistoryStable` never returns true on tick 1 (`Pnl.mqh:441-448`, the first poll sets the counter to 1 against a requirement of 3). NOT AN OPTION.

A second variant is named and not proposed: gating the write on `g_ag_locked_until > 0` rather than on state. It preserves the mirror through SYNCING but also prevents expiry from ever clearing it, since `EA:550` sets memory to 0 and the guard would then refuse the write; the mirror would carry an expired `until` forever until the next lock, which is harmless to the witness (`> now` fails) and wrong as a record. Closed.

### 3.4 Defect 4, option 4a, THE SNAPSHOT AND ACCOUNT GROUP

MECHANISM. `AgPnlNumbersString` (`EA:156-167`) gains a LOCKED branch before the `return ""`, returning a group of fields that are each individually meaningful under a lock and none of which is a live limit or a pre breach mechanism figure:

`locked_until=<t>|limit_snap=<l>|base_snap=<b>|balance=<B>|floating=<F>|equity=<E>`

where `locked_until` is `g_ag_locked_until` (`State.mqh:29`), `limit_snap` and `base_snap` are `g_ag_state_limit_snap` and `g_ag_state_base_snap` (`Persist.mqh:72-73`), `balance` is `AccountInfoDouble(ACCOUNT_BALANCE)`, `floating` is `AgFloating()` (`Pnl.mqh:262`), and `equity` is either `balance + floating` or `AccountInfoDouble(ACCOUNT_EQUITY)` per D2D4-4. No `HistorySelect`, no anchor arithmetic, no fold. The builder is called every tick at `EA:1110` and `AgProofOfLife` emits at the 30 second cadence (`Log.mqh:71-72`); the two platform reads and the position loop therefore run every tick, which is the same per tick cost `AgFloating()` already carries in ACTIVE (`EA:732`).

WHAT IT CHANGES ON THE RUNNING PATH. Nothing in any decision. `AgEvaluateLocked` is untouched. The LIFE line under LOCKED gains a group; the banner (`EA:170-179`) is a separate question, D2D4-8.

WHAT IT DOES NOT CHANGE. The state file, the model, every include, the ACTIVE group, the `lock level` line, the transition lines.

PERSISTED STATE TOUCHED. None. Reads the model, writes nothing.

JOURNAL LINES EMITTED. The existing LIFE line gains the group. No new line.

FINALS SUPERSEDED. None. Text to amend: `README.md:176` "The numbers field is present in `ACTIVE` only. A `LOCKED` line carries state, seconds, and `waiting_on`, and no PnL figures." and its Hebrew mirror `README.md:426`; the README field table `README.md:161-172` gains the LOCKED fields; `docs/SPEC_v0.1.md:253` "the ACTIVE proof-of-life line and the banner gain the governing numbers" gains a LOCKED clause under the ruling that causes it, no A7 (`LEDGER.md:2304`).

SYNTHETIC VECTORS ADDED. None unless D2D4-9(a): if the group is built by a pure function in an include, `string AgLockedNumbersString(const datetime locked_until, const double limit_snap, const double base_snap, const double balance, const double floating, const double equity)` in `Log.mqh`, which the vectors script already reaches transitively through `Persist.mqh:19`, the vectors script can assert the exact string for fixed arguments, one check per field ordering and one for the two decimal rendering, four to six checks taking the run from 95 to about 100. The ruling C precedent for moving a helper into an include so a script can reach it is `LEDGER.md:1922`.

ACCEPTANCE ROWS NEEDED. P3-4 as written (`docs/PREDICTIONS_PHASE3_DEFECTS_2026-08-19.md:191-196`), quoted in section 3.7, which needs "at least one account level event inside" a locked window and "one owner reading of the terminal at a stamped instant reconciled against the line covering it".

WORKED AGAINST THE 2026-08-31 LOCK. The line at `journal-20260831-flat-expiry-and-v1a-lock.txt:3944` would read `AG|2026.08.31 16:52:59|LIFE|state=LOCKED|seconds_in_state=13|waiting_on=expiry: TimeCurrent >= locked_until|locked_until=2026.09.01 01:00:00|limit_snap=117.54|base_snap=2350.86|balance=<B>|floating=0.00|equity=<B>|server=2026.08.31 16:52:59|local=2026.08.31 16:52:57`, `limit_snap` and `base_snap` equal to the `limit=117.54` and `base=2350.86` on the `breach arithmetic` line `:3939` because `AgDeclareLock` passes `enforced_limit` and `base` to `AgStateSetBreach` at `EA:391` from the same values it prints at `EA:396-398`. `floating=0.00` because the position closed at `terminal-20260831-v1a-lock.txt:43` six seconds earlier. `<B>` is the balance after that close and is the figure the owner asked for on 2026-08-18 and could not have (`LEDGER.md:36`); no banked artifact carries it today, which is the defect.

WORKED AGAINST THE 2026-08-30 BATTERY OUTAGE BOOT. The line at `journal-20260830-rollover-and-boot-breach.txt:3670` would read `...|locked_until=2026.08.31 01:00:00|limit_snap=127.14|base_snap=<b>|balance=<B>|floating=0.00|equity=<B>|...`, `limit_snap` equal to the `limit_cmp=127.14` on the DERIVED line `:3666` because shape 1 writes the derivation's own `limit_out` at `EA:480` (`EA:330` `limit_out = limit_cmp;`), and `balance` sitting 192.00 below `base_snap` because `realized=-192.00` on `:3666` and no position was open (`floating=0.00`). The loss the terminal's sync lines could not show (`LEDGER.md:152` "both read `0 positions`") is readable on every LIFE line of the lock.

COST, stated. The group does not carry the day's realized figure or the pnl against the snapshot. A reader wanting `realized` under a lock derives it from `balance - base_snap` only when no balance type deal landed since the anchor, which the 2133 deposit case of 2026-08-18 (`LEDGER.md:1278-1279`) shows is not always true. That is what 4b adds.

### 3.5 Defect 4, option 4b, THE FULL RECOMPUTE

MECHANISM. 4a's group plus the ACTIVE computation run under LOCKED at the LIFE cadence: `anchor=<a>|realized=<r>|pnl_vs_snap=<p> vs -<l>` where `anchor = AgDayAnchor(AgServerNow())` (`Clock.mqh:37`), `realized = AgRealized(anchor, ok)` (`Pnl.mqh:205`), and `pnl_vs_snap = realized + floating` against `-limit_snap`, the snapshot and never the live limit (Q6). The computation runs inside `AgEvaluateLocked` or a sibling called from the LOCKED dispatch at `EA:1159-1160`, guarded by its own `TimeLocal()` cadence on `AG_LIFE_INTERVAL_SECONDS` so the `HistorySelect` walk runs once per 30 seconds and not once per tick, and writes a second set of last known globals the builder prints. A failed `HistorySelect` (F6, `Pnl.mqh:224-227` WARN) leaves the previous figures in place with a `DEGRADED|` prefix, the same discipline `EA:743` applies in ACTIVE.

WHAT IT CHANGES ON THE RUNNING PATH. A history walk every 30 seconds while locked, where today LOCKED performs none. No decision changes; the Q6 witness and the expiry test are untouched.

PERSISTED STATE TOUCHED. None.

JOURNAL LINES EMITTED. The LIFE line gains the larger group. Possibly the F6 WARN from `Pnl.mqh:224` on a failed select, which today cannot occur under LOCKED.

FINALS SUPERSEDED. None. The same text amendments as 4a, wider.

SYNTHETIC VECTORS ADDED. As 4a under D2D4-9(a); the computation itself uses `AgRealized` which the existing vectors do not exercise either (`LEDGER.md:1338` "AgRealizedFold's running minimum needs real deals").

ACCEPTANCE ROWS NEEDED. P3-4 as written, plus one row that the `realized` on a LOCKED line equals the `realized` on the `breach arithmetic` line at the instant of the lock (P73).

WORKED AGAINST THE 2026-08-31 LOCK. `:3944` would additionally carry `anchor=2026.08.31 01:00:00|realized=<r>|pnl_vs_snap=<r> vs -117.54` with `<r>` the day's realized after the 16:52:53 close, and each later line would move with any further deal. After the 01:00 expiry the ACTIVE group takes over unchanged.

WORKED AGAINST THE 2026-08-30 BATTERY OUTAGE BOOT. `:3670` would carry `anchor=2026.08.30 01:00:00|realized=-192.00|pnl_vs_snap=-192.00 vs -127.14`, the `-192.00` matching `:3666` exactly, so the mobile trades the guardian caught after the fact are readable as a figure on the record rather than only on the witness line.

COST, stated. A `HistorySelect` walk every 30 seconds in a state that today takes none, and a rollover inside a lock (ruling THREE, `LEDGER.md:1930`) moves `anchor` and resets `realized` to the new day while `limit_snap` and `base_snap` stay at the breach, so the line reads a new day's realized against an old day's snapshot. That is honest and it needs the README table to say so.

### 3.6 Named and not proposed

Printing the stale `g_ag_last_*` under LOCKED. Cheapest of all, and wrong twice: the figures freeze at the declaring pass, so a liquidation inside the window is invisible exactly as today, and on a boot derived lock `g_ag_have_pnl_numbers` is false (`EA:61`) so nothing prints at all, which is the 2026-08-30 case.

Printing `peak`, `peak_level` or `ratchet_level` under LOCKED. Forbidden in substance by D8 (`LEDGER.md:1880`, "PRE BREACH ONLY") and by question SEVEN; the `lock level` line stays ACTIVE only.

Printing the LIVE limit under LOCKED. Q6 (`LEDGER.md:2049`) makes the snapshot the governing figure; a live limit on the LOCKED line would advertise a number that governs nothing, which is the shape of the adjacent ACTIVE observation at `LEDGER.md:115` ("the LIFE line advertises `limit=126.21` while `:3367` shows `enforced_limit=114.74`"). That observation is ACTIVE only, out of this plan's scope, and is named so it is not folded in by habit.

### 3.7 Acceptance rows, both defects

Evidence standard for every row, unchanged from `docs/PLAN_R10_INPUT_HARDENING_2026-09-03.md:637`: artifact file name and line number, banked as a transcoded `.txt` under `docs/evidence/`, owner copies out, executor reads the copy only, an owner dialog or banner reading is eyewitness fact for what was displayed (`LEDGER.md:19-20`), a session report counts for nothing.

Build identity for every live row, standing rule 7: the md5 of every source file against the committed tip, the ex5 mtime, and the `init|build=<label>` journal line (D2D4-13).

Static rows, worktree only:

| Row | Procedure | Expected | Evidence |
|---|---|---|---|
| D2D4-S1 compile | `metaeditor64.exe /compile:<wt>\MQL5\Experts\AccountGuardian\AccountGuardian.mq5 /include:<wt>\MQL5 /log:<jobtmp>\metaeditor.log`, and both vector scripts | `Result: 0 errors, 0 warnings` three times; every `including` line under the worktree | log lines quoted; exit code ignored, standing rule 6 |
| D2D4-S2 no trade API | grep `OrderSend`, `CTrade`, `PositionClose`, `OrderDelete`, `Trade.mqh` over `MQL5/` | exactly one hit, `Sweep.mqh` header comment | grep output quoted |
| D2D4-S3 scoped diff | `git diff bd61a0f -- MQL5/` | `AgEvaluateActive` byte identical by md5 (the R10 tail md5 `A3176C1C0E9F2D03586EAD6CBB175AA3` at `LEDGER.md:121` plus the region above it); `AgBootDerivation` touched ONLY at `EA:260` under 2b and not at all under 2a; `AgEvaluateLocked` untouched under 4a, touched only by the cadence block under 4b; includes untouched by md5 except `Log.mqh` under D2D4-9(a) | hashes quoted |
| D2D4-S4 Stage 6 static row rerun | enumerate every reference to `g_ag_obs_connected` and `g_ag_obs_resync_prev` | zero inside `AgEvaluateActive`, `AgEvaluateLocked`, `AgBootDerivation`, `AgDeclareLock`, `AgEnterLockFromBoot`, `AgRatchetUpdate` (`LEDGER.md:1320`) | grep output quoted by line range |
| D2D4-S5 clock discipline | grep `TimeLocal`, `TimeGMT`, `TimeTradeServer` over the added lines | zero added occurrences on any decision path; a `TimeLocal()` cadence under 4b is the A1 class | grep output quoted |

Deploy row, owner performs every copy, and it is the first exercise of the amended procedure of 2026-09-07 (`LEDGER.md:2312`):

| Row | Procedure | Expected | Evidence |
|---|---|---|---|
| D2D4-D deploy | RULE B alias audit first. Executor records worktree md5 and size of `AccountGuardian.ex5` and, if vectors changed, `AgPhase2StateVectors.ex5`. Owner copies per D2D4-11. Executor `Get-FileHash` on each landed file. THEN, BEFORE ANY RESTART: owner removes and re attaches the EA on the running chart with `a9_defaults.set` (the last used set per `LEDGER.md:11`), reads the dialog, clicks OK, and the executor reads the `limits accepted` line of that init. Only then the owner restarts the terminal. | every landed md5 equals the worktree md5; the pre restart init reads `INFO\|init\|build=<label>\|account=1200252169\|server=JustMarkets-Demo3` and `INFO\|limits accepted\|percent=5.50\|currency=200.00\|raw=550/200\|both list members (D1f), effective limit is the min of the two legs` with no ALERT; the post restart boot reads `BOOT->SYNCING` then `SYNCING->ACTIVE\|history stable\|polls=3/3`. If the pre restart init REFUSES, the owner corrects the inputs while attached, per the ruling, and the row records the refusal line. | hashes quoted; both inits quoted with file and line; owner dialog reading |

Live rows:

| Row | Procedure | Expected journal lines | Evidence |
|---|---|---|---|
| D2D4-0 synthetic run | owner runs `AgPhase2StateVectors` | `AGVEC\|SUMMARY\|<n>/<n>`, `<n>` = 95 under D2D4-9(b) or 95 plus the added checks under (a), every new check `PASS` | journal lines quoted |
| P3-2, quoted from `docs/PREDICTIONS_PHASE3_DEFECTS_2026-08-19.md:116-120` | "terminal killed hard and relaunched while the account is genuinely locked, with the state file and the GV mirror both intact" | "the cold boot transition reads `BOOT->SYNCING` AND `boot witness GV fired` appears in the same witness block as FILE and DERIVED, carrying the pre kill `locked_until` in its `raw` field; the memory preserving reload control still fires all three; ZERO cold boots in the run fire fewer than three witnesses" | "journal scan across at least two cold boots and one reload, quoted lines and counts" |
| P3-4, quoted from `docs/PREDICTIONS_PHASE3_DEFECTS_2026-08-19.md:191-196` | "any locked window, with at least one account level event inside it" | "every LOCKED LIFE line carries a numbers group whose fields are individually justified as still meaningful under a lock, at minimum the snapshot limit governing the window and the live figures the guardian can still compute; the balance and equity at any sampled instant inside the window are readable from the journal alone; ZERO LOCKED LIFE lines emitted without the group" | "journal scan over the whole locked window, quoted lines, plus one owner reading of the terminal at a stamped instant reconciled against the line covering it" |

Both live rows need a genuine lock, which needs a losing position that clears the enforced limit, or under version 1 a profit given back past the peak level (`LEDGER.md:140`). P3-2's hard kills advance the crash loop chain when adjacent inits fall inside 300 s (`EA:48`; `LEDGER.md:1268` "a gap of THIRTY EIGHT seconds" and `:1270` "chain=2/3" on two kills); a third inside the window trips SAFE_HALT (`EA:1026`). Two cold boots spaced more than 300 s apart keep the chain at 1 (`LEDGER.md:1704` "the chain reset at 16:29:57 with no clean record involved, because that adjacent init pair spans 302 seconds against the 300 second bound"). D2D4-14 asks how many.

### 3.8 Post fix predictions, P61 onward

**P61.** OPTION 2a OR 2b. On a cold boot while genuinely locked, the SYNCING exit block reads, in order and at one server stamp, `boot witness FILE fired|reason=DAILY_BREACH|raw=<t>|bounded=<t>`, `boot witness GV fired|raw=<t>|bounded=<t>` with `raw` equal to the `locked_until` on the pre kill `TRANSITION|...->LOCKED` line, and `boot witness DERIVED fired|...`, preceded by `TRANSITION|BOOT->SYNCING|boot|weekly=on|timer=1s`. That is P12's block on P9's transition, which today never coincide.

**P62.** OPTION 2a OR 2b. The memory preserving reload control is unchanged: `TRANSITION|LOCKED->SYNCING|boot|...` followed by all three witness lines, P12 verbatim.

**P63.** OPTION 2a OR 2b, NEGATIVE CONTROL. On a cold boot of an account that was ACTIVE and unlocked at the kill, ZERO `boot witness` lines of any kind, counted over the boot, and `SYNCING->ACTIVE|history stable|polls=3/3`. The 2026-08-30 block at `journal-20260830-rollover-and-boot-breach.txt:3663-3667` fired DERIVED only, and a fixed build on the same conditions fires DERIVED only.

**P64.** OPTION 2a OR 2b. After the fixed build's first ordinary expiry, the next cold boot fires ZERO GV lines, because expiry zeroes memory at `EA:550` and ACTIVE writes 0 at `EA:1085`; the mirror is not sticky.

**P65.** OPTION 2a ONLY, F3 corroboration per rule 2. Inside a cold boot's SYNCING occupancy the live `AG_LOCK_<login>` still reads the pre kill value; under 2b it reads 0. Sampling a three second window by hand is not expected to succeed and this prediction closes nothing.

**P66.** OPTION 2b ONLY, if D2D4-2(b). `INFO|lock GV mirror at init|raw=<t>|...` appears once per init, immediately after `lock state file loaded` (`EA:948`), with `raw` equal to the pre kill `locked_until` on a cold boot while locked and `1970.01.01 00:00:00` on a fresh account.

**P67.** OPTION 4a OR 4b. Every LIFE line carrying `state=LOCKED` carries `locked_until=`, `limit_snap=`, `base_snap=`, `balance=`, `floating=` and `equity=`; ZERO LOCKED LIFE lines without all six, counted over the whole window. P22's "ZERO occurrences of `anchor=`, `realized=`, ... on any line carrying `state=LOCKED`" is REVERSED for the fields each option adds.

**P68.** OPTION 4a OR 4b. The first LOCKED LIFE line after `TRANSITION|ACTIVE->LOCKED|DAILY_BREACH|pnl=<p>|limit=<l>|locked_until=<t>` carries `limit_snap=<l>` equal to that `limit=` and `base_snap=` equal to the `base=` on the `breach arithmetic` line of the same pass, to the cent, because `EA:391` and `EA:396-398` read the same locals.

**P69.** OPTION 4a OR 4b. The first LOCKED LIFE line after `TRANSITION|SYNCING->LOCKED|boot derivation: DAILY_BREACH|locked_until=<t>` carries `limit_snap=` equal to the `limit_cmp=` on the `boot witness DERIVED fired` line when the file carried no snapshot (shape 1, `EA:480`), and equal to the loaded file's `N` record first field when it did (`EA:473`).

**P70.** OPTION 4a OR 4b. Across a position close inside the window, consecutive LOCKED LIFE lines differ in `balance=` by the closed deal's value and `floating=` moves toward 0.00, so P23's "consecutive LOCKED LIFE lines are byte identical apart from `seconds_in_state` and the two clock fields" is FALSE on the fixed build across any account level event.

**P71.** OPTION 4a OR 4b. On a CORRUPT_STATE lock, `limit_snap=` and `base_snap=` render per D2D4-7, either `0.00` or `n/a`, and `balance=` and `equity=` still carry live figures.

**P72.** OPTION 4a OR 4b, if D2D4-6(a). While `TERMINAL_CONNECTED` is false under LOCKED, the group is prefixed `DEGRADED|` and the `waiting_on` field carries `DEGRADED: disconnected` on the same line, two markers from two sites exactly as P2-C found for the note alone (`LEDGER.md:1254`). If D2D4-6(b), the group carries no prefix and only `waiting_on` marks the disconnect.

**P73.** OPTION 4b ONLY. The first LOCKED LIFE line after an `ACTIVE->LOCKED` carries `realized=` within one deal's value of the `realized=` on the `breach arithmetic` line, and `pnl_vs_snap=<p> vs -<l>` with `<l>` equal to `limit_snap`. After a rollover inside the lock, `anchor=` advances and `realized=` resets while `limit_snap=` does not move.

**P74.** BOTH FIXES, the deploy row. The pre restart re attach on the new build logs `limits accepted|percent=5.50|currency=200.00|raw=550/200` and NO ALERT, since the last used inputs are `a9_defaults.set` values (`LEDGER.md:11`) and this build changes no input. The 2026-09-07 hazard (`LEDGER.md:109`, `raw 5` from a stale profile) does not recur unless the profile has moved.

**P75.** BOTH FIXES, no regression. `TRANSITION|ACTIVE->LOCKED` and `TRANSITION|SYNCING->LOCKED` lines are byte identical in shape to `bd61a0f`'s; `lock level`, `breach arithmetic` and `lock bounds` lines are unchanged; the ACTIVE LIFE group is unchanged.

### 3.9 Documentation surfaces the build session touches

| Surface | Defect 2 | Defect 4 |
|---|---|---|
| `docs/SPEC_v0.1.md:47` transition table Actions cell "read GV mirror" | 2b: "read GV mirror at init" | no change |
| `docs/SPEC_v0.1.md:71` "both written each timer tick" | 2a: "written each timer tick in ACTIVE and LOCKED; not written in SYNCING or SAFE_HALT, so the value a fresh image inherits survives to the boot derivation" | no change |
| `docs/SPEC_v0.1.md:253` observability | no change | LOCKED line gains the group; recorded under the ruling, no A7 (`LEDGER.md:2304`) |
| `README.md:70` and `:320` | 2a: "rewritten from memory every tick while ACTIVE or LOCKED" | no change |
| `README.md:161-172` field table, `:176` and `:426` | no change | the LOCKED sentence rewritten in both languages, the table gains the LOCKED fields, English first then Hebrew, never naming this ledger |
| `docs/DESIGN_PHASE1_2.md:104` | left as written, a design record | left as written |
| `docs/vectors/README.md` | no change | D2D4-9(a): the new checks listed |

---

## TASK 4, ruling sheet

Closed options, a and b, c only where a third is genuinely distinct. Consequence per option. NO RECOMMENDATION. Each answer is recorded FINAL in DECISIONS by the owner, per the process ruling of 2026-07-29 (`LEDGER.md:2097`).

**D2D4-1. Fix shape for defect 2.**
(a) THE STATE GATE, section 3.1: `EA:1083` gains `&& (g_ag_state == AG_STATE_ACTIVE || g_ag_state == AG_STATE_LOCKED)`. Consequence: one condition on one line; the mirror is never written before a decision has been taken on it; SAFE_HALT preserves a persisted lock's mirror; `docs/SPEC_v0.1.md:71` and `README.md:70`/`:320` are amended; self healing is suspended for the three seconds of every SYNCING occupancy.
(b) THE BOOT CAPTURE, section 3.2: one new EA global captured in `OnInit`, the witness at `EA:260` reads it. Consequence: the write stays unconditional and the SPEC clause stays literally true; the live mirror is still zeroed during SYNCING, so a second hard kill inside that window, or during a NOT EVALUABLE retry loop, loses the witness for the boot after it; one more global and one more `OnInit` step.
(c) BOTH. Consequence: the capture is redundant with the gate on every path in 2.1; two mechanisms to maintain for one property.

**D2D4-2. Journal witness for the defect 2 fix.**
(a) No new line. Consequence: P3-2 closes on the presence of `boot witness GV fired` on a `BOOT->SYNCING` boot; on a boot with no lock the fix leaves no trace, and P63 is a count of zero.
(b) One INFO line at init, `lock GV mirror at init|raw=<t>|weighed by the boot derivation at the SYNCING exit`, beside `lock state file loaded`. Consequence: every boot carries what the mirror held at the moment it was read, lock or no lock, so a zero is on the record as a zero; one more line per init; under (a) of D2D4-1 the line reports a live read taken at init even though the witness reads the live GV again at the SYNCING exit.

**D2D4-3. Fix shape for defect 4.**
(a) THE SNAPSHOT AND ACCOUNT GROUP, section 3.4: `locked_until|limit_snap|base_snap|balance|floating|equity`, no history walk. Consequence: balance and equity readable on every LOCKED line, the P3-4 minimum met; no `realized` and no pnl against the snapshot; per tick cost is two platform reads and one position loop.
(b) THE FULL RECOMPUTE, section 3.5: (a) plus `anchor|realized|pnl_vs_snap` at the LIFE cadence. Consequence: the day's realized and the comparison against the snapshot are on the record; one `HistorySelect` walk per 30 s in a state that today performs none; after a rollover inside a lock the line pairs a new day's realized with the old snapshot and the README must say so; a failed select under LOCKED becomes possible and needs the DEGRADED discipline.

**D2D4-4. The equity figure.**
(a) Derived, `equity = balance + floating`, no new platform read. Consequence: the tree keeps zero `ACCOUNT_EQUITY` reads and `LEDGER.md:1883` "NO Equity read is introduced anywhere" stays a true description; the figure equals the platform's equity only while the platform's floating equals `AgFloating()`, which the 2026-08-14 measurement showed to the cent (`LEDGER.md:1504` "equity minus balance is -52.25, equal to the ticket profit exactly").
(b) Read, `AccountInfoDouble(ACCOUNT_EQUITY)`. Consequence: the first equity read in the tree, for logging only; the base at `Pnl.mqh:254` is untouched so the 2026-08-05 FINAL is not superseded; the descriptive clause at `LEDGER.md:1883` stops describing the tree and the build entry must say so.

**D2D4-5. `breach_time` on the LOCKED line, under the shape 1 FINAL's "recorded as such" (`LEDGER.md:1890`).**
(a) Omitted. Consequence: the LOCKED line never reports the field, so the obligation is not engaged; a reader wanting the instant reads the transition line or the state file.
(b) Printed with provenance, `breach_time=<t>|breach_kind=<declared|derived|file>`, set at `EA:391` (declared), `EA:480` (derived) and `EA:473` (file, provenance unknown by the third ruling). Consequence: the obligation is satisfied on the line itself; one more EA global; `file` is the honest value after any restart, since the state file carries no marker (`LEDGER.md:1886`).

**D2D4-6. `DEGRADED|` prefix on the LOCKED group.**
(a) Keyed on `g_ag_obs_connected` (`EA:122`), read inside the builder. Consequence: the numbers field alone says the figures may be stale, the property the ACTIVE prefix was added for (`EA:150-154`); the read is in a logger and the Stage 6 static row stays clean; two markers on one line, one from the note and one from the group.
(b) No prefix. Consequence: `waiting_on` already carries `DEGRADED: disconnected` on LOCKED lines (`EA:1106-1107`, `journal-20260818-stage7-p2c-locked-disconnect.txt:1512`), so the line as a whole is unambiguous while the numbers field alone is not.

**D2D4-7. CORRUPT_STATE rendering.**
(a) `limit_snap=0.00|base_snap=0.00`, the stored values (`Persist.mqh:412-419`). Consequence: the line is a faithful print of the model; a reader must know that zeros mean CORRUPT_STATE, which the `Lock reason` on the banner and the `SYNCING->LOCKED|boot derivation: CORRUPT_STATE` line already say.
(b) `limit_snap=n/a|base_snap=n/a` when `g_ag_lock_reason == AG_LOCK_CORRUPT_STATE`. Consequence: self describing; a numeric field carries a non numeric token, which any later parser must handle.

**D2D4-8. The chart banner under LOCKED (`EA:172` "n/a (Phase 1, no ACTIVE pass has completed yet)").**
(a) Unchanged. Consequence: the banner's last line keeps a Phase 1 placeholder under every lock; the journal carries the numbers.
(b) Reads `locked: snapshot limit <l>, balance <B>` (4a) or adds `pnl <p> vs -<l>` (4b). Consequence: the on chart record matches the journal; one more branch in `AgRefreshBanner`; the Phase 1 placeholder text survives only for SYNCING.

**D2D4-9. Vector reach for the defect 4 formatter.**
(a) A pure function in `Log.mqh` builds the group from arguments; `AgPhase2StateVectors.mq5` gains four to six checks asserting the exact string. Consequence: the format is vector proven before deploy, on the ruling C precedent (`LEDGER.md:1922`); `Log.mqh` changes and its md5 moves; `docs/vectors/README.md` gains rows; the run denominator moves off 95.
(b) EA only. Consequence: the format is proven live on P3-4 alone; every include stays byte identical; the denominator stays 95.

**D2D4-10. One build or two.**
(a) One build, D2 implemented and committed before D4, one deploy, one acceptance session in which P3-2's kills and P3-4's window use the same lock. Consequence: the ruled order is honoured in commit order; one exercise of the amended deploy procedure; one lock serves both rows; a defect found in one fix during acceptance holds the other's row on the same binary.
(b) Two builds in the ruled order, D2 deployed and P3-2 closed before D4 is built. Consequence: two deploys, two exercises of the amended procedure, two locks to produce; each row closes on a binary carrying one change; the V1 sequencing shape (`LEDGER.md:1880` "no version 1 binary is deployed while either is open") applied here.

**D2D4-11. The deploy hand for this build.**
(a) A second script, `scripts/deploy-<label>.ps1`, under the 2026-09-06 ruling's shape: `Copy-Item` and `Get-FileHash` lines only, every path literal, the owner runs it. Consequence: the R10 mechanism reused; the ruling at `LEDGER.md:2308` names `scripts/deploy-r10.ps1` and a new file name needs this ruling to extend it.
(b) Dictation, one file at a time, per ruling ONE of 2026-08-18 (`LEDGER.md:1950`). Consequence: no new script; the owner types each copy; two files at most (the EA ex5 and, under D2D4-9(a), the vectors ex5).

**D2D4-12. What the deploy row records of the amended procedure.**
(a) Two artifacts, the pre restart `limits accepted` line and the post restart `BOOT->SYNCING` boot, the row recorded as the first exercise of the 2026-09-07 procedure. Consequence: the procedure gains its first banked instance; a refused pre restart init is on the row as a correction, not a failure.
(b) The post restart boot alone, the pre restart attach performed and quoted in the ACTIONS entry but not rowed. Consequence: the procedure is followed and not measured as a row.

**D2D4-13. The runtime build label, the identity channel of standing rule 7.**
(a) `init|build=D2D4`. Consequence: names the content.
(b) `init|build=R11`. Consequence: continues the R10 series, since R11 is already taken by the 2026-08-27 incidents ruling name at `LEDGER.md:1834` and would collide in prose.

**D2D4-14. P3-2's cold boot count.**
(a) As written, at least two cold boots and one reload, the two cold boots spaced more than 300 s apart so the crash loop chain stays at 1 (`EA:48`, `Persist.mqh:279`). Consequence: the row's own wording is met; the owner performs two `taskkill /F` kills while locked and one input change; the halt file records three sessions.
(b) One cold boot and one reload. Consequence: the row's "at least two" clause is amended by ruling; one kill; the pattern P11 versus P12 is shown once rather than twice.

**D2D4-15. SPEC and README edits.**
(a) In the build session, per section 3.9, SPEC in place under the ruling with no A7 (`LEDGER.md:2304`), README both languages. Consequence: the build's diff touches `docs/SPEC_v0.1.md` and `README.md`; `README.md:176` and `:426` stop being false the day the build lands.
(b) Deferred to the acceptance session. Consequence: a build whose README describes a LOCKED line it no longer emits, for the length of the acceptance window.

---

## TASK 5, LEDGER entries the build would create, drafted, not written

### 5.1 ISSUES, build session, added at the top

```
Issue:  D2 AND D4 BUILD, ACCEPTANCE PENDING. The two open defects of the fix order FINAL of 2026-08-19 (`LEDGER.md:1898`) are implemented on branch `<branch>` at commit `<hash>` per `docs/FIXPLAN_PHASE3_DEFECTS_2_4_2026-09-08.md` and the owner rulings D2D4-1 to D2D4-15 of `<date>` in DECISIONS. Defect 2 is <the state gate at EA:<n> / the boot capture at EA:<n> and EA:<n>>; defect 4 is <the snapshot and account group / the full recompute> in `AgPnlNumbersString` at EA:<n>-<n>. Static rows D2D4-S1 to D2D4-S5 <closed on measured values / open>. Deploy row D2D4-D and live rows D2D4-0, P3-2 and P3-4 are NOT RUN. Both live rows need a genuine lock, which needs a losing position or a profit given back past the peak level.
Action: OWNER DEPLOYS per RULE A and D2D4-11, attaches and confirms a healthy init with its `limits accepted` line BEFORE any restart per the 2026-09-07 procedure (D2D4-D), then produces one lock and runs P3-2's kills and P3-4's window on it per D2D4-14. Executor harvests read only and closes each row on quoted lines.
Status: OPEN
```

Plus one UPDATED paragraph on the NEXT BEST ACTION entry at `LEDGER.md:5-8`, pointing at this ISSUES entry.

### 5.2 ACTIONS, this plan session, written this session as the second commit

```
2026-09-08. D2 AND D4 DEFECT FIX PLAN SESSION, PLAN ONLY. No source file was written, no compile was run, nothing was deployed, no vector file was edited, and nothing under the MetaTrader Terminal data folder was read, written or approached, per RULE A; no command named a path inside it, so RULE B's alias audit was not reached. Work in worktree `d2d4-plan-20260908` on branch `worktree-d2d4-plan-20260908` from `bd61a0f`, main's own head. LEDGER.md was read in full, all 2314 lines, before any of the work below, per execution rule 2. Two commits: `docs/FIXPLAN_PHASE3_DEFECTS_2_4_2026-09-08.md` (`<H1>`), and this entry, the second commit. THE PLAN quotes both ISSUES entries and the fix order FINAL whole, tags forty one FINAL entries INHERITED and finds ZERO clauses that any option supersedes, maps every read, write and journal site of the GV mirror at `bd61a0f` (the write at EA:1083-1087, the read at EA:259-271, the three setters of `g_ag_locked_until` at EA:386, :452 and :550, and the stability gate at Pnl.mqh:426-449 that puts the read on the third tick) across the cold boot, chart re init and 01:00 rollover paths, maps the single LIFE emitter Log.mqh:66-87 with its single call site EA:1109-1110 and what each argument carries in LOCKED, and lays out two closed options per defect: for defect 2 a state gate on the write or a boot capture of the mirror in OnInit, with reordering the write after the dispatch examined and closed by tick arithmetic; for defect 4 a snapshot and account group or a full recompute at the LIFE cadence. Each option is worked against the 2026-08-31 lock (`journal-20260831-flat-expiry-and-v1a-lock.txt:3939-3944`) and the 2026-08-30 battery outage boot (`journal-20260830-rollover-and-boot-breach.txt:3663-3670`), where both defect 2 options change nothing on the boot itself, the mirror having held 0 before the outage, and would change the boot after it. Predictions P61 to P75 continue the defect 3 plan's numbering. THE RULING SHEET carries fifteen closed questions, D2D4-1 to D2D4-15, fix shape per defect, journal witness, equity source, `breach_time` provenance under the shape 1 FINAL, DEGRADED prefix, CORRUPT_STATE rendering, banner, vector reach, one build or two, the deploy hand, what the deploy row records of the 2026-09-07 procedure, the build label, P3-2's boot count, and the SPEC and README edits, with the consequence of each option and NO RECOMMENDATION. Two facts found for free and recorded: the source at `bd61a0f` is md5 identical to the R10 build identity on all six files the R10 entry names, so the plan cites the running binary's own source; and `ACCOUNT_EQUITY` has zero occurrences in the tree, the only `AccountInfoDouble` read being Pnl.mqh:254. The build's ISSUES and ACTIONS entries are drafted inside the plan and not written. Nothing is merged and the executor performed no push.
```

### 5.3 ACTIONS, build session template, every angle bracket field a measured value

```
<date>. D2 AND D4 BUILD IMPLEMENTED PER THE RULINGS D2D4-1 TO D2D4-15 OF <date>, on branch `<branch>` at `<hash>`, <n> files, <ins> insertions and <del> deletions, D2 committed at `<hash>` BEFORE D4 at `<hash>` per the fix order FINAL. RULE A held. Compile inside the worktree: `Result: 0 errors, 0 warnings, <ms> ms elapsed` for the EA and both vector scripts, exit code ignored per standing rule 6, every `including` line under the worktree. Build identity per standing rule 7: `AccountGuardian.mq5` `<md5>`, <changed includes with md5>, and the unchanged includes `<md5 each>`; ex5 `<md5>` at <bytes> bytes, mtime <ts>, recorded and not identity. Static rows: D2D4-S1 to D2D4-S5 <values>; `AgEvaluateActive` byte identical at md5 `<hash>`. <Vectors: <n> checks added, denominator <n>.> SPEC `:47`/`:71`/`:253` and README `:70`/`:176`/`:320`/`:426` amended per D2D4-15. Nothing deployed, nothing merged, no push.
```

### 5.4 ACTIONS, acceptance session template

```
<date>. D2 AND D4 ACCEPTANCE, <k> OF <n> ROWS CLOSED. D2D4-D: landed md5 `<md5>` equals worktree; pre restart attach `limits accepted|percent=5.50|currency=200.00|raw=550/200` at `<file>:<line>` with no ALERT, first exercise of the 2026-09-07 procedure; post restart `BOOT->SYNCING` at `:<line>`. D2D4-0: `AGVEC|SUMMARY|<n>/<n>` at `<file>:<line>`. THE LOCK: `<TRANSITION line>` at `:<line>`. P3-2: cold boot one at `:<line>` `BOOT->SYNCING`, witness block `:<lines>` with `boot witness GV fired|raw=<t>`; cold boot two at `:<lines>`; reload control `LOCKED->SYNCING` at `:<line>` with three witnesses at `:<lines>`; ZERO cold boots with fewer than three, counted over `<file>`. P3-4: first LOCKED LIFE at `:<line>` carrying `<group>`; the account level event at `<terminal file>:<line>`; the line covering it at `:<line>`; owner reading <values> at <stamp> against `balance=<B>|equity=<E>` on `:<line>`; ZERO LOCKED LIFE lines without the group over `<file>`. Evidence banked at `docs/evidence/<files>` md5 `<md5 each>`.
```

## What closes none of this

No option, prediction or row in this document is closed by reading source. Each names a journal line, a file content or a count over a named window, and closes on the artifact only, the standing evidence rule of 2026-08-05 (`LEDGER.md:2010`) applied in advance. This document is a plan. It recommends nothing and authorises nothing.
