# Chapter 2 retro: The Bridge of Tens

Date: 2026-11-01 · Process used: [chapter-process.md](../chapter-process.md) v1 · Result: process v2

## What was built

5 scenes (B1 to B5), 4 skills (`tensOnes`, `line20`, `bridgeAdd`, `hop20`), new kinds `tensOnes` and `bridgeAdd`,
the 0 to 20 stone line, plank bundles and the double ten-frame. 2 QA play-through tests.

## QA review: signed off

| Run | Result | Findings |
|---|---|---|
| 1 (3211d44) | 2 of 2 passed | Screenshots were not printed: the print script only matched Chapter 1 names. Fixed (`cN-` prefix). |
| 2 (54efb6b) | 2 of 2 passed, 100 screenshots | c2-02-30: the find-on-line target number was white on the pale sky and hard to read. Fixed (number on a card). |
| 3 (f86380c) | 2 of 2 passed | Fix verified: the target number sits on a card (c2-02-30). |

Checked: AC-2a (bundle of ten plus loose planks, "ten and N more", c2-02-06, c2-02-17), AC-2b (the first box
fills to ten before the second, c2-02-52, c2-02-55 hint "how many more fill it to ten?"), AC-2c (0 to 20 line,
c2-02-30), AC-2d (bridge locked when the Garden scenes are done but its skills are not secure, c2-01-01).

## PM review: signed off with follow-ups

- Scope delivered. AC-2d was written against full mastery; it now follows the chapter gate (default: secure). The
  brief is updated by this note; the gate decision is still with Shrikant.
- D2-1 (54 pt stones on the 0 to 20 line) stays ticketed for the illustrated line.

## Child learning expert review: signed off with follow-ups

- Bundles make "ten and some more" visible, and bridge-add makes ten first, as the brief asked.
- Teen numeral tiles carry many dots (c2-02-17). They are still readable, but at 15 and above the dots stop helping.
  Follow-up: show dots as a ten-bar plus ones for teens.
- **Dose:** about 6 items per skill per scene against roughly 18 for full mastery. This is why the lighter
  "secure" gate was proposed (decision with Shrikant).

## Learnings (in process v2)

1. The dose check uses the chapter gate in use, not full mastery.
2. Screenshot names carry the chapter prefix so the print script finds them.
3. Check every on-screen number against both day and night skies.
