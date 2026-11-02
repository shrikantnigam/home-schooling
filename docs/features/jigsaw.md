# Feature brief: jigsaw widget (first set)

Issue #25 under the Home School hub (#30). Rules J1 to J12 come from the jigsaw plan doc
(https://claude.ai/artifact/YYk7UgfufRD7j6s9XcxJR3). "Make your own puzzle" (#32) comes later.

**Skill trained.** Picture puzzles: shapes and space, and parts of a whole. Number-line puzzle: number order and
counting on (this is the widget's number variation, so it follows the whole charter).

## How it plays

- She chooses a picture puzzle or the number line. Pictures are paper-theatre scenes (castle, garden, her companion,
  ballet, karate, ball, night sky, rainbow) and never repeat back to back (J9).
- **Sizes.** Her first puzzle is a 10-piece quick check (J10). Easy (85% or more right first time, one hint at most)
  moves straight up a size until a puzzle isn't easy. After that she picks from two or three sizes around her level.
- **Ladder (J2).** One knob changes per step: 10 squares → tabs → 20 → faint guide → 30 → mixed edges → 40 →
  turning pieces → no guide → 50 → wavy cuts. Four easy puzzles in a row move up one step; a stuck puzzle (third
  hint step reached, or under half right first time) moves down one.
- **Fit (J1).** A piece fits only in its own place, the right way up. A wrong drop wobbles and stays in the tray;
  nothing is marked wrong.
- **Hints (J3).** One button, four steps for the piece she last touched: a strategy in words, the area glows, the
  outline shows, then the piece slides home. Two misses in a row make the hint button glow.
- **Explain (J4).** Halfway, the companion asks how she found that piece (colours, edge shape, the picture,
  turning; for the number line, counted on or the dots).
- **Companion slip (J5).** On every third puzzle the companion places a piece wrongly and asks "Does it fit?".
  She says no and why.
- **Quiet (J7), no extrinsic rewards (J8).** One-time intros, then silence unless she asks. No timers, points or
  stickers; the finished picture is the reward.
- **Number line (J12).** Ten pieces in a row: 1 to 10 with dots, then hops, then numerals, then counting in 2s, 5s
  and 10s.

## Grown-ups (J8, J11)

The parent area has a Jigsaw page with the lowest and highest sizes she can be offered, her level, the first-try
rate and hints over the last ten puzzles, the strategies she names, and one try-at-home idea that changes after each
puzzle.

## QA

`App/QATests/Chapter8PlaythroughTests.swift` (CI job "chapter 8"): hub, picture puzzle with a wrong drop and the
whole hint ladder, explain moment, quick check moving up, companion slip, number line, parent range.
