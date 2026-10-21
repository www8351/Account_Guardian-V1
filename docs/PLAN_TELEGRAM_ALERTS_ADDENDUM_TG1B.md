# AccountGuardian: Telegram alerts, design addendum for TG-1 (B)

Written 2026-10-21 on branch `build/telegram-alerts`, cut from `plan/telegram-alerts` at `00c7237`. It is the design for the architecture the owner ruled on 2026-10-20, and it sits beside `docs/PLAN_TELEGRAM_ALERTS_2026-10-19.md`, changing that plan only where it says so.

RULED 2026-10-21, after this document was written: TG-14 (A), TG-15 (A), TG-16 (A), the SPEC changes including item 8.1, and a trade disallowed state in SYNCING or SAFE_HALT (A); the build of that date changed item 13 as item 13 states.

UNRULED 2026-10-21. Everything below is design content written for the owner's review, except where it quotes an owner ruling, and it is authority for nothing until the owner rules on it. Three ruling items are OPEN: TG-14 (item 5), TG-15 (item 6) and TG-16 (item 11). This document authorizes no code, no compile, no build and no deploy. Part B starts only on the owner's line "PART B AUTHORIZED".

Citations. `LEDGER.md:<n> as at <commit>` is the line at that commit: FINAL entries that predate this work as at `31ac695`, the plan's own convention, and the rulings of 2026-10-20 as at `ba8ddee`, the commit that recorded them. `EA:<n>`, `Persist.mqh:<n>`, `Sweep.mqh:<n>`, `Pnl.mqh:<n>` and `SPEC:<n>` are lines of `MQL5/Experts/AccountGuardian/AccountGuardian.mq5`, of the includes and of `docs/SPEC_v0.1.md` as at `00c7237`, where every file under `MQL5/` and the SPEC equal `31ac695`. "Plan <n>" is a section of the plan.

Measured this session and used below: the development terminal's data folder `D0E8209F77C8CF37AD8BF550E51FF075` on this computer carries `MQL5\Services`, LastWriteTime 2026-07-05 06:34:56, the same stamp as its `Indicators` and `Libraries` folders. It was read by one plain `Get-ChildItem -Directory` listing after the RULE B alias audit. Nothing else under any terminal data folder was read, and nothing was written.

## 0. Rulings, statements and the shape of the build

### 0.1 The rulings this design follows

| Item | Ruling, in short | LEDGER.md as at `ba8ddee` |
|---|---|---|
| TG-1 | (B) a separate MQL5 Service fed by the EA through a queue file; the EA makes no network call | `:2840` |
| TG-2.1 | (A) the owner's own healthchecks.io account, a simple schedule, the service's Telegram integration | `:2844` |
| TG-2.2 | network heartbeat every 60 s | `:2848` |
| TG-2.3 | (A) 60 s period plus 240 s grace | `:2852` |
| TG-3 | (B) two levels, 50 and 80 percent | `:2856` |
| TG-4 | (B) an end of day summary at the day rollover | `:2860` |
| TG-5 | (B) a persisted queue file `tgqueue_<login>.dat` written through `AgAtomicWrite` | `:2864` |
| TG-6 | the token, the chat id and the ping URL are input fields of the service | `:2868` |
| TG-7 | void, no revocation | `:2872` |
| TG-8 | (B) one read only command, answered only to the configured chat id with the status message | `:2876` |
| TG-9 | (A) the README gains Hebrew setup steps | `:2880` |
| TG-10 | (A) a demo terminal first, then the live account | `:2884` |
| TG-11 | (A) main as it stands plus the plan commits | `:2888` |
| TG-12 | (A) now, on its own branch | `:2892` |
| TG-13 | (B) at a stop, the local writes first, then the stop message | `:2896` |
| status | a visible status message every 4 hours, also the reply to the command | `:2900` |
| S12 | the trade permission flags read in every state, an immediate alert, enforcement unchanged | `:2904` |
| S12 local | in ACTIVE, the local Alert and the chart banner as well, at the cadence of the FINAL at `LEDGER.md:2387` as at `31ac695` | `:2908` |

### 0.2 FINAL decisions

Plan 2 lists the FINAL decisions this work follows. Every one still binds and none is reopened here. Five bind this design closely. Q3/F2, the trade disallowed states, at `LEDGER.md:2387` as at `31ac695`: item 8. The mutex heartbeat's local clock exemption at `:2451` and `AG_MUTEX_STALE_SECONDS = 10` at `:2460`: items 3 and 4. Never loaded, never written at `:2464`, and lock artifacts never deleted at `:2427`, the second applied by choice to a file that carries no lock state: item 1. The ratified installer departure TWO at `:2726`, one folder created on a fresh install: item 11. The README Hebrew only FINAL at `:2730`: items 9 and 11. Under TG-1 (B), RULE A and RULE B (`:2356`), the naming discipline (`:2423`) and SPEC 6's "No secrets, no credentials, ever" (`SPEC:137`) bind the service as they bind the EA.

### 0.3 Owner statements that supersede plan text

- The bot and the token. Plan 1.3 item 3 and plan 6.7 A say the owner created a new bot token in BotFather. That wording came from chat and is inaccurate. The owner states, with TG-7, that the bot and the token in use are the ones set up early in the guardian's development, and no revocation follows. Plan 6.7 C is void with TG-7. The plan is left as written.
- Where the values are entered. Plan 1.3 item 4, plan 6.2 item 1, plan 6.7 E and plan TG-6 place the token and the chat id in EA input fields. TG-6, as amended by TG-1 (B), places the token, the chat id and the ping URL in input fields of the service, entered when the service is added (item 9). The EA gains no input.

### 0.4 The two programs

The EA, `AccountGuardian.ex5`, stays the guardian. It writes one new file, the queue, and never touches the network. The service, `AccountGuardianAlerts.ex5`, reads that file and the mutex heartbeat, holds the three secrets, and makes every network request. Nothing the service writes is read by any decision path of the EA.

| File | Program | What it carries | Encoding |
|---|---|---|---|
| `MQL5/Experts/AccountGuardian/AccountGuardian.mq5` | EA, changed | the queue load in OnInit, the S12 permission read, the alert producer at the end of OnTimer, the stop event in OnDeinit, the label `TG` | UTF-8 with a byte order mark, as today, and zero bytes above 127 after it |
| `MQL5/Include/AccountGuardian/AlertQueue.mqh` | EA, service, vectors | the queue model, the event codes, the snapshot record, the serializer and the parser, the pure producer helpers and the new journal line formatters | ASCII |
| `MQL5/Include/AccountGuardian/AlertJson.mqh` | service, vectors | JSON escaping, the `getUpdates` parser and the command matcher, all pure | ASCII |
| `MQL5/Include/AccountGuardian/AlertText.mqh` | service, vectors | every Hebrew template and the renderer, pure | UTF-8 with a byte order mark |
| `MQL5/Services/AccountGuardian/AccountGuardianAlerts.mq5` | service | the loop, the three inputs, every `WebRequest` | ASCII |
| `MQL5/Include/AccountGuardian/Persist.mqh` | EA, changed | a quiet failure mode of `AgAtomicWrite` for the queue file alone, and three flags the producer reads: the takeover age seen by `AgMutexAcquire`, the overwrite seen by `AgMutexRefresh`, and the kind of a failed lock, halt, floor or peak file write | ASCII |
| `MQL5/Include/AccountGuardian/Sweep.mqh` | EA, changed | event pushes at four existing sites and three episode counters | ASCII |
| `MQL5/Include/AccountGuardian/Pnl.mqh` | EA, changed | one counter at each `HistorySelect failed` WARN site (`Pnl.mqh:148`, `:309`, `:522`) | ASCII |
| `MQL5/Scripts/AccountGuardian/AgPhase2StateVectors.mq5` | vectors | checks on the queue, the parser, the matcher, the renderer and the schedule | ASCII |

None of the five functions plan TG-S4 protects gains a line: `AgEvaluateActive` with its breach tail, `AgBootDerivation`, `AgEvaluateLocked`, `AgDeclareLock` and `AgEnterLockFromBoot` stay byte identical, and so does `AgTransition` in State.mqh. Everything the alerts need is read at the end of the tick from globals those functions already leave, through the two pure readers `AgFloorEffectiveLimit` (`Persist.mqh:713`) and `AgPeakEffectiveLevel` (`Persist.mqh:1038`).

The service's three inputs, names fixed at the build: `TelegramToken`, `TelegramChatId`, `NetworkHeartbeatUrl`. An empty field turns its channel off; a malformed one turns it off with one WARN; the guardian is unaffected either way, Q4/F9's optional class read onto the service. Telegram needs the token and the chat id, the command needs both as well, and the network heartbeat needs the URL alone. The checks, pure and vector tested: the token is digits, a colon, then at least 30 characters of letters, digits, underscores and hyphens; the chat id is an optional minus sign and up to 20 digits; the URL is `https://hc-ping.com/` followed by 36 characters of hexadecimal digits and hyphens in the 8, 4, 4, 4, 12 shape.

The service's journal lines, ASCII, never carrying a secret or a URL (plan 6.2.2):
- `alerts service started|build=TG|login=<n>|telegram=<on|off:empty|off:malformed>|network_heartbeat=<on|off:empty|off:malformed>|command=<on|off>`
- `alerts sent|seq=<n>|class=<code>|http=<code>|ms=<n>` and `alerts failed|seq=<n>|class=<code>|http=<code>|err=<n>|ms=<n>`
- `alerts ping|http=<code>|ms=<n>`, a success at most once per 30 s, every failure; `alerts ping skipped|guardian=<stale|released|missing>|age=<n>`, on the edge
- `alerts guardian|state=<fresh|stale|released|missing>|age=<n>`, on every change
- `alerts inbound|matched=<n>|ignored=<n>`, on a poll that returned anything
- `alerts service stopping|unsent=<n>`

Where a service's journal output appears in the terminal, the Experts tab or another: UNKNOWN, read at row TG-SV-D.

## 1. The queue between the EA and the service

### 1.1 The file

`MQL5\Files\AccountGuardian\tgqueue_<login>.dat` (TG-5 (B)). Text through `FILE_TXT | FILE_ANSI`, lines ending CRLF as the halt file's do. Codes and numbers only: digits, the minus sign, the decimal point, capital ASCII letters in the codes and in the magic, and the `|` separator. All Hebrew lives in the service (item 10).

### 1.2 Format, version 1

```text
AGTGQ|1|<login>
E|<next_seq>|<latch_anchor>|<s9_mask>
N|<snapshot fields, item 2>
V|<seq>|<code>|<server_t>|<local_t>|<state>|<pnl_mode>|<balance>|<equity>|<pnl>|<limit>|<x1>|<x2>|<x3>|<x4>|<x5>|<x6>|<x7>|<x8>
C|<checksum>
```

- `AGTGQ` differs from `AGHALT`, `AGSTATE`, `AGFLOOR` and `AGPEAK`, so no loader can take one file for another.
- `E`: the number the next event takes, and the S9 latch of item 7: the day anchor it belongs to and one bit per level fired.
- `N`: the snapshot, rewritten with every write (item 2).
- `V`: one line per unacknowledged event, in ascending `seq`, at most 50 (plan 6.4.4). `server_t` is `TimeCurrent` and `local_t` is `TimeLocal` at the event, as integer seconds. `state`, `pnl_mode`, `balance`, `equity`, `pnl` and `limit` are the common lines of every message (plan 5). `pnl_mode` 0 is ACTIVE: `pnl` is the day result `g_ag_last_pnl` and `limit` the enforced limit. `pnl_mode` 1 is LOCKED: `pnl` is equity minus `base_snap` and `limit` is `limit_snap`, the D2D4-3(a) shortcut the plan's field map names. `pnl_mode` 2 is not computed yet. `x1` to `x8` depend on the code (1.11); an unused field is 0. Money is printed at 2 decimals.
- `C`: `AgChecksum` (`Persist.mqh:95`) over every byte above it, the convention of the other four files.

### 1.3 Who writes

The EA alone, and within the EA only the instance that owns the mutex (`g_owns_mutex`). A refused instance never writes it (1.10). Every write goes through `AgAtomicWrite` (`Persist.mqh:112-135`): a `.tmp` file, `FileFlush`, then `FileMove` with `FILE_REWRITE`. For this one file the write is quiet. Today a failed open or rename raises the ALERT "state-write failure" (`Persist.mqh:123`, `:131`), which SPEC 6 makes mandatory for the lock and halt files; the queue is neither, so `AgAtomicWrite` gains an optional quiet flag whose default keeps every existing call exactly as it behaves today, and the queue passes it. A failed queue write journals `alerts queue write deferred|attempts=<n>` at most once per `AG_LIFE_INTERVAL_SECONDS`, is retried on the next tick, and never raises a popup.

When the EA writes: at most once per tick, at the end of OnTimer and also just before the SAFE_HALT return at `EA:1296`, so SAFE_HALT ticks write too; and only when something changed: an event was pushed, events were forgotten after an acknowledgement, or the snapshot is `AG_LIFE_INTERVAL_SECONDS` old. And once in OnDeinit, synchronously, for the stop event (item 7, TG-13).

### 1.4 Who reads

The service, read only: `FileOpen` with `FILE_READ | FILE_TXT | FILE_ANSI | FILE_SHARE_READ | FILE_SHARE_WRITE`, every line read, the handle closed at once. The service never opens the file for writing, never moves, copies or deletes it, and calls no `AgAtomicWrite` (static row TG-S11).

The EA reads it once, in OnInit, right after `AgMutexAcquire` succeeds and before any branch that returns, with the same flags, so a service read in flight cannot fail the load. If the open still fails, the load is retried on later ticks. Until it succeeds nothing is written, never loaded never written applied by choice, and events pushed in the meantime are held in memory and appended after the loaded ones.

### 1.5 Who deletes

Nobody. No program deletes the queue file. The EA forgets events from its own memory once the service has acknowledged them, and its next write is the shorter list. A file that fails its checksum or does not parse at load is quarantined by the EA under a free name, the `AgStateQuarantinePath` pattern (`Persist.mqh:332`), never deleted; the EA then starts an empty queue, journals one WARN and pushes an S17 event naming the queue. The lock artifact FINAL does not reach this file, which carries no lock state; its discipline is applied by choice.

### 1.6 The acknowledgement

One global variable, `AG_TGACK_<login>`: the `seq` of the last event the service has sent, merged or suppressed (1.9). The service writes it after each such event and calls `GlobalVariablesFlush`; nothing else writes it. The EA reads it once per tick with `GlobalVariableGet`, which does not wait, and forgets every event at or below it. At load the EA numbers on from the larger of `E.next_seq` and the acknowledgement plus one, so a queue file lost while the acknowledgement survives can never reuse a number the service has already passed. If the service ever reads a file whose `E.next_seq` is at or below its acknowledgement, the queue was reset, the file and the variable both lost, and the service sends every event the file holds, which are all new.

### 1.7 Atomicity, and no partial read

The rename is atomic: a reader opens either the whole previous file or the whole next one. The service acts only on a file whose header, `E`, `N` and `C` lines all parse and whose checksum verifies; anything else is a read not taken, retried on the next loop, and nothing is half applied. A read that meets the rename fails to open or fails the check, with the same outcome. Whether `FileMove` with `FILE_REWRITE` fails while the service holds the target open for reading on this platform: UNKNOWN, measured at TG-SV-L1 by the count of `alerts queue write deferred` lines. Either way the result is a deferral of at most one tick, never a partial file.

### 1.8 The EA never blocks and never waits

Every file call is one call that returns at once on failure. The EA holds no lock and makes no handshake. It reads one value the service writes, the acknowledgement, and acts on it only by forgetting events. If the service never runs, the EA's behaviour is unchanged except that the queue fills to its bound (1.12). The EA's added work per tick is the producer, which touches memory only, one `GlobalVariableGet`, the four permission reads of item 8, and at most one small file write.

### 1.9 No event lost on a clean restart, and no duplicate flood

- An EA restart for any reason: OnDeinit writes the queue with the stop event before it releases the mutex heartbeat (item 7, TG-13), and the next image loads it and keeps every unacknowledged event. A hard kill loses only the events pushed after the last successful write, at most one tick's worth, the loss TG-5 (B) names.
- A service restart: the service reads the acknowledgement at start and sends only what lies above it.
- Order: the service sends strictly in `seq` order. An S2 held for the in place restart merge (plan 6.4.3, item 7) holds the events behind it until it resolves, at most 60 s, so the acknowledgement is always one high water mark.
- Duplicates: the one window is a service stop between a successful send and the acknowledgement write, which resends that one event once at the next start. Messages leave at least 3 s apart and a 429 `retry_after` is honoured (plan 6.4.5). The same class and key within 300 s is suppressed and counted, and the count rides on the next message of that class (plan 6.4.2); a suppressed event is acknowledged like a sent one. The catalog's own limits apply in the service: S17 once per file per day, S19 once per lock or per day, S21 once per 300 s.

### 1.10 A refused start

A refused init does not own the mutex and must not touch the queue the live instance writes. It sets one global variable instead, `AG_TGREFUSED_<login>`, to `TimeLocal() * 100 + <code>`, a single write that cannot tear: code 1, the percent input is not a list member; 2, the currency input is not a list member; 3, another instance is live. It is set beside each `AgRefuseInit` call (`EA:1062`, `:1082`), in OnInit, outside the protected functions. The service reports S3 from it at once if it is running, or at its next start if the value is newer than the last one it reported, which it keeps in a second variable it alone writes, `AG_TGREFSEEN_<login>`.

### 1.11 What the EA writes, and from where

The producer is one function, called at the end of OnTimer and just before the SAFE_HALT return. It compares this tick's globals with the ones it kept from the last tick and pushes events on the edges; OnInit resets what it keeps, so an in place re-init starts it afresh. Sweep.mqh pushes four events at its own emission sites, OnInit pushes two, and OnDeinit pushes the stop event. "Producer" below means the tick end function.

| Code | Plan row | Pushed by, when | x1 to x8 |
|---|---|---|---|
| S1 | S1 | producer: the first SYNCING exit after this init, to ACTIVE | percent input, currency input, live limit, enforced limit |
| S16 | S16 | producer: the first SYNCING exit after this init, to LOCKED | reason (1 DAILY_BREACH, 2 CORRUPT_STATE, 3 SWEEP_WITNESS), `locked_until`, source mask (1 the state file loaded unexpired at init, 2 the lock GV unexpired at init, 4 neither, so deal history), `limit_snap`, positions, pendings |
| S4 | S4 | producer: ACTIVE to LOCKED | crossed limit (1 the percent leg, 2 the currency leg, 3 the held floor, 4 the daily peak, by the plan's field map), `locked_until`, `limit_snap`, realized, floating, peak, positions, pendings |
| S8 | S8 | producer: after an expiry, the first completed ACTIVE pass (1, released) or the SYNCING exit to LOCKED (2, locked again) | 1 or 2, the expired or the new `locked_until`, the new day's enforced limit or `limit_snap` |
| S6C | S6 | Sweep.mqh, at the `sweep complete` line (`Sweep.mqh:703`) | positions closed, pendings deleted, attempts, failures, elapsed passes |
| S6H | S6 | Sweep.mqh, at the first hold of a ticket (`Sweep.mqh:324`) | ticket, 1 if an order, hold reason (1 session closed, 2 hard stop, 3 refuse, 4 trade mode disabled), next open |
| S6F | S6 | Sweep.mqh, at "flattened after hold" (`Sweep.mqh:648`) | ticket, 1 if an order |
| S7 | S7 | Sweep.mqh, at a close classified done on an accelerated pass (`Sweep.mqh:634`) | position ticket, attempt |
| S9 | S9 | producer: a level reached on a completed ACTIVE pass (item 7, TG-3) | level (50 or 80), the share in percent, enforced limit, room left to the lock level |
| S10 | S10 | producer: the connection sample (`EA:1282`) true again after 30 s or more | server stamp at the loss, server stamp at the return, the gap in seconds on the local clock |
| S12 | S12 | producer: the permission read of item 8, on each edge, in every state | 1 blocked or 0 restored, the blocking flag (1 to 4, in the order of `AgTradeBlockName`), the guardian state at the edge |
| S15 | S15 | OnInit, when the halt file was removed by hand (`EA:1164-1172`) | none |
| S17 | S17 | producer: the flag `AgAtomicWrite` sets on a loud failure, or a quarantine OnInit reported | file (1 state, 2 halt, 3 floor, 4 peak, 5 queue), 1 write failed or 2 quarantined at load |
| S18 | S18 | OnInit, after `AgMutexAcquire` took over a stale mutex | the stale mutex heartbeat's age in seconds |
| S19 | S19 | producer: in LOCKED, live inputs that differ from the captured ones (the condition of `EA:668-669`), once per lock; in ACTIVE, the live limit above the enforced one, once per day | 1 input ignored while LOCKED or 2 raise held, the entered percent or the live limit, the governing limit, the entered currency |
| S20 | S20 | producer: the day anchor `g_ag_last_anchor` advanced by more than 86400 s | old anchor, new anchor, the jump in seconds |
| S21 | S21 | producer: the Pnl.mqh failure counter moved, or the SYNCING dispatch reported the derivation not evaluable (`EA:1321-1323`), at most once per 300 s | 1 history read failed or 2 derivation not evaluable, count |
| S22 | S22 | producer: SYNCING for 300 s or more, once per occupancy | seconds, 1 disconnected or 2 history not stable |
| S24 | S24 | producer: the overwrite flag `AgMutexRefresh` sets | none |
| S3 | S3 | producer: the first tick in SAFE_HALT | 1 crash loop or 2 persisted from an earlier session, halt time, chain length |
| S2 | S2 | OnDeinit (item 7, TG-13) | the deinit reason, 0 to 9 |

The service makes the rest itself: S3 for a refused start (1.10), S11 when Telegram is reachable again, S13 through the hosted check, S14 (item 7, TG-4), the status message (item 6), the command reply (item 5), and the guardian liveness messages (item 4).

### 1.12 The bound

At most 50 unacknowledged events (plan 6.4.4). On overflow the EA keeps the oldest unacknowledged event and the newest 49 and forgets the ones between. The service sees the gap in `seq` and puts its size on the next message, in the "not kept" line of item 13.

### 1.13 The service's loop

One iteration, then `Sleep(1000)`, until `IsStopped()`:
1. Read the account login. On a change, start over for the new login.
2. Read `AG_HB_<login>` (item 3) and update the guardian liveness state (item 4).
3. Read the queue file (1.4). On a good read, take the snapshot and every event above the acknowledgement.
4. Read `AG_TGREFUSED_<login>` (1.10).
5. Make at most one network request, in this order: the oldest pending message, if 3 s have passed since the last send, no 429 window is open and no failure backoff is running (2, 4, 8 and so on up to 300 s, plan 6.1.3); else the network heartbeat ping, if due and the mutex heartbeat is fresh; else the command poll, if due (TG-14); else nothing. A status slot (TG-15) or a matched command adds a pending message.
6. After a successful send, write the acknowledgement and flush.

Every request carries the timeout constant, 2000 ms (plan 6.1.4), a compile time constant of the service. The service's waits cost the EA nothing: the two programs run on separate threads, and the EA reads nothing that waits on the service. When Telegram has failed for 60 s or more and a send then succeeds, the S11 notice goes first and the backlog follows, oldest first (plan S11). Any message sent more than 60 s after its event carries the delay line (plan 5).

## 2. The state snapshot

The `N` line of the queue file is the guardian's state as the service sees it. The EA rewrites it with every queue write, so it is never older than `AG_LIFE_INTERVAL_SECONDS` while the EA's timer runs, and it is atomic with the events because it is the same file.

```text
N|<local_t>|<server_t>|<build>|<state>|<reason>|<seconds_in_state>|<connected>|<block>|<pnl_mode>|<balance>|<floating>|<equity>|<pnl>|<limit>|<live_limit>|<enforced_limit>|<peak>|<peak_level>|<anchor>|<locked_until>|<limit_snap>|<base_snap>|<percent>|<currency>|<sweep_open>|<sweep_held>
```

The sources, all globals the existing code already keeps, read at the end of the tick: `state` is `g_ag_state`; `reason` `g_ag_lock_reason`; `seconds_in_state` `AgSecondsInState()`; `connected` `g_ag_obs_connected`; `block` item 8's read; `balance` `ACCOUNT_BALANCE`; `floating` `AgFloating()`; `equity` their sum, never an `ACCOUNT_EQUITY` read (D2D4-4(a)); `pnl`, `limit` and `pnl_mode` as in 1.2; `live_limit` `g_ag_last_limit`; `enforced_limit` `AgFloorEffectiveLimit(g_ag_last_limit, g_ag_last_anchor)`; `peak` `g_ag_peak_currency`; `peak_level` `AgPeakEffectiveLevel(enforced_limit, g_ag_last_anchor)`; `anchor` `g_ag_last_anchor`; `locked_until` `g_ag_locked_until`; `limit_snap` and `base_snap` the Q6 snapshot; `percent` and `currency` the live inputs; `sweep_open` and `sweep_held` the sweep's counts; `build` the label token `TG`. The two pure readers return exactly what the last ACTIVE pass enforced: `AgRatchetUpdate` returns either `AgFloorEffectiveLimit` or the live limit after seeding the floor with it, and `AgPeakUpdate` returns `AgPeakEffectiveLevel`, each leaving its globals as it used them (`Persist.mqh:761-876`, `:1075-1215`).

The service uses the snapshot for the status message and the command reply (items 5 and 6), for the day boundary of S14 (item 7, TG-4), and as the guardian's last known figures. Every message built from it states its age when it matters: if the mutex heartbeat is fresh and the snapshot is more than 90 s old, the status carries the age line of item 13, so old figures are never shown as current. When the guardian is not running (item 4), the service reads the balance itself, computes equity as balance plus `AgFloating()` from the shared Pnl.mqh, D2D4-4(a) again, and prints the day result as not computed.

Rejected, and recorded so they are not proposed again: the state in global variables, which carry numbers alone but which a reader cannot take as one consistent set without a lock; and a second snapshot file, one more file to protect for no gain over a line in the queue.

## 3. Network heartbeat gating

The service pings the ping URL every 60 s (TG-2.2), a GET with the 2000 ms timeout, and only while the mutex heartbeat is fresh. Fresh is the test `AgMutexAcquire` uses to refuse a second instance (`Persist.mqh:1230-1234`): the value of `AG_HB_<login>` above 0.5, and `TimeLocal()` minus it below `AG_MUTEX_STALE_SECONDS`, 10 s (`Persist.mqh:31`, FINAL at `LEDGER.md:2460` as at `31ac695`). The service includes Persist.mqh for that constant, so one value governs both programs, and both read the same local clock on the same computer, the mutex heartbeat's own clock under the exemption at `:2451`. The EA refreshes the mutex heartbeat first thing in every tick of every state, SAFE_HALT included (`EA:1219-1220`, `Persist.mqh:1265-1278`), so a fresh value means the EA's timer ran within the last 10 s. A ping therefore proves three things at once: the service runs, the guardian's timer runs, and the computer reaches hc-ping.com.

A stale, released (0) or missing value skips the ping and journals `alerts ping skipped|guardian=<stale|released|missing>|age=<n>` once, on the edge, and item 4 alerts at once. A failed ping is journaled and retried at the next interval, never sooner.

What the hosted check, 60 s period plus 240 s grace (TG-2.3), then covers, each case reported through the check's own Telegram integration about 5 minutes after the last ping:
- the computer off, asleep or without power;
- the terminal closed, killed, crashed or frozen;
- the service stopped, removed, never added, or its ping URL field empty, so that a provisioned check goes down by design;
- the EA removed, refused at init, stopped by a runtime error, its timer never armed, or its timer blocked for 10 s or more;
- the internet down on that computer, or hc-ping.com unreachable from it.

What it does not cover, and what does: the guardian alive but not protecting, in SAFE_HALT (S3), in SYNCING for 300 s (S22), or with trading disabled (S12); the broker link down while the internet works, since the mutex heartbeat stays fresh (S22 while SYNCING, S10 at the return); Telegram refused or unreachable while the pings flow (S11 when it returns); Telegram itself down for the owner, which silences both channels alike, TG-2.1 (C), email, not having been ruled.

## 4. The guardian stopped while the terminal runs

The service reads `AG_HB_<login>` on every loop, about once a second, and keeps a liveness state:
- fresh, as in item 3;
- stale: a value above 0.5 that is 10 s old or more, with no release;
- released: 0, the marker `AgMutexRelease` writes in a clean OnDeinit (`Persist.mqh:1280-1288`);
- missing: no such variable.

On the move from fresh to stale the service alerts at once with the "not responding" message of item 13, and its pings stop, so the hosted check follows about 5 minutes later if nothing changes. This covers what no EA code can report: a timer that never armed (plan 3.1 row 13), a runtime error that stops the EA, a timer blocked by anything for 10 s or more. When the value turns fresh again without a new start, the service sends "responds again" with the length of the gap; a new start, S1 or S16, closes the episode instead.

On the move to released, the stop event is already in the queue, because OnDeinit writes it before the release (item 7, TG-13), and the service follows TG-13's timing. If no S2 has appeared 5 s after the release, it sends "not responding" with the reason line "not recorded".

Missing or stale when the service itself starts: the terminal's own start races the EA's init, so the service waits 60 s from its start for a fresh value before it alerts "not running", a compile time constant, UNRULED. It alerts once per episode.

A refused start leaves the variable as the live instance keeps it, or stale or missing if no instance runs; the refusal code (1.10) names the reason in the S3 message, which then replaces the generic "not running".

## 5. The command

TG-8 (B): one read only command, the exact text:

```text
בדוק אותי
```

Polling: `GET https://api.telegram.org/bot<token>/getUpdates?offset=<o>&timeout=0&allowed_updates=["message"]`, the parameter URL encoded, one request per due poll from the service's loop, never from the EA.

**TG-14. The command poll interval.** TG-8 (B), FINAL at `LEDGER.md:2876` as at `ba8ddee`, reads "polled from `getUpdates` at most every 60 s". That is read here as no more often than once per 60 s, so every option polls at 60 s or slower. Under TG-1 (B) a poll costs the guardian nothing: it is one HTTPS request of up to 2000 ms on the service's own thread, which can hold back one pending message by as much.
- (A) 60 s. 1440 polls a day. A reply within about 60 s of the command, plus the send.
- (B) 120 s. 720 polls a day. A reply within about 2 minutes.
- (C) 300 s. 288 polls a day. A reply within about 5 minutes.

Recommendation: A.

The offset. Kept in memory only, as TG-8 (B)'s text says. The first poll of a service session uses offset 0, which returns whatever Telegram still holds unconfirmed; each response sets the offset to its highest `update_id` plus one, so the next poll confirms everything returned and no update is handled twice in one session. After a service restart the unconfirmed backlog comes back once, and a command older than 120 s by its `message.date` is ignored with no reply, so a stale command is never answered after an outage; 120 s is a compile time constant, UNRULED.

The exact match rule. A reply is sent only when all four hold:
1. The update carries `message`: not `edited_message`, not `channel_post`, nothing else.
2. `message.chat.id`, as decimal text, equals the configured chat id field character for character.
3. `message.text`, after JSON unescaping (`\"`, `\\`, `\/`, `\n` and the rest, and `\uXXXX` with surrogate pairs) and UTF-8 decoding, equals the text above exactly: nine code points, U+05D1 U+05D3 U+05D5 U+05E7 U+0020 U+05D0 U+05D5 U+05EA U+05D9, compared with `==` on MQL5 strings. No trimming, no normalizing, no folding, no prefix or partial match: a space before or after, a line break, a direction mark such as U+200F, a punctuation mark or a third word makes it a different text.
4. `message.date`, which Telegram gives in UTC seconds, is within 120 s of the service's `TimeGMT()`.

The reply is the status message of item 6 with the values of that moment, sent to the configured chat id only, in the same send order, spacing and backoff as every other message. Several matching commands in one poll get one reply.

Anything else is ignored with no reply: any other text, the exact text from any other chat, an edited message, a stale command. Their content is never journaled; the poll journals counts only (0.4). A 409 answer, which Telegram gives when a webhook is set on the bot or a second program polls the same token, is journaled as `alerts failed|class=poll|http=409|...`, and the poll backs off; clearing it is the owner's act. RAISED, NOT RULED.

Read only by construction. The service writes nothing the guardian reads except the acknowledgement, which can only make the EA forget events already sent. It has no path to an input, a file the EA loads, a lock, a limit or the state machine (static row TG-S11). No command can unlock, widen a limit or disable the guardian, as TG-8 (B) requires.

## 6. The periodic status

A visible message every 4 hours stating that the guardian is alive, with the account state fields of plan 5 (`:2900` as at `ba8ddee`); the same message is the command reply. It is built from the snapshot (item 2) and the liveness state (item 4). When the mutex heartbeat is fresh it says the guardian runs, in the state it is in; when it is not, it says so. A slot missed while the service was not running is not sent late; the next slot comes as scheduled.

**TG-15. The schedule anchor.**
- (A) The computer's local clock: 00:00, 04:00, 08:00, 12:00, 16:00 and 20:00, read with `TimeLocal`. Independent of the broker feed and of the day anchor. It never falls on the 01:00 server summary of TG-4 while the server keeps Israel's offset. The slots follow the local clock across a DST change.
- (B) The server clock, aligned to the day anchor: 01:00, 05:00, 09:00, 13:00, 17:00 and 21:00 server, the snapshot's anchor plus multiples of 4 hours, against `TimeCurrent`. Tied to the trading day the guardian measures. The 01:00 slot falls on the TG-4 summary, two messages at once. `TimeCurrent` stops with the feed, in the nightly break or a disconnect, so a slot can come late exactly when proof of life matters most.
- (C) Every 4 hours from the service's own start, on the local clock. The simplest. The times move with every restart and cannot be known in advance.

Recommendation: A. Proof of life is a local clock matter, the ground of the exemption at `LEDGER.md:2451` as at `31ac695`, and (A) never doubles with the summary.

Every option sends two slots at night. A silent delivery is not ruled and is not used.

## 7. Plan option texts that assumed the EA sends, read under TG-1 (B)

Each is quoted from plan 7 and is FINAL at the lines of 0.1.

- TG-2.1 (A): "The ping URL is entered as an EA input field, as TG-6 places the token. S13 then needs no EA code beyond the ping." Under TG-1 (B), with TG-6 as amended, the ping URL is an input of the service and the EA has no ping code at all; S13 needs only the service's gated ping (item 3) and the hosted check.
- TG-2.2, "network heartbeat every 60 s", the value of option (A): sent by the service, once per 60 s, and only while the mutex heartbeat is fresh.
- TG-3 (B), "Two levels, 50 and 80 percent, each once per day. Re-armed if the share falls back 10 points below the level." Detected in the EA by the producer at the end of each tick, from `g_ag_last_pnl`, the enforced limit and the day's peak through the two pure readers (item 2), on completed ACTIVE passes only and outside every protected function; the share is the plan's, the day reference minus pnl over the enforced limit, the day reference being `AgPeakEffectiveLevel` plus the enforced limit. The service renders and sends. Read with both clauses together: a level fires when the share reaches it while it is armed, disarms when it fires, and re-arms when the share falls to 10 points below it; every level re-arms when the anchor advances. Executor reading, UNRULED. The latch lives in the queue file's `E` line, so a restart neither repeats a level nor loses one.
- TG-4 (B): "Triggered by the existing `day rollover` line (EA:864) or, on a locked day, by the expiry (EA:689)." Under TG-1 (B) no EA code is added at either line. The service makes S14 when the snapshot's anchor advances by exactly 86400 s: it folds the window from the old anchor to the new one with the shared `AgRealizedRunFold` (Pnl.mqh), where the F12 whitelist and the Q3 formula live in their one place, for the day's closed result and its peak; it counts the S4 and S16 events it handled in that window; and it takes the new day's limit from the snapshot. The anchors are the EA's own, so no second day boundary exists, and on a locked day the anchor advances at the first ACTIVE pass after the expiry, which is the expiry trigger in effect. A jump of more than one day sends S20 and no summary.
- TG-5 (B): "A persisted queue file ... Atomic write through `AgAtomicWrite` ...". Under TG-1 (B) the queue is the channel between the two programs (item 1), and `AgAtomicWrite` gains the quiet failure mode of 1.3 for this file alone.
- TG-6, the amended ruling, read against plan 6.2 and 6.7 E: the three values are entered when the service is added (item 9), never in the EA's attach dialog; the EA keeps its four inputs; the `alerts config` line of plan 6.2.2 becomes the service's start line (0.4). The consequence "Every new input adds validation vector cost" falls on the service's pure input checks and not on the EA.
- TG-8 (B): "polled from `getUpdates` at most every 60 s ... It costs one more request on the polling ticks". The polling runs in the service's loop (item 5, TG-14); the "polling ticks" are service iterations, and the EA's ticks carry no request.
- TG-9 (A): "The installer's manifest and the export carry the new file." Under TG-1 (B) there are four new source files and a second compiled program (item 11, TG-16).
- TG-10 (A): "receiving the build by a deploy script under the 2026-09-06 hand." The deploy script copies the two programs and the vectors script, and the owner then adds the service on the demo terminal (item 9).
- TG-13 (B): "For reasons 1, 4 and 9, one send attempt inside OnDeinit with a 1500 ms timeout, after the halt clean mark, the mutex release and the queue write. Queue only for every other reason. A refused start queues. Fast news of a removal or a close, if acceptance shows WebRequest works there (3.2). The S2 entry stays queued if the attempt fails." Under TG-1 (B) the EA sends nothing, for any reason. In OnDeinit, for every reason, the EA keeps its order of local writes and adds one: the halt clean mark (`EA:1423-1427`), then the stop event S2 with its reason pushed and the queue written through `AgAtomicWrite`, then the mutex heartbeat released (`EA:1432-1433`). A released mutex heartbeat therefore means the stop event is already on disk. The service sends it as follows.
  - Reasons 1 and 4, removed or chart closed: at once, on its next loop, about 1 s later. This is the fast news the option names.
  - Reasons 2, 3, 5 and 7, an in place re-init: held up to 60 s; a following S1 or S16 makes one "restarted" message (plan 6.4.3), and otherwise S2 goes alone.
  - Reason 6, an account change: as reasons 2, 3, 5 and 7.
  - Reason 0: at once.
  - Reason 8, a refused init: no S2, since a refused instance owns no mutex and writes no queue. The refusal variable of 1.10 carries it instead, so "a refused start queues" becomes "a refused start sets the refusal variable", reported at once if the service runs, or at its next start.
  - Reason 9, the terminal closing: the service is being stopped at the same moment. On its stop signal it makes one last pass: it reads the queue once more and, if an unsent S2 with reason 9 is there, makes one send attempt with a 1500 ms timeout, the option's own figure, writes the acknowledgement on success, and exits. Whether the stop signal reaches the service before or after the EA has written S2, whether the network is still open then, and how long the terminal lets a service finish: UNKNOWN, measured at TG-L1 and TG-SV-L4. When the attempt fails or never happens, S2 stays unacknowledged in the queue and is sent at the service's next start with the delay line, and the hosted check reports the silence after about 5 minutes if the terminal stays closed.
- Plan 6.1, enforcement first and the pump in OnTimer: void under TG-1 (B). The EA makes no request, so the one request per tick, the 2000 ms wait inside OnTimer, the skip on a tick that swept, and the worst case of plan 6.1.5 no longer describe the EA. The service has its own loop (1.13), and TG-M is restated in item 12.
- Plan 6.6, the network heartbeat from the same pump, in every state, skipped on a tick that swept: in the service, gated on the mutex heartbeat (item 3), which the EA refreshes in every state, SAFE_HALT included, so the network heartbeat still follows the guardian in every state.
- Plan 3.1's column "Send at that moment" now reads "queued at that moment, sent by the service on its next loop", except where no EA code runs, rows 13 and 42; row 13 is now reported by the service (item 4). Plan 3.3 fact 6, "An MQL5 Service program can call WebRequest", becomes load bearing: UNKNOWN until TG-SV-D.

## 8. S12 in ACTIVE

Where the reads go. `AgTradeAllowed` (`Sweep.mqh:176-183`), the four reads named through `AgTradeBlockName`, is called once per tick in OnTimer: after the connection sample (`EA:1282`); before the LIFE line and the banner refresh (`EA:1292-1294`), so the same tick's banner and LIFE line reflect it; and before the SAFE_HALT return (`EA:1296`), so it runs in every state. No other read site is added, and the sweep's own read inside `AgSweepPass` stays as it is.

How often. Once per tick, 1 s.

What it raises.
- Telegram, in every state: one S12 event when a blocking flag appears and one when it clears, keyed on the block alone, so a state change during a block sends nothing extra (1.11).
- LOCKED: nothing local is added. The sweep keeps its `sweep blocked` journal line at `AG_SWEEP_CADENCE_PASSES`, its CANNOT_TRADE ALERT at entry and its restored ALERT at exit (`Sweep.mqh:451-474`), and the banner sub-condition (`EA:226-230`), exactly as today.
- ACTIVE, under the ruling at `:2908` as at `ba8ddee`: the journal line `trading blocked|state=<name>|guardian=ACTIVE` at entry and every 30 ticks while the block lasts, and `trading restored|state=<name>|guardian=ACTIVE` at exit; one Alert at entry, "CANNOT_TRADE while ACTIVE: <name>; a breach would still lock the account, and the guardian could not close positions until trading is restored", and one at exit, "trading restored while ACTIVE: <name> cleared"; and on the banner's ACTIVE line the sub-condition `CANNOT_TRADE: <name>` while the block lasts.
- SYNCING and SAFE_HALT: the journal lines and the Telegram event only. No local Alert and no banner text there, those two states not being ruled. RAISED, NOT RULED.
- Entering ACTIVE while blocked, after an expiry, counts as an entry in ACTIVE. Leaving ACTIVE while blocked, at a breach, ends the ACTIVE episode with no exit Alert, and the sweep raises its own entry Alert on its first LOCKED pass.

The cadence. The ruling sets it by the FINAL at `LEDGER.md:2387` as at `31ac695`, Q3/F2: "continuous loud alerting (journal + Alert + chart banner)". `SPEC:99` reads "continuous" under ENF-14(b): the journal line at the cadence, the banner sub-condition, and the popup once at entry and once at exit, not at the cadence. ACTIVE takes the same reading, with the 30 tick cadence of `AG_SWEEP_CADENCE_PASSES` counted on its own tick counter, since no sweep pass runs in ACTIVE. Executor reading, UNRULED.

How it relates to that FINAL. Q3/F2 fixes, for every trade disallowed state: detect only; continuous loud alerting on the journal, the Alert and the chart banner; an immediate sweep the moment trading is restored; and each state enumerated and logged distinctly. Extending detection to ACTIVE changes none of it. LOCKED's alerting and its sweep are untouched. Enforcement stays detect only: nothing is swept outside LOCKED (ENF-21(a)), and the read feeds no decision. ACTIVE now carries the FINAL's three local channels, which it did not carry before, at the FINAL's cadence as SPEC reads it. "Immediate sweep on restoration" has nothing to act on in ACTIVE, where no sweep runs, so it is unchanged. No stop arises.

Not a decision path. The read's results are read by the banner builder, the LIFE line builder, the two journal lines, the two Alerts and the producer, and by nothing else: no state, transition, breach test, sweep branch or expiry reads them, which static row TG-S16 checks by grep, the Stage 6 discipline. The four flags are the ones `AgTradeAllowed` reads. An investor login reads as `ACCOUNT_TRADE_ALLOWED` false. A closed or close only symbol session stays with the sweep's own pre check in LOCKED, because it belongs to one symbol and not to the account.

### 8.1 The SPEC amendment, drafted for the owner and not applied

In place under the ruling at `:2908` as at `ba8ddee`, with no A7, the SPEC amendment series having closed at A6 (owner ruling of 2026-09-03, R10 build review). UNRULED draft.

`SPEC:42`, now: "CANNOT_TRADE is a tracked and logged sub-condition inside LOCKED (section 4.4), not a state." Proposed: "CANNOT_TRADE is a tracked and logged sub-condition, not a state: inside LOCKED it belongs to the sweep (section 4.4); inside ACTIVE it is raised by the permission read of every tick (owner ruling of 2026-10-20, S12 in ACTIVE), as alerting only, with no transition and no effect on any decision."

`SPEC:99`, appended after "not at the cadence.": "The same four reads run once per tick in every state (owner ruling of 2026-10-20, S12 in ACTIVE). In ACTIVE a blocking state raises the same three local channels at the same cadence: the `trading blocked` journal line at the cadence, the CANNOT_TRADE sub-condition on the chart banner, and one Alert at entry and one at exit. In SYNCING and SAFE_HALT it is journaled. Nothing is swept outside LOCKED (ENF-21(a))."

`SPEC:133`, a new bullet after it: "Trade permission: `trading blocked|state=<name>|guardian=<state>` at entry and every 30 ticks while the state lasts outside LOCKED, and `trading restored|state=<name>|guardian=<state>` at exit."

`SPEC:134`, now: "Alert popups mandatory for: breach, lock, unlock, state-write failure, cannot-trade-while-locked, SAFE_HALT." Proposed: "Alert popups mandatory for: breach, lock, unlock, state-write failure, cannot-trade-while-locked, cannot-trade-while-active, SAFE_HALT." Appended to the same bullet: "Cannot-trade-while-active cadence by the same reading: one popup at entry to the blocked state and one at exit."

`SPEC:135`, appended: "Under ACTIVE the banner carries the CANNOT_TRADE sub-condition while an account-wide state blocks (owner ruling of 2026-10-20, S12 in ACTIVE, local alerting)."

Other SPEC lines the build touches, named and not drafted, for the owner to direct: `SPEC:10`, network visibility listed as deferred; `SPEC:12`, the network heartbeat said not to exist in v0; `SPEC:16-26`, the layout, which gains the service, the three includes and the queue file; `SPEC:30`, OnTimer's list, which gains the producer and the permission read; `SPEC:35`, the static structure rule, which gains the network reachable from the service alone; and `SPEC:137`, the dormant secrets clause, now live in the service. No ruling yet names the SPEC edits of this build, as ENF-28(a) did for the enforcement build.

## 9. Service lifecycle

Every step on a terminal is the owner's, written as dictation. The executor performs none of them and never sees the token, the chat id or the ping URL. Names and menu wording are as recalled and are confirmed at TG-SV-D.

A. Before the service's first run on each terminal, the WebRequest allow list holds exactly `https://api.telegram.org` and `https://hc-ping.com` (plan 6.7 D; on the live terminal the owner states this is done). Whether the allow list under Tools, Options, Expert Advisors applies to a service as it does to an EA: UNKNOWN, read at TG-SV-D from the first `alerts sent` line or an `alerts failed|...|err=4014` line.

B. Add and configure the service, on the demo terminal of TG-10 (A) after the deploy script, and on the live computer after the installer:
1. Start MetaTrader 5 and open the Navigator (Ctrl+N).
2. Open Services and find `AccountGuardianAlerts` where TG-16 places it.
3. Right click it and choose Add Service.
4. In the properties window that opens, on the Inputs tab, paste the bot token into `TelegramToken`, the chat id into `TelegramChatId`, and the check's ping URL into `NetworkHeartbeatUrl`.
5. Do not press Save in the inputs window: a saved preset carries the token (plan 6.2.5).
6. Press OK.
7. If the new instance under Services does not show as running, right click it and choose Start.
8. In the journal, read `alerts service started|build=TG|login=<n>|telegram=on|network_heartbeat=on|command=on`, then the first `alerts ping|http=200|...` within about 60 s.
9. Paste those lines back.

One instance per terminal: a second instance would send every message twice.

C. Change a value: right click the instance, Stop; right click it, Properties; change the field; OK; right click it, Start. Read the start line again.

D. Remove: right click the instance, Stop, then Remove. The guardian runs on, unaffected. Telegram, the command and the network heartbeat stop, and the hosted check reports the silence after about 5 minutes.

E. Upgrade: stop the instance before a new ex5 is copied, then start it. The installer requires the terminal closed in any case (IN-12 (a)).

Restart with the terminal. Whether a service that was running when the terminal closed runs again when the terminal starts, with no owner action: UNKNOWN. Recalled from the MQL5 reference and not fetched, since this work makes no network call: it does. Not relied on: TG-SV-L4 closes the terminal, reopens it and reads the service's start line with no owner step between.

Where the terminal stores the service's input values on disk: UNKNOWN. The executor reads no terminal configuration file and nothing under a data folder beyond the one listing named at the head of this document. Measured at TG-SV-L10 without exposing any secret: the owner adds a second, test instance whose `TelegramChatId` holds the marker `AGMARKER20261021` and whose other two fields stay empty, so it sends nothing; closes the terminal; searches the data folder for the marker in ANSI and in UTF-16LE with the owner's own `Select-String` commands; reports only the paths of the files that hold it; then reopens the terminal and removes the test instance. Whatever file that names carries the token as well, in plain text, and falls under plan 6.2.5: never shared, never copied into a repository, never banked as evidence.

## 10. Hebrew text

All Hebrew lives in `MQL5/Include/AccountGuardian/AlertText.mqh`, saved as UTF-8 with a byte order mark, `EF BB BF`, the encoding `AccountGuardian.mq5` already carries (plan 3.1). MetaEditor reads a file with that mark as UTF-8; how it reads one without the mark is not relied on (plan 6.5.2). Every other new file is ASCII only, the EA's own source keeps zero bytes above 127 after its mark, and the queue carries no Hebrew (item 1).

At send time the service builds the message as an MQL5 string, escapes it for JSON, converts it with `StringToCharArray(text, bytes, 0, WHOLE_ARRAY, CP_UTF8)`, drops the trailing zero, and posts it with `Content-Type: application/json; charset=utf-8` (plan 6.5.1). The command is compared after the reverse conversion (item 5).

It is verified at the plan's three levels (plan 6.5.4):
- static, TG-S7: the include starts `EF BB BF`, decodes as strict UTF-8, holds no U+2013, U+2014 or U+05BE, and each template's Hebrew character count equals the drafts block of item 13, counted by a script and committed with the build;
- vectors, TG-S8: each template rendered with the example values of item 13 gives UTF-8 bytes whose md5 equals a value computed independently by a script from item 13's text;
- live, the TG-L and TG-SV-L rows: the owner's pasted received text equals the rendered draft with the live values.

The build label of this build is `TG`. The EA's init line reads `init|build=TG|...`, the label at `EA:1052` that reads `PK` today; the service's start line reads `alerts service started|build=TG|...`; and every message ends `build=TG`. When the service's own label differs from the label in the snapshot, that last line reads `build=<EA label>|service=<service label>`.

## 11. Installer, manifest and export

The changes the build makes, each under IN-1 to IN-29 as ruled:
- `scripts/make-manifest.ps1`: the four new sources join `$shippedFiles` (`make-manifest.ps1:22-33`), so `installer/manifest.txt` grows from 10 lines to 14: `MQL5/Services/AccountGuardian/AccountGuardianAlerts.mq5`, `MQL5/Include/AccountGuardian/AlertQueue.mqh`, `MQL5/Include/AccountGuardian/AlertJson.mqh` and `MQL5/Include/AccountGuardian/AlertText.mqh`.
- `scripts/export-release.ps1`: no change to its file list, which comes from the manifest (`export-release.ps1:96-108`); the release `.gitignore` it writes (`:119`) gains `installer/compile-service.log`. Its secrecy search reaches the new files with the rest.
- `installer/install.ps1`: check 6 also knows the service's target, an unknown file there stopping the installer (IN-15 (a)) and a present one being an upgrade replaced in place (IN-14 (a)); check 7 probes write access where the service lands; a second compile, of the service, in the download tree, `metaeditor64.exe /compile:"<download>\MQL5\Services\AccountGuardian\AccountGuardianAlerts.mq5" /include:"<download>\MQL5" /log:"<download>\installer\compile-service.log"`, read as the first is, its Result line and a fresh ex5 required (standing rules 6 and 7); a second copy and its landed md5; the done stage naming two files; and the attach steps followed by the steps of item 9 B. Every message stays English then Hebrew in the record file and English on the console, under IN-21 as replaced.
- `README.md` (TG-9 (A)): Hebrew setup steps in the Hebrew only README, covering the bot and the chat id, the hosted check, the allow list, and adding the service with its three fields. The sentence that says the installer copies one file into the terminal changes with it, and IN-S6 as redefined applies.
- Static rows IN-S3, the installer's write set, and IN-S5, the manifest, are measured again on the new set.

**TG-16. Where the service ex5 lands, under the installer's one folder departure.** The ratified departure TWO of 2026-09-29 (`LEDGER.md:2726` as at `31ac695`) reads "one folder, `MQL5\Experts\AccountGuardian`, may be created in the chosen data folder on a fresh install". Measured on this computer: the development terminal's data folder carries `MQL5\Services`, created with the terminal (head of this document). On a customer's machine: UNKNOWN.
- (A) `MQL5\Services\AccountGuardianAlerts.ex5`, straight into the existing Services folder. No folder is created beyond the ratified one. Check 4 also requires `MQL5\Services` to exist and stops with a message naming the manual route if it does not; the installer never creates it. Check 6 knows this one file name there and leaves every other file in Services alone. The Navigator lists the service at the top of Services. Removing it by hand is one more file.
- (B) `MQL5\Services\AccountGuardian\AccountGuardianAlerts.ex5`, in a second created folder that mirrors the EA's. It needs a ruling beyond departure TWO, which names one folder. Check 6 applies the IN-15 (a) rule to that folder as it does to the EA's. Removing it by hand is a folder.
- (C) The installer does not place the service: it compiles and copies the EA only, and the README tells the customer to copy the service by hand. The write set stays as it is. A manual step comes back where IN-24 (a) removed the manual route.

Recommendation: A. It stays inside the departure as ratified, creates nothing new, and its one added check reads a folder the terminal's own setup creates.

The deploy script of TG-10 (A) for the development terminal, under the 2026-09-06 hand, copies the service to the same target TG-16 rules.

## 12. Acceptance rows added for the service

Every row closes on quoted evidence carrying the build: the EA's `init|build=TG` line, the service's `alerts service started|build=TG` line, and both landed ex5 md5 values the owner pastes from `Get-FileHash`. Per standing rule 7 an md5 is recorded with the label and is not identity by itself. Every live row is the owner's; the executor reads only what the owner pastes or banks. A live row failure is reported at once as a numbered defect.

Static, at the build, by the executor:
- TG-S9. The service compiles at `Result: 0 errors, 0 warnings`, every `including` line inside the worktree; with the EA and the two vectors scripts, plan TG-S1 becomes four compiles.
- TG-S10. The EA has no network path: a grep of `WebRequest`, `SendNotification`, `SendMail`, `SocketCreate` and `SocketConnect` over the EA and every include it compiles returns zero; `WebRequest` appears only in `AccountGuardianAlerts.mq5`, and every call passes the timeout constant. This replaces plan TG-S5.
- TG-S11. The service writes nothing the guardian reads: its source and its includes hold no `FileOpen` with `FILE_WRITE`, no `FileMove`, `FileCopy`, `FileDelete` or `FolderDelete`, no call of `AgAtomicWrite`, no `GlobalVariableSet` or `GlobalVariableDel` except on `AG_TGACK_<login>` and `AG_TGREFSEEN_<login>`, and none of the ENF-S2 trade API family.
- TG-S12. The queue, by vectors: a serialize and parse round trip for every code; a changed byte fails the checksum; a cut file is refused; the overflow keeps the oldest unacknowledged event and the newest 49; events are forgotten at an acknowledgement; numbering goes on after a reload; every byte is ASCII.
- TG-S13. The command, by vectors on fixed `getUpdates` bodies: the exact text matches in raw UTF-8 and in `\u` escaped form; a trailing space, a leading U+200F, another chat id, an `edited_message` and a stale date do not.
- TG-S14. The schedule, by vectors on the TG-15 slot function at fixed instants, as TG-15 rules.
- TG-S15. Plan TG-S4 with no exception: the five protected functions and `AgTransition` byte identical by md5, no hook line named, since this design needs none.
- TG-S16. The S12 read is no decision path: every reference to its globals lies in the banner builder, the LIFE line builder, its two journal lines, its two Alerts and the producer, and none in the five protected functions or in a branch of `AgSweepPass`.

Deploy:
- TG-SV-D. On the demo terminal of TG-10 (A): the deploy script run by the owner and both landed md5 values pasted; then, before any restart, the EA's `init|build=TG` and `limits accepted|...` with no ALERT between; then the service added per item 9 B, its start line and first ping line pasted; where the service's journal output appears, recorded; the first message received and its text pasted.

Live, each closing on the owner's pasted received text and the matching `alerts sent|seq=<n>|class=<code>|http=200|ms=<n>` lines:
- TG-SV-L1. The handoff: S1 at the attach received; the service's `seq` read; `AG_TGACK_<login>` read in the F3 dialog by open, read, close, reopen, read (standing rule 2) and equal to it; the count of `alerts queue write deferred` lines over the window recorded.
- TG-SV-L2. A service stop and start: with the instance stopped, a chart period change, so S2 with reason 3 and then S1; then the instance started: exactly one "restarted" message, and no repeat of any message sent before the stop.
- TG-SV-L3. The EA removed while the service runs: S2 "removed" within 5 s; `alerts ping skipped|guardian=released` once; the hosted check "down" after about 5 minutes; the EA attached again: S1, the pings back, the check "up".
- TG-SV-L4. The terminal closed and reopened with the service running: the reason 9 outcome recorded, sent at the close or late at the next start with the delay line; and the service's start line after the reopen with no owner step between, or the step it needed.
- TG-SV-L5. The command from the configured chat: one status reply within the TG-14 interval and a few seconds; the same text with a trailing space, and another text: no reply; if the owner has a second Telegram account, the exact text from it: no reply.
- TG-SV-L6. One periodic status at a TG-15 slot.
- TG-SV-L7. A channel off: an instance with an empty token reads `telegram=off:empty` and still pings; one with an empty URL reads `network_heartbeat=off:empty`; the EA's journal shows no change.
- TG-SV-L8. Telegram refused: `https://api.telegram.org` removed from the allow list during an event and restored after 2 minutes; `alerts failed|...|err=4014` journaled; the S11 notice, then the delayed messages in order. This replaces the sending half of plan TG-L8.
- TG-SV-L9. A refused start: a second EA attached to another chart; the S3 "second instance" message from the refusal variable, and the live instance's messages unaffected.
- TG-SV-L10. Where the inputs are stored, by the marker search of item 9.
- TG-M, restated: the duration of every service request, sends, pings and polls, over the acceptance window under three conditions: normal, Telegram refused by the allow list, and internet off. It passes on a maximum of 3000 ms or less per request, zero `stale mutex heartbeat` WARN lines in the EA's journal, no LOCKED tick without its sweep pass, and the EA's `timer_ticks` keeping pace with the wall clock across the window.
- TG-X and TG-W stand as the plan writes them; TG-X covers the service's journal lines as well.

Plan rows under TG-1 (B): TG-S1 becomes four compiles; TG-S2 and TG-S3 stand; TG-S4 becomes TG-S15; TG-S5 is replaced by TG-S10; TG-S6 runs over the service as well; TG-S7 and TG-S8 stand (item 10); TG-D gains the service steps of TG-SV-D; TG-L1 to TG-L12 stand, every message now sent by the service, and TG-L1 reads reason 9 as TG-SV-L4 does.

## 13. Hebrew drafts

The block below carries every draft of plan 5, then the new ones, then, under labels that begin `BUILD:`, the drafts the build of 2026-10-21 adds. The format, the example values and the field map are plan 5's. Its `===` lines are English labels for the owner and are never sent. The build changed the carried and the new drafts in four ways, and each rendered message equals its draft here byte for byte (TG-S8): a count of 1 takes the Hebrew singular with the word for one, and a count shown as a field value stands under a label of the form "number of the ...", the form the S11 draft already used; a day result that prints 0.00 reads as a loss of 0.00, so S1, S1 restarted and the ACTIVE status read so; and S8 locked again and S17 carry the locked wording, the guardian being LOCKED and the figures the lock's.

```text
=== S1 start ===
🟢 השומר הופעל ומגן על החשבון
חשבון: 1200252169
שעת שרת: 2026.10.19 09:00:03
יתרה: 2172.06
הון: 2172.06
הפסד היום: 0.00 מול מגבלה של 126.21
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
הפסד היום: 0.00 מול מגבלה של 126.21
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
מספר ניסיונות השליחה: 5
מספר הכשלים: 0
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
הפסד היום: 108.84 מול מגבלה נעולה של 101.40
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
מספר הנעילות ביום שהסתיים: 0
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
השומר סוגר עכשיו פוזיציה אחת ומוחק 0 פקודות ממתינות
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
הפסד היום: 0.00 מול מגבלה נעולה של 126.21
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

=== NEW: periodic status, at each slot and as the reply to the check command, while ACTIVE ===
🟢 השומר פועל ומגן על החשבון
חשבון: 1200252169
שעת שרת: 2026.10.21 12:00:01
יתרה: 2172.06
הון: 2172.06
הפסד היום: 0.00 מול מגבלה של 126.21
מצב השומר: פעיל
בדיקה תקופתית: השומר עדכן את סימן החיים שלו לפני שנייה אחת
נעילה: אין
המגבלה שבתוקף כעת: 126.21
build=TG

=== NEW: periodic status, while LOCKED ===
🔒 השומר פועל, החשבון נעול
חשבון: 1200252169
שעת שרת: 2026.09.23 16:00:01
יתרה: 2880.70
הון: 2880.70
הפסד היום: 0.00 מול מגבלה נעולה של 147.54
מצב השומר: נעול
בדיקה תקופתית: השומר עדכן את סימן החיים שלו לפני שנייה אחת
נעול עד: 2026.09.24 01:00:00
build=TG

=== NEW: periodic status headline wordings, in order: SYNCING, SAFE_HALT, not running ===
⚠️ השומר פועל אבל עדיין לא מגן על החשבון
🛑 השומר בעצירת בטיחות ואינו מגן על החשבון
🔴 השומר אינו פועל ואינו מגן על החשבון

=== NEW: periodic status, the age line when the guardian's figures are old ===
עדכון הנתונים האחרון מהשומר: לפני 95 שניות

=== NEW: guardian not responding while the terminal runs ===
⛔ השומר הפסיק להגיב
חשבון: 1200252169
שעת שרת: 2026.10.21 14:05:12
יתרה: 2172.06
הון: 2150.10
הפסד היום: עדיין לא חושב
מצב השומר: לא פועל
השומר לא עדכן את סימן החיים שלו כבר 15 שניות
הטרמינל פועל, אבל השומר אינו מגן על החשבון
סימן החיים לשירות הניטור החיצוני הופסק
build=TG

=== NEW: guardian not responding, the reason line when it stopped without recording one ===
סיבה: לא נרשמה

=== NEW: guardian not running when the alerts service starts ===
⛔ השומר אינו פועל בטרמינל
חשבון: 1200252169
שעת שרת: 2026.10.21 09:01:00
יתרה: 2172.06
הון: 2172.06
הפסד היום: עדיין לא חושב
מצב השומר: לא פועל
שירות ההתראות פועל כבר 60 שניות והשומר עדיין לא הופעל
השומר אינו מגן על החשבון עד שיוצמד לגרף
build=TG

=== NEW: guardian responds again, no restart ===
✅ השומר חזר להגיב
חשבון: 1200252169
שעת שרת: 2026.10.21 14:05:54
יתרה: 2172.06
הון: 2150.10
הפסד היום: 21.96 מול מגבלה של 126.21
מצב השומר: פעיל
השומר לא הגיב במשך 42 שניות
build=TG

=== NEW: S12 algorithmic trading blocked while ACTIVE ===
⛔ המסחר האלגוריתמי חסום, השומר לא יכול לסגור פוזיציות
חשבון: 1200252169
שעת שרת: 2026.10.21 10:44:02
יתרה: 2805.35
הון: 2805.35
רווח היום: 12.40 מול מגבלת הפסד של 164.94
מצב השומר: פעיל
החסימה: כפתור המסחר האלגוריתמי בטרמינל כבוי
החסימה בזמן שהחשבון פעיל: אם תהיה חריגה השומר לא יוכל לסגור פוזיציות
build=TG

=== NEW: line added after the queue overflowed ===
מספר ההתראות שלא נשמרו בגלל עומס: 12

=== NEW: line added when similar events were held back ===
מספר האירועים הדומים שלא נשלחו מאז ההודעה הקודמת: 3

=== BUILD: S6 a pending order held, trade session closed, next open unknown ===
⚠️ פקודה ממתינה לא נמחקה: המסחר בסמל סגור כעת
חשבון: 1200252169
שעת שרת: 2026.09.26 16:35:38
יתרה: 3138.34
הון: 3138.30
הפסד היום: 0.00 מול מגבלה נעולה של 158.69
מצב השומר: נעול
מספר הפקודה: 781624901
XAUUSD.ecn
ניסיון חוזר כשהמסחר בסמל ייפתח
build=TG

=== BUILD: S6 position held, the server did not carry out the close ===
⚠️ פוזיציה לא נסגרה: השרת לא ביצע את הסגירה
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

=== BUILD: S6 pending order held, the server did not carry out the deletion ===
⚠️ פקודה ממתינה לא נמחקה: השרת לא ביצע את המחיקה
חשבון: 1200252169
שעת שרת: 2026.09.23 15:30:00
יתרה: 2880.70
הון: 2850.10
הפסד היום: 30.60 מול מגבלה נעולה של 147.54
מצב השומר: נעול
מספר הפקודה: 753031560
XAUUSD.ecn
השומר ינסה שוב כל 60 שניות
build=TG

=== BUILD: S6 position held, trading in the symbol disabled ===
⚠️ פוזיציה לא נסגרה: המסחר בסמל חסום כעת
חשבון: 1200252169
שעת שרת: 2026.09.26 16:35:38
יתרה: 3138.34
הון: 3138.30
הפסד היום: 0.00 מול מגבלה נעולה של 158.69
מצב השומר: נעול
מספר הפוזיציה: 781624897
XAUUSD.ecn
ניסיון חוזר כשהמסחר בסמל יתאפשר
build=TG

=== BUILD: S6 pending order held, hard stop ===
⚠️ פקודה ממתינה לא נמחקה אחרי 10 ניסיונות
חשבון: 1200252169
שעת שרת: 2026.09.23 15:30:00
יתרה: 2880.70
הון: 2850.10
הפסד היום: 30.60 מול מגבלה נעולה של 147.54
מצב השומר: נעול
מספר הפקודה: 753031560
XAUUSD.ecn
השומר ינסה שוב כל 60 שניות
build=TG

=== BUILD: S6 held pending order finally deleted ===
🧹 פקודה ממתינה שלא נמחקה קודם נמחקה עכשיו
חשבון: 1200252169
שעת שרת: 2026.09.28 01:01:05
יתרה: 2998.80
הון: 2998.80
הפסד היום: 0.00 מול מגבלה נעולה של 158.69
מצב השומר: נעול
מספר הפקודה: 781624901
XAUUSD.ecn
build=TG

=== BUILD: S6 enforcement result, one position and one pending order ===
🧹 סגירת הפוזיציות הושלמה
חשבון: 1200252169
שעת שרת: 2026.09.23 15:28:24
יתרה: 2880.70
הון: 2880.70
הפסד היום: 0.00 מול מגבלה נעולה של 147.54
מצב השומר: נעול
נסגרה: פוזיציה אחת
נמחקה: פקודה ממתינה אחת
מספר ניסיונות השליחה: 2
מספר הכשלים: 0
משך: 3 שניות
build=TG

=== BUILD: S7 closed on a later attempt ===
🧹 עסקה שנפתחה בזמן הנעילה נסגרה
חשבון: 1200252169
שעת שרת: 2026.09.23 15:56:12
יתרה: 2880.62
הון: 2880.62
הפסד היום: 0.08 מול מגבלה נעולה של 147.54
מצב השומר: נעול
מספר הפוזיציה: 753338779
XAUUSD.ecn
נסגרה בניסיון מספר 2
build=TG

=== BUILD: S17 a file found corrupt at the start ===
⚠️ השומר מצא קובץ פגום
חשבון: 1200252169
שעת שרת: 2026.10.21 09:00:05
יתרה: 2172.06
הון: 2172.06
הפסד היום: עדיין לא חושב
מצב השומר: בסנכרון
הקובץ: קובץ שיא הרווח הסגור
הקובץ הועבר להסגר ונוצר קובץ חדש
build=TG

=== BUILD: S17 file names, in order: halt, floor, queue, unknown ===
הקובץ: קובץ העצירה
הקובץ: קובץ המגבלה שנשמרה מול הגדלה
הקובץ: קובץ תור ההתראות
הקובץ: קובץ של השומר

=== BUILD: S19 the currency limit entered while locked ===
המגבלה שהוזנה: 150

=== BUILD: S12 blocked while SYNCING or SAFE_HALT ===
⛔ המסחר האלגוריתמי חסום, השומר לא יכול לסגור פוזיציות
חשבון: 1200252169
שעת שרת: 2026.10.21 09:00:20
יתרה: 2172.06
הון: 2172.06
הפסד היום: עדיין לא חושב
מצב השומר: בסנכרון
החסימה: המסחר האלגוריתמי כבוי בהגדרות השומר
build=TG

=== BUILD: the day's result while LOCKED and in profit ===
רווח היום: 5.00 מול מגבלה נעולה של 147.54

=== BUILD: S16 restarted in place ===
🔒 הנעילה שוחזרה בהפעלת השומר
חשבון: 1200252169
שעת שרת: 2026.09.23 16:57:35
יתרה: 2880.70
הון: 2880.70
הפסד היום: 0.00 מול מגבלה נעולה של 147.54
מצב השומר: נעול
סיבת ההפעלה מחדש: הגדרות השומר שונו
נעול עד: 2026.09.24 01:00:00
מקור הנעילה: קובץ מצב הנעילה ומשתנה הגיבוי בטרמינל
השומר סוגר עכשיו 0 פוזיציות ומוחק 0 פקודות ממתינות
build=TG

=== BUILD: periodic status while SYNCING ===
⚠️ השומר פועל אבל עדיין לא מגן על החשבון
חשבון: 1200252169
שעת שרת: 2026.10.21 08:00:01
יתרה: 2172.06
הון: 2172.06
הפסד היום: עדיין לא חושב
מצב השומר: בסנכרון
בדיקה תקופתית: השומר עדכן את סימן החיים שלו לפני 0 שניות
build=TG

=== BUILD: periodic status, the guardian not running, its mutex heartbeat stale ===
🔴 השומר אינו פועל ואינו מגן על החשבון
חשבון: 1200252169
שעת שרת: 2026.10.21 16:00:01
יתרה: 2172.06
הון: 2172.06
הפסד היום: עדיין לא חושב
מצב השומר: לא פועל
השומר לא עדכן את סימן החיים שלו כבר 75 שניות
build=TG

=== BUILD: the singular forms, in order: the delay line, the crash loop line, a hard stop of one attempt ===
נשלחה באיחור של שנייה אחת
הפעלה אחת ברצף הסתיימה בלי עצירה תקינה, בהפרש של עד 300 שניות זו מזו
⚠️ פוזיציה לא נסגרה אחרי ניסיון אחד
```

Field map, the new lines:

| Line | Source |
|---|---|
| status, the mutex heartbeat line | `TimeLocal` minus the value of `AG_HB_<login>`, in seconds |
| status, the age line | the snapshot's `local_t` against the service's `TimeLocal`, shown when over 90 s |
| not responding, the seconds | `TimeLocal` minus the value of `AG_HB_<login>` |
| not running, the seconds | the time since the service started |
| responds again, the gap | from the first stale read to the first fresh one, on the service's local clock |
| the "not kept" line | the gap in `seq` (1.12) |
| the "held back" line | the suppressed count of plan 6.4.2 |

## What this addendum does not do

- No source, include, script, installer, vector, SPEC or README change; no compile, no MetaEditor run, no deploy.
- Nothing under any terminal data folder written. One read only listing of the development terminal's `MQL5` folder, after the RULE B alias audit. No terminal configuration file read or edited.
- No network call to Telegram, healthchecks.io or any other service.
- No ruling recorded beyond those of 0.1; TG-14, TG-15 and TG-16 are OPEN.
- The token, the chat id and the ping URL appear nowhere in this repository or this session.
