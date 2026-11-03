# Retro: jigsaw map, cup shuffle and follow-ups (2026-11-02)

Scope: #36 (jigsaw map, ticks, number-line puzzle removed), #27 (cup shuffle), save safety (PR #35), app icon
(#29), and Shrikant's same-day follow-ups: the size picker (J15), voices, iPad signing. Escape logged as #50.

## What went well
- The map, ticks and cup shuffle shipped to the rules Shrikant set (J13, J14, C1 to C10). Chapters 8 and 9 passed
  on the simulator once the app built.
- QA tap metrics are now real numbers: 3 taps from home to the first cup guess, 2 per later round, 3 from home
  to the jigsaw size picker.
- The Mac session caught three tool problems before they could mislead anyone: a zero-test "pass", the signing
  team being wiped, and a test that expected the wrong thing.

## What went wrong, and the rule that stops it next time
1. **Pushed code that didn't compile** (duplicate `Triangle`, `CupArc` as a ViewModifier). The cloud has no
   compiler, so the Mac was the first build. *Rule (dev):* before adding a new type, grep App/Sources for its
   name. Shared shapes live in Art.swift. Animated offsets use `GeometryEffect`, like `Wobble`.
2. **A run that executed 0 tests counted as a pass.** *Fixed in qa_run.sh:* a chapter passes only when the log
   says it executed at least one test.
3. **xcodegen wiped his signing team** (`DEVELOPMENT_TEAM: ""`). *Fixed:* Signing.xcconfig includes the
   gitignored App/Local.xcconfig.
4. **"How many pieces?" (rule 5 escape, #50).** It read like a counting question and was never spoken.
   *Fixed:* `tools/screen_text_audit.py` (run by qa_run.sh), plus new rules for kid-eye, ux-art and PM: review
   every screen as a non-reader with the sound on.
5. **Voices picked once per launch.** Ava, downloaded while the app was open, was never used. *Fixed:* voices
   are re-picked when iPadOS reports a change, and grown-ups can choose one. *Rule (dev):* nothing reads a
   system list once and caches it for the whole launch without listening for its change notification.
6. **No mocks for the map or the cup table.** Screenshots stood in, so the design gate was only partly met.
   *Rule (ux-art):* a mock comes before code for every new child screen, even small ones.
7. **No explain moment in cup shuffle.** It trains attention, but the charter's "how did you know?" is
   missing. Taken to the learning expert for the next cup shuffle pass.
8. **First-try rate isn't measured from real play** (#49). Proposed: read it from her own play on the
   grown-ups' pages, not from a simulated learner.
9. **Chapter 1 test01 failed once on 5898802 with no message.** Since 8e43065, every chapter keeps its log and
   result bundle. It hasn't failed again (passed on 8e632cc and on 640686a). If it does, the bundle holds the
   cause.

## Process
- Shrikant found two problems in his own play-through (the heading, the voice). Both now have automated checks.

## Follow-up build, 2026-11-03: PIN, parent dashboard, jigsaw groups, memory game
Scope: a PIN for the parent dashboard (AC-P1a); the dashboard grouped as General plus one group per game (AC-P1b);
the jigsaw with no square-piece rung, and Easy / Medium (30) / Hard (50) groups with 8 new busier scenes (J15,
J16); the memory game with 10 characters and Easy 3-4, Medium 4-6, Hard 6-8 pairs (M1 to M10).

### What went well
- All four shipped in the order Shrikant asked, each with its unit tests and a QA suite. The memory game passed
  its suite on its first Mac run (4 of 4). Taps: 2 from home to the first card, 8 per easy game.
- The Mac run caught two things a player would notice, and both were fixed within the hour: the home caption stayed
  over the games, and the memory card backs were too dark.

### What went wrong, and the rule that stops it next time
1. **The busy jigsaw scenes didn't type-check in time** (09e6cfa). *Rule (dev):* in art files, every expression
   that mixes CGFloat maths and colours goes into a typed `let`, with at most about five operations each. Split
   any shape longer than that into helper functions.
2. **A test run silently skipped a test** (5 of 6 ran under load and counted as a pass). *Fixed:* qa_run.sh
   compares the executed count with the suite's `func test` count.
3. **The caption stayed over the next screen.** `SpeechPlayer.stop()` cleared the voice but not the caption.
   *Rule (dev):* stopping something clears everything it shows. *Rule (kid-eye):* check every new screen for text
   left over from the screen before.
4. **The memory card backs had low contrast** (an unlit star on dark brown). *Rule (ux-art):* the back of any card
   or tile must stand out against the table at a glance. Check it in a screenshot before sign-off.
5. **No mocks again** for the memory board, the jigsaw group bands or the PIN pad. This is the same gap as item 6
   above. *Rule (PM):* for each new child screen, the build doesn't start until a mock or a sketch is posted,
   even if Shrikant has already described it in words.
6. **Test time.** Every shared change replayed all of Kingdom (about 75 min). Shrikant asked why we test chapters
   we didn't change. *Changed with his agreement:* suites are named for what they cover (Kingdom1 to 7,
   HubJigsaw, Cups, Memory). While building, a shared change runs a quick set of about 21 min (Kingdom1,
   KingdomSmoke, write it down, plus the games changed). The full run happens only before a merge.
7. **Workflow question.** Shrikant asked why he kept needing `git pull`. *Decided:* code is still written in the
   cloud. The Mac session keeps his folder on the branch while a PR is open, and moves it to `main` after every
   merge (release formula step `sync-mac`).

### Still open
- Neither cup shuffle nor memory has an explain moment ("how did you remember?"). This goes to the learning
  expert.
- Medium memory starts at 4 pairs (8 cards) and grows to 6 as she does well. Shrikant can ask for it to start
  higher.
- The Medium and Hard jigsaw bands sit below the Easy band and need a scroll to reach. Watch whether she finds
  them.
