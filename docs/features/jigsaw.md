# Feature brief: jigsaw widget (first set)

Issue #25 under the Home School hub (#30). Rules J1 to J12 come from the jigsaw plan doc
(https://claude.ai/artifact/YYk7UgfufRD7j6s9XcxJR3). "Make your own puzzle" (#32) comes later.

**Skill trained.** Shapes and space, and parts of a whole.

**Changed 2026-11-02 (Shrikant).** The puzzle map replaces the chooser (J13), finished puzzles get a green tick
(J14), and the number-line puzzle (J12) is removed. Old saves keep their jigsaw level; any number-line results stay
in her history but no longer count.

## How it plays

- **Puzzle map (J13, charter AC-H7).** The jigsaw opens on a paper map showing all eight pictures (castle, garden,
  her companion, ballet, karate, ball, night sky, rainbow) joined by a dotted path. She picks any of them. The one
  she hasn't played for longest wears a small sun ring as a suggestion (this replaces J9's "never twice in a row").
- **Finished puzzles (J14).** A picture she has finished at least once keeps its colours and gets a green tick, with
  the most pieces she has done it in ("20 pieces"). It stays open to play again at any size. Nothing is greyed
  out, because grey reads as locked.
- **Sizes (J15, Shrikant 2026-11-02, replaces "two or three sizes around her level").** The picker, headed and
  spoken "Pick your puzzle size", always shows 10, 20 and 30. 20 and 30 are faded with a padlock until she has
  finished a 10-piece puzzle; tapping a locked one wobbles it and says "Finish a 10 piece puzzle first". Her first
  puzzle is the 10-piece quick check (J10): easy (85% or more right first time, one hint at most) moves the sun-ring
  suggestion up a size, up to 30. 40 and 50 are not offered; the ladder's later knobs (turning, no guide, wavy cuts)
  still come at 30.
- **Ladder (J2).** One knob changes per step: 10 squares → tabs → 20 → faint guide → 30 → mixed edges → 40 →
  turning pieces → no guide → 50 → wavy cuts. Four easy puzzles in a row move up one step; a stuck puzzle (third
  hint step reached, or under half right first time) moves down one.
- **Fit (J1).** A piece fits only in its own place, the right way up. A wrong drop wobbles and stays in the tray;
  nothing is marked wrong.
- **Hints (J3).** One button, four steps for the piece she last touched: a strategy in words, the area glows, the
  outline shows, then the piece slides home. Two misses in a row make the hint button glow.
- **Explain (J4).** Halfway, the companion asks how she found that piece (colours, edge shape, the picture,
  turning).
- **Companion slip (J5).** On every third puzzle the companion places a piece wrongly and asks "Does it fit?".
  She says no and why.
- **Quiet (J7), no extrinsic rewards (J8).** One-time intros, then silence unless she asks. No timers, points or
  stickers; the finished picture is the reward.

## Grown-ups (J8, J11)

The parent area has a Jigsaw page with her level (the grown-up size range was removed with J15), the first-try
rate and hints over the last ten puzzles, the strategies she names, and one try-at-home idea that changes after each
puzzle.

## QA

`App/QATests/Chapter8PlaythroughTests.swift` (chapter 8): hub, puzzle map, picture puzzle with a wrong drop and the
whole hint ladder, explain moment, the tick after finishing, quick check moving up, companion slip, parent range.
