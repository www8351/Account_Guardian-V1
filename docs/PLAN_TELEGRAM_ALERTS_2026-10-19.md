# AccountGuardian: Telegram alerts, plan and ruling sheet TG

Date of the request: 2026-10-19. Written: 2026-10-20. Plan only. This document authorizes no code, no build, no deploy and no change under any MetaTrader terminal data folder. Every TG item is OPEN except TG-6, which carries the owner's answer given in chat on 2026-10-20 and recorded as the owner's statement, not as a ruling.

Branch `plan/telegram-alerts`, cut from main at `31ac695` ("ledger: review fix build accepted by owner attestation"). LEDGER.md was read in full before any other step, 2824 lines, md5 `9A04F39AD5DA11FC4FF2934E250D7E56`, equal in the main checkout and in this branch's worktree.

## 1. The request and the owner's statements

### 1.1 The request, as recorded in ISSUES

"Telegram alerts on account and guardian state: guardian active or not, account locked, no internet, or any other state. Alert text summarized in Hebrew."

### 1.2 What stopped the first pass, and the owner's answer

The first pass stopped before any write on the FINAL at `LEDGER.md:2431-2433`, quoted whole:

> Decision: (owner note 2026-07-29) The external healthchecks.io dead-man check belonging to the deleted prior project has been deleted by the owner. When the deferred visibility phase opens, provision a fresh check with a new UUID. The old UUID is never reused.
> Reason: No network path exists in v0, so there is no impact now; reusing a retired dead-man UUID would silence or misattribute alerts later.
> Status: FINAL

`docs/SPEC_v0.1.md:10` defers "network visibility (network heartbeat, events, dead-man drill)", and Telegram alerts are the "events" of that phase, so this work opens it. The task's watcher options "none" and "owner hosted watcher" ran against that FINAL. The owner answered in chat on 2026-10-20: proceed; S13 follows the FINAL, a fresh hosted dead man check with a new UUID, the old UUID never reused; the item's only open questions are the provisioning details, the network heartbeat interval and the silence threshold; the options "none" and "owner hosted watcher" are withdrawn.

### 1.3 Owner statements in chat, 2026-10-20, not verified by the executor

Recorded as given. No command of this session read or could read the computers they describe.

1. The live account does not run on the computer this session runs on (hostname `www8351`). It runs on a different computer, which this session cannot read or verify. Every step on that computer is the owner's, written below as dictation, and its evidence is output the owner pastes back.
2. On the live computer's terminal, the WebRequest allow list now holds exactly `https://api.telegram.org` and `https://hc-ping.com` and nothing else. The prior project's URLs were removed.
3. The owner created a new bot token in BotFather and holds the chat id. The executor never asks for either value.
4. Token and chat id location, the owner's answer: "EA input fields, entered by the owner in the attach dialog."

### 1.4 What LEDGER says about the guardian's computers, quoted

The owner asked for these quotes and asked that the live computer's hostname not be inferred. None is inferred here.

- `LEDGER.md:2794`, DECISIONS: "No VPS. A dedicated computer runs the guardian. This supersedes R8."
- `LEDGER.md:110`: "UPDATED 2026-10-01, OWNER RULING (4) OF 2026-10-01, FINAL in DECISIONS (end of section), ACTIONS entry of this date: no VPS; a dedicated computer runs the guardian; this supersedes R8, the owner direction of 2026-09-02 this entry's Action line names."
- `LEDGER.md:2754`, DECISIONS: "The identity of the new computer rests on the owner's statement and on hostname DESKTOP-PF23NA8."
- `LEDGER.md:267`: "The identity of the new computer rests on the owner's statement and on hostname DESKTOP-PF23NA8, per ruling (3) of this date."
- `LEDGER.md:245`: "The new computer's MT5 data folder carries the ID `D0E8209F77C8CF37AD8BF550E51FF075`, the owner's statement, the same ID IN-26 names for the development terminal." and "So the ID derives from the install path, and on the new computer it names a different terminal on a different computer, so IN-26 was not touched."
- `LEDGER.md:243`: "All rows ran on the new computer." and "The owner removed AccountGuardian from the chart on the development computer, so it runs on demo account 1200252169 on the new computer only."
- How a build reaches the new computer, `LEDGER.md:7`: "The owner exported from `b1a4c17`, "EXPORT PASSED", 18 files, manifest 10 of 10, secrecy 0; copied the export into the release repository, where `git status` listed exactly three modified files, `AccountGuardian.mq5`, `Sweep.mqh` and `installer/manifest.txt`; committed `72dbe84` and pushed it. IN-D and RC-1 then ran on the new computer from that release and passed." And `LEDGER.md:243`: "IN-D ran from the release ZIP of `e784d2a`, whose installer and source blobs equal those at `1ab2541`."
- `LEDGER.md:2802`, DECISIONS: "The LIVE HAZARD of last-used inputs off the ruled defaults is closed. The new computer's Experts journal reads `limits accepted|percent=5.50|currency=200.00`, the values the owner set."
- Account 2003092066: LEDGER.md on main records it nowhere, zero matches. The unmerged branch `worktree-ledger-poll-counter-issue` (`12d7df1`) records a live observation on account 2002830054, JustMarkets-Live, a different number. Nothing here links either number to a computer.

## 2. FINAL decisions this plan follows

Every FINAL in LEDGER was read. These bind the design. None is reopened, and no TG item below offers an option against any of them.

| FINAL | Location | What it requires of this work |
|---|---|---|
| healthchecks.io check, owner note 2026-07-29 | `LEDGER.md:2431` | S13 is a fresh hosted dead man check with a new UUID; the old UUID is never reused |
| Naming discipline 2026-07-29 | `LEDGER.md:2423` | "network heartbeat" for the dead man ping, "mutex heartbeat" for `AG_HB_<login>`, never the bare word in LEDGER or SPEC; this plan follows the same rule |
| Telegram token 2026-10-01 | `LEDGER.md:2814` | creating or rotating a token belongs to this work |
| Q3/F2 trade disallowed states 2026-07-29 | `LEDGER.md:2387` | Telegram is an added channel; journal, Alert and chart banner alerting stay exactly as they are |
| Q4/F9 config classes | `LEDGER.md:2391` | the Telegram settings are optional class: malformed means the feature off plus WARN, never a refused init |
| F13 timer architecture | `LEDGER.md:2419` | every send runs from OnTimer; OnTradeTransaction stays acceleration only |
| AG_MUTEX_STALE_SECONDS = 10, a constant | `LEDGER.md:2460` | a blocking call inside OnTimer must stay far below 10 s, or a second instance may take the mutex |
| AG_LIFE_INTERVAL_SECONDS = 30, a constant | `LEDGER.md:2456` | timing values of this work are compile-time constants, not inputs, on the same precedent |
| Q9 one pass deferral, stale quote ruling | `LEDGER.md:2591`, `:2320` | nothing in this work may delay, suppress or gate a breach decision |
| Q6/F7, Q7, D1f, hardening before COMPLETE | `LEDGER.md:2399`, `:2403`, `:2603`, `:2181` | no inbound path may unlock, widen a limit or disable the guardian |
| SPEC section 6 | `docs/SPEC_v0.1.md:137` | "No secrets, no credentials, ever" in anything the EA writes |
| Never loaded, never written | `LEDGER.md:2464` | applied by choice to any queue file this work adds |
| Branch plan 2026-09-23 | `LEDGER.md:2698` | every item runs on its own branch cut from main and merges on its own proven work |
| Remote state 2026-08-04 | `LEDGER.md:2546` | no ledger text asserts a remote position; the executor never pushes |
| RULE A and RULE B, 2026-08-17; dictation 2026-08-18; deploy hand 2026-09-06; IN-26 | `LEDGER.md:2356`, `:2300`, `:2658`, `:2714` | the executor never writes under a terminal data folder; every terminal step is the owner's, dictated with source, destination and md5 |
| Phase 4 weekly banner 2026-07-30 | `LEDGER.md:2500` | if any weekly figure is ever sent, it is the raw weekly figure only |
| Standing rule 7 | `LEDGER.md:2214` | an ex5 md5 is recorded with the build label and is not build identity |

## 3. Code survey (read only, main at `31ac695`)

### 3.1 What the EA knows today

Sources: `MQL5/Experts/AccountGuardian/AccountGuardian.mq5` (EA), `MQL5/Include/AccountGuardian/*.mqh`. "Send" says whether a WebRequest at that moment could deliver: yes, no, or only after recovery.

| # | State or event | Where | Journal line today | Detect | Send at that moment | Why |
|---|---|---|---|---|---|---|
| 1 | Init start, build label | EA:1052 | `init\|build=PK\|account=..\|server=..` | yes | only after recovery | OnInit runs before the timer; sending here would hold init; queue for the first OnTimer |
| 2 | Core config refused | EA:1059-1063, AgRefuseInit EA:1018-1025 | `ALERT\|refusing to run, core config invalid: ..` | yes | only after recovery | OnInit returns INIT_PARAMETERS_INCORRECT, the platform removes the EA (LEDGER `:100`); no OnTimer ever runs; WebRequest inside OnInit is UNKNOWN |
| 3 | Limits accepted | EA:1064-1067 | `limits accepted\|percent=..\|currency=..\|raw=..` | yes | only after recovery | same as row 1 |
| 4 | Optional config invalid | EA:1071-1075 | `WARN\|optional config invalid: ..` | yes | only after recovery | same as row 1 |
| 5 | Duplicate instance refused | EA:1078-1083, Persist.mqh:1227-1236 | `ALERT\|refusing to run: another AccountGuardian instance is live ..` | yes | only after recovery, and only by the refused instance | the live instance keeps running and is unaware |
| 6 | Stale mutex takeover, the previous instance died | Persist.mqh:1235 | `WARN\|stale mutex heartbeat (<n>s), taking over crashed-instance mutex` | yes, with the downtime in seconds | only after recovery | proves the prior session ended without OnDeinit (LEDGER `:1624`) |
| 7 | State, floor, peak file loaded or quarantined | EA:1098-1162 | `lock state file loaded ..`, `WARN\|.. quarantined ..` | yes | only after recovery | OnInit |
| 8 | Manual resume from SAFE_HALT | EA:1164-1172 | `RESUMED_FROM_SAFE_HALT\|..` | yes | only after recovery, on the first tick | OnInit |
| 9 | SAFE_HALT persisted across restart | EA:1174-1185 | `TRANSITION\|..->SAFE_HALT\|halt flag persisted ..`, ALERT | yes | yes, from OnTimer | init succeeds and the timer runs; OnTimer returns at EA:1296 after the liveness journal line |
| 10 | Crash loop guard trips | EA:1187-1198, AgEnterSafeHalt EA:1031-1042 | `TRANSITION\|..->SAFE_HALT\|crash loop: ..`, ALERT | yes | yes, from OnTimer | as row 9 |
| 11 | Crash loop chain | EA:1199 | `DEBUG\|crash-loop check\|chain=..` | yes | not needed | DEBUG only at Verbose |
| 12 | Boot into SYNCING | EA:1202 | `TRANSITION\|BOOT->SYNCING\|boot\|weekly=..\|timer=1s` | yes | yes, from OnTimer | first tick follows within 1 s |
| 13 | Timer failed to arm | EA:141-149 | `ALERT\|EventSetTimer FAILED ..` | yes | no | no OnTimer will ever run; only the network heartbeat silence reveals it |
| 14 | SYNCING exit to ACTIVE | EA:1332 | `TRANSITION\|SYNCING->ACTIVE\|history stable\|polls=3/3` | yes | yes | OnTimer |
| 15 | Boot derivation not evaluable | EA:363, EA:370 | `WARN\|boot derivation NOT EVALUABLE ..` | yes | yes | stays SYNCING and retries |
| 16 | Lock found at boot: FILE, GV, DERIVED, SWEEP, PEAK witnesses | EA:319, :332, :420, :444, :465 | `boot witness <W> fired\|..` | yes | yes, after the first sweep pass | OnTimer, SYNCING dispatch EA:1319-1328 |
| 17 | Lock entered from boot, reason DAILY_BREACH, SWEEP_WITNESS or CORRUPT_STATE | AgEnterLockFromBoot EA:577-633 | `TRANSITION\|SYNCING->LOCKED\|boot derivation: <reason>`, ALERT `LOCKED at boot by derivation ..` | yes | yes | OnTimer |
| 18 | Disconnected while ACTIVE | EA:794-804 | LIFE `waiting_on=DEGRADED: disconnected, no breach decisions\|DEGRADED` | yes, every tick | no while disconnected; yes after | the broker link is down, the internet usually with it |
| 19 | RESYNC entered and exited | EA:1363-1371 | `RESYNC entered\|..`, `RESYNC exited\|..` | yes | yes | OnTimer |
| 20 | Connection sample, every state | EA:1282 | DEGRADED marker on SYNCING and LOCKED LIFE lines | yes | after recovery | the start of the gap is known, the duration at reconnect |
| 21 | Anchor jump over one day | EA:836-850 | INFO and capped ALERT `anchor jump accepted: ..` | yes | yes | OnTimer |
| 22 | Day rollover | EA:857-868 | `day rollover\|old_anchor=..\|new_anchor=..\|jump=..` | yes | yes | OnTimer, ACTIVE only |
| 23 | History read failed | Pnl.mqh:148, :309, :522 | `WARN\|HistorySelect failed ..` | yes | yes | the ACTIVE pass returns without a breach decision |
| 24 | Lock level, every LIFE cadence and at a breach | EA:945-1007 | `lock level\|enforced_limit=..\|peak=..\|ratchet_level=..\|peak_level=..\|chosen=..\|pnl=..` | yes | yes | carries what S9 needs |
| 25 | Ratchet holding against a raised limit | Persist.mqh:839 | `WARN\|ratchet HOLDING against a raised limit (question SEVEN): ..` | yes | yes | at the cadence cap |
| 26 | Breach deferred one pass | EA:962 | `WARN\|breach deferred one pass: ..` | yes | not sent | one pass, then the lock or nothing |
| 27 | Lock declared, daily loss | AgDeclareLock EA:503-543 | `breach arithmetic\|..`, `lock bounds\|..`, `TRANSITION\|ACTIVE->LOCKED\|DAILY_BREACH\|..`, ALERT `DAILY_BREACH: account LOCKED until ..` | yes, with which mechanism set the level (`chosen`) and both legs | yes, after the sweep's first pass | the sweep runs from the next LOCKED tick (EA:1342-1351) |
| 28 | Which limit: percent leg or currency leg | Pnl.mqh:491-501 | not printed today; derivable from base, percent and currency | yes | yes | min of the two legs |
| 29 | State file not written at the lock | EA:517 | `ALERT\|LOCK DECLARED BUT THE STATE FILE WAS NOT WRITTEN ..` | yes | yes | OnTimer |
| 30 | Input changed while LOCKED, ignored | EA:668-684 | `WARN\|input changed while LOCKED and is being IGNORED (Q6): ..` | yes | yes | cadence capped |
| 31 | Lock expiry at the day anchor | AgEvaluateLocked EA:686-725 | `lock expired\|..`, `TRANSITION\|LOCKED->SYNCING\|lock expired\|..` | yes | yes | OnTimer; the outcome is known at the SYNCING exit, ACTIVE (EA:1332) or locked again (EA:1327) |
| 32 | Sweep pass result | Sweep.mqh:631-635, :695-696 | `sweep close\|..\|retcode=..\|class=..\|attempt=..`, `sweep delete\|..`, `sweep pass\|positions=..\|pendings=..\|held=..\|sent=..` | yes | yes, on a tick that sent nothing | one synchronous OrderSend per pass (Sweep.mqh:605) |
| 33 | Flatten episode complete | Sweep.mqh:698-706 | `sweep complete\|positions=0\|pendings=0\|attempts=..\|elapsed=..` | yes | yes | OnTimer |
| 34 | Ticket held, CANNOT_FLATTEN | AgSweepHold Sweep.mqh:310-328 | `sweep held\|..`, ALERT `CANNOT_FLATTEN: ..` | yes | yes | first hold only |
| 35 | Held ticket finally flattened | Sweep.mqh:646-651 | ALERT `flattened after hold: ..` | yes | yes | OnTimer |
| 36 | Trade opened while LOCKED | OnTradeTransaction EA:1388-1404 | `sweep accelerated\|transaction=DEAL_ADD\|deal=..` then `sweep close\|..` | yes | yes, after the close | the accelerator runs one pass at once |
| 37 | Trading blocked while LOCKED, and restored | Sweep.mqh:451-474, reads Sweep.mqh:176-183 | `sweep blocked\|state=<name>`, ALERT `CANNOT_TRADE while LOCKED: ..`, ALERT `trading restored while LOCKED: ..` | yes, LOCKED only today | yes | the four permission reads exist only inside the sweep |
| 38 | Sweep resumed after a gap | Sweep.mqh:363-377 | `sweep resumed\|gap=<t1>..<t2>` | yes | yes | OnTimer |
| 39 | Mutex overwritten by another instance | Persist.mqh:1268-1272 | ALERT `instance mutex overwritten by another instance ..` | yes | yes | OnTimer |
| 40 | State write failure, any lock or halt file | Persist.mqh:123, :131; EA:1035, :1190 | ALERT `state-write failure: ..` | yes | yes | OnTimer, or after recovery when it happens in OnInit |
| 41 | Deinit, every reason | OnDeinit EA:1415-1445 | `deinit\|reason=<n>\|session marked clean\|timer_armed=..\|timer_ticks=..` | yes | UNKNOWN, see 3.2 | OnDeinit is time limited and the reason decides what follows |
| 42 | Hard kill, crash, power loss, sleep | none | no line at all; the next start shows row 6 | no | no | no code runs; the network heartbeat silence reveals it |

Reads of the named platform flags, complete:

| Flag | Where read | When |
|---|---|---|
| TERMINAL_CONNECTED | EA:794 (ACTIVE gate), EA:1282 (every tick), Pnl.mqh:513 (stability poll), Sweep.mqh:363 (every sweep pass) | every tick |
| TERMINAL_TRADE_ALLOWED, MQL_TRADE_ALLOWED, ACCOUNT_TRADE_ALLOWED, ACCOUNT_TRADE_EXPERT | Sweep.mqh:178-181 inside AgTradeAllowed, named by SweepPolicy.mqh:327-338 | only inside a LOCKED sweep pass |
| WebRequest, SendNotification, SendMail | nowhere | the EA has no network path today, as SPEC section 0 says |

Other facts the design rests on, measured this session:
- AgTransition (State.mqh:77-83) is the single choke point for every transition, so one hook there sees every state change.
- AgAtomicWrite (Persist.mqh:112-135) opens its file with FILE_ANSI (Persist.mqh:120); Hebrew text cannot pass through it.
- The mutex heartbeat is refreshed once per tick, first thing in OnTimer (EA:1219-1220).
- Source encodings: AccountGuardian.mq5 starts with the UTF-8 byte order mark `EF BB BF`; the seven includes and both vector scripts carry none; every source file has zero bytes above 127 after its mark.
- Weekly measurement does not exist yet: `WeeklyReportEnabled` reaches only the boot transition line (EA:1070, EA:1202).
- No on-demand lock exists on main: a grep of `MQL5/` for `on.?demand|OnChartEvent|OBJ_BUTTON|CHARTEVENT` returns zero lines.

### 3.2 OnDeinit by reason code

Reason codes from the MQL5 reference (REASON_* constants). Observed in this ledger: 1, 3, 5, 6, 8 and 9.

| Code | Constant | Meaning | What follows | WebRequest inside OnDeinit |
|---|---|---|---|---|
| 0 | REASON_PROGRAM | ExpertRemove called | the EA never calls it | UNKNOWN, to be verified at acceptance |
| 1 | REASON_REMOVE | removed from the chart | no guardian until re-attached | UNKNOWN, to be verified at acceptance |
| 2 | REASON_RECOMPILE | recompiled | a fresh init within seconds (LEDGER `:1550`) | UNKNOWN, to be verified at acceptance |
| 3 | REASON_CHARTCHANGE | symbol or period changed | an in-place init within seconds | UNKNOWN, to be verified at acceptance |
| 4 | REASON_CHARTCLOSE | chart closed | no guardian until re-attached | UNKNOWN, to be verified at acceptance |
| 5 | REASON_PARAMETERS | inputs changed | an in-place init within seconds | UNKNOWN, to be verified at acceptance |
| 6 | REASON_ACCOUNT | another account activated, or a reconnect after an account settings change | an init follows; the connection is in transition | UNKNOWN, to be verified at acceptance |
| 7 | REASON_TEMPLATE | template applied | depends on whether the template carries the EA | UNKNOWN, to be verified at acceptance |
| 8 | REASON_INITFAILED | OnInit returned non zero | the platform removes the EA | UNKNOWN, to be verified at acceptance |
| 9 | REASON_CLOSE | terminal closed | no guardian until the terminal starts | UNKNOWN, to be verified at acceptance; the network may already be closing |
| none | hard kill, crash, power loss | OnDeinit does not run (LEDGER `:1594`, `:1626`, `:2060`) | the next start shows the stale mutex takeover | not possible |

The MQL5 reference limits OnDeinit to 2.5 seconds, after which the program is terminated. Recalled from the reference, not fetched this session, and confirmed or corrected at acceptance. Whatever TG-13 rules, local writes (the halt clean mark, the mutex release, the queue file) come before any send, so a forced termination loses at most the send.

### 3.3 Platform and service facts, recalled and not fetched

No network call is authorized in this session. Each fact below comes from the vendor's documentation as the executor knows it. Each is to be confirmed by the owner at provisioning or measured at acceptance. Where the executor is not sure, the fact is marked UNKNOWN.

1. MQL5 WebRequest is synchronous. It holds the calling program until the reply arrives or the timeout runs out. It is not available in indicators and does not run in the Strategy Tester.
2. Every URL must be on the terminal's allow list (Tools, Options, Expert Advisors, "Allow WebRequest for listed URL"). A URL not on the list returns -1 with error 4014.
3. WebRequest returns the HTTP status code, or -1 with GetLastError 5200 to 5203 (invalid address, connect failed, timeout, request failed).
4. The timeout argument is in milliseconds. Whether it also bounds name resolution and the TLS handshake: UNKNOWN, measured by row TG-M.
5. WebRequest inside OnInit is not documented as forbidden. Whether it completes during a terminal start: UNKNOWN.
6. An MQL5 Service program can call WebRequest. UNKNOWN until measured.
7. MQL5 handles a program's events one at a time, so an OnTradeTransaction event waits while OnTimer is inside a WebRequest.
8. Telegram Bot API sendMessage is POST `https://api.telegram.org/bot<token>/sendMessage`. The token is part of the URL path; the chat id goes in the body. A message holds up to 4096 characters. The guidance is about one message per second per chat. Excess is answered with HTTP 429 carrying `parameters.retry_after`.
9. Healthchecks.io: a check is pinged at `https://hc-ping.com/<uuid>`, with a period and a grace time set per check. When the grace runs out after a missed period, the service sends a "down" notification, and an "up" notification when pings resume. It offers a Telegram integration delivered by the service's own bot. Its notification text is the service's own English template, carrying the check name the owner chooses. Plan limits and prices at today's date: UNKNOWN, read by the owner at provisioning.

The owner asked whether the dead man service's own Telegram integration delivers the S13 alert, so that S13 needs no code beyond the network heartbeat ping. Answer, from fact 9: yes. With that integration, the EA's only S13 code is the ping.

Two consequences follow, stated so they are not discovered later:
- The S13 message arrives from the service's bot, not from the owner's bot.
- Its text is the service's English template, not the fixed Hebrew format of section 5. The check name can be Hebrew with digits, and it appears inside that template.

## 4. State catalog

Classes: LIVE (the EA sends live), AFTER (the EA queues and sends after recovery), WATCHER (needs the off-machine watcher), NONE (not possible).

| Row | State | Class | Source rows in 3.1 | Note |
|---|---|---|---|---|
| S1 | Guardian started: build label, account, limits, current floor, lock state | LIVE | 1, 3, 12, 14 | sent at the SYNCING exit so the floor and lock state are known; an in-place re-init within 60 s merges with S2 into one "restarted" message |
| S2 | Guardian stopped, deinit reason in plain Hebrew | AFTER, and WATCHER if it never restarts | 41 | live only if TG-13 rules a send in OnDeinit and acceptance proves it |
| S3 | Init failed or crash loop guard tripped | AFTER for a refused init (rows 2, 5); LIVE for SAFE_HALT (rows 9, 10); WATCHER for a timer that never armed (row 13) | 2, 5, 9, 10, 13 | a refused init leaves no guardian across the next restart (LEDGER `:100`) |
| S4 | Locked by a daily loss limit: which limit, threshold, value at lock | LIVE | 24, 27, 28 | sent on the first tick after the lock on which the sweep sent nothing |
| S5 | Locked on demand | NONE | none | not on main |
| S6 | Enforcement result: closed, deleted, failed, retry count | LIVE | 32, 33, 34, 35 | at `sweep complete`, at the first hold of a ticket, and when a held ticket closes |
| S7 | Trade opened while locked and swept | LIVE | 36, 32 | after its close |
| S8 | Lock released at the new server day | LIVE | 31, 14, 17 | at the SYNCING exit after expiry, saying whether it stayed released or locked again (question FIVE's held loser) |
| S9 | Approaching a limit | LIVE | 24 | new comparison, notification only, levels in TG-3 |
| S10 | Broker connection lost and restored, with duration | AFTER | 18, 19, 20, 38 | sent at reconnect with the gap; gaps under 30 s are not sent |
| S11 | Telegram unreachable, backlog sent on recovery | AFTER | new | the notice opens the backlog |
| S12 | Algorithmic trading disabled at any level | LIVE | 37, new reads | the four reads are added to every tick in every state; LOCKED keeps its own sweep lines and popups unchanged |
| S13 | Guardian silent: computer off, terminal killed, EA hung, internet down | WATCHER | 13, 42 | the hosted dead man check of the FINAL at `LEDGER.md:2431`, fed by the network heartbeat ping |
| S14 | End of day summary | LIVE if ruled | 22, 31 | TG-4 |
| S15 | Manual resume from SAFE_HALT | LIVE | 8 | first tick |
| S16 | Lock restored or found at boot, including CORRUPT_STATE | LIVE | 16, 17, 7 | after the first sweep pass |
| S17 | Persistence failure: a lock, halt, floor or peak file not written or quarantined | LIVE, or AFTER when it happens in OnInit | 7, 29, 40 | one message per file per day |
| S18 | Previous session ended without a clean stop | AFTER | 6 | the stale mutex takeover gives the downtime in seconds |
| S19 | Limit change refused: input changed while LOCKED, or a raise held by the ratchet | LIVE | 25, 30 | once per lock or per day |
| S20 | Server clock jumped more than one day | LIVE | 21 | capped like its ALERT |
| S21 | History read failure, or boot derivation not evaluable | LIVE | 15, 23 | once per 300 s while it lasts |
| S22 | Guardian not protecting yet: SYNCING longer than 300 s | LIVE when the internet is up | 12, 14, 20 | new threshold, a compile-time constant |
| S23 | Telegram settings invalid | NONE | 4 | journal WARN only; the network heartbeat still runs if its own setting is valid |
| S24 | Another instance overwrote the mutex | LIVE | 39 | |

## 5. Hebrew message drafts

Fixed format, every message:
- Line 1: one status emoji and a short Hebrew headline.
- Then the account number, server time, balance, equity, today's loss against the limit, and the guardian's state.
- Event lines follow.
- The last line is the build label.

The drafts carry example values, not placeholders, so every Hebrew line stays Hebrew and digits. The example account is the demo account 1200252169, which the FINAL of 2026-09-02 (`LEDGER.md:2172`) rules not a secret. The build label `TG` is an example; the build instruction names the real label. A symbol name sits alone on its own line, never inside a Hebrew sentence. The block is plain text for the owner to edit. Its `===` lines are English labels for the owner and are never sent.

```text
=== S1 start ===
🟢 השומר הופעל ומגן על החשבון
חשבון: 1200252169
שעת שרת: 2026.10.19 09:00:03
יתרה: 2172.06
הון: 2172.06
רווח היום: 0.00 מול מגבלת הפסד של 126.21
מצב השומר: פעיל
מגבלה באחוזים: 5.50 אחוז מהיתרה בתחילת היום
מגבלה בסכום קבוע: 200
המגבלה שבתוקף כעת: 126.21
נעילה: אין
build=TG

=== S1 restarted in place ===
🟢 השומר הופעל מחדש
חשבון: 1200252169
שעת שרת: 2026.10.19 11:42:10
יתרה: 2172.06
הון: 2172.06
רווח היום: 0.00 מול מגבלת הפסד של 126.21
מצב השומר: פעיל
סיבת ההפעלה מחדש: הגדרות השומר שונו
המגבלה שבתוקף כעת: 126.21
נעילה: אין
build=TG

=== S2 stop ===
🔴 השומר הפסיק לפעול
חשבון: 1200252169
שעת שרת: 2026.10.19 18:00:00
יתרה: 2217.06
הון: 2217.06
רווח היום: 45.00 מול מגבלת הפסד של 126.21
מצב השומר: לא פועל
סיבה: השומר הוסר מהגרף
השומר אינו מגן על החשבון עד שיופעל שוב
build=TG

=== S2 reason wordings ===
סיבה: השומר עצר את עצמו
סיבה: השומר הוסר מהגרף
סיבה: השומר נבנה מחדש
סיבה: סמל הגרף או מסגרת הזמן שלו שונו
סיבה: הגרף נסגר
סיבה: הגדרות השומר שונו
סיבה: החשבון בטרמינל הוחלף או שהחיבור אליו אותחל
סיבה: הוחלה תבנית על הגרף
סיבה: ההפעלה נכשלה
סיבה: הטרמינל נסגר

=== delay line, for any message sent late ===
נשלחה באיחור של 125 שניות

=== guardian state wordings ===
מצב השומר: פעיל
מצב השומר: נעול
מצב השומר: בסנכרון
מצב השומר: עצירת בטיחות
מצב השומר: לא פועל

=== result not computed yet ===
הפסד היום: עדיין לא חושב

=== S3 refused start ===
⛔ השומר סירב לפעול
חשבון: 1200252169
שעת שרת: 2026.09.07 13:19:28
יתרה: 2294.76
הון: 2294.76
הפסד היום: עדיין לא חושב
מצב השומר: לא פועל
סיבה: ערך המגבלה היומית אינו מהרשימה המותרת
השומר אינו מגן על החשבון עד שההגדרה תתוקן והשומר יוצמד מחדש
נשלחה באיחור של 300 שניות
build=TG

=== S3 second instance refused ===
⛔ עותק נוסף של השומר סירב לפעול
חשבון: 1200252169
שעת שרת: 2026.08.03 01:48:42
יתרה: 2133.00
הון: 2133.00
הפסד היום: עדיין לא חושב
מצב השומר: פעיל
סיבה: עותק אחר של השומר כבר פועל על החשבון
העותק הקיים ממשיך להגן על החשבון
build=TG

=== S3 SAFE_HALT after repeated crashes ===
🛑 עצירת בטיחות: השומר קרס שוב ושוב
חשבון: 1200252169
שעת שרת: 2026.08.04 16:37:04
יתרה: 2133.00
הון: 2133.00
הפסד היום: עדיין לא חושב
מצב השומר: עצירת בטיחות
4 הפעלות ברצף הסתיימו בלי עצירה תקינה, בהפרש של עד 300 שניות זו מזו
השומר אינו מגן על החשבון ואינו סוגר דבר
לחידוש: לעצור את השומר, למחוק את קובץ העצירה ולהפעיל מחדש
build=TG

=== S3 SAFE_HALT persists after a restart ===
🛑 עצירת בטיחות נמשכת אחרי הפעלה מחדש
חשבון: 1200252169
שעת שרת: 2026.08.04 16:37:54
יתרה: 2133.00
הון: 2133.00
הפסד היום: עדיין לא חושב
מצב השומר: עצירת בטיחות
העצירה התחילה בשעה 2026.08.04 16:37:04
השומר אינו מגן על החשבון עד לחידוש ידני
build=TG

=== S4 lock, the daily limit ===
🔒 החשבון ננעל: חריגה מהמגבלה היומית
חשבון: 1200252169
שעת שרת: 2026.09.15 18:36:17
יתרה: 2300.16
הון: 2164.56
הפסד היום: 130.20 מול מגבלה של 126.21
מצב השומר: נעול
נעול עד: 2026.09.16 01:00:00
המגבלה שנחצתה: המגבלה היומית באחוזים, 5.50 אחוז מהיתרה בתחילת היום
התוצאה ברגע הנעילה: הפסד 130.20
השומר סוגר עכשיו 3 פוזיציות ומוחק 0 פקודות ממתינות
build=TG

=== S4 crossed limit wordings, in order: percent leg, currency leg, held floor, daily peak ===
המגבלה שנחצתה: המגבלה היומית באחוזים, 5.50 אחוז מהיתרה בתחילת היום
המגבלה שנחצתה: המגבלה היומית בסכום קבוע של 200
המגבלה שנחצתה: מגבלה שנקבעה מוקדם יותר היום ונשמרה מול הגדלה
המגבלה שנחצתה: ירידה מהשיא היומי של הרווח הסגור

=== S4 lock, give back from the daily peak ===
🔒 החשבון ננעל: ירידה מהשיא היומי
חשבון: 1200252169
שעת שרת: 2026.09.26 16:35:35
יתרה: 3138.34
הון: 2976.30
רווח היום: 90.96 מול מגבלת הפסד של 158.69
מצב השומר: נעול
נעול עד: 2026.09.27 01:00:00
שיא הרווח הסגור היום: 253.00
סף הנעילה: רווח 94.31
התוצאה ברגע הנעילה: רווח 90.96
השומר סוגר עכשיו 3 פוזיציות ומוחק 0 פקודות ממתינות
build=TG

=== S6 enforcement result ===
🧹 סגירת הפוזיציות הושלמה
חשבון: 1200252169
שעת שרת: 2026.09.23 15:28:24
יתרה: 2880.70
הון: 2880.70
הפסד היום: 0.00 מול מגבלה נעולה של 147.54
מצב השומר: נעול
נסגרו: 3 פוזיציות
נמחקו: 2 פקודות ממתינות
ניסיונות שליחה: 5
כשלים: 0
משך: 7 שניות
build=TG

=== S6 position held, trade session closed ===
⚠️ פוזיציה לא נסגרה: המסחר בסמל סגור כעת
חשבון: 1200252169
שעת שרת: 2026.09.26 16:35:38
יתרה: 3138.34
הון: 3138.30
הפסד היום: 0.00 מול מגבלה נעולה של 158.69
מצב השומר: נעול
מספר הפוזיציה: 781624897
XAUUSD.ecn
ניסיון חוזר כשהמסחר בסמל ייפתח: 2026.09.28 01:01:00
build=TG

=== S6 position held, hard stop ===
⚠️ פוזיציה לא נסגרה אחרי 10 ניסיונות
חשבון: 1200252169
שעת שרת: 2026.09.23 15:30:00
יתרה: 2880.70
הון: 2850.10
הפסד היום: 30.60 מול מגבלה נעולה של 147.54
מצב השומר: נעול
מספר הפוזיציה: 753031555
XAUUSD.ecn
השומר ינסה שוב כל 60 שניות
build=TG

=== S6 held position finally closed ===
🧹 פוזיציה שלא נסגרה קודם נסגרה עכשיו
חשבון: 1200252169
שעת שרת: 2026.09.28 01:01:05
יתרה: 2998.80
הון: 2998.80
הפסד היום: 0.00 מול מגבלה נעולה של 158.69
מצב השומר: נעול
מספר הפוזיציה: 781624897
XAUUSD.ecn
build=TG

=== S7 trade opened while locked ===
🧹 עסקה שנפתחה בזמן הנעילה נסגרה
חשבון: 1200252169
שעת שרת: 2026.09.23 15:56:12
יתרה: 2880.62
הון: 2880.62
הפסד היום: 0.08 מול מגבלה נעולה של 147.54
מצב השומר: נעול
מספר הפוזיציה: 753338779
XAUUSD.ecn
נסגרה בניסיון הראשון
build=TG

=== S8 lock released ===
🔓 הנעילה הסתיימה, יום מסחר חדש
חשבון: 1200252169
שעת שרת: 2026.09.27 01:00:03
יתרה: 2998.84
הון: 2998.80
הפסד היום: 0.04 מול מגבלה של 164.94
מצב השומר: פעיל
הנעילה הסתיימה בשעה 2026.09.27 01:00:00
המגבלה ליום החדש: 164.94
build=TG

=== S8 locked again at the new day ===
🔒 הנעילה חודשה ביום המסחר החדש
חשבון: 1200252169
שעת שרת: 2026.08.26 01:00:10
יתרה: 2027.98
הון: 1919.14
הפסד היום: 108.84 מול מגבלה של 101.40
מצב השומר: נעול
ההפסד הפתוח עדיין חוצה את המגבלה של היום החדש
נעול עד: 2026.08.27 01:00:00
build=TG

=== S9 approaching the limit ===
⚠️ התקרבות למגבלה היומית
חשבון: 1200252169
שעת שרת: 2026.10.19 14:05:12
יתרה: 2172.06
הון: 2071.09
הפסד היום: 100.97 מול מגבלה של 126.21
מצב השומר: פעיל
נוצלו 80 אחוז מהמגבלה
נותרו 25.24 עד נעילה
זו התראה בלבד, החשבון אינו נעול
build=TG

=== S10 broker connection restored ===
📶 החיבור לשרת הברוקר חזר
חשבון: 1200252169
שעת שרת: 2026.08.18 12:13:43
יתרה: 2133.13
הון: 2133.13
הפסד היום: 0.00 מול מגבלה של 106.66
מצב השומר: פעיל
החיבור נותק בשעה 2026.08.18 12:08:42
החיבור חזר בשעה 2026.08.18 12:13:43
משך הניתוק: 301 שניות
בזמן הניתוק השומר לא קיבל החלטות נעילה ולא שלח פקודות
build=TG

=== S11 Telegram reachable again ===
📨 התראות שהתעכבו נשלחות עכשיו
חשבון: 1200252169
שעת שרת: 2026.10.19 12:20:40
יתרה: 2172.06
הון: 2172.06
הפסד היום: 0.00 מול מגבלה של 126.21
מצב השומר: פעיל
טלגרם לא היה זמין מהשעה 12:00:05 עד השעה 12:20:40
מספר ההתראות שהתעכבו: 4
ההתראות שהתעכבו נשלחות מיד אחרי הודעה זו
build=TG

=== S12 algorithmic trading blocked ===
⛔ המסחר האלגוריתמי חסום, השומר לא יכול לסגור פוזיציות
חשבון: 1200252169
שעת שרת: 2026.09.28 10:44:02
יתרה: 2805.35
הון: 2805.35
הפסד היום: 193.49 מול מגבלה נעולה של 164.94
מצב השומר: נעול
החסימה: כפתור המסחר האלגוריתמי בטרמינל כבוי
השומר ימשיך לבדוק ויסגור מיד כשהמסחר יחזור
build=TG

=== S12 block wordings, in order: terminal button, EA setting, account, broker, while ACTIVE ===
החסימה: כפתור המסחר האלגוריתמי בטרמינל כבוי
החסימה: המסחר האלגוריתמי כבוי בהגדרות השומר
החסימה: החשבון אינו מאפשר מסחר, ייתכן שנכנסו בסיסמת צפייה
החסימה: הברוקר אינו מאפשר מסחר אוטומטי בחשבון
החסימה בזמן שהחשבון פעיל: אם תהיה חריגה השומר לא יוכל לסגור פוזיציות

=== S12 trading restored ===
✅ המסחר האלגוריתמי חזר
חשבון: 1200252169
שעת שרת: 2026.09.28 10:47:03
יתרה: 2805.35
הון: 2805.36
הפסד היום: 193.48 מול מגבלה נעולה של 164.94
מצב השומר: נעול
השומר יכול שוב לסגור פוזיציות
build=TG

=== S13 check name at the dead man service ===
השומר של חשבון 1200252169 שותק

=== S14 end of day summary ===
📊 סיכום יום מסחר
חשבון: 1200252169
שעת שרת: 2026.10.20 01:00:04
יתרה: 2140.50
הון: 2140.50
הפסד היום: 0.00 מול מגבלה של 117.73
מצב השומר: פעיל
יום המסחר שהסתיים: 2026.10.19
התוצאה הסגורה של היום שהסתיים: הפסד 31.56
שיא הרווח הסגור של היום שהסתיים: 12.40
נעילות ביום שהסתיים: 0
המגבלה ליום החדש: 117.73
build=TG

=== S15 resumed after SAFE_HALT ===
🟢 השומר חודש אחרי עצירת בטיחות
חשבון: 1200252169
שעת שרת: 2026.08.04 16:39:54
יתרה: 2133.00
הון: 2133.00
הפסד היום: עדיין לא חושב
מצב השומר: בסנכרון
קובץ העצירה נמחק ידנית, לפי נוהל החידוש
build=TG

=== S16 lock restored at start ===
🔒 הנעילה שוחזרה בהפעלת השומר
חשבון: 1200252169
שעת שרת: 2026.09.23 16:57:35
יתרה: 2880.70
הון: 2879.58
הפסד היום: 1.12 מול מגבלה נעולה של 147.54
מצב השומר: נעול
נעול עד: 2026.09.24 01:00:00
מקור הנעילה: קובץ מצב הנעילה ומשתנה הגיבוי בטרמינל
השומר סוגר עכשיו 1 פוזיציות ומוחק 0 פקודות ממתינות
build=TG

=== S16 lock source wordings ===
מקור הנעילה: קובץ מצב הנעילה
מקור הנעילה: משתנה הגיבוי בטרמינל
מקור הנעילה: היסטוריית העסקאות בשרת
מקור הנעילה: עסקאות הסגירה של השומר מהיום
מקור הנעילה: ירידה מהשיא היומי
מקור הנעילה: קובץ מצב הנעילה פגום, הנעילה נמשכת עד תחילת יום המסחר הבא

=== S17 file write failure ===
⚠️ השומר לא הצליח לשמור קובץ
חשבון: 1200252169
שעת שרת: 2026.10.19 14:05:12
יתרה: 2172.06
הון: 2172.06
הפסד היום: 0.00 מול מגבלה של 126.21
מצב השומר: נעול
הקובץ: קובץ מצב הנעילה
הנעילה נשמרת בזיכרון בלבד עד ההפעלה הבאה
build=TG

=== S18 previous session cut off ===
⚠️ ההפעלה הקודמת של השומר נקטעה
חשבון: 1200252169
שעת שרת: 2026.09.15 22:35:38
יתרה: 2172.06
הון: 2172.06
הפסד היום: עדיין לא חושב
מצב השומר: בסנכרון
השומר לא פעל במשך 28 שניות לפני ההפעלה הזו
סיבה אפשרית: כיבוי המחשב, קריסה או סגירה בכוח
build=TG

=== S19 limit change refused while locked ===
⚠️ שינוי מגבלה נחסם
חשבון: 1200252169
שעת שרת: 2026.08.18 15:36:30
יתרה: 239.63
הון: 239.63
הפסד היום: 1893.50 מול מגבלה נעולה של 106.66
מצב השומר: נעול
המגבלה שהוזנה: 10.00 אחוז
המגבלה שבתוקף עד סוף הנעילה: 106.66
build=TG

=== S19 raise held until the next day ===
⚠️ הגדלת המגבלה תיכנס לתוקף רק ביום המסחר הבא
חשבון: 1200252169
שעת שרת: 2026.09.07 14:32:54
יתרה: 2294.76
הון: 2294.76
הפסד היום: 0.00 מול מגבלה של 114.74
מצב השומר: פעיל
המגבלה שהוזנה: 126.21
המגבלה שבתוקף היום: 114.74
build=TG

=== S20 server clock jump ===
⚠️ שעון השרת קפץ ביותר מיום אחד
חשבון: 1200252169
שעת שרת: 2026.08.10 01:00:00
יתרה: 2003.46
הון: 2003.46
הפסד היום: 0.00 מול מגבלה של 100.17
מצב השומר: פעיל
תחילת היום קפצה ב 259200 שניות
השומר ממשיך לחשב לפי היום החדש
build=TG

=== S21 history read failure ===
⚠️ קריאת היסטוריית העסקאות נכשלה
חשבון: 1200252169
שעת שרת: 2026.10.19 14:05:12
יתרה: 2172.06
הון: 2172.06
הפסד היום: עדיין לא חושב
מצב השומר: בסנכרון
השומר לא מקבל החלטות נעילה עד שהקריאה תצליח, ומנסה שוב בכל שנייה
build=TG

=== S22 not protecting yet ===
⚠️ השומר עדיין לא מגן על החשבון
חשבון: 1200252169
שעת שרת: 2026.10.19 09:05:03
יתרה: 2172.06
הון: 2172.06
הפסד היום: עדיין לא חושב
מצב השומר: בסנכרון
השומר בסנכרון כבר 300 שניות
סיבה: אין חיבור לשרת הברוקר
build=TG

=== S22 second reason wording ===
סיבה: היסטוריית העסקאות עדיין לא יציבה

=== S24 another instance took over ===
⛔ עותק אחר של השומר השתלט על החשבון
חשבון: 1200252169
שעת שרת: 2026.10.19 14:05:12
יתרה: 2172.06
הון: 2172.06
הפסד היום: 0.00 מול מגבלה של 126.21
מצב השומר: פעיל
עותק נוסף של השומר רשם את עצמו כפעיל על אותו חשבון
יש לוודא שהשומר מוצמד לגרף אחד בלבד
build=TG
```

Field map, the runtime source of each line:

| Line | Source |
|---|---|
| Line 2, account | `ACCOUNT_LOGIN` (`g_ag_login`) |
| Line 3, server time | `TimeCurrent` at the event, through `AgServerNow`, date and seconds |
| Line 4, balance | `ACCOUNT_BALANCE` |
| Line 5, equity | balance plus `AgFloating`, never an `ACCOUNT_EQUITY` read, the D2D4-4(a) precedent |
| Line 6, today's loss or gain against the limit | ACTIVE: `g_ag_last_pnl` against `enforced_limit`. LOCKED: `base_snap` minus equity against `limit_snap`, no history walk (D2D4-3(a)); a deposit during a locked day shifts this line, since the Q2 identity does not apply to the shortcut. SYNCING before a first pass, a refused start, or a stopped guardian: the block's "not computed yet" wording |
| Line 7, guardian state | the block's five state lines, in this order: ACTIVE, LOCKED, SYNCING, SAFE_HALT, no running EA |
| S4, the limit that was crossed | `chosen=peak`: the fourth wording; otherwise `enforced_limit` below the live limit: the third wording; otherwise the smaller of the percent leg (base times percent, first wording) and the currency leg (second wording) |
| Last line, build | the build label constant of the init line |
| The delay line | any message sent later than 60 s after its event, the delay in whole seconds |

S13's own text is the service's template. The block gives only the check name.

## 6. Design constraints

These are fixed unless the owner rules otherwise.

### 6.1 Enforcement first, and the worst case delay

1. One alert pump call per OnTimer tick, after the state dispatch and the RESYNC lines. In SAFE_HALT, which returns early at EA:1296, the pump runs just before that return. SAFE_HALT does no enforcement, so nothing precedes the pump there.
2. At most one WebRequest per tick: either one Telegram message or one network heartbeat ping, never both.
3. The pump does nothing on a tick where:
   - the sweep sent an order (`sent > 0`), or the accelerator ran since the last tick;
   - `TERMINAL_CONNECTED` reads false. A lost broker link usually means a lost internet link, so this avoids hanging connects; events queue and S10 reports the gap at reconnect;
   - a failure backoff is running: 2, 4, 8 and so on up to 300 s, on the pass counter as the sweep does (ENF-10(a));
   - fewer than 3 s have passed since the last Telegram message;
   - a Telegram 429 `retry_after` window is open.
4. The WebRequest timeout is a compile-time constant, 2000 ms, never an input, on the `AG_MUTEX_STALE_SECONDS` precedent.
5. Worst case:
   - A tick does either the sweep's one synchronous OrderSend (2.2 to 3.4 s measured, LEDGER `:420`) or one WebRequest (2000 ms plus connect overhead, UNKNOWN), never both.
   - The next tick's breach evaluation or sweep pass therefore starts at most about 2 s plus that overhead late.
   - An OnTradeTransaction accelerator event that lands during a send waits up to the same time (3.3, fact 7). Q9 still bounds a declaration at one pass after the evaluation that runs.
   - The mutex heartbeat is refreshed at the start of every tick. The gap between two refreshes is at most 1 s plus one tick's work, about 4.4 s on a sweep tick, below the 10 s threshold.
6. Row TG-M measures every send's duration under three conditions: normal, Telegram refused by the allow list, and internet off. If any send exceeds 3000 ms, the bound above does not hold and TG-1's fallback applies.

### 6.2 Secrets: token, chat id and the check's ping URL

1. None of the three ever enters git, any file the executor writes, or this session. The owner enters them in the EA's input fields in the attach dialog (TG-6).
2. The EA journals the configuration only as `alerts config|telegram=<on|off:empty|off:malformed>|network_heartbeat=<on|off:empty|off:malformed>`, never a value.
   - Send failures print the class, HTTP code, error code and duration, never the URL.
   - Every formatter takes no secret argument, which makes the SPEC 6 clause (`docs/SPEC_v0.1.md:137`) hold by construction.
3. The token travels in the Bot API URL path (`/bot<token>/sendMessage`) and the chat id in the JSON body. The ping URL is itself a secret: anyone holding it can ping and mask a silent guardian.
4. Where MetaTrader 5 keeps input values on disk, all plain text under the terminal data folder:
   - Chart profiles: `MQL5\Profiles\Charts\<profile>\chartNN.chr`, inside the `<expert>` block, written at a clean shutdown. `LEDGER.md:1611` reads `DailyLossPercent=5.0` from `chart01.chr`.
   - Templates: `MQL5\Profiles\Templates\*.tpl`, saved while the EA is on the chart. `LEDGER.md:2074` records that `Default.tpl` once carried the prior project's `InpTelegramToken`.
   - Preset files: `.set` files saved from the inputs dialog, `MQL5\Presets` by default.
   - Any other terminal file that keeps last used values: UNKNOWN.
5. WARNING: a saved preset or template carries the token. It is never shared, never sent in a message, never copied into a repository, and never banked as evidence. Never save a preset or a template while the token is filled in. No chart profile is ever banked as evidence.
6. Windows environment variables are not an option. Reading them from MQL5 needs a DLL import (for example `GetEnvironmentVariableW` from `kernel32.dll`) and "Allow DLL imports", which this project does not use and which would open a path this design keeps closed.
7. Release secrecy: any new source file passes the IN-22 (b) patterns of `scripts/secrecy-patterns.txt`, comments included.

### 6.3 Inbound commands

None in this design: outbound only, no `getUpdates` polling. Any inbound path is TG-8. No command may unlock, widen a limit or disable the guardian. SPEC section 0 ("Unlock is time expiry only. No manual override of any kind."), Q6/F7, D1f and the hardening FINAL of 2026-09-02 each forbid it.

### 6.4 Deduplication and rate limits

1. Messages are edge triggered: on entry to a state class, and on exit where the catalog names one (S10, S11, S12). Cadence lines are never sent: LIFE, `sweep held` at the cadence, `sweep blocked` at the cadence.
2. The same class and key within 300 s is suppressed and counted, and the count rides on the next message of that class.
3. An in-place re-init (reasons 2, 3, 5 and 7) followed by an init within 60 s sends one S1 "restarted" message, not S2 then S1.
4. The queue holds at most 50 events. On overflow it keeps the first and the newest and reports the number dropped.
5. Telegram: at least 3 s between messages, and 429 `retry_after` is honored. The network heartbeat ping is not a Telegram request.
6. Local alerting is untouched (FINAL at `LEDGER.md:2387`). Every journal line, Alert popup and banner sub-condition the EA raises today stays exactly as it is. Telegram deduplication applies to Telegram only. For the trade disallowed states, Telegram is an added channel and never replaces or reduces the journal, the Alert or the chart banner.

### 6.5 UTF-8 and the encoding of Hebrew literals

1. An MQL5 `string` is UTF-16 in memory.
   - The message is built as JSON, with quote, backslash and newline escaped.
   - It is converted with `StringToCharArray(text, bytes, 0, WHOLE_ARRAY, CP_UTF8)`, and the trailing zero byte is dropped.
   - It is sent with `Content-Type: application/json; charset=utf-8`.
2. Hebrew literals live in one new include file, saved as UTF-8 with a byte order mark. That is the encoding AccountGuardian.mq5 already carries (3.1). MetaEditor reads a file with that mark as UTF-8. How it decodes a file without the mark is not relied on.
3. The queue file holds event codes and numbers only, never Hebrew text, so it stays ASCII through `AgAtomicWrite`'s `FILE_ANSI`. The Hebrew is rendered at send time.
4. Verification at three levels:
   - Static (TG-S7): the include starts `EF BB BF`, decodes as UTF-8 with no error, and each template's Hebrew character count equals section 5's block.
   - Vectors (TG-S8): a script check renders each template with fixed values. The md5 of its UTF-8 bytes must equal a value computed independently from section 5's text.
   - Live (TG-L rows): the owner's pasted received text equals the rendered draft.

### 6.6 The network heartbeat (S13, per the FINAL at `LEDGER.md:2431`)

1. A GET to the check's ping URL every interval of TG-2.2, from the same pump.
2. It runs in every state, SAFE_HALT included, because guardian liveness is not a function of state. That is the mutex heartbeat's own rule at EA:1216-1218.
3. It is the tick's one request, and it is skipped on a tick that swept.
4. Failures are journaled. A success is journaled at most once per `AG_LIFE_INTERVAL_SECONDS`.
5. The S13 message is the dead man service's own, through its Telegram integration (3.3, fact 9).

### 6.7 Owner steps, written as dictation

Every step on any terminal is the owner's. The executor performs none of them, and never sees the token, the chat id or the ping URL.

A. The bot. The owner states the new bot and token already exist (1.3). These steps stay for a rotation:
1. In Telegram, open BotFather.
2. For a new token on the same bot, send `/revoke`, choose the bot, and keep the new token BotFather returns. The old token stops working at once.
3. Enter the new token in the EA's input field at the next attach, per E below.

B. The chat id. The owner states it is already known. These steps stay for reference:
1. From the owner's own Telegram account, send any message to the new bot.
2. In a browser on the owner's own computer, open `https://api.telegram.org/bot` followed by the token, then `/getUpdates`, typing the token by hand.
3. Read the number after `"chat":{"id":` in the reply.
4. Keep it private. Never paste it into a chat with anyone.

C. The prior project's bot, only if TG-7 rules revoke:
1. In BotFather send `/mybots`.
2. Choose the prior project's bot, if it is listed.
3. Choose API Token, then Revoke current token.
4. Report back only "revoked" or "not listed".

D. The WebRequest allow list on each acceptance terminal. The owner states the live terminal is already set (1.3). For a demo terminal under TG-10 (A):
1. In MetaTrader 5, open Tools, then Options, then the Expert Advisors tab.
2. Tick "Allow WebRequest for listed URL".
3. Add `https://api.telegram.org`.
4. Add `https://hc-ping.com`.
5. Remove every other entry in that list.
6. Press OK.
7. Take a screenshot of the list and paste it back. This screenshot, from each acceptance terminal, is the evidence that closes the ISSUES entry at `LEDGER.md:177` at acceptance.

E. The EA inputs, at attach, following the 2026-09-07 procedure:
1. Attach the EA to the chart, or open its properties, and go to the Inputs tab.
2. Paste the token into the token field, the chat id into the chat id field, and the check's ping URL into the network heartbeat field. The field names are fixed in the build instruction.
3. Do not press Save in the inputs dialog, and do not save a template while the EA is on the chart.
4. Press OK.
5. In the Experts journal, read `init|build=<label>`, `limits accepted|..` and `alerts config|telegram=on|network_heartbeat=on`, with no ALERT between them, before any restart.
6. Confirm the S1 message arrived in Telegram.
7. Paste the three journal lines and the received text back.

F. The dead man check, under TG-2.1:
1. Sign in to the owner's own account at healthchecks.io.
2. Add a new check. Never reuse the prior project's UUID.
3. Name it with section 5's S13 name.
4. Set the period and the grace time ruled in TG-2.2 and TG-2.3.
5. Under Integrations, add Telegram and follow the service's own steps to link the owner's chat.
6. Use the service's test notification once, and confirm it arrives.
7. Copy the check's ping URL into the network heartbeat field at the next attach, per E.

G. A build, later, under its own instruction:
- On the development terminal, the owner runs a deploy script written under the 2026-09-06 hand. On the computer that runs the live account, the build arrives through an exported folder and the installer, as IN-D did (`LEDGER.md:7`, `:243`).
- Every md5 on any terminal is read by the owner with `Get-FileHash` and pasted back.

## 7. Ruling sheet TG

Every item is OPEN except TG-6, which carries the owner's answer recorded as the owner's statement. Options are worked against the code as surveyed in section 3. No option runs against a FINAL in section 2.

**TG-1. Where does the sending live?**
- (A) Inside the guardian EA, one pump at the end of OnTimer under 6.1. One program, one deploy, no inter-program protocol. Each tick that sends runs up to about 2 s longer, bounded and measured by TG-M. Deploy, installer manifest and export grow by one include file.
- (B) A separate MQL5 Service program fed by the EA through a queue file under `MQL5\Files\AccountGuardian`. The EA never waits on the network. The owner adds and starts the service once in the Navigator. A second program has its own failure modes and needs its own acceptance rows. The file is shared between two programs. The installer, manifest and export carry a second ex5. The service can also watch the `AG_HB_<login>` mutex heartbeat and report an EA that stopped while the terminal still runs.
- (C) A separate MQL5 Service fed through terminal global variables (event codes and numbers only), composing the Hebrew itself. Same isolation as (B) with no shared file. Global variables carry numbers only, so every field is encoded by convention. The highest build cost of the three.

Recommendation: A, under the containment of 6.1. If TG-M measures any send above 3000 ms, B replaces it.

**TG-2. S13, the hosted dead man check, per the FINAL at `LEDGER.md:2431`.** A fresh hosted check with a new UUID; the old UUID is never reused. The open questions are only these three.

TG-2.1, provisioning details:
- (A) The owner's own healthchecks.io account. One check on a simple schedule (period and grace). The service's Telegram integration delivers to the owner's chat. The ping URL is entered as an EA input field, as TG-6 places the token. S13 then needs no EA code beyond the ping.
- (B) As (A), with a cron schedule in place of period and grace. Same delivery. No gain for a guardian that runs all week, since the account trades every day (`LEDGER.md:2222`).
- (C) As (A), plus the service's email integration as a second channel. A second path if Telegram itself is down, and one more place the alert can be missed or filtered.

Recommendation: A.

TG-2.2, network heartbeat interval:
- (A) 60 s. 1440 pings a day. The shortest period the service offers, recalled as 1 minute and to be confirmed at provisioning.
- (B) 30 s. Twice the traffic. No faster detection, since the service's own period cannot go below its minimum.
- (C) 300 s. A fifth of the traffic. Detection is never faster than about 5 minutes plus the grace.

Recommendation: A.

TG-2.3, silence threshold (period plus grace):
- (A) 60 s period plus 240 s grace: the alert about 5 minutes after the last ping. A routine stop and start stays below it: a LiveUpdate restart measured at about 14 s (`LEDGER.md:458`) and a terminal close and reopen measured at 3 min 19 s (`LEDGER.md:449`).
- (B) 60 s plus 60 s: about 2 minutes. Faster, and a routine restart or update can raise a false alert.
- (C) 60 s plus 840 s: about 15 minutes. Quiet, and an unprotected account stays unreported for a quarter of an hour.

Recommendation: A.

**TG-3. S9 approach levels.** The share of the allowance used is (day reference minus pnl) divided by `enforced_limit`. The day reference is the larger of 0 and the day's realized peak, so a share of 1.0 is exactly the lock level `MathMax(ratchet_level, peak_level)` (EA:925-927). Every level is a notification, never a limit. Its text says so, in the spirit of the FINAL at `LEDGER.md:2500`.
- (A) One level, 80 percent. One message a day at most. No earlier warning.
- (B) Two levels, 50 and 80 percent, each once per day. Re-armed if the share falls back 10 points below the level. An early and a late warning.
- (C) Three levels, 50, 75 and 90 percent, each once per day. The most warning and the most messages on a volatile day.

Recommendation: B.

**TG-4. S14, an end of day summary.**
- (A) No summary. Fewer messages. The day's result is read in the journal or the terminal.
- (B) Yes, at the day rollover, 01:00 server. Triggered by the existing `day rollover` line (EA:864) or, on a locked day, by the expiry (EA:689). It uses the one day boundary already FINAL and defines no second one.
- (C) As (B), plus a weekly summary once Phase 4 weekly measurement exists. The weekly figure is raw only, per the FINAL at `LEDGER.md:2500`. Nothing weekly can be sent before Phase 4 is built.

Recommendation: B.

**TG-5. Does the unsent queue persist across terminal restarts?**
- (A) Memory only. Simple. Every queued event is lost on a restart, a kill or a refused init, so S2, S3 and S18 can never be sent after recovery.
- (B) A persisted queue file `MQL5\Files\AccountGuardian\tgqueue_<login>.dat`. Atomic write through `AgAtomicWrite`, event codes and numbers only (6.5), never loaded never written applied by choice. Clean restarts lose nothing. A hard kill loses only events after the last write.
- (C) As (B), plus a send attempt inside OnDeinit for the reasons where the EA does not come straight back. See TG-13.

Recommendation: B.

**TG-6. Where are the token and the chat id entered?** ANSWERED BY THE OWNER IN CHAT, 2026-10-20, recorded as the owner's statement and not as a ruling, quoted as given: "EA input fields, entered by the owner in the attach dialog."

Consequences on record:
- The values live in plain text in chart profiles, and in any preset or template saved while they are filled in (6.2).
- New inputs are optional class under Q4/F9: an empty or malformed value turns the feature off with a WARN and never refuses init.
- Every new input adds validation vector cost (`LEDGER.md:2269`).
- Windows environment variables are not an option (6.2).

**TG-7. The prior project's bot.** Its token once sat in a template (`LEDGER.md:2074`). The FINAL at `LEDGER.md:2814` moves creating or rotating a token to this work.
- (A) Revoke its token in BotFather if the bot still exists, per 6.7 C. Any copy of the old token, in an old template or backup, stops working. The bot itself and its history stay unless deleted.
- (B) Leave it. No owner step. An old token that still works stays usable by anyone holding a copy.

Recommendation: A.

**TG-8. Inbound commands, checked against the input hardening decisions.** No option may unlock, widen a limit or disable the guardian. That bar is fixed by SPEC section 0, Q6/F7 (`LEDGER.md:2399`), D1f (`:2603`) and the hardening FINAL (`:2181`), and is not a choice here.
- (A) None. Outbound only. No polling, no extra request per tick, nothing the network can ask of the guardian.
- (B) One read only command, a status reply, polled from `getUpdates` at most every 60 s and answered only to the configured chat id. It changes no input and no state, so it stays within D1f and Q6. It costs one more request on the polling ticks and keeps an offset in memory. Anyone holding the token can read the status.

Recommendation: A.

**TG-9. Does the feature ship in the customer release repository?**
- (A) Yes, in the release after its acceptance closes. Customers enter their own token, chat id and ping URL, and the feature stays off while they are empty. The README gains Hebrew setup steps. The installer's manifest and the export carry the new file. IN-22 (b) secrecy runs over it.
- (B) No. The owner's copy differs from the release. The live computer still receives the build through a private exported folder and the installer, as IN-D did. Two lineages to keep apart.

Recommendation: A.

**TG-10. Acceptance venue.**
- (A) A demo terminal first, then the live account. For example the development terminal on this computer, logged into a demo account, receiving the build by a deploy script under the 2026-09-06 hand. The lock rows (S4, S6, S7, S8, S16) need a real lock, which on a demo costs nothing. Then the live account's computer by the installer, for rows that need no lock.
- (B) Live directly. Every lock row would need a real loss on the live account. The alerts code meets real money before any row has passed.

Recommendation: A.

**TG-11. Base branch for the build.** Step 0 found one unmerged branch, `worktree-ledger-poll-counter-issue` at `12d7df1`, ledger only. It records the OPEN issue that the SYNCING poll counter is not reset on an in-place re-init (reasons 3 and 5), which shapes when S1 fires after such a re-init.
- (A) Cut from main as it stands at the build. No wait. The two ISSUES heads meet at a later merge and need a union, which is routine.
- (B) Cut after the owner merges `worktree-ledger-poll-counter-issue` into main. No union later. Waits on the owner's merge.
- (C) Cut after a poll counter fix, which is not authorized today. S1 after a re-init would then follow a fresh three poll gate. Waits on a separate ruling and build.

Recommendation: A.

**TG-12. Where the alerts work sits beside the branch plan FINAL of 2026-09-23 (`LEDGER.md:2698`).** That FINAL lists the remaining items; the owner's stated next steps put alerts in step FOUR with Phase 4 weekly reporting, the pre-trade gate and the Definition of Done drills (`LEDGER.md:215`). The installer's IN-1 is the precedent.
- (A) Now, on its own branch, in parallel with Phase 4 planning, under the merge gate.
- (B) After Phase 4 weekly reporting is built, so a weekly summary (TG-4 C) is possible from the first build.
- (C) After the Definition of Done drills. The drills then run without alerts.

Recommendation: A.

**TG-13. Sends at a stop and at a refused start (S2 and S3).** The local writes always come first under every option.
- (A) Queue only. S2 and S3 are sent by the next healthy session. A guardian removed for good is reported by S13 alone.
- (B) For reasons 1, 4 and 9, one send attempt inside OnDeinit with a 1500 ms timeout, after the halt clean mark, the mutex release and the queue write. Queue only for every other reason. A refused start queues. Fast news of a removal or a close, if acceptance shows WebRequest works there (3.2). The S2 entry stays queued if the attempt fails.
- (C) As (B), plus one send attempt inside OnInit before a refusal returns. Also reports a refused start at once. Holds the refusing init up to 1500 ms. WebRequest during a terminal start is UNKNOWN.

Recommendation: B.

## 8. Acceptance rows

Every row closes on quoted evidence carrying the build: the `init|build=<label>` journal line and the landed ex5 md5 the owner pastes from `Get-FileHash`. Per standing rule 7, that md5 is recorded with the label and is not identity by itself. Every live row is the owner's; the executor reads only what the owner pastes or banks. Any live row failure is reported at once as a numbered defect.

Static rows, at the build, by the executor:
- TG-S1. Three compiles at `Result: 0 errors, 0 warnings`, every `including` line inside the worktree.
- TG-S2. The trade API grep of ENF-S2 returns the same lines as at `31ac695`, all in `Sweep.mqh`.
- TG-S3. AgSweepPass keeps exactly its two call sites (ENF-S3).
- TG-S4. AgEvaluateActive and its breach tail, AgBootDerivation, AgEvaluateLocked, AgDeclareLock and AgEnterLockFromBoot are byte identical by md5. The only exceptions are hook lines the build instruction names one by one.
- TG-S5. WebRequest appears only in the new alerts code, every call passes the timeout constant, and none is reachable before the state dispatch of a tick.
- TG-S6. No token shaped string, chat id literal or ping UUID anywhere in the tree. Every alerts formatter takes no secret argument. The IN-22 (b) patterns read zero over every shipped file.
- TG-S7. The Hebrew include starts `EF BB BF`, decodes as UTF-8, and its Hebrew counts match section 5.
- TG-S8. The vectors render every template and match the md5 values computed from section 5. The vector denominator grows by the number of checks named in the build.

Deploy row:
- TG-D. On the venue of TG-10, by the owner at dictation. Before any restart: `init|build=<label>`, `limits accepted|..` and `alerts config|telegram=on|network_heartbeat=on`, with no ALERT between them. The landed ex5 md5 is pasted. The S1 message is received, its text pasted.

Live rows. Each closes on the owner's pasted received text together with the matching journal lines (`alerts sent|class=<S>|http=200|ms=<n>`):
- TG-L1. S2 and S1: the EA removed from the chart (reason 1) and attached again; then a parameter change (reason 5) giving one "restarted" message.
- TG-L2. S3: an attach with an off list limit vector, then the correction. The refusal reported per TG-13.
- TG-L3. S4 and S6 on one lock of the demo: a losing position past the limit.
- TG-L4. S7: a position opened from the mobile app while locked.
- TG-L5. S8 at the 01:00 expiry.
- TG-L6. S9 at each ruled level.
- TG-L7. S10: the network off for at least 60 s, then on.
- TG-L8. S11:
  1. The owner removes `https://api.telegram.org` from the allow list during an event and restores it after 2 minutes.
  2. The S11 notice arrives, then the delayed messages, with `alerts failed|..|err=4014` journaled in between.
  3. The allow list screenshot after the restore shows exactly the two URLs.
- TG-L9. S12: Algo Trading off then on, once while ACTIVE and once while LOCKED. The local popups and banner sub-conditions behave exactly as before.
- TG-L10. S13, the dead man drill, on the venue of TG-10:
  1. The terminal closed for longer than the TG-2.3 threshold.
  2. The service's Telegram alert arrives.
  3. The terminal started again; the "up" notification arrives.
  4. Both texts pasted, with the times from the service's own event log.
- TG-L11. S14 at a rollover, if TG-4 rules a summary.
- TG-L12. The states a drill can reach safely:
  - S18 by a hard kill (`taskkill /F`) and a relaunch after at least 15 s.
  - S19 by raising a limit while locked.
  - S22 by starting the terminal with the network off.
  - S15, S16, S17, S20, S21 and S24 close on the vector proof of TG-S8 where no safe drill exists. Which is which is stated row by row in the build.
- TG-M. The duration of every send and every ping over the acceptance window, under three conditions: normal, Telegram refused by the allow list, and internet off. Passes on:
  - a maximum of 3000 ms or less;
  - zero `stale mutex heartbeat` WARN lines;
  - no LOCKED tick without its sweep pass.
- TG-X. Secrecy:
  1. The owner searches the Experts and terminal journals of every acceptance day on the acceptance terminal for the token, the chat id and the ping UUID, typing each value only in the owner's own window.
  2. The owner pastes the three counts. They must be zero.
  3. The values themselves are never pasted.
- TG-W. A screenshot of the WebRequest allow list on each acceptance terminal, showing exactly `https://api.telegram.org` and `https://hc-ping.com`. This closes the ISSUES entry at `LEDGER.md:177`, which stays OPEN until then.

## 9. What this plan does not do

- No source, include, script, installer, vector or preset change. No compile, no MetaEditor run, no deploy.
- Nothing under any terminal data folder is read or written by the executor. No terminal configuration file, `common.ini` included, is read or edited.
- No network call to Telegram, healthchecks.io or any other service.
- No merge, no push, no branch or worktree deletion. Nothing in the release repository.
- No DECISIONS entry. No TG item is recorded as an owner ruling. TG-6 carries the owner's statement.
- The token, the chat id and the ping URL appear nowhere in this repository or this session.
