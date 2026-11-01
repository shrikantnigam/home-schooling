# Chapter 6 retro: The Moon Crystal

Date: 2026-11-01 · Process used: v2 draft · Result: process v2 adds one rule

## What was built

4 scenes (M1 to M4), 3 skills (`equalParts`, `fractionOfSet`, `fractionLine`), new kinds `parts`, `fractionOf`,
`fractionLine`, the crystal, the moonbeam line with fraction labels and `FractionText`. 1 QA play-through test.

## QA review: signed off after fixes

| Run | Result | Findings |
|---|---|---|
| 1 (54efb6b) | 1 of 1 passed first time, 85 screenshots | **Blocker, c6-01-74:** a fraction-of-a-set item at the Numbers level showed "14 + 2". **Blocker, c6-01-17:** the crystal was cut with vertical slices, which are not equal parts of a circle (AC-6a). Both fixed: "½ of 14", and pie wedges. Praise for equal parts said "one 4th"; reworded. |
| 2 (f86380c) | 1 of 1 passed | Fixes verified: equal pie-wedge parts, counted clockwise (c6-01-06, c6-01-10, c6-01-17), "½ of 14" (c6-01-74), new praise wording. Minor: help piles for 14 gems overflow their ovals (c6-01-75); ticketed. |

Checked: AC-6b (gems shared into equal piles, c6-01-32), AC-6c (moonbeam with `b` steps and fraction labels,
c6-01-47 to c6-01-59), AC-6d (stacked fractions), the final payoff and the map with every place lit (c6-01-85).

## PM review: signed off

- The story ends with the whole kingdom saved (c6-01-83).

## Child learning expert review: signed off

- Equal parts must look equal. The wedge fix matters more than any other in this chapter: unequal "halves"
  teach the wrong idea.
- The moonbeam line is a stretch for kindergarten; it is fine as the last new idea, with practice scenes as needed.

## Learnings (in process v2)

1. Every new kind needs a Numbers-level display reviewed on its own. The generic equation fallback showed a `+`
   for a kind with no operator. v2's definition of done adds: "check the Numbers-level screenshot of every new kind".
