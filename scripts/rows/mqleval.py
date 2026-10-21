# A small evaluator for the subset of MQL5 the alert includes and their
# vectors are written in, used by the static rows under scripts/rows. It reads
# function bodies from the source files themselves and runs them, so a row can
# measure what the source does without a terminal. It is not the compiler and
# not the terminal: the compiled program is measured by the vectors script on
# the terminal. What the evaluator models, and where it assumes:
# - integers wrap to their declared width on every store, return and cast, as
#   MQL5 integer arithmetic does; integer division truncates toward zero;
# - an array index outside the array raises MqlRuntimeError, the critical
#   error MQL5 stops a program on, and so does an integer division by zero;
# - StringToInteger reads an optional sign and the digits that follow and,
#   by assumption, saturates outside the long range; StringToDouble reads a
#   decimal number; StringSplit returns 0 on an empty string;
# - logical operators short circuit.
import calendar, copy, math, re, time

TOKEN_RE = re.compile(r"""
 (?P<ws>\s+)
|(?P<lc>//[^\n]*)
|(?P<bc>/\*.*?\*/)
|(?P<dt>D'[^']*')
|(?P<chr>'(?:\\.|[^'\\])')
|(?P<str>"(?:\\.|[^"\\])*")
|(?P<hex>0[xX][0-9A-Fa-f]+)
|(?P<num>\d+\.\d*(?:[eE][+-]?\d+)?|\d+[eE][+-]?\d+|\d+|\.\d+)
|(?P<id>[A-Za-z_]\w*)
|(?P<op><<|>>|==|!=|<=|>=|&&|\|\||\+=|-=|\*=|/=|\|=|&=|\^=|\+\+|--|[-+*/%<>=!&|^~?:;,.(){}\[\]])
""", re.S | re.X)

ESC = {"n": "\n", "r": "\r", "t": "\t", "\\": "\\", '"': '"', "'": "'", "0": "\0"}

INT_TYPES = {"char": (8, True), "uchar": (8, False), "short": (16, True), "ushort": (16, False),
             "int": (32, True), "uint": (32, False), "long": (64, True), "ulong": (64, False),
             "datetime": (64, True), "color": (32, False)}
TYPES = set(INT_TYPES) | {"string", "double", "float", "bool", "void"}
ASSIGN_OPS = ("=", "+=", "-=", "*=", "/=", "|=", "&=", "^=")


class MqlRuntimeError(Exception):
    """A critical runtime error: MQL5 stops the program on it."""


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
        elif kind == "hex":
            toks.append(("num", int(text, 16)))
        elif kind == "num":
            toks.append(("num", float(text) if ("." in text or "e" in text or "E" in text) else int(text)))
        elif kind == "id":
            toks.append(("id", text))
        else:
            toks.append(("op", text))
    toks.append(("eof", None))
    return toks


# ---------------------------------------------------------------- values
class MqlArray(list):
    """A dynamic or fixed array; elem is its element type."""

    def __init__(self, elem, items=()):
        super().__init__(items)
        self.elem = elem


def wrap(v, bits, signed):
    v &= (1 << bits) - 1
    if signed and v >= 1 << (bits - 1):
        v -= 1 << bits
    return v


def to_int(v):
    if isinstance(v, bool):
        return int(v)
    if isinstance(v, int):
        return v
    if math.isnan(v) or math.isinf(v):
        return 0
    return int(math.trunc(v))


class Cell:
    def __init__(self, value, typ):
        self.value = value
        self.typ = typ

    def get(self):
        return self.value

    def set(self, v, ev):
        self.value = ev.coerce(self.typ, v)


class Slot:
    """A reference to a struct field or an array element, for a by reference argument."""

    def __init__(self, container, key, typ):
        self.container = container
        self.key = key
        self.typ = typ

    def get(self):
        return self.container[self.key]

    def set(self, v, ev):
        self.container[self.key] = ev.coerce(self.typ, v)


# ---------------------------------------------------------------- parser
class Parser:
    LEVELS = [["||"], ["&&"], ["|"], ["^"], ["&"], ["==", "!="], ["<", ">", "<=", ">="], ["<<", ">>"], ["+", "-"], ["*", "/", "%"]]

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

    def is_type(self, tok):
        return tok[0] == "id" and (tok[1] in TYPES or tok[1] in self.structs)

    def block(self):
        self.take("op", "{")
        body = []
        while not self.at("op", "}"):
            body.append(self.statement())
        self.take("op", "}")
        return ("block", body)

    def simple(self):
        """A declaration, an assignment or an expression, without its ';'."""
        if self.at("id", "const") and self.is_type(self.peek(1)):
            self.take()
        tok = self.peek()
        if self.is_type(tok) and self.peek(1)[0] == "id":
            typ = self.take()[1]
            decls = []
            while True:
                name = self.take("id")[1]
                size = None
                if self.at("op", "["):
                    self.take()
                    size = self.expr() if not self.at("op", "]") else ("lit", -1)
                    self.take("op", "]")
                init = None
                if self.at("op", "="):
                    self.take()
                    if self.at("op", "{"):
                        self.take()
                        items = []
                        while not self.at("op", "}"):
                            items.append(self.expr())
                            if self.at("op", ","):
                                self.take()
                        self.take()
                        init = ("list", items)
                    else:
                        init = self.expr()
                decls.append((name, size, init))
                if self.at("op", ","):
                    self.take()
                    continue
                break
            return ("decl", typ, decls)
        e = self.expr()
        if self.at("op") and self.peek()[1] in ASSIGN_OPS:
            op = self.take()[1]
            return ("assign", op, e, self.expr())
        return ("expr", e)

    def statement(self):
        tok = self.peek()
        if tok == ("op", "{"):
            return self.block()
        if tok == ("op", ";"):
            self.take()
            return ("block", [])
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
        if tok == ("id", "while"):
            self.take()
            self.take("op", "(")
            cond = self.expr()
            self.take("op", ")")
            return ("for", None, cond, None, self.statement())
        if tok == ("id", "for"):
            self.take()
            self.take("op", "(")
            init = None if self.at("op", ";") else self.simple()
            self.take("op", ";")
            cond = None if self.at("op", ";") else self.expr()
            self.take("op", ";")
            step = None if self.at("op", ")") else self.simple()
            self.take("op", ")")
            return ("for", init, cond, step, self.statement())
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
        if tok == ("id", "continue"):
            self.take()
            self.take("op", ";")
            return ("continue",)
        st = self.simple()
        self.take("op", ";")
        return st

    def expr(self):
        cond = self.binary(0)
        if self.at("op", "?"):
            self.take()
            a = self.expr()
            self.take("op", ":")
            b = self.expr()
            return ("tern", cond, a, b)
        return cond

    def binary(self, level):
        if level == len(self.LEVELS):
            return self.unary()
        left = self.binary(level + 1)
        while self.at("op") and self.peek()[1] in self.LEVELS[level]:
            op = self.take()[1]
            left = ("bin", op, left, self.binary(level + 1))
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
        if self.at("op", "++") or self.at("op", "--"):
            op = self.take()[1]
            return ("incdec", op, self.unary(), True)
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
            elif self.at("op", "++") or self.at("op", "--"):
                e = ("incdec", self.take()[1], e, False)
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


# ---------------------------------------------------------------- reading sources
def read_text(path):
    raw = open(path, "rb").read()
    if raw[:3] == b"\xef\xbb\xbf":
        raw = raw[3:]
    return raw.decode("utf-8").replace("\r\n", "\n")


def read_structs(src, structs):
    for m in re.finditer(r"\bstruct\s+(\w+)\s*\{(.*?)\};", src, re.S):
        fields = []
        for f in re.finditer(r"^\s*(\w+)\s+(\w+)\s*(?:\[\s*(\w+)\s*\])?\s*;", m.group(2), re.M):
            fields.append((f.group(2), f.group(1), f.group(3)))
        structs[m.group(1)] = fields
    return structs


def read_consts(src, consts):
    for m in re.finditer(r"^#define\s+(\w+)\s+(-?\d+|0[xX][0-9A-Fa-f]+|\"[^\"]*\")[ \t]*(?://.*)?$", src, re.M):
        v = m.group(2)
        consts[m.group(1)] = v[1:-1] if v.startswith('"') else int(v, 0)
    for m in re.finditer(r"\benum\s+\w+\s*\{(.*?)\};", src, re.S):
        for e in re.finditer(r"\b(\w+)\s*=\s*(-?\d+)", m.group(1)):
            consts[e.group(1)] = int(e.group(2))
    return consts


def read_functions(src, structs, wanted=None):
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
        depth, b, in_str, in_chr = 0, k, False, False
        while True:
            ch = src[b]
            if in_str or in_chr:
                if ch == "\\":
                    b += 1
                elif (ch == '"' and in_str) or (ch == "'" and in_chr):
                    in_str = in_chr = False
            elif ch == '"':
                in_str = True
            elif ch == "'":
                in_chr = True
            elif ch == "/" and src[b + 1] == "/":
                b = src.index("\n", b)
                continue
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
            is_array = "[]" in p
            words = p.replace("&", " & ").replace("[]", " ").split()
            byref = "&" in words or is_array
            words = [w for w in words if w not in ("&", "const")]
            params.append((words[0], words[-1], byref, is_array, default))
        body = Parser(tokenize(src[k:b + 1]), structs).block()
        funcs[name] = (rtype, params, body)
    return funcs


# ---------------------------------------------------------------- evaluator
class Return(Exception):
    def __init__(self, value):
        self.value = value


class Break(Exception):
    pass


class Continue(Exception):
    pass


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


def string_to_integer(s):
    m = re.match(r"\s*([-+]?)(\d*)", s)
    digits = m.group(2)
    if not digits:
        return 0
    v = int(digits) * (-1 if m.group(1) == "-" else 1)
    return max(-(1 << 63), min((1 << 63) - 1, v))   # assumption: saturates


def string_to_double(s):
    m = re.match(r"\s*([-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?)", s)
    return float(m.group(1)) if m else 0.0


def string_split(s, sep, arr):
    pieces = s.split(chr(sep)) if s != "" else []
    arr[:] = pieces
    return len(pieces)


def string_get_character(s, i):
    return ord(s[i]) if 0 <= i < len(s) else 0


def string_find(s, sub, start=0):
    return s.find(sub, start)


def string_substr(s, start, length=-1):
    if start < 0 or start >= len(s):
        return ""
    return s[start:] if length < 0 else s[start:start + length]


def string_to_char_array(s, arr, start=0, count=-1, codepage=0):
    data = s.encode("utf-8" if codepage == 65001 else "latin-1", errors="replace") + b"\0"
    arr[:] = list(data)
    return len(data)


class Evaluator:
    def __init__(self, functions, consts, structs, extra_builtins=None):
        self.functions = functions
        self.consts = dict(consts)
        self.consts.update({"TIME_DATE": 1, "TIME_MINUTES": 2, "TIME_SECONDS": 4, "WHOLE_ARRAY": -1,
                            "CP_UTF8": 65001, "CP_ACP": 0})
        self.structs = structs
        self.called = set()
        self.builtins = {
            "DoubleToString": lambda v, d=8: "%.*f" % (int(d), v),
            "MathIsValidNumber": lambda v: math.isfinite(v),
            "MathRound": mql_round,
            "MathAbs": lambda v: abs(v),
            "TimeToString": lambda t, f=3: time_to_string(t, f),
            "StringSplit": string_split,
            "StringLen": len,
            "StringGetCharacter": string_get_character,
            "StringFind": string_find,
            "StringSubstr": string_substr,
            "StringToInteger": string_to_integer,
            "StringToDouble": string_to_double,
            "StringToCharArray": string_to_char_array,
            "ShortToString": lambda c: chr(c),
            "ArraySize": len,
            "ArrayResize": self.array_resize,
            "ZeroMemory": self.zero_memory,
        }
        if extra_builtins:
            self.builtins.update(extra_builtins)

    # types
    def default(self, typ, size=None):
        if size is not None:
            n = 0 if size < 0 else size
            return MqlArray(typ, [self.default(typ) for _ in range(n)])
        if typ in INT_TYPES:
            return 0
        if typ in ("double", "float"):
            return 0.0
        if typ == "bool":
            return False
        if typ == "string":
            return ""
        if typ in self.structs:
            d = {"__struct__": typ}
            for fname, ftype, fsize in self.structs[typ]:
                n = None if fsize is None else (int(fsize) if fsize.isdigit() else self.consts[fsize])
                d[fname] = self.default(ftype, n)
            return d
        raise TypeError("type " + typ)

    def coerce(self, typ, v):
        if typ in INT_TYPES:
            bits, signed = INT_TYPES[typ]
            return wrap(to_int(v), bits, signed)
        if typ in ("double", "float"):
            if isinstance(v, str):
                raise TypeError("a string bound to a number")
            return float(v)
        if typ == "bool":
            return bool(v)
        if typ == "string":
            if not isinstance(v, str):
                raise TypeError("a non string bound to a string")
            return v
        if typ in self.structs:
            if not isinstance(v, dict):
                raise TypeError("a non struct bound to a struct")
            return copy.deepcopy(v)
        if typ == "void":
            return v
        raise TypeError("type " + typ)

    def array_resize(self, arr, n, reserve=0):
        if n < len(arr):
            del arr[n:]
        else:
            arr.extend(self.default(arr.elem) for _ in range(n - len(arr)))
        return n

    def zero_memory(self, obj):
        if isinstance(obj, dict):
            fresh = self.default(obj["__struct__"])
            obj.clear()
            obj.update(fresh)

    # calls
    def invoke(self, name, values):
        """A direct call with plain values, for a script's own use."""
        rtype, params, body = self.functions[name]
        return self.call_user(name, [Cell(v, p[0]) if p[2] else v for v, p in zip(values, params)])

    def call_user(self, name, args):
        rtype, params, body = self.functions[name]
        self.called.add(name)
        local = {}
        for (ptype, pname, byref, is_array, pdefault), a in zip(params, args):
            if byref:
                local[pname] = a if isinstance(a, (Cell, Slot)) else Cell(a, ptype)
            else:
                v = a.get() if isinstance(a, (Cell, Slot)) else a
                local[pname] = Cell(self.coerce(ptype, v), ptype)
        for (ptype, pname, byref, is_array, pdefault) in params[len(args):]:
            local[pname] = Cell(self.coerce(ptype, self.val(pdefault, {})), ptype)
        try:
            self.run(body, local)
        except Return as r:
            return None if rtype == "void" else self.coerce(rtype, r.value)
        return None

    def call(self, name, arg_exprs, env):
        if name in self.functions:
            params = self.functions[name][1]
            args = []
            for k, a in enumerate(arg_exprs):
                byref = k < len(params) and params[k][2]
                args.append(self.ref(a, env) if byref else self.val(a, env))
            return self.call_user(name, args)
        if name in self.builtins:
            return self.builtins[name](*[self.val(a, env) for a in arg_exprs])
        raise NameError("unknown function " + name)

    # statements
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
        elif k == "for":
            if st[1] is not None:
                self.run(st[1], env)
            while st[2] is None or self.val(st[2], env):
                try:
                    self.run(st[4], env)
                except Break:
                    break
                except Continue:
                    pass
                if st[3] is not None:
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
        elif k == "continue":
            raise Continue()
        elif k == "decl":
            typ = st[1]
            for name, size, init in st[2]:
                if size is not None:
                    n = self.val(size, env)
                    arr = self.default(typ, n)
                    if init is not None:
                        arr = MqlArray(typ, [self.coerce(typ, self.val(x, env)) for x in init[1]])
                    env[name] = Cell(arr, typ)
                elif init is not None:
                    env[name] = Cell(self.coerce(typ, self.val(init, env)), typ)
                else:
                    env[name] = Cell(self.default(typ), typ)
        elif k == "assign":
            target = self.ref(st[2], env)
            v = self.val(st[3], env)
            if st[1] != "=":
                v = self.binop(st[1][0], target.get(), v)
            target.set(v, self)
        elif k == "expr":
            self.eval(st[1], env)
        else:
            raise SyntaxError("statement " + k)

    # expressions
    def ref(self, e, env):
        """The storage an lvalue names: a Cell or a Slot."""
        if e[0] == "name":
            if e[1] in env:
                return env[e[1]]
            raise NameError("not a variable " + e[1])
        if e[0] == "member":
            obj = self.val(e[1], env)
            ftype = [f[1] for f in self.structs[obj["__struct__"]] if f[0] == e[2]][0]
            if isinstance(obj[e[2]], MqlArray):
                return Cell(obj[e[2]], ftype)
            return Slot(obj, e[2], ftype)
        if e[0] == "index":
            arr = self.val(e[1], env)
            i = self.val(e[2], env)
            if not 0 <= i < len(arr):
                raise MqlRuntimeError("array out of range, index %d of %d" % (i, len(arr)))
            return Slot(arr, i, arr.elem)
        return Cell(self.val(e, env), None)

    def val(self, e, env):
        v = self.eval(e, env)
        return v.get() if isinstance(v, (Cell, Slot)) else v

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
            if isinstance(a, int) and isinstance(b, int) and not isinstance(a, bool):
                if b == 0:
                    raise MqlRuntimeError("zero divide")
                return int(a / b) if abs(a) < (1 << 52) else (abs(a) // abs(b)) * (1 if (a < 0) == (b < 0) else -1)
            return a / b
        if op == "%":
            if b == 0:
                raise MqlRuntimeError("zero divide")
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
        if op == "<<":
            return a << b
        if op == ">>":
            return a >> b
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
        if k == "incdec":
            target = self.ref(e[2], env)
            old = target.get()
            target.set(old + (1 if e[1] == "++" else -1), self)
            return target.get() if e[3] else old
        if k == "tern":
            return self.val(e[2], env) if self.val(e[1], env) else self.val(e[3], env)
        if k == "cast":
            v = self.val(e[2], env)
            if e[1] == "string":
                if isinstance(v, bool):
                    return "true" if v else "false"
                if isinstance(v, int):
                    return str(v)
                raise TypeError("(string) of a non integer is outside the evaluated subset")
            return self.coerce(e[1], v)
        if k == "member":
            return self.val(e[1], env)[e[2]]
        if k == "index":
            arr = self.val(e[1], env)
            i = self.val(e[2], env)
            if not 0 <= i < len(arr):
                raise MqlRuntimeError("array out of range, index %d of %d" % (i, len(arr)))
            return arr[i]
        if k == "call":
            if e[1][0] != "name":
                raise SyntaxError("call target")
            return self.call(e[1][1], e[2], env)
        raise SyntaxError(k)
