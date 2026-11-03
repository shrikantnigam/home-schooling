# Kingdom of Numbers: Product Spec (v0.1, draft)

Owner: Product manager role · Reviewed with: Child learning expert role
Status: v0.2, Shrikant's answers applied · Date: 2026-11-01

## 1. Why we are building this

One learner: a 6-year-old in kindergarten who likes math and reading but cannot yet read or calculate. Most kids' math apps either hold attention without teaching (Prodigy-style quiz toll gates, loot, upsells) or teach without a story (DragonBox, Todo Math). We want both: a princess and unicorn story where **the story's problem is the math problem**.

**Success looks like:** after the MVP, she can add within 10 using objects, ten-frames and a number line, explain one way she got an answer, and asks to play again without rewards being the reason.

### Principles (non-negotiable)

1. **Intrinsic integration.** Every math task is a plot action (plant 3 more flowers so Sparkle can cross). No quiz screen standing between her and the fun.
2. **Concrete, then Pictorial, then Abstract (CPA).** Each skill starts with objects she drags, then pictures, then numerals. The number line is the second tool throughout.
3. **No reading required.** Every instruction, choice and piece of feedback is spoken. Text on screen is optional and always paired with audio.
4. **Mastery, not speed.** No timers, no streak pressure, no lives. Progress unlocks when she shows understanding.
5. **Explain mistakes kindly.** A wrong answer triggers a model-based hint, never a buzzer.
6. **Finite sessions.** A scene is 10 to 15 minutes and ends at a natural story stopping point; the daily cap is 20 minutes.
7. **No ads, no purchases, no accounts, no network needed.** Nothing leaves the iPad.

## 2. Users

| User | Needs |
|---|---|
| Child (6, pre-reader) | Big touch targets, spoken everything, a friend (Sparkle) to talk to her, short wins, a story she cares about |
| Parent (Shrikant) | Set time limits, see what she has mastered and where she is stuck, lock settings behind a parent gate, trust there is no manipulation |

## 3. MVP scope

**In:** Prologue (counting 1 to 10) and Chapter 1 (Garden: addition within 10). Parent area with time limit and progress view. One child profile. Offline. iPad only, landscape.

**Out of MVP (later releases):** Chapters 2 to 6, multiple child profiles, iCloud sync, abacus mode, Android, iPhone layout, any narration languages beyond English, handwriting input.

Target MVP size: about 2 to 3 weeks of play at 4 to 5 sessions per week.

## 4. Story and chapter flow

### Whole arc (for planning; only Prologue and Chapter 1 ship in MVP)

| # | Chapter | Story problem | Math | Main models |
|---|---|---|---|---|
| P | Counting Stars | The night sky went dark; Sparkle needs stars counted back into place | Counting 1 to 10, one-to-one, cardinality, subitizing up to 5 | Objects, ten-frame, number line 0 to 10 |
| 1 | The Flower Garden | The garden must bloom for Sparkle to find the path | Addition within 10, number bonds, make-10 | Ten-frame, number bond, number line hops |
| 2 | The Bridge of Tens | Rebuild a bridge from bundles of ten planks | Place value, addition within 20 with regrouping | Ten-sticks and ones, number line 0 to 20 |
| 3 | The Goblin's Gems | A goblin took gems; win them back | Subtraction within 20, take-away and difference | Ten-frame removal, hops back, bar model |
| 4 | The Royal Ball | Seat the guests in equal rows | Multiplication as equal groups and arrays | Arrays, skip-count hops |
| 5 | The Fair Feast | Share food fairly with every guest | Division as fair sharing and grouping | Sharing into plates, bar model |
| 6 | The Moon Crystal | Mend the broken moon crystal | Unit fractions, halves, quarters, fractions on the line | Bar model cut into parts, number line 0 to 1 |

### Chapter structure (applies to every chapter)

Each chapter is 4 to 6 **scenes**. A scene is one session (10 to 15 min):

1. **Story open** (about 30 to 60 s): narrated animated panel recapping the last scene and setting today's problem.
2. **Warm-up** (2 to 3 items): mixed review of earlier skills (spaced practice).
3. **Core activity** (6 to 10 items): the new skill, moving through C, then P, then A within the chapter.
4. **Story payoff** (about 30 s): her work visibly changes the world (flowers bloom, a star lights up).
5. **Goodbye**: Sparkle names one thing she learned today and says goodnight. App returns to the "castle" home and does not auto-start the next scene.

### MVP scene list

**Prologue: Counting Stars (4 scenes)**
- P1 Meet Sparkle: tap to count stars 1 to 5; Sparkle counts aloud with her.
- P2 How many?: drag stars into a 5-frame, then a ten-frame; answer "how many" by tapping a numeral (with spoken options).
- P3 Star Path: stars sit on a number line 0 to 10; hop Sparkle to the number named.
- P4 Quick Look: flash 1 to 5 stars for 2 seconds (no timer to answer); she says or taps how many (subitizing). Payoff: the sky lights up and the kingdom map unlocks.

**Chapter 1: The Flower Garden (5 scenes)**
- G1 More Flowers (Concrete): 3 flowers bloom, plant 2 more; how many now? Drag seeds into a ten-frame.
- G2 Flower Pairs (Pictorial): number bonds; split 5 flowers between two beds in every way.
- G3 Hopping Path (Number line): Sparkle starts at 4, hops 3; where does she land?
- G4 Make Ten: fill a ten-frame to 10; "7 and how many make 10?"
- G5 Garden Festival (Abstract with support): 3 + 4 = ? read aloud, with the ten-frame and line available on tap. Payoff: the garden blooms and the bridge appears (teaser for Chapter 2).

### Interaction rules for a pre-reader

- Every screen has a **replay-instructions** button (Sparkle's ear icon) at the same spot.
- Answers are given by **dragging objects, tapping a spot on the number line, or tapping one of up to 4 numerals** that are read aloud when touched. No typing.
- Numerals are always shown with their quantity (dots) the first time they appear in a chapter.
- Touch targets at least 60 pt; no time-limited input; no double-tap or long-press required.

## 5. Mastery and progression rules

These were settled with the child learning expert role (see section 10).

**Skills.** Each chapter defines 3 to 5 skills (for example "add within 5 with objects", "make 10", "add on the number line"). Every item is tagged with one skill and one CPA level.

**Attempts and hints, per item:**
1. Wrong first try: Sparkle says it kindly and gives a **model hint** (for example, the ten-frame lights up the empty cells). She tries again.
2. Wrong second try: a **worked step** (the app counts on together with her, pausing for her to tap).
3. Still wrong: the app **shows the answer with the model**, narrates why, and marks the item "needs practice". The story still moves on.
An item counts as "correct" for mastery only if right on the first try without a hint.

**Moving up in CPA within a skill:** 4 of the last 5 items at the current level correct on first try. Moving down: 3 wrong first tries in a row at a level drops her back one level for the next items, without announcing it.

**Skill mastered:** at the Abstract level, at least 80% first-try correct across the last 10 items for that skill, **over at least 2 different days**.

**Scene unlock:** next scene unlocks when the current scene is completed (all items attempted). Scenes are a story path, not a gate.

**Chapter unlock:** the next chapter unlocks only when every skill in the current chapter is mastered. If she finishes all scenes before mastery, a short **"Garden Practice"** scene is offered that draws on her "needs practice" items, still with story framing.

**Review (spaced practice):** warm-ups draw 60% from the last chapter's skills and 40% from older ones, favoring items marked "needs practice" or not seen in 3+ days.

**Rewards:** the only rewards are story progress (the world gets restored) and Sparkle's spoken praise naming what she did ("You made ten by adding three!"). No coins, stickers to collect, or streaks in MVP.

**Parent override:** the parent can unlock the next chapter or reset a skill from the parent area.

## 6. Parent controls and time limits

**Parent gate:** entering the parent area needs a task a pre-reader cannot do: hold two fingers for 3 seconds, then answer a written question such as "type the year".

**Time limits:**
- Daily limit, default **20 minutes**, adjustable from 5 to 30 in 5-minute steps.
- Optional session limit, default off. Sessions already end naturally after one scene.
- When the limit is reached, she **finishes the current item and the payoff**, then Sparkle says goodnight and the castle shows a "Sparkle is sleeping" screen until the next day. No mid-problem cutoff.
- Quiet hours (optional): no play between set times, for example after 7:30 pm.
- Recommend the parent also use iPad Screen Time and Guided Access; the parent area links to short how-tos.

**Progress view:**
- Per chapter: skills with a status of not started, practicing, or mastered, plus CPA level.
- Last 7 days: minutes played per day, scenes completed.
- "Stuck on" list: items marked needs practice, each with a one-line suggestion for an off-screen activity (for example, "Make 7 with spoons, then add 2 more").
- No raw scores shown to the child.

**Other settings:** narration volume, music on/off, speech rate, reset all progress (with confirmation).

**Privacy:** all data stays on the device. No analytics SDKs, no network calls. App must fit Apple's Kids Category rules.

## 7. Audio and voiceover

- MVP uses Apple's on-device text-to-speech (AVSpeechSynthesizer) with two distinct enhanced English voices: one narrator and one for Sparkle. Lines name the heroine Siara.
- MVP line count estimate: about 250 to 350 recorded lines (instructions, number names 0 to 20, praise variants, hint scripts, story panels).
- The app checks that the enhanced voices are downloaded and, if not, shows the parent how to download them in Settings. It falls back to the default voice so play is never blocked.
- Recorded voices can replace TTS later without code changes, because every line has an ID.
- Music and sound effects are bundled files. Speech is generated on the device, so nothing streams.
- Subtitles off by default; available as a parent setting for later reading practice.

## 8. Art list (MVP)

Style direction: soft, warm, storybook watercolor or flat-pastel vector, high contrast for math objects so counting is easy. Math objects must be clearly separable shapes (no overlapping clusters).

**Characters**
- Sparkle the unicorn: idle, talking, happy, thinking, encouraging, sleeping, hopping (number line), flying (payoff). About 8 poses, plus mouth flaps for talking.
- Princess Siara (the child's character): idle, waving, celebrating, pointing, thinking.
- Star sprites (Prologue): small character stars that blink when counted.
- Garden helpers (Chapter 1): a bee or butterfly guide, optional.

**Backgrounds (1 per scene, about 2732 x 2048 at full resolution)**
- Castle home screen (day, night, "Sparkle is sleeping" variant)
- Kingdom map (dark, then each region lighting up)
- Prologue: dark night sky, partly lit sky, fully lit sky
- Chapter 1: bare garden, half-bloomed garden, full garden festival, garden path to bridge (teaser)

**Math manipulatives (reusable across chapters)**
- 5-frame and ten-frame (empty, cell highlight)
- Counters: stars, seeds, flowers (bud and bloom states), gems later
- Number line 0 to 10 (and 0 to 20 later) with tick marks and stepping-stones
- Number bond diagram (whole and two parts)
- Numeral tiles 0 to 20 with dot patterns

**UI**
- Replay-instructions button (ear), back-to-castle button, parent gate button (small, corner)
- Hint glow effect, correct sparkle burst, gentle "try again" wobble
- Story panels: 6 to 10 illustrated panels for scene opens and payoffs

**Audio art:** home music loop, Prologue loop, Garden loop, short sound effects (pop, chime, plant, hop, bloom).

App icon and launch screen.

## 9. Technology recommendation

### Requirements that drive the choice
iPad only for now, offline, drag-and-drop and animation heavy, lots of bundled audio, Apple Pencil not required, small team, may want Android later.

### Comparison

| Option | Pros | Cons | Fit |
|---|---|---|---|
| **SwiftUI (native)** + SpriteKit for animated scenes | Best iPad feel and performance; first-class drag and drop, accessibility, AVFoundation audio, Screen Time APIs; smallest app; no third-party runtime; long-term Apple support | iOS only; needs a Mac with Xcode to build and run | **Recommended** |
| Flutter | One codebase for iPad and Android; good animation engine; hot reload | Still needs a Mac with Xcode to build for iPad; non-native feel in places; Dart is a new language for most | Good if Android matters within a year |
| React Native (Expo) | JavaScript/TypeScript; Expo cloud builds reduce Mac needs during development | Heavy drag and animation work needs extra libraries; performance tuning for game-like scenes; still needs Apple signing | Weaker for this kind of app |
| Unity | Strong for game scenes and both platforms | Overkill for UI and parent screens; large app size; licensing; 2D storybook art is fine but UI is clunky | Only if it becomes a full game |
| Web app (PWA) on iPad | No Mac needed; fastest to start; runs in Safari | Audio autoplay limits, weaker offline, no App Store, no Screen Time integration, feels less like an app | Good for a quick prototype only |

### Recommendation
**SwiftUI for app structure and parent area, with SpriteKit (or SwiftUI Canvas/animation) for the story and manipulative scenes. Local data with SwiftData. Bundled audio with AVFoundation.** Distribute to the family iPad via TestFlight or direct install from Xcode; no App Store release needed at first.

**What this requires (confirmed):** Shrikant's Mac with the current Xcode, the Apple Developer Program ($99/year) for TestFlight installs, and an iPad running iPadOS 17 or newer.


### Architecture outline (for the developers)
- Content is **data, not code**: chapters, scenes, items, skills, hints and audio IDs live in JSON files, so new chapters need no engine changes.
- Modules: Story player, Activity engine (one view per activity type: count, ten-frame fill, number bond split, number line hop, numeral choice), Mastery engine (pure logic, unit-tested), Audio manager, Parent area, Persistence.
- The mastery engine has no UI dependencies so QA and unit tests can drive it directly.

## 10. Learning expert review (questions the PM resolved)

| Question | Decision | Reason |
|---|---|---|
| What daily limit for a 6-year-old? | Default 20 (Shrikant's choice), scenes 10 to 15 | Short distributed sessions beat long ones at this age; one scene at a time leaves room for off-screen play |
| Should she ever see a wrong answer marked red? | No; gentle wobble plus hint | Error-related anxiety in early math hurts persistence |
| Speed or timed drills? | None in MVP | Fluency comes later; timing at 6 adds anxiety without benefit |
| Move straight to numerals once she gets it right? | Only via the CPA rule (4 of 5) | Children often succeed with objects before the abstract idea is secure |
| Mastery on a single day? | Must hold across 2 days | Same-day success often reflects short-term memory |
| Rewards like stickers or coins? | No, story progress only | Extrinsic rewards can crowd out interest; the research rule is that the story is the reward |
| Abacus? | Deferred | Strongest only with high spatial working memory and heavy weekly practice; does not carry to fractions |
| Off-screen work? | Parent tips for each "stuck on" item | Concrete stage works best with real objects |

## 11. Acceptance criteria (for QA)

Each criterion is testable. IDs are referenced in test cases.

### Audio and accessibility
- **AC-A1** Every instruction, question, numeral choice, hint and praise line plays audio automatically when its screen appears.
- **AC-A2** The replay button on every activity screen replays the current instruction in full.
- **AC-A3** Touching a numeral tile speaks its name before it is selected (tap once to hear, drag or tap again to choose).
- **AC-A4** No activity requires reading text to complete. Verify by completing the Prologue with text hidden.
- **AC-A5** All touch targets in child screens are at least 60 x 60 pt.
- **AC-A6** No child screen has a countdown or time-limited input.
- **AC-A7** Narration and Sparkle use two audibly different voices, and every line that names the heroine says "Siara".
- **AC-A8** With enhanced voices not downloaded, all audio still plays using the default voice, and the parent area shows how to download the better voices.

### Story and flow
- **AC-S1** A new install starts at Prologue scene P1 after a short intro, with no setup required from the child.
- **AC-S2** Each scene follows the order: story open, warm-up (except P1), core, payoff, goodbye.
- **AC-S3** After the goodbye, the app returns to the castle home and does not start the next scene automatically.
- **AC-S4** Completing P4 lights up the sky and unlocks Chapter 1 on the kingdom map.
- **AC-S5** Completing G5 shows the garden festival payoff and the bridge teaser.
- **AC-S6** Quitting mid-scene and reopening resumes at the start of the same item.

### Mastery engine
- **AC-M1** A first-try correct answer with no hint is recorded as correct; any hinted or second-try answer is not.
- **AC-M2** First wrong answer shows a model hint; second shows a worked step; third shows the answer with explanation and marks the item needs practice.
- **AC-M3** After 4 of the last 5 items correct at a CPA level, the next item for that skill uses the next level.
- **AC-M4** After 3 wrong first tries in a row at a level, the next item drops one level (not below Concrete).
- **AC-M5** A skill is marked mastered only when it has at least 80% first-try correct over its last 10 Abstract items, spread across at least 2 calendar days.
- **AC-M6** Chapter 1 stays locked until all Prologue skills are mastered; when all Prologue scenes are done but a skill is not mastered, a practice scene is offered.
- **AC-M7** Warm-up items include at least one item marked needs practice when any exist.
- **AC-M8** Mastery state survives app restart and device reboot.

### Parent controls
- **AC-P1** The parent area cannot be opened without passing the parent gate.
  - **AC-P1a (Shrikant, 2026-11-03)** The gate is a 4-digit grown-ups' PIN, set during first-launch setup and changed in
    the parent area under Grown-ups' PIN. Only a salted hash is saved. Five wrong PINs lock the pad for a minute.
    "Forgot PIN?" falls back to the two-finger hold and the year, then opens the PIN page to set a new one. Installs
    from before the PIN keep the hold-and-year gate, and the parent area offers to set a PIN. Reset everything keeps it.
- **AC-P2** Daily limit defaults to 20 minutes and can be set from 5 to 30 in 5-minute steps.
- **AC-P3** When the daily limit is reached mid-item, the child can finish that item and see the payoff; then the sleeping screen appears and blocks play until local midnight.
- **AC-P4** Quiet hours, when set, block starting a scene in that window.
- **AC-P5** The progress view shows each skill's status and CPA level, minutes per day for the last 7 days, and the stuck-on list with an off-screen tip per item.
- **AC-P6** Parent can unlock the next chapter and reset a skill; both take effect immediately.
- **AC-P7** Reset all progress asks for confirmation and returns the app to a fresh-install state.

### Privacy, safety and quality
- **AC-Q1** The app makes zero network requests (verify with a network proxy or by playing in airplane mode with full function).
- **AC-Q2** No ads, purchase prompts, external links or sign-in screens are reachable from child screens.
- **AC-Q3** App launches to the castle in under 3 seconds on the target iPad.
- **AC-Q4** Animations hold 60 fps on the target iPad during drag and payoff scenes.
- **AC-Q5** Works in landscape both ways; portrait is locked out.
- **AC-Q6** Audio respects the mute switch setting chosen in parent settings and ducks music under narration.

### Learning outcome check (manual, with the child)
- **AC-L1** After finishing Chapter 1 she can solve 4 of 5 spoken addition problems within 10 using real objects, off-screen.
- **AC-L2** She can show at least one strategy (count on, make ten, or hops on a line) when asked "how did you know?"

## 12. Decisions from Shrikant (2026-11-01)

1. **Mac:** Available. Build natively with SwiftUI; the web-prototype fallback is not needed.
2. **Heroine:** The princess is named **Siara**. Sparkle and the narrator call her Siara. No avatar builder in MVP.
3. **Voice:** On-device computer voice (Apple text-to-speech, using an enhanced/premium English voice) for MVP. Recording real voices can come later.
4. **Time limit:** Default **20 minutes a day**, adjustable later in the parent area.
5. **Target iPad:** Not bought yet. Target any iPad that runs iPadOS 17 or newer; test on the iPad the family gets (the base 10th or 11th generation iPad is enough).
6. **Apple Developer Program:** Approved ($99/year). Install builds through TestFlight.

Still open: whether to block play after a certain hour (quiet hours ship off by default).

## 13. Team roles and hand-offs

| Role | Owns | First deliverable from this spec |
|---|---|---|
| Product manager | This spec, priorities, scope calls | Keep this spec current as decisions land |
| Child learning expert | Pedagogy, mastery rules, hint scripts | Hint and praise scripts for Prologue and Chapter 1 |
| UX designer | Flows, screen layouts, interaction details | Wireframes for castle, map, each activity type, parent area |
| Graphic designer | Characters, backgrounds, manipulatives | Sparkle model sheet and style frames from section 8 |
| Developers | App, content format, mastery engine | Content JSON schema, mastery engine with unit tests, P1 playable |
| QA | Test cases and runs against section 11 | Test plan mapped to every AC ID |
