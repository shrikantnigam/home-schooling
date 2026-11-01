# Kingdom Studio: the pack that builds the app

A Gas City-style pack for this project. Gas City describes a software factory as configuration you own:
**agents** (who), **formulas** (how), and **orders** (when), packaged as a pack and pointed at a repository (a
"rig"), with a supervisor that keeps it running and a ledger where every action can be audited. This folder is
that configuration for Kingdom of Numbers. It runs on Claude projects instead of the Gas City runtime (see "How it
runs here").

Everything here serves one document: [the product charter](../docs/product-charter.md). The charter says what
good is (learning through a relatable story). The pack says who makes it, how, and when.

## The parts

| Gas City / Gas Town idea | Here | File |
|---|---|---|
| Rig (the repository the factory works on) | `shrikantnigam/home-schooling` | - |
| Mayor (the coordinator you talk to) | The project coordinator, acting as the **PM agent** | [agents/pm.md](agents/pm.md) |
| Agents (who) | PM, learning expert, story director, child's-eye reviewer, UX and art, developer, QA | [agents/](agents/) |
| Formulas and molecules (how: a reusable workflow whose steps are tracked units of work) | Feature, chapter, fix batch, release | [formulas/](formulas/) |
| Orders (when) | What starts each formula, plus patrols and the digest | [orders.md](orders.md) |
| Beads (the durable, git-visible work ledger) | GitHub Issues with labels for formula, step, owner and gate | [ledger.md](ledger.md) |
| Hook (work assigned to an agent, which it must pick up) | An issue labelled `owner:<agent>` and `status:ready` | [ledger.md](ledger.md) |
| Polecats (short-lived workers that each do one unit of work) | Project threads started by the coordinator, one per issue or step | - |
| Witness and Deacon (supervisors that watch workers and patrol for stuck work) | The **patrol** order: a scheduled check of the ledger, CI and open threads | [orders.md](orders.md) |
| Refinery (the merge queue that only lets verified work through) | The PR gate: CI checks plus the sign-off comments the formula requires | [formulas/release.md](formulas/release.md) |
| Convoy (a bundle of work shipped together) | A batch: a milestone of issues released as one build | [ledger.md](ledger.md) |

## How it runs here

- **Shrikant talks only to the PM agent** (the project coordinator). A new ask becomes a feature or chapter
  formula. The PM confirms the objective with him once, then pours the formula into ledger issues.
- **Each step is an issue with an owner.** The coordinator starts a thread for the step. The thread loads the
  owner's agent file and does only that step, then records its output and gate result on the issue. This keeps
  each worker's context small and its job clear, like a polecat.
- **Gates are hard.** A step is done only when its gate passes: a check script, a rubric score, or a sign-off. A
  failed gate reopens the earliest step that caused it.
- **The patrol** looks for stuck or failed steps and restarts them, so nothing waits on Shrikant except decisions.
- **Everything is auditable.** Issues, PRs, rubric scores in the chapter files, audit outputs and retros are all
  in the repo or on GitHub.

## Why not install Gas City itself

Gas City runs many agent processes on a machine you keep running, with its own CLI and database. Doing that
would mean running a local supervisor on the personal Mac all the time and paying for many parallel agents. The
project's threads already give a mayor, workers and a shared folder. This pack borrows the parts that matter
(roles with charters, formulas with gates, a ledger, a patrol) and can be moved to real Gas City packs later
without rewriting it.
