# Formula: feature

Used for anything new that isn't a chapter (a map change, a new parent setting). The same gates as a chapter, made
smaller.

| Step id | Owner | Output | Gate |
|---|---|---|---|
| `objective` | PM | Parent issue: what she or Shrikant can do afterwards, and which charter rows it serves | Shrikant confirmed |
| `brief` | PM | ACs, journey ACs, and any line changes | ACs checkable |
| `learning-review` | learning | Notes on the issue | No charter rule is weakened |
| `story-review` | story | Line changes; the narration audit passes | S1 to S10 still hold |
| `design` | ux-art | Mock or layout note | Mock exists |
| `build` | dev | Code and tests | CI green |
| `qa` | qa | Screenshots, transcript, edge paths | No blocker |
| `signoff` | PM, learning, QA | Comment on the parent issue | All three sign off |
| `retro` | all seven agents | A retro file in `docs/retros/` | Each agent's went-well, went-wrong and learning recorded; the learnings change `studio/` and the charter before the next build starts |
