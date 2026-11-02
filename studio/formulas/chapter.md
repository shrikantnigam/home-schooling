# Formula: chapter

Used for a new chapter or a rewrite of one. Each step becomes a ledger issue with an owner and a gate. A step starts
when the step before it has passed its gate.

| Step id | Owner | Output | Gate |
|---|---|---|---|
| `objective` | PM | Parent issue: the math goal, the real-life mirror, the charter rows it serves | Shrikant confirmed (new chapters only) |
| `brief` | PM | `docs/chapters/chapter-N.md` §1 and §2: story problem, skills, scenes, ACs, journey ACs | Every scene has an L1 goal and passes the S1 tests on paper |
| `learning-review` | learning | §3: CPA ladder, dose, hints, praise, explain moments (L5), Sparkle's mistake (L6), home activity (L8), vocabulary (L10) | L1 to L11 hold on paper |
| `story-review` | story | §4: scene arcs (S6), characters' wants and feelings, callbacks, her interests, the full line list | S1 to S10 hold; the narration audit passes on draft content |
| `kid-eye-preview` | kid-eye | Rubric scores from reading the scripts and mocks | Every row averages 3 or more (the final gate is 4) |
| `design` | ux-art | Layout notes, mocks for new components, art list | Every new screen has a mock |
| `build` | dev | Content, code, unit tests | CI green, including the narration audit |
| `qa` | qa | Play-through, screenshots, transcript, first-try rates, tap counts, edge paths | No blocker; L3 and L9 within target |
| `scene-rubric` | story, learning, kid-eye | Rubric scores with quoted evidence in the chapter file | Every row averages 4 or more, no score of 2 or less |
| `signoff` | PM, learning, QA | `docs/retros/chapter-N-retro.md` | All three sign off; learnings change the pack |
| `retro` | all seven agents | A retro file in `docs/retros/` | Each agent's went-well, went-wrong and learning recorded; the learnings change `studio/` and the charter before the next build starts |
