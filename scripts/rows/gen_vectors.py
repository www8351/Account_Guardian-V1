# Generates the Telegram alerts vector block for AgPhase2StateVectors.mq5 and
# inserts it before the final SUMMARY line. The md5 of each draft's UTF-8 bytes
# is computed here, independently, from item 13 of the addendum (TG-S8).
import hashlib, sys

ROOT = sys.argv[1]
ADD = ROOT + r"\docs\PLAN_TELEGRAM_ALERTS_ADDENDUM_TG1B.md"
VEC = ROOT + r"\MQL5\Scripts\AccountGuardian\AgPhase2StateVectors.mq5"

t = open(ADD, "rb").read().decode("utf-8").replace("\r\n", "\n").split("\n")
s = t.index("```text", t.index("## 13. Hebrew drafts"))
e = t.index("```", s + 1)
drafts = {}
cur = None
for l in t[s + 1:e]:
    if l.startswith("=== ") and l.endswith(" ==="):
        cur = l[4:-4]
        drafts[cur] = []
    elif l == "":
        cur = None
    elif cur is not None:
        drafts[cur].append(l)

def md5(text):
    return hashlib.md5(text.encode("utf-8")).hexdigest().upper()

A, L, N = "AG_TG_PNL_ACTIVE", "AG_TG_PNL_LOCKED", "AG_TG_PNL_NONE"
SA, SL, SS, SH, SN = "AG_STATE_ACTIVE", "AG_STATE_LOCKED", "AG_STATE_SYNCING", "AG_STATE_SAFE_HALT", "AG_TG_STATE_NOT_RUNNING"

def C(t_, bal, eq, pnl, mode, lim, st):
    return "AgVecC(c, D'%s', %s, %s, %s, %s, %s, %s);" % (t_, bal, eq, pnl, mode, lim, st)

FIN = 'AgTgFinish(%s, 0, 0, 0, "build=TG")'
# (name, label, line or None, common, expression)
cases = [
 ("s1_start", "S1 start", None, C("2026.10.19 09:00:03", "2172.06", "2172.06", "0.0", A, "126.21", SA), FIN % "AgTgTextS1(c, 5.50, 200, 126.21)"),
 ("s1_restarted", "S1 restarted in place", None, C("2026.10.19 11:42:10", "2172.06", "2172.06", "0.0", A, "126.21", SA), FIN % "AgTgTextS1Restarted(c, 5, 126.21)"),
 ("s2_stop", "S2 stop", None, C("2026.10.19 18:00:00", "2217.06", "2217.06", "45.00", A, "126.21", SA), FIN % "AgTgTextS2(c, 1)"),
 ("s3_refused", "S3 refused start", None, C("2026.09.07 13:19:28", "2294.76", "2294.76", "0.0", N, "0.0", SN), 'AgTgFinish(AgTgTextS3Refused(c), 0, 0, 300, "build=TG")'),
 ("s3_second", "S3 second instance refused", None, C("2026.08.03 01:48:42", "2133.00", "2133.00", "0.0", N, "0.0", SA), FIN % "AgTgTextS3Second(c)"),
 ("s3_crash", "S3 SAFE_HALT after repeated crashes", None, C("2026.08.04 16:37:04", "2133.00", "2133.00", "0.0", N, "0.0", SH), FIN % "AgTgTextS3Crash(c, 4, 300)"),
 ("s3_persisted", "S3 SAFE_HALT persists after a restart", None, C("2026.08.04 16:37:54", "2133.00", "2133.00", "0.0", N, "0.0", SH), FIN % "AgTgTextS3Persisted(c, D'2026.08.04 16:37:04')"),
 ("s4_daily", "S4 lock, the daily limit", None, C("2026.09.15 18:36:17", "2300.16", "2164.56", "-130.20", A, "126.21", SL), FIN % "AgTgTextS4(c, 1, D'2026.09.16 01:00:00', 5.50, 200, -130.20, 3, 0)"),
 ("s4_peak", "S4 lock, give back from the daily peak", None, C("2026.09.26 16:35:35", "3138.34", "2976.30", "90.96", A, "158.69", SL), FIN % "AgTgTextS4Peak(c, D'2026.09.27 01:00:00', 253.00, 253.00 - 158.69, 90.96, 3, 0)"),
 ("s6_complete", "S6 enforcement result", None, C("2026.09.23 15:28:24", "2880.70", "2880.70", "0.0", L, "147.54", SL), FIN % "AgTgTextS6C(c, 3, 2, 5, 0, 7)"),
 ("s6_session", "S6 position held, trade session closed", None, C("2026.09.26 16:35:38", "3138.34", "3138.30", "0.0", L, "158.69", SL), FIN % "AgTgTextS6H(c, 781624897, false, 1, \"XAUUSD.ecn\", D'2026.09.28 01:01:00', 10, 60)"),
 ("s6_hard_stop", "S6 position held, hard stop", None, C("2026.09.23 15:30:00", "2880.70", "2850.10", "-30.60", L, "147.54", SL), FIN % "AgTgTextS6H(c, 753031555, false, 2, \"XAUUSD.ecn\", 0, 10, 60)"),
 ("s6_flattened", "S6 held position finally closed", None, C("2026.09.28 01:01:05", "2998.80", "2998.80", "0.0", L, "158.69", SL), FIN % "AgTgTextS6F(c, 781624897, false, \"XAUUSD.ecn\")"),
 ("s7", "S7 trade opened while locked", None, C("2026.09.23 15:56:12", "2880.62", "2880.62", "-0.08", L, "147.54", SL), FIN % "AgTgTextS7(c, 753338779, \"XAUUSD.ecn\", 1)"),
 ("s8_released", "S8 lock released", None, C("2026.09.27 01:00:03", "2998.84", "2998.80", "-0.04", A, "164.94", SA), FIN % "AgTgTextS8Released(c, D'2026.09.27 01:00:00', 164.94)"),
 ("s8_again", "S8 locked again at the new day", None, C("2026.08.26 01:00:10", "2027.98", "1919.14", "-108.84", L, "101.40", SL), FIN % "AgTgTextS8Again(c, D'2026.08.27 01:00:00')"),
 ("s9", "S9 approaching the limit", None, C("2026.10.19 14:05:12", "2172.06", "2071.09", "-100.97", A, "126.21", SA), FIN % "AgTgTextS9(c, 80, 25.24)"),
 ("s10", "S10 broker connection restored", None, C("2026.08.18 12:13:43", "2133.13", "2133.13", "0.0", A, "106.66", SA), FIN % "AgTgTextS10(c, D'2026.08.18 12:08:42', D'2026.08.18 12:13:43', 301)"),
 ("s11", "S11 Telegram reachable again", None, C("2026.10.19 12:20:40", "2172.06", "2172.06", "0.0", A, "126.21", SA), FIN % "AgTgTextS11(c, D'2026.10.19 12:00:05', D'2026.10.19 12:20:40', 4)"),
 ("s12_blocked_locked", "S12 algorithmic trading blocked", None, C("2026.09.28 10:44:02", "2805.35", "2805.35", "-193.49", L, "164.94", SL), FIN % "AgTgTextS12Blocked(c, 1)"),
 ("s12_restored", "S12 trading restored", None, C("2026.09.28 10:47:03", "2805.35", "2805.36", "-193.48", L, "164.94", SL), FIN % "AgTgTextS12Restored(c)"),
 ("s14", "S14 end of day summary", None, C("2026.10.20 01:00:04", "2140.50", "2140.50", "0.0", A, "117.73", SA), FIN % "AgTgTextS14(c, D'2026.10.19 01:00:00', -31.56, 12.40, 0, 117.73)"),
 ("s15", "S15 resumed after SAFE_HALT", None, C("2026.08.04 16:39:54", "2133.00", "2133.00", "0.0", N, "0.0", SS), FIN % "AgTgTextS15(c)"),
 ("s16", "S16 lock restored at start", None, C("2026.09.23 16:57:35", "2880.70", "2879.58", "-1.12", L, "147.54", SL), FIN % "AgTgTextS16(c, D'2026.09.24 01:00:00', 1, 3, 1, 0, -1)"),
 ("s17", "S17 file write failure", None, C("2026.10.19 14:05:12", "2172.06", "2172.06", "0.0", L, "126.21", SL), FIN % "AgTgTextS17(c, 1, 1)"),
 ("s18", "S18 previous session cut off", None, C("2026.09.15 22:35:38", "2172.06", "2172.06", "0.0", N, "0.0", SS), FIN % "AgTgTextS18(c, 28)"),
 ("s19_locked", "S19 limit change refused while locked", None, C("2026.08.18 15:36:30", "239.63", "239.63", "-1893.50", L, "106.66", SL), FIN % "AgTgTextS19Locked(c, 1, 10.00, 200, 106.66)"),
 ("s19_raise", "S19 raise held until the next day", None, C("2026.09.07 14:32:54", "2294.76", "2294.76", "0.0", A, "114.74", SA), FIN % "AgTgTextS19Raise(c, 126.21, 114.74)"),
 ("s20", "S20 server clock jump", None, C("2026.08.10 01:00:00", "2003.46", "2003.46", "0.0", A, "100.17", SA), FIN % "AgTgTextS20(c, 259200)"),
 ("s21", "S21 history read failure", None, C("2026.10.19 14:05:12", "2172.06", "2172.06", "0.0", N, "0.0", SS), FIN % "AgTgTextS21(c)"),
 ("s22", "S22 not protecting yet", None, C("2026.10.19 09:05:03", "2172.06", "2172.06", "0.0", N, "0.0", SS), FIN % "AgTgTextS22(c, 300, 1)"),
 ("s24", "S24 another instance took over", None, C("2026.10.19 14:05:12", "2172.06", "2172.06", "0.0", A, "126.21", SA), FIN % "AgTgTextS24(c)"),
 ("status_active", "NEW: periodic status, at each slot and as the reply to the check command, while ACTIVE", None, C("2026.10.21 12:00:01", "2172.06", "2172.06", "0.0", A, "126.21", SA), FIN % "AgTgTextStatus(c, 1, -1, 0, 126.21)"),
 ("status_locked", "NEW: periodic status, while LOCKED", None, C("2026.09.23 16:00:01", "2880.70", "2880.70", "0.0", L, "147.54", SL), FIN % "AgTgTextStatus(c, 1, -1, D'2026.09.24 01:00:00', 0)"),
 ("not_responding", "NEW: guardian not responding while the terminal runs", None, C("2026.10.21 14:05:12", "2172.06", "2150.10", "0.0", N, "0.0", SN), FIN % "AgTgTextNotResponding(c, 15, false, true)"),
 ("not_running", "NEW: guardian not running when the alerts service starts", None, C("2026.10.21 09:01:00", "2172.06", "2172.06", "0.0", N, "0.0", SN), FIN % "AgTgTextNotRunning(c, 60)"),
 ("responds_again", "NEW: guardian responds again, no restart", None, C("2026.10.21 14:05:54", "2172.06", "2150.10", "-21.96", A, "126.21", SA), FIN % "AgTgTextRespondsAgain(c, 42)"),
 ("s12_active", "NEW: S12 algorithmic trading blocked while ACTIVE", None, C("2026.10.21 10:44:02", "2805.35", "2805.35", "12.40", A, "164.94", SA), FIN % "AgTgTextS12Blocked(c, 1)"),
 ("b_s6_order_session", "BUILD: S6 a pending order held, trade session closed, next open unknown", None, C("2026.09.26 16:35:38", "3138.34", "3138.30", "0.0", L, "158.69", SL), FIN % "AgTgTextS6H(c, 781624901, true, 1, \"XAUUSD.ecn\", 0, 10, 60)"),
 ("b_s6_refuse", "BUILD: S6 position held, the server did not carry out the close", None, C("2026.09.23 15:30:00", "2880.70", "2850.10", "-30.60", L, "147.54", SL), FIN % "AgTgTextS6H(c, 753031555, false, 3, \"XAUUSD.ecn\", 0, 10, 60)"),
 ("b_s6_order_hold", "BUILD: S6 pending order held, the server did not carry out the deletion", None, C("2026.09.23 15:30:00", "2880.70", "2850.10", "-30.60", L, "147.54", SL), FIN % "AgTgTextS6H(c, 753031560, true, 5, \"XAUUSD.ecn\", 0, 10, 60)"),
 ("b_s6_mode", "BUILD: S6 position held, trading in the symbol disabled", None, C("2026.09.26 16:35:38", "3138.34", "3138.30", "0.0", L, "158.69", SL), FIN % "AgTgTextS6H(c, 781624897, false, 4, \"XAUUSD.ecn\", 0, 10, 60)"),
 ("b_s6_order_hard_stop", "BUILD: S6 pending order held, hard stop", None, C("2026.09.23 15:30:00", "2880.70", "2850.10", "-30.60", L, "147.54", SL), FIN % "AgTgTextS6H(c, 753031560, true, 2, \"XAUUSD.ecn\", 0, 10, 60)"),
 ("b_s6_order_flattened", "BUILD: S6 held pending order finally deleted", None, C("2026.09.28 01:01:05", "2998.80", "2998.80", "0.0", L, "158.69", SL), FIN % "AgTgTextS6F(c, 781624901, true, \"XAUUSD.ecn\")"),
 ("b_s6_complete_singular", "BUILD: S6 enforcement result, one position and one pending order", None, C("2026.09.23 15:28:24", "2880.70", "2880.70", "0.0", L, "147.54", SL), FIN % "AgTgTextS6C(c, 1, 1, 2, 0, 3)"),
 ("b_s7_later", "BUILD: S7 closed on a later attempt", None, C("2026.09.23 15:56:12", "2880.62", "2880.62", "-0.08", L, "147.54", SL), FIN % "AgTgTextS7(c, 753338779, \"XAUUSD.ecn\", 2)"),
 ("b_s17_corrupt", "BUILD: S17 a file found corrupt at the start", None, C("2026.10.21 09:00:05", "2172.06", "2172.06", "0.0", N, "0.0", SS), FIN % "AgTgTextS17(c, 4, 2)"),
 ("b_s12_syncing", "BUILD: S12 blocked while SYNCING or SAFE_HALT", None, C("2026.10.21 09:00:20", "2172.06", "2172.06", "0.0", N, "0.0", SS), FIN % "AgTgTextS12Blocked(c, 2)"),
 ("b_s16_restarted", "BUILD: S16 restarted in place", None, C("2026.09.23 16:57:35", "2880.70", "2880.70", "0.0", L, "147.54", SL), FIN % "AgTgTextS16(c, D'2026.09.24 01:00:00', 1, 3, 0, 0, 5)"),
 ("b_status_syncing", "BUILD: periodic status while SYNCING", None, C("2026.10.21 08:00:01", "2172.06", "2172.06", "0.0", N, "0.0", SS), FIN % "AgTgTextStatus(c, 0, -1, 0, 0)"),
 ("b_status_not_running", "BUILD: periodic status, the guardian not running, its mutex heartbeat stale", None, C("2026.10.21 16:00:01", "2172.06", "2172.06", "0.0", N, "0.0", SN), FIN % "AgTgTextStatus(c, 75, -1, 0, 0)"),
]
# single lines of the wording lists
base_c = C("2026.10.19 14:05:12", "2172.06", "2172.06", "0.0", A, "126.21", SA)
for i in range(10):
    cases.append(("s2_reason_%d" % i, "S2 reason wordings", i, base_c, "AgVecLine(AgTgTextS2(c, %d), 7)" % i))
cases.append(("delay_line", "delay line, for any message sent late", 0, None, 'AgVecLine(AgTgFinish("x", 0, 0, 125, "b"), 1)'))
for i, st in enumerate([SA, SL, SS, SH, SN]):
    cases.append(("state_word_%d" % i, "guardian state wordings", i,
                  C("2026.10.19 14:05:12", "2172.06", "2172.06", "0.0", N, "0.0", st), "AgVecLine(AgTgCommonLines(c), 5)"))
cases.append(("not_computed", "result not computed yet", 0, None, "AgTgPnlLine(AG_TG_PNL_NONE, 0.0, 0.0)"))
s4c = C("2026.09.15 18:36:17", "2300.16", "2164.56", "-130.20", A, "126.21", SL)
for i, kind in enumerate([1, 2, 3]):
    cases.append(("s4_crossed_%d" % kind, "S4 crossed limit wordings, in order: percent leg, currency leg, held floor, daily peak", i,
                  s4c, "AgVecLine(AgTgTextS4(c, %d, D'2026.09.16 01:00:00', 5.50, 200, -130.20, 3, 0), 8)" % kind))
for i in range(4):
    cases.append(("s12_block_%d" % (i + 1), "S12 block wordings, in order: terminal button, EA setting, account, broker, while ACTIVE", i,
                  C("2026.09.28 10:44:02", "2805.35", "2805.35", "-193.49", L, "164.94", SL), "AgVecLine(AgTgTextS12Blocked(c, %d), 7)" % (i + 1)))
cases.append(("s12_block_active_line", "S12 block wordings, in order: terminal button, EA setting, account, broker, while ACTIVE", 4,
              C("2026.10.21 10:44:02", "2805.35", "2805.35", "12.40", A, "164.94", SA), "AgVecLine(AgTgTextS12Blocked(c, 1), 8)"))
s16c = C("2026.09.23 16:57:35", "2880.70", "2879.58", "-1.12", L, "147.54", SL)
for i, pair in enumerate([(1, 1), (1, 2), (1, 4), (3, 4), None, (2, 0)]):
    if pair is None:
        continue   # the daily peak source: no code path names it, the peak witness fires as DAILY_BREACH
    reason, mask = pair
    cases.append(("s16_source_%d" % i, "S16 lock source wordings", i, s16c,
                  "AgVecLine(AgTgTextS16(c, D'2026.09.24 01:00:00', %d, %d, 1, 0, -1), 8)" % (reason, mask)))
cases.append(("s22_reason_2", "S22 second reason wording", 0,
              C("2026.10.19 09:05:03", "2172.06", "2172.06", "0.0", N, "0.0", SS), "AgVecLine(AgTgTextS22(c, 300, 2), 8)"))
for i, st in enumerate([SS, SH, SN]):
    cases.append(("status_head_%d" % i, "NEW: periodic status headline wordings, in order: SYNCING, SAFE_HALT, not running", i,
                  C("2026.10.21 12:00:01", "2172.06", "2172.06", "0.0", N, "0.0", st), "AgVecLine(AgTgTextStatus(c, 1, -1, 0, 0), 0)"))
cases.append(("status_age_line", "NEW: periodic status, the age line when the guardian's figures are old", 0,
              C("2026.10.21 12:00:01", "2172.06", "2172.06", "0.0", A, "126.21", SA), "AgVecLine(AgTgTextStatus(c, 1, 95, 0, 126.21), 8)"))
cases.append(("not_recorded_line", "NEW: guardian not responding, the reason line when it stopped without recording one", 0,
              C("2026.10.21 14:05:12", "2172.06", "2150.10", "0.0", N, "0.0", SN), "AgVecLine(AgTgTextNotResponding(c, 15, true, true), 8)"))
cases.append(("overflow_line", "NEW: line added after the queue overflowed", 0, None, 'AgVecLine(AgTgFinish("x", 12, 0, 0, "b"), 1)'))
cases.append(("held_back_line", "NEW: line added when similar events were held back", 0, None, 'AgVecLine(AgTgFinish("x", 0, 3, 0, "b"), 1)'))
s17c = C("2026.10.19 14:05:12", "2172.06", "2172.06", "0.0", L, "126.21", SL)
for i, kind in enumerate([2, 3, 5, 0]):
    cases.append(("s17_file_%d" % kind, "BUILD: S17 file names, in order: halt, floor, queue, unknown", i, s17c,
                  "AgVecLine(AgTgTextS17(c, %d, 1), 7)" % kind))
cases.append(("s19_currency_line", "BUILD: S19 the currency limit entered while locked", 0,
              C("2026.08.18 15:36:30", "239.63", "239.63", "-1893.50", L, "106.66", SL), "AgVecLine(AgTgTextS19Locked(c, 2, 10.00, 150, 106.66), 7)"))
cases.append(("locked_profit_line", "BUILD: the day's result while LOCKED and in profit", 0, None, "AgTgPnlLine(AG_TG_PNL_LOCKED, 5.00, 147.54)"))
cases.append(("singular_delay", "BUILD: the singular forms, in order: the delay line, the crash loop line, a hard stop of one attempt", 0, None,
              'AgVecLine(AgTgFinish("x", 0, 0, 1, "b"), 1)'))
cases.append(("singular_crash", "BUILD: the singular forms, in order: the delay line, the crash loop line, a hard stop of one attempt", 1,
              C("2026.08.04 16:37:04", "2133.00", "2133.00", "0.0", N, "0.0", SH), "AgVecLine(AgTgTextS3Crash(c, 1, 300), 7)"))
cases.append(("singular_hard_stop", "BUILD: the singular forms, in order: the delay line, the crash loop line, a hard stop of one attempt", 2,
              base_c, 'AgVecLine(AgTgTextS6H(c, 1, false, 2, "", 0, 1, 60), 0)'))

code = []
used = set()
for name, label, line, common, expr in cases:
    d = drafts[label]
    want = d[line] if line is not None else "\n".join(d)
    used.add(label)
    if common:
        code.append("   " + common)
    code.append('   AgVecMd5("tg_text_%s", %s, "%s");' % (name, expr, md5(want)))
unused = [l for l in drafts if l not in used]

HAND = r'''
   //================================================================
   //--- TG, the Telegram alerts build (TG-1 (B) of 2026-10-20, design
   //--- addendum docs/PLAN_TELEGRAM_ALERTS_ADDENDUM_TG1B.md item 12). Pure
   //--- functions of AlertQueue.mqh, AlertJson.mqh and AlertText.mqh only:
   //--- no file, no global variable and no network call is touched here.
   //================================================================

   //--- TG-S12, the queue: a round trip of every code, the checksum, a cut
   //--- file, the bound, the acknowledgement, the numbering, ASCII bytes
   int tg_codes[21] = {AG_TG_S1, AG_TG_S2, AG_TG_S3, AG_TG_S4, AG_TG_S6C, AG_TG_S6H, AG_TG_S6F,
                       AG_TG_S7, AG_TG_S8, AG_TG_S9, AG_TG_S10, AG_TG_S12, AG_TG_S15, AG_TG_S16,
                       AG_TG_S17, AG_TG_S18, AG_TG_S19, AG_TG_S20, AG_TG_S21, AG_TG_S22, AG_TG_S24};
   AgTgEvent tg_ev[];
   ArrayResize(tg_ev, 21);
   for(int k = 0; k < 21; k++)
     {
      tg_ev[k].seq      = 100 + k;
      tg_ev[k].code     = tg_codes[k];
      tg_ev[k].server_t = (long)D'2026.10.21 12:00:00' + k;
      tg_ev[k].local_t  = (long)D'2026.10.21 12:00:01' + k;
      tg_ev[k].state    = (k % 4) + 1;
      tg_ev[k].pnl_mode = k % 3;
      tg_ev[k].balance  = 2172.06;
      tg_ev[k].equity   = 2150.10;
      tg_ev[k].pnl      = -21.96;
      tg_ev[k].limit    = 126.21;
      for(int x = 0; x < AG_TGQ_X_COUNT; x++)
         tg_ev[k].x[x] = (x == 0) ? 781624897.0 : (x == 1 ? 5.5 : (double)(k * 10 + x));
     }
   AgTgSnapshot tg_sn;
   tg_sn.local_t = (long)D'2026.10.21 12:00:02'; tg_sn.server_t = (long)D'2026.10.21 12:00:01';
   tg_sn.state = AG_STATE_ACTIVE; tg_sn.reason = 0; tg_sn.seconds_in_state = 3600; tg_sn.connected = 1;
   tg_sn.block = 0; tg_sn.pnl_mode = AG_TG_PNL_ACTIVE; tg_sn.balance = 2172.06; tg_sn.floating = -21.96;
   tg_sn.equity = 2150.10; tg_sn.pnl = -21.96; tg_sn.limit = 126.21; tg_sn.live_limit = 126.21;
   tg_sn.enforced_limit = 126.21; tg_sn.peak = 0.0; tg_sn.peak_level = -126.21;
   tg_sn.anchor = (long)D'2026.10.21 01:00:00'; tg_sn.locked_until = 0; tg_sn.limit_snap = 0.0;
   tg_sn.base_snap = 0.0; tg_sn.percent = 5.5; tg_sn.currency = 200.0; tg_sn.sweep_open = 0; tg_sn.sweep_held = 0;
   string tg_q = AgTgQueueSerialize(990000021, 121, (long)D'2026.10.21 01:00:00', 3,
                                    AgTgSnapshotLine(tg_sn, "TG"), tg_ev, 21);
   long tg_login = 0, tg_next = 0, tg_latch = 0; int tg_mask = 0, tg_count = 0;
   AgTgSnapshot tg_sn2; string tg_build = "", tg_why = ""; AgTgEvent tg_back[];
   bool tg_ok = AgTgQueueParse(tg_q, tg_login, tg_next, tg_latch, tg_mask, tg_sn2, tg_build, tg_back, tg_count, tg_why);
   AgVecCheck("tg_q_roundtrip_parses", tg_ok, tg_why);
   AgVecCheck("tg_q_roundtrip_header_e_and_n",
              tg_login == 990000021 && tg_next == 121 && tg_latch == (long)D'2026.10.21 01:00:00'
              && tg_mask == 3 && tg_build == "TG" && tg_sn2.anchor == tg_sn.anchor
              && MathAbs(tg_sn2.equity - 2150.10) < 0.000001 && tg_sn2.seconds_in_state == 3600,
              "login=" + (string)tg_login + " next=" + (string)tg_next + " build=" + tg_build);
   AgVecCheckInt("tg_q_roundtrip_every_code_count", tg_count, 21);
   bool tg_same = (tg_count == 21);
   for(int k = 0; k < tg_count && tg_same; k++)
      tg_same = tg_back[k].seq == tg_ev[k].seq && tg_back[k].code == tg_ev[k].code
                && tg_back[k].server_t == tg_ev[k].server_t && tg_back[k].local_t == tg_ev[k].local_t
                && tg_back[k].state == tg_ev[k].state && tg_back[k].pnl_mode == tg_ev[k].pnl_mode
                && MathAbs(tg_back[k].pnl - tg_ev[k].pnl) < 0.000001
                && MathAbs(tg_back[k].x[0] - 781624897.0) < 0.5 && MathAbs(tg_back[k].x[1] - 5.5) < 0.000001
                && MathAbs(tg_back[k].x[7] - tg_ev[k].x[7]) < 0.000001;
   AgVecCheck("tg_q_roundtrip_every_code_every_field", tg_same, "a field changed in the round trip");
   bool tg_ascii = true;
   for(int k = 0; k < StringLen(tg_q); k++)
      if(StringGetCharacter(tg_q, k) > 127)
         tg_ascii = false;
   AgVecCheck("tg_q_every_byte_is_ascii", tg_ascii, "a byte above 127");
   string tg_bad = tg_q;
   StringReplace(tg_bad, "|781624897|", "|781624898|");
   AgVecCheck("tg_q_changed_byte_fails_the_checksum",
              !AgTgQueueParse(tg_bad, tg_login, tg_next, tg_latch, tg_mask, tg_sn2, tg_build, tg_back, tg_count, tg_why)
              && tg_why == "checksum mismatch", tg_why);
   string tg_cut = StringSubstr(tg_q, 0, StringFind(tg_q, "C|"));
   AgVecCheck("tg_q_cut_file_is_refused",
              !AgTgQueueParse(tg_cut, tg_login, tg_next, tg_latch, tg_mask, tg_sn2, tg_build, tg_back, tg_count, tg_why),
              tg_why);
   AgVecCheck("tg_q_halt_file_is_not_a_queue",
              !AgTgQueueParse(AgVecSealed("AGHALT|1|990000021\nH|1|crash loop|1786027355\n"),
                              tg_login, tg_next, tg_latch, tg_mask, tg_sn2, tg_build, tg_back, tg_count, tg_why)
              && AG_TGQ_MAGIC != "AGHALT" && AG_TGQ_MAGIC != "AGSTATE" && AG_TGQ_MAGIC != "AGFLOOR"
              && AG_TGQ_MAGIC != "AGPEAK", tg_why);
   AgTgEvent tg_rev[];
   ArrayResize(tg_rev, 2);
   tg_rev[0] = tg_ev[1];
   tg_rev[1] = tg_ev[0];
   AgVecCheck("tg_q_events_out_of_order_are_refused",
              !AgTgQueueParse(AgTgQueueSerialize(990000021, 121, 0, 0, AgTgSnapshotLine(tg_sn, "TG"), tg_rev, 2),
                              tg_login, tg_next, tg_latch, tg_mask, tg_sn2, tg_build, tg_back, tg_count, tg_why)
              && tg_why == "V lines out of order", tg_why);
   AgTgEvent tg_many[];
   int tg_n = 60;
   ArrayResize(tg_many, tg_n);
   for(int k = 0; k < tg_n; k++)
     {
      tg_many[k] = tg_ev[0];
      tg_many[k].seq = k + 1;
     }
   int tg_dropped = AgTgQueueTrim(tg_many, tg_n, AG_TGQ_MAX_EVENTS);
   AgVecCheck("tg_q_overflow_keeps_the_oldest_and_the_newest_49",
              tg_dropped == 10 && tg_n == 50 && tg_many[0].seq == 1 && tg_many[1].seq == 12 && tg_many[49].seq == 60,
              "dropped=" + (string)tg_dropped + " n=" + (string)tg_n + " first=" + (string)tg_many[0].seq
              + " second=" + (string)tg_many[1].seq);
   int tg_forgot = AgTgQueueForget(tg_many, tg_n, 30);
   AgVecCheck("tg_q_forgotten_at_the_acknowledgement",
              tg_forgot == 19 && tg_n == 31 && tg_many[0].seq == 31 && tg_many[30].seq == 60,
              "forgot=" + (string)tg_forgot + " n=" + (string)tg_n);
   AgVecCheck("tg_q_numbering_goes_on_after_a_reload",
              AgTgNextSeqAfterLoad(121, 50) == 121 && AgTgNextSeqAfterLoad(10, 50) == 51
              && AgTgNextSeqAfterLoad(1, 0) == 1, "next seq after load");
   bool tg_codes_ok = true;
   for(int k = 0; k < 21; k++)
      if(AgTgCodeFromText(AgTgCodeText(tg_codes[k])) != tg_codes[k])
         tg_codes_ok = false;
   AgVecCheck("tg_q_code_text_round_trips_and_rejects_unknown",
              tg_codes_ok && AgTgCodeFromText("S5") == 0 && AgTgCodeFromText("S23") == 0
              && AgTgCodeFromText("X1") == 0 && AgTgCodeFromText("S-1") == 0, "code text");
   AgVecCheck("tg_q_names_carry_the_login",
              AgTgQueuePath(990000021) == "AccountGuardian\\tgqueue_990000021.dat"
              && AgGvTgAck(990000021) == "AG_TGACK_990000021"
              && AgGvTgRefused(990000021) == "AG_TGREFUSED_990000021"
              && AgGvTgRefSeen(990000021) == "AG_TGREFSEEN_990000021", AgTgQueuePath(990000021));
   AgVecCheck("tg_q_block_codes_in_the_q3_order",
              AgTgBlockCode(AgTradeBlockName(false, true, true, true)) == 1
              && AgTgBlockCode(AgTradeBlockName(true, false, true, true)) == 2
              && AgTgBlockCode(AgTradeBlockName(true, true, false, true)) == 3
              && AgTgBlockCode(AgTradeBlockName(true, true, true, false)) == 4
              && AgTgBlockCode(AgTradeBlockName(true, true, true, true)) == 0, "block codes");

   //--- S9, TG-3 (B): the share and the latch
   AgVecCheck("tg_s9_share_on_the_draft_figures_is_80",
              MathAbs(AgTgShareUsed(-126.21, 126.21, -100.97) - 80.0016) < 0.001,
              DoubleToString(AgTgShareUsed(-126.21, 126.21, -100.97), 4));
   AgVecCheck("tg_s9_share_from_the_peak",
              MathAbs(AgTgShareUsed(253.00 - 158.69, 158.69, 150.00) - 64.9064) < 0.001,
              DoubleToString(AgTgShareUsed(253.00 - 158.69, 158.69, 150.00), 4));
   int tg_m = 0;
   int tg_l1 = AgTgS9Step(55.0, tg_m);
   int tg_l2 = AgTgS9Step(60.0, tg_m);
   int tg_l3 = AgTgS9Step(85.0, tg_m);
   int tg_l4 = AgTgS9Step(75.0, tg_m);
   int tg_l5 = AgTgS9Step(70.0, tg_m);
   int tg_m5 = tg_m;
   int tg_l6 = AgTgS9Step(39.0, tg_m);
   int tg_l7 = AgTgS9Step(50.0, tg_m);
   AgVecCheck("tg_s9_levels_fire_once_and_rearm_ten_points_below",
              tg_l1 == 50 && tg_l2 == 0 && tg_l3 == 80 && tg_l4 == 0 && tg_l5 == 0 && tg_m5 == 1
              && tg_l6 == 0 && tg_l7 == 50,
              (string)tg_l1 + "," + (string)tg_l2 + "," + (string)tg_l3 + "," + (string)tg_l4 + ","
              + (string)tg_l5 + "," + (string)tg_l6 + "," + (string)tg_l7);
   int tg_jm = 0;
   AgVecCheck("tg_s9_a_jump_past_both_levels_fires_80_once",
              AgTgS9Step(95.0, tg_jm) == 80 && tg_jm == 3 && AgTgS9Step(96.0, tg_jm) == 0, "jump");

   //--- TG-S13, the command, on fixed getUpdates answers
   string tg_chat = (string)(990000000 + 123);
   long   tg_now  = (long)D'2026.10.21 10:00:00';
   string tg_head = "{\"ok\":true,\"result\":[{\"update_id\":7,\"message\":{\"message_id\":3,\"chat\":{\"id\":";
   string tg_raw  = tg_head + tg_chat + ",\"type\":\"private\"},\"date\":" + (string)(tg_now - 5)
                  + ",\"text\":\"" + AgTgCommandText() + "\"}}]}";
   long tg_max = 0; int tg_ign = 0; bool tg_aok = false;
   int  tg_hit = AgTgMatchCommands(tg_raw, AgTgCommandText(), tg_chat, tg_now, 120, tg_max, tg_ign, tg_aok);
   AgVecCheck("tg_cmd_exact_text_matches", tg_aok && tg_hit == 1 && tg_ign == 0 && tg_max == 7,
              "hit=" + (string)tg_hit + " ignored=" + (string)tg_ign + " max=" + (string)tg_max);
   char   tg_bytes[];
   int    tg_nb = AgTgUtf8Bytes(tg_raw, tg_bytes);
   string tg_dec = AgTgUtf8ToString(tg_bytes, tg_nb);
   tg_hit = AgTgMatchCommands(tg_dec, AgTgCommandText(), tg_chat, tg_now, 120, tg_max, tg_ign, tg_aok);
   AgVecCheck("tg_cmd_exact_text_matches_through_utf8", tg_dec == tg_raw && tg_hit == 1 && tg_nb > StringLen(tg_raw),
              "bytes=" + (string)tg_nb + " chars=" + (string)StringLen(tg_raw));
   string tg_esc = tg_head + tg_chat + "},\"date\":" + (string)(tg_now - 5)
                 + ",\"text\":\"\\u05d1\\u05d3\\u05d5\\u05e7 \\u05d0\\u05d5\\u05ea\\u05d9\"}}]}";
   tg_hit = AgTgMatchCommands(tg_esc, AgTgCommandText(), tg_chat, tg_now, 120, tg_max, tg_ign, tg_aok);
   AgVecCheck("tg_cmd_escaped_text_matches", tg_hit == 1, "hit=" + (string)tg_hit);
   string tg_sp = tg_head + tg_chat + "},\"date\":" + (string)(tg_now - 5)
                + ",\"text\":\"" + AgTgCommandText() + " \"}}]}";
   tg_hit = AgTgMatchCommands(tg_sp, AgTgCommandText(), tg_chat, tg_now, 120, tg_max, tg_ign, tg_aok);
   AgVecCheck("tg_cmd_trailing_space_does_not_match", tg_hit == 0 && tg_ign == 1, "hit=" + (string)tg_hit);
   string tg_rlm = tg_head + tg_chat + "},\"date\":" + (string)(tg_now - 5)
                 + ",\"text\":\"\\u200f" + AgTgCommandText() + "\"}}]}";
   tg_hit = AgTgMatchCommands(tg_rlm, AgTgCommandText(), tg_chat, tg_now, 120, tg_max, tg_ign, tg_aok);
   AgVecCheck("tg_cmd_leading_u200f_does_not_match", tg_hit == 0 && tg_ign == 1, "hit=" + (string)tg_hit);
   tg_hit = AgTgMatchCommands(tg_raw, AgTgCommandText(), (string)(990000000 + 124), tg_now, 120, tg_max, tg_ign, tg_aok);
   AgVecCheck("tg_cmd_another_chat_does_not_match", tg_hit == 0 && tg_ign == 1, "hit=" + (string)tg_hit);
   string tg_edit = tg_raw;
   StringReplace(tg_edit, "\"message\":", "\"edited_message\":");
   tg_hit = AgTgMatchCommands(tg_edit, AgTgCommandText(), tg_chat, tg_now, 120, tg_max, tg_ign, tg_aok);
   AgVecCheck("tg_cmd_edited_message_does_not_match", tg_hit == 0 && tg_ign == 1 && tg_max == 7, "hit=" + (string)tg_hit);
   string tg_old = tg_head + tg_chat + "},\"date\":" + (string)(tg_now - 121)
                 + ",\"text\":\"" + AgTgCommandText() + "\"}}]}";
   tg_hit = AgTgMatchCommands(tg_old, AgTgCommandText(), tg_chat, tg_now, 120, tg_max, tg_ign, tg_aok);
   AgVecCheck("tg_cmd_stale_date_does_not_match", tg_hit == 0 && tg_ign == 1, "hit=" + (string)tg_hit);
   string tg_two = "{\"ok\":true,\"result\":[{\"update_id\":8,\"message\":{\"chat\":{\"id\":" + tg_chat + "},\"date\":"
                 + (string)(tg_now - 9) + ",\"text\":\"" + AgTgCommandText() + "\"}},{\"update_id\":9,\"message\":{\"chat\":{\"id\":"
                 + tg_chat + "},\"date\":" + (string)(tg_now - 4) + ",\"text\":\"" + AgTgCommandText() + "\"}}]}";
   tg_hit = AgTgMatchCommands(tg_two, AgTgCommandText(), tg_chat, tg_now, 120, tg_max, tg_ign, tg_aok);
   AgVecCheck("tg_cmd_two_commands_in_one_poll_and_the_offset", tg_hit == 2 && tg_max == 9,
              "hit=" + (string)tg_hit + " max=" + (string)tg_max);
   tg_hit = AgTgMatchCommands("{\"ok\":false,\"error_code\":409}", AgTgCommandText(), tg_chat, tg_now, 120, tg_max, tg_ign, tg_aok);
   AgVecCheck("tg_cmd_not_ok_answer_is_flagged", !tg_aok && tg_hit == 0 && tg_max == -1, "ok flag");
   AgVecCheckInt("tg_json_retry_after_of_a_429",
                 AgTgRetryAfter("{\"ok\":false,\"error_code\":429,\"parameters\":{\"retry_after\":5}}"), 5);
   AgVecCheck("tg_json_escape",
              AgJsonEscape("a\"b\\c\nd\te") == "a\\\"b\\\\c\\nd\\te", AgJsonEscape("a\"b\\c\nd\te"));
   string tg_jp[]; string tg_jv[]; int tg_jk[]; int tg_jc = 0;
   bool tg_jok = AgJsonParse("{\"a\":[1,{\"b\":\"x\\/y\"}],\"c\":null,\"d\":-1.5e3}", tg_jp, tg_jv, tg_jk, tg_jc);
   AgVecCheck("tg_json_flat_paths",
              tg_jok && tg_jc == 4 && tg_jp[0] == "a[0]" && tg_jv[0] == "1" && tg_jp[1] == "a[1].b"
              && tg_jv[1] == "x/y" && tg_jk[2] == AG_JSON_NULL && tg_jv[3] == "-1.5e3",
              "count=" + (string)tg_jc);
   AgVecCheck("tg_json_rejects_trailing_garbage",
              !AgJsonParse("{\"a\":1} x", tg_jp, tg_jv, tg_jk, tg_jc), "parsed");

   //--- the three inputs, on values built here so no token, chat id or ping
   //--- URL shaped literal exists anywhere in the tree (TG-S6)
   string tg_tail = "";
   for(int k = 0; k < 35; k++)
      tg_tail += "x";
   string tg_token = (string)(990000000 + 1) + ":" + tg_tail;
   AgVecCheck("tg_input_token_shape",
              AgTgTokenValid(tg_token) && !AgTgTokenValid(StringSubstr(tg_token, 0, StringLen(tg_token) - 6))
              && !AgTgTokenValid(tg_tail) && !AgTgTokenValid(tg_token + " ") && !AgTgTokenValid("a" + tg_token)
              && !AgTgTokenValid(""), "token checks");
   AgVecCheck("tg_input_chat_id_shape",
              AgTgChatIdValid(tg_chat) && AgTgChatIdValid("-" + tg_chat) && !AgTgChatIdValid("")
              && !AgTgChatIdValid("-") && !AgTgChatIdValid(tg_chat + "a")
              && !AgTgChatIdValid(tg_chat + tg_chat + "123"), "chat id checks");
   string tg_zero8 = "00000000", tg_zero4 = "0000";
   string tg_uuid  = tg_zero8 + "-" + tg_zero4 + "-" + tg_zero4 + "-" + tg_zero4 + "-" + tg_zero4 + tg_zero8;
   string tg_host  = "https://" + "hc-ping.com/";
   AgVecCheck("tg_input_ping_url_shape",
              AgTgPingUrlValid(tg_host + tg_uuid) && !AgTgPingUrlValid("http://" + "hc-ping.com/" + tg_uuid)
              && !AgTgPingUrlValid(tg_host + tg_uuid + "/") && !AgTgPingUrlValid(tg_host + tg_zero8 + tg_zero8)
              && !AgTgPingUrlValid(""), "ping URL checks");
   AgVecCheck("tg_input_channel_states",
              AgTgChannelState(true, false) == "off:empty" && AgTgChannelState(false, false) == "off:malformed"
              && AgTgChannelState(false, true) == "on", "channel states");

   //--- TG-S14, the status slot, TG-15 (A): the local clock's 4 hour slots
   AgVecCheckInt("tg_slot_midnight", AgTgStatusSlot((long)D'2026.10.21 00:00:00'), (long)D'2026.10.21 00:00:00');
   AgVecCheckInt("tg_slot_03_59_59", AgTgStatusSlot((long)D'2026.10.21 03:59:59'), (long)D'2026.10.21 00:00:00');
   AgVecCheckInt("tg_slot_04_00_00", AgTgStatusSlot((long)D'2026.10.21 04:00:00'), (long)D'2026.10.21 04:00:00');
   AgVecCheckInt("tg_slot_12_00_01", AgTgStatusSlot((long)D'2026.10.21 12:00:01'), (long)D'2026.10.21 12:00:00');
   AgVecCheckInt("tg_slot_23_59_59", AgTgStatusSlot((long)D'2026.10.21 23:59:59'), (long)D'2026.10.21 20:00:00');
   int tg_slots = 0;
   long tg_prev_slot = AgTgStatusSlot((long)D'2026.10.20 23:59:59');
   for(long tg_s = (long)D'2026.10.21 00:00:00'; tg_s < (long)D'2026.10.22 00:00:00'; tg_s += 60)
     {
      long tg_cur_slot = AgTgStatusSlot(tg_s);
      if(tg_cur_slot != tg_prev_slot)
         tg_slots++;
      tg_prev_slot = tg_cur_slot;
     }
   AgVecCheckInt("tg_slot_six_per_local_day", tg_slots, 6);

   //--- the new journal lines, field names exact, none taking a secret
   AgVecCheck("tg_line_trading_blocked",
              AgTgTradeBlockedLine("TERMINAL_TRADE_ALLOWED=false", "ACTIVE")
              == "trading blocked|state=TERMINAL_TRADE_ALLOWED=false|guardian=ACTIVE", "");
   AgVecCheck("tg_line_trading_restored",
              AgTgTradeRestoredLine("MQL_TRADE_ALLOWED=false", "SYNCING")
              == "trading restored|state=MQL_TRADE_ALLOWED=false|guardian=SYNCING", "");
   AgVecCheck("tg_line_queue_deferred", AgTgQueueDeferredLine(3) == "alerts queue write deferred|attempts=3", "");
   AgVecCheck("tg_line_queue_loaded", AgTgQueueLoadedLine(2, 15) == "alerts queue loaded|events=2|next_seq=15", "");
   AgVecCheck("tg_line_service_started",
              AgTgServiceStartedLine("TG", 1200252169, "on", "off:empty", "on")
              == "alerts service started|build=TG|login=1200252169|telegram=on|network_heartbeat=off:empty|command=on", "");
   AgVecCheck("tg_line_sent", AgTgSentLine(42, "S4", 200, 311) == "alerts sent|seq=42|class=S4|http=200|ms=311", "");
   AgVecCheck("tg_line_failed",
              AgTgFailedLine(43, "S12", -1, 4014, 2) == "alerts failed|seq=43|class=S12|http=-1|err=4014|ms=2", "");
   AgVecCheck("tg_line_ping", AgTgPingLine(200, 180) == "alerts ping|http=200|ms=180", "");
   AgVecCheck("tg_line_ping_skipped",
              AgTgPingSkippedLine("released", 0) == "alerts ping skipped|guardian=released|age=0", "");
   AgVecCheck("tg_line_guardian", AgTgGuardianLine("stale", 12) == "alerts guardian|state=stale|age=12", "");
   AgVecCheck("tg_line_inbound", AgTgInboundLine(1, 2) == "alerts inbound|matched=1|ignored=2", "");
   AgVecCheck("tg_line_stopping", AgTgStoppingLine(0) == "alerts service stopping|unsent=0", "");

   //--- TG-S8, the Hebrew: each draft of item 13 rendered with its example
   //--- values, the md5 of the UTF-8 bytes against the value computed from the
   //--- draft's own text, independently, by a script at the build
   AgTgCommon c;
'''

block = HAND + "\n".join(code) + "\n"
v = open(VEC, "rb").read().decode("utf-8").replace("\r\n", "\n")
anchor = '   PrintFormat("AGVEC|SUMMARY|%d/%d", g_pass, g_total);\n  }\n'
assert v.count(anchor) == 1
v = v.replace(anchor, block + "\n" + anchor)
# the includes and the helpers, after the existing includes
inc_old = "#include <AccountGuardian/Persist.mqh>\n#include <AccountGuardian/SweepPolicy.mqh>\n"
assert v.count(inc_old) == 1
inc_new = inc_old + ("#include <AccountGuardian/AlertQueue.mqh>\n#include <AccountGuardian/AlertJson.mqh>\n"
                     "#include <AccountGuardian/AlertText.mqh>\n")
v = v.replace(inc_old, inc_new)
helpers_anchor = "//--- A well-formed body plus a correct checksum line.\n"
assert v.count(helpers_anchor) == 1
helpers = r'''//--- TG: the md5 of a string's UTF-8 bytes, the trailing zero dropped
string AgVecMd5Hex(const string s)
  {
   uchar data[];
   uchar key[];
   uchar hash[];
   int n = StringToCharArray(s, data, 0, WHOLE_ARRAY, CP_UTF8);
   if(n > 0)
      ArrayResize(data, n - 1);
   if(CryptEncode(CRYPT_HASH_MD5, data, key, hash) <= 0)
      return "";
   string hex = "";
   for(int i = 0; i < ArraySize(hash); i++)
      hex += StringFormat("%02X", hash[i]);
   return hex;
  }

void AgVecMd5(const string name, const string got, const string want_md5)
  {
   string m = AgVecMd5Hex(got);
   AgVecCheck(name, m == want_md5, "md5=" + m + " text=" + got);
  }

//--- one line of a rendered message, 0 based
string AgVecLine(const string text, const int index)
  {
   string parts[];
   int n = StringSplit(text, '\n', parts);
   return (index < n) ? parts[index] : "";
  }

//--- the common lines of a draft: the demo account of the drafts
void AgVecC(AgTgCommon &c, const datetime server_t, const double balance, const double equity,
            const double pnl, const int mode, const double limit, const int state)
  {
   c.login    = 1200252169;
   c.server_t = server_t;
   c.balance  = balance;
   c.equity   = equity;
   c.pnl      = pnl;
   c.limit    = limit;
   c.pnl_mode = mode;
   c.state    = state;
  }

'''
v = v.replace(helpers_anchor, helpers + helpers_anchor)
open(VEC, "wb").write(v.replace("\n", "\r\n").encode("utf-8"))
sys.stdout.buffer.write(("md5 vectors " + str(len(cases)) + ", drafts not rendered by any vector: "
                         + str(unused) + "\n").encode("utf-8"))
