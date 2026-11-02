# Batch 3A retro: the problem-solving bridge

Date: 2026-11-02 · Formula: `feature` (brief: [docs/features/problem-solving.md](../features/problem-solving.md)) ·
Charter v1.4 → v1.5 · Result: the pack gains eight rules (listed at the end)

**What was built.** The bridge from story play to problem solving that the learning expert proposed and Shrikant
approved on 2026-11-02:

1. **Write it down** (F1, L11, L16). The first time she finishes a place, she builds that place's number sentence
   from tiles. The "=" is a paper balance that tips while a side is empty and levels when both sides are filled.
   The second sentence starts with the answer (`10 = 6 + 4`). A wrong tile wobbles and the companion gives a hint;
   nothing is marked wrong.
2. **Puzzle scrolls** (F2, F4) on the iPad, with no printer. Each finished place has a scroll: two picture-first
   items, two sentences, a missing number, an answer-first item, "draw it" and "make a puzzle". She writes with her
   finger or Pencil and Vision reads it on the device; number keys are the fallback. She gets one retry, then the
   app shows the answer. There are no stars and no score. Mixed scrolls draw on her weak signs.
3. **The Puzzle Board** (F3, L14, L15) in the castle. She picks the sign first, then a helper (counters, number
   line, in my head), then the answer. The story fades over three levels: spoken with a picture, then words only,
   then a bare sentence where she picks only the sign. Each solve lights a lantern. She makes puzzles for the
   companion, who slips on every third puzzle for her to catch.
4. **Grown-ups' area.** A "Puzzle scrolls" tab where a grown-up taps Easy, OK or Hard for each finished scroll.
   Hard brings that place's skills back into the warm-ups and Easy lets them rest. The tab also shows the board's
   level and lanterns for each sign.

| Agent | Went well | Went wrong | Learning |
|---|---|---|---|
| PM | All five approved parts shipped against ACs W1–W5, S1–S5, B1–B7 and M1–M2. Each AC has a QA step or a unit test. | AC-B1 said the board opens after "the first operation place". That meant the board stayed hidden after the Prologue even though its scroll was ready. | Changed AC-B1: the board opens after the Prologue and shows only scrolls until a sign is taught. If a reading of an AC changes during the build, the brief changes in the same commit. |
| Learning | She chooses the operation before the answer (L14), helpers are her choice, and the fade is earned: 3 first-try solves go up a level, 2 misses go down. Weak spots feed the mixed scrolls. | Screenshot c7-02-13: after she caught the companion's slip, the box still showed the wrong answer, 11. Screenshot c7-03-10: the sequence "5 6 ?" read as fifty-six. | A wrong answer never stays on screen once it has been judged; the box shows the true one. A counting sequence shows commas between its numbers. |
| Story | Board stories reuse each place's world: garden flowers, Grub's gems, ball guests, feast cupcakes. | Story lines needed two numbers that don't come from a scene item, and the catalog could only fill `{n}`. | Added `LineCatalog.spoken(_:a:b:)` with a unit test. Any new placeholder gets a catalog overload and a test in the same change. |
| Child's eye | Lanterns are a reward she can see that isn't a score. Making puzzles for the companion turns her into the teacher. | Vision can't be tested on her handwriting in the simulator, so pen reading is unproven. | Real-iPad check: does she write or tap, and does the app read her 4, 7 and 9? Added to the feel check. |
| UX and art | The balance, the board and the scroll each look like paper. Nothing important sits in the top 100 pt. | Scrolls inherited the Prologue's night stage, so the steppers and "Scroll finished!" in dark ink disappeared (c7-03-18, c7-03-20). The selected Easy/OK/Hard button was only a tint, too faint to see (c7-03-21). | Screens with dark ink sit on day paper. A selected state changes fill, not just tint. |
| Dev | Logic lives in KingdomCore with 14 new unit tests. The app reads it through four small `AppModel` calls. | Two compile breaks only CI caught: a `func` declared inside a `GeometryReader` closure (not allowed in a view builder), and Path math the type checker gave up on. | Drawing math goes in helper functions that return a `Path`, with explicit `CGFloat` types, never inline in a view builder. |
| QA | Chapter 7 plays all three new flows through the UI: write it down, the board up to level 3 plus two made puzzles, and a full scroll plus parent feedback. Chapters 1 to 6 still pass. | The test read sentence 1's state after QA speech had already moved on to sentence 2, so it failed on a state that had passed. New end-of-place screens would have broken every earlier chapter test. | Never assert on a state the app moves past by itself; check it only if it is still there. A new screen inside an existing path is handled once in `QAPlayer`, not in each test. |

## Sign-offs

- **PM:** signed off once CI is green on the PR head. AC-B1 is reworded in the brief.
- **Learning:** signed off on rubric rows 4 and 5 for the three new flows. Two open items go to the real-iPad
  check: whether she uses the helpers, and pen reading.
- **QA:** signed off on CI green for the PR head (unit tests and seven play-throughs), with the c7 screenshots
  reviewed.

## Deferred (each has an owner)

- Pen reading on her real handwriting, and keys as the fallback if it misreads often (owner: dev, kid-eye; needs
  her iPad).
- Voice items from the change list. These are batched and not built yet (owner: PM, waiting on Shrikant's go).

## Changes to the pack

1. **dev:** drawing math lives in helper functions that return a `Path`, with explicit types. No declarations
   inside view-builder closures.
2. **dev / story:** a new line placeholder gets a catalog overload and a unit test in the same change.
3. **qa:** don't assert on a state the app moves past by itself. A new screen inside an existing path is stepped
   through once, in `QAPlayer`.
4. **ux-art:** screens with dark ink sit on day paper. Selected states change fill, not just tint.
5. **learning:** once a wrong answer has been judged it never stays on screen. Number sequences show commas.
6. **pm:** a changed reading of an AC is written into the brief in the same commit.
7. **kid-eye:** the feel check adds the pen (writes or taps, and is she read right?) and the board's helpers (does
   she use them?).
8. **charter v1.5:** L14 to L16 and the Puzzle Board exception to S6 (already merged into the charter at the start
   of this batch).
