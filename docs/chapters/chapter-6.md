# Chapter 6: The Moon Crystal

Process: [chapter-process.md](../chapter-process.md) · Status: built; QA and retro follow the Chapter 5 retro

## 1. Brief (PM)

**Story problem.** The Moon Crystal broke into pieces. To mend it, Siara must find equal parts, share moonstones
into halves and quarters, and walk the moonbeam path from 0 to 1. **The math problem is the story problem:** each
piece she names correctly floats back into the crystal.

**Math goal.** Early fractions: equal parts (halves, thirds, quarters), a fraction of a set (½ and ¼ of a group),
and fractions as points on a line from 0 to 1.

**Skills (3).** `equalParts` (parts), `fractionOfSet` (fractionOf), `fractionLine`.

**Scenes (4).** M1 The Broken Crystal, M2 Half the Moonstones, M3 The Moonbeam Path, M4 Mend the Moon.

**Payoff.** The moon shines whole again over the whole kingdom: the end of the first book.

**New acceptance criteria.**
- **AC-6a** Parts are always equal; the crystal is cut into `b` equal pieces and she counts them.
- **AC-6b** A fraction of a set shares `a` gems into `b` equal piles; the answer is one pile.
- **AC-6c** The moonbeam line has `b` steps from 0 to 1, labelled with fractions, and she taps `a/b`.
- **AC-6d** Fractions are written with a stacked numerator and denominator and spoken as words ("one quarter").

## 2. Pedagogy (LE)

| Skill | Concrete | Pictorial | Abstract | Home tip |
|---|---|---|---|---|
| equalParts | Tap each piece of the crystal | Pieces pictured | "How many equal parts?" | Fold paper in half twice |
| fractionOfSet | Place each gem; piles fill in turn | Piles pictured | "½ of 8" | Raisins into 2 piles |
| fractionLine | Hop along the moonbeam | Steps drawn | "Find ¾" | Ribbon cut in 4 |

Kindergarten fractions stay at "equal parts" and "one of the parts". The line is a stretch goal; it is the last scene
before the mixed M4, so a child who isn't ready simply practises it.

**Dose check.** Starting levels: all three at Objects. `fractionLine` answers on the line, so it moves through the
CPA levels like the number-line skills. About 8 items per skill across the chapter; expect practice scenes.

## 3. Layout notes (design)

Reuses the counter activity (crystal pieces, gem piles) and the stone line with `max = b` and fraction labels. New:
the night sky background, crystal counters, `FractionText`.

## 4. Deviation log

- D6-1: Unit fractions of a set only (½, ¼, ⅓ as "one pile"). Non-unit fractions of a set (¾ of 8) are left for a
  later book, which matches the kindergarten goal.

## 5. QA

See [retro](../retros/chapter-6-retro.md).
