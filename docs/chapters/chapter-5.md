# Chapter 5: The Fair Feast

Process: [chapter-process.md](../chapter-process.md) · Status: built; QA and retro follow the Chapter 4 retro

## 1. Brief (PM)

**Story problem.** After the Royal Ball, the Queen's feast must be fair: every guest gets the same number of
cupcakes, berries go into baskets that hold the same amount, and nobody is left out. **The math problem is the
story problem:** the feast can't start until Siara finds how many each guest gets.

**Math goal.** Division two ways: sharing (how many in each group?) and grouping (how many groups?), then the ÷ sign.
Every item divides exactly, and totals stay at 20 or below.

**Skills (3).** `fairShare` (share), `grouping` (groupInto), `divide` (numerals).

**Scenes (4).** F1 Sharing Cupcakes, F2 Baskets of Berries, F3 The Big Table, F4 Enough for Everyone.

**Payoff.** Everyone eats; the Moon Crystal cracks in the night sky (teaser for Chapter 6).

**New acceptance criteria.**
- **AC-5a** Sharing deals treats one at a time onto plates, round and round, so each plate ends equal.
- **AC-5b** Grouping fills one basket of `b` before starting the next; the answer is the number of baskets.
- **AC-5c** No item has a remainder (checked by `Content.validationErrors`).
- **AC-5d** Divide items show the ÷ sign with "shared by" spoken, and help shows the plates.

## 2. Pedagogy (LE)

| Skill | Concrete | Pictorial | Abstract | Home tip |
|---|---|---|---|---|
| fairShare | Place each treat; it goes to the next plate | Plates pictured | "12 shared by 3" | Deal grapes onto plates |
| grouping | Place each berry; baskets fill in turn | Baskets pictured | "10 in groups of 5" | Socks into pairs |
| divide | (numerals; help shows plates) | | "8 ÷ 2" | "8 cookies, 2 people?" |

Sharing comes before grouping because dealing out is how children share in real life. The ÷ sign is introduced
only after both meanings have been met with objects.

**Dose check.** Starting levels: `fairShare` and `grouping` at Objects, `divide` at Numbers (numeral-only, retro 2 fix).
fairShare has 12 items across F1 and F3, grouping 6 in F2 plus warm-ups, divide 7. Under the secure gate each needs
about 13 abstract-or-lower items, so expect one or two practice scenes before Chapter 6 opens. Acceptable.

## 3. Layout notes (design)

Reuses the counter activity with containers: plates for sharing, baskets for grouping. New: the feast background
(warm gold), treat and berry counters. Help on divide items shows the plates drawn from the item.

## 4. Deviation log

- D5-1: Grouping in F2 deals berries into a known number of baskets (`a / b`) rather than letting her make baskets
  herself. Making the groups is a richer task that needs a drag interaction; ticketed with the P2 drag follow-up.

## 5. QA

See [retro](../retros/chapter-5-retro.md).
