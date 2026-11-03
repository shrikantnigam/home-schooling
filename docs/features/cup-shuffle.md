# Feature brief: cup shuffle widget

Issue #27 under the Home School hub (#30). Asked for by Shrikant on 2026-11-02: 3 or 5 cups, speed 1 to 3, a small
bird under the cup that chirps when she finds it, and a tutorial that shows only the first time. Charter AC-H6 to
AC-H8 apply.

**Skill trained.** Attention: keeping her eyes on one moving thing among look-alikes (visual tracking), and holding
it in mind until the cups stop. There is no number variation for now (AC-H6 makes it optional); the draft's
"counters under the cups" idea stays in #27 as a possible later variation.

## How it plays

- **C1 Choose.** The widget opens on a paper table with two choices: **3 cups or 5 cups**, and **speed 1, 2 or 3**.
  Her last choice is remembered. The first time, it is 3 cups at speed 1.
- **C2 Hide.** A small paper bird hops under one cup. The cup lifts so she sees it, then comes down.
- **C3 Shuffle.** Pairs of cups swap places, sliding past each other in arcs, so she can follow one cup.

  | | Speed 1 | Speed 2 | Speed 3 |
  |---|---|---|---|
  | 3 cups | 3 swaps, 0.9 s each | 5 swaps, 0.6 s | 7 swaps, 0.4 s |
  | 5 cups | 5 swaps, 0.9 s | 7 swaps, 0.6 s | 9 swaps, 0.4 s |

  The bird's cup moves in at least half the swaps, so watching it always matters.
- **C4 Find.** When the cups stop she taps one. If the bird is there, the cup lifts, the bird flutters and **chirps**.
  That chirp is the reward. An "Again" button starts a new round with the same cups and speed.
- **C5 Miss.** The cup she tapped lifts to show it's empty, then the bird's cup lifts and the bird chirps from there.
  The companion says one short line ("Here it is! Keep your eyes on its cup."). Nothing is marked wrong and there
  is no second guess, so the next round is a fresh try.
- **C6 Quiet.** Apart from the tutorial and the miss line, the game is silent except for the chirp. The ear button
  repeats the one-line intro.
- **C7 Tutorial (AC-H8).** The first time the widget opens: three cups, the bird hides, and its cup has a glowing
  outline during **one** slow swap. A hand points at the cup when they stop. A wrong tap only wobbles that cup, and
  the hand points again, so she can't fail it. Three lines guide it ("A little bird is hiding under a cup." "Watch
  its cup move." "Tap the cup with the bird!"). Then "Now you try!" opens the choices. It never shows again unless
  a grown-up asks for it.
- **C8 No extrinsic rewards.** No timers, points, streaks or stickers on screen.
- **C9 Gentle suggestion.** After 3 finds in a row at one setting, the next faster speed (then 5 cups) wears a small
  sun ring. After 2 misses in a row, the slower setting does. She still chooses.

## Grown-ups (C10)

A "Cup shuffle" page in the grown-ups' area shows the last ten rounds (found or not, cups and speed), how often she
finds the bird at each setting she has played, a "Show the tutorial again" button, and one try-at-home idea.

## QA

`App/QATests/CupsQATests.swift` (suite Cups): the tutorial on first open, then never again; 3 cups at
speed 1 found; 5 cups at speed 3 with a miss and the reveal; the chirp on a find; the suggestion ring; the
grown-ups' page, including "Show the tutorial again".
