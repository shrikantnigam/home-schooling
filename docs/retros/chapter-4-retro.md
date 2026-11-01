# Chapter 4 retro: The Royal Ball

Date: 2026-11-01 · Process used: v1 plus Chapter 2 and 3 learnings · Result: process v2

## What was built

4 scenes (R1 to R4), 4 skills (`equalGroups`, `arrays`, `skipCount`, `multiply`), new kinds `groups`, `array`,
`skipHop`, `multiply`, guest counters and table circles. 1 QA play-through test.

## QA review: signed off

| Run | Result | Findings |
|---|---|---|
| 1 (54efb6b) | 1 of 1 passed first time, 87 screenshots | c4-01-16: tables were tiny and guests spilled outside them (a lazy grid collapsed inside the row). c4-01-23 and c4-01-64: pictorial guests faded (disabled buttons). Both fixed. |
| 2 (f86380c) | 1 of 1 passed | Fixes verified: guests sit inside fixed-size tables (c4-01-16), pictorial guests and chairs at full strength (c4-01-23, c4-01-64). |

Checked: AC-4a (equal groups in separate tables), AC-4b (rows count by the row size), AC-4c (each arc spans `b`
tiles, c4-01-51), AC-4d (content validation: no product over 20).

## PM review: signed off

- Scope delivered, first-time green in QA: the per-kind QA solver from v1 paid off.

## Child learning expert review: signed off with a follow-up

- The hop button shows hops left ("→ 5" counting down to "→ 0"). A 6-year-old may read 0 as the answer.
  Follow-up: show the hop count as dots that empty instead of a number.

## Learnings

1. Fixed-size containers for groups, so layout doesn't depend on lazy grids inside stacks.
2. Splitting QA per chapter (v2) kept the run at about 17 minutes for six chapters.
