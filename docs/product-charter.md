# Kingdom of Numbers: product charter (v1.5)

Date: 2026-11-01 · Owners: PM (keeper), child learning expert (learning rules), story director (story rules)
Status: proposed, waiting for Shrikant's approval

This is what "good" means for the app. Every agent works toward it, every gate checks against it, and it outranks
every other rule in the project. The narration, screen and code checklists in
[team-operating-model.md](team-operating-model.md) exist only to serve it.

## The objective

> Through a story she finds relatable and wants to continue, she learns math she can explain and use away from
> the screen. Every minute either teaches her something or moves the story because of something she worked out.

There are two halves, and both are required. A scene that teaches without a story she cares about fails. A scene
she enjoys that doesn't teach also fails, and that one matters more, because it's the kind of app Shrikant doesn't
want.

## Who she is (the persona every agent writes for)

- 6 years old (as of Nov 2026), in kindergarten. She can't read yet and loves math and stories. **She is ahead
  for her age** (Shrikant, 2026-11-01): she already counts well, and she told him about subitizing herself.
  Plain counting from 1 to 6 bored and irritated her. Never assume she starts from zero: find out (L12).
- She loves princesses and unicorns. She dances and wants to go back to martial arts. She's an older sister.
- What feels real at her age: being fair and sharing, helping a friend who is sad, practising until you get it
  (a dance step, a kick), getting ready for a show or a party, lost things, bedtime, being brave in the dark,
  being the big girl who knows how.
- No personal data goes into the app or the repo. Her real name is only the hero's name.

## Learning rules (L)

Owner: child learning expert. Each rule has a check.

| # | Rule | How it is checked |
|---|---|---|
| L1 | **One observable goal per scene,** written as something she does: "She finds how many more make 10 using a ten-frame." Every item serves it, or is spaced review. | Brief review: the goal is a verb she performs and items map to it |
| L2 | **Concrete, then pictures, then numbers,** with the number line as the second tool. She moves level on evidence, not on time. | Content tests; mastery engine unit tests |
| L3 | **Right level of challenge.** A simulated learner (QA) and, later, her real data land at 70 to 85% first-try correct per scene. Over 90% is too easy; under 60% is too hard and needs a smaller step. | QA run reports first-try rate per scene; PM digest reports her real rate |
| L4 | **Hints model the method, and she does the last step.** No hint just gives the answer before the third try. | Content review of every hint ladder |
| L5 | **She explains, not only answers.** At least one "How did you know?" moment per scene. She picks, by tapping, the picture of the way she did it (counted all, counted on, made ten). | Scene list has an explain item |
| L6 | **She teaches Sparkle.** At least once per chapter Sparkle makes a believable mistake (counts a star twice, forgets to count on) and she spots and fixes it. Teaching someone is one of the strongest ways to learn. | Brief review |
| L7 | **Spaced, mixed review.** Warm-ups mix earlier skills, picked from what she found hard. | Warm-up picker unit tests |
| L8 | **Away from the screen.** Every chapter has a home activity with real objects she has (toys, snacks, dance counts, kicks), and the payoff points to it. | Brief has a home activity; parent area shows it |
| L9 | **Teaching density.** At least 80% of her taps in a scene are math actions or math choices. No decoration, collection or reward taps. A reward is the world changing, never points, stickers or streaks. | QA counts taps by kind in the play-through |
| L10 | **Order of ideas.** No word, symbol or method is used before the scene that teaches it. Every chapter has a vocabulary list, and new words are shown before they are named. | Narration audit vocabulary list; LE review |
| L12 | **Start where she is.** Every chapter opens with a short, story-framed challenge (3 to 5 items across the chapter's skills, harder ones included). If she gets them right first try, she skips ahead: the skill starts at the numbers level, and scenes she has shown she knows are marked done. No skill makes a quick learner wait days for a spacing rule. Spacing is for review, not for gating. | Unit tests for test-out; QA runs a "fast learner" persona who answers everything right first time and must reach the next chapter in one session |
| L13 | **Never mundane.** No more than 3 items in a row of the same kind or size. Numbers spread across the skill's range, and each item is a little harder or different. If she gets 4 right in a row first try, the scene steps up a level or ends early with the payoff. A scene has 8 items at most. | Content audit (kinds and ranges per scene); unit test for the step-up |
| L11 | **Show, then name.** The world shows the idea first and Sparkle names it after she has done it. "Today you learned that..." lectures are kept to one short line per chapter. | Story and LE review of payoffs |
| L14 | **She chooses the operation.** Once two operations are taught, a puzzle never tells her which one to use: she picks +, −, × or ÷ first, then a tool (counters, the line, or in her head), then answers. The story wrapper fades in three levels (story with a picture, story words only, the bare number sentence) as she gets them right. | Unit tests for the fade and for choice-first; QA on the Puzzle Board |
| L15 | **She makes problems.** Every place sheet and the Puzzle Board let her make a puzzle for the companion, who sometimes gets it wrong for her to catch (L6). | QA play-through of make-a-puzzle |
| L16 | **"=" means "the same as".** The equals sign is shown as a balance, and each place writes at least one sentence answer-first (10 = 6 + 4), so she never reads "=" as "the answer comes next". | Unit test that every place's write-it-down has an answer-first sentence |

## Story rules (S)

Owner: story director. Each rule has a check.

| # | Rule | How it is checked |
|---|---|---|
| S1 | **The story's problem is the math problem.** The *remove-the-math test*: take the math out and the plot can't move. The *swap test*: swap the math for an unrelated quiz and the story breaks. Both must hold for every scene. | Rubric, row 1 |
| S2 | **Stakes a 6-year-old feels.** Every chapter names its real-life mirror: sharing snacks fairly with her little sister (division), lining dancers in equal rows for a show (multiplication), a friend who took something and feels bad (subtraction). If you can't name the mirror, the stakes are too abstract. | Brief has a "mirror" line |
| S3 | **She is the hero who decides.** Siara (spoken as "you") makes the choices. Sparkle asks for help, wonders, and gets things wrong, but never does the math for her. | Rubric, row 2 |
| S4 | **Characters with a want and a feeling.** Every scene has someone who wants something and feels something she can name (shy stars, a worried Queen, a lonely goblin). Problems are solved with kindness. Nobody is punished, and nothing is scary. | Rubric, row 3 |
| S5 | **Her work changes the world right away.** Each right answer visibly changes something (a star lights up, a plank clicks in), not only the payoff. | QA screenshot pairs before and after each item |
| S6 | **A shape to every scene.** Hook (30 seconds or less), problem, try, a wobble (one moment that's a little hard), success, change, and a tease for next time. Each chapter carries a small mystery across its scenes. The Puzzle Board and worksheets are exempt from the full shape, but every puzzle still passes the remove-the-math test (S1). | Brief review |
| S7 | **The world remembers.** Places she fixed stay fixed, and friends come back (the beaver at the feast, Grub at the ball). Callbacks to what she did earlier. | Brief has callbacks |
| S8 | **Her interests are in the story.** Princesses and unicorns are the frame. Dancing (counting steps, rows of dancers, rhythm for skip counting) and martial arts (practice, belts, counting kicks) appear across the book, at least once every two chapters. | PM backlog review |
| S9 | **Values she can carry.** Fairness, kindness, being brave, and the idea that mistakes help brains grow. Every chapter ends with a kind act as well as a solved problem. | Rubric, row 3 |
| S11 | **An open kingdom she explores.** After the Prologue (or after testing out of it), several places open at once and she chooses where to go. Each place is a complete story with its own small arc, and a light thread ties them together (each place gives back a piece of the Moon Crystal). A place opens when its prerequisites are met, not when the place before it on a line is done. | Map design; progression unit tests against the skill map |
| S10 | **Told for the ear.** Short, warm and spoken (the narration rules in 5A). | Narration audit |

## The scene rubric (a gate, not a suggestion)

The story director, the learning expert and the child's-eye reviewer each score every scene from 1 to 5 on each
row. A scene ships when every row averages 4 or more and no single score is 2 or less. Scores and one-line reasons
go in the chapter file. The first time, "Show me": each reviewer quotes the line or screenshot behind their score.

| Row | 5 looks like | 2 looks like |
|---|---|---|
| 1. Math is the plot (S1) | The bridge can't be crossed until she builds it with tens | "Count the chairs" with no reason to |
| 2. Her agency (S3, L6) | She decides, and catches Sparkle's mistake | She follows instructions while Sparkle narrates |
| 3. Heart (S2, S4, S9) | A character she cares about, with a feeling, and a kind ending | Objects with no one who cares |
| 4. Learning goal (L1, L3) | One clear goal, at the right challenge | Mixed goals, too easy or too hard |
| 5. Understanding (L4, L5, L11) | She explains her way; the idea is shown before it's named | Answer-only; the rule is lectured |
| 6. Pull to return (S6, S7) | A wobble, a win, and a tease she'll want to see | Ends flat, or pulls with rewards instead of story |

## How we know it's working (product measures)

| Measure | Target | Source |
|---|---|---|
| Skills secure at Numbers level, per chapter | All the chapter's skills before the next chapter | App's parent area |
| First-try correct per scene | 70 to 85% | QA simulated learner now; her real data later |
| Off-screen check (one task per chapter, from the spec's learning outcome check) | She does it with real objects and explains how | Shrikant, 2 minutes, once per chapter |
| She asks to play | Yes, most days she plays | Shrikant, one yes-or-no in the weekly digest (optional) |
| Sessions that end at a story stop, not cut off by the limit | 90% or more | App's parent area |
| Escaped problems (found by Shrikant, catchable by a check) | 0 per release | PM digest |
| "Too easy" or "too long" (four first-try rights in a row, or a scene she leaves early) | Under 10% of scenes | App's parent area |

## Visual direction (Shrikant, 2026-11-01)

**Paper theatre (board 1), without folk patterns.** He tried the mix and turned it down because it "lost its
character". The kingdom is a toy theatre of layered cut paper: soft shadows between layers, a paper grain, and
warm, muted colours (cream, terracotta, sage, ochre), not bright app colours. Every place is its own stage set.
From the stage direction, three ideas come too: the curtain rises at a scene's start and falls at its end; counts
land on a soft beat, so each tap matches one number and skip counting becomes dance steps; and dancing appears in
the story. Her right answers build the set piece by piece (S5). Sounds are paper, wood and music, not chimes.
Reference: https://claude.ai/artifact/LS4xENNvUjJpmw8KYWgDoa (board 1). The unicorn on board 1 reads as a pig:
companions must be recognisable in silhouette (a unicorn has its horn, mane, a long neck and legs).

## First-launch setup (Shrikant, 2026-11-01)

- A one-time setup at first launch, done by the parent with the child: the daily time limit, the hero's name, and
  the companion.
- **Time limit:** default 25 minutes, always under 60.
- **Name:** default "Siara", which can be changed during setup.
- **Companion:** five choices: a unicorn (Sparkle), a made-up superhero, a princess, a cute monster, or a gnome.
  Each has its own look, voice pitch and a few lines of its own. Story lines name the companion and never hard-code
  "unicorn" or "hooves".
- **Locked after setup.** None of the three can be changed afterwards. (Our reading: only "reset everything" in the
  parent area, behind the parent gate, starts setup again.)
- Map: a detailed, imaginary kingdom landscape in the paper-theatre style (paths, river, hills, castle, each place a
  small set), not a set of circles.

## How the team improves (Shrikant, 2026-11-01)

After every build, all seven agents hold a retro (went well, went wrong, learning). Its learnings change the agent
and formula files in `studio/` and, where needed, this charter, before the next build starts.

## Changelog

- v1.5 (2026-11-02): from story to problem solving (Shrikant approved the learning expert's plan): L14 she chooses the operation, L15 she makes problems, L16 "=" means "the same as", and the Puzzle Board exception to S6. Worksheets are digital, answered with the pen or by tapping (no printer).

- v1.4 (2026-11-01): a retro across all agents after every build, which revises the pack (batch 2 retro:
  `docs/retros/batch-2-retro.md`).

- v1.3 (2026-11-01): paper theatre only (the folk mix was turned down), first-launch setup (time limit, name,
  companion, locked), five companions, and a detailed map.
- v1.2 (2026-11-01): visual direction set to paper theatre, with the curtain, beat and dance ideas.
- v1.1 (2026-11-01): Shrikant watched her play. The Prologue was too long and too easy (counting 1 to 6 again and
  again), and she already knows counting and subitizing. Added L12 (start where she is, test-out), L13 (never
  mundane), S11 (an open kingdom after the Prologue), and the "too easy" measure. The persona now says she is ahead.
  This counts as an escape: v1 would have caught the repetition (the narration audit and L3), but not that she is
  ahead, because the persona assumed she starts from zero and nothing tested a fast learner.
