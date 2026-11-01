# Chapter 1 retro: Prologue (Counting Stars) and The Flower Garden

Date: 2026-11-01 · Process used: [chapter-process.md](../chapter-process.md) v0 · Result: process v1

The retro asks each role one question: does the built chapter do what the brief asked?
Each role signs off, signs off with follow-ups, or blocks. Learnings change the process.

## What was built

- 9 scenes (P1 to P4, G1 to G5), 57 core items, 8 skills and 114 spoken lines, all in `content.json`.
- 9 activity kinds, each with concrete, pictorial and abstract views.
- Mastery, progression, warm-ups, practice scenes, time limit, quiet hours and the parent gate in `KingdomCore`, with 61 unit tests.
- Castle, map, scene player, sleeping screen, parent gate and parent area in SwiftUI, with placeholder shape art.
- 9 QA play-through tests in the iPad simulator, with 213 screenshots per run.

## QA review: signed off with follow-ups

| Run | Result | Findings |
|---|---|---|
| 1 | 2 of 9 passed | Numeral tiles and seeds had no reachable identifiers, because an identifier on a container hid its children. That would also have broken VoiceOver. Another failure came from two "Reset" buttons on the reset dialog. |
| 2 | 9 of 9 passed | Screenshot review found that subtitles covered the answer tiles (04-33), that Sparkle appeared twice on number-line screens (04-44, 04-52), and that screenshots were cropped (see below). |
| 3 | 9 of 9 passed | The fixes from run 2 held. The screenshots were still cropped: the test captured the app element, which comes out rotated and cut off in landscape. Now fixed to capture the whole screen. |

Checked against the mocks: castle (one glowing action, quiet lock), story panels, P1 one-to-one star counting
with counted stars staying lit, P2 numeral tiles with dots and the "heard it" ring, the P3 stone line, P4 quick look
and cloud, the G1 flower box with the full hint ladder (03-08 to 03-10: box glows, count on, answer shown, no red),
G2 bond circles with found pairs collected, G3 horseshoes and hop arcs, G4 make ten with the fountain,
G5 equation with flower-box and hopping-path help, the sleeping screen, the two-step parent gate, and the parent area.

Not covered by the simulator: real audio and the two voices, the drag gesture (QA taps seeds; the drag path was
only checked by reading the code), the two-finger hold (unit tested), VoiceOver, speed on a real iPad (AC-Q3 and AC-Q4).
These go on Shrikant's real-iPad checklist.

## Product manager review: signed off with follow-ups

- Scope delivered: every MVP scene, the parent area and the time limits. ACs A1 to A8, S1 to S6, M1 to M8 and P1 to P7 are covered by unit or QA tests.
- **Deviations found at the retro** (the developer had not logged them):
  1. P2 says "drag stars into a 5-frame, then a ten-frame". It was built as tapping stars in a cloud, then choosing a numeral. Ticketed.
  2. Music and sound effects (spec sections 7 and 8, AC-Q6 ducking) are not built. Only speech plays. Ticketed: needs bundled audio files.
  3. The Fredoka and Nunito fonts are not bundled. The system rounded font is used instead. Ticketed.
- Follow-up: the chapter gate (below) needs Shrikant's call.

## Child learning expert review: signed off with follow-ups

- The CPA ladder works as designed: P1 moves counting from objects to pictures after 4 of 5 (01-11), and items drop back after 3 misses (unit tested).
- The hint ladder matches the spec, and praise names what she did ("You made ten by adding 3!").
- **Dose problem.** The spec's mastery rule needs about 18 items per skill: 4 to move up from objects, 4 more to move up from pictures, then 10 at numbers over 2 days. The Prologue has 6 or 7 items per skill. With practice scenes of 8 items spread over 4 skills, she would need about 6 practice sessions before the Garden opens. That risks the "finite, kind" feel the spec wants. **Recommendation:** open the next chapter when every skill has reached Numbers with 4 of its last 5 right, across 2 days. Keep the 80%-of-10 rule as the "Mastered" badge in the parent area, which warm-ups keep building. This is Shrikant's call.
- G2 asks for the second bed given the first, instead of letting her find every split herself. The found pairs row shows the pattern, so this is acceptable for now. Ticketed as a richer G2.
- Minor: numerals show their dots the first time per scene, not per chapter. Acceptable.

## Learnings and process changes (now in process v1)

1. **Accessibility identifiers are part of "done".** Run 1 failed because tappable things were unreachable. v1 adds this to the developer definition of done.
2. **Log deviations when they happen.** PM found 3 deviations at the retro. v1 adds a deviation log to each chapter file, filled in during the build.
3. **Dose check before building.** The mastery volume problem was only found at the retro. v1 adds a dose check to the pedagogy stage.
4. **The QA harness is part of each activity kind.** v1 adds QA solver support for every new kind, driven by a `steps=` description the app exposes in UI-test builds.
5. **Screenshot pipeline.** Rotate to landscape before launch, capture the whole screen, and print the screenshots to the job log, because artifact downloads are blocked from the cloud session.
6. **Design for later chapters** uses layout notes on shared components, with mock boards only for new components. This keeps the chapters consistent and saves a design pass per scene.
