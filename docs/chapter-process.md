# Chapter process (v2)

How one chapter of Kingdom of Numbers goes from idea to a playable, tested build.
v0 was used for Chapter 1. The Chapter 1 retro ([retros/chapter-1-retro.md](retros/chapter-1-retro.md))
produced v1. Every later retro updates this file; see the changelog at the end.

## Roles

| Role | Owns | Signs off on |
|---|---|---|
| Product manager (PM) | Chapter brief, scope, acceptance criteria, deviation log | Story problem = math problem; scope delivered; ACs met; every deviation accepted or ticketed |
| Child learning expert (LE) | Skills, CPA ladder, hint and praise scripts, home tips, dose check | Pedagogy in the built app matches the brief |
| UX and graphic designer | Scene layout notes, new components, art list | Screens match the layout notes and style frame |
| Developers | Content data, activity kinds, engine changes, unit tests, QA hooks | Unit tests green; content validation green; definition of done below |
| QA | Play-through tests in the iPad simulator, screenshot review, QA report | Every scene playable end to end; one wrong path per activity kind; every AC checked |

## Stages and gates

Each stage has an output in the repo. A stage starts only when the one before it has its output.

1. **Brief (PM)** → `docs/chapters/chapter-N.md`, sections 1 and 2.
   Story problem, math goal, 3 to 5 skills, 4 to 6 scenes, new acceptance criteria (IDs `AC-Nx`),
   what the payoff changes in the world, and the teaser for the next chapter.
2. **Pedagogy (LE)** → same file, section 3.
   For each skill: concrete, pictorial and abstract forms; the 3 hint steps; praise that names what she did;
   one off-screen home tip. **Dose check (new in v1):** count items per skill across scenes and confirm the
   mastery rule (up a level at 4 of 5, mastery at 8 of last 10 abstract over 2 days) can be reached with
   the scene items plus practice scenes, and say how many practice scenes that takes.
   **New in v2:** check against the chapter gate in use (default: secure, 4 of the last 5 at Numbers over
   2 days), state each skill's starting CPA level, and flag numeral-only skills (all items `isAbstractOnly`),
   which start at Numbers.
3. **Design (UX and graphic)** → same file, section 4.
   One layout note per scene using the shared component library (corners, tiles, ten-frame, stone line,
   bond circles, story panel). Any new component gets a mock board in `mocks/` at 1180 x 820 first.
   Art list for the chapter (placeholder shapes now, illustration later).
4. **Build (developers)** → `content.json`, KingdomCore, App.
   Definition of done (new in v1):
   - Every new activity kind has: the answer rule in `Item.answer`, a unit test for it, prompt, hint
     and praise lines at every CPA level, a SwiftUI view for each level, and QA solver support in `QAPlayer`.
   - Every tappable element has an accessibility identifier; containers use
     `.accessibilityElement(children: .contain)` so they don't hide their children's identifiers.
   - Any change from the brief or mock goes in the **deviation log** (section 5 of the chapter file) when it is made, with the reason.
   - **New in v2:** every new kind has a case in the parent area's stuck-list `describe()` (the switch must be
     exhaustive, so a missing case breaks the build), and its `concreteStep` so `QAPlayer` can solve it.
   - `swift test` is green, including `ContentTests` (content validation, lines for every item at every level).
5. **QA play-through** → `App/QATests/ChapterNPlaythroughTests.swift` and section 6 of the chapter file.
   Play every new scene start to finish from a preset, one wrong-answer path per activity kind (all three hint
   steps for at least one), every new parent-area element, and a screenshot of each step. Review screenshots
   as contact sheets per scene. **New in v2:** name screenshots with the chapter prefix (`cN-TT-SS name`) so the
   print script picks them up against the layout notes and the ACs. File each finding with a screenshot name.
6. **Fix and re-run** until QA has no open blocker. Cosmetic findings can be ticketed.
7. **Retro** → `docs/retros/chapter-N-retro.md`.
   PM, LE and QA each sign off, sign off with follow-ups, or block. Gaps become learnings; learnings change this
   file (bump the version, add to the changelog) before the next chapter's brief starts.

## How the cloud build works

There is no Mac in the cloud session, so CI does the Mac work (`.github/workflows/ci.yml`):

- `Developer unit tests` runs `swift test` on macOS.
- `QA play-through` generates the Xcode project with XcodeGen, runs the UI tests on an iPad simulator,
  and prints every screenshot into the job log (the session can read logs but not artifact downloads).
  Rotate the device to landscape before launching the app, or screenshots come out cropped.
- **New in v2:** each chapter's play-through runs as its own parallel job (a matrix over chapters), so CI time
  stays near 15 minutes as chapters are added instead of growing past the 45-minute job limit.
  A new chapter adds its number to the matrix.

## Changelog

- v2 (2026-11-01, after the Chapter 2 and 3 retros): dose check names starting levels and numeral-only skills
  and uses the chapter gate; definition of done adds the parent stuck-list entry and `concreteStep`;
  screenshot naming prefix; QA split into one CI job per chapter.
- v1 (2026-11-01, after the Chapter 1 retro): added the dose check, the developer definition of done
  (accessibility identifiers, QA solver support), the deviation log, landscape-before-launch for QA,
  and the cloud CI notes. Design for later chapters is layout notes on the shared components, with new
  mock boards only for new components.
- v0 (2026-11-01): first draft, used for Chapter 1.
