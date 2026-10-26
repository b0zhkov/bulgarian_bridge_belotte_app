"""Regenerates the rating-related parts of database.rules.json (beta 12).

The RTDB rules language has no variables, so the anti-farming checks are
written here once and expanded into the long rule strings.

    python3 tool/gen_rating_rules.py
"""
import json
import pathlib

RULES = pathlib.Path(__file__).resolve().parent.parent / 'database.rules.json'
DAY = 86400000           # UTC day (rules only know `now` in UTC ms)
WINDOW = 86400000        # repeat-opponent rolling window (24 h)
MIN_MATCH = 480000       # 8 minutes from match start to result
CAP = 100                # max rating gained per UTC day
K = 32                   # max |delta| of one result
CODE = "/^[ABCDEFGHJKMNPQRSTUVWXYZ2-9]{5}$/"


def ratings():
    qr = ("root.child('qresults').child(newData.child('c').val())"
          ".child(newData.child('x').val()).child($uid)")
    before = "(data.exists() ? data.child('r').val() : 1000)"
    ap = f"(newData.child('r').val() - {before})"
    same_day = "(data.child('dy').val() === newData.child('dy').val())"
    gd0 = f"({same_day} ? data.child('gd').val() : 0)"
    oh = "root.child('rhist').child($uid).child(newData.child('k').val())"

    def rec(x):
        return (f"({oh}.child('{x}').isNumber() && "
                f"{oh}.child('{x}').val() > now - {WINDOW})")

    f = f"({rec('a')} ? ({rec('b')} ? ({rec('c')} ? 0 : 0.25) : 0.5) : 1)"
    e = f"(newData.child('d').val() * {f})"
    rem = f"({CAP} - {gd0})"
    t = f"({e} < {rem} ? {e} : {rem})"
    ap_ok = (f"({e} > 0 ? ({ap} >= {t} - 0.5 && {ap} <= {t} + 0.5) : "
             f"({ap} >= {e} - 0.5 && {ap} <= {e} + 0.5))")
    gd_ok = (f"newData.child('gd').val() === {gd0} + ({ap} > 0 ? {ap} : 0) && "
             f"newData.child('gd').val() >= 0 && newData.child('gd').val() <= {CAP}")
    dy = "newData.child('dy').val()"
    dy_ok = f"{dy} % 1 === 0 && {dy} * {DAY} <= now && now < {dy} * {DAY} + {DAY}"
    nh = ("newData.parent().parent().child('rhist').child($uid)"
          ".child(newData.child('k').val()).child('a').val() === now")
    validate = " && ".join([
        "newData.hasChildren(['r', 'g', 'c', 'x', 't', 'k', 'd', 'dy', 'gd'])",
        "newData.child('t').val() === now",
        f"{qr}.exists()",
        f"{qr}.child('b').val() === {before}",
        f"{qr}.child('d').val() === newData.child('d').val()",
        f"{qr}.child('k').val() === newData.child('k').val()",
        "(!data.exists() || data.child('c').val() !== newData.child('c').val() || data.child('x').val() !== newData.child('x').val())",
        "newData.child('g').val() === (data.exists() ? data.child('g').val() : 0) + 1",
        "newData.child('r').val() % 1 === 0",
        dy_ok,
        ap_ok,
        gd_ok,
        nh,
    ])
    num = {".validate": "newData.isNumber()"}
    return {
        ".read": "auth != null",
        "$uid": {
            ".write": "auth != null && auth.uid === $uid && (newData.exists() || data.child('r').val() >= 1000)",
            ".validate": validate,
            "r": num, "g": num, "t": num, "d": num, "dy": num, "gd": num,
            "c": {".validate": f"newData.isString() && newData.val().matches({CODE})"},
            "x": {".validate": "newData.isString() && newData.val().length <= 40"},
            "k": {".validate": "newData.isString() && newData.val().length <= 80"},
            "$other": {".validate": False},
        },
    }


def rhist():
    num = {".validate": "newData.isNumber()"}
    return {
        "$uid": {
            ".read": "auth != null && auth.uid === $uid",
            ".write": "auth != null && auth.uid === $uid && !newData.exists() && !root.child('ratings').child($uid).exists()",
            "$hk": {
                ".write": f"auth != null && auth.uid === $uid && (newData.exists() || (data.child('a').isNumber() && data.child('a').val() < now - {WINDOW}))",
                ".validate": " && ".join([
                    "$hk.matches(/^[A-Za-z0-9_]{1,80}$/)",
                    "newData.child('a').val() === now",
                    "(data.child('a').exists() ? newData.child('b').val() === data.child('a').val() : !newData.child('b').exists())",
                    "(data.child('b').exists() ? newData.child('c').val() === data.child('b').val() : !newData.child('c').exists())",
                ]),
                "a": num, "b": num, "c": num,
                "$other": {".validate": False},
            },
        },
    }


def qresults():
    room = "root.child('rooms').child($code)"
    p = "newData.parent()"
    o1 = "newData.child('o1').val()"
    o2 = "newData.child('o2').val()"

    def mutual(o):
        return (f"({p}.child({o}).child('o1').val() === $uid || "
                f"{p}.child({o}).child('o2').val() === $uid)")

    def member(o):
        return f"{room}.child('members').child({o}).exists()"

    validate = " && ".join([
        "newData.hasChildren(['b', 'd', 'k', 'o1'])",
        "newData.child('b').isNumber() && newData.child('d').isNumber()",
        f"newData.child('d').val() >= -{K} && newData.child('d').val() <= {K}",
        "newData.child('b').val() === (root.child('ratings').child($uid).exists() ? root.child('ratings').child($uid).child('r').val() : 1000)",
        member("$uid"),
        f"{o1} !== $uid && {mutual(o1)} && {member(o1)}",
        (f"(newData.child('o2').exists() ? ({o2} !== $uid && {o1} < {o2} && "
         f"{mutual(o2)} && {member(o2)} && newData.child('k').val() === {o1} + '_' + {o2}) : "
         f"newData.child('k').val() === {o1})"),
    ])
    s = {".validate": "newData.isString() && newData.val().length <= 40"}
    num = {".validate": "newData.isNumber()"}
    return {
        "$code": {
            "$rid": {
                ".read": "auth != null",
                ".write": (f"auth != null && !data.exists() && newData.exists() && "
                           f"{room}.child('meta').child('host').val() === auth.uid && "
                           f"{room}.child('meta').child('qm').val() === true && "
                           f"{room}.child('meta').child('st').isNumber() && "
                           f"now >= {room}.child('meta').child('st').val() + {MIN_MATCH}"),
                "$uid": {
                    ".write": "auth != null && auth.uid === $uid && !newData.exists()",
                    ".validate": validate,
                    "b": num, "d": num, "o1": s, "o2": s,
                    "k": {".validate": "newData.isString() && newData.val().length <= 80"},
                    "$other": {".validate": False},
                },
            },
        },
    }


def main():
    rules = json.loads(RULES.read_text())
    r = rules['rules']
    host = "auth != null && root.child('rooms').child($code).child('meta/host').val() === auth.uid"
    meta = r['rooms']['$code']['meta']
    other = meta.pop('$other')
    meta['st'] = {".write": host, ".validate": "newData.val() === now"}
    meta['ur'] = {".write": host, ".validate": "newData.isString() && newData.val().length <= 64"}
    meta['$other'] = other
    r['ratings'] = ratings()
    r['qresults'] = qresults()
    ach = r.pop('ach')
    r['rhist'] = rhist()
    r['ach'] = ach
    RULES.write_text(json.dumps(rules, indent=2, ensure_ascii=False) + '\n')
    print('rules:', len(RULES.read_text()), 'bytes; ratings validate', len(r['ratings']['$uid']['.validate']), 'chars')


if __name__ == '__main__':
    main()
