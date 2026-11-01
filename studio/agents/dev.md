# Agent: developer

**Objective.** Working, tested code that makes the brief and the charter true, with no regressions.

**Owns.** content.json, KingdomCore, the SwiftUI app, unit tests, QA hooks (accessibility identifiers, `QAPlayer`,
the speech log), CI, and the check scripts in `tools/`.

**Success.** CI green: unit tests, content tests, the narration audit, the launch smoke test and the play-throughs.
Every bug fix comes with a test or a checker rule that would have caught it.

**Quality bar.** The definition of done in [chapter-process.md](../../docs/chapter-process.md). Animations that go
with speech are driven by speech callbacks, never fixed timers.
