# Chapter 3 retro: The Goblin's Cave

Date: 2026-11-01 · Process used: v1 (with the Chapter 2 learnings) · Result: process v2

## What was built

5 scenes (K1 to K5), 4 skills (`takeAway`, `hopBack`, `compare`, `subtract20`), new kinds `takeAway`, `hopBack`,
`compare` and `subtraction`, Grub's sack, gem counters and the shared `CounterActivity` and `LineOpsActivity` views.
2 QA play-through tests.

## QA review: signed off

| Run | Result | Findings |
|---|---|---|
| 1 (3cad6a2) | 2 of 2 passed | Screenshots not printed (same naming bug as Chapter 2). |
| 2 (54efb6b) | 2 of 2 passed, 101 screenshots | c3-01-16: "Tap 1 gems" (plural with 1). c3-01-47: the row labels were dark on the night sky and said "Goblin" instead of "Grub". c3-01-64: pictorial gems looked faded because disabled buttons dim. All fixed. |
| 3 (f86380c) | 2 of 2 passed | Fixes verified: new prompt wording (c3-01-16), light "Siara" and "Grub" labels (c3-01-47), pictorial gems at full strength (c3-01-64). |

Checked: AC-3a (taken gems stay faded and visible, c3-01-11, c3-01-23), AC-3b (rows line up, only Siara's extra gems
glow and can be tapped, c3-01-51), AC-3c (hop back from the start, c3-01-29), AC-3d (lines reviewed; no scary lines).

## PM review: signed off

- Scope delivered. D3-1 (`subtract20` is numbers-with-help only) was logged during the build, as v1 asks.

## Child learning expert review: signed off

- Take-away keeps the whole visible, which is the key idea for "how many are left".
- Comparing by matching one-to-one is the right first model for "how many more".
- **Dose bug found here:** `subtract20` is numeral-only, but every skill started at Objects, and results at a
  different level don't count toward level changes. So it could never reach Numbers or become secure, and the
  chapter could never open the next one. Fixed in the engine: a skill first met at Numbers starts there.

## Learnings (in process v2)

1. The dose check states each skill's starting level and flags numeral-only skills.
2. Use `.allowsHitTesting` rather than `.disabled` on counters that are only for looking; disabled buttons fade
   and make pictorial screens look broken.
3. Say counts with numbers in the copy carefully ("Tap 1 gems"); prompts avoid putting `{b}` before a plural noun.
