# Static rows TG-S1 and TG-S9: compiles one MQL5 source of this repository
# with the program folder MetaEditor, /include at the repository's MQL5
# folder and /log in a folder outside the repository. The exit code is printed
# and not used (standing rule 6); the log's Result line, the including lines
# and a fresh ex5 are the signals. The md5 is recorded with the label and is
# not identity (standing rule 7).
#
# Usage: python -I scripts/rows/compile.py <source path relative to the repository> <tag> <log folder>
import hashlib, os, subprocess, sys, time

ME = r"C:\Program Files\MetaTrader 5\metaeditor64.exe"
WT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

src = sys.argv[1].replace("/", "\\")
tag = sys.argv[2]
logdir = os.path.abspath(sys.argv[3])
if logdir.lower().startswith(WT.lower()):
    sys.exit("the log folder must lie outside the repository")
full = os.path.join(WT, src)
ex5 = full[:-4] + ".ex5"
log = os.path.join(logdir, "compile-" + tag + ".log")
if os.path.exists(log):
    os.remove(log)
before = os.path.getmtime(ex5) if os.path.exists(ex5) else None
t0 = time.time()
p = subprocess.run([ME, "/compile:" + full, "/include:" + os.path.join(WT, "MQL5"), "/log:" + log])
raw = open(log, "rb").read()
text = raw.decode("utf-16") if raw[:2] in (b"\xff\xfe", b"\xfe\xff") else raw.decode("utf-8", "replace")
lines = [l.strip() for l in text.splitlines() if l.strip()]
out = []
out.append("source " + src)
out.append("exit code " + str(p.returncode) + " (not a compile signal, standing rule 6)")
inc = [l for l in lines if "including" in l]
outside = [l for l in inc if WT.lower() not in l.lower()]
out.append("including lines " + str(len(inc)) + ", outside the repository " + str(len(outside)))
for l in outside:
    out.append("  OUTSIDE: " + l)
for l in lines:
    low = l.lower()
    if (": error" in low or ": warning" in low or "result:" in low) and "including" not in low:
        out.append("  " + l)
if os.path.exists(ex5):
    m = os.path.getmtime(ex5)
    data = open(ex5, "rb").read()
    out.append("ex5 " + os.path.basename(ex5) + " mtime " + time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(m))
               + (" FRESH" if (before is None or m > before) and m >= t0 - 2 else " NOT FRESH")
               + " bytes " + str(len(data)) + " md5 " + hashlib.md5(data).hexdigest().upper())
else:
    out.append("ex5 absent")
sys.stdout.buffer.write(("\n".join(out) + "\n").encode("utf-8"))
