# Kingdom of Numbers: team operating model (v1.1)

Date: 2026-11-01 · Owner: Product manager · Approved by: Shrikant (pending)

This is how the project runs on autopilot. A team of agent roles builds the app with clear objectives,
measurable quality bars and hard gates. Shrikant sets the goals and approves scope. Everything else is decided,
built, tested and reviewed by the team before it reaches him.

It sits on top of the per-chapter process in [chapter-process.md](chapter-process.md) (v3 adds the gates
below) and the [product spec](product-spec.md).

## 1. Why this exists

On 2026-11-01 Shrikant found these problems himself, by listening to the app and tapping through the simulator:

| Escaped problem | Why the old process missed it |
|---|---|
| Every screen repeated its spoken intro, and Siara's name appeared in 46 of 331 lines | Nobody owned narration. QA checked screenshots, never what was said. |
| "The last number tells how many" said after almost every tap | Praise lines were checked one at a time, never as a sequence. |
| No visible overall progress, no direct way to the map | Acceptance criteria were written per chapter, never for the whole app journey. |
| Narration sounded robotic, with no pauses | No quality bar for voice; nobody reviewed lines as speech. |
| Sparkle's novelty or whisper voice was silent | Tests never checked that a voice actually produced sound. |
| Blank screen at launch in the simulator | QA tests launched with presets that skipped the real cold start. |

Every one of these was checkable without Shrikant. The rule from now on: **a problem Shrikant finds that a
checklist could have caught is a process failure.** It gets a new checklist item and an automated check where
possible, in the same batch as the fix.

## 2. The goal every role serves

> She learns real math through a story she cares about, in short sessions, and asks to come back because the
> story and the success feel good, not because the app pulls at her.

Every role's objective below is a piece of that sentence. When two roles disagree, the child learning expert
decides on learning, the PM decides on scope and order, and anything that changes the goal goes to Shrikant.

## 3. Roles

### Product manager (PM): Shrikant's single point of contact

- **Objective:** ship the smallest set of changes that moves the goal forward, with no surprises for Shrikant.
- **Owns:** the backlog and its order, chapter and feature briefs with acceptance criteria (ACs), the whole-app
  journey ACs (section 6), batching, the decision log, the digest, and every message to Shrikant.
- **Decides alone:** priority, order, batching, wording of ACs, and whether a finding blocks release.
- **Escalates to Shrikant only for:** (1) confirming the objective of a new ask before building it, (2) approving
  scope (a new chapter, a new feature, or dropping something he asked for), (3) spend, accounts and anything
  outside the project (Apple developer account, TestFlight, App Store, paid tools), (4) anything about his
  daughter's personal data or safety, and (5) the release-candidate feel check on a real iPad (section 7).
- **Success measures:** zero escaped problems per release (section 1 rule); every ask from Shrikant has a
  confirmed objective within one reply and a delivered result or a dated plan; no more than one decision ask
  per day unless he asks for more.
- **Quality bar:** a brief states the story problem, the math goal, the player-visible outcome, and ACs a tester
  can check from a screenshot or a transcript. "Looks good" is not an AC.

### Child learning expert (LE)

- **Objective:** every minute of play teaches something, at the right level, in a way a 6-year-old pre-reader can follow.
- **Owns:** skills and their CPA ladder, the dose check, hint and praise scripts, the teaching content of every
  spoken line, the home tips, and the session-length check.
- **Decides alone:** what is taught, in what order, how hints and praise work, and vetoes anything that holds
  attention without teaching (rewards for their own sake, streaks, timers, fake urgency).
- **Success measures:** every skill reachable to the chapter gate within the dose; every item's story problem
  is the math problem; no teaching phrase spoken more than once per scene (section 5B); each scene fits in
  10 to 15 minutes at a 6-year-old's pace.
- **Quality bar:** praise names what she did ("You counted on from 5!"), never generic, and doesn't repeat the
  same teaching rule more than once per scene. Hints model the method; they never just give the answer.

### UX designer

- **Objective:** she always knows what to do, where she is, and how far she has come, without reading.
- **Owns:** screen flows, layout notes, the component library, navigation (castle, map, scenes), overall
  progress display, touch targets, and the mock boards in `mocks/`.
- **Decides alone:** layout, flow, and component choices within the style frame.
- **Success measures:** every screen reachable from the castle in two taps or fewer; overall progress visible
  on the castle and the map; no dead ends; every tappable element at least 64 pt with an accessibility identifier.
- **Quality bar:** every screen has a mock or layout note before it is built, and QA screenshots match it.

### Graphic designer

- **Objective:** a kingdom that feels warm and consistent, where the art helps the math (equal parts look
  equal, groups look like groups).
- **Owns:** the style frame, characters, art list per chapter, colour and contrast.
- **Decides alone:** visual style within the spec.
- **Success measures:** math visuals are accurate (equal parts equal, counts exact) in every screenshot;
  contrast meets WCAG AA for any text; Siara and Sparkle look the same on every screen.
- **Quality bar:** no art that misleads the math, and nothing faded that should look tappable.

### Story and voice director (new role)

- **Objective:** the app sounds like a kind storyteller and a playful friend, not a machine reading a script.
- **Owns:** every spoken line's wording, the narration rules (section 5A), pacing and pauses, voice selection
  and fallback, and the per-screen narration transcript review.
- **Decides alone:** wording and pacing of lines, voice settings, which lines are intros versus feedback.
- **Success measures:** the narration audit (section 5A) passes with zero failures; no line over 14 words;
  every multi-sentence line has a pause between sentences; every character voice is audible on a device
  without extra voices installed.
- **Quality bar:** read every screen's transcript aloud in order, as she would hear it. If it sounds repetitive,
  nagging or robotic, it fails, even if each line is fine alone.

### Developers

- **Objective:** working, tested code that makes the brief true, with no regressions.
- **Owns:** content data, KingdomCore, the SwiftUI app, unit tests, QA hooks (accessibility identifiers,
  `QAPlayer` support, the speech log in section 5A), and CI.
- **Decides alone:** architecture and implementation.
- **Success measures:** `swift test` green; content validation green; the narration audit and launch smoke test
  green; no fix ships without a test that would have caught it.
- **Quality bar:** the definition of done in [chapter-process.md](chapter-process.md), plus: every bug fix adds a
  unit test, a UI test or a checker rule.

### QA

- **Objective:** nothing reaches Shrikant that a careful tester playing every screen would notice.
- **Owns:** play-through UI tests, screenshot review against mocks, the launch smoke test, the narration
  transcript audit, the whole-app journey test, and the QA report.
- **Decides alone:** whether a build passes. A blocker stops the release; the PM can only downgrade a finding
  to "ticketed" with the LE's agreement if it affects learning.
- **Success measures:** every screen and every activity kind played, including one wrong path each and the full
  hint ladder for at least one; every AC checked against a named screenshot or transcript line; zero escaped
  problems.
- **Quality bar:** play like the child, not like a script. Cold launch first, then the real path through the
  castle and map, not only presets.

## 4. The pipeline: gates before anything reaches Shrikant

The same pipeline runs for a chapter, a feature, or a batch of change requests. Each gate has an owner, an output
in the repo, and a pass rule. A stage starts only when the gate before it has passed.

| # | Gate | Owner | Output | Passes when |
|---|---|---|---|---|
| 0 | Objective confirmed | PM | Row in the decision log | Shrikant confirmed the objective (new asks only; skip for fixes inside an approved scope) |
| 1 | Spec | PM | Brief with ACs in `docs/chapters/` or `docs/features/` | ACs cover the story, the math, the journey (section 6) and narration (section 5A) |
| 2 | Learning review | LE | Pedagogy section, dose check | Every item's story problem is its math problem; dose reaches the gate; praise and hints scripted |
| 3 | UX and art | UX, graphic | Layout notes, mock boards, art list | Every new screen has a mock; navigation and progress covered |
| 4 | Script | Story and voice | Line list per screen, marked intro or feedback | `tools/narration_audit.py` has no FAIL; the rest of 5A holds on paper |
| 5 | Build and unit tests | Developers | Code, content, tests | Definition of done met; CI unit tests green |
| 6 | QA play-through | QA | UI tests, screenshots, QA report | Launch smoke test, every screen, wrong paths, screenshots match mocks, no blocker |
| 7 | Narration and voice review | Story and voice, with QA | Transcript per screen from the play-through | Narration audit passes; transcript read in order sounds natural |
| 8 | Sign-off retro | PM, LE, QA | `docs/retros/` | All three sign off; learnings applied to the process docs |
| 9 | Release candidate | PM | Digest entry, build instructions | Only now does Shrikant hear about it |

Fail at any gate goes back to the owner of the earliest gate that caused it. Two failed loops on the same gate
means the PM rewrites the brief or splits the work, rather than looping a third time.

## 5. Review checklists

Each item names how it is checked. "Auto" means a test or script fails the build. "Review" means a named role
reads it and records the result in the QA report.

### 5A. Narration and voice (Story and voice director, QA)

Rules 2 to 5 and 7 run from content alone with `python3 tools/narration_audit.py`, in any cloud session, at
gate 4 and in CI. QA does not rely on anyone listening. The app records every utterance to a speech log in QA runs
(screen id, scene id, line id, speaker, text, and whether it was an intro or feedback). The play-through writes
one transcript per screen, and a checker runs these rules over it:

1. **Auto.** A screen's intro plays only the first time that screen appears after launch. Returning to it
   (castle from the map, map from a scene, a finished scene replayed) is silent. The ear button replays it.
2. **Auto.** Siara's name appears only in the launch welcome. No other line contains "Siara".
3. **Auto.** "The last number tells how many" (and every other teaching-rule phrase) is spoken at most once
   per scene.
4. **Auto.** A how-to sentence ("Tap each star to count it") is said in full at most twice per scene, then in a
   short form. No identical line is spoken twice within 3 utterances unless it answers a new tap. A question
   is asked once per item, not again after the hands-on step.
5. **Auto.** No sentence over 12 words, and no more than 25 words before she can act on an item. Lines with
   more than one sentence are spoken sentence by sentence with a pause (at least 0.3 s) between them.
6. **Auto.** Every speaker resolves to a voice that is installed on a default iPad, with a fallback, and every
   utterance produces audio (the speech delegate reports `didFinish`, not `didCancel`, and the duration is above
   zero). Novelty and whisper voices are not used.
7. **Auto.** Lines shared by every chapter (practice, map, wrap-up, hints) name no chapter's place or objects
   (no garden lines in the cave).
8. **Review.** Read each screen's transcript in order, aloud, as she would hear it in one sitting. Flag anything
   repetitive, nagging, too long, or robotic. Record "read, passed" per screen in the QA report.
9. **Review.** Pacing: speech rate is slow enough for a 6-year-old, and there is a beat of silence after a question
   before the next prompt.

### 5B. Learning (LE)

1. **Review.** Each item's story problem is the math problem. No quiz screen in front of the fun.
2. **Auto.** Every item has a prompt, three hint steps and praise at every CPA level (content tests).
3. **Review.** Praise names what she did and doesn't repeat a teaching rule more than once per scene.
4. **Review.** Hints model the method and never just give the answer.
5. **Review.** Nothing holds attention without teaching: no streaks, timers, loot, or rewards for their own sake.
6. **Review.** The scene fits in 10 to 15 minutes, and the daily limit ends at a natural stop.
7. **Review.** Order of ideas: no term, symbol or method is used before the scene that teaches it
   (no "fraction" in the first equal-parts scene).
8. **Review.** Vocabulary: every word the audit flags as hard for a pre-reader is kept on purpose (and taught)
   or replaced.
9. **Review.** The story never claims a success she didn't earn. If the daily limit cuts a scene short, the
   wrap-up says "we'll finish tomorrow", and the scene resumes where she stopped.

### 5C. Journey and navigation (UX, QA)

1. **Auto.** The castle shows overall progress ("3 of 7" places with icons), and so does the map.
2. **Auto.** The map is reachable from the castle in one tap, even with a scene half-finished.
3. **Auto.** From every screen the castle is one tap away, and there are no dead ends.
4. **Review.** After finishing a place, she sees what changed in the kingdom and what is next.
5. **Auto.** Every tappable element has an accessibility identifier and is at least 64 pt.
6. **Review.** Every chapter unlock is marked on the map once (not only the garden), and anything the voice
   offers ("visit a place again?") actually works.
7. **Review, every release: edge-path walkthrough.** Walk these paths in the code and in the simulator, not
   only the happy path: the daily limit mid-scene, quitting and resuming mid-item, replaying a finished place,
   each chapter unlock, the ear button on every screen, leaving the parent area, and quiet hours.

### 5D. Screens and art (graphic designer, QA)

1. **Review.** Every screenshot matches its mock or layout note (contact sheet per scene).
2. **Review.** Math visuals are exact: equal parts equal, counts right, Numbers-level text right for each kind.
3. **Review.** Nothing that should be tappable looks faded; look-only elements use `.allowsHitTesting(false)`.
4. **Auto where possible, else review.** Speech and visuals stay in step. Any animation that goes with speech
   (count-along lights, quick-look hiding, highlights) is driven by the speech player's callbacks, never by a
   fixed timer. QA flags any `asyncAfter` or timer next to a `speech.say`.

### 5E. Launch and stability (developers, QA)

1. **Auto.** Launch smoke test: cold launch with no presets, first screenshot within 3 s is not blank (pixel
   variance above a threshold), and the welcome line is in the speech log.
2. **Auto.** No audio, file or speech setup blocks the main thread at launch.
3. **Auto.** Kill and relaunch mid-scene resumes at the right item.
4. **Auto.** Daily limit, parent gate and quiet hours each have a UI test.

### 5F. What agents can't judge

The simulator and the team can't judge how the voices feel on a real iPad, how dragging feels under a finger,
or whether she enjoys it. These are batched into one short feel-check script per release candidate (section 7).
They are the only testing Shrikant is asked to do.

## 6. Whole-app journey ACs

Every brief inherits these, so no chapter can break them:

- **J1.** Overall progress is visible on the castle and the map.
- **J2.** The map is one tap from the castle at any time.
- **J3.** Each intro speaks once per launch per screen; feedback always plays.
- **J4.** Her name is said once per launch, in the welcome.
- **J5.** Cold launch shows the castle and speaks the welcome within 3 seconds.
- **J6.** A session never ends mid-item, and the daily limit ends at a story stop.

## 7. How Shrikant is involved

Shrikant talks to the PM. Nobody else asks him things.

- **New ask:** he tells the PM what he wants. The PM replies once with the objective in one or two sentences,
  the ACs it will be judged by, and the scope. He confirms or corrects. Then the team runs the pipeline and he
  hears back at the release candidate.
- **Decision asks:** one question, two to four options, a recommendation, sent as a decision card. Work continues
  on the recommended option unless the step can't be undone.
- **Digest:** a short PM digest, at most once a day while work is active, and always at a release candidate.
  Under 10 lines: what shipped, what's next, what needs him (if anything), and the escaped-problem count.
- **Release-candidate feel check:** a 10-minute script on a real iPad or his Mac's simulator, listing exactly what
  to listen and feel for. His notes go to the PM, who files them in the change list. Anything he finds that a
  checklist should have caught is counted as an escape and gets a new checklist item.
- **Never asked of him:** finding bugs, listening for repeated lines, checking screens against mocks, reading
  logs, or choosing between implementation options.

## 8. Standing rules

- Never use Remote Control or folder access on the work laptop (user `nigamshr`).
- The repo is public: never commit secrets, his daughter's photos, or personal data.
- Change requests are collected in `/mnt/project-files/kingdom/change-requests.md` and built as one batch when
  Shrikant says go.
- Every deferred or ticketed item has an owner and a line in the change list, and it stays in the digest until it
  is built or Shrikant drops it. Nothing deferred drops out of sight.
- If a thread stops on a usage or credit limit, retry and continue after it resets without asking.
- Don't merge to `main` without Shrikant's approval of the release candidate.

## 9. Changelog

- v1.1 (2026-11-01, after the dry run on the current app, see [audits/2026-11-01-dry-run.md](audits/2026-11-01-dry-run.md)):
  the repeated-instruction rule and the per-sentence and per-turn word caps replace the per-line cap; shared lines
  name no place; order of ideas, vocabulary and earned-success checks; the edge-path walkthrough; speech and
  visuals in step; owners for deferred items; the cloud-runnable `tools/narration_audit.py`.
- v1 (2026-11-01): first version, after Shrikant found the narration, progress and launch problems himself.
