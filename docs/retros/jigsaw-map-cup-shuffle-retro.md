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
