"""Content for chapters after the MVP. Each chapter is added by its own function,
following docs/chapter-process.md. Briefs live in docs/chapters/."""


def add(skills, chapters, scenes, l, it, sc, N, S):
    chapter_2(skills, chapters, scenes, l, it, sc, N, S)
    chapter_3(skills, chapters, scenes, l, it, sc, N, S)
    chapter_4(skills, chapters, scenes, l, it, sc, N, S)
    chapter_5(skills, chapters, scenes, l, it, sc, N, S)
    chapter_6(skills, chapters, scenes, l, it, sc, N, S)


def skill(skills, id, chapter, name, tip):
    skills.append(dict(id=id, chapter=chapter, name=name, homeTip=tip))


def chapter_2(skills, chapters, scenes, l, it, sc, N, S):
    """The Bridge of Tens: numbers to 20 as ten and some more, adding by making ten."""
    ch = "bridge"
    skill(skills, "tensOnes", ch, "Ten and some more (11 to 20)",
          "Bundle 10 straws with a hair tie, add a few loose straws, and count on from ten.")
    skill(skills, "line20", ch, "Find numbers to 20 on the line",
          "Chalk a number line to 20 and jump to the numbers she calls out.")
    skill(skills, "bridgeAdd", ch, "Add within 20 by making ten",
          "Put 8 spoons in an egg box of 10 and add 5 more. How many fill the box first, and how many are left over?")
    skill(skills, "hop20", ch, "Add on the number line to 20",
          "Hop forward on the stairs, counting on from the step where you start.")
    chapters.append(dict(id=ch, title="The Bridge of Tens", place="Bridge of Tens",
                         scenes=["B1", "B2", "B3", "B4", "B5"]))
    T = 20
    scenes += [
        sc("B1", ch, "Planks in Bundles", 2, [
            it("b1-13", "tensOnes", "tensOnes", 1, 3, T), it("b1-15", "tensOnes", "tensOnes", 1, 5, T),
            it("b1-12", "tensOnes", "tensOnes", 1, 2, T), it("b1-17", "tensOnes", "tensOnes", 1, 7, T),
            it("b1-11", "tensOnes", "tensOnes", 1, 1, T), it("b1-16", "tensOnes", "tensOnes", 1, 6, T),
            it("b1-18", "tensOnes", "tensOnes", 1, 8, T)], ["b1.payoff"]),
        sc("B2", ch, "Stepping Stones to 20", 2, [
            it("b2-12", "line20", "findOnLine", 12, 0, T), it("b2-15", "line20", "findOnLine", 15, 0, T),
            it("b2-18", "line20", "findOnLine", 18, 0, T), it("b2-11", "line20", "findOnLine", 11, 0, T),
            it("b2-20", "line20", "findOnLine", 20, 0, T), it("b2-14", "line20", "findOnLine", 14, 0, T),
            it("b2-17", "line20", "findOnLine", 17, 0, T)], ["b2.payoff"]),
        sc("B3", ch, "Fill the Gap", 2, [
            it("b3-9+3", "bridgeAdd", "bridgeAdd", 9, 3, T), it("b3-8+4", "bridgeAdd", "bridgeAdd", 8, 4, T),
            it("b3-7+5", "bridgeAdd", "bridgeAdd", 7, 5, T), it("b3-9+5", "bridgeAdd", "bridgeAdd", 9, 5, T),
            it("b3-8+6", "bridgeAdd", "bridgeAdd", 8, 6, T), it("b3-6+5", "bridgeAdd", "bridgeAdd", 6, 5, T)], ["b3.payoff"]),
        sc("B4", ch, "Long Hops", 2, [
            it("b4-12+4", "hop20", "hop", 12, 4, T), it("b4-9+5", "hop20", "hop", 9, 5, T),
            it("b4-14+3", "hop20", "hop", 14, 3, T), it("b4-11+6", "hop20", "hop", 11, 6, T),
            it("b4-15+4", "hop20", "hop", 15, 4, T), it("b4-8+7", "hop20", "hop", 8, 7, T)], ["b4.payoff"]),
        sc("B5", ch, "The Bridge Opens", 3, [
            it("b5-8+5", "bridgeAdd", "bridgeAdd", 8, 5, T), it("b5-1+4", "tensOnes", "tensOnes", 1, 4, T),
            it("b5-7+6", "bridgeAdd", "bridgeAdd", 7, 6, T), it("b5-9+9", "bridgeAdd", "bridgeAdd", 9, 9, T),
            it("b5-1+9", "tensOnes", "tensOnes", 1, 9, T), it("b5-6+6", "bridgeAdd", "bridgeAdd", 6, 6, T),
            it("b5-8+8", "bridgeAdd", "bridgeAdd", 8, 8, T)], ["b5.payoff1", "b5.payoff2"]),
    ]
    l("b1.open1", N, "Beyond the garden, an old bridge crossed a sparkling river. But its planks had fallen into the water.")
    l("b1.open2", S, "Look! A beaver keeps the planks tied in bundles of ten. Let's count how many we have.")
    l("b1.payoff", S, "Click! The first part of the bridge is back. Ten and some more makes a teen number!")
    l("b1.goodbye", S, "Today you learned that thirteen is ten and three more. Goodnight!")
    l("b2.open1", N, "Stepping stones cross the shallow part of the river. Each one has a number, all the way to twenty.")
    l("b2.open2", S, "Help me find the right stone so I don't get my hooves wet!")
    l("b2.payoff", S, "We crossed every stone! Twenty is two tens.")
    l("b2.goodbye", S, "Today you found numbers all the way to twenty. Goodnight!")
    l("b3.open1", N, "Each part of the bridge has two plank boxes. The first box must be full before the second one holds.")
    l("b3.open2", S, "Let's fill the first box to ten, then put the rest in the next box.")
    l("b3.payoff", S, "Another part of the bridge is fixed! Making ten first makes adding easy.")
    l("b3.goodbye", S, "Today you added by making ten first. Goodnight!")
    l("b4.open1", N, "A long log runs beside the bridge, marked with stones from zero to twenty.")
    l("b4.open2", S, "I can hop a long way today! Count my hops with me.")
    l("b4.payoff", S, "Boing! We hopped all the way along the log.")
    l("b4.goodbye", S, "Today you added by hopping on to twenty. Goodnight!")
    l("b5.open1", N, "Only the last part of the bridge is missing. The beaver has brought all the planks.")
    l("b5.open2", S, "Let's put the bridge together. You can use numbers now!")
    l("b5.payoff1", S, "You rebuilt the whole bridge! Today you learned that teen numbers are ten and some more.")
    l("b5.payoff2", S, "Look, on the other side... is that a cave? I can hear someone grumbling about gems.")
    l("b5.goodbye", S, "Goodnight! We'll cross the bridge together next time.")
    # Prompts, asks, hints and praise for the new kinds.
    l("prompt.tensOnes.concrete", S, "Here is a bundle of ten planks and some loose ones. Tap each loose plank and count on from ten.")
    l("prompt.tensOnes.pictorial", S, "A bundle of ten and {b} more planks. How many planks is that?")
    l("prompt.tensOnes", S, "Ten and {b} more. How many is that?")
    l("ask.tensOnes", S, "How many planks are there altogether?")
    l("hint.model.tensOnes", S, "Hmm, not quite. Look at the bundle. It already has ten planks inside.")
    l("hint.worked.tensOnes", S, "Let's start at ten and count on, one plank at a time.")
    l("praise.tensOnes", S, "Yes! Ten and {b} more is {answer}.")
    l("prompt.findOnLine.concrete", S, "Can you help me hop to {a}? Tap the stone where {a} lives.")
    l("prompt.bridgeAdd.concrete", S, "This span has {a} planks. Let's add {b} more. Fill the first box to ten, then use the next box.")
    l("prompt.bridgeAdd.pictorial", S, "{a} planks and {b} more. How many planks altogether?")
    l("prompt.bridgeAdd", S, "{a} plus {b}. If you want help, tap the plank boxes.")
    l("ask.bridgeAdd", S, "How many planks are there now?")
    l("hint.model.bridgeAdd", S, "Hmm, not quite. Look at the first box. How many more fill it to ten?")
    l("hint.worked.bridgeAdd", S, "Let's count on from {a}, filling the box to ten first.")
    l("praise.bridgeAdd", S, "Yes! {a} and {b} make {answer}. You filled the ten first!")
    l("praise.findOnLine", S, "Yes! That's where {a} lives.")


def chapter_3(skills, chapters, scenes, l, it, sc, N, S):
    """The Goblin's Gems: subtraction within 20 as taking away, hopping back and comparing."""
    ch = "goblin"
    skill(skills, "takeAway", ch, "Take away within 20",
          "Put 9 grapes on a plate, eat 3, and count what is left.")
    skill(skills, "hopBack", ch, "Subtract by hopping back",
          "Stand on a stair, step down 3, and say where you are.")
    skill(skills, "compare", ch, "How many more",
          "Line up her socks against yours. How many more does one of you have?")
    skill(skills, "subtract20", ch, "Subtract within 20 with numbers",
          "Ask \"13 take away 4\" at dinner and let her use fingers or spoons to check.")
    chapters.append(dict(id=ch, title="The Goblin's Gems", place="Goblin's Cave",
                         scenes=["K1", "K2", "K3", "K4", "K5"]))
    T = 20
    scenes += [
        sc("K1", ch, "Gems Go Missing", 2, [
            it("k1-7-2", "takeAway", "takeAway", 7, 2, T), it("k1-9-4", "takeAway", "takeAway", 9, 4, T),
            it("k1-6-3", "takeAway", "takeAway", 6, 3, T), it("k1-10-5", "takeAway", "takeAway", 10, 5, T),
            it("k1-8-1", "takeAway", "takeAway", 8, 1, T), it("k1-10-7", "takeAway", "takeAway", 10, 7, T)], ["k1.payoff"]),
        sc("K2", ch, "Hopping Home", 2, [
            it("k2-9-3", "hopBack", "hopBack", 9, 3, T), it("k2-12-4", "hopBack", "hopBack", 12, 4, T),
            it("k2-15-5", "hopBack", "hopBack", 15, 5, T), it("k2-11-3", "hopBack", "hopBack", 11, 3, T),
            it("k2-18-6", "hopBack", "hopBack", 18, 6, T), it("k2-14-7", "hopBack", "hopBack", 14, 7, T)], ["k2.payoff"]),
        sc("K3", ch, "Who Has More?", 2, [
            it("k3-7-4", "compare", "compare", 7, 4, T), it("k3-9-5", "compare", "compare", 9, 5, T),
            it("k3-6-2", "compare", "compare", 6, 2, T), it("k3-10-6", "compare", "compare", 10, 6, T),
            it("k3-8-7", "compare", "compare", 8, 7, T), it("k3-9-3", "compare", "compare", 9, 3, T)], ["k3.payoff"]),
        sc("K4", ch, "Take From Ten", 2, [
            it("k4-13-4", "takeAway", "takeAway", 13, 4, T), it("k4-15-6", "takeAway", "takeAway", 15, 6, T),
            it("k4-12-5", "takeAway", "takeAway", 12, 5, T), it("k4-14-8", "takeAway", "takeAway", 14, 8, T),
            it("k4-16-7", "takeAway", "takeAway", 16, 7, T), it("k4-11-3", "takeAway", "takeAway", 11, 3, T)], ["k4.payoff"]),
        sc("K5", ch, "The Gems Come Home", 3, [
            it("k5-9-4", "subtract20", "subtraction", 9, 4, T), it("k5-13-5", "subtract20", "subtraction", 13, 5, T),
            it("k5-17-8", "subtract20", "subtraction", 17, 8, T), it("k5-12-6", "subtract20", "subtraction", 12, 6, T),
            it("k5-15-9", "subtract20", "subtraction", 15, 9, T), it("k5-20-10", "subtract20", "subtraction", 20, 10, T),
            it("k5-16-8", "subtract20", "subtraction", 16, 8, T)], ["k5.payoff1", "k5.payoff2"]),
    ]
    l("k1.open1", N, "Across the bridge was a dark cave. Inside lived a grumpy goblin named Grub, who loved shiny gems.")
    l("k1.open2", S, "Oh no! Grub is taking the kingdom's gems. Let's find out how many are left each time.")
    l("k1.payoff", S, "We counted every gem that was left. Taking away makes the number smaller.")
    l("k1.goodbye", S, "Today you learned that taking away means some are gone. Goodnight!")
    l("k2.open1", N, "Grub's tunnel has stepping stones, and the way home goes backwards.")
    l("k2.open2", S, "Let's hop back toward the entrance. Count my hops with me!")
    l("k2.payoff", S, "We hopped all the way back! Hopping back is taking away.")
    l("k2.goodbye", S, "Today you subtracted by hopping back on the line. Goodnight!")
    l("k3.open1", N, "Grub says he has more gems than you. Is that true?")
    l("k3.open2", S, "Let's line up the gems, one next to one, and see who has more.")
    l("k3.payoff", S, "Lining them up shows who has more, and how many more!")
    l("k3.goodbye", S, "Today you found how many more by matching. Goodnight!")
    l("k4.open1", N, "Grub hid the gems in bags of ten, with a few loose ones beside them.")
    l("k4.open2", S, "When he takes more than the loose ones, we can take from the ten!")
    l("k4.payoff", S, "Grub is surprised! You can take away from teen numbers too.")
    l("k4.goodbye", S, "Today you took away from numbers up to twenty. Goodnight!")
    l("k5.open1", N, "Grub sits on his gem pile, looking a little lonely.")
    l("k5.open2", S, "Let's work out the gems with numbers. Maybe Grub will give them back!")
    l("k5.payoff1", S, "Grub says sorry and gives the gems back! Today you learned that subtracting finds what is left, or how many more.")
    l("k5.payoff2", S, "And look, Grub has an invitation... to a Royal Ball! I wonder who will be there.")
    l("k5.goodbye", S, "Goodnight! Even grumpy goblins can be friends.")
    l("prompt.takeAway.concrete", S, "We have {a} gems. Grub wants {b} of them. Tap the gems to give Grub {b}.")
    l("prompt.takeAway.pictorial", S, "There were {a} gems, and Grub took {b}. How many gems are left?")
    l("prompt.takeAway", S, "{a} take away {b}. How many are left?")
    l("ask.takeAway", S, "How many gems are left for us?")
    l("hint.model.takeAway", S, "Hmm, not quite. Look at the gems that are still here. Touch each one.")
    l("hint.worked.takeAway", S, "Let's count the gems that are left, together.")
    l("praise.takeAway", S, "Yes! {a} take away {b} leaves {answer}.")
    l("prompt.hopBack.concrete", S, "I'm on {a}. I'll hop back {b} times. Tap the hop button and count with me!")
    l("prompt.hopBack.pictorial", S, "I'm on {a} and I hopped back {b} times. Where did I land?")
    l("prompt.hopBack", S, "{a} take away {b}. Tap the stone where I land.")
    l("ask.hopBack", S, "Where did I land? Tap the stone.")
    l("hint.model.hopBack", S, "Hmm, not quite. Count the hops back, one stone each.")
    l("hint.worked.hopBack", S, "Let's count back together from {a}.")
    l("praise.hopBack", S, "We landed on {answer}! {a} take away {b} is {answer}.")
    l("prompt.compare.concrete", S, "You have {a} gems and Grub has {b}. Tap your gems that have no partner.")
    l("prompt.compare.pictorial", S, "You have {a} gems and Grub has {b}. How many more do you have?")
    l("prompt.compare", S, "{a} and {b}. How many more is {a}?")
    l("ask.compare", S, "How many more gems do you have than Grub?")
    l("hint.model.compare", S, "Hmm, not quite. Look for your gems with no partner. Those are the extra ones.")
    l("hint.worked.compare", S, "Let's count the gems with no partner, together.")
    l("praise.compare", S, "Yes! You have {answer} more than Grub.")
    l("prompt.subtraction", S, "{a} minus {b}. If you want help, tap the gems.")
    l("hint.model.subtraction", S, "Hmm, not quite. Let's look at the gems and take away {b}.")
    l("hint.worked.subtraction", S, "Let's take them away one at a time and count what is left.")
    l("praise.subtraction", S, "Yes! {a} minus {b} is {answer}.")


def chapter_4(skills, chapters, scenes, l, it, sc, N, S):
    """The Royal Ball: multiplication as equal groups, rows (arrays) and skip-count hops. Products up to 20."""
    ch = "ball"
    skill(skills, "equalGroups", ch, "Equal groups",
          "Make 3 plates with 2 crackers each. How many crackers altogether?")
    skill(skills, "arrays", ch, "Rows of the same (arrays)",
          "Set out 3 rows of 4 buttons. Count by rows: 4, 8, 12.")
    skill(skills, "skipCount", ch, "Skip counting by 2, 5 and 10",
          "Count shoes by twos, fingers by fives, and toes by tens.")
    skill(skills, "multiply", ch, "Multiply with numbers",
          "Ask \"3 groups of 4?\" in the car and let her draw dots to check.")
    chapters.append(dict(id=ch, title="The Royal Ball", place="Royal Ball", scenes=["R1", "R2", "R3", "R4"]))
    T = 20
    scenes += [
        sc("R1", ch, "Seats at the Tables", 2, [
            it("r1-2x3", "equalGroups", "groups", 2, 3, T), it("r1-3x2", "equalGroups", "groups", 3, 2, T),
            it("r1-4x2", "equalGroups", "groups", 4, 2, T), it("r1-2x5", "equalGroups", "groups", 2, 5, T),
            it("r1-3x3", "equalGroups", "groups", 3, 3, T), it("r1-5x2", "equalGroups", "groups", 5, 2, T)], ["r1.payoff"]),
        sc("R2", ch, "Rows of Chairs", 2, [
            it("r2-2x4", "arrays", "array", 2, 4, T), it("r2-3x3", "arrays", "array", 3, 3, T),
            it("r2-3x5", "arrays", "array", 3, 5, T), it("r2-4x4", "arrays", "array", 4, 4, T),
            it("r2-2x6", "arrays", "array", 2, 6, T), it("r2-4x5", "arrays", "array", 4, 5, T)], ["r2.payoff"]),
        sc("R3", ch, "The Hopping Dance", 2, [
            it("r3-5x2", "skipCount", "skipHop", 5, 2, T), it("r3-3x5", "skipCount", "skipHop", 3, 5, T),
            it("r3-2x10", "skipCount", "skipHop", 2, 10, T), it("r3-4x2", "skipCount", "skipHop", 4, 2, T),
            it("r3-4x5", "skipCount", "skipHop", 4, 5, T), it("r3-8x2", "skipCount", "skipHop", 8, 2, T)], ["r3.payoff"]),
        sc("R4", ch, "The Royal Ball", 3, [
            it("r4-2x4", "multiply", "multiply", 2, 4, T), it("r4-3x5", "multiply", "multiply", 3, 5, T),
            it("r4-5x2", "multiply", "multiply", 5, 2, T), it("r4-4x3", "multiply", "multiply", 4, 3, T),
            it("r4-2x10", "multiply", "multiply", 2, 10, T), it("r4-3x6", "multiply", "multiply", 3, 6, T),
            it("r4-4x4", "multiply", "multiply", 4, 4, T)], ["r4.payoff1", "r4.payoff2"]),
    ]
    l("r1.open1", N, "Grub's invitation was real. The Queen was holding a Royal Ball, and everyone was invited!")
    l("r1.open2", S, "Every table must have the same number of guests. Let's count the seats!")
    l("r1.payoff", S, "Every guest has a seat! Equal groups make counting easy.")
    l("r1.goodbye", S, "Today you counted equal groups. Goodnight!")
    l("r2.open1", N, "For the music, the chairs stand in neat rows, the same number in every row.")
    l("r2.open2", S, "Let's count the chairs row by row!")
    l("r2.payoff", S, "The musicians are ready! Rows of the same make counting fast.")
    l("r2.goodbye", S, "Today you counted rows of chairs. Goodnight!")
    l("r3.open1", N, "The dance floor has numbered tiles, and the Royal Dance uses big hops.")
    l("r3.open2", S, "Each hop jumps over the same number of tiles. Count the hops with me!")
    l("r3.payoff", S, "What a dance! Counting by twos, fives and tens is like hopping.")
    l("r3.goodbye", S, "Today you skip counted. Goodnight!")
    l("r4.open1", N, "The Ball begins! The Queen asks you to help with the last seating plans.")
    l("r4.open2", S, "You can use numbers now. Times means groups of!")
    l("r4.payoff1", S, "Everyone is dancing! Today you learned that times means equal groups.")
    l("r4.payoff2", S, "The Queen says the feast is next... but she is worried there won't be enough to share.")
    l("r4.goodbye", S, "Goodnight! Save some energy for the feast.")
    l("prompt.groups.concrete", S, "There are {a} tables, with {b} guests at each. Tap each guest to count them all.")
    l("prompt.groups.pictorial", S, "{a} tables with {b} guests at each. How many guests are there?")
    l("prompt.groups", S, "{a} groups of {b}. How many altogether?")
    l("ask.groups", S, "How many guests are at the tables?")
    l("hint.model.groups", S, "Hmm, not quite. Look at one table. It has {b} guests. Every table is the same.")
    l("hint.worked.groups", S, "Let's count on, one table at a time.")
    l("praise.groups", S, "Yes! {a} groups of {b} is {answer}.")
    l("prompt.array.concrete", S, "There are {a} rows with {b} chairs in each. Tap each row and count by rows.")
    l("prompt.array.pictorial", S, "{a} rows of {b} chairs. How many chairs?")
    l("prompt.array", S, "{a} rows of {b}. How many chairs?")
    l("ask.array", S, "How many chairs are there?")
    l("hint.model.array", S, "Hmm, not quite. Each row has {b} chairs. Count by {b}s.")
    l("hint.worked.array", S, "Let's count row by row, adding {b} each time.")
    l("praise.array", S, "Yes! {a} rows of {b} make {answer}.")
    l("prompt.skipHop.concrete", S, "Each hop jumps {b} tiles. I'll hop {a} times. Tap the hop button and count with me!")
    l("prompt.skipHop.pictorial", S, "I hopped {a} times, {b} tiles each hop. Where did I land?")
    l("prompt.skipHop", S, "{a} hops of {b}. Tap where I land.")
    l("ask.skipHop", S, "Where did I land? Tap the tile.")
    l("hint.model.skipHop", S, "Hmm, not quite. Each hop is {b} tiles long. Count by {b}s.")
    l("hint.worked.skipHop", S, "Let's count by {b}s together.")
    l("praise.skipHop", S, "We landed on {answer}! {a} hops of {b} is {answer}.")
    l("prompt.multiply", S, "{a} times {b}. If you want help, tap the guests.")
    l("hint.model.multiply", S, "Hmm, not quite. Think of {a} groups with {b} in each.")
    l("hint.worked.multiply", S, "Let's count by {b}s, {a} times.")
    l("praise.multiply", S, "Yes! {a} times {b} is {answer}.")


def chapter_5(skills, chapters, scenes, l, it, sc, N, S):
    """The Fair Feast: division as fair sharing and as grouping. Totals up to 20, always exact."""
    ch = "feast"
    skill(skills, "fairShare", ch, "Share fairly",
          "Deal 12 grapes onto 3 plates, one at a time, round and round. How many on each plate?")
    skill(skills, "grouping", ch, "Put into equal groups",
          "Put 10 socks into pairs. How many pairs?")
    skill(skills, "divide", ch, "Divide with numbers",
          "Ask \"8 cookies shared by 2 people?\" and let her share real cookies to check.")
    chapters.append(dict(id=ch, title="The Fair Feast", place="Fair Feast", scenes=["F1", "F2", "F3", "F4"]))
    T = 20
    scenes += [
        sc("F1", ch, "Sharing Cupcakes", 2, [
            it("f1-6/2", "fairShare", "share", 6, 2, T), it("f1-8/2", "fairShare", "share", 8, 2, T),
            it("f1-9/3", "fairShare", "share", 9, 3, T), it("f1-12/3", "fairShare", "share", 12, 3, T),
            it("f1-8/4", "fairShare", "share", 8, 4, T), it("f1-10/2", "fairShare", "share", 10, 2, T)], ["f1.payoff"]),
        sc("F2", ch, "Baskets of Berries", 2, [
            it("f2-6/2", "grouping", "groupInto", 6, 2, T), it("f2-10/5", "grouping", "groupInto", 10, 5, T),
            it("f2-12/3", "grouping", "groupInto", 12, 3, T), it("f2-8/2", "grouping", "groupInto", 8, 2, T),
            it("f2-15/5", "grouping", "groupInto", 15, 5, T), it("f2-12/4", "grouping", "groupInto", 12, 4, T)], ["f2.payoff"]),
        sc("F3", ch, "The Big Table", 2, [
            it("f3-15/3", "fairShare", "share", 15, 3, T), it("f3-16/4", "fairShare", "share", 16, 4, T),
            it("f3-20/5", "fairShare", "share", 20, 5, T), it("f3-18/3", "grouping", "groupInto", 18, 3, T),
            it("f3-14/2", "fairShare", "share", 14, 2, T), it("f3-20/4", "grouping", "groupInto", 20, 4, T)], ["f3.payoff"]),
        sc("F4", ch, "Enough for Everyone", 3, [
            it("f4-8/2", "divide", "divide", 8, 2, T), it("f4-12/3", "divide", "divide", 12, 3, T),
            it("f4-10/5", "divide", "divide", 10, 5, T), it("f4-16/4", "divide", "divide", 16, 4, T),
            it("f4-15/3", "divide", "divide", 15, 3, T), it("f4-18/2", "divide", "divide", 18, 2, T),
            it("f4-20/5", "divide", "divide", 20, 5, T)], ["f4.payoff1", "f4.payoff2"]),
    ]
    l("f1.open1", N, "After the dancing, everyone was hungry. The royal cooks had made a feast!")
    l("f1.open2", S, "The Queen says every plate must get the same. Let's share fairly, one at a time!")
    l("f1.payoff", S, "Every plate has the same! That's what fair means.")
    l("f1.goodbye", S, "Today you shared things fairly. Goodnight!")
    l("f2.open1", N, "The berry pickers came back with heaps of berries, and baskets that hold the same amount.")
    l("f2.open2", S, "Let's fill each basket until it's full, then start the next one.")
    l("f2.payoff", S, "All the berries are in baskets! Making equal groups tells us how many groups.")
    l("f2.goodbye", S, "Today you made equal groups. Goodnight!")
    l("f3.open1", N, "More guests came to the big table, and the cooks brought more treats.")
    l("f3.open2", S, "Bigger numbers, same idea. Fair shares for everyone!")
    l("f3.payoff", S, "Everyone at the big table is smiling. Sharing works for big numbers too.")
    l("f3.goodbye", S, "Today you shared even bigger piles. Goodnight!")
    l("f4.open1", N, "The feast is nearly over, and the last treats wait on the table.")
    l("f4.open2", S, "You can use numbers now. Divide means share fairly!")
    l("f4.payoff1", S, "Everyone had enough! Today you learned that dividing means sharing fairly into equal groups.")
    l("f4.payoff2", S, "Oh! Look up at the sky. The moon has a crack in it. Someone needs to mend the Moon Crystal.")
    l("f4.goodbye", S, "Goodnight! The moon is waiting for us.")
    l("prompt.share.concrete", S, "We have {a} cupcakes and {b} plates. Tap the pile to put one on each plate, round and round.")
    l("prompt.share.pictorial", S, "{a} treats shared fairly onto {b} plates. How many on each plate?")
    l("prompt.share", S, "{a} shared by {b}. How many each?")
    l("ask.share", S, "How many treats are on each plate?")
    l("hint.model.share", S, "Hmm, not quite. Look at just one plate and count what is on it.")
    l("hint.worked.share", S, "Let's count the treats on one plate, together.")
    l("praise.share", S, "Yes! {a} shared by {b} is {answer} each. That's fair!")
    l("prompt.groupInto.concrete", S, "We have {a} berries. Each basket holds {b}. Tap the pile to fill the baskets.")
    l("prompt.groupInto.pictorial", S, "{a} berries, {b} in each basket. How many baskets?")
    l("prompt.groupInto", S, "{a} in groups of {b}. How many groups?")
    l("ask.groupInto", S, "How many baskets did we fill?")
    l("hint.model.groupInto", S, "Hmm, not quite. Count the baskets, not the berries.")
    l("hint.worked.groupInto", S, "Let's count the full baskets together.")
    l("praise.groupInto", S, "Yes! {a} makes {answer} groups of {b}.")
    l("prompt.divide", S, "{a} divided by {b}. If you want help, tap the plates.")
    l("hint.model.divide", S, "Hmm, not quite. Think of {a} treats shared onto {b} plates.")
    l("hint.worked.divide", S, "Let's share them one at a time and count one plate.")
    l("praise.divide", S, "Yes! {a} divided by {b} is {answer}.")


def chapter_6(skills, chapters, scenes, l, it, sc, N, S):
    """The Moon Crystal: unit fractions as equal parts of a whole, of a set, and on a line from 0 to 1."""
    ch = "moon"
    skill(skills, "equalParts", ch, "Equal parts (halves, thirds, quarters)",
          "Fold a paper in half, then in half again. How many equal parts now?")
    skill(skills, "fractionOfSet", ch, "Half and a quarter of a group",
          "Share 8 raisins into 2 equal piles. One pile is half. How many is half?")
    skill(skills, "fractionLine", ch, "Fractions on a line from 0 to 1",
          "Cut a ribbon into 4 equal parts and lay it out. Point to one quarter, two quarters, three quarters.")
    chapters.append(dict(id=ch, title="The Moon Crystal", place="Moon Crystal", scenes=["M1", "M2", "M3", "M4"]))
    scenes += [
        sc("M1", ch, "The Broken Crystal", 2, [
            it("m1-2", "equalParts", "parts", 0, 2), it("m1-4", "equalParts", "parts", 0, 4),
            it("m1-3", "equalParts", "parts", 0, 3), it("m1-2b", "equalParts", "parts", 0, 2),
            it("m1-4b", "equalParts", "parts", 0, 4), it("m1-3b", "equalParts", "parts", 0, 3)], ["m1.payoff"]),
        sc("M2", ch, "Half the Moonstones", 2, [
            it("m2-8/2", "fractionOfSet", "fractionOf", 8, 2, 20), it("m2-6/2", "fractionOfSet", "fractionOf", 6, 2, 20),
            it("m2-8/4", "fractionOfSet", "fractionOf", 8, 4, 20), it("m2-10/2", "fractionOfSet", "fractionOf", 10, 2, 20),
            it("m2-12/4", "fractionOfSet", "fractionOf", 12, 4, 20), it("m2-12/2", "fractionOfSet", "fractionOf", 12, 2, 20)], ["m2.payoff"]),
        sc("M3", ch, "The Moonbeam Path", 2, [
            it("m3-1/2", "fractionLine", "fractionLine", 1, 2, 2), it("m3-1/4", "fractionLine", "fractionLine", 1, 4, 4),
            it("m3-3/4", "fractionLine", "fractionLine", 3, 4, 4), it("m3-1/3", "fractionLine", "fractionLine", 1, 3, 3),
            it("m3-2/4", "fractionLine", "fractionLine", 2, 4, 4), it("m3-2/3", "fractionLine", "fractionLine", 2, 3, 3)], ["m3.payoff"]),
        sc("M4", ch, "Mend the Moon", 3, [
            it("m4-16/4", "fractionOfSet", "fractionOf", 16, 4, 20), it("m4-1/4", "fractionLine", "fractionLine", 1, 4, 4),
            it("m4-14/2", "fractionOfSet", "fractionOf", 14, 2, 20), it("m4-3", "equalParts", "parts", 0, 3),
            it("m4-3/4", "fractionLine", "fractionLine", 3, 4, 4), it("m4-20/4", "fractionOfSet", "fractionOf", 20, 4, 20)],
           ["m4.payoff1", "m4.payoff2"]),
    ]
    l("m1.open1", N, "High above the kingdom, the Moon Crystal had cracked into pieces.")
    l("m1.open2", S, "To mend it, every piece must be the same size. Let's count the equal parts!")
    l("m1.payoff", S, "The pieces fit! Equal parts means every part is the same size.")
    l("m1.goodbye", S, "Today you learned about halves, thirds and quarters. Goodnight!")
    l("m2.open1", N, "Moonstones lay scattered on the hill. Half must go to the left of the moon, half to the right.")
    l("m2.open2", S, "Let's share the moonstones into equal piles. One pile is one part.")
    l("m2.payoff", S, "The moon is glowing on both sides! Half means one of two equal parts.")
    l("m2.goodbye", S, "Today you found half and a quarter of a group. Goodnight!")
    l("m3.open1", N, "A moonbeam stretches from the ground, at zero, all the way up to the moon, at one.")
    l("m3.open2", S, "The moonbeam has equal steps. Help me find the right step!")
    l("m3.payoff", S, "We walked the whole moonbeam! Fractions live between zero and one.")
    l("m3.goodbye", S, "Today you found fractions on a line. Goodnight!")
    l("m4.open1", N, "The last piece of the Moon Crystal is waiting.")
    l("m4.open2", S, "Use everything you know. Let's mend the moon!")
    l("m4.payoff1", S, "You mended the Moon Crystal! The whole kingdom is shining. You learned so much.")
    l("m4.payoff2", S, "Stars, flowers, a bridge, gems, a ball, a feast, and now the moon. Thank you for saving the Kingdom of Numbers!")
    l("m4.goodbye", S, "Goodnight. I'll always be here when you want to play.")
    l("prompt.parts.concrete", S, "The crystal broke into equal parts. Tap each part to count them.")
    l("prompt.parts.pictorial", S, "The crystal broke into equal parts. How many parts are there?")
    l("prompt.parts", S, "How many equal parts make the whole crystal?")
    l("ask.parts", S, "How many equal parts are there?")
    l("hint.model.parts", S, "Hmm, not quite. Touch each part once, and count.")
    l("hint.worked.parts", S, "Let's count the parts together.")
    l("praise.parts", S, "Yes! {answer} equal parts make the whole crystal. The bottom number of a fraction tells how many equal parts.")
    l("prompt.fractionOf.concrete", S, "We have {a} moonstones. Share them into {b} equal piles. Tap the pile to share.")
    l("prompt.fractionOf.pictorial", S, "{a} moonstones in {b} equal piles. How many are in one pile?")
    l("prompt.fractionOf", S, "One part out of {b} equal parts of {a}. How many is that?")
    l("ask.fractionOf", S, "How many moonstones are in one pile?")
    l("hint.model.fractionOf", S, "Hmm, not quite. Look at just one pile.")
    l("hint.worked.fractionOf", S, "Let's count one pile together.")
    l("praise.fractionOf", S, "Yes! One part of {a} in {b} equal parts is {answer}.")
    l("prompt.fractionLine", S, "The moonbeam has {b} equal steps. Tap the step for {a} out of {b}.")
    l("hint.model.fractionLine", S, "Hmm, not quite. Count the steps from zero.")
    l("hint.worked.fractionLine", S, "Let's count the steps from zero together, up to {a}.")
    l("praise.fractionLine", S, "Yes! That's {a} out of {b} steps along the moonbeam.")
