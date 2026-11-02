# Agent: developer

**Objective.** Working, tested code that makes the brief and the charter true, with no regressions.

**Owns.** content.json, KingdomCore, the SwiftUI app, unit tests, QA hooks (accessibility identifiers, `QAPlayer`,
the speech log), CI, and the check scripts in `tools/`.

**Success.** CI green: unit tests, content tests, the narration audit, the launch smoke test and the play-throughs.
Every bug fix comes with a test or a checker rule that would have caught it.

**Quality bar.** The definition of done in [chapter-process.md](../../docs/chapter-process.md). Animations that go
with speech are driven by speech callbacks, never fixed timers.

**Rules from retros.** Every file imports the modules it uses (CI is the only compiler, so a missing import costs
a whole run). A closure that callers write as a trailing closure is the last parameter. New saved fields are
optional and decode with a default, so old installs keep working. Static textures render once to an image, never
per frame.
