# Generates the TG-S8 render vectors of AgPhase2StateVectors.mq5 from item 13
# of the addendum, and the vectors of the display formatters and the F10
# helpers of AlertText.mqh (format pass B3 of 2026-10-21). It replaces, in
# place, the generated part of the TG block: from the "AgTgCommon c;" line
# under the TG-S8 comment to the final SUMMARY line. The hand written part of
# the TG block above it, Part B's with the corrections of fix pass B2, is not
# touched. The md5 of each draft's UTF-8 bytes is computed here, independently,
# from item 13's own text; a helper's expected value is stated here.
#
# Pass B5 of 2026-10-21, R3 and R4: each draft's common lines carry its open
# positions, the last argument of AgVecC, as item 13 shows them; the line
# indexes count the open trades line, which S4 and S16 leave out; and the
# helpers gain the PNL line and the open trades line.
#
# The Manual Lockout build of 2026-10-22 (ML-17 (A)): the drafts under labels
# that begin "ML:", S5 at the engagement (ML-30), S25 at the lockout's own end,
# its wording list and the S17 name of the lockout's record; and one helper,
# R4 and ML-31 for S5.
#
# A draft of item 13 runs from its "=== ... ===" label to the next label, the
# blank lines before the next label not part of it, since a message of the
# format F1 to F11 carries blank lines between its groups.
#
# Usage: python -I scripts/rows/gen_vectors.py [repository root]
import hashlib, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(HERE))
ADD = os.path.join(ROOT, "docs", "PLAN_TELEGRAM_ALERTS_ADDENDUM_TG1B.md")
VEC = os.path.join(ROOT, "MQL5", "Scripts", "AccountGuardian", "AgPhase2StateVectors.mq5")


def read_drafts(path):
    t = open(path, "rb").read().decode("utf-8").replace("\r\n", "\n").split("\n")
    s = t.index("```text", t.index("## 13. Hebrew drafts"))
    e = t.index("```", s + 1)
    drafts, cur = {}, None
    for l in t[s + 1:e]:
        if l.startswith("=== ") and l.endswith(" ==="):
            cur = l[4:-4]
            drafts[cur] = []
        elif cur is not None:
            drafts[cur].append(l)
    for k in drafts:
        while drafts[k] and drafts[k][-1] == "":
            drafts[k].pop()
    return drafts


drafts = read_drafts(ADD)


def md5(text):
    return hashlib.md5(text.encode("utf-8")).hexdigest().upper()


A, L, N = "AG_TG_PNL_ACTIVE", "AG_TG_PNL_LOCKED", "AG_TG_PNL_NONE"
SA, SL, SS, SH, SN = "AG_STATE_ACTIVE", "AG_STATE_LOCKED", "AG_STATE_SYNCING", "AG_STATE_SAFE_HALT", "AG_TG_STATE_NOT_RUNNING"


def C(t_, bal, eq, pnl, mode, lim, st, n=0):
    return "AgVecC(c, D'%s', %s, %s, %s, %s, %s, %s, %d);" % (t_, bal, eq, pnl, mode, lim, st, n)


# F9: the messages that carry the build line, and those that do not
FIN = 'AgTgFinish(%s, 0, 0, 0, "build=TG")'
NOB = 'AgTgFinish(%s, 0, 0, 0, "")'
# the line indexes of a message (F1, R4): with a limit, the events start at
# line 13; with the day's result not computed, at line 12; in S4 and S16,
# which leave the open trades line out, at line 12
EV, EVN, EVL = 13, 12, 12

# (name, label, line or None, common, expression)
cases = [
 ("s1_start", "S1 start", None, C("2026.10.21 14:55:00", "2544.33", "2544.33", "0.0", A, "139.94", SA),
  'AgTgFinish(AgTgTextS1(c, 5.50, 200, 139.94, "$"), 0, 0, 1670, "build=TG")'),
 ("s1_restarted", "S1 restarted in place", None, C("2026.10.19 11:42:10", "2172.06", "2172.06", "0.0", A, "126.21", SA), FIN % "AgTgTextS1Restarted(c, 5)"),
 ("s2_stop", "S2 stop", None, C("2026.10.19 18:00:00", "2217.06", "2217.06", "45.00", A, "126.21", SA), FIN % "AgTgTextS2(c, 1)"),
 ("s3_refused", "S3 refused start", None, C("2026.09.07 13:19:28", "2294.76", "2294.76", "0.0", N, "0.0", SN), 'AgTgFinish(AgTgTextS3Refused(c), 0, 0, 300, "")'),
 ("s3_second", "S3 second instance refused", None, C("2026.08.03 01:48:42", "2133.00", "2133.00", "0.0", N, "0.0", SA), NOB % "AgTgTextS3Second(c)"),
 ("s3_crash", "S3 SAFE_HALT after repeated crashes", None, C("2026.08.04 16:37:04", "2133.00", "2133.00", "0.0", N, "0.0", SH), NOB % "AgTgTextS3Crash(c, 4, 300)"),
 ("s3_persisted", "S3 SAFE_HALT persists after a restart", None, C("2026.08.04 16:37:54", "2133.00", "2133.00", "0.0", N, "0.0", SH), NOB % "AgTgTextS3Persisted(c, D'2026.08.04 16:37:04')"),
 ("s4_daily", "S4 lock, the daily limit", None, C("2026.09.15 18:36:17", "2300.16", "2164.56", "-130.20", A, "126.21", SL, 3), NOB % "AgTgTextS4(c, 1, D'2026.09.16 01:00:00', 5.50, 200, -130.20, 3, 0, \"$\")"),
 ("s4_peak", "S4 lock, give back from the daily peak", None, C("2026.09.26 16:35:35", "3138.34", "2976.30", "90.96", A, "158.69", SL, 3), NOB % "AgTgTextS4Peak(c, D'2026.09.27 01:00:00', 253.00, 253.00 - 158.69, 90.96, 3, 0, \"$\")"),
 ("s6_complete", "S6 enforcement result", None, C("2026.09.23 15:28:24", "2880.70", "2880.70", "0.0", L, "147.54", SL), NOB % "AgTgTextS6C(c, 3, 2, 5, 0, 7)"),
 ("s6_session", "S6 position held, trade session closed", None, C("2026.09.26 16:35:38", "3138.34", "3138.30", "0.0", L, "158.69", SL, 1), NOB % "AgTgTextS6H(c, 781624897, false, 1, \"XAUUSD.ecn\", D'2026.09.28 01:01:00', 10, 60)"),
 ("s6_hard_stop", "S6 position held, hard stop", None, C("2026.09.23 15:30:00", "2880.70", "2850.10", "-30.60", L, "147.54", SL, 1), NOB % "AgTgTextS6H(c, 753031555, false, 2, \"XAUUSD.ecn\", 0, 10, 60)"),
 ("s6_flattened", "S6 held position finally closed", None, C("2026.09.28 01:01:05", "2998.80", "2998.80", "0.0", L, "158.69", SL), NOB % "AgTgTextS6F(c, 781624897, false, \"XAUUSD.ecn\")"),
 ("s7", "S7 trade opened while locked", None, C("2026.09.23 15:56:12", "2880.62", "2880.62", "-0.08", L, "147.54", SL), NOB % "AgTgTextS7(c, 753338779, \"XAUUSD.ecn\", 1)"),
 ("s8_released", "S8 lock released", None, C("2026.09.27 01:00:03", "2998.84", "2998.80", "-0.04", A, "164.94", SA, 1), NOB % "AgTgTextS8Released(c, D'2026.09.27 01:00:00', 164.94)"),
 ("s8_again", "S8 locked again at the new day", None, C("2026.08.26 01:00:10", "2027.98", "1919.14", "-108.84", L, "101.40", SL, 2), NOB % "AgTgTextS8Again(c, D'2026.08.27 01:00:00')"),
 ("s9", "S9 approaching the limit", None, C("2026.10.19 14:05:12", "2172.06", "2071.09", "-100.97", A, "126.21", SA, 3), NOB % "AgTgTextS9(c, 80, 25.24)"),
 ("s10", "S10 broker connection restored", None, C("2026.08.18 12:13:43", "2133.13", "2133.13", "0.0", A, "106.66", SA), NOB % "AgTgTextS10(c, D'2026.08.18 12:08:42', D'2026.08.18 12:13:43', 301)"),
 ("s11", "S11 Telegram reachable again", None, C("2026.10.19 12:20:40", "2172.06", "2172.06", "0.0", A, "126.21", SA), NOB % "AgTgTextS11(c, D'2026.10.19 12:00:05', D'2026.10.19 12:20:40', 4)"),
 ("s12_blocked_locked", "S12 algorithmic trading blocked", None, C("2026.09.28 10:44:02", "2805.35", "2805.35", "-193.49", L, "164.94", SL), NOB % "AgTgTextS12Blocked(c, 1)"),
 ("s12_restored", "S12 trading restored", None, C("2026.09.28 10:47:03", "2805.35", "2805.36", "-193.48", L, "164.94", SL, 1), NOB % "AgTgTextS12Restored(c)"),
 ("s14", "S14 end of day summary", None, C("2026.10.20 01:00:04", "2140.50", "2140.50", "0.0", A, "117.73", SA), FIN % "AgTgTextS14(c, D'2026.10.19 01:00:00', -31.56, 12.40, 0, 117.73)"),
 ("s15", "S15 resumed after SAFE_HALT", None, C("2026.08.04 16:39:54", "2133.00", "2133.00", "0.0", N, "0.0", SS), NOB % "AgTgTextS15(c)"),
 ("s16", "S16 lock restored at start", None, C("2026.09.23 16:57:35", "2880.70", "2879.58", "-1.12", L, "147.54", SL, 1), NOB % "AgTgTextS16(c, D'2026.09.24 01:00:00', 1, 3, 1, 0, -1)"),
 ("s17", "S17 file write failure", None, C("2026.10.19 14:05:12", "2172.06", "2172.06", "0.0", L, "126.21", SL), NOB % "AgTgTextS17(c, 1, 1)"),
 ("s18", "S18 previous session cut off", None, C("2026.09.15 22:35:38", "2172.06", "2172.06", "0.0", N, "0.0", SS), NOB % "AgTgTextS18(c, 28)"),
 ("s19_locked", "S19 limit change refused while locked", None, C("2026.08.18 15:36:30", "239.63", "239.63", "-1893.50", L, "106.66", SL), NOB % "AgTgTextS19Locked(c, 1, 10.00, 200, 106.66, \"$\")"),
 ("s19_raise", "S19 raise held until the next day", None, C("2026.09.07 14:32:54", "2294.76", "2294.76", "0.0", A, "114.74", SA), NOB % "AgTgTextS19Raise(c, 126.21, 114.74)"),
 ("s20", "S20 server clock jump", None, C("2026.08.10 01:00:00", "2003.46", "2003.46", "0.0", A, "100.17", SA), NOB % "AgTgTextS20(c, 259200)"),
 ("s21", "S21 history read failure", None, C("2026.10.19 14:05:12", "2172.06", "2172.06", "0.0", N, "0.0", SS), NOB % "AgTgTextS21(c)"),
 ("s22", "S22 not protecting yet", None, C("2026.10.19 09:05:03", "2172.06", "2172.06", "0.0", N, "0.0", SS), NOB % "AgTgTextS22(c, 300, 1)"),
 ("s24", "S24 another instance took over", None, C("2026.10.19 14:05:12", "2172.06", "2172.06", "0.0", A, "126.21", SA), NOB % "AgTgTextS24(c)"),
 ("status_active", "NEW: periodic status, at each slot and as the reply to the check command, while ACTIVE", None, C("2026.10.21 15:34:00", "2544.33", "2544.33", "0.0", A, "139.94", SA), FIN % "AgTgTextStatus(c, 1, -1, 0)"),
 ("status_locked", "NEW: periodic status, while LOCKED", None, C("2026.09.23 16:00:01", "2880.70", "2880.70", "0.0", L, "147.54", SL), FIN % "AgTgTextStatus(c, 1, -1, D'2026.09.24 01:00:00')"),
 ("not_responding", "NEW: guardian not responding while the terminal runs", None, C("2026.10.21 14:05:12", "2172.06", "2150.10", "0.0", N, "0.0", SN, 1), NOB % "AgTgTextNotResponding(c, 15, false, true)"),
 ("not_running", "NEW: guardian not running when the alerts service starts", None, C("2026.10.21 09:01:00", "2172.06", "2172.06", "0.0", N, "0.0", SN), NOB % "AgTgTextNotRunning(c, 60)"),
 ("responds_again", "NEW: guardian responds again, no restart", None, C("2026.10.21 14:05:54", "2172.06", "2150.10", "-21.96", A, "126.21", SA, 1), NOB % "AgTgTextRespondsAgain(c, 42)"),
 ("s12_active", "NEW: S12 algorithmic trading blocked while ACTIVE", None, C("2026.10.21 10:44:02", "2805.35", "2805.35", "12.40", A, "164.94", SA), NOB % "AgTgTextS12Blocked(c, 1)"),
 ("b_s6_order_session", "BUILD: S6 a pending order held, trade session closed, next open unknown", None, C("2026.09.26 16:35:38", "3138.34", "3138.30", "0.0", L, "158.69", SL, 1), NOB % "AgTgTextS6H(c, 781624901, true, 1, \"XAUUSD.ecn\", 0, 10, 60)"),
 ("b_s6_refuse", "BUILD: S6 position held, the server did not carry out the close", None, C("2026.09.23 15:30:00", "2880.70", "2850.10", "-30.60", L, "147.54", SL, 1), NOB % "AgTgTextS6H(c, 753031555, false, 3, \"XAUUSD.ecn\", 0, 10, 60)"),
 ("b_s6_order_hold", "BUILD: S6 pending order held, the server did not carry out the deletion", None, C("2026.09.23 15:30:00", "2880.70", "2850.10", "-30.60", L, "147.54", SL, 1), NOB % "AgTgTextS6H(c, 753031560, true, 5, \"XAUUSD.ecn\", 0, 10, 60)"),
 ("b_s6_mode", "BUILD: S6 position held, trading in the symbol disabled", None, C("2026.09.26 16:35:38", "3138.34", "3138.30", "0.0", L, "158.69", SL, 1), NOB % "AgTgTextS6H(c, 781624897, false, 4, \"XAUUSD.ecn\", 0, 10, 60)"),
 ("b_s6_order_hard_stop", "BUILD: S6 pending order held, hard stop", None, C("2026.09.23 15:30:00", "2880.70", "2850.10", "-30.60", L, "147.54", SL, 1), NOB % "AgTgTextS6H(c, 753031560, true, 2, \"XAUUSD.ecn\", 0, 10, 60)"),
 ("b_s6_order_flattened", "BUILD: S6 held pending order finally deleted", None, C("2026.09.28 01:01:05", "2998.80", "2998.80", "0.0", L, "158.69", SL), NOB % "AgTgTextS6F(c, 781624901, true, \"XAUUSD.ecn\")"),
 ("b_s6_complete_singular", "BUILD: S6 enforcement result, one position and one pending order", None, C("2026.09.23 15:28:24", "2880.70", "2880.70", "0.0", L, "147.54", SL), NOB % "AgTgTextS6C(c, 1, 1, 2, 0, 3)"),
 ("b_s7_later", "BUILD: S7 closed on a later attempt", None, C("2026.09.23 15:56:12", "2880.62", "2880.62", "-0.08", L, "147.54", SL), NOB % "AgTgTextS7(c, 753338779, \"XAUUSD.ecn\", 2)"),
 ("b_s17_corrupt", "BUILD: S17 a file found corrupt at the start", None, C("2026.10.21 09:00:05", "2172.06", "2172.06", "0.0", N, "0.0", SS), NOB % "AgTgTextS17(c, 4, 2)"),
 ("b_s12_syncing", "BUILD: S12 blocked while SYNCING or SAFE_HALT", None, C("2026.10.21 09:00:20", "2172.06", "2172.06", "0.0", N, "0.0", SS), NOB % "AgTgTextS12Blocked(c, 2)"),
 ("b_s16_restarted", "BUILD: S16 restarted in place", None, C("2026.09.23 16:57:35", "2880.70", "2880.70", "0.0", L, "147.54", SL), NOB % "AgTgTextS16(c, D'2026.09.24 01:00:00', 1, 3, 0, 0, 5)"),
 ("b_status_syncing", "BUILD: periodic status while SYNCING", None, C("2026.10.21 08:00:01", "2172.06", "2172.06", "0.0", N, "0.0", SS), FIN % "AgTgTextStatus(c, 0, -1, 0)"),
 ("b_status_not_running", "BUILD: periodic status, the guardian not running, its mutex heartbeat stale", None, C("2026.10.21 16:00:01", "2172.06", "2172.06", "0.0", N, "0.0", SN), FIN % "AgTgTextStatus(c, 75, -1, 0)"),
]
# single lines of the wording lists
base_c = C("2026.10.19 14:05:12", "2172.06", "2172.06", "0.0", A, "126.21", SA)
for i in range(10):
    cases.append(("s2_reason_%d" % i, "S2 reason wordings", i, base_c, "AgVecLine(AgTgTextS2(c, %d), %d)" % (i, EV)))
cases.append(("delay_line", "delay line, for any message sent late", 0, None, 'AgVecLine(AgTgFinish("x", 0, 0, 125, "b"), 2)'))
for i, st in enumerate([SA, SL, SS, SH, SN]):
    cases.append(("state_word_%d" % i, "guardian state wordings", i,
                  C("2026.10.19 14:05:12", "2172.06", "2172.06", "0.0", N, "0.0", st), "AgVecLine(AgTgCommonLines(c), 9)"))
cases.append(("not_computed", "result not computed yet", 0, None, 'AgTgPnlLine(AG_TG_PNL_NONE, 0.0, 0.0, "$")'))
s4c = C("2026.09.15 18:36:17", "2300.16", "2164.56", "-130.20", A, "126.21", SL, 3)
for i, kind in enumerate([1, 2, 3]):
    cases.append(("s4_crossed_%d" % kind, "S4 crossed limit wordings, in order: percent leg, currency leg, held floor, daily peak", i,
                  s4c, "AgVecLine(AgTgTextS4(c, %d, D'2026.09.16 01:00:00', 5.50, 200, -130.20, 3, 0, \"$\"), 9)" % kind))
for i in range(4):
    cases.append(("s12_block_%d" % (i + 1), "S12 block wordings, in order: terminal button, EA setting, account, broker, while ACTIVE", i,
                  C("2026.09.28 10:44:02", "2805.35", "2805.35", "-193.49", L, "164.94", SL), "AgVecLine(AgTgTextS12Blocked(c, %d), %d)" % (i + 1, EV)))
cases.append(("s12_block_active_line", "S12 block wordings, in order: terminal button, EA setting, account, broker, while ACTIVE", 4,
              C("2026.10.21 10:44:02", "2805.35", "2805.35", "12.40", A, "164.94", SA), "AgVecLine(AgTgTextS12Blocked(c, 1), %d)" % (EV + 1)))
s16c = C("2026.09.23 16:57:35", "2880.70", "2879.58", "-1.12", L, "147.54", SL, 1)
for i, pair in enumerate([(1, 1), (1, 2), (1, 4), (3, 4), None, (2, 0)]):
    if pair is None:
        continue   # the daily peak source: no code path names it, the peak witness fires as DAILY_BREACH
    reason, mask = pair
    cases.append(("s16_source_%d" % i, "S16 lock source wordings", i, s16c,
                  "AgVecLine(AgTgTextS16(c, D'2026.09.24 01:00:00', %d, %d, 1, 0, -1), %d)" % (reason, mask, EVL + 1)))
cases.append(("s22_reason_2", "S22 second reason wording", 0,
              C("2026.10.19 09:05:03", "2172.06", "2172.06", "0.0", N, "0.0", SS), "AgVecLine(AgTgTextS22(c, 300, 2), %d)" % (EVN + 1)))
for i, st in enumerate([SS, SH, SN]):
    cases.append(("status_head_%d" % i, "NEW: periodic status headline wordings, in order: SYNCING, SAFE_HALT, not running", i,
                  C("2026.10.21 12:00:01", "2172.06", "2172.06", "0.0", N, "0.0", st), "AgVecLine(AgTgTextStatus(c, 1, -1, 0), 0)"))
cases.append(("status_age_line", "NEW: periodic status, the age line when the guardian's figures are old", 0,
              C("2026.10.21 12:00:01", "2172.06", "2172.06", "0.0", A, "126.21", SA), "AgVecLine(AgTgTextStatus(c, 1, 95, 0), %d)" % (EV + 2)))
cases.append(("not_recorded_line", "NEW: guardian not responding, the reason line when it stopped without recording one", 0,
              C("2026.10.21 14:05:12", "2172.06", "2150.10", "0.0", N, "0.0", SN), "AgVecLine(AgTgTextNotResponding(c, 15, true, true), %d)" % (EVN + 1)))
cases.append(("overflow_line", "NEW: line added after the queue overflowed", 0, None, 'AgVecLine(AgTgFinish("x", 12, 0, 0, "b"), 2)'))
cases.append(("held_back_line", "NEW: line added when similar events were held back", 0, None, 'AgVecLine(AgTgFinish("x", 0, 3, 0, "b"), 2)'))
s17c = C("2026.10.19 14:05:12", "2172.06", "2172.06", "0.0", L, "126.21", SL)
for i, kind in enumerate([2, 3, 5, 0]):
    cases.append(("s17_file_%d" % kind, "BUILD: S17 file names, in order: halt, floor, queue, unknown", i, s17c,
                  "AgVecLine(AgTgTextS17(c, %d, 1), %d)" % (kind, EV)))
cases.append(("s19_currency_line", "BUILD: S19 the currency limit entered while locked", 0,
              C("2026.08.18 15:36:30", "239.63", "239.63", "-1893.50", L, "106.66", SL),
              "AgVecLine(AgTgTextS19Locked(c, 2, 10.00, 150, 106.66, \"$\"), %d)" % EV))
cases.append(("locked_profit_line", "BUILD: the day's result while LOCKED and in profit", None, None, 'AgTgPnlLine(AG_TG_PNL_LOCKED, 5.00, 147.54, "$")'))
cases.append(("singular_delay", "BUILD: the singular forms, in order: the delay line, the crash loop line, a hard stop of one attempt", 0, None,
              'AgVecLine(AgTgFinish("x", 0, 0, 1, "b"), 2)'))
cases.append(("singular_crash", "BUILD: the singular forms, in order: the delay line, the crash loop line, a hard stop of one attempt", 1,
              C("2026.08.04 16:37:04", "2133.00", "2133.00", "0.0", N, "0.0", SH), "AgVecLine(AgTgTextS3Crash(c, 1, 300), %d)" % EVN))
cases.append(("singular_hard_stop", "BUILD: the singular forms, in order: the delay line, the crash loop line, a hard stop of one attempt", 2,
              base_c, 'AgVecLine(AgTgTextS6H(c, 1, false, 2, "", 0, 1, 60), 0)'))
for i, s in enumerate([1670, 259200, 7260, 7500]):
    cases.append(("b3_duration_%d" % s, "B3: the durations, in order: minutes, hours, hours and one minute, hours and minutes", i, None,
                  'AgVecLine(AgTgFinish("x", 0, 0, %d, "b"), 2)' % s))
for i, pair in enumerate([(3, 2), (0, 1)]):
    cases.append(("b3_sweep_%d_%d" % pair, "B3: the sweep line of a lock, in order: positions and pending orders, pending orders only", i, None,
                  "AgTgSweepNow(%d, %d)" % pair))
cases.append(("b3_failures_line", "B3: lines a zero count leaves out, here with a count, in order: the failures, the locks of the ended day", 0,
              C("2026.09.23 15:28:24", "2880.70", "2880.70", "0.0", L, "147.54", SL), "AgVecLine(AgTgTextS6C(c, 3, 2, 5, 1, 7), %d)" % (EV + 3)))
cases.append(("b3_locks_line", "B3: lines a zero count leaves out, here with a count, in order: the failures, the locks of the ended day", 1,
              C("2026.10.20 01:00:04", "2140.50", "2140.50", "0.0", A, "117.73", SA),
              "AgVecLine(AgTgTextS14(c, D'2026.10.19 01:00:00', -31.56, 12.40, 1, 117.73), %d)" % (EV + 3)))


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


def esc_html(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


s4_whole = "\n".join(drafts["S4 lock, the daily limit"])
s4_head, s4_rest = s4_whole.split("\n", 1)

# the helpers (F3 to F6, F9, F10): (name, kind, expression, expected); kind "eq"
# compares with an ASCII literal, "md5" with the md5 of the expected text,
# "true" asserts the expression
helpers = [
 ("tg_fmt_stamp_drops_the_seconds", "eq", "AgTgStamp(D'2026.10.21 15:34:59')", "21/10/2026 15:34"),
 ("tg_fmt_stamp_pads_day_month_and_hour", "eq", "AgTgStamp(D'2026.01.02 03:04:05')", "02/01/2026 03:04"),
 ("tg_fmt_date", "eq", "AgTgDate(D'2026.10.19 01:00:00')", "19/10/2026"),
 ("tg_fmt_money_zero", "eq", "AgTgMoneyText(0.0)", "0.00"),
 ("tg_fmt_money_under_a_thousand", "eq", "AgTgMoneyText(999.99)", "999.99"),
 ("tg_fmt_money_a_thousand", "eq", "AgTgMoneyText(1000.0)", "1,000.00"),
 ("tg_fmt_money_the_reference_balance", "eq", "AgTgMoneyText(2544.33)", "2,544.33"),
 ("tg_fmt_money_millions_rounded_to_the_cent", "eq", "AgTgMoneyText(1234567.891)", "1,234,567.89"),
 ("tg_fmt_money_negative", "eq", "AgTgMoneyText(-1893.5)", "-1,893.50"),
 ("tg_fmt_money_rounds_to_an_unsigned_zero", "eq", "AgTgMoneyText(-0.004)", "0.00"),
 ("tg_fmt_currency_usd_eur_gbp_and_a_code", "true",
  "AgTgCurrencySign(\"USD\") == \"$\" && AgTgCurrencySign(\"EUR\") == ShortToString(0x20AC)"
  " && AgTgCurrencySign(\"GBP\") == ShortToString(0x00A3) && AgTgCurrencySign(\"ILS\") == \"ILS\"", None),
 ("tg_fmt_amount_with_its_currency", "true",
  "AgTgWithCurrency(\"200\", \"$\") == \"200$\" && AgTgWithCurrency(\"200\", ShortToString(0x20AC)) == \"200\" + ShortToString(0x20AC)"
  " && AgTgWithCurrency(\"200\", \"ILS\") == \"200 ILS\" && AgTgWithCurrency(\"200\", \"\") == \"200\"", None),
 ("tg_fmt_signed_with_currency", "true",
  "AgTgSignedWithCurrency(-130.20, \"$\") == \"-130.20$\" && AgTgSignedWithCurrency(90.96, \"$\") == \"+90.96$\""
  " && AgTgSignedWithCurrency(0.0, \"$\") == \"0.00$\" && AgTgSignedWithCurrency(-0.004, \"$\") == \"0.00$\""
  " && AgTgSignedWithCurrency(-1234.5, \"ILS\") == \"-1,234.50 ILS\"", None),
 ("tg_fmt_duration_0", "md5", "AgTgDuration(0)", "0 שניות"),
 ("tg_fmt_duration_1", "md5", "AgTgDuration(1)", "שנייה אחת"),
 ("tg_fmt_duration_119", "md5", "AgTgDuration(119)", "119 שניות"),
 ("tg_fmt_duration_120", "md5", "AgTgDuration(120)", "2 דקות"),
 ("tg_fmt_duration_179", "md5", "AgTgDuration(179)", "2 דקות"),
 ("tg_fmt_duration_7199", "md5", "AgTgDuration(7199)", "119 דקות"),
 ("tg_fmt_duration_7200", "md5", "AgTgDuration(7200)", "2 שעות"),
 ("tg_fmt_duration_7260", "md5", "AgTgDuration(7260)", "2 שעות ודקה אחת"),
 ("tg_fmt_duration_7320", "md5", "AgTgDuration(7320)", "2 שעות ו 2 דקות"),
 ("tg_fmt_ago_4", "md5", "AgTgAgo(4)", "רגע"),
 ("tg_fmt_ago_5", "md5", "AgTgAgo(5)", "5 שניות"),
 ("tg_fmt_sweep_line_with_both_zero_is_absent", "eq", "AgTgSweepNow(0, 0)", ""),
 ("tg_fmt_sweep_line_positions_only", "md5", "AgTgSweepNow(3, 0)", "🧹 סוגר עכשיו 3 פוזיציות"),
 ("tg_fmt_sweep_line_singular", "md5", "AgTgSweepNow(1, 1)", "🧹 סוגר עכשיו פוזיציה אחת ומוחק פקודה ממתינה אחת"),
 ("tg_fmt_add_leaves_an_empty_part_out", "true",
  "AgTgAdd(\"a\", \"\") == \"a\" && AgTgAdd(\"\", \"b\") == \"b\" && AgTgAdd(\"a\", \"b\") == \"a\\nb\"", None),
 ("tg_fmt_html_escape", "eq", "AgTgHtmlEscape(\"a&b<c>d\")", "a&amp;b&lt;c&gt;d"),
 ("tg_fmt_html_escape_keeps_quotes_and_escapes_an_entity_again", "eq",
  "AgTgHtmlEscape(\"\\\"x\\\" 'y' &amp;\")", "\"x\" 'y' &amp;amp;"),
 ("tg_fmt_html_bold_wraps_line_one_after_the_escape", "eq",
  "AgTgHtmlBold(\"head <1>\\nline & 2\\nline 3\")", "<b>head &lt;1&gt;</b>\nline &amp; 2\nline 3"),
 ("tg_fmt_html_bold_one_line", "eq", "AgTgHtmlBold(\"only\")", "<b>only</b>"),
 ("tg_fmt_html_bold_on_the_s4_reference", "md5s4",
  "AgTgHtmlBold(AgTgFinish(AgTgTextS4(c, 1, D'2026.09.16 01:00:00', 5.50, 200, -130.20, 3, 0, \"$\"), 0, 0, 0, \"\"))",
  "<b>" + esc_html(s4_head) + "</b>\n" + esc_html(s4_rest)),
 ("tg_fmt_plain_after_a_400_to_the_html_form_only", "true",
  "AgTgPlainAfter(400, true) && !AgTgPlainAfter(400, false) && !AgTgPlainAfter(200, true)"
  " && !AgTgPlainAfter(429, true) && !AgTgPlainAfter(-1, true)", None),
 ("tg_fmt_build_line_classes", "true",
  "AgTgCarriesBuild(\"S1\") && AgTgCarriesBuild(\"S2+S1\") && AgTgCarriesBuild(\"S2\") && AgTgCarriesBuild(\"STATUS\")"
  " && AgTgCarriesBuild(\"REPLY\") && AgTgCarriesBuild(\"S14\") && !AgTgCarriesBuild(\"S4\") && !AgTgCarriesBuild(\"S2+S16\")"
  " && !AgTgCarriesBuild(\"S3\") && !AgTgCarriesBuild(\"S11\") && !AgTgCarriesBuild(\"LIVE_STOP\")", None),
 ("tg_fmt_finish_without_a_build_line", "true",
  "AgTgFinish(\"x\", 0, 0, 0, \"\") == \"x\" && AgTgFinish(\"x\", 0, 0, 0, \"b\") == \"x\\nb\"", None),
]

# the helpers of pass B5 (R3, R4): the PNL line by the sign of the result and
# not computed, and the open trades line by its count; kind "truec" sets the
# common lines given, here with 3 open positions, then asserts
helpers_b5 = [
 ("tg_fmt_pnl_line_above_zero", "md5", "AgTgResultLine(AG_TG_PNL_ACTIVE, 12.40, \"$\")", "📈 סה״כ PNL: +12.40$"),
 ("tg_fmt_pnl_line_zero", "md5", "AgTgResultLine(AG_TG_PNL_ACTIVE, 0.0, \"$\")", "📉 סה״כ PNL: 0.00$"),
 ("tg_fmt_pnl_line_a_figure_that_prints_zero", "true",
  "AgTgResultLine(AG_TG_PNL_ACTIVE, 0.004, \"$\") == AgTgResultLine(AG_TG_PNL_ACTIVE, 0.0, \"$\")"
  " && AgTgResultLine(AG_TG_PNL_LOCKED, -0.004, \"$\") == AgTgResultLine(AG_TG_PNL_ACTIVE, 0.0, \"$\")", None),
 ("tg_fmt_pnl_line_below_zero", "md5", "AgTgResultLine(AG_TG_PNL_ACTIVE, -130.20, \"$\")", "📉 סה״כ PNL: -130.20$"),
 ("tg_fmt_pnl_line_below_zero_with_a_code", "md5", "AgTgResultLine(AG_TG_PNL_LOCKED, -1893.50, \"ILS\")",
  "📉 סה״כ PNL: -1,893.50 ILS"),
 ("tg_fmt_pnl_line_not_computed", "md5", "AgTgResultLine(AG_TG_PNL_NONE, -50.00, \"$\")", "📉 סה״כ PNL: עדיין לא חושב"),
 ("tg_fmt_open_line_zero", "md5", "AgTgOpenLine(0)", "📂 עסקאות פתוחות: אין"),
 ("tg_fmt_open_line_one", "md5", "AgTgOpenLine(1)", "📂 עסקאות פתוחות: 1"),
 ("tg_fmt_open_line_several", "md5", "AgTgOpenLine(12)", "📂 עסקאות פתוחות: 12"),
 ("tg_fmt_open_line_left_out_where_the_sweep_line_counts", "truec",
  "StringFind(AgTgTextS2(c, 1), AgTgOpenLine(3)) > 0"
  " && StringFind(AgTgTextS4(c, 1, D'2026.09.16 01:00:00', 5.50, 200, -130.20, 3, 0, \"$\"), AgTgOpenLine(3)) < 0"
  " && StringFind(AgTgTextS4Peak(c, D'2026.09.27 01:00:00', 253.00, 94.31, 90.96, 3, 0, \"$\"), AgTgOpenLine(3)) < 0"
  " && StringFind(AgTgTextS16(c, D'2026.09.24 01:00:00', 1, 3, 3, 0, -1), AgTgOpenLine(3)) < 0", s4c),
]


# the Manual Lockout build, R4 and ML-31: S5 leaves the open trades line out,
# its sweep line giving the count; S25 keeps it
helpers_ml = [
 ("ml_fmt_open_line_left_out_of_s5_with_its_sweep_line", "truec",
  "StringFind(AgTgTextS5(c, D'2026.10.22 15:00:05', D'2026.10.23 01:00:00', 1800, 3, 0), AgTgOpenLine(3)) < 0"
  " && StringFind(AgTgTextS25(c, 1, D'2026.10.22 15:00:05', 0, 0), AgTgOpenLine(3)) > 0", s4c),
]


def mql_str(s):
    assert all(ord(ch) < 128 for ch in s), "a non ASCII literal: " + repr(s)
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


code = []
used = set()
for name, label, line, common, expr in cases:
    d = drafts[label]
    want = d[line] if line is not None else "\n".join(d)
    used.add(label)
    if common:
        code.append("   " + common)
    code.append('   AgVecMd5("tg_text_%s", %s, "%s");' % (name, expr, md5(want)))
def emit(helper_list):
    for name, kind, expr, want in helper_list:
        if kind == "eq":
            code.append('   AgVecCheck("%s", %s == %s, %s);' % (name, expr, mql_str(want), expr))
        elif kind == "md5":
            code.append('   AgVecMd5("%s", %s, "%s");' % (name, expr, md5(want)))
        elif kind == "md5s4":
            code.append("   " + s4c)
            code.append('   AgVecMd5("%s", %s, "%s");' % (name, expr, md5(want)))
        elif kind == "truec":
            code.append("   " + want)
            code.append('   AgVecCheck("%s", %s, "");' % (name, expr))
        else:
            code.append('   AgVecCheck("%s", %s, "");' % (name, expr))


code.append("")
code.append("   //--- the display formatters and the F10 helpers, format pass B3: the")
code.append("   //--- time, the money and the currency, the durations, the zero counts,")
code.append("   //--- the build line by class, the HTML escape and the plain text decision")
emit(helpers)
code.append("")
code.append("   //--- pass B5, R3 and R4: the PNL line above zero, at zero, below zero")
code.append("   //--- and not computed; the open trades line at none, one and several,")
code.append("   //--- and left out of the lock messages whose sweep line gives the count")
emit(helpers_b5)
code.append("")
code.append("   //--- the Manual Lockout build, R4 and ML-31: the open trades line left")
code.append("   //--- out of S5, whose sweep line counts, and kept in S25")
emit(helpers_ml)
for l in code:
    assert all(ord(ch) < 128 for ch in l), "a non ASCII vector line: " + l
unused = [l for l in drafts if l not in used]

v = open(VEC, "rb").read().decode("utf-8").replace("\r\n", "\n")
head = ("   //--- TG-S8, the Hebrew: each draft of item 13 rendered with its example\n"
        "   //--- values, the md5 of the UTF-8 bytes against the value computed from the\n"
        "   //--- draft's own text, independently, by a script at the build\n"
        "   AgTgCommon c;\n")
anchor = '   PrintFormat("AGVEC|SUMMARY|%d/%d", g_pass, g_total);\n  }\n'
assert v.count(head) == 1 and v.count(anchor) == 1
i = v.index(head) + len(head)
j = v.index(anchor)
v = v[:i] + "\n".join(code) + "\n\n" + v[j:]
open(VEC, "wb").write(v.replace("\n", "\r\n").encode("utf-8"))
sys.stdout.buffer.write(("render vectors %d, helper vectors %d, of which pass B5 %d and the Manual Lockout build %d,"
                         " drafts not rendered by any vector: %s\n"
                         % (len(cases), len(helpers) + len(helpers_b5) + len(helpers_ml), len(helpers_b5),
                            len(helpers_ml), unused)).encode("utf-8"))
