# Hub and jigsaw retro: Home School becomes a hub of widgets

Date: 2026-11-02 · Formula: `feature` (brief: [docs/features/jigsaw.md](../features/jigsaw.md)) ·
Charter v1.5 → v1.6 · Issues: #30 (parent), #28, #25, steps #33 and #34 · PR #31 ·
Result: the pack gains eight rules (listed at the end)

**What was built.**

1. **Home School hub** (#30, #28, AC-H1 to H6). The app opens on a home screen of widget tiles. Kingdom of Numbers
   is one tile and the jigsaw is the second. A house button in the corner of every widget goes back home. One
   daily limit covers the whole app.
2. **Jigsaw widget** (#25, rules J1 to J12). Picture puzzles from 10 to 50 pieces. The first is a 10-piece quick
   check that sets her size. A wrong drop wobbles back. The hint ladder goes strategy, then area, then outline,
   then slides the piece home. She gets one "why does it fit?" moment halfway, and from the second puzzle the
   companion puts a piece in the wrong place for her to catch. A 1-to-10 number-line puzzle with dots ties it
   to counting.
3. **Grown-ups' jigsaw page.** How she plays (first-fit rate, level, strategies), the range of sizes, and an idea
   to try at home.
4. **Debug "Jump to" page** (Shrikant's ask). In Debug builds only, the grown-ups' area can open any scene,
   the map, the board, the jigsaw or a Write it down. Her real progress is saved first and put back by
   "End testing", or on the next launch if the app was closed mid-test.
5. **Speech hang fix** (urgent, two screens hung on her iPad). Every utterance now has a watchdog, so a screen
   that waits for speech can never wait forever.
6. **Local builds.** Builds and tests now run on Shrikant's personal Mac. GitHub Actions CI runs only by hand.

| Agent | Went well | Went wrong | Learning |
|---|---|---|---|
| PM | Shrikant's three asks (hub, jigsaw, logo) were split cleanly: the logo went to its own thread and the hub and jigsaw shipped against AC-H1 to H6 and J1 to J12. | The urgent hang report arrived mid-build and took priority over the wrap-up. CI at 25 to 30 minutes per push slowed every fix. | Urgent fixes on her iPad jump the queue. Builds move to the personal Mac; CI is manual. |
| Learning | The jigsaw trains a named skill (spatial), with a strategy taught before hints, a reason to explain, and a mistake to catch. The number line ties it back to counting. | The test expected the size picker to offer two sizes after an easy quick check; the rule says it moves up exactly one size. | A test's expectation is read from the rule (J5), not from what seems likely. |
| Child's eye | Pieces she drags stay under her finger; the companion's slip makes her the expert. | On the first build no piece could be dropped. A 6-year-old would have quit on the first try. | Any drag interaction gets a play-through that drops at least one piece, before anything else is tested. |
| UX and art | The hub tiles are large (at least 200 pt wide) and the house button sits in the same corner on every widget. | Slot outlines were invisible to accessibility, so QA could not find them. | See the dev rule on accessibility order. |
| Dev | Logic lives in KingdomCore (`Jigsaw.swift`, `JigsawCutPlan`) with unit tests; the cut plan is seeded so tests are repeatable. | Four escapes: (1) the tray removed a piece's view when a drag began, which cancelled the drag; (2) `.accessibilityElement` after `.position()` made each slot's frame the whole board; (3) `countOnFrom` indexed an empty array on the 4th hint of a picture puzzle and crashed; (4) screens waited for `didFinish` from the speech engine, which sometimes never comes, so the app hung. | A view that owns a gesture stays alive for the whole gesture. Accessibility modifiers come before `.position()`. A function that indexes by a hint step guards the kind of puzzle first. Nothing waits on a system callback without a timeout. |
| QA | Chapter 8 plays the hub, both puzzle kinds, the hint ladder, the slip, the grown-ups' page and Jump to (6 of 6 locally). A new test (chapter 1, test 13) runs with speech that never finishes and proves no screen hangs. | The Kingdom tile sometimes appeared after a 1.5 s check, so chapter 6 failed once. Two other failures (chapter 4, a simulator launch timeout) were flakes. | Waits for a screen loop until their timeout instead of checking once. The speech hang now has a test that fakes the failure, so it cannot come back unseen. |

## Sign-offs

- **PM:** signed off on AC-H1 to H6 and J1 to J12, each with a QA step or unit test.
- **Learning:** signed off on rubric rows 4 and 5 for the jigsaw. Open item for the real-iPad check: does she use
  the strategy hint before the area hint?
- **QA:** signed off on the local run: 133 unit tests and chapter 8 (6 of 6). The full chapter run on the Mac is
  due before the merge.

## Deferred (each has an owner)

- The AVAudioBuffer `mDataByteSize (0)` log line. It is Apple's own noise and harmless now that nothing waits on
  speech; no change planned (owner: dev).
- Make-your-own puzzle (#32), memory (#26) and cup shuffle (#27) widgets (owner: PM, waiting on Shrikant's go).
- The logo (#29), awaiting Shrikant's pick (owner: PM, in its own thread).

## Changes to the pack

1. **dev:** a view that owns a gesture is never removed while the gesture runs; move it instead.
2. **dev:** accessibility modifiers come before `.position()` and `.offset()`.
3. **dev:** nothing waits on a system callback (speech, audio, animation completion) without a watchdog timeout.
4. **dev:** code that indexes by a step or a value guards the kind of input first; the guard gets a unit test.
5. **dev:** builds and tests run on the personal Mac through Remote Control; CI is manual only (see
   `.github/workflows/ci.yml`).
6. **qa:** every system callback the app waits on has a QA flag that fakes its failure (like
   `-speechNeverFinishes`), with a test that walks the main path under it.
7. **qa:** a wait for a screen loops until its timeout; it never checks once.
8. **kid-eye:** a drag interaction's first play-through drops at least one piece in the right place.
