# The ledger (beads)

Every unit of work is a GitHub Issue in `shrikantnigam/home-schooling`. The repository is public, so issues hold
no personal data.

## Labels

| Label | Values | Meaning |
|---|---|---|
| `formula:` | `feature`, `chapter`, `fix-batch`, `release` | Which formula poured this issue |
| `step:` | the formula's step id, e.g. `brief`, `learning-review`, `story-review`, `build`, `qa`, `signoff` | Where in the formula it sits |
| `owner:` | `pm`, `learning`, `story`, `kid-eye`, `ux-art`, `dev`, `qa` | The agent whose hook it is on |
| `status:` | `ready`, `working`, `blocked`, `gate-failed`, `done` | Its state |
| `needs:shrikant` | - | Only for the five kinds of decision in agents/pm.md |
| `severity:` | `high`, `medium`, `low` | For findings |

A formula run has one **parent issue** (the epic: the objective, the ACs, the charter rows it serves) and one
child issue per step. A **batch (convoy)** is a GitHub milestone.

## Rules

1. Work isn't done until its issue records the output (a link to a commit, a file, or a PR) and the gate result.
2. A step that fails its gate gets `status:gate-failed` and a comment naming the cause. The earliest step that
   caused it reopens.
3. A deferred finding stays open with an owner and a milestone. It never gets closed as "later".
4. Shrikant's change requests start in `/mnt/project-files/kingdom/change-requests.md` and become issues once he
   says go.
