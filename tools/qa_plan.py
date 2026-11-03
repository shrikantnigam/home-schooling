#!/usr/bin/env python3
"""Pick which QA play-through chapters a change needs (Shrikant, 2026-11-02: "only the screens that change").

Usage:  python3 tools/qa_plan.py [BASE]     (BASE defaults to the last commit the play-throughs passed on,
                                             read from .qa-last-pass if present, else origin/main)
Prints the chapters as a comma list, e.g. "7,8", or "none" when only docs changed.

Each chapter's test already opens on its own place with a preset, so a chapter only needs to run when a file
on its path changed. Anything not listed below is treated as shared and runs every chapter: a missed chapter
costs an escaped bug, an extra one only costs minutes.
"""
import subprocess
import sys
from fnmatch import fnmatch
from pathlib import Path

ALL = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

# First matching pattern wins. [] means no play-through is needed (unit tests still run).
RULES = [
    ("docs/*", []),
    ("studio/*", []),
    ("*.md", []),
    (".github/*", []),
    (".gitignore", []),
    ("tools/gen_content.py", "ALL"),                   # generates content.json, which every chapter reads
    ("tools/chapters_2_to_6.py", "ALL"),
    ("tools/*", []),                                   # test and audit scripts
    ("Tests/*", []),                                   # unit tests only
    ("App/QATests/QAPlayer.swift", ALL),
    ("App/QATests/Chapter*PlaythroughTests.swift", "own"),
    # Home School hub and jigsaw widget
    ("App/Sources/HomeView.swift", [1, 8, 9, 10]),
    # Memory game
    ("App/Sources/MemoryView.swift", [10]),
    ("Sources/KingdomCore/Memory.swift", [10]),         # every chapter taps the Kingdom tile, chapter 8 tests the hub
    # Cup shuffle widget
    ("App/Sources/CupShuffleView.swift", [9]),
    ("App/Sources/ChirpPlayer.swift", [9]),
    ("Sources/KingdomCore/CupShuffle.swift", [9]),
    ("App/Sources/Jigsaw*.swift", [8]),
    ("Sources/KingdomCore/Jigsaw.swift", [8]),
    # Problem-solving bridge (batch 3A)
    ("App/Sources/WriteItDownView.swift", [7]),
    ("App/Sources/PuzzleBoardView.swift", [7]),
    ("App/Sources/WorksheetView.swift", [7]),
    ("App/Sources/PenInput.swift", [7]),
    ("App/Sources/ProblemArt.swift", [7]),
    ("Sources/KingdomCore/Problems.swift", [7]),
    ("Sources/KingdomCore/Worksheets.swift", [7]),
    # Grown-ups' area and first-launch setup
    ("App/Sources/ParentViews.swift", [1, 7, 8, 9, 10]),
    ("Sources/KingdomCore/ParentGate.swift", [1, 7, 8]),
    ("App/Sources/SetupView.swift", [1]),
    ("Sources/KingdomCore/Setup.swift", [1]),
    ("App/Resources/*", [1]),                         # app icon: the launch smoke test is enough
    ("App/Sources/MapArt.swift", [1, 2, 3, 4, 5, 6]),
    # Everything else (AppModel, SpeechPlayer, the scene player, castle, content.json, project.yml...) is shared.
]


def chapters_for(path: str) -> list:
    for pattern, chapters in RULES:
        if fnmatch(path, pattern):
            if chapters == "ALL":
                return ALL
            if chapters == "own":
                digits = "".join(c for c in Path(path).name if c.isdigit())
                return [int(digits)] if digits else ALL
            return chapters
    return ALL


def main() -> None:
    root = Path(__file__).resolve().parent.parent
    base = sys.argv[1] if len(sys.argv) > 1 else None
    if base is None:
        marker = root / ".qa-last-pass"
        base = marker.read_text().strip() if marker.exists() else "origin/main"
    changed = subprocess.run(["git", "diff", "--name-only", f"{base}...HEAD"], cwd=root,
                             capture_output=True, text=True, check=True).stdout.split()
    picked = set()
    for path in changed:
        picked.update(chapters_for(path))
    print(",".join(str(c) for c in sorted(picked)) or "none")


if __name__ == "__main__":
    main()
