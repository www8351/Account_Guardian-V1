# The queue parser on hostile input, the tg_qr_ cases of the vectors script
# (TG-S12, fix pass B2 of 2026-10-21), run on the source by mqleval.py:
# AgVecTgQueueCases of AgPhase2StateVectors.mq5 calls the parser of
# AlertQueue.mqh and AgChecksum of Persist.mqh, each read from its own text.
# Every case reports its result: a rejection with its reason, a valid result
# with the events kept, or a runtime error (an array index out of range or a
# zero divide, the errors MQL5 stops a program on). The vectors run on the
# terminal stays the measurement of the compiled program.
#
# Usage: python -I scripts/rows/tg_s12_cases.py [repository root] [--queue <AlertQueue.mqh to use>]
# Exit code 0 when every case passes, 1 otherwise.
import os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import mqleval as mq

args = [a for a in sys.argv[1:]]
queue_override = None
if "--queue" in args:
    i = args.index("--queue")
    queue_override = args[i + 1]
    del args[i:i + 2]
ROOT = args[0] if args else os.path.dirname(os.path.dirname(HERE))
INC = os.path.join(ROOT, "MQL5", "Include", "AccountGuardian")
QUE = queue_override or os.path.join(INC, "AlertQueue.mqh")
VEC = os.path.join(ROOT, "MQL5", "Scripts", "AccountGuardian", "AgPhase2StateVectors.mq5")


class CaseEvaluator(mq.Evaluator):
    def __init__(self, *a, **k):
        super().__init__(*a, **k)
        self.results = []

    def call_user(self, name, args):
        if name != "AgVecTgQueueCase":
            return super().call_user(name, args)
        case = args[0].get() if hasattr(args[0], "get") else args[0]
        try:
            return super().call_user(name, args)
        except mq.MqlRuntimeError as exc:
            self.results.append(("tg_qr_" + case, False, "RUNTIME ERROR: " + str(exc)))
            return None


def main():
    consts, structs = {}, {}
    sources = [mq.read_text(os.path.join(INC, "State.mqh")), mq.read_text(QUE), mq.read_text(VEC)]
    for s in sources:
        mq.read_consts(s, consts)
        mq.read_structs(s, structs)
    functions = mq.read_functions(mq.read_text(QUE), structs)
    functions.update(mq.read_functions(mq.read_text(os.path.join(INC, "Persist.mqh")), structs, {"AgChecksum"}))
    vec_names = {"AgVecSealed", "AgVecTgField", "AgVecTgDropLast", "AgVecTgHeader", "AgVecTgE", "AgVecTgN",
                 "AgVecTgV", "AgVecTgFile", "AgVecTgQueueCase", "AgVecTgQueueCases"}
    functions.update(mq.read_functions(mq.read_text(VEC), structs, vec_names))
    ev = CaseEvaluator(functions, consts, structs)
    ev.builtins["AgVecCheck"] = lambda name, ok, detail: ev.results.append((name, ok, detail))
    ev.builtins["StringReplace"] = None
    # StringReplace takes its string by reference: handled as a statement here
    ev.functions["StringReplace"] = ("int", [("string", "s", True, False, None), ("string", "find", False, False, None),
                                             ("string", "repl", False, False, None)], None)

    def string_replace(args):
        cell, find, repl = args
        n = cell.get().count(find)
        cell.set(cell.get().replace(find, repl), ev)
        return n

    base_call_user = ev.call_user

    def call_user(name, a):
        if name == "StringReplace":
            return string_replace([a[0], a[1].get() if hasattr(a[1], "get") else a[1],
                                   a[2].get() if hasattr(a[2], "get") else a[2]])
        return base_call_user(name, a)
    ev.call_user = call_user

    ev.invoke("AgVecTgQueueCases", [])
    out = ["parser " + os.path.relpath(QUE, ROOT) if queue_override is None else "parser " + QUE]
    passed = 0
    for name, ok, detail in ev.results:
        passed += bool(ok)
        out.append("%s %s | %s" % ("PASS" if ok else "FAIL", name, detail))
    out.append("cases %d, pass %d, fail %d" % (len(ev.results), passed, len(ev.results) - passed))
    sys.stdout.buffer.write(("\n".join(out) + "\n").encode("utf-8"))
    return 0 if passed == len(ev.results) else 1


if __name__ == "__main__":
    sys.exit(main())
