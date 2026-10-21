# Static row TG-S7 of the Telegram alerts build, design addendum item 10:
# "the include starts EF BB BF, decodes as strict UTF-8, holds no U+2013,
# U+2014 or U+05BE, and each template's Hebrew character count equals the
# drafts block of item 13".
#
# A template is one rendered message, or one rendered line of a wording list,
# as the vectors script renders it (plan 6.5.4). The count is taken from the
# source, not from a copy of the drafts: this script evaluates the functions
# of AlertText.mqh, and AgTgMoney and AgTgNum of AlertQueue.mqh, from their
# own text, with a small evaluator for the subset of MQL5 those functions use,
# on every tg_text_ render case of AgPhase2StateVectors.mq5 exactly as that
# file states it. Each case is tied to its draft by the md5 the vectors file
# carries. The vectors run on the terminal (TG-S8) stays the check of the
# compiled program; this row reads the source.
#
# Usage: python -I scripts/rows/tg_s7.py [repository root]
# Exit code 0 when every check holds, 1 otherwise.
import calendar, copy, hashlib, math, os, re, sys, time

ROOT = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
INC = os.path.join(ROOT, "MQL5", "Include", "AccountGuardian")
TXT = os.path.join(INC, "AlertText.mqh")
QUE = os.path.join(INC, "AlertQueue.mqh")
STA = os.path.join(INC, "State.mqh")
VEC = os.path.join(ROOT, "MQL5", "Scripts", "AccountGuardian", "AgPhase2StateVectors.mq5")
ADD = os.path.join(ROOT, "docs", "PLAN_TELEGRAM_ALERTS_ADDENDUM_TG1B.md")


def heb(s):
    return sum(1 for ch in s if "֐" <= ch <= "׿")


def read_text(path):
    raw = open(path, "rb").read()
    if raw[:3] == b"\xef\xbb\xbf":
        raw = raw[3:]
    return raw.decode("utf-8").replace("\r\n", "\n")


# ---------------------------------------------------------------- tokenizer
TOKEN_RE = re.compile(r"""
 (?P<ws>\s+)
|(?P<lc>//[^\n]*)
|(?P<bc>/\*.*?\*/)
|(?P<dt>D'[^']*')
|(?P<chr>'(?:\\.|[^'\\])')
|(?P<str>"(?:\\.|[^"\\])*")
|(?P<num>\d+\.\d*(?:[eE][+-]?\d+)?|\d+[eE][+-]?\d+|\d+|\.\d+)
|(?P<id>[A-Za-z_]\w*)
|(?P<op>==|!=|<=|>=|&&|\|\||\+=|-=|\*=|/=|\+\+|--|[-+*/%<>=!&|^~?:;,.(){}\[\]])
""", re.S | re.X)

ESC = {"n": "\n", "r": "\r", "t": "\t", "\\": "\\", '"': '"', "'": "'", "0": "\0"}


def unescape(body):
    out, i = [], 0
    while i < len(body):
        ch = body[i]
        if ch == "\\":
            nxt = body[i + 1]
            if nxt not in ESC:
                raise ValueError("escape \\" + nxt)
            out.append(ESC[nxt])
            i += 2
        else:
            out.append(ch)
            i += 1
    return "".join(out)


def tokenize(src):
    toks, pos = [], 0
    while pos < len(src):
        m = TOKEN_RE.match(src, pos)
        if not m:
            raise ValueError("cannot tokenize at " + repr(src[pos:pos + 40]))
        pos = m.end()
        kind = m.lastgroup
        text = m.group(kind)
        if kind in ("ws", "lc", "bc"):
            continue
        if kind == "str":
            toks.append(("str", unescape(text[1:-1])))
        elif kind == "chr":
            toks.append(("num", ord(unescape(text[1:-1]))))
        elif kind == "dt":
            v = text[2:-1].strip()
            fmt = "%Y.%m.%d %H:%M:%S" if v.count(":") == 2 else ("%Y.%m.%d %H:%M" if ":" in v else "%Y.%m.%d")
            toks.append(("num", calendar.timegm(time.strptime(v, fmt))))
        elif kind == "num":
            toks.append(("num", float(text) if ("." in text or "e" in text or "E" in text) else int(text)))
        elif kind == "id":
            toks.append(("id", text))
        else:
            toks.append(("op", text))
    toks.append(("eof", None))
    return toks


TYPES = {"string", "long", "int", "double", "bool", "ulong", "uint", "ushort", "uchar", "char", "datetime",
         "short", "float", "void"}


# ---------------------------------------------------------------- parser
class Parser:
    def __init__(self, toks, structs):
        self.t = toks
        self.i = 0
        self.structs = structs

    def peek(self, k=0):
        return self.t[self.i + k]

    def take(self, kind=None, val=None):
        tok = self.t[self.i]
        if (kind and tok[0] != kind) or (val is not None and tok[1] != val):
            raise SyntaxError("expected %s %s got %s" % (kind, val, tok))
        self.i += 1
        return tok

    def at(self, kind, val=None):
        tok = self.t[self.i]
        return tok[0] == kind and (val is None or tok[1] == val)

    # statements
    def block(self):
        self.take("op", "{")
        body = []
        while not self.at("op", "}"):
            body.append(self.statement())
        self.take("op", "}")
        return ("block", body)

    def is_type(self, tok):
        return tok[0] == "id" and (tok[1] in TYPES or tok[1] in self.structs)

    def statement(self):
        tok = self.peek()
        if tok == ("op", "{"):
            return self.block()
        if tok == ("id", "return"):
            self.take()
            if self.at("op", ";"):
                self.take()
                return ("return", None)
            e = self.expr()
            self.take("op", ";")
            return ("return", e)
        if tok == ("id", "if"):
            self.take()
            self.take("op", "(")
            cond = self.expr()
            self.take("op", ")")
            then = self.statement()
            other = None
            if self.at("id", "else"):
                self.take()
                other = self.statement()
            return ("if", cond, then, other)
        if tok == ("id", "switch"):
            self.take()
            self.take("op", "(")
            subj = self.expr()
            self.take("op", ")")
            self.take("op", "{")
            groups = []
            while not self.at("op", "}"):
                labels = []
                while self.at("id", "case"):
                    self.take()
                    labels.append(self.expr())
                    self.take("op", ":")
                body = []
                while not (self.at("id", "case") or self.at("op", "}")):
                    body.append(self.statement())
                groups.append((labels, body))
            self.take("op", "}")
            return ("switch", subj, groups)
        if tok == ("id", "break"):
            self.take()
            self.take("op", ";")
            return ("break",)
        if tok[0] == "id" and tok[1] in ("for", "while", "do"):
            raise SyntaxError("loops are outside the evaluated subset: " + tok[1])
        if tok == ("id", "const") and self.is_type(self.peek(1)):
            self.take()
            tok = self.peek()
        if self.is_type(tok) and self.peek(1)[0] == "id":
            typ = self.take()[1]
            decls = []
            while True:
                name = self.take("id")[1]
                is_array = False
                if self.at("op", "["):
                    self.take()
                    self.take("op", "]")
                    is_array = True
                init = None
                if self.at("op", "="):
                    self.take()
                    init = self.expr()
                decls.append((name, is_array, init))
                if self.at("op", ","):
                    self.take()
                    continue
                break
            self.take("op", ";")
            return ("decl", typ, decls)
        e = self.expr()
        if self.at("op") and self.peek()[1] in ("=", "+="):
            op = self.take()[1]
            rhs = self.expr()
            self.take("op", ";")
            return ("assign", op, e, rhs)
        self.take("op", ";")
        return ("expr", e)

    # expressions, C precedence
    def expr(self):
        return self.ternary()

    def ternary(self):
        cond = self.binary(0)
        if self.at("op", "?"):
            self.take()
            a = self.ternary()
            self.take("op", ":")
            b = self.ternary()
            return ("tern", cond, a, b)
        return cond

    LEVELS = [["||"], ["&&"], ["|"], ["^"], ["&"], ["==", "!="], ["<", ">", "<=", ">="], ["+", "-"], ["*", "/", "%"]]

    def binary(self, level):
        if level == len(self.LEVELS):
            return self.unary()
        left = self.binary(level + 1)
        while self.at("op") and self.peek()[1] in self.LEVELS[level]:
            op = self.take()[1]
            right = self.binary(level + 1)
            left = ("bin", op, left, right)
        return left

    def unary(self):
        if self.at("op", "!"):
            self.take()
            return ("not", self.unary())
        if self.at("op", "-"):
            self.take()
            return ("neg", self.unary())
        if self.at("op", "~"):
            self.take()
            return ("inv", self.unary())
        if self.at("op", "(") and self.peek(1)[0] == "id" and self.peek(1)[1] in TYPES and self.peek(2) == ("op", ")"):
            self.take()
            typ = self.take()[1]
            self.take()
            return ("cast", typ, self.unary())
        return self.postfix()

    def postfix(self):
        e = self.primary()
        while True:
            if self.at("op", "("):
                self.take()
                args = []
                while not self.at("op", ")"):
                    args.append(self.expr())
                    if self.at("op", ","):
                        self.take()
                self.take("op", ")")
                e = ("call", e, args)
            elif self.at("op", "."):
                self.take()
                e = ("member", e, self.take("id")[1])
            elif self.at("op", "["):
                self.take()
                idx = self.expr()
                self.take("op", "]")
                e = ("index", e, idx)
            else:
                return e

    def primary(self):
        tok = self.take()
        if tok[0] == "num":
            return ("lit", tok[1])
        if tok[0] == "str":
            s = tok[1]
            while self.at("str"):
                s += self.take()[1]
            return ("lit", s)
        if tok[0] == "id":
            if tok[1] == "true":
                return ("lit", True)
            if tok[1] == "false":
                return ("lit", False)
            return ("name", tok[1])
        if tok == ("op", "("):
            e = self.expr()
            self.take("op", ")")
            return e
        raise SyntaxError("unexpected " + str(tok))


# ---------------------------------------------------------------- evaluator
class Return(Exception):
    def __init__(self, value):
        self.value = value


class Break(Exception):
    pass


class Cell:
    def __init__(self, value):
        self.value = value


def coerce(typ, v):
    if typ in ("long", "int", "ulong", "uint", "ushort", "uchar", "char", "datetime", "short"):
        if isinstance(v, bool):
            return int(v)
        return int(v) if isinstance(v, int) else int(math.trunc(v))
    if typ in ("double", "float"):
        return float(v)
    if typ == "bool":
        return bool(v)
    if typ == "string":
        if not isinstance(v, str):
            raise TypeError("a non string bound to a string")
        return v
    return copy.deepcopy(v)


def mql_round(x):
    return math.floor(abs(x) + 0.5) * (1 if x >= 0 else -1)


def time_to_string(t, flags):
    g = time.gmtime(int(t))
    parts = []
    if flags & 1:
        parts.append(time.strftime("%Y.%m.%d", g))
    if flags & 4:
        parts.append(time.strftime("%H:%M:%S", g))
    elif flags & 2:
        parts.append(time.strftime("%H:%M", g))
    return " ".join(parts)


def string_split(s, sep, arr):
    pieces = s.split(chr(sep))
    arr[:] = pieces
    return len(pieces)


class Interp:
    def __init__(self, functions, consts, structs, builtins):
        self.functions = functions
        self.consts = consts
        self.structs = structs
        self.builtins = builtins
        self.called = set()

    def call(self, name, args, env):
        if name in self.functions:
            params, body = self.functions[name]
            self.called.add(name)
            local = {}
            for (ptype, pname, byref, pdefault), a in zip(params, args):
                if byref:
                    local[pname] = a if isinstance(a, Cell) else Cell(a)
                else:
                    v = a.value if isinstance(a, Cell) else a
                    local[pname] = Cell(coerce(ptype, v))
            for (ptype, pname, byref, pdefault) in params[len(args):]:
                local[pname] = Cell(coerce(ptype, self.eval(pdefault, {})))
            try:
                self.run(body, local)
            except Return as r:
                return r.value
            return None
        if name in self.builtins:
            vals = [a.value if isinstance(a, Cell) else a for a in args]
            return self.builtins[name](*vals)
        raise NameError("unknown function " + name)

    def run(self, st, env):
        k = st[0]
        if k == "block":
            for s in st[1]:
                self.run(s, env)
        elif k == "return":
            raise Return(None if st[1] is None else self.val(st[1], env))
        elif k == "if":
            if self.val(st[1], env):
                self.run(st[2], env)
            elif st[3] is not None:
                self.run(st[3], env)
        elif k == "switch":
            subj = self.val(st[1], env)
            hit = False
            try:
                for labels, body in st[2]:
                    if not hit and any(self.val(l, env) == subj for l in labels):
                        hit = True
                    if hit:
                        for s in body:
                            self.run(s, env)
            except Break:
                pass
        elif k == "break":
            raise Break()
        elif k == "decl":
            typ = st[1]
            for name, is_array, init in st[2]:
                if is_array:
                    env[name] = Cell([])
                elif init is not None:
                    env[name] = Cell(coerce(typ, self.val(init, env)))
                elif typ in self.structs:
                    env[name] = Cell({f: 0 for f in self.structs[typ]})
                else:
                    env[name] = Cell("" if typ == "string" else 0)
        elif k == "assign":
            v = self.val(st[3], env)
            target = st[2]
            if st[1] == "+=":
                v = self.binop("+", self.val(target, env), v)
            self.store(target, v, env)
        elif k == "expr":
            self.eval(st[1], env)
        else:
            raise SyntaxError("statement " + k)

    def store(self, target, v, env):
        if target[0] == "name":
            cell = env[target[1]]
            cell.value = copy.deepcopy(v) if isinstance(v, dict) else v
        elif target[0] == "member":
            obj = self.val(target[1], env)
            obj[target[2]] = v
        else:
            raise SyntaxError("store " + target[0])

    def val(self, e, env):
        v = self.eval(e, env)
        return v.value if isinstance(v, Cell) else v

    def binop(self, op, a, b):
        if op == "+":
            if isinstance(a, str) != isinstance(b, str):
                raise TypeError("string + number without a cast")
            return a + b
        if op == "-":
            return a - b
        if op == "*":
            return a * b
        if op == "/":
            if isinstance(a, int) and isinstance(b, int):
                return int(a / b)
            return a / b
        if op == "%":
            return int(math.fmod(a, b))
        if op == "==":
            return a == b
        if op == "!=":
            return a != b
        if op == "<":
            return a < b
        if op == ">":
            return a > b
        if op == "<=":
            return a <= b
        if op == ">=":
            return a >= b
        if op == "&":
            return a & b
        if op == "|":
            return a | b
        if op == "^":
            return a ^ b
        raise SyntaxError(op)

    def eval(self, e, env):
        k = e[0]
        if k == "lit":
            return e[1]
        if k == "name":
            if e[1] in env:
                return env[e[1]]
            if e[1] in self.consts:
                return self.consts[e[1]]
            raise NameError("unknown name " + e[1])
        if k == "bin":
            op = e[1]
            if op == "&&":
                return bool(self.val(e[2], env)) and bool(self.val(e[3], env))
            if op == "||":
                return bool(self.val(e[2], env)) or bool(self.val(e[3], env))
            return self.binop(op, self.val(e[2], env), self.val(e[3], env))
        if k == "not":
            return not self.val(e[1], env)
        if k == "neg":
            return -self.val(e[1], env)
        if k == "inv":
            return ~self.val(e[1], env)
        if k == "tern":
            return self.val(e[2], env) if self.val(e[1], env) else self.val(e[3], env)
        if k == "cast":
            v = self.val(e[2], env)
            if e[1] == "string":
                if isinstance(v, bool) or not isinstance(v, int):
                    raise TypeError("(string) of a non integer is outside the evaluated subset")
                return str(v)
            return coerce(e[1], v)
        if k == "member":
            return self.val(e[1], env)[e[2]]
        if k == "index":
            return self.val(e[1], env)[self.val(e[2], env)]
        if k == "call":
            if e[1][0] != "name":
                raise SyntaxError("call target")
            args = [self.eval(a, env) for a in e[2]]
            return self.call(e[1][1], args, env)
        raise SyntaxError(k)


def extract_functions(src, structs, wanted=None):
    funcs = {}
    for m in re.finditer(r"^[ \t]*([A-Za-z_]\w*)[ \t]+([A-Za-z_]\w*)[ \t]*\(", src, re.M):
        rtype, name = m.group(1), m.group(2)
        if rtype not in TYPES and rtype not in structs:
            continue
        if wanted is not None and name not in wanted:
            continue
        depth, j = 0, m.end() - 1
        while True:
            if src[j] == "(":
                depth += 1
            elif src[j] == ")":
                depth -= 1
                if depth == 0:
                    break
            j += 1
        params_src = src[m.end():j]
        k = j + 1
        while src[k] in " \t\r\n":
            k += 1
        if src[k] != "{":
            continue
        depth, b = 0, k
        in_str = False
        while True:
            ch = src[b]
            if in_str:
                if ch == "\\":
                    b += 1
                elif ch == '"':
                    in_str = False
            elif ch == '"':
                in_str = True
            elif ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    break
            b += 1
        params = []
        for p in [x.strip() for x in params_src.split(",") if x.strip()]:
            default = None
            if "=" in p:
                p, d = p.split("=", 1)
                default = Parser(tokenize(d), structs).expr()
            words = p.replace("&", " & ").split()
            byref = "&" in words
            words = [w for w in words if w not in ("&", "const")]
            ptype, pname = words[0], words[-1].replace("[]", "")
            if pname.endswith("[]") or p.strip().endswith("[]"):
                byref = True
            params.append((ptype, pname, byref, default))
        body = Parser(tokenize(src[k:b + 1]), structs).block()
        funcs[name] = (params, body)
    return funcs


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
    for ch, name in (("–", "U+2013"), ("—", "U+2014"), ("־", "U+05BE")):
        check("AlertText.mqh holds no " + name, src.count(ch) == 0, "count %d" % src.count(ch))
    outside = re.sub(r'"((?:[^"\\]|\\.)*)"', '""', src)
    outside = re.sub(r"//[^\n]*", "", outside)
    check("no Hebrew outside string literals", heb(outside) == 0, "count %d" % heb(outside))
    src = src.replace("\r\n", "\n")

    # ---- the drafts of item 13 and the command of item 5
    a = read_text(ADD).split("\n")
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
    consts = {"TIME_DATE": 1, "TIME_MINUTES": 2, "TIME_SECONDS": 4}
    for path in (STA,):
        for m in re.finditer(r"\b(AG_[A-Z_]+)\s*=\s*(\d+)", read_text(path)):
            consts[m.group(1)] = int(m.group(2))
    for path in (QUE, TXT):
        for m in re.finditer(r"^#define\s+(\w+)\s+(-?\d+)\b", read_text(path), re.M):
            consts[m.group(1)] = int(m.group(2))
    structs = {}
    m = re.search(r"struct AgTgCommon\s*\{(.*?)\};", src, re.S)
    structs["AgTgCommon"] = re.findall(r"^\s*\w+\s+(\w+);", m.group(1), re.M)
    functions = extract_functions(src, structs)
    functions.update(extract_functions(read_text(QUE), structs, {"AgTgMoney", "AgTgNum"}))
    functions.update(extract_functions(read_text(VEC), structs, {"AgVecLine", "AgVecC"}))
    cases = []
    builtins = {
        "DoubleToString": lambda v, d: "%.*f" % (int(d), v),
        "MathIsValidNumber": lambda v: math.isfinite(v),
        "MathRound": mql_round,
        "MathAbs": lambda v: abs(v),
        "TimeToString": time_to_string,
        "StringSplit": string_split,
        "AgVecMd5": lambda name, got, want: cases.append((name, got, want)),
    }
    it = Interp(functions, consts, structs, builtins)
    text_functions = sorted(n for n in functions if n not in ("AgTgMoney", "AgTgNum", "AgVecLine", "AgVecC"))

    vec = read_text(VEC).split("\n")
    env = {}
    for line in vec:
        t = line.strip()
        if t == "AgTgCommon c;":
            env["c"] = Cell({f: 0 for f in structs["AgTgCommon"]})
        elif t.startswith("AgVecC(") or t.startswith('AgVecMd5("tg_text_'):
            st = Parser(tokenize(t), structs).statement()
            it.run(st, env)

    # ---- per template counts
    out.append("")
    out.append("per template: case | draft | Hebrew in the code's rendering | Hebrew in the draft | text")
    covered = {}
    equal_counts = 0
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
        if not same_count:
            ok_all = False
        out.append("%s %s | %s%s | %d | %d | %s" % (
            "OK  " if same_count else "FAIL", name, label, "" if line is None else " [line %d]" % line,
            heb(got), heb(draft), "identical" if got == draft else "DIFFERS"))
    check("templates whose Hebrew count equals item 13", equal_counts == len(cases),
          "%d of %d" % (equal_counts, len(cases)))
    identical = sum(1 for name, got, want in cases if want in by_md5 and got == (
        drafts[by_md5[want][0]][by_md5[want][1]] if by_md5[want][1] is not None else "\n".join(drafts[by_md5[want][0]])))
    out.append("     templates whose rendering equals the draft character for character: %d of %d" % (identical, len(cases)))
    check("the command, item 5, Hebrew count", heb(it.call("AgTgCommandText", [], {})) == heb(command),
          "%d vs %d, identical %s" % (heb(it.call("AgTgCommandText", [], {})), heb(command),
                                       it.call("AgTgCommandText", [], {}) == command))

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
        missing = [n for n in range(len(drafts[label])) if n not in got]
        for n in missing:
            out.append("     %s [line %d] %d Hebrew characters" % (label, n, heb(drafts[label][n])))
    never = [f for f in text_functions if f not in it.called]
    out.append("functions of AlertText.mqh no case calls: %s" % (never if never else "none"))
    out.append("")
    out.append("render cases %d, drafts in item 13 %d" % (len(cases), len(order)))
    out.append("TG-S7 " + ("HOLDS" if ok_all else "DOES NOT HOLD"))
    sys.stdout.buffer.write(("\n".join(out) + "\n").encode("utf-8"))
    return 0 if ok_all else 1


if __name__ == "__main__":
    sys.exit(main())
