# Feature brief: from story to problem solving (batch 3, part A)

Formula: `feature`, five times. Approved by Shrikant 2026-11-02 (the learning expert's "Recommended plan"; no printer,
so worksheets are digital). Charter v1.5: L14, L15, L16 and the S6 exception. Spec:
https://claude.ai/artifact/SiF3EH4ut6TtdJapGyU8Jw

**Objective.** She moves from "the story tells me what to do" to "I decide what the problem needs": she writes what
happened as a number sentence, practises on her own with a worksheet, and on the Puzzle Board chooses the operation
herself as the story fades away.

## Operations and when they open

| Operation | Sign | Spoken as | Opens when this place is finished |
|---|---|---|---|
| add | + | plus | Flower Garden |
| subtract | − | minus | Goblin's Cave |
| multiply | × | times | Royal Ball |
| divide | ÷ | divided by | Fair Feast |

Numbers grow with her: sums and differences go to 20 once the Bridge of Tens is finished, otherwise 10.

## F1. Write it down (owner: learning; story, ux-art, dev)

When a place's last scene finishes, she writes what happened with number tiles before going home.

- AC-W1: Finishing a place for the first time opens "Write it down" for that place, once.
- AC-W2: Two sentences per place. She taps tiles into empty slots, left to right. The second is answer-first (L16).

  | Place | Sentence | Answer-first |
  |---|---|---|
  | Night Sky | 5 = 5 (five stars here, five there) | 5 = 5 |
  | Flower Garden | 6 + 4 = 10 | 10 = 6 + 4 |
  | Bridge of Tens | 10 + 3 = 13 | 13 = 10 + 3 |
  | Goblin's Cave | 12 − 5 = 7 | 7 = 12 − 5 |
  | Royal Ball | 3 × 4 = 12 | 12 = 3 × 4 |
  | Fair Feast | 12 ÷ 3 = 4 | 4 = 12 ÷ 3 |
  | Moon Crystal | ½ of 8 = 4 | 4 = ½ of 8 |

- AC-W3: "=" is drawn as a balance. It tips while a side is incomplete and levels when both sides are filled.
- AC-W4: A wrong tile wobbles and the companion gives a hint. Nothing is marked wrong in her record.
- AC-W5: The end line tells her a new puzzle scroll is waiting on the Puzzle Board.

Learning review: tiles hold only the numbers and signs she has met, plus one distractor number. Writing it after the
story keeps "show, then name" (L11). Story review: one intro line per place in the place's own words.

## F2. Place worksheets on the iPad (owner: learning; ux-art, dev)

- AC-S1: Each finished place has its own scroll on the Puzzle Board. It has 6 checked items, 1 "draw it" and
  1 "make a puzzle".
- AC-S2: Items are picture-first, then plain sentences, a missing number (3 + ? = 7) and an answer-first sentence.
- AC-S3: The default input is the pen: she writes the number in a box, and handwriting is read on the device.
  Tapping the number keys is always available. An unreadable answer asks her to try again and never counts as wrong.
- AC-S4: The app checks every answer. It gives one retry, then shows the answer. There are no stars or scores for her.
- AC-S5: In the parent area, each finished scroll shows its first-try result and has easy, OK and hard buttons.
  "Hard" adds the place's least-recently-seen items to her practice list (the warm-up picker uses it). "Easy" clears
  that place's items from the list.

## F3. Puzzle Board (owner: learning; story, ux-art, dev, kid-eye)

- AC-B1: A Puzzle Board button appears on the castle once she has finished her first place (the Prologue). Until a sign is taught (the Garden), the board shows only the puzzle scrolls.
- AC-B2 (L14): Each puzzle asks for the sign first. All four signs are shown, and ones not taught yet are greyed.
  Then she picks a helper (counters, the number line, or in her head), then the answer.
- AC-B3: The story fades in three levels per operation. Level 1 has the story spoken with a picture. Level 2 has
  the story spoken and written, with no picture. Level 3 is the bare sentence with the sign missing
  (6 ○ 2 = 8), and choosing the sign is the whole puzzle. Three first-try solves in a row go up a level, and two
  misses in a row go down.
- AC-B4: A wrong sign gets a "think about the story" line. A second wrong sign shows the right one.
- AC-B5: Each solved puzzle lights a paper lantern on the board, which stays lit.
- AC-B6 (L15, L6): "Make a puzzle" lets her pick two numbers and a sign. The companion answers, and about one time in
  three it gets the answer wrong for her to catch.
- AC-B7: The board lists her scrolls: one per finished place, plus mixed ones (F4).

## F4. Mixed worksheets (owner: learning; dev)

- AC-M1: A mixed scroll is offered once two operation places are finished.
- AC-M2: Its items come mostly from her weakest operation: board misses and scroll mistakes count against an
  operation, and solves count for it. It always includes one missing-sign item (L14) and one make-a-puzzle (L15).

## Layout notes (ux-art)

Paper theatre, same corners as every child screen (castle top left, ear bottom left, lock top right). Nothing
important in the top 100 pt.

- **Write it down:** a paper balance in the middle, with the sentence slots on paper cards along the beam. The left
  pan holds the left side and the right pan the right side. Tiles are in a row of paper cards at the bottom.
- **Puzzle Board:** a cork-and-paper board with a row of lanterns along the top. In the middle is a puzzle card:
  the story picture (level 1), the story text (level 2) or the bare sentence (level 3). Below it, step by step, are
  four sign cards, then three helper cards, then the answer tiles. On the right are "Make a puzzle" and the scrolls.
- **Worksheet:** a paper scroll with one item at a time, large. The picture is on top, the sentence with a write box
  in the middle, and number keys at the bottom. "Draw it" is a full paper canvas with a Done button.

## Checks

- Unit tests: write-it-down table (every place answer-first, signs match the place), slot checking, sign unlocking,
  fade up and down, the companion's planned mistakes, worksheet composition, answer checking, parent feedback
  reaching the practice list, mixed scroll weighting.
- Narration audit over the new lines (0 fail).
- QA play-through (`Chapter7PlaythroughTests`): write it down after the Garden, a scroll answered with the keys, the
  board (wrong sign then right, a helper, the answer, a lantern), level 3, make a puzzle and catch a mistake, and
  parent feedback.
