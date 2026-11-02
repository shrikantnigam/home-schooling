# Orders (when things run)

| Order | Trigger | Runs |
|---|---|---|
| New ask | Shrikant asks the PM for something new | The PM confirms the objective, then pours [feature](formulas/feature.md) or [chapter](formulas/chapter.md) |
| Change list go | Shrikant says go on the change list | [fix-batch](formulas/fix-batch.md) |
| Content change | Any commit touching `content.json` | `tools/narration_audit.py` in CI (fails the PR on FAIL) |
| Code change | Any PR | Unit tests; for app code, the QA play-through and launch smoke test |
| Batch complete | Every issue in a milestone is done | [release](formulas/release.md) |
| Patrol | Every 6 hours while any issue is `working` or `gate-failed`, and once a day otherwise | Finds stuck steps (no update in 6 hours), failed CI and stalled threads; restarts them or files a blocker; retries after usage limits |
| Digest | Daily while work is active, and at each release candidate | The PM's digest (under 10 lines) |
| Retro | After each release | PM, learning expert and QA sign off; learnings change the agents, formulas or checklists |
