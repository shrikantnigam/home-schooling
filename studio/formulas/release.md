# Formula: release (the refinery)

| Step id | Owner | Output | Gate |
|---|---|---|---|
| `candidate` | dev | A PR to `main` with every milestone issue closed | CI green on the head: unit, content, narration audit, launch smoke, play-throughs |
| `evidence` | qa | A QA report on the PR: screenshots, transcripts, rubric scores, first-try rates | Every charter rubric row 4 or more for every changed scene |
| `feel-check` | PM | A 10-minute script for Shrikant (voices, dragging, does she want more) | Shrikant ran it (this is the only test he does) |
| `merge` | Shrikant | Merge to `main` | His approval |
| `retro` | PM, learning, QA | Retro file; pack updated | Learnings applied |
