#!/usr/bin/env python3
"""Narration audit over content.json (team operating model, checklist 5A).

Builds the transcript a child hears in every scene on the happy path, at each CPA level, and checks the
narration rules that can be checked from content alone. It needs no Mac, so it runs in any cloud session:

    python3 tools/narration_audit.py [path/to/content.json]

Rules that depend on what happens at run time (an intro once per launch, every voice audible) need the
app's speech log from a QA run on a simulator.

Exit code 1 if any FAIL. WARN lines go to the story and voice director for review.
"""
import json
import re
import sys
from collections import Counter

PATH = sys.argv[1] if len(sys.argv) > 1 else "Sources/KingdomCore/Resources/content.json"
LEVELS = ["concrete", "pictorial", "abstract"]
HERO = "Siara"
NAME_ALLOWED = {"castle.first", "castle.back"}
TEACHING_RULES = [r"last number (you say )?tells how many", r"bottom number of a fraction"]
SENTENCE_MAX = 12        # words per sentence
TURN_MAX = 25            # words she hears before she can act on an item
INSTRUCTION_REPEAT_MAX = 2  # the same how-to sentence, in full, per scene
# Words to check with the child learning expert for a kindergartner who doesn't read yet.
HARD_WORDS = ["altogether", "scattered", "shallow", "span", "fraction", "denominator", "numerator",
              "subtract", "divide", "multiply", "amount", "partner"]
PLACE_WORDS = {"garden": ["garden", "flower", "seed", "bee", "fountain"],
               "prologue": ["star", "sky"], "bridge": ["bridge", "plank", "river"],
               "goblin": ["gem", "grub", "cave"], "ball": ["guest", "chair", "ball", "dance"],
               "feast": ["plate", "cupcake", "treat", "basket", "berry"], "moon": ["moon", "crystal"]}
SHARED_PREFIXES = ("practice.", "map.practice", "warmup.", "core.", "wrapup", "reveal", "tryAgain")

content = json.load(open(PATH))
L = content["lines"]
fails, warns = [], []


def text(lid, item=None):
    if lid not in L:
        return None
    t = L[lid]["text"]
    if item:
        for k in ("a", "b"):
            t = t.replace("{%s}" % k, str(item.get(k, 0)))
        t = t.replace("{answer}", "N")
    return t


def most_specific(base, kind, level):
    for lid in (f"{base}.{kind}.{level}", f"{base}.{kind}", base):
        if lid in L:
            return lid
    return None


def sentences(t):
    return [s.strip() for s in re.split(r"(?<=[.!?])\s+", t) if s.strip()]


def words(t):
    return len(re.sub(r"\{.*?\}", "x", t).split())


# Line-level rules
for lid, line in L.items():
    t = line["text"]
    if HERO in t and lid not in NAME_ALLOWED:
        fails.append(f"name     {lid}: '{HERO}' outside the launch welcome")
    for s in sentences(t):
        if words(s) > SENTENCE_MAX:
            warns.append(f"long     {lid}: {words(s)} words in one sentence: {s}")
    for w in HARD_WORDS:
        if re.search(r"\b" + w, t, re.I):
            warns.append(f"word     {lid}: '{w}' (check with the learning expert)")
    if lid.startswith(SHARED_PREFIXES):
        own = lid.rsplit(".", 1)[-1]  # practice.payoff.garden belongs to the garden
        for place, ws in PLACE_WORDS.items():
            if place == own:
                continue
            hit = [w for w in ws if re.search(r"\b" + w, t, re.I)]
            if hit:
                fails.append(f"place    {lid}: shared by every chapter but names {place} ({', '.join(hit)})")

# Scene transcripts
general_praise = sorted(k for k in L if re.fullmatch(r"praise\.\d+", k))
for sc in content["scenes"]:
    for level in LEVELS:
        heard = []  # (role, text)
        heard += [("open", text(o)) for o in sc["open"]]
        taught, variant, asked = set(), 0, Counter()
        for it in sc["items"]:
            kind = it["kind"]
            lv = "abstract" if sc.get("challenge") or kind in ("equation", "subtraction", "multiply", "divide") else level
            pid = next((i for i in (f"prompt.{kind}.{lv}", f"prompt.{kind}") if i in L), None)
            if not pid:
                fails.append(f"missing  {sc['id']}/{level}: no prompt for {kind}")
                continue
            # Like the app: the full how-to twice per scene, then the short form (item 8).
            if asked[(kind, lv)] >= 2:
                pid = next((i for i in (f"prompt.{kind}.{lv}.short", f"prompt.{kind}.short") if i in L), pid)
            asked[(kind, lv)] += 1
            if kind == "quickLook":
                # Quick look says "Ready? Look quickly!", shows the stars, then asks (item 14).
                pid = "quickLook.ready"
                heard.append(("prompt", text(pid, it)))
                aid = "ask.quickLook.short" if asked[("ask", kind)] >= 2 and "ask.quickLook.short" in L else "ask.quickLook"
                asked[("ask", kind)] += 1
                heard.append(("ask", text(aid, it)))
                variant += 1
                heard.append(("praise", text(general_praise[variant % len(general_praise)], it)))
                continue
            prompt = text(pid, it)
            if words(prompt) > TURN_MAX:
                warns.append(f"turn     {sc['id']}/{level}: {words(prompt)} words before she can act ({pid})")
            heard.append(("prompt", prompt))
            if lv == "concrete" and f"ask.{kind}" in L:
                aid = f"ask.{kind}.short" if asked[("ask", kind)] >= 2 and f"ask.{kind}.short" in L else f"ask.{kind}"
                asked[("ask", kind)] += 1
                ask = text(aid, it)
                heard.append(("ask", ask))
                if prompt.rstrip().endswith("?") or re.search(r"\?", prompt):
                    q1 = [s for s in sentences(prompt) if s.endswith("?")]
                    if q1:
                        warns.append(f"twice    {sc['id']}/{level}: asks the question in the prompt and again after the step "
                                     f"({q1[-1]} / {ask})")
            variant += 1
            praise = most_specific("praise", kind, level)
            if praise and praise != "praise" and kind not in taught:
                taught.add(kind)
                heard.append(("praise", text(praise, it)))
            elif general_praise:
                heard.append(("praise", text(general_praise[variant % len(general_praise)], it)))
        heard += [("payoff", text(p)) for p in sc["payoff"]]
        heard.append(("goodbye", text(sc["goodbye"])))
        heard = [(r, t) for r, t in heard if t]

        for rule in TEACHING_RULES:
            n = sum(1 for _, t in heard if re.search(rule, t, re.I))
            if n > 1:
                fails.append(f"teach    {sc['id']}/{level}: '{rule}' spoken {n} times (max 1 per scene)")
        instr = Counter(s for r, t in heard if r in ("prompt", "ask") for s in sentences(t) if words(s) > 3)
        for s, n in instr.items():
            if n > INSTRUCTION_REPEAT_MAX:
                fails.append(f"repeat   {sc['id']}/{level}: '{s}' said {n} times in one scene "
                             f"(max {INSTRUCTION_REPEAT_MAX} in full, then a short form)")

# One finding per line and rule is enough across levels.
def dedupe(xs):
    seen, out = set(), []
    for x in xs:
        key = re.sub(r"/(concrete|pictorial|abstract)", "", x)
        if key not in seen:
            seen.add(key)
            out.append(x)
    return out

fails, warns = dedupe(fails), dedupe(warns)
for f in fails:
    print("FAIL", f)
for w in warns:
    print("WARN", w)
print(f"\n{len(fails)} fail, {len(warns)} warn, {len(L)} lines, {len(content['scenes'])} scenes")
sys.exit(1 if fails else 0)
