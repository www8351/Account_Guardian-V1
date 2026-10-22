# Proof of the one-time ledger compaction of 2026-10-22, owner rulings C1 and
# C2 of 2026-10-21 with the owner's corrections of 2026-10-22. It reads the new
# LEDGER.md on disk and LEDGER.md at commit ffa5186 through git show. Every
# DECISIONS entry at ffa5186 is named below by its first line there, in its
# final class. A KEEP entry stands in the new DECISIONS once, every line of it
# but its Reason lines, byte for byte; an amendment stands directly after the
# entry it amends. A deleted entry's Decision line, or the Issue line of an
# entry moved from ISSUES, is absent. The six open ISSUES entries stand as
# approved, in order. The file is valid UTF-8 with CR equal to LF. The bare
# word heartbeat, which the naming discipline of 2026-07-29 rules out, stands
# only in the code review entry of 2026-10-01, kept byte for byte as the one
# known exception.
#
# Usage: python -I scripts/rows/ledger_compaction.py [repository root]
# Exit code 0 when every check passes, 1 otherwise.
import os, re, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(HERE))
BASE = "ffa5186"

KEEP = [2273, 2276, 2279, 2282, 2288, 2291, 2316, 2321, 2331, 2336, 2341, 2345,
        2349, 2355, 2359, 2363, 2371, 2383, 2387, 2391, 2395, 2399, 2403, 2407,
        2411, 2415, 2419, 2427, 2435, 2439, 2443, 2447, 2475, 2479, 2483, 2487,
        2491, 2498, 2502, 2506, 2510, 2514, 2518, 2522, 2526, 2530, 2534, 2538,
        2542, 2546, 2550, 2554, 2558, 2562, 2566, 2570, 2575, 2579, 2583, 2587,
        2591, 2607, 2611, 2615, 2619, 2623, 2627, 2631, 2635, 2639, 2644, 2648,
        2652, 2660, 2665, 2669, 2673, 2681, 2685, 2701, 2706, 2710, 2714, 2718,
        2722, 2730, 2734, 2738, 2742, 2746, 2750, 2753, 2761, 2765, 2773, 2777,
        2781, 2785, 2789, 2793, 2797, 2801, 2805, 2809, 2817, 2825, 2829, 2833,
        2837, 2845, 2849, 2853, 2857, 2861, 2865, 2869, 2873, 2877, 2881, 2885,
        2889, 2905, 2909, 2913, 2929, 2937, 2945, 2949, 2953, 2957, 2961, 2965,
        2969, 2973, 2981, 2985, 2989, 3001, 3005, 3009, 3013, 3017, 3021, 3025,
        3033, 3041, 3045, 3053, 3057, 3061, 3065, 3069, 3073, 3077]
ONETIME = [2285, 2297, 2303, 2306, 2311, 2326, 2367, 2451, 2455, 2459, 2463, 2467,
           2599, 2603, 2689, 2693, 2697, 2757, 2769, 2813, 2821, 2893, 2897, 2901,
           2917, 2921, 2925, 2933, 2941, 2977, 2993, 2997, 3029, 3037, 3049]
# superseded or void; each one's superseding entry is named in docs/evidence/ledger-compaction.md
SUPERSEDED = [2294, 2300, 2375, 2379, 2423, 2431, 2471, 2495, 2595, 2656, 2677, 2726,
              2841]
AMENDS = {2750: 2746, 2829: 2825}   # amendment: the KEEP entry it amends
EXCEPTION = 2937                    # the code review findings of 2026-10-01

# the open ISSUES entries as approved, in order: texts A, D, B, C, E and PUB
ISSUES = [r"""Issue:  TELEGRAM ALERTS ROWS NOT YET RUN, under R2 of 2026-10-21 (DECISIONS): the lock release and the end of day summary at the server day rollover; a trade opened while locked; the stop message; the dead-man drill; and every row on the live computer. The R2 row "the B3 format on the terminal" is closed by R1 on the owner's evidence of 2026-10-21, recorded in the compaction entry of ACTIONS. In the deployment phase the owner's attestation closes a row (R1); a defect found later is fixed on a new branch (R2).
Action: Pass B5, the PNL line and the open trades line of R3 and R4, build label `TG`, is on main at `ffa5186`, evidence `docs/evidence/tg-b5.md`. By the owner's evidence it runs on the demo terminal with `AGVEC|SUMMARY|522/522`. Venue per TG-10 (A): the demo terminal first, then the live account's computer by the installer. The rows are drafted in `docs/PLAN_TELEGRAM_ALERTS_2026-10-19.md` and `docs/PLAN_TELEGRAM_ALERTS_ADDENDUM_TG1B.md`. THE NEXT BEST ACTION IS THE OWNER'S: the remaining rows on the B5 build, each closed by the owner's attestation.
Status: OPEN""",
r"""Issue:  The broker server DST peg is documented, not measured. JustMarkets publishes server time as GMT+2 in winter and GMT+3 in summer; the calendar it follows sets the windows where server time and Israel civil time differ by an hour (candidate pegs US, EU, fixed GMT+3). The measured Monday reopen at server `2026.08.10 01:00:00`, Sunday 18:00 New York under GMT+3 with US DST, is consistent with a US peg and proves nothing. Server and Israel DST changes fall inside the weekend freeze, so a change shows only as the Monday reopen stamping at the new offset. Q1 of 2026-08-08 (DECISIONS, REVISIT scheduled) is revisited against this measurement.
Action: Harvest the dual clock LIFE lines across 2026-10-25 to 2026-11-01, the first stretch where Israel has left DST and the candidate pegs disagree. Both clocks are on every LIFE line since the `72ed960` fix. Read the offset from the `server=` and `local=` fields of the same line, never from the terminal's own line stamp; the local clock trails the server by about one second. Record the offset before and after and name the peg it settles. Until measured, no session cites a server DST calendar as fact.
Status: OPEN, window opens 2026-10-25""",
r"""Issue:  History stability poll counter is not reset on EA reinit (REASON_CHARTCHANGE=3, REASON_PARAMETERS=5). Globals survive reinit, so the SYNCING gate passes after a single poll, and the same reinits log ACTIVE->SYNCING instead of BOOT->SYNCING. Observed live 2026-10-05, account 2002830054, JustMarkets-Live, build label PK (binary md5 A259DB5A4693721FD9B0B5BEF4778148, build identity pending verification). Journal evidence: 16:03:39 SYNCING->ACTIVE polls=3/3 (fresh boot after reason=6); 16:04:06 SYNCING->ACTIVE polls=4/3 (after reason=3); 16:05:01 SYNCING->ACTIVE polls=5/3 (after reason=3); 16:10:29 SYNCING->ACTIVE polls=6/3 (after reason=5). Practical risk assessed low (same account, history already loaded), but the gate is meant to be fresh on every init.
Action: Owner ruling 2026-10-05: record as OPEN issue. Investigation and fix not yet authorized.
Status: OPEN""",
r"""Issue:  THE `stale_anchor_reconstructed` D3.1 BRANCH HAS ONLY BEEN EXERCISED IN ITS DEGENERATE ALL ZERO CASE, at the 2026-08-31 01:00:05 boot, `docs/evidence/journal-20260831-flat-expiry-and-v1a-lock.txt:125`. No banked evidence exercises it with a NONZERO stale figure, the case where reconstruction and the stale persisted value could actually disagree and the branch would be tested rather than merely fired.
Action: A FUTURE SESSION captures a run where a restart or boot derivation hits a stale anchor carrying a nonzero peak, so the branch is exercised on the case that can distinguish a correct reconstruction from an incorrect one.
Status: OPEN""",
r"""Issue:  A prior, unrelated AccountGuardian implementation exists inside the terminal data folder, outside this repo: MQL5\Experts\AccountGuardian_foreign.mq5.bak dated 2026-07-24, plus metaeditor.log references from 2026-07-25 to an AccountGuardian.mq5 and three AG_* scripts that are no longer on disk. The charter declares this project greenfield and any reference to prior implementations invalid by definition.
Action: Not read, not used, not deleted. Flagged for the owner. Nothing in this build derives from it.
Status: OPEN""",
r"""Issue:  PUBLICATION OF THE RELEASE REPOSITORY `www8351/AccountGuardian-Release`. The installer acceptance is complete and IN-S7 is closed on the release repository (history line of 2026-09-28 to 2026-10-01).
Action: The owner's act, gated on `docs/media/lock.gif`, `docs/media/install.gif` and `docs/media/attach.gif` existing under `docs/media` (DECISIONS, the GIF links ruling of 2026-09-30, and IN-29).
Status: OPEN"""]

out, fails = [], []


def check(name, ok, detail=""):
    out.append("%s %s%s" % ("PASS" if ok else "FAIL", name, " | " + detail if detail else ""))
    if not ok:
        fails.append(name)


def split_entries(lines):
    entries, cur = [], []
    for l in lines + [""]:
        if l:
            cur.append(l)
        elif cur:
            entries.append(cur)
            cur = []
    return entries


def main():
    base = subprocess.run(["git", "show", BASE + ":LEDGER.md"], cwd=ROOT, capture_output=True, check=True).stdout
    raw = open(os.path.join(ROOT, "LEDGER.md"), "rb").read()

    # the base: every DECISIONS entry starts on a non empty line after an empty one
    old = base.decode("utf-8").split("\n")
    d0 = old.index("## DECISIONS")
    blocks = {}
    for i in range(d0 + 1, len(old)):
        if old[i] and not old[i - 1]:
            e = i
            while e < len(old) and old[e]:
                e += 1
            blocks[i + 1] = old[i:e]
    classes = {}
    for s in KEEP:
        classes[s] = "KEEP"
    for s in ONETIME:
        classes[s] = "ONETIME"
    for s in SUPERSEDED:
        classes[s] = "SUPERSEDED"
    check("base entries", sorted(blocks) == sorted(classes) and len(classes) == len(KEEP) + len(ONETIME) + len(SUPERSEDED),
          "DECISIONS at %s holds %d entries, %d carry a class, each exactly one" % (BASE, len(blocks), len(classes)))

    # the new file
    try:
        text = raw.decode("utf-8")
        check("utf-8", True, "%d bytes decode, %d characters outside ASCII" % (len(raw), sum(1 for c in text if ord(c) > 127)))
    except UnicodeDecodeError as exc:
        check("utf-8", False, str(exc))
        text = raw.decode("utf-8", "replace")
    cr, lf, crlf = raw.count(b"\r"), raw.count(b"\n"), raw.count(b"\r\n")
    check("cr equals lf", cr == lf == crlf and raw.endswith(b"\r\n"), "CR %d, LF %d, CRLF %d, last line ends CRLF" % (cr, lf, crlf))
    check("no em or en dash", "—" not in text and "–" not in text,
          "U+2014 %d, U+2013 %d" % (text.count("—"), text.count("–")))
    lines = text.split("\r\n")
    heads = [l for l in lines if l.startswith("# ") or l.startswith("## ")]
    want = ["# LEDGER", "## ISSUES", "## ACTIONS", "## DECISIONS", "## PROJECT"]
    check("sections", heads == want, " then ".join(heads))
    i_iss, i_act, i_dec, i_proj = (lines.index(h) for h in want[1:])

    # ISSUES
    iss = split_entries([l for l in lines[i_iss + 1:i_act] if l != "---"])
    want_iss = [t.split("\n") for t in ISSUES]
    check("issues", iss == want_iss, "%d entries, %d approved, %d equal in order"
          % (len(iss), len(want_iss), sum(1 for a, b in zip(iss, want_iss) if a == b)))

    # ACTIONS: the compaction entry first, at most 1,500 characters (R5)
    first = next(l for l in lines[i_act + 1:i_dec] if l)
    check("compaction entry", first.startswith("2026-10-22. LEDGER COMPACTION") and len(first) <= 1500,
          "%d characters" % len(first))

    # DECISIONS
    section = lines[i_dec + 1:i_proj]
    dec = "\r\n".join(section)

    def kept(s):
        return "\r\n".join(l for l in blocks[s] if not l.startswith("Reason:"))

    missing = [s for s in KEEP if dec.count("\r\n\r\n" + kept(s) + "\r\n\r\n") != 1 or text.count(kept(s)) != 1]
    check("keep entries", not missing, "%d of %d stand once, byte for byte, Reason lines dropped%s"
          % (len(KEEP) - len(missing), len(KEEP), "; missing " + ", ".join(map(str, missing)) if missing else ""))
    for a, b in sorted(AMENDS.items()):
        check("amendment %d" % a, (kept(b) + "\r\n\r\n" + kept(a) + "\r\n") in dec, "directly after %d, the entry it amends" % b)
    present = []
    for s in ONETIME + SUPERSEDED:
        head = next(l for l in blocks[s] if l.startswith("Decision:") or l.startswith("Issue:"))
        if head in text:
            present.append(s)
    check("deleted entries", not present, "%d of %d Decision lines absent%s"
          % (len(ONETIME) + len(SUPERSEDED) - len(present), len(ONETIME) + len(SUPERSEDED),
             "; present " + ", ".join(map(str, present)) if present else ""))
    reasons = sum(1 for l in section if l.startswith("Reason:"))
    statuses = sum(1 for l in section if l.startswith("Status:"))
    check("reason lines", reasons == 0, "%d Reason lines in DECISIONS" % reasons)
    check("decision count", statuses == len(KEEP) + 2, "%d Status lines, %d KEEP entries plus C1 and C2" % (statuses, len(KEEP)))
    ents = [e for e in split_entries(section) if not e[0].startswith("#") and e != ["---"]]
    c1, c2 = ents[-2], ents[-1]
    check("c1 and c2", c1[0].startswith("Decision: (owner ruling given in chat on 2026-10-21, C1, ") and c1[-1] == "Status: FINAL"
          and c2[0].startswith("Decision: (owner ruling given in chat on 2026-10-21, C2, ") and c2[-1] == "Status: FINAL",
          "the last two entries of DECISIONS, FINAL")

    # the naming discipline: every use of the word, qualified, quoted as the word itself, or bare
    span = (text.find(kept(EXCEPTION)), text.find(kept(EXCEPTION)) + len(kept(EXCEPTION)))
    bare = []
    for m in re.finditer(r"heartbeat", text, re.I):
        q = re.search(r"(mutex|network)[ -]$", text[max(0, m.start() - 8):m.start()], re.I)
        line = text.count("\n", 0, m.start()) + 1
        if q:
            kind = "qualified, " + text[m.start() - len(q.group(0)):m.end()]
        elif text[m.start() - 1] == '"' and text[m.end()] == '"':
            kind = "quoted as the word itself, the naming rule"
        else:
            kind = "bare"
            bare.append(m.start())
        out.append("  heartbeat at line %d: %s" % (line, kind))
    check("naming exception", len(bare) == 1 and span[0] <= bare[0] < span[1],
          "%d bare use, inside the entry of %d at %s, the one known exception" % (len(bare), EXCEPTION, BASE))

    # PROJECT
    proj = [l for l in lines[i_proj + 1:] if l]
    check("project", 5 <= len(proj) <= 10, "%d lines" % len(proj))

    out.append("final classes: KEEP %d, deleted one-time %d, deleted superseded %d, total %d"
               % (len(KEEP), len(ONETIME), len(SUPERSEDED), len(KEEP) + len(ONETIME) + len(SUPERSEDED)))
    out.append("before: LEDGER.md at %s, %d bytes as git stores it (LF), %d bytes and %d lines on disk with CRLF"
               % (BASE, len(base), len(base) + base.count(b"\n"), base.count(b"\n")))
    out.append("after: LEDGER.md on disk, %d bytes and %d lines" % (len(raw), lf))
    out.append("checks %d, pass %d, fail %d" % (len([o for o in out if o[:5] in ("PASS ", "FAIL ")]),
                                                len([o for o in out if o.startswith("PASS ")]), len(fails)))
    sys.stdout.buffer.write(("\n".join(out) + "\n").encode("utf-8"))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
