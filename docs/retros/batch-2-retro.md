# Batch 2 retro: rebuild, setup and kingdom map

Date: 2026-11-01 · Formulas: `fix-batch` (rebuild, change-list items 8 to 19) and `feature` (setup, map) ·
Charter v1.3 → v1.4 · Result: the pack gains seven rules (listed at the end)

Shrikant asked for three builds and a retro across all agents after each. This file holds all three, then the
changes made to the pack.

## Build 1: the rebuild (Prologue test-out, open map, paper theatre, items 8 to 19)

**What was built.** A short Prologue: P0 is a five-item challenge that tests her out of counting and quick looks
(L12), then P1 and P2 only if she needs them. After the Prologue the kingdom opens (S11): the Garden, the Royal
Ball and the Fair Feast at once; the Bridge and the Goblin's Cave after the Garden; the Moon Crystal after the
Feast. Scenes that need an earlier skill wait, and the map says which place to visit first. Mastery lost its
two-day rule, so practice places appear when she needs them, with their own lines. Short prompts after two asks,
a quick look that really is quick, a pause-and-resume when the daily limit hits mid-scene, and a step-up when
she gets four in a row. The whole app moved to paper theatre: paper stage sets per place, grain, the curtain.

| Agent | Went well | Went wrong | Learning |
|---|---|---|---|
| PM | All 12 items and the three structural asks shipped in one branch, with checks. | The batch was large; QA ran long because every change touched the Prologue. | Split a rebuild into a logic PR and a look PR when both are big. Kept as advice, not a rule. |
| Learning | Test-out means she starts where she is (L12). Challenge items run at the Numbers level only, so passing them shows real fluency. | First draft of the practice picker repeated the same skill four times in a row; the interleave needed a look-ahead. | Interleaving is a rule with a test: no run longer than two of one skill when another skill is available. |
| Story | Every place now has its own practice lines and its own "waiting" line, so the open map never says a generic thing. | "Sparkle" and "hooves" were hard-coded in 40 lines. | Lines name `{companion}` and never use a body part or pronoun that only fits one companion. Added to the audit. |
| Child's eye | P0 asks five fair questions and then lets her go. A right answer in a row brings a harder one, so it isn't mundane (L13). | The full prompt was still read on every item in a scene. | After two asks the short prompt is enough; the ear button replays the long one. Already in L13; the audit now models it. |
| UX and art | Each place reads as its own stage. The curtain makes start and end feel like a show. | The map title banner sat under the spoken-line strip (screenshot 02-15), and the setup sun sat behind a card (12-01). | Layout check: nothing important in the top 100 pt, which belongs to the corners and the spoken line. |
| Dev | 26 skills, 30 scenes, 188 items; unit tests cover the open map, waiting scenes, challenge, pause and resume. | Two compile breaks only CI caught: a file used `Companion` without `import KingdomCore`, and `say(each:then:)` would have bound a trailing closure to `each`. | Every file imports what it uses; a closure parameter that callers write as a trailing closure goes last. |
| QA | Chapter 1 play-through now covers the fast learner, partial test-out, replay, resume, the limit mid-scene and setup. | Two flaky failures: a lost tile touch (chapter 2) and a quick-look timing race (chapter 1). | The QA player retries a lost touch once on the same tile, and timed reveals last longer under test. Flakes are fixed, never re-run away. |

## Build 2: first-launch setup (name, companion, time limit)

**What was built.** A setup screen at first launch: her name (default Siara), five companions (Sparkle the
unicorn, Nova the superhero, Lumi the princess, Bloop the cute monster, Pip the gnome), and the daily limit
(default 25 minutes, 5 to 55). A confirm alert says it can't be changed later. After that it is locked: the
parent area shows the limit with a lock. Only "Reset everything" behind the parent gate starts setup again. Each
companion has its own art, voice pitch and hello line, and the unicorn was redrawn (long neck, legs, horn, mane)
so it no longer reads as a pig.

| Agent | Went well | Went wrong | Learning |
|---|---|---|---|
| PM | Shrikant's rules are all checkable: default, cap, locked, reset path. | Our reading of "cannot be changed" (reset starts setup again) is a guess, recorded in the charter. | Write any reading of an ambiguous ask into the charter where Shrikant will see it. |
| Learning | Setup changes nothing about what is taught. | - | - |
| Story | One line set serves all five companions. | A gnome saying "my horn glows" would have broken the story. | Same as build 1: `{companion}` and companion-neutral lines. |
| Child's eye | Picking a friend is her first choice in the app, and the friend shows up on the castle (12-04) and in P0 (12-05). | The setup text is for the parent; she can't read it. | Fine for a screen done together, but each companion card says its name aloud when tapped. Deferred to batch 3. |
| UX and art | Five companions are recognisable in silhouette at 60 pt. | The sun showed through behind the cards. | Stages behind form screens hide the sun or moon. Fixed. |
| Dev | `SetupChoices` cleans the name (letters only, 20 max, empty → Siara) and the state decodes old saves. | - | New saved fields are always optional and decoded with a default, so old installs keep working. |
| QA | Test 12 picks a name and the gnome and checks the 55 cap; test 8 checks the lock and the reset path. | QA runs skip setup by default, so most tests never see it. | Every first-launch screen has its own test with the skip turned off. |

## Build 3: the kingdom map

**What was built.** The map is now a landscape: layered hills, a river, trees, foot paths along the real unlock
links, the castle in the middle, and a small paper set for each place (an observatory, a garden, a bridge, a cave,
a palace, a fair tent, the moon). Locked places sit in paper mist, finished ones fly a pennant, scene dots show
progress, and the map speaks only what changed since she last saw it.

| Agent | Went well | Went wrong | Learning |
|---|---|---|---|
| PM | The paths come from the same `requires` data as the unlock rules, so the map can't lie. | - | Drawn structure comes from data, never hand-placed copies. |
| Learning | The map tells her which place to visit when a scene waits on a skill, so she learns where a skill comes from. | - | - |
| Story | "The garden is awake!" lines only for places that just opened. | - | - |
| Child's eye | Mist that clears is a reward she can see. | Five places open at once could feel like too many choices. | Watch at the next playtest whether she picks or freezes. Measure added to the feel check. |
| UX and art | Reads as a place, not a menu (02-33). | The title banner sat under the spoken-line strip. | Same layout check as build 1. Fixed: the banner moved down. |
| Dev | Place spots are static per chapter; the landscape is drawn once. | The paper grain drawn per frame slowed the simulator and lost a touch. | Static textures are rendered once to an image. |
| QA | Map state is in `accessibilityValue` (locked, open, waiting, practice, done) so tests read it, not pixels. | - | - |

## Sign-offs

- **PM:** signed off. Every change-list item 8 to 19, the Prologue, the open map, paper theatre, setup and the
  map are on the branch, with the issues in the "Batch 2" milestone.
- **Learning:** signed off. L12 and L13 hold; challenge items are Numbers-level only; practice interleaves.
- **QA:** signed off on CI green for the head of the PR (unit tests and all six chapter play-throughs), with the
  screenshots named above.

## Deferred to batch 3 (each has an owner)

- Counting on a soft beat, so each tap lands on one number (owner: dev, story).
- Dancing in the story at the Royal Ball (owner: story).
- Paper, wood and music sounds instead of chimes (owner: ux-art).
- Companion cards say their name aloud in setup (owner: ux-art).
- Help piles for 14 gems overflow their ovals (owner: ux-art; from chapter 6).

## Changes to the pack

1. **dev:** every file imports the modules it uses; a closure that callers write as a trailing closure is the
   last parameter. New saved fields are optional with a default.
2. **dev:** static textures render once to an image, never per frame.
3. **qa:** a lost touch is retried once on the same element; timed reveals last longer under test; flakes are
   fixed, never re-run away. Every first-launch screen has its own test.
4. **story:** lines use `{companion}` and nothing that fits only one companion.
5. **ux-art:** the top 100 pt belongs to the corners and the spoken line; nothing important goes there. Form
   screens hide the sun or moon.
6. **formulas:** every build ends with a `retro` step across all seven agents, and its learnings change the pack
   before the next build starts (Shrikant, 2026-11-01).
7. **charter v1.4:** the retro rule, and our reading of "locked" recorded where Shrikant sees it.
