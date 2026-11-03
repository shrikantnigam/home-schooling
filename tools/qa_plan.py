#!/usr/bin/env python3
"""Pick which QA play-through suites a change needs (Shrikant, 2026-11-02: "only the screens that change").

Usage:  python3 tools/qa_plan.py [--full] [BASE]   (BASE defaults to the last commit the play-throughs passed
                                                    on, read from .qa-last-pass if present, else origin/main)
Prints suites as a comma list, e.g. "Kingdom7,HubJigsaw", or "none" when only docs changed.

Suites (App/QATests/<name>QATests.swift), named for what they cover (Shrikant, 2026-11-03):
  Kingdom1      launch, first-launch setup, PIN and parent dashboard, Prologue and the Flower Garden
  Kingdom2..6   the Bridge, the Goblin, the Ball, the Feast, the Moon (every scene of the place)
  Kingdom7      problem solving: write it down, the puzzle board, scrolls
  HubJigsaw     the Home School hub and the jigsaw
  Cups          cup shuffle
  Memory        the memory game
  KingdomSmoke  one short scene from each place after the Garden (the quick check)

While building (the default), a change to shared code (speech, the app model, saved progress...) runs the quick
set: Kingdom1, KingdomSmoke and the write-it-down test, plus the suites of any widget files changed. That is about
20 minutes instead of 75. --full (and `tools/qa_run.sh all`, always before a merge to main) runs every suite in full.
Anything not listed in RULES is shared: a missed suite costs an escaped bug, an extra one only costs minutes.
"""
import subprocess
import sys
from fnmatch import fnmatch
from pathlib import Path

ALL = ["Kingdom1", "Kingdom2", "Kingdom3", "Kingdom4", "Kingdom5", "Kingdom6", "Kingdom7", "HubJigsaw", "Cups",
       "Memory"]
QUICK = ["Kingdom1", "KingdomSmoke", "Kingdom7/test01_WriteItDown_Garden"]

# First matching pattern wins. [] means no play-through is needed (unit tests still run).
RULES = [
    ("docs/*", []),
    ("studio/*", []),
    ("*.md", []),
    (".github/*", []),
    (".gitignore", []),
    ("tools/gen_content.py", "ALL"),                   # generates content.json, which every suite reads
    ("tools/chapters_2_to_6.py", "ALL"),
    ("tools/*", []),                                   # test and audit scripts
    ("Tests/*", []),                                   # unit tests only
    ("App/QATests/QAPlayer.swift", "ALL"),
    ("App/QATests/*QATests.swift", "own"),
    # Home School hub and jigsaw widget
    ("App/Sources/HomeView.swift", ["Kingdom1", "HubJigsaw", "Cups", "Memory"]),
    # Memory game
    ("App/Sources/MemoryView.swift", ["Memory"]),
    ("Sources/KingdomCore/Memory.swift", ["Memory"]),
    # Cup shuffle widget
    ("App/Sources/CupShuffleView.swift", ["Cups"]),
    ("App/Sources/ChirpPlayer.swift", ["Cups"]),
    ("Sources/KingdomCore/CupShuffle.swift", ["Cups"]),
    ("App/Sources/Jigsaw*.swift", ["HubJigsaw"]),
    ("Sources/KingdomCore/Jigsaw.swift", ["HubJigsaw"]),
    # Problem-solving bridge (batch 3A)
    ("App/Sources/WriteItDownView.swift", ["Kingdom7"]),
    ("App/Sources/PuzzleBoardView.swift", ["Kingdom7"]),
    ("App/Sources/WorksheetView.swift", ["Kingdom7"]),
    ("App/Sources/PenInput.swift", ["Kingdom7"]),
    ("App/Sources/ProblemArt.swift", ["Kingdom7"]),
    ("Sources/KingdomCore/Problems.swift", ["Kingdom7"]),
    ("Sources/KingdomCore/Worksheets.swift", ["Kingdom7"]),
    # Grown-ups' area and first-launch setup
    ("App/Sources/ParentViews.swift", ["Kingdom1", "Kingdom7", "HubJigsaw", "Cups", "Memory"]),
    ("Sources/KingdomCore/ParentGate.swift", ["Kingdom1", "Kingdom7", "HubJigsaw"]),
    ("App/Sources/SetupView.swift", ["Kingdom1"]),
    ("Sources/KingdomCore/Setup.swift", ["Kingdom1"]),
    ("App/Resources/*", ["Kingdom1"]),                         # app icon: the launch smoke test is enough
    ("App/Sources/MapArt.swift", ["Kingdom1", "Kingdom2", "Kingdom3", "Kingdom4", "Kingdom5", "Kingdom6"]),
    # Everything else (AppModel, SpeechPlayer, the scene player, castle, content.json, project.yml...) is shared.
]


def chapters_for(path: str) -> list:
    for pattern, chapters in RULES:
        if fnmatch(path, pattern):
            if chapters == "ALL":
                return "SHARED"
            if chapters == "own":
                return [Path(path).name[: -len("QATests.swift")]]
            return chapters
    return "SHARED"


def main() -> None:
    root = Path(__file__).resolve().parent.parent
    args = sys.argv[1:]
    full = "--full" in args
    args = [a for a in args if a != "--full"]
    base = args[0] if args else None
    if base is None:
        marker = root / ".qa-last-pass"
        base = marker.read_text().strip() if marker.exists() else "origin/main"
    changed = subprocess.run(["git", "diff", "--name-only", f"{base}...HEAD"], cwd=root,
                             capture_output=True, text=True, check=True).stdout.split()
    picked, shared = [], False
    for path in changed:
        got = chapters_for(path)
        if got == "SHARED":
            shared = True
        else:
            picked += [c for c in got if c not in picked]
    if shared:
        picked = ALL if full else QUICK + [c for c in picked if c not in QUICK and c not in ("Kingdom1",)]
    # A suite running in full already covers its single tests.
    picked = [c for c in picked if "/" not in c or c.split("/")[0] not in picked]
    order = ALL + ["KingdomSmoke"]
    picked.sort(key=lambda c: order.index(c.split("/")[0]) if c.split("/")[0] in order else len(order))
    print(",".join(picked) or "none")


if __name__ == "__main__":
    main()
