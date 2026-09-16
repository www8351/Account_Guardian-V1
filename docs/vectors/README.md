# A9 input matrix vectors

Eight `.set` files, one per row of the A9 acceptance matrix as rewritten by R10
(D1f, D7b, D11a FINAL 2026-09-03). Each is a complete input set of four keys with
exactly one field moved off the defaults.

| File | Field off default | Expected |
|---|---|---|
| `a9_defaults.set` | none | healthy init; `limits accepted\|percent=5.50\|currency=200.00\|raw=550/200` |
| `a9_optional_bad.set` | `LogVerbosity` 99 | WARN `optional config invalid: LogVerbosity unrecognised, falling back to NORMAL`, init succeeds |
| `a9_percent_zero.set` | `DailyLossPercent` 0 | refuse, `DailyLossPercent is not a list member (raw 0)` |
| `a9_percent_off_grid.set` | `DailyLossPercent` 510 (5.10) | refuse, `(raw 510)` |
| `a9_percent_over_ceiling.set` | `DailyLossPercent` 575 (5.75) | refuse, `(raw 575)` |
| `a9_currency_zero.set` | `DailyLossCurrency` 0 | refuse, `DailyLossCurrency is not a list member (raw 0)` |
| `a9_currency_gap.set` | `DailyLossCurrency` 12 | refuse, `(raw 12)` |
| `a9_currency_over_ceiling.set` | `DailyLossCurrency` 205 | refuse, `(raw 205)` |

The two limit values are stored as their backing integers: percent in hundredths,
so `550` is 5.50 percent, and currency in whole account-currency units, so `200`
is 200. A value that is not a member of its own list refuses init.

## Retired 2026-09-03 (D8b)

Ten vectors were removed from the tree by `git rm` in the R10 build session. Each
names an input the build no longer has, or a value the list-membership check now
covers. Git history keeps the bytes; the last commit that carries all ten is
`4f93013`, the commit this branch started from.

| File | Struck by |
|---|---|
| `a9_both_zero.set` | D1f, list membership supersedes the both-limits-zero check |
| `a9_neg_percent.set` | D1f, list membership supersedes the negative check |
| `a9_neg_currency.set` | D1f, list membership supersedes the negative check |
| `a9_percent_over_100.set` | D1f, list membership supersedes the above-100 range check |
| `a9_nonfinite.set` | D1f, list membership supersedes the finite check |
| `a9_sweep_zero.set` | D7b, `SweepPeriodSeconds` is a compile-time constant |
| `a9_sweep_over.set` | D7b, `SweepPeriodSeconds` is a compile-time constant |
| `a9_polls_zero.set` | D7b, `HistoryStablePolls` is a compile-time constant |
| `a9_crash_max_zero.set` | D11a, `CrashLoopMaxInits` is a compile-time constant |
| `a9_window_zero.set` | D11a, `CrashLoopWindowSeconds` is a compile-time constant |

A copy of any of the ten that is still sitting in the terminal Presets folder is a
live hazard, because a row that loads it by mistake would run an input set this
build does not have. Deleting those copies is a hand action in the terminal folder
and belongs to the owner.

## Synthetic checks in `AgPhase2StateVectors`

The script `MQL5/Scripts/AccountGuardian/AgPhase2StateVectors.mq5` runs from the
Navigator and prints one `AGVEC|<name>|PASS` line per check plus a final
`AGVEC|SUMMARY|<pass>/<total>` line. On this build the summary reads `234/234`:
the 100 checks of the D2D4 build plus the 134 ENF-0 checks listed in the section
below.
The five checks added by the D2D4 build assert the exact string of the `LOCKED`
numbers group, built by `AgLockedNumbersString` in `Log.mqh`, before the build is
deployed:

| Check | Asserts |
|---|---|
| `d2d4_locked_group_exact_string` | `locked_until=2026.09.01 01:00:00\|limit_snap=117.54\|base_snap=2350.86\|balance=2311.26\|floating=-115.50\|equity=2195.76` for those six arguments |
| `d2d4_locked_group_field_order` | the six keys appear in that order, `locked_until` first |
| `d2d4_locked_group_two_decimal_rendering` | two decimals throughout: 99.2985 renders `99.30`, -52.254 renders `-52.25`, 1880.876 renders `1880.88` |
| `d2d4_locked_group_corrupt_state_renders_zero` | a zeroed snapshot renders `limit_snap=0.00\|base_snap=0.00` while `balance` and `equity` still carry |
| `d2d4_locked_group_carries_only_the_six_ruled_fields` | the formatter's own output carries no `breach_time`, `peak`, `ratchet`, `anchor=`, `realized=`, `\|limit=`, `pnl` or `DEGRADED` |

The `DEGRADED\|` prefix on a live `LOCKED` line is added by the advisor, not by
the formatter, and is keyed on the terminal's connection state.

## ENF-0, the sweep policy checks (enforcement build, owner rulings ENF-1 to ENF-29 of 2026-09-16)

The script gains `#include <AccountGuardian/SweepPolicy.mqh>`, the sweep engine's
pure policy file, and still makes no trade call: `Sweep.mqh`, the only file that
reaches the trade API, is not included and the vectors binary links none of it.
The 134 checks are prefixed `enf_` and take the denominator from 100 to 234.

| Check group | Count | Asserts |
|---|---|---|
| `enf_value_<NAME>_is_<n>` | 41 | the numeric value of every retcode constant the classifier names, on this compiler, against the plan's documentation table (P92): `DONE` 10009, `DONE_PARTIAL` 10010, `MARKET_CLOSED` 10018, `CLIENT_DISABLES_AT` 10027, `POSITION_CLOSED` 10036 among them |
| `enf_class_<NAME>_is_<class>` | 41 | the classifier's answer for each constant: `done`, `retry`, `hold`, `refuse` or `placed`, per plan 2.7.4 |
| `enf_class_retcode_zero_is_retry`, `enf_class_unknown_retcode_is_refuse` | 2 | a request the terminal never sent is retry class; a retcode the classifier does not know is refuse class |
| `enf_partial_flag_on_10010`, `enf_partial_flag_off_10009` | 2 | the `DONE_PARTIAL` flag the caller reads (ENF-12(a)) |
| `enf_class_names`, `enf_retcode_names` | 2 | the class and retcode names the journal prints |
| `enf_backoff_attempt_<k>_is_<n>` | 9 | the schedule in passes, 1, 2, 4, 8, 16, 32, 60, 60 for attempts 1 to 8, and 1 for attempt 0 (ENF-9(c), ENF-10(a)) |
| `enf_hard_stop_is_10`, `enf_backoff_cap_is_60_passes`, `enf_rearm_is_60_passes`, `enf_cadence_is_30_passes`, `enf_magic_is_20260916`, `enf_comment_is_ag_sweep`, `enf_deviation_is_100_points` | 7 | the constants as ruled (ENF-25(a), ENF-11(a), ENF-19(a), ENF-6(a)) |
| `enf_order_most_negative_first_ties_by_ticket`, `enf_compare_*` | 4 | three synthetic positions sort most negative floating first, ties by ticket ascending (ENF-7(a)) |
| `enf_flat_on_zero_zero`, `enf_not_flat_*` | 3 | the one pass flat predicate (ENF-16(b)) |
| `enf_q3_*` | 6 | the account wide Q3 names in the ruled order, and the empty string when nothing blocks |
| `enf_symbol_mode_names`, `enf_closeonly_is_sendable`, `enf_disabled_is_not_sendable`, `enf_full_longonly_shortonly_are_sendable` | 4 | `SYMBOL_TRADE_MODE` named distinctly; CLOSEONLY sendable (ENF-15(a)), DISABLED held |
| `enf_filling_*` | 3 | FOK when allowed, else IOC, else RETURN, on the symbol's flag set (ENF-6(a)) |
| `enf_pending_types`, `enf_type_names` | 2 | the six pending types and the names the lines print |
| `enf_line_sweep_*` | 8 | the exact string of every sweep journal line on fixed arguments: `sweep pass`, `sweep delete`, `sweep close`, `sweep held`, `sweep blocked`, `sweep complete`, `sweep resumed`, `sweep accelerated` |

## Which copy is operative

The **terminal Presets folder is the operative copy**. It is the only one the
MetaTrader Load browser reads, and it is what an acceptance row actually loads:

```
%APPDATA%\MetaQuotes\Terminal\<terminal-id>\MQL5\Presets\a9_*.set
```

The copy in this directory is the **reviewable record**. It exists so a change to
a vector shows up as a diff against a committed baseline instead of appearing
from nowhere inside a terminal folder that no review ever sees.

## Keeping the two in sync

This repository is the source. The direction is always repo to terminal, never
back:

1. Edit the vector here and commit it, so the change is reviewable on its own.
2. Copy the file into the terminal Presets folder.
3. Restart the terminal. A running terminal never enumerates files added to its
   data folder after it started, so a vector copied into a live terminal stays
   invisible in the Load browser until the next start.
4. Confirm the file is listed in the Load browser before running any row that
   depends on it.

Step 3 is not optional and is not a precaution. It is measured behaviour, and it
has already cost this project one misdiagnosed session.

If the two copies ever disagree, the terminal copy is what ran and the repo copy
is wrong. Fix the repo copy to match what ran, record why, and never assume the
committed file describes a completed row.
