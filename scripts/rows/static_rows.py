# The static acceptance rows of the Telegram alerts build that run on this
# computer, measured on the committed tree at HEAD and, where a row compares,
# against 00c7237, the commit the build was cut from. TG-S7 has its own
# script, tg_s7.py; TG-S1 and TG-S9 are the compiles of compile.py.
#
# Usage: python -I scripts/rows/static_rows.py [repository root]
import hashlib, os, re, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
WT = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(HERE))
BASE = "00c7237"


def git(*args):
    return subprocess.run(["git", "-C", WT] + list(args), capture_output=True).stdout


def show(rev, path):
    return git("show", rev + ":" + path).decode("utf-8", "replace").replace("\r\n", "\n")


def now(path):
    return open(os.path.join(WT, path), "rb").read().decode("utf-8", "replace").replace("\r\n", "\n")


def code_only(line):
    return re.sub(r'"(?:[^"\\]|\\.)*"', '""', line).split("//")[0]


FDEF = re.compile(r"^(?:void|int|bool|string|double|long|ulong|uint|datetime)\s+(\w+)\s*\(")


def function_of_lines(src):
    """For each line number, the top level function it lies in, or '-'. A
    signature may run over several lines; the name holds until its body closes."""
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
            pending = False      # a declaration with no body
        if not pending and depth == 0:
            cur = "-"
    return out


def bodies(src):
    """Function name to body text, top level functions only."""
    res, lines = {}, src.split("\n")
    where = function_of_lines(src)
    for n, l in enumerate(lines, 1):
        name = where[n]
        if name != "-":
            res[name] = res.get(name, "") + code_only(l) + "\n"
    return res


out = []
head = git("rev-parse", "HEAD").decode().strip()
out.append("HEAD " + head + ", compared with " + BASE)

EA = "MQL5/Experts/AccountGuardian/AccountGuardian.mq5"
INC = "MQL5/Include/AccountGuardian/"
SVC = "MQL5/Services/AccountGuardian/AccountGuardianAlerts.mq5"
files = [l for l in git("ls-files", "MQL5").decode().split("\n") if l.strip()]


def includes_of(path, seen=None):
    seen = seen if seen is not None else []
    for m in re.finditer(r"#include\s*<AccountGuardian/(\w+\.mqh)>", now(path)):
        p = INC + m.group(1)
        if p not in seen:
            seen.append(p)
            includes_of(p, seen)
    return seen


# ---- TG-S15 (plan TG-S4): the five protected functions and AgTransition, byte identical
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


prot = [(EA, "void AgEvaluateActive()"), (EA, "int AgBootDerivation("), (EA, "void AgEvaluateLocked()"),
        (EA, "void AgDeclareLock("), (EA, "void AgEnterLockFromBoot("), (INC + "State.mqh", "void AgTransition(")]
for path, sig in prot:
    a = func(show(BASE, path), sig)
    b = func(now(path), sig)
    ma = hashlib.md5(a.encode()).hexdigest().upper()
    mb = hashlib.md5(b.encode()).hexdigest().upper()
    out.append("TG-S15 %-20s %s %s now %s %s" % (sig.split("(")[0].split()[-1], BASE, ma, mb,
                                                 "IDENTICAL" if ma == mb else "CHANGED"))

# ---- TG-S2 (ENF-S2): the trade API family, the same lines as at the base, all in Sweep.mqh
TRADE = re.compile(r"OrderSend|OrderSendAsync|CTrade|PositionClose|OrderDelete|Trade\.mqh|TRADE_ACTION_")


def hits(getter, rev_files):
    res = []
    for f in rev_files:
        for l in getter(f).split("\n"):
            if TRADE.search(l):
                res.append((f, l.strip()))
    return res


old_files = [l for l in git("ls-tree", "-r", "--name-only", BASE, "MQL5").decode().split("\n") if l.strip()]
h_old = hits(lambda f: show(BASE, f), old_files)
h_new = hits(now, files)
per = {}
for f, l in h_new:
    per[f] = per.get(f, 0) + 1
out.append("TG-S2 hits at %s %d, now %d, per file now %s, the same line texts: %s"
           % (BASE, len(h_old), len(h_new), per, sorted(h_old) == sorted(h_new)))

# ---- TG-S3 (ENF-S3): AgSweepPass call sites
calls = []
for f in files:
    for n, l in enumerate(now(f).split("\n"), 1):
        if re.search(r"\bAgSweepPass\s*\(", code_only(l)) and "void AgSweepPass" not in l:
            calls.append("%s:%d %s" % (f.split("/")[-1], n, l.strip()))
out.append("TG-S3 AgSweepPass call sites %d: %s" % (len(calls), calls))

# ---- TG-S10: no network path in the EA or any include it compiles; WebRequest
# ---- only in the service, every call with the timeout constant
NET = re.compile(r"\b(WebRequest|SendNotification|SendMail|SocketCreate|SocketConnect)\b")
ea_set = [EA] + includes_of(EA)
ea_hits = ["%s:%d" % (f, n) for f in ea_set for n, l in enumerate(now(f).split("\n"), 1) if NET.search(l)]
out.append("TG-S10 the EA compiles %d files: %s" % (len(ea_set), [f.split("/")[-1] for f in ea_set]))
out.append("TG-S10 network names, comments included, in the EA and the includes it compiles: %d %s" % (len(ea_hits), ea_hits))
web = ["%s:%d %s" % (f, n, l.strip()) for f in files for n, l in enumerate(now(f).split("\n"), 1)
       if re.search(r"\bWebRequest\b", l)]
out.append("TG-S10 every line naming WebRequest in MQL5/, comments included: %d %s" % (len(web), web))


def call_args(src, name):
    res = []
    for m in re.finditer(r"\b" + name + r"\s*\(", src):
        i, depth, args, cur = m.end(), 1, [], ""
        while depth:
            ch = src[i]
            if ch in "([":
                depth += 1
            elif ch in ")]":
                depth -= 1
            if depth == 1 and ch == ",":
                args.append(cur.strip())
                cur = ""
            elif depth:
                cur += ch
            i += 1
        args.append(cur.strip())
        line = src.count("\n", 0, m.start()) + 1
        res.append((line, args))
    return res


svc_src = now(SVC)
svc_code = "\n".join(code_only(l) for l in svc_src.split("\n"))
for name, k in (("WebRequest", 3), ("AgSvcRequest", 4), ("AgSvcSendText", 3)):
    for line, args in call_args(svc_code, name):
        if FDEF.match(svc_src.split("\n")[line - 1]):
            continue
        out.append("TG-S10 %s at %s:%d passes the timeout %s" % (name, SVC.split("/")[-1], line, args[k]))
for c in ("AG_SVC_TIMEOUT_MS", "AG_SVC_FINAL_TIMEOUT_MS"):
    m = re.search(r"#define\s+" + c + r"\s+(\d+)", svc_src)
    out.append("TG-S10 %s = %s" % (c, m.group(1) if m else "NOT FOUND"))

# ---- TG-S11, as ruled 2026-10-21: zero file, GV or trade writes in the service's own
# ---- source and its three own includes; GlobalVariableSet only on AG_TGACK_<login> and
# ---- AG_TGREFSEEN_<login>; zero calls from those files into any writer of the shared
# ---- includes the service compiles
own = [SVC, INC + "AlertQueue.mqh", INC + "AlertJson.mqh", INC + "AlertText.mqh"]
svc_includes = includes_of(SVC)
shared = [p for p in svc_includes if p not in own]
out.append("TG-S11 the service compiles its source and %d includes: own %s, shared %s"
           % (len(svc_includes), [p.split("/")[-1] for p in own[1:]], [p.split("/")[-1] for p in shared]))
WRITE = re.compile(r"FILE_WRITE|\bFileMove\b|\bFileCopy\b|\bFileDelete\b|\bFolderDelete\b|\bFolderCreate\b|"
                   r"\bFileWrite\w*|\bFileFlush\b|\bGlobalVariableSet\w*|\bGlobalVariableDel\b|\bGlobalVariableTemp\b|"
                   r"\bGlobalVariablesDeleteAll\b|\bGlobalVariablesFlush\b|\bAgAtomicWrite\b|" + TRADE.pattern)
violations, gvset, flushes = [], [], []
for f in own:
    for n, l in enumerate(now(f).split("\n"), 1):
        c = code_only(l)
        for m in WRITE.finditer(c):
            w = m.group(0)
            if w == "GlobalVariableSet":
                gvset.append("%s:%d %s" % (f.split("/")[-1], n, l.strip()))
                arg = re.search(r"GlobalVariableSet\s*\(\s*(\w+)\s*\(", c)
                if not arg or arg.group(1) not in ("AgGvTgAck", "AgGvTgRefSeen"):
                    violations.append("%s:%d %s" % (f.split("/")[-1], n, l.strip()))
            elif w == "GlobalVariablesFlush":
                flushes.append("%s:%d" % (f.split("/")[-1], n))
            else:
                violations.append("%s:%d %s" % (f.split("/")[-1], n, l.strip()))
out.append("TG-S11 file, GV or trade writes in the service's own four files, GlobalVariableSet on the two "
           "names aside: %d %s" % (len(violations), violations))
out.append("TG-S11 GlobalVariableSet sites: %s" % gvset)
out.append("TG-S11 GlobalVariablesFlush sites, persisting those two: %s" % flushes)
# the writers of the shared includes, derived: a function whose body holds a write,
# then every function that calls one, to a fixed point
shared_bodies = {}
for p in shared:
    shared_bodies.update(bodies(now(p)))
writers = {n for n, b in shared_bodies.items() if WRITE.search(b)}
while True:
    more = {n for n, b in shared_bodies.items() if n not in writers
            and any(re.search(r"\b" + w + r"\s*\(", b) for w in writers)}
    if not more:
        break
    writers |= more
out.append("TG-S11 writers of the shared includes, derived: %d %s" % (len(writers), sorted(writers)))
called = []
for f in own:
    c = "\n".join(code_only(l) for l in now(f).split("\n"))
    for w in sorted(writers):
        for m in re.finditer(r"\b" + w + r"\s*\(", c):
            called.append("%s:%d %s" % (f.split("/")[-1], c.count("\n", 0, m.start()) + 1, w))
out.append("TG-S11 calls from the service's own four files into those writers: %d %s" % (len(called), called))

# ---- TG-S16, with the owner ruling of 2026-10-21: the S12 globals are referenced only
# ---- in the banner builder, the LIFE line builder, the read with its two journal lines
# ---- and its two Alerts, the producer, and AgTgInitReset
ea_src = now(EA)
where = function_of_lines(ea_src)
refs = {}
note_callers = set()
for n, l in enumerate(ea_src.split("\n"), 1):
    c = code_only(l)
    if re.search(r"\bg_ag_tp_\w+", c):
        refs[where[n]] = refs.get(where[n], 0) + 1
    if re.search(r"\bAgTgPermissionNote\s*\(", c) and not FDEF.match(l):
        note_callers.add(where[n])
out.append("TG-S16 references to the g_ag_tp_ globals by function ('-' the declarations): %s" % refs)
out.append("TG-S16 the LIFE line note AgTgPermissionNote is called from: %s" % sorted(note_callers))
allowed = {"-", "AgRefreshBanner", "AgTgPermissionRead", "AgTgPermissionNote", "AgTgSnapshotNow", "AgTgProduce",
           "AgTgInitReset"} | note_callers
outside = sorted(k for k in refs if k not in allowed)
protected = {"AgEvaluateActive", "AgBootDerivation", "AgEvaluateLocked", "AgDeclareLock", "AgEnterLockFromBoot",
             "AgSweepPass", "AgTransition"}
out.append("TG-S16 outside the allowed sites: %s; in a protected function: %s; in Sweep.mqh: %s; in State.mqh: %s"
           % (outside, sorted(k for k in refs if k in protected),
              [n for n, l in enumerate(now(INC + "Sweep.mqh").split("\n"), 1) if "g_ag_tp_" in l],
              [n for n, l in enumerate(now(INC + "State.mqh").split("\n"), 1) if "g_ag_tp_" in l]))

# ---- TG-S6: no secret shaped literal anywhere in the tree; the inputs only where they are used
tree = [l for l in git("ls-files").decode().split("\n") if l.strip()]
TOK = re.compile(r"\b\d{6,}:[A-Za-z0-9_-]{30,}")
UUID = re.compile(r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}")
INPUTS = re.compile(r"(TelegramToken|TelegramChatId|NetworkHeartbeatUrl)\s*=\s*\"[^\"]+\"")
th, uh, ih = [], [], []
for f in tree:
    try:
        t = open(os.path.join(WT, f), "rb").read().decode("utf-8", "replace")
    except Exception:
        continue
    for n, l in enumerate(t.split("\n"), 1):
        if TOK.search(l):
            th.append("%s:%d" % (f, n))
        if UUID.search(l):
            uh.append("%s:%d" % (f, n))
        if INPUTS.search(l):
            ih.append("%s:%d" % (f, n))
out.append("TG-S6 token shaped literals in the tree: %d %s" % (len(th), th[:5]))
out.append("TG-S6 UUID shaped literals in the tree: %d %s" % (len(uh), uh[:5]))
out.append("TG-S6 a non empty default on the three inputs: %d %s" % (len(ih), ih))
secret_use = []
for f in own:
    for n, l in enumerate(now(f).split("\n"), 1):
        if re.search(r"\b(TelegramToken|TelegramChatId|NetworkHeartbeatUrl)\b", code_only(l)):
            secret_use.append("%s:%d %s" % (f.split("/")[-1], n, l.strip()[:150]))
out.append("TG-S6 every use of the three inputs:")
for s in secret_use:
    out.append("   " + s)
journal_with_secret = [s for s in secret_use if re.search(r"Ag(Info|Warn|Log|AlertEvent)\(|Print|Alert\(|Comment\(", s)]
out.append("TG-S6 a journal, Alert or chart call carrying an input: %d" % len(journal_with_secret))

# ---- IN-S5: the manifest against the LF blobs at HEAD
man = now("installer/manifest.txt").strip().split("\n")
ok = 0
for l in man:
    h, p = l.split("  ", 1)
    if hashlib.md5(git("cat-file", "blob", "HEAD:" + p)).hexdigest().upper() == h:
        ok += 1
out.append("IN-S5 manifest lines %d, matching the HEAD blobs %d" % (len(man), ok))

# ---- IN-S3: the installer's write set
ins = now("installer/install.ps1").split("\n")
W = re.compile(r"\b(Copy-Item|New-Item|Set-Content|Add-Content|Out-File|Remove-Item|Move-Item|Rename-Item|WriteAll\w*|Start-Process)\b")
for n, l in enumerate(ins, 1):
    if W.search(l) and not l.strip().startswith("#"):
        out.append("IN-S3 install.ps1:%d %s" % (n, l.strip()[:160]))

# ---- IN-S6, as redefined 2026-09-30: zero em dashes, CR equals LF, secrecy grep zero,
# ---- no development file named except paths under docs/media/
raw = open(os.path.join(WT, "README.md"), "rb").read()
readme = raw.decode("utf-8")
patterns = [p.strip() for p in now("scripts/secrecy-patterns.txt").split("\n") if p.strip()]
sec = {p: len(re.findall(p, readme, re.IGNORECASE)) for p in patterns}
dev = re.compile(r"(?:docs/(?!media/)[\w./-]*|scripts/[\w./-]*|installer/[\w./-]*\.(?:ps1|txt)|LEDGER|CLAUDE|"
                 r"SPEC_v0|PLAN_\w+|agtest|deploy-\w+|\.claude|AgPhase\w+)")
dev_hits = sorted(set(dev.findall(readme)))
out.append("IN-S6 README.md CR %d LF %d, em dashes %d, secrecy hits %d %s, development names %s, docs/media paths %d"
           % (raw.count(b"\r"), raw.count(b"\n"), readme.count(chr(0x2014)), sum(sec.values()),
              {k: v for k, v in sec.items() if v}, dev_hits, len(set(re.findall(r"docs/media/[\w.-]+", readme)))))

# ---- the naming rule on the two governed files
for f in ("LEDGER.md", "docs/SPEC_v0.1.md"):
    t = now(f)
    bare = 0
    for m in re.finditer(r"heartbeat", t, re.IGNORECASE):
        pre = t[max(0, m.start() - 8):m.start()]
        if pre.endswith('"') or pre.lower().endswith("mutex ") or pre.lower().endswith("network ") \
                or pre.endswith("Network") or pre.endswith("network_"):
            continue
        bare += 1
    out.append("naming rule %s: bare uses %d" % (f, bare))

# ---- the PowerShell files parse
for f in ("installer/install.ps1", "scripts/deploy-tg.ps1", "scripts/export-release.ps1", "scripts/make-manifest.ps1"):
    cmd = ("$t=$null; $e=$null; [void][System.Management.Automation.Language.Parser]::ParseFile('"
           + os.path.join(WT, f) + "', [ref]$t, [ref]$e); $e.Count")
    r = subprocess.run(["pwsh", "-NoProfile", "-NonInteractive", "-Command", cmd], capture_output=True)
    out.append("parse %s: errors %s" % (f, r.stdout.decode().strip() or r.stderr.decode().strip()))

sys.stdout.buffer.write(("\n".join(out) + "\n").encode("utf-8"))
