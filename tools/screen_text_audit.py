#!/usr/bin/env python3
"""Screen text audit (rule 5 escape, 2026-11-02: the jigsaw size picker said "How many pieces?" on screen only).

She is 6. Anything on a child-facing screen that tells her what to do must also be SPOKEN, and its words must
not read like a question the screen isn't asking (a size picker titled "How many pieces?" looks like counting).
narration_audit.py only sees content.json, so text typed straight into a Swift view was never checked.

This scans every Text("...") literal in the child-facing views and fails when one is:
  - an instruction or question (ends in "?" or "!", or starts with a verb she must act on) with no spoken line in
    content.json carrying the same words, or
  - any other text that is neither spoken nor listed in LABELS below with the reason a non-reader is fine without it.

    python3 tools/screen_text_audit.py        (exit 1 on any FAIL; runs in the cloud, no Mac needed)

A new on-screen word on a child screen needs either a spoken line or a LABELS entry reviewed by the kid's-eye
reviewer, who asks: "If I couldn't read this, would I still know what to do?"
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCES = ROOT / "App" / "Sources"
CONTENT = ROOT / "Sources" / "KingdomCore" / "Resources" / "content.json"
# Grown-up screens: read by an adult, exempt.
GROWN_UP_FILES = {"ParentViews.swift", "SetupView.swift", "ParentGate.swift"}

# Titles and labels a non-reader can do without, each with the reason (kid's-eye reviewed 2026-11-02).
LABELS = {
    "Home School": "app title; the hello is spoken and the tiles are pictures",
    "Kingdom of Numbers": "title over the castle; the castle line is spoken",
    "The Kingdom": "map title; places are pictures",
    "z z z": "the sleeping companion's snore, a picture not a word",
    "Cup shuffle": "title; cup.intro is spoken",
    "Cups": "label over cup pictures (3 or 5 drawn cups)",
    "Speed": "label over 1-3 speed cards; the suggested one glows",
    "Jigsaw": "title; the map is pictures with ticks",
    "Memory": "title; memory.intro is spoken the first time and the ear replays it",
    "Easy": "group label over picture cards; always open",
    "Medium": "group label; while closed it shows a padlock and a tap says what opens it",
    "Hard": "group label; while closed it shows a padlock and a tap says what opens it",
    "Make a puzzle": "button with a picture; the companion asks for the puzzle aloud",
    "Puzzle scrolls": "label over scroll icons",
    "Done": "button with a tick; sheet.drawIt tells her to tap done",
    "Scroll finished!": "end card; the companion's spoken praise covers it",
    "Back to the Puzzle Board": "button with the lantern icon",
    "Write it down": "title; the write-it-down lines are spoken",
    "Finish a place on the map to get puzzles here.": "empty board; reached only before the board unlocks",
}
VERBS = ("pick", "tap", "choose", "drag", "find", "write", "draw", "make", "watch", "look", "count", "how many",
         "which", "where", "what")


def norm(t: str) -> str:
    return re.sub(r"[^a-z0-9 ]", "", t.lower()).strip()


def main() -> int:
    lines = json.loads(CONTENT.read_text())["lines"]
    spoken = [norm(v["text"]) for v in lines.values()]
    fails, checked = [], 0
    for f in sorted(SOURCES.glob("*.swift")):
        if f.name in GROWN_UP_FILES:
            continue
        for n, line in enumerate(f.read_text().splitlines(), 1):
            for t in re.findall(r'Text\("((?:[^"\\]|\\.)*)"\)', line):
                if "\\(" in t or not re.search(r"[A-Za-z]{2}", t):
                    continue  # interpolated numbers and symbols are pictures of maths, not instructions
                checked += 1
                is_spoken = any(norm(t) and norm(t) in s for s in spoken)
                instruction = t.rstrip().endswith(("?", "!")) or norm(t).startswith(VERBS)
                where = f"{f.relative_to(ROOT)}:{n}"
                if instruction and not is_spoken and t not in LABELS:
                    fails.append(f"FAIL {where}: on-screen instruction {t!r} is never spoken")
                elif not is_spoken and t not in LABELS:
                    fails.append(f"FAIL {where}: {t!r} is neither spoken nor a reviewed label (add it to LABELS)")
                elif norm(t).startswith("how many") and "count" not in where.lower():
                    print(f"WARN {where}: {t!r} reads as a counting question; is counting the task here?")
    for x in fails:
        print(x)
    print(f"\n{len(fails)} fail, {checked} on-screen texts on child screens")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
