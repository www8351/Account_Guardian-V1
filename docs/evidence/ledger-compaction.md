# Ledger compaction of 2026-10-22

Evidence for the ACTIONS entry of 2026-10-22 in `LEDGER.md`. Branch `ledger/compaction`, cut from main at `ffa5186c13a694f90d7ee7065e055a94f6f92de0`. The new ledger is commit `88764ed`; the proof script `scripts/rows/ledger_compaction.py` is commit `d115cc9`. Line numbers below are those of `LEDGER.md` at `ffa5186`.

## The owner's authorization of 2026-10-22, quoted whole

```
COMPACTION AUTHORIZED, with the owner's corrections and answers of 2026-10-22
below. Run Part B of C1.txt with these changes. Where this file and the Part A file
C:\Users\www83\Documents\AG-prompts\C1-classification.md differ, this file wins.

DECISIONS, the corrections to the classification
1. :2750 (the correction to D8b) and :2829 (PK-14 amended to (b)) are KEEP. Each one
   amends a KEEP entry, :2746 and :2825, and deleting the amendment would leave the
   kept entry in its unamended wording. Place each one directly after the entry it
   amends.
2. :2917, :2921 and :2925 are deleted, as proposed.
3. :2316 is KEEP.
4. :2495 is deleted. The shipped code is the answer to it.
5. :2599: read its Decision text. If it binds the code or a standing procedure, and
   not only a Phase 0 row, it is KEEP; otherwise it is deleted, as proposed. Report
   which, with its Decision text.

ISSUES
6. The kept entries are texts A, D, B, C and E as drafted in the Part A file, in
   that order, then text PUB. :39 stays as the short OPEN entry PUB.
7. :202 leaves ISSUES, covered by the KEEP entry :2331.

THE PART A QUESTIONS
8. Q-A: :2937 stays byte for byte. The proof script reports it as the one known
   exception to the naming rule of :2542, and checks that the word has no other bare
   use anywhere in the new ledger.
9. Q-B: every line of a KEEP entry carries over except its Reason lines.
10. Q-C: inside ACTIONS, the compaction entry comes first, then the history.
11. Q-D: noted. No action.

HISTORY AND PROJECT
12. The history of section 3 and the PROJECT text of section 4 of the Part A file
    are approved as drafted.

THE COMPACTION ENTRY AND THE PROOF
13. The ACTIONS entry for this compaction is at most 1,500 characters. Its evidence
    file docs/evidence/ledger-compaction.md quotes this file whole, the owner
    evidence of C1.txt, the final class of every DECISIONS entry with its line at
    ffa5186, and the proof script's output.
14. The proof script checks every entry this file makes KEEP, the amendments of
    item 1 included, and reports the final counts: KEEP, deleted one-time, deleted
    superseded.

Every other part of C1.txt stands, its STOP FOR and NOT AUTHORIZED included. Stop at
the end of Part B and report.
```

## The owner evidence of C1.txt, quoted as given

```
OWNER EVIDENCE, 2026-10-21. Record it in the compaction's ACTIONS entry as given,
not verified by the executor: the owner deployed the B5 build to the demo terminal;
"2026.10.21 20:05:09.528 AgPhase2StateVectors (XAUUSD.ecn,M5)
AGVEC|SUMMARY|522/522"; the command was answered with the status message in the B5
format, with the headline bold and with the open trades line and the PNL line
present. By R1, this closes the R2 row "the B3 format on the terminal". Every other
row of R2 stays OPEN, the live computer included.
```

Recorded in the compaction entry of ACTIONS as given, not verified by the executor. Under R1 it closes the R2 row "the B3 format on the terminal"; every other R2 row stays OPEN, in text A of ISSUES.

## Item 5, the entry at :2599

The Decision text at `:2599`, quoted:

```
Decision: (owner ruling 2026-07-30) R3, server offset, is a measurement and a record correction, not a decision gate. The executor measures, corrects the audit record in the ledger, and continues without stopping; escalation only if the measurement contradicts a FINAL decision.
```

Verdict: deleted, one-time, as proposed. It binds the R3 server offset measurement of Phase 0 and nothing else, and that measurement was made on 2026-07-30, quoted from ACTIONS `:2224`: "R3 measured: server clock equals machine clock, broker GMT+3, offset about zero, established by the identity chain process start, journal stamp, TimeCurrent body, TimeLocal record, and file mtime all agreeing within seconds". It binds no code and no standing procedure. The server DST harvest that stays in ISSUES rests on Q1 of 2026-08-08, kept at `:2673`, not on R3.

## The final class of every DECISIONS entry

202 entries: KEEP 154, deleted one-time 35, deleted superseded 13. A KEEP entry stands in the new ledger with every line but its Reason lines, under the topic heading named. "Mixed" marks a KEEP entry that joins a standing rule with a one-time record. The owner's corrections of 2026-10-22 are named by their item number.

| Line | Final class | Entry | Note |
|---|---|---|---|
| 2273 | KEEP | .gitignore keeps the bare *.log rule with !docs/evidence/** below it | topic: Git and repository |
| 2276 | KEEP | from 2026-08-19 a live behaviour citation names the artifact file and line | topic: Process and evidence |
| 2279 | KEEP | the roadmap surface is owner side and outside the repository scope | topic: Process and evidence; mixed |
| 2282 | KEEP | the primary checkout stays on main | topic: Git and repository |
| 2285 | deleted, one-time | R5 investigation runs first against metaeditor.log, the owner copies it out |  |
| 2288 | KEEP | ISSUES holds open items only; ACTIONS append only | topic: Process and evidence |
| 2291 | KEEP | repository public; account, terminal id, broker, paths not secret; raw terminal files never in git | topic: Git and repository |
| 2294 | deleted, superseded | R8: the real account on an always on VPS, deploy by git sync | superseded by :2913, no VPS, ruling (4) of 2026-10-01, which names R8 |
| 2297 | deleted, one-time | a tmp copy of a state file is residue, the owner deletes it |  |
| 2300 | deleted, superseded | limit input hardening is a mandatory stage before COMPLETE | superseded by :2722, D1f and the R10 rulings that carried it out |
| 2303 | deleted, one-time | R11: the 2026-08-27 compile incidents were owner actions |  |
| 2306 | deleted, one-time | Q8 cadence cap, permanent scope limit of a Phase 1 row (moved from ISSUES) |  |
| 2311 | deleted, one-time | MathIsValidNumber gate fix struck as never existing (moved from ISSUES) |  |
| 2316 | KEEP | fresh load audit and the attach procedure for the A9 matrix (moved from ISSUES) | topic: Process and evidence; owner correction: KEEP, owner item 3 |
| 2321 | KEEP | executor error; standing lesson: walk an audit forward to the end state (moved from ISSUES) | topic: Process and evidence; mixed |
| 2326 | deleted, one-time | bypass demonstration scope limit (moved from ISSUES) |  |
| 2331 | KEEP | standing observation rules (1) to (7) (moved from ISSUES) | topic: Process and evidence |
| 2336 | KEEP | #property version "1.00" note (moved from ISSUES) | topic: Scope and platform |
| 2341 | KEEP | the account trades everything; BTCUSD.ecn stays in Market Watch; the weekend is a trading day | topic: Scope and platform |
| 2345 | KEEP | four rulings closing version 1: implementation readings, build identity, the 2026-08-29 rollover, the 2026-08-30 boot lock | topic: Ratchet and realized peak; mixed |
| 2349 | KEEP | version 1, the realized peak trailing floor, nine elements D1 to D8 | topic: Ratchet and realized peak |
| 2355 | KEEP | "recorded as such" met by ledger, plan and journal; no state file format change | topic: Lock, state machine and boot derivation |
| 2359 | KEEP | defect 3 shape 1: breach_time on the boot derived path is the derivation instant | topic: Lock, state machine and boot derivation |
| 2363 | KEEP | defect 1 shape A: lock expiry enters SYNCING; defect 3 coupled to the same deploy | topic: Lock, state machine and boot derivation; mixed |
| 2367 | deleted, one-time | defect fix order (1) to (4) for one build |  |
| 2371 | KEEP | reseed on reload stays as is | topic: Lock, state machine and boot derivation |
| 2375 | deleted, superseded | P2-H not closable by this build | superseded by :2901, P2-H PASS by attestation, 2026-10-01 |
| 2379 | deleted, superseded | PROPOSAL, main not checked out anywhere (UNRULED, then REJECTED) | superseded by :2282, the proposal REJECTED, main stays checked out |
| 2383 | KEEP | ratchet epsilon: AgRatchetUpdate branch tests through AG_PNL_EPSILON, fixed before Part 2 | topic: Ratchet and realized peak |
| 2387 | KEEP | AG_QUOTE_FROZEN_SECONDS = 120, a constant | topic: Clock, quotes and day anchor |
| 2391 | KEEP | AgLockedUntilComputed and AgLockedUntilFromWitness live in Clock.mqh | topic: Lock, state machine and boot derivation; mixed |
| 2395 | KEEP | the question FOUR floor wins over the 2026-07-30 clamp, by domain | topic: Lock, state machine and boot derivation |
| 2399 | KEEP | Phase 2 question THREE: anchor straddle floor on locked_until | topic: Lock, state machine and boot derivation |
| 2403 | KEEP | Phase 2 question FOUR: locked_until never below the latch next day anchor | topic: Lock, state machine and boot derivation |
| 2407 | KEEP | Phase 2 question FIVE: carry drag is total exposure | topic: PnL evaluation and limits |
| 2411 | KEEP | Phase 2 question SIX: observability ships inside Phase 2, quote age note non gating | topic: Clock, quotes and day anchor; mixed |
| 2415 | KEEP | Phase 2 question SEVEN: the ratchet mechanism, five elements | topic: Ratchet and realized peak |
| 2419 | KEEP | Phase 2 question ONE: the owner performs every copy into the terminal folder, dictation protocol | topic: Terminal folder, deploy and vectors |
| 2423 | deleted, superseded | Phase 2 question TWO: interim posture, locks but sends no order | superseded by :2793, ENF-1 to ENF-29, which supersedes its operative clause |
| 2427 | KEEP | CLAUDE.md returns to untracked (owner reversal) | topic: Git and repository |
| 2431 | deleted, superseded | all three protocol files tracked in git | superseded by :2427, the owner reversal, CLAUDE.md untracked |
| 2435 | KEEP | provenance correction of the stale quote entry; no session cites its own draft as a ruling | topic: Clock, quotes and day anchor; mixed |
| 2439 | KEEP | stale quote: a breach may be taken from an unproven fresh quote while connected | topic: Clock, quotes and day anchor |
| 2443 | KEEP | README token usage block removed permanently, a returning block deleted on sight | topic: README and SPEC; mixed |
| 2447 | KEEP | the GateGuard hook is a project tool feature, kept on | topic: Process and evidence |
| 2451 | deleted, one-time | Phase 1 closed |  |
| 2455 | deleted, one-time | P1-B closed |  |
| 2459 | deleted, one-time | P1-C closed |  |
| 2463 | deleted, one-time | P1-K pass by construction |  |
| 2467 | deleted, one-time | P1-O closed |  |
| 2471 | deleted, superseded | stale quote gap and carry drag stay open as Phase 2 inputs | superseded by :2439 (stale quote) and :2407 (carry drag, question FIVE) |
| 2475 | KEEP | governance incident: RULE A and RULE B | topic: Terminal folder, deploy and vectors |
| 2479 | KEEP | a session report is not evidence, only artifacts are | topic: Process and evidence |
| 2483 | KEEP | A10: the SPEC transition table moves, the code stands | topic: Lock, state machine and boot derivation |
| 2487 | KEEP | target stack: MQL5 account level Expert Advisor | topic: Scope and platform |
| 2491 | KEEP | the EA cannot close the terminal; maximum enforcement is close, delete, block | topic: Scope and platform |
| 2495 | deleted, superseded | library or framework for MQL5 not yet chosen | superseded by the shipped code, the owner's item 4 of 2026-10-22; owner correction: deleted, owner item 4 |
| 2498 | KEEP | Q1: DAILY_BREACH locked_until is the next day anchor | topic: Lock, state machine and boot derivation |
| 2502 | KEEP | Q2/F1: the percent base is reconstructed live from all deals since the anchor | topic: PnL evaluation and limits |
| 2506 | KEEP | Q3/F2: trade disallowed states are kill equivalent, detect only, loud | topic: Enforcement sweep |
| 2510 | KEEP | Q4/F9: config classes, a malformed core input refuses init | topic: Inputs and config |
| 2514 | KEEP | Q5/F16: flatten and the locked sweep delete pending orders | topic: Enforcement sweep |
| 2518 | KEEP | Q6/F7: the breach snapshot governs the locked window | topic: Lock, state machine and boot derivation |
| 2522 | KEEP | Q7/F5: TimeCurrent only for expiry and anchor decisions | topic: Clock, quotes and day anchor |
| 2526 | KEEP | Q8: dual limits, the stricter wins | topic: PnL evaluation and limits |
| 2530 | KEEP | F11: carried position double count | topic: PnL evaluation and limits |
| 2534 | KEEP | F12: realized whitelist, BUY and SELL deals only | topic: PnL evaluation and limits |
| 2538 | KEEP | F13: timer driven, EventSetTimer(1) | topic: Scope and platform |
| 2542 | KEEP | naming discipline: the bare word heartbeat is never used | topic: Process and evidence |
| 2546 | KEEP | lock artifacts are quarantined, never deleted | topic: Lock, state machine and boot derivation |
| 2550 | KEEP | owner note: a fresh dead man check with a new UUID | topic: Telegram alerts |
| 2554 | KEEP | Amendment 1: LEDGER.md tracked, CLAUDE.md local | topic: Git and repository |
| 2558 | KEEP | Amendment 2a/2b: SAFE_HALT evidence in halt_<login>.dat | topic: Halt, crash loop, mutex and liveness |
| 2562 | KEEP | Amendment 2c: manual resume is deleting the halt file by hand | topic: Halt, crash loop, mutex and liveness |
| 2566 | KEEP | only the owner marks an entry FINAL | topic: Process and evidence |
| 2570 | KEEP | crash loop and mutex timestamps use the local clock | topic: Halt, crash loop, mutex and liveness |
| 2575 | KEEP | AG_LIFE_INTERVAL_SECONDS = 30, a constant | topic: Halt, crash loop, mutex and liveness |
| 2579 | KEEP | AG_MUTEX_STALE_SECONDS = 10, a constant | topic: Halt, crash loop, mutex and liveness |
| 2583 | KEEP | a persistence model never loaded is never written | topic: Halt, crash loop, mutex and liveness |
| 2587 | KEEP | manual resume detection is best effort | topic: Halt, crash loop, mutex and liveness; Status REVISIT |
| 2591 | KEEP | R1: crash loop primitive, consecutive unclean sessions with a pairwise gap bound | topic: Halt, crash loop, mutex and liveness |
| 2595 | deleted, superseded | R2: CrashLoopWindowSeconds default 300 | superseded by :2761, D11a, CrashLoopWindowSeconds = 300 a constant |
| 2599 | deleted, one-time | R3: server offset is a measurement, not a gate | owner correction: deleted, owner item 5 |
| 2603 | deleted, one-time | R4: the bypass demonstration runs both refusal rows at contact 1 |  |
| 2607 | KEEP | proof of life, SPEC amendment A3 | topic: Halt, crash loop, mutex and liveness |
| 2611 | KEEP | a witness supplied locked_until is clamped to the next day anchor | topic: Lock, state machine and boot derivation |
| 2615 | KEEP | a login mismatched state file is CORRUPT_STATE equivalent | topic: Lock, state machine and boot derivation |
| 2619 | KEEP | Phase 4 weekly banner shows the raw weekly figure only | topic: Scope and platform |
| 2623 | KEEP | test epsilon 0.01; a live breach epsilon errs toward breach | topic: PnL evaluation and limits |
| 2627 | KEEP | 2026-08-01 instrument scope (two clauses superseded by :2341) | topic: Scope and platform |
| 2631 | KEEP | Q6 clarification: with no snapshot the derived comparison falls back to live inputs | topic: Lock, state machine and boot derivation |
| 2635 | KEEP | build the ratchet defense against active state limit inflation | topic: Ratchet and realized peak |
| 2639 | KEEP | merge gate replaced: a branch merges on its own proven work | topic: Git and repository |
| 2644 | KEEP | a visible REFUSED banner on both refusal paths | topic: Inputs and config |
| 2648 | KEEP | a backward clock step counts inside the crash loop window | topic: Halt, crash loop, mutex and liveness |
| 2652 | KEEP | the a9 vectors committed under docs/vectors, sync repository to terminal | topic: Terminal folder, deploy and vectors |
| 2656 | deleted, superseded | SweepPeriodSeconds wording: refused outside 1..5 | superseded by :2742, D7b, SweepPeriodSeconds = 1 a constant |
| 2660 | KEEP | the repository does not live inside the MT5 terminal data folder | topic: Git and repository |
| 2665 | KEEP | remote state is owner managed; the executor never pushes; no durable remote claims | topic: Git and repository |
| 2669 | KEEP | the day anchor base is Balance; the day starts at 01:00 Israel | topic: Clock, quotes and day anchor |
| 2673 | KEEP | Q1 of 2026-08-08: 01:00 server constant, REVISIT after the 2026-10-25 to 2026-11-01 harvest | topic: Clock, quotes and day anchor |
| 2677 | deleted, superseded | Q2 of 2026-08-08: Phase 1 interim posture, alert only | superseded by :2423, the Phase 2 posture, itself superseded by :2793 |
| 2681 | KEEP | Q3 of 2026-08-08: DEAL_FEE in the per deal value | topic: PnL evaluation and limits |
| 2685 | KEEP | Q4 of 2026-08-08: a deal at the anchor second belongs to the new day | topic: Clock, quotes and day anchor |
| 2689 | deleted, one-time | Q5 of 2026-08-08: withdrawals unavailable on the demo, rows redesigned |  |
| 2693 | deleted, one-time | Q6 of 2026-08-08: Phase 0 last gate closed |  |
| 2697 | deleted, one-time | Q7 of 2026-08-08: the symbol specification read rides the next owner session |  |
| 2701 | KEEP | Q8 weekend reopen amendment: alert and advance | topic: Clock, quotes and day anchor |
| 2706 | KEEP | Q8 of 2026-08-08: the in memory high water anchor latch | topic: Clock, quotes and day anchor |
| 2710 | KEEP | Q9: the one pass breach deferral | topic: PnL evaluation and limits |
| 2714 | KEEP | Q10 reconnect amendment: RESYNC needs history stability | topic: PnL evaluation and limits |
| 2718 | KEEP | Q10: DEGRADED while disconnected | topic: PnL evaluation and limits |
| 2722 | KEEP | D1f: both limits are mandatory list inputs with ceilings | topic: Inputs and config |
| 2726 | deleted, superseded | D2/D3/D3b: void under D1f | superseded by :2722, void under D1f by its own text |
| 2730 | KEEP | D4a: within the ceiling while locked, an input change is rejected and journaled | topic: Inputs and config |
| 2734 | KEEP | D5a: a tightening takes effect immediately | topic: Inputs and config |
| 2738 | KEEP | D6a: the ratchet compares the derived limit; the ceiling check is per raw input | topic: Inputs and config |
| 2742 | KEEP | D7b: SweepPeriodSeconds = 1 and HistoryStablePolls = 3 are constants | topic: Inputs and config |
| 2746 | KEEP | D8b: struck a9 vectors retired, two survive | topic: Terminal folder, deploy and vectors |
| 2750 | KEEP | CORRECTION to D8b: the two survivors carry DailyLossCurrency=0.0 | topic: Terminal folder, deploy and vectors; owner correction: KEEP, owner item 1 |
| 2753 | KEEP | D9a: an ignored widening uses the ratchet HOLDING WARN form | topic: Inputs and config |
| 2757 | deleted, one-time | D10a: hardening ships first as its own build |  |
| 2761 | KEEP | D11a: CrashLoopMaxInits = 3 and CrashLoopWindowSeconds = 300 are constants | topic: Inputs and config |
| 2765 | KEEP | defaults under D1f: 5.50 and 200 | topic: Inputs and config |
| 2769 | deleted, one-time | R10 plan review: four plan items ratified |  |
| 2773 | KEEP | R10 build review: SPEC:114 ratified; SPEC amendment series closed at A6 | topic: README and SPEC; mixed |
| 2777 | KEEP | deploy hand: the executor writes a copy script, the owner runs it | topic: Terminal folder, deploy and vectors |
| 2781 | KEEP | deploy procedure: healthy init before any restart; the limits accepted raw= line is the witness; banner survival deferred | topic: Terminal folder, deploy and vectors |
| 2785 | KEEP | D2D4-1 to D2D4-15 | topic: Lock, state machine and boot derivation; mixed |
| 2789 | KEEP | worktrees and branches are kept after merge as evidence | topic: Git and repository |
| 2793 | KEEP | ENF-1 to ENF-29, the enforcement sweep | topic: Enforcement sweep |
| 2797 | KEEP | ENF-30: the refuse class re-arms | topic: Enforcement sweep |
| 2801 | KEEP | ENF-31: the sweep walk is positions first | topic: Enforcement sweep |
| 2805 | KEEP | ENF-DEF-1 (b): the sweep= field reflects what is open | topic: Enforcement sweep; mixed |
| 2809 | KEEP | the boot ALERT head | topic: Enforcement sweep |
| 2813 | deleted, one-time | ENF-31 rerun set |  |
| 2817 | KEEP | branch plan: each item on its own branch, items (1) to (5) | topic: Git and repository |
| 2821 | deleted, one-time | ENF-DEF-1 manifestation ONE accepted on source read |  |
| 2825 | KEEP | PK-1 to PK-15, the peak path witness | topic: Lock, state machine and boot derivation; mixed |
| 2829 | KEEP | PK-14 amended to (b) | topic: Lock, state machine and boot derivation; owner correction: KEEP, owner item 1 |
| 2833 | KEEP | IN-1 to IN-29, the customer installer | topic: Installer and release; mixed |
| 2837 | KEEP | export secrecy (a): comment only scrub of the shipped sources | topic: Installer and release |
| 2841 | deleted, superseded | IN-S7 (c): stays open, publication gated on it | superseded by :2889, IN-S7 redefined (a) |
| 2845 | KEEP | the six build departures of fad86fa ratified | topic: Installer and release |
| 2849 | KEEP | README.md is Hebrew only | topic: README and SPEC |
| 2853 | KEEP | IN-27 replaced: installer acceptance on a separate new computer | topic: Installer and release |
| 2857 | KEEP | export gap (a): docs/media svg and gif files only | topic: Installer and release; mixed |
| 2861 | KEEP | IN-21 replaced by (c): the console shows English only | topic: Installer and release |
| 2865 | KEEP | installer build merged onto the README branch; "README.md stays bilingual." void | topic: Installer and release; mixed |
| 2869 | KEEP | GIF links: publication gated on the three GIF files | topic: Installer and release |
| 2873 | KEEP | installer acceptance evidence is what the owner banks and attests | topic: Installer and release |
| 2877 | KEEP | IN-S6 redefined for the Hebrew only README | topic: Installer and release |
| 2881 | KEEP | installer acceptance rows are closed by the owner's attestation | topic: Process and evidence |
| 2885 | KEEP | DEFECT D1 (b): no fix, the line order stays | topic: Installer and release |
| 2889 | KEEP | IN-S7 redefined (a): release repository only | topic: Installer and release |
| 2893 | deleted, one-time | PK-L1, PK-L2 and PK-L4 closed by attestation |  |
| 2897 | deleted, one-time | branch worktree-readme-upgrade-20260926 dropped unmerged |  |
| 2901 | deleted, one-time | rows passed by attestation: P2-A, P2-H, market closed, P1-L, P1-N, have_snapshot |  |
| 2905 | KEEP | V2 moved to the V2 repository | topic: Scope and platform |
| 2909 | KEEP | Phase 3 maximum position size: the customer chooses | topic: Scope and platform |
| 2913 | KEEP | no VPS; a dedicated computer runs the guardian | topic: Terminal folder, deploy and vectors |
| 2917 | deleted, one-time | the final acceptance week is cancelled | owner correction: deleted, owner item 2 |
| 2921 | deleted, one-time | the last used inputs hazard is closed | owner correction: deleted, owner item 2 |
| 2925 | deleted, one-time | machine sleep is handled by the owner | owner correction: deleted, owner item 2 |
| 2929 | KEEP | the README token usage badge writer is cancelled | topic: README and SPEC |
| 2933 | deleted, one-time | Telegram token absent from repository history (owner statement) |  |
| 2937 | KEEP | code review findings (1) to (7) ruled | topic: Installer and release; mixed |
| 2941 | deleted, one-time | review fix build: IN-D and RC-1 pass by attestation |  |
| 2945 | KEEP | TG-1 (B): a separate MQL5 Service fed by a queue file | topic: Telegram alerts |
| 2949 | KEEP | TG-2.1 (A): the owner's healthchecks.io check | topic: Telegram alerts |
| 2953 | KEEP | TG-2.2: network heartbeat every 60 s | topic: Telegram alerts |
| 2957 | KEEP | TG-2.3 (A): 60 s period plus 240 s grace | topic: Telegram alerts |
| 2961 | KEEP | TG-3 (B): approach levels 50 and 80 percent | topic: Telegram alerts |
| 2965 | KEEP | TG-4 (B): end of day summary at the rollover | topic: Telegram alerts |
| 2969 | KEEP | TG-5 (B): a persisted queue file | topic: Telegram alerts |
| 2973 | KEEP | TG-6: token, chat id and ping URL are service inputs | topic: Telegram alerts |
| 2977 | deleted, one-time | TG-7: void, the bot and token are the owner's |  |
| 2981 | KEEP | TG-8 (B): one read only command | topic: Telegram alerts |
| 2985 | KEEP | TG-9 (A): the README gains Hebrew setup steps | topic: Telegram alerts |
| 2989 | KEEP | TG-10 (A): acceptance on a demo terminal, then the live account | topic: Telegram alerts |
| 2993 | deleted, one-time | TG-11 (A): base branch for the build |  |
| 2997 | deleted, one-time | TG-12 (A): the alerts work now, beside Phase 4 planning |  |
| 3001 | KEEP | TG-13 (B): sends at a stop and at a refused start | topic: Telegram alerts |
| 3005 | KEEP | a periodic status message every 4 hours | topic: Telegram alerts |
| 3009 | KEEP | S12 in ACTIVE: trade permission flags read in every state | topic: Telegram alerts |
| 3013 | KEEP | S12 in ACTIVE: local Alert and chart banner | topic: Telegram alerts |
| 3017 | KEEP | TG-14 (A): command poll every 60 s | topic: Telegram alerts |
| 3021 | KEEP | TG-15 (A): status slots on the local clock | topic: Telegram alerts |
| 3025 | KEEP | TG-16 (A): the service ex5 straight into MQL5\Services | topic: Telegram alerts |
| 3029 | deleted, one-time | the SPEC changes of the alerts build |  |
| 3033 | KEEP | a trade disallowed state in SYNCING or SAFE_HALT (A) | topic: Telegram alerts |
| 3037 | deleted, one-time | TG-S10 and TG-S7 fixed before the deploy |  |
| 3041 | KEEP | TG-S11: how the row reads | topic: Telegram alerts |
| 3045 | KEEP | TG-S16: AgTgInitReset an allowed site | topic: Telegram alerts |
| 3049 | deleted, one-time | TG-W closes on the owner's attestation |  |
| 3053 | KEEP | the message format F1 to F11 | topic: Telegram alerts |
| 3057 | KEEP | equity in the messages | topic: Telegram alerts |
| 3061 | KEEP | R1: attestation closes a row in the deployment phase | topic: Process and evidence |
| 3065 | KEEP | R2: the merges into main and the rows not yet run | topic: Telegram alerts; mixed |
| 3069 | KEEP | R3: the PNL line | topic: Telegram alerts |
| 3073 | KEEP | R4: the open trades line | topic: Telegram alerts |
| 3077 | KEEP | R5: an ACTIONS entry is at most 1,500 characters | topic: Process and evidence |

## ISSUES at ffa5186 and where each entry went

Six entries stay, in this order: text A (`:5`), D (`:197`), B (`:9`), C (`:142`), E (`:210`) and PUB (`:39`). "Stale" marks a Status line that reads OPEN while the entry's own later lines record the close.

| Line | Entry | Status as written | Where it went |
|---|---|---|---|
| 5 | TELEGRAM ALERTS ROWS NOT YET RUN | OPEN | kept, text A, the next best action |
| 9 | history stability poll counter not reset on EA reinit | OPEN | kept, text B |
| 26 | Telegram alerts on account and guardian state, plan to B3 | OPEN (stale) | left; `:6` says it keeps the history through B3 and its status line predates the merges of R2; its open rows are in text A |
| 34 | REVIEW FIX BUILD | DONE | left, history |
| 39 | INSTALLER BUILD | DONE except publication | kept as text PUB, owner item 6 |
| 51 | DEFECT D1 | CLOSED | left; ruling kept at `:2885` |
| 55 | EXPORT SECRECY CONFLICT | CLOSED | left, history |
| 60 | INSTALLER, FOR THE OWNER'S RULING | OPEN (stale) | left; `:62` records IN-1 to IN-29 ruled |
| 65 | PK BUILD | PK acceptance complete | left, history |
| 71 | ENF-31 BUILD, ACCEPTANCE PENDING | OPEN (stale) | left; `:74` closes the rerun set |
| 77 | ENFORCEMENT BUILD, ACCEPTANCE PENDING | OPEN (stale) | left; `:81` closes every original live row |
| 84 | ENF-DEF-1 | OPEN (stale) | left; its own CLOSED line `:87` |
| 90 | ENF-31 BUILD PENDING | OPEN (stale) | left; built per `:92`, accepted per `:74` |
| 95 | BYPASS PATH | OPEN (stale) | left; answered by PK-1 to PK-15, PK accepted per `:68` |
| 105 | NEXT BEST ACTION, the D2/D4 plan session | OPEN (stale) | left; D2/D4 closed at `:121`, enforcement accepted per `:81` and `:74` |
| 119 | D2 AND D4 BUILD | CLOSED | left, history |
| 124 | R10 BUILD ACCEPTANCE | CLOSED | left, history |
| 129 | a refused init unloads the EA | CLOSED | left; ruling kept at `:2781` |
| 133 | the properties dialog is not a witness | CLOSED | left; ruling kept at `:2781` |
| 137 | zero enforcement while the terminal is not running | CLOSED | left; ruling kept at `:2913` |
| 142 | stale_anchor_reconstructed only exercised all zero | OPEN | kept, text C |
| 146 | DEFECT 2 | CLOSED | left, history |
| 152 | DEFECT 4 | CLOSED | left, history |
| 158 | P2-A | CLOSED | left, history |
| 164 | P2-H | CLOSED | left, history |
| 170 | the market closed distinction | CLOSED | left, history |
| 176 | maximum position size | CLOSED | left; ruling kept at `:2909` |
| 182 | the README token usage badge writer | CLOSED | left; ruling kept at `:2929` |
| 187 | P1-N gated on P1-L | CLOSED | left, history |
| 192 | machine sleep and the mutex | CLOSED | left, history |
| 197 | the broker server DST peg | OPEN | kept, text D |
| 202 | external reads of bases\gvariables.dat | OPEN | left, covered by the KEEP entry `:2331`, owner item 7 |
| 206 | NOTE, common.ini WebRequest allow list | OPEN (stale) | left; `:27` and `:31` close it at TG-W |
| 210 | a prior unrelated AccountGuardian implementation | OPEN | kept, text E |

## Git facts behind the history lines, read in this session

`git log --first-parent --merges --format='%h %ad %p | %s' --date=short ffa5186`:

```
85ff44e 2026-10-21 12d7df1 d1e7de0 | Merge branch 'build/telegram-alerts'
a6aa115 2026-09-30 fe161a5 eca0d4c | merge main into the readme branch, ledger union, ready for main fast-forward
dbc962f 2026-09-30 ea00089 b1261df | merge: installer console build into the readme branch, ledger union, owner rulings
daf8364 2026-09-01 8ff2e25 0da55d0 | merge: V1-A expiry banked, incidents recorded, instrument scope ruling FINAL
8ff2e25 2026-09-01 de8d9c3 c63e62a | merge: version 1 realized-peak trailing floor, accepted on V1-A..V1-D
de8d9c3 2026-08-27 b58caaf a2e0e9e | docs: rewrite README as a bilingual product-grade document with diagrams and roadmap
962d6fb 2026-08-26 e73874a 44ac449 | merge: phase 3 defect fixes, P3-1 P49 P53 closed and the D4 gate opened
e73874a 2026-08-25 dbb1705 d4e2869 | merge: evidence/manual-trades-20260811, P1-I and Q7 closures into main
c0f29a9 2026-08-24 4a84f70 9a9ab74 | merge: record version 1 realized peak ruling set D1-D8
4021519 2026-08-19 1ea7c2d 4c44fac | merge: Stage 7 ledger record of its own merge
1ea7c2d 2026-08-19 49ea967 6219dfe | merge: Phase 2 Stage 7, deploy and live acceptance
3ad7ef4 2026-08-18 06d92ee 35628f6 | merge: Phase 2 Stages 2 through 6, the lock semantics branch
cef9127 2026-08-17 c7170a8 c7030a4 | merge: Phase 2 kickoff ledger, the 2026-08-18 stale quote ruling and the banked investigation
c7170a8 2026-08-17 dd4727b 149536e | merge: ledger record of the housekeeping merge and the second push
dd4727b 2026-08-17 0babf84 1cb3c57 | merge: post Phase 1 housekeeping, README token block and ledger sync
0babf84 2026-08-17 ca27980 85671b5 | merge: ledger record of the Phase 1 merge and the outstanding push
112db9c 2026-08-17 1aa9a15 aedbc61 | merge: Phase 1 PnL core evidence branch into main, owner ordered
1aa9a15 2026-08-17 08f23cf 0eb13cf | chore: token usage badge [skip ci]
d52f063 2026-08-11 42ede70 c4d363f | Merge branch 'worktree-phase1-pnl-core'
937c604 2026-08-08 d0dabc5 461c415 | Merge branch 'worktree-a9-phantom-audit'
c111787 2026-08-05 1aa216f 5a1772a | merge: a10 transition conformance sweep and its two findings into main
28c29a4 2026-08-04 83f1bdb 3cdcec9 | merge: stage 5a crash-loop primitive, vectors and deploy into main
ce6964d 2026-08-03 d6e5fe8 3e18c48 | merge: phase 0 proven work into main before stage 5a touches the crash loop primitive
```

`git reflog show --date=iso main`, the source of every fast forward named in the history:

```
ffa5186 main@{2026-10-21 20:07:40 +0300}: merge build/telegram-alerts-pnl: Fast-forward
2acbe38 main@{2026-10-21 18:49:27 +0300}: merge build/telegram-alerts-format: Fast-forward
85ff44e main@{2026-10-21 16:24:42 +0300}: commit (merge): Merge branch 'build/telegram-alerts'
12d7df1 main@{2026-10-21 16:23:19 +0300}: merge worktree-ledger-poll-counter-issue: Fast-forward
31ac695 main@{2026-10-02 12:50:13 +0300}: merge worktree-review-fix-build: Fast-forward
8b6862a main@{2026-10-01 15:04:37 +0300}: merge ledger-owner-rulings-2026-10-01: Fast-forward
1ce2530 main@{2026-10-01 02:41:05 +0300}: merge worktree-ledger-rulings-20261001: Fast-forward
a6aa115 main@{2026-10-01 00:26:05 +0300}: merge worktree-readme-hebrew-20260930: Fast-forward
eca0d4c main@{2026-09-29 13:55:29 +0300}: merge worktree-pk-build-20260928: Fast-forward
1b21c2a main@{2026-09-29 13:05:16 +0300}: merge worktree-installer-plan-20260928: Fast-forward
2be5606 main@{2026-09-28 16:52:11 +0300}: merge worktree-pk-build-20260928: Fast-forward
5ee880a main@{2026-09-28 16:02:04 +0300}: merge worktree-peak-witness-ruling-20260928: Fast-forward
8a15c6e main@{2026-09-28 13:51:20 +0300}: merge worktree-peak-witness-plan-20260928: Fast-forward
6c82281 main@{2026-09-28 12:48:31 +0300}: merge worktree-enf31-build-20260928: Fast-forward
b235108 main@{2026-09-28 08:12:06 +0300}: merge worktree-enforcement-lock-two-20260925: Fast-forward
442391a main@{2026-09-25 17:44:46 +0300}: merge worktree-enforcement-lock-two-20260925: Fast-forward
6820301 main@{2026-09-23 17:25:08 +0300}: merge worktree-enforcement-build-20260916: Fast-forward
7a45e93 main@{2026-09-16 21:16:42 +0300}: merge worktree-enforcement-build-20260916: Fast-forward
a6e77d2 main@{2026-09-16 14:48:57 +0300}: merge worktree-enforcement-ruling-20260916b: Fast-forward
973179d main@{2026-09-16 13:49:33 +0300}: merge worktree-enforcement-plan-20260916: Fast-forward
6a44dba main@{2026-09-15 23:13:22 +0300}: merge worktree-d2d4-build: Fast-forward
f717261 main@{2026-09-10 16:00:34 +0300}: merge worktree-d2d4-build: Fast-forward
c4d7706 main@{2026-09-09 19:15:25 +0300}: merge worktree-d2d4-ruling: Fast-forward
dfe17b0 main@{2026-09-09 01:51:08 +0300}: merge worktree-d2d4-plan-20260908: Fast-forward
bd61a0f main@{2026-09-08 02:43:42 +0300}: merge worktree-r10-acceptance-session2-20260908: Fast-forward
d88a71f main@{2026-09-07 15:20:47 +0300}: merge worktree-parsed-wishing-ritchie: Fast-forward
cb19144 main@{2026-09-07 14:43:21 +0300}: commit: ledger: R10 acceptance, seven of nine live rows closed, two deferred
67177ae main@{2026-09-06 17:45:07 +0300}: commit: ledger: 2026-09-06 deploy hand ruling FINAL, and scripts/deploy-r10.ps1
f33c509 main@{2026-09-03 23:28:43 +0300}: merge worktree-r10-build-20260903: Fast-forward
8db1501 main@{2026-09-03 18:14:11 +0300}: merge worktree-r10-build-20260903: Fast-forward
4f93013 main@{2026-09-03 13:47:28 +0300}: merge worktree-r10-plan-20260903: Fast-forward
00e2b43 main@{2026-09-03 03:43:03 +0300}: merge worktree-input-hardening-r10-20260903: Fast-forward
1d8b953 main@{2026-09-03 00:41:30 +0300}: merge g6-closure-20260903: Fast-forward
83c9d55 main@{2026-09-02 21:18:17 +0300}: merge ledger-hygiene-20260902: Fast-forward
daf8364 main@{2026-09-01 01:34:28 +0300}: merge 0da55d0: Merge made by the 'ort' strategy.
8ff2e25 main@{2026-09-01 01:26:51 +0300}: merge worktree-v1-realized-peak: Merge made by the 'ort' strategy.
de8d9c3 main@{2026-08-27 02:03:57 +0300}: merge worktree-readme-overhaul: Merge made by the 'ort' strategy.
b58caaf main@{2026-08-27 00:52:46 +0300}: commit: ledger: record the 2026-08-26/27 consolidation in ACTIONS
962d6fb main@{2026-08-26 23:28:45 +0300}: commit (merge): merge: phase 3 defect fixes, P3-1 P49 P53 closed and the D4 gate opened
e73874a main@{2026-08-25 23:27:49 +0300}: commit (merge): merge: evidence/manual-trades-20260811, P1-I and Q7 closures into main
dbb1705 main@{2026-08-25 23:22:01 +0300}: pull: Fast-forward
c0f29a9 main@{2026-08-24 13:28:03 +0300}: commit (amend): merge: record version 1 realized peak ruling set D1-D8
7dc38e7 main@{2026-08-24 13:19:16 +0300}: merge worktree-ledger-v1-peak-ruling: Merge made by the 'ort' strategy.
4a84f70 main@{2026-08-24 12:16:48 +0300}: commit: docs: bring README to Phase 2, drop stale no-trading-calls framing
d4efb3d main@{2026-08-23 18:11:19 +0000}: commit: docs: re-sync status page to the Notion roadmap (2026-08-23)
8e99778 main@{2026-08-19 12:39:10 +0300}: commit: ledger: record the Stage 7 push and the UNRULED main-checkout proposal
4021519 main@{2026-08-19 12:21:59 +0300}: merge worktree-phase2-stage7: Merge made by the 'ort' strategy.
1ea7c2d main@{2026-08-19 12:15:37 +0300}: merge worktree-phase2-stage7: Merge made by the 'ort' strategy.
49ea967 main@{2026-08-18 00:21:17 +0300}: commit: ledger: record the Phase 2 merge to main
3ad7ef4 main@{2026-08-18 00:20:02 +0300}: merge worktree-phase2-lock: Merge made by the 'ort' strategy.
06d92ee main@{2026-08-17 21:05:33 +0300}: commit: ledger: rule the floor-versus-clamp precedence, the floor wins
1c4118d main@{2026-08-17 20:59:15 +0300}: commit: ledger: rule Phase 2 questions THREE through SEVEN, only EIGHT remains
869a114 main@{2026-08-17 20:42:27 +0300}: commit: ledger: rule Phase 2 questions ONE and TWO, six remain
e7f5cae main@{2026-08-17 20:39:32 +0300}: commit: ledger: close the history exposure issue, the rewrite is done
```

The build label at each commit, read with `git show <commit>:MQL5/Experts/AccountGuardian/AccountGuardian.mq5`:

```
28c29a4: AgInfo("init|build=Phase0|account=" + (string)g_ag_login + "|server=" + AccountInfoString(ACCOUNT_SERVER));
d52f063: AgInfo("init|build=Phase1|account=" + (string)g_ag_login + "|server=" + AccountInfoString(ACCOUNT_SERVER));
112db9c: AgInfo("init|build=Phase1|account=" + (string)g_ag_login + "|server=" + AccountInfoString(ACCOUNT_SERVER));
3ad7ef4: AgInfo("init|build=Phase2|account=" + (string)g_ag_login + "|server=" + AccountInfoString(ACCOUNT_SERVER));
1ea7c2d: AgInfo("init|build=Phase2|account=" + (string)g_ag_login + "|server=" + AccountInfoString(ACCOUNT_SERVER));
962d6fb: AgInfo("init|build=Phase2|account=" + (string)g_ag_login + "|server=" + AccountInfoString(ACCOUNT_SERVER));
daf8364: AgInfo("init|build=Phase2|account=" + (string)g_ag_login + "|server=" + AccountInfoString(ACCOUNT_SERVER));
f33c509: AgInfo("init|build=R10|account=" + (string)g_ag_login + "|server=" + AccountInfoString(ACCOUNT_SERVER));
6a44dba: AgInfo("init|build=D2D4|account=" + (string)g_ag_login + "|server=" + AccountInfoString(ACCOUNT_SERVER));
6820301: AgInfo("init|build=ENF|account=" + (string)g_ag_login + "|server=" + AccountInfoString(ACCOUNT_SERVER));
6c82281: AgInfo("init|build=ENF31|account=" + (string)g_ag_login + "|server=" + AccountInfoString(ACCOUNT_SERVER));
2be5606: AgInfo("init|build=PK|account=" + (string)g_ag_login + "|server=" + AccountInfoString(ACCOUNT_SERVER));
31ac695: AgInfo("init|build=PK|account=" + (string)g_ag_login + "|server=" + AccountInfoString(ACCOUNT_SERVER));
85ff44e: #define AG_BUILD_LABEL "TG"
2acbe38: #define AG_BUILD_LABEL "TG"
ffa5186: #define AG_BUILD_LABEL "TG"
```

## Notes

* Kept entries stand byte for byte. Their relative references ("above", "below", "directly below") and their ledger line citations with no commit name positions at `ffa5186` and resolve against git history. Two amendments stand directly after the entries they amend, `:2750` after `:2746` and `:2829` after `:2825`, as the owner's item 1 requires, and the Q8 and Q10 amendments stand directly above the entries they amend, `:2701` over `:2706` and `:2714` over `:2718`, as their own text reads.
* The entry at `:2937` keeps its bare use of the word the naming discipline at `:2542` rules out, by the owner's item 8; the proof reports it as the one known exception and finds no other.
* The deleted entry at `:2495` is counted as superseded: the owner's item 4 names the shipped code as its answer, and no DECISIONS entry supersedes it.

## The proof script's output

`python -I scripts/rows/ledger_compaction.py`, exit code 0:

```
PASS base entries | DECISIONS at ffa5186 holds 202 entries, 202 carry a class, each exactly one
PASS utf-8 | 127072 bytes decode, 0 characters outside ASCII
PASS cr equals lf | CR 600, LF 600, CRLF 600, last line ends CRLF
PASS no em or en dash | U+2014 0, U+2013 0
PASS sections | # LEDGER then ## ISSUES then ## ACTIONS then ## DECISIONS then ## PROJECT
PASS issues | 6 entries, 6 approved, 6 equal in order
PASS compaction entry | 1377 characters
PASS keep entries | 154 of 154 stand once, byte for byte, Reason lines dropped
PASS amendment 2750 | directly after 2746, the entry it amends
PASS amendment 2829 | directly after 2825, the entry it amends
PASS deleted entries | 48 of 48 Decision lines absent
PASS reason lines | 0 Reason lines in DECISIONS
PASS decision count | 156 Status lines, 154 KEEP entries plus C1 and C2
PASS c1 and c2 | the last two entries of DECISIONS, FINAL
  heartbeat at line 105: quoted as the word itself, the naming rule
  heartbeat at line 105: qualified, Mutex heartbeat
  heartbeat at line 105: qualified, Network heartbeat
  heartbeat at line 395: qualified, mutex heartbeat
  heartbeat at line 481: bare
  heartbeat at line 503: qualified, mutex heartbeat
  heartbeat at line 509: qualified, network heartbeat
  heartbeat at line 509: qualified, network heartbeat
PASS naming exception | 1 bare use, inside the entry of 2937 at ffa5186, the one known exception
PASS project | 8 lines
final classes: KEEP 154, deleted one-time 35, deleted superseded 13, total 202
before: LEDGER.md at ffa5186, 1216668 bytes as git stores it (LF), 1219747 bytes and 3079 lines on disk with CRLF
after: LEDGER.md on disk, 127072 bytes and 600 lines
checks 16, pass 16, fail 0
```

