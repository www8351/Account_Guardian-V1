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
          "TG-S6 token shaped literals in the tree: 0", "TG-S6 UUID shaped literals in the tree: 1 ['docs/evidence/metaeditor-20260902.txt:372']",
          "TG-S6 a non empty default on the three inputs: 0",
          "TG-S6 a journal, Alert or chart call carrying an input: 0"):
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
