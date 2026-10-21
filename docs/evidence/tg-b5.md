# Pass B5 evidence: Telegram alerts, the PNL line and the open trades line, 2026-10-21

Branch `build/telegram-alerts-pnl` in worktree `.claude/worktrees/build-telegram-alerts-pnl`, cut from main at `2acbe38`, on host `www8351`. Every value below is an executor measurement of this session unless it is marked as the owner's. The ACTIONS entry of 2026-10-21 on pass B5 names this file.

## 1. The owner's instruction on the ledger read, as given

"OWNER INSTRUCTION, for this session only: rule 2's full read of LEDGER.md is replaced by these reads, each done in full: the Telegram alerts entry at the head of ISSUES; the DECISIONS entries dated 2026-10-20 and 2026-10-21; and the ACTIONS entry of format pass B3. Also read addendum items 6 and 13 in full, and each source file before you edit it. Record this in the ACTIONS entry as the owner's instruction."

The reads, line numbers as at `2acbe38`, all before the first change: the Telegram alerts entry, `LEDGER.md:22` to `:28`; the DECISIONS entries dated 2026-10-20 and 2026-10-21, `:2938` to `:3053`; the ACTIONS entry of format pass B3, `:213` to `:236`; addendum item 6, `:260` to `:271`; addendum item 13, `:425` to `:1437`. Read in full before the first edit: `AlertText.mqh`, `AccountGuardianAlerts.mq5`, `scripts/rows/gen_vectors.py` and `scripts/deploy-tg.ps1`. `AgPhase2StateVectors.mq5` was read at lines 1 to 200, 1500 to 1559 and 1740 to 1796, with a search of the whole file for every use of `AgTgCommon`, `AgVecC` and the render functions, before its one hand written edit, to `AgVecC` at line 179; its other lines were read in full later in the session, after the commit `8248797`, and hold no other use of those names. Read in full before they ran: `scripts/rows/static_rows.py`, `compile.py`, `mqleval.py`, `tg_s7.py` and `tg_s12_cases.py`, `scripts/make-manifest.ps1` and `scripts/export-release.ps1`. For the archive rule only, the date of the oldest ACTIONS entry was read: 2026-07-28, 85 days old, so nothing was archived.

## 2. The checks of the instruction's CONTEXT

- `git status --porcelain` in the main checkout: empty.
- `git merge-base --is-ancestor 2acbe38 main`: exit code 0.
- main: `2acbe381f58ca1ff6bf85248dd9b60f7f2b5c9ea` "ledger: format pass B3 recorded, the message format F1 to F11 built, every static row holds, deploy dictation for the service and the vectors script", one parent, `6e45ea446ae48c3312ae7eab1590faa14eef1cc1`. Local refs, no fetch.
- Worktrees at the start: `build-telegram-alerts` and `build-telegram-alerts-format` at `2acbe38`, `ledger-poll-counter-issue` at `12d7df1`, `plan-telegram-alerts` at `00c7237`.
- `git worktree add -b build/telegram-alerts-pnl .claude/worktrees/build-telegram-alerts-pnl 2acbe381f58ca1ff6bf85248dd9b60f7f2b5c9ea`: "Preparing worktree (new branch 'build/telegram-alerts-pnl')", "HEAD is now at 2acbe38". The later merge into main is a fast forward.

## 3. The owner's evidence, recorded as given, not verified by the executor

The prompt's line wraps are joined; the text is otherwise as given.

"OWNER EVIDENCE, from the demo terminal, against the build compiled from 777a48f. Record it in ACTIONS as given, not verified by the executor:
- 15:47:58 server time: S12 blocked in ACTIVE, by the terminal button. The local Alert popup and the chart banner appeared, by the owner's attestation. 15:48:04: S12 restored.
- 15:48:03: the status message, in reply to the command sent at 15:47.
- 16:03:08: S4. Day loss 195.00 against a limit of 139.94, the percent leg 5.50, locked until 2026.10.22 01:00:00, one position to close.
- 16:03:11: S6C. Loss 360.00 against the locked limit 139.94; one position closed, zero pendings, one attempt, zero failures, 3 seconds.
- THE 16:00 STATUS SLOT: no defect. The demo terminal's journal, read by an executor on 2026-10-21, shows "16:00:01.300 AccountGuardianAlerts AG|2026.10.21 16:00:02|INFO|alerts sent|seq=0|class=STATUS|http=200|ms=344". The owner states that he deleted the chat messages, so the chat cannot confirm it."

R5 caps the ACTIONS entry at 1,500 characters and sends quotes here, so the entry names this section in place of the quote.

## 4. The FINAL check, before any write

- F2 of the entry "(owner ruling 2026-10-21, the message format F1 to F11)": its day result labels are the two R3 names and replaces "everywhere". An owner supersession by name, no stop.
- F6 of the same entry: "A zero count is left out of a list line. A line whose counts are all zero is left out." The open trades line is a field line, and R4 gives it its own wording at zero. No stop.
- F8 of the same entry: "Next comes U+1F4C9 [Hebrew "total" then the Latin PNL: U+05E1 U+05D4 U+05F4 U+05DB] PNL: <the signed day result with its sign>, which takes the place of the day result line." Read with R3 as reading A of section 5, under which no FINAL text is changed. No stop.
- No other FINAL entry was found in conflict with the pass.

## 5. Build readings, executor readings and not rulings, UNRULED 2026-10-21

- A. R3's sign rule, U+1F4C8 above zero and U+1F4C9 otherwise, is applied to the day result lines R3 replaces. The PNL line F8 gives S4 and its daily peak variant is kept as F8 writes it, U+1F4C9 included, R3 not naming it. The daily peak variant in profit therefore still reads U+1F4C9 with +90.96$, as at format pass B3. If R3 is meant to reach that line, the change is one literal in `AgTgTextS4Peak` and one emoji in its draft.
- B. R4's exclusion is read by message type: S4, its daily peak variant and S16, the restarted S16 included, carry no open trades line, whether or not their sweep line shows. A lock with nothing open shows neither line.
- C. The count and the currency sign are read when the message is rendered: an event when it is converted into a waiting message, a merged restart at the merge, and the periodic status, the reply, S3, S11, S14 and the liveness messages when they are built. A message waiting for Telegram keeps the count read at its render.
- D. A result not computed takes U+1F4C9, R3's "otherwise". A result that prints 0.00 reads 0.00$, U+1F4C9 and no sign.
- E. The open trades line at one shows the digit, as a label and a count; R4 gives the zero wording only.
- F. The open counts of the drafts are illustrative: none where the equity equals the balance; otherwise one, with two in S8 locked again and three in S9. The vectors render S4 and its daily peak variant with three open and S16 with one, their sweep counts, to show the line is left out.
- G. S14's line of the ended day's closed result keeps its own wording: it is the closed result of the ended day, not the day result since the anchor.
- H. `PositionsTotal` in a service: the service compiles at 0 errors and 0 warnings with its two direct calls, and it has called `PositionsTotal` through `AgFloating` (`Pnl.mqh:357`) and read positions in `AgSvcSymbolOf` since Part B. No MQL5 reference was found on this computer and no network call was made, so the service's runtime read is confirmed by a row on the demo terminal: the open trades line of a message.

## 6. Item 13, `ad9a7e8`

51 result lines rewritten, 49 messages and two wording drafts; 47 open trades lines added after the equity line; four messages without one: S4, its daily peak variant, S16 and S16 restarted in place. The intro paragraph states R3, R4 and reading A, UNRULED. The emoji map: the loss and profit labels give way to the PNL line under U+1F4C9 and U+1F4C8, and U+1F4C2 is added for the open trades line after the equity line. The field map gains the open trades line, `PositionsTotal` read by the service when it renders.

## 7. The code

- `AlertText.mqh`, `f48d69d`: `AgTgCommon` gains `open_pos` and `cur`; `AgTgResultLine` and `AgTgPnlLine` take the currency sign and render the PNL line of R3; `AgTgOpenLine` renders the line of R4; `AgTgCommonHead` and `AgTgMessageWith` take `open_line`, false in `AgTgTextS4`, `AgTgTextS4Peak` and `AgTgTextS16`. The header comment states R3 and R4.
- The service, `6f002ef`: `AgSvcCommonFromEvent` and `AgSvcCommonNow` read `PositionsTotal()` into `open_pos` and `AgSvcCurrency()` into `cur`; every `AgTgCommon` of the service is filled by one of the two.
- The vectors, `8248797`: `AgVecC` takes the draft's open count and sets the USD sign; the generated block regenerated by `scripts/rows/gen_vectors.py`, which counts the shifted line indexes and adds ten helper vectors. After the ledger commit `0f62071`, `gen_vectors.py` alone was respaced at `39c9439`, sixteen case lines given the space after the comma the file writes elsewhere; run again, it leaves the vectors file byte identical.
- Unchanged, by the constraint: the queue format, `AlertQueue.mqh` with `AgTgMoney` and `AgTgNum`, `AlertJson.mqh`, `AccountGuardian.mq5`, `Persist.mqh`, `Pnl.mqh`, `Sweep.mqh`, `SweepPolicy.mqh`, `State.mqh`, `Clock.mqh` and `Log.mqh`: `git diff --stat 2acbe38 HEAD` over them reads nothing. No SPEC or README line describes the changed message lines, so neither changes.

## 8. The vectors

`python -I scripts/rows/gen_vectors.py`: "render vectors 106, helper vectors 46, of which pass B5 10, drafts not rendered by any vector: ['S13 check name at the dead man service']". Generated checks 142 at `2acbe38` and 152 at HEAD; the rest of the script unchanged, so the terminal run should read `AGVEC|SUMMARY|522/522`, 512 at B3 plus 10. The ten: `tg_fmt_pnl_line_above_zero`, `tg_fmt_pnl_line_zero`, `tg_fmt_pnl_line_a_figure_that_prints_zero`, `tg_fmt_pnl_line_below_zero`, `tg_fmt_pnl_line_below_zero_with_a_code`, `tg_fmt_pnl_line_not_computed`, `tg_fmt_open_line_zero`, `tg_fmt_open_line_one`, `tg_fmt_open_line_several` and `tg_fmt_open_line_left_out_where_the_sweep_line_counts`.

Executor measurement, not a row: every generated line run on the source by `mqleval.py` from a script under the job tmp directory: tg_text_ 106 of 106, tg_fmt_ 46 of 46, 152 of 152. Negative control, outside the repository: a copy of the files those two measurements read, with one letter removed from the open trades label: TG-S7 exit code 1, "every Hebrew literal fragment found verbatim in item 13 or item 5: 228 fragments, 1 missing", "templates whose Hebrew count equals item 13: 59 of 106", "TG-S7 DOES NOT HOLD", 47 template lines failing; the vector run 102 of 152, tg_text_ 59 of 106 and tg_fmt_ 43 of 46.

## 9. The compiles

By `scripts/rows/compile.py` from `8248797`, the program folder MetaEditor, `/include` at the worktree `MQL5` folder and `/log` under the job tmp directory; `git diff --stat 8248797 HEAD -- MQL5` reads nothing, so the sources are those of HEAD. Exit code 1 every run, not used, standing rule 6. Every md5 a label and not identity, standing rule 7.

- `AccountGuardian.mq5`: "Result: 0 errors, 0 warnings, 8121 ms elapsed, cpu='X64 Regular'"; 8 including lines, all in the worktree: `Log.mqh`, `Clock.mqh`, `State.mqh`, `Persist.mqh`, `Pnl.mqh`, `SweepPolicy.mqh`, `Sweep.mqh`, `AlertQueue.mqh`; `AccountGuardian.ex5` md5 `CF25915368E9EEBAF6E48DDBFB6E66B5`, 227626 bytes, 19:34:25. Its sources are byte identical to `2acbe38`; the md5 differs from B3's `12E6F1C63AFDC547C3A03907A79A4E46`, compiled from another worktree path.
- `AccountGuardianAlerts.mq5`: "Result: 0 errors, 0 warnings, 4853 ms elapsed, cpu='X64 Regular'"; 9 including lines; `AccountGuardianAlerts.ex5` `9C656165419DF3FFB166BB677591450F`, 148376 bytes, 19:34:41.
- `AgPhase2StateVectors.mq5`: "Result: 0 errors, 0 warnings, 10628 ms elapsed, cpu='X64 Regular'"; 9 including lines; `AgPhase2StateVectors.ex5` `F196ACF8BB7E0970A7F53721963B42EF`, 316694 bytes, 19:34:58.
- `AgPhase1ClockVectors.mq5`: "Result: 0 errors, 0 warnings, 597 ms elapsed, cpu='X64 Regular'"; 2 including lines; `AgPhase1ClockVectors.ex5` `6A2AED891D1F96912436913B5120082C`, 13752 bytes, 19:35:00.

A SIDE EFFECT OF EVERY COMPILE, MEASURED THIS SESSION: MetaEditor appends one `Compile` line per compile to its own log, `logs\metaeditor.log` of the data folder `D0E8209F77C8CF37AD8BF550E51FF075`, whatever `/log` names. A read only listing found that file alone modified in that folder during the compiles, and a plain `Get-Content -Tail` read, after the alias audit, shows four lines from 19:34:25 to 19:35:00, one per compile of this pass, after the eight of format pass B3 at 17:22 and 17:24. The executor wrote nothing there itself.

## 10. The manifest, `f3ae744`

`scripts/make-manifest.ps1`, 14 lines, two changed: `AccountGuardianAlerts.mq5` `22054C6E8B7774EC4B17A0E84A3D8697`, was `161E205910897186840CF6F96EC98C76`; `AlertText.mqh` `8647CABF599FDBE72015D9CC6D4F4E4B`, was `355C5CB155BF841D02D5BBDEAEB8F405`.

## 11. The static rows, from the committed scripts

`python -I -B scripts/rows/static_rows.py` at `85dd154`:

```text
HEAD 85dd15453ac67f2a8c95564d148d6443b8f40281, compared with 00c7237
TG-S15 AgEvaluateActive     00c7237 85F76042B48031B129B49F3B1D8D0353 now 85F76042B48031B129B49F3B1D8D0353 IDENTICAL
TG-S15 AgBootDerivation     00c7237 5D800A949B45996400D00DFB107903CF now 5D800A949B45996400D00DFB107903CF IDENTICAL
TG-S15 AgEvaluateLocked     00c7237 91CC9E9F668DAE2420117FE34FF2DA68 now 91CC9E9F668DAE2420117FE34FF2DA68 IDENTICAL
TG-S15 AgDeclareLock        00c7237 D6CEFE1AC2A369E489B820930A203F67 now D6CEFE1AC2A369E489B820930A203F67 IDENTICAL
TG-S15 AgEnterLockFromBoot  00c7237 F3F0DA3E8BBF7C54E1D613FD29740D61 now F3F0DA3E8BBF7C54E1D613FD29740D61 IDENTICAL
TG-S15 AgTransition         00c7237 82A3CAE3DE3F4179CFA0B61AC7343F2A now 82A3CAE3DE3F4179CFA0B61AC7343F2A IDENTICAL
TG-S2 hits at 00c7237 7, now 7, per file now {'MQL5/Include/AccountGuardian/Sweep.mqh': 7}, the same line texts: True
TG-S3 AgSweepPass call sites 2: ['AccountGuardian.mq5:2099 AgSweepPass("timer");', 'AccountGuardian.mq5:2156 AgSweepPass("accelerated");']
TG-S10 the EA compiles 9 files: ['AccountGuardian.mq5', 'Log.mqh', 'Clock.mqh', 'State.mqh', 'Persist.mqh', 'Pnl.mqh', 'SweepPolicy.mqh', 'Sweep.mqh', 'AlertQueue.mqh']
TG-S10 network names, comments included, in the EA and the includes it compiles: 0 []
TG-S10 every line naming WebRequest in MQL5/, comments included: 1 ['MQL5/Services/AccountGuardian/AccountGuardianAlerts.mq5:829 int code = WebRequest(method, url, headers, timeout_ms, data, result, result_headers);']
TG-S10 WebRequest at AccountGuardianAlerts.mq5:829 passes the timeout timeout_ms
TG-S10 AgSvcRequest at AccountGuardianAlerts.mq5:856 passes the timeout timeout_ms
TG-S10 AgSvcRequest at AccountGuardianAlerts.mq5:861 passes the timeout timeout_ms
TG-S10 AgSvcRequest at AccountGuardianAlerts.mq5:904 passes the timeout AG_SVC_TIMEOUT_MS
TG-S10 AgSvcRequest at AccountGuardianAlerts.mq5:921 passes the timeout AG_SVC_TIMEOUT_MS
TG-S10 AgSvcSendText at AccountGuardianAlerts.mq5:891 passes the timeout timeout_ms
TG-S10 AgSvcSendText at AccountGuardianAlerts.mq5:960 passes the timeout AG_SVC_TIMEOUT_MS
TG-S10 AgSvcSendText at AccountGuardianAlerts.mq5:1060 passes the timeout AG_SVC_FINAL_TIMEOUT_MS
TG-S10 AG_SVC_TIMEOUT_MS = 2000
TG-S10 AG_SVC_FINAL_TIMEOUT_MS = 1500
TG-S11 the service compiles its source and 9 includes: own ['AlertQueue.mqh', 'AlertJson.mqh', 'AlertText.mqh'], shared ['Persist.mqh', 'Log.mqh', 'Clock.mqh', 'State.mqh', 'Pnl.mqh', 'SweepPolicy.mqh']
TG-S11 file, GV or trade writes in the service's own four files, GlobalVariableSet on the two names aside: 0 []
TG-S11 GlobalVariableSet sites: ['AccountGuardianAlerts.mq5:260 GlobalVariableSet(AgGvTgAck(g_svc_login), (double)g_svc_ack);', 'AccountGuardianAlerts.mq5:754 GlobalVariableSet(AgGvTgRefSeen(g_svc_login), v);']
TG-S11 GlobalVariablesFlush sites, persisting those two: ['AccountGuardianAlerts.mq5:261', 'AccountGuardianAlerts.mq5:755']
TG-S11 writers of the shared includes, derived: 17 ['AgAtomicWrite', 'AgFloorLoad', 'AgFloorQuarantine', 'AgFloorSave', 'AgHaltLoad', 'AgHaltSave', 'AgMutexAcquire', 'AgMutexRefresh', 'AgMutexRelease', 'AgPeakLoad', 'AgPeakQuarantine', 'AgPeakSave', 'AgPeakUpdate', 'AgRatchetUpdate', 'AgStateLoad', 'AgStateQuarantine', 'AgStateSave']
TG-S11 calls from the service's own four files into those writers: 0 []
TG-S16 references to the g_ag_tp_ globals by function ('-' the declarations): {'-': 7, 'AgRefreshBanner': 2, 'AgTgSnapshotNow': 1, 'AgTgPermissionRead': 18, 'AgTgPermissionNote': 2, 'AgTgProduce': 4, 'AgTgInitReset': 7}
TG-S16 the LIFE line note AgTgPermissionNote is called from: ['OnTimer']
TG-S16 outside the allowed sites: []; in a protected function: []; in Sweep.mqh: []; in State.mqh: []
TG-S6 token shaped literals in the tree: 0 []
TG-S6 UUID shaped literals in the tree: 1 ['docs/evidence/metaeditor-20260902.txt:372']
TG-S6 a non empty default on the three inputs: 0 []
TG-S6 a journal, Alert or chart call carrying an input: 0
IN-S5 manifest lines 14, matching the HEAD blobs 14
IN-S3 install.ps1:56 Add-Content -LiteralPath $recordPath -Value $Text -Encoding UTF8
IN-S3 install.ps1:167 $compileProcess = Start-Process -FilePath $metaEditor -ArgumentList $compileArguments -PassThru -WindowStyle Hidden
IN-S3 install.ps1:569 $null = New-Item -ItemType Directory -Path $targetFolder
IN-S3 install.ps1:572 Copy-Item -LiteralPath $compiledFile -Destination $targetFile -Force
IN-S3 install.ps1:581 Copy-Item -LiteralPath $serviceCompiledFile -Destination $serviceTargetFile -Force
IN-S6 README.md CR 132 LF 132, em dashes 0, secrecy hits 0 {}, development names [], docs/media paths 6
naming rule LEDGER.md: bare uses 14
naming rule docs/SPEC_v0.1.md: bare uses 0
parse installer/install.ps1: errors 0
parse scripts/deploy-tg.ps1: errors 0
parse scripts/export-release.ps1: errors 0
parse scripts/make-manifest.ps1: errors 0
```

The TG-S6 list of every use of the three inputs is left out above; it reads as at B3, the lines shifted by the seven new lines of the service. TG-S1 and TG-S9 are the compiles of section 9.

`python -I -B scripts/rows/tg_s7.py`, exit code 0: "AlertText.mqh starts EF BB BF", "decodes as strict UTF-8", "holds no U+2013: count 0", "holds no U+2014: count 0", "holds no U+05BE: count 0", "no Hebrew outside string literals: count 0", "every Hebrew literal fragment found verbatim in item 13 or item 5: 228 fragments, 0 missing", "templates whose Hebrew count equals item 13: 106 of 106", "templates whose rendering equals the draft character for character: 106 of 106", "the command, item 5, Hebrew count: 8 vs 8, identical True", "TG-S7 HOLDS". The draft lines no case renders are the three of B3: the daily peak wording of the S4 list, the S13 check name and the daily peak source of S16.

`python -I -B scripts/rows/tg_s12_cases.py`, exit code 0: "cases 64, pass 64, fail 0".

## 12. The export dry run

`scripts/export-release.ps1 -Destination` a folder under the job tmp directory, from HEAD `f3ae744`: 22 files exported, "Manifest check: 14 of 14 files match.", "Secrecy search: 0 hits over 8 patterns.", "EXPORT PASSED from commit f3ae7445fdb32f97347787a4507bc73605bf0dd4. The folder is ready to be committed into the release repository." The folder is left there and is not published.

## 13. The deploy, dictation, NOT RUN, THE OWNER'S

Under TG-10 (A) and the 2026-09-06 hand. The EA's compiled sources are unchanged from main at `2acbe38`, so the EA's file is not copied and the running guardian is not touched.

1. The owner stops the running AccountGuardianAlerts instance: Navigator, Services, right click, Stop.
2. The owner runs `scripts\deploy-tg.ps1` at `85dd154` from the owner's own PowerShell window. Two copies from the worktree `build-telegram-alerts-pnl`: `AccountGuardianAlerts.ex5` straight into `MQL5\Services`, and `AgPhase2StateVectors.ex5` into `MQL5\Scripts\AccountGuardian`, each landed md5 printed, to read `9C656165419DF3FFB166BB677591450F` and `F196ACF8BB7E0970A7F53721963B42EF`.
3. The executor verifies each landed file with a plain `Get-FileHash`, read only.
4. The owner starts the instance again and pastes its start line, `alerts service started|build=TG|...`.
5. The owner runs the vectors script, which should read `AGVEC|SUMMARY|522/522`. UNKNOWN, as at B3: whether a running terminal runs the replaced vectors file without a restart; a summary still reading an older total means the run waits for the next terminal restart.
6. Then the rows of R2 run on the B5 build, the format row among them: a message showing the PNL line with the currency sign, the open trades line and the bold headline.

## 14. Not done, by the instruction

No deploy and no copy, the service never run; the executor wrote nothing under any MetaTrader terminal data folder, MetaEditor's own log line per compile aside, section 9; no terminal configuration file read or edited; no network call; no fetch, no push, no merge, no branch or worktree deleted; no ruling recorded beyond R1 to R5; no attribution. A `scripts/rows/__pycache__` folder that a row run of this session created was removed, and later runs used `-B`. No context compaction occurred up to the writing of this file.
