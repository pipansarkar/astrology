"""Lists every English UI string that needs a translation.

  python3 -I tool/extract_tr_keys.py            # prints JSON list
  python3 -I tool/extract_tr_keys.py --missing  # keys missing in bn or hi

Static keys come from tr('...') calls; dynamic keys (festival names, koota
names, numerology texts, ...) are read from the domain tables listed below.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIT = r"""(?:'(?:[^'\\\n]|\\.)*'|"(?:[^"\\\n]|\\.)*")"""


def unquote(lit):
    body = lit[1:-1]
    return re.sub(r"\\(.)", lambda m: "\n" if m.group(1) == "n" else m.group(1), body)


def literals_after(pattern, text):
    out = []
    for m in re.finditer(pattern + r"\s*((?:" + LIT + r"\s*)+)", text):
        out.append("".join(unquote(x) for x in re.findall(LIT, m.group(1))))
    return out


keys = set()
for f in (ROOT / "lib").rglob("*.dart"):
    if f.parent.name == "l10n":
        continue
    keys.update(literals_after(r"\btr\(", f.read_text()))

# Dynamic keys from domain tables.
dyn_sources = {
    "lib/astro/festivals.dart": [r"_Rule\(", r"Festival\(\s*", r"sankrantiNames\s*=\s*\{[^}]*?\d+:\s*",
                                 r"\badd\(", r"Observe\.\w+,\s*"],
    "lib/astro/muhurat.dart": [r"label:\s*"],
    "lib/astro/vedic/dignity.dart": [r"Dignity\.\w+:\s*"],
    "lib/astro/vedic/matching.dart": [r"Koota\(\s*", r"Koota\(\s*" + LIT + r",\s*", r"\?\s*", r":\s*"],
    "lib/astro/vedic/doshas.dart": [r"name:\s*", r"summary:\s*", r"remedy:\s*", r"ShaniPhase\.\w+:\s*",
                                   r"_conjunction\(\s*k,\s*", r"'Respect", r"\?\s*", r":\s*"],
    "lib/numerology/numerology.dart": [r"planet:\s*", r"traits:\s*", r"return\s*"],
    "lib/charts/chart_layout.dart": [r"ChartStyle\.\w+:\s*"],
}
for path, patterns in dyn_sources.items():
    text = (ROOT / path).read_text()
    for p in patterns:
        keys.update(literals_after(p, text))
    # list literals of words, e.g. days/colours/table names
    for m in re.finditer(r"(?:days|colours):\s*\[([^\]]*)\]", text):
        keys.update(unquote(x) for x in re.findall(LIT, m.group(1)))
    for m in re.finditer(r"const _(?:varnaNames|vashyaNames|yoniNames|ganaNames|nadiNames)\s*=\s*\[([^\]]*)\]", text):
        keys.update(unquote(x) for x in re.findall(LIT, m.group(1)))

keys.update([
    "Total solar eclipse", "Partial solar eclipse", "Annular solar eclipse", "Hybrid solar eclipse",
    "Total lunar eclipse", "Partial lunar eclipse", "Penumbral lunar eclipse",
    "Excellent match", "Very good match", "Acceptable match", "Not recommended",
    "Nakshatra count", "Sun", "Moon", "Mars", "Mercury", "Jupiter", "Venus", "Saturn", "Rahu", "Ketu",
    "Devi Paksha begins",
])
keys = sorted(
    k for k in keys
    if len(k) > 1 and re.search(r"[A-Za-z]", k) and "$" not in k and not k.startswith(("package:", "../"))
)

if "--missing" in sys.argv:
    have = {}
    for lang in ("bn", "hi"):
        text = (ROOT / f"lib/l10n/strings_{lang}.dart").read_text()
        have[lang] = set(unquote(m) for m in re.findall(r"^\s*(" + LIT + r")\s*:", text, re.M))
    for lang in ("bn", "hi"):
        missing = [k for k in keys if k not in have[lang]]
        print(f"{lang}: {len(missing)} missing")
        for k in missing:
            print("   ", json.dumps(k, ensure_ascii=False))
else:
    print(json.dumps(keys, ensure_ascii=False, indent=0))
    print(len(keys), file=sys.stderr)
