# Formula: fix batch

Used when Shrikant says go on the change list, or for findings from an audit.

| Step id | Owner | Output | Gate |
|---|---|---|---|
| `triage` | PM | One issue per item in a milestone, with owner and severity | Every item has an owner and an AC |
| `fix` | owner of each item | Commit linked on the issue | CI green |
| `regression-check` | dev | For each item, a test or checker rule that would have caught it | Each issue links its check |
| `qa` | qa | Play-through, transcript, edge paths | No blocker; every item verified with a named screenshot or line |
| `signoff` | PM, learning, QA | Comment on the milestone | All three sign off |
| `retro` | all seven agents | A retro file in `docs/retros/` | Each agent's went-well, went-wrong and learning recorded; the learnings change `studio/` and the charter before the next build starts |
