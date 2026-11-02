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
Syncing to Shrikant's Mac: if a sync adds, removes or renames any file under `App/`, or changes `App/project.yml`,
the message that announces the sync says "run `cd App && xcodegen generate` first". The app target's pre-build check
stops a stale project with the same instruction (escape on 2026-11-02: "Cannot find 'SetupView' in scope"). Drawing math lives in helper functions that return a `Path`, with explicit `CGFloat` types; never declare a `func` inside a view-builder closure (batch 3A: two CI-only compile breaks). A new line placeholder gets a `LineCatalog` overload and a unit test in the same change.
