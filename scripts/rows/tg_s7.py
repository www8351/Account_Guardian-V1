# Static row TG-S7 of the Telegram alerts build, design addendum item 10:
# "the include starts EF BB BF, decodes as strict UTF-8, holds no U+2013,
# U+2014 or U+05BE, and each template's Hebrew character count equals the
# drafts block of item 13".
#
# A template is one rendered message, or one rendered line of a wording list,
# as the vectors script renders it (plan 6.5.4). The count is taken from the
# source, not from a copy of the drafts: the functions of AlertText.mqh, and
# AgTgMoney and AgTgNum of AlertQueue.mqh, are evaluated from their own text
# by mqleval.py, on every tg_text_ render case of AgPhase2StateVectors.mq5
# exactly as that file states it. Each case is tied to its draft by the md5
# the vectors file carries. The vectors run on the terminal (TG-S8) stays the
# check of the compiled program; this row reads the source.
#
# Usage: python -I scripts/rows/tg_s7.py [repository root]
# Exit code 0 when every check holds, 1 otherwise.
import hashlib, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import mqleval as mq

ROOT = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(HERE))
INC = os.path.join(ROOT, "MQL5", "Include", "AccountGuardian")
TXT = os.path.join(INC, "AlertText.mqh")
QUE = os.path.join(INC, "AlertQueue.mqh")
STA = os.path.join(INC, "State.mqh")
VEC = os.path.join(ROOT, "MQL5", "Scripts", "AccountGuardian", "AgPhase2StateVectors.mq5")
ADD = os.path.join(ROOT, "docs", "PLAN_TELEGRAM_ALERTS_ADDENDUM_TG1B.md")

HEB_LO, HEB_HI = chr(0x0590), chr(0x05FF)
EN_DASH, EM_DASH, MAQAF = chr(0x2013), chr(0x2014), chr(0x05BE)


def heb(s):
    return sum(1 for ch in s if HEB_LO <= ch <= HEB_HI)


def main():
    out = []
    ok_all = True

    def check(label, cond, detail=""):
        nonlocal ok_all
        if not cond:
            ok_all = False
        out.append("%-4s %s%s" % ("OK" if cond else "FAIL", label, (": " + detail) if detail else ""))

    # ---- the encoding rows
    raw = open(TXT, "rb").read()
    check("AlertText.mqh starts EF BB BF", raw[:3] == b"\xef\xbb\xbf")
    try:
        src = raw[3:].decode("utf-8", errors="strict")
        check("AlertText.mqh decodes as strict UTF-8", True)
    except UnicodeDecodeError as exc:
        check("AlertText.mqh decodes as strict UTF-8", False, str(exc))
        src = raw[3:].decode("utf-8", errors="replace")
    for ch, name in ((EN_DASH, "U+2013"), (EM_DASH, "U+2014"), (MAQAF, "U+05BE")):
        check("AlertText.mqh holds no " + name, src.count(ch) == 0, "count %d" % src.count(ch))
    outside = re.sub(r'"((?:[^"\\]|\\.)*)"', '""', src)
    outside = re.sub(r"//[^\n]*", "", outside)
    check("no Hebrew outside string literals", heb(outside) == 0, "count %d" % heb(outside))
    src = src.replace("\r\n", "\n")

    # ---- the drafts of item 13 and the command of item 5
    a = mq.read_text(ADD).split("\n")
    s = a.index("```text", a.index("## 13. Hebrew drafts"))
    e = a.index("```", s + 1)
    drafts, order, cur = {}, [], None
    for line in a[s + 1:e]:
        if line.startswith("=== ") and line.endswith(" ==="):
            cur = line[4:-4]
            drafts[cur] = []
            order.append(cur)
        elif line == "":
            cur = None
        elif cur is not None:
            drafts[cur].append(line)
    c0 = a.index("```text", a.index("## 5. The command"))
    command = "\n".join(a[c0 + 1:a.index("```", c0 + 1)])

    by_md5, all_md5 = {}, {}
    for label in order:
        whole = "\n".join(drafts[label])
        h = hashlib.md5(whole.encode("utf-8")).hexdigest().upper()
        by_md5.setdefault(h, (label, None))
        all_md5.setdefault(h, []).append((label, None))
        for n, line in enumerate(drafts[label]):
            h = hashlib.md5(line.encode("utf-8")).hexdigest().upper()
            by_md5.setdefault(h, (label, n))
            all_md5.setdefault(h, []).append((label, n))

    # ---- the evaluator over the source
    consts, structs = {}, {}
    for path in (STA, QUE, TXT):
        mq.read_consts(mq.read_text(path), consts)
    mq.read_structs(src, structs)
    functions = mq.read_functions(src, structs)
    functions.update(mq.read_functions(mq.read_text(QUE), structs, {"AgTgMoney", "AgTgNum"}))
    functions.update(mq.read_functions(mq.read_text(VEC), structs, {"AgVecLine", "AgVecC"}))
    cases = []
    ev = mq.Evaluator(functions, consts, structs,
                      {"AgVecMd5": lambda name, got, want: cases.append((name, got, want))})
    text_functions = sorted(n for n in functions if n not in ("AgTgMoney", "AgTgNum", "AgVecLine", "AgVecC"))

    env = {}
    for line in mq.read_text(VEC).split("\n"):
        t = line.strip()
        if t == "AgTgCommon c;" or t.startswith("AgVecC(") or t.startswith('AgVecMd5("tg_text_'):
            ev.run(mq.Parser(mq.tokenize(t), structs).statement(), env)

    # ---- per template counts
    out.append("")
    out.append("per template: case | draft | Hebrew in the code's rendering | Hebrew in the draft | text")
    covered = {}
    equal_counts = 0
    identical = 0
    for name, got, want in cases:
        if want not in by_md5:
            check(name + " ties to a draft of item 13", False, "md5 " + want + " matches no draft")
            continue
        label, line = by_md5[want]
        draft = drafts[label][line] if line is not None else "\n".join(drafts[label])
        for lab, ln in all_md5[want]:
            covered.setdefault(lab, set()).add("all" if ln is None else ln)
        same_count = heb(got) == heb(draft)
        equal_counts += same_count
        identical += got == draft
        if not same_count:
            ok_all = False
        out.append("%s %s | %s%s | %d | %d | %s" % (
            "OK  " if same_count else "FAIL", name, label, "" if line is None else " [line %d]" % line,
            heb(got), heb(draft), "identical" if got == draft else "DIFFERS"))
    check("templates whose Hebrew count equals item 13", equal_counts == len(cases),
          "%d of %d" % (equal_counts, len(cases)))
    out.append("     templates whose rendering equals the draft character for character: %d of %d" % (identical, len(cases)))
    cmd = ev.invoke("AgTgCommandText", [])
    check("the command, item 5, Hebrew count", heb(cmd) == heb(command),
          "%d vs %d, identical %s" % (heb(cmd), heb(command), cmd == command))

    # ---- what no case renders
    out.append("")
    out.append("draft lines no case renders, alone or as a line of a rendered message:")
    rendered_lines = set()
    for name, got_text, want in cases:
        rendered_lines.update(got_text.split("\n"))
    for label in order:
        got = covered.get(label, set())
        if "all" in got:
            continue
        got = got | {n for n, line in enumerate(drafts[label]) if line in rendered_lines}
        for n in [n for n in range(len(drafts[label])) if n not in got]:
            out.append("     %s [line %d] %d Hebrew characters" % (label, n, heb(drafts[label][n])))
    never = [f for f in text_functions if f not in ev.called]
    out.append("functions of AlertText.mqh no case calls: %s" % (never if never else "none"))
    out.append("")
    out.append("render cases %d, drafts in item 13 %d" % (len(cases), len(order)))
    out.append("TG-S7 " + ("HOLDS" if ok_all else "DOES NOT HOLD"))
    sys.stdout.buffer.write(("\n".join(out) + "\n").encode("utf-8"))
    return 0 if ok_all else 1


if __name__ == "__main__":
    sys.exit(main())
