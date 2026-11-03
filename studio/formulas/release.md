# Formula: release (the refinery)

| Step id | Owner | Output | Gate |
|---|---|---|---|
| `candidate` | dev | A PR to `main` with every milestone issue closed | CI green on the head: unit, content, narration audit, launch smoke, play-throughs |
| `evidence` | qa | A QA report on the PR: screenshots, transcripts, rubric scores, first-try rates | Every charter rubric row 4 or more for every changed scene |
| `feel-check` | PM | A 10-minute script for Shrikant (voices, dragging, does she want more) | Shrikant ran it (this is the only test he does) |
| `merge` | Shrikant | Merge to `main` | His approval |
| `sync-mac` | dev (via the Mac session) | His personal Mac folder on the merged `main`: `git fetch origin && git checkout main && git pull --ff-only origin main`, then `xcodegen generate` in App/ | Done right after every merge, so he never pulls by hand. Only if `git status` is clean; otherwise report and change nothing |
| `retro` | PM, learning, QA | Retro file; pack updated | Learnings applied |

## Where the code is written (Shrikant, 2026-11-03)
Code is written and committed in the cloud and pushed to the build branch. The Remote Control session on his personal
Mac (folder `/Users/shrikantnigam/Documents/personal-projects/home-schooling`, never the work laptop) builds and tests
it with `tools/qa_run.sh`. While a PR is open, that session fast-forwards his folder to the branch head so he can run
it on the iPad. After every merge it runs the `sync-mac` step above. Shrikant never needs to run `git pull` himself.
