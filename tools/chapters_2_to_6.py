"""Content for chapters after the MVP. Each chapter is added by its own function,
following docs/chapter-process.md. Briefs live in docs/chapters/."""


def add(skills, chapters, scenes, l, it, sc, N, S):
    chapter_2(skills, chapters, scenes, l, it, sc, N, S)
    chapter_3(skills, chapters, scenes, l, it, sc, N, S)


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
    l("b1.open2", S, "Look, Siara! A beaver keeps the planks tied in bundles of ten. Let's count how many we have.")
    l("b1.payoff", S, "Click! The first part of the bridge is back. Ten and some more makes a teen number!")
    l("b1.goodbye", S, "Today you learned that thirteen is ten and three more. Goodnight, Siara!")
    l("b2.open1", N, "Stepping stones cross the shallow part of the river. Each one has a number, all the way to twenty.")
    l("b2.open2", S, "Help me find the right stone so I don't get my hooves wet!")
    l("b2.payoff", S, "We crossed every stone! Twenty is two tens.")
    l("b2.goodbye", S, "Today you found numbers all the way to twenty. Goodnight, Siara!")
    l("b3.open1", N, "Each part of the bridge has two plank boxes. The first box must be full before the second one holds.")
    l("b3.open2", S, "Let's fill the first box to ten, then put the rest in the next box.")
    l("b3.payoff", S, "Another part of the bridge is fixed! Making ten first makes adding easy.")
    l("b3.goodbye", S, "Today you added by making ten first. Goodnight, Siara!")
    l("b4.open1", N, "A long log runs beside the bridge, marked with stones from zero to twenty.")
    l("b4.open2", S, "I can hop a long way today! Count my hops with me.")
    l("b4.payoff", S, "Boing! We hopped all the way along the log.")
    l("b4.goodbye", S, "Today you added by hopping on to twenty. Goodnight, Siara!")
    l("b5.open1", N, "Only the last part of the bridge is missing. The beaver has brought all the planks.")
    l("b5.open2", S, "Let's put the bridge together, Siara. You can use numbers now!")
    l("b5.payoff1", S, "You rebuilt the whole bridge! Today you learned that teen numbers are ten and some more.")
    l("b5.payoff2", S, "Look, on the other side... is that a cave? I can hear someone grumbling about gems.")
    l("b5.goodbye", S, "Goodnight, Siara! We'll cross the bridge together next time.")
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
    l("k1.open2", S, "Oh no, Siara! Grub is taking the kingdom's gems. Let's find out how many are left each time.")
    l("k1.payoff", S, "We counted every gem that was left. Taking away makes the number smaller.")
    l("k1.goodbye", S, "Today you learned that taking away means some are gone. Goodnight, Siara!")
    l("k2.open1", N, "Grub's tunnel has stepping stones, and the way home goes backwards.")
    l("k2.open2", S, "Let's hop back toward the entrance. Count my hops with me!")
    l("k2.payoff", S, "We hopped all the way back! Hopping back is taking away.")
    l("k2.goodbye", S, "Today you subtracted by hopping back on the line. Goodnight, Siara!")
    l("k3.open1", N, "Grub says he has more gems than Siara. Is that true?")
    l("k3.open2", S, "Let's line up the gems, one next to one, and see who has more.")
    l("k3.payoff", S, "Lining them up shows who has more, and how many more!")
    l("k3.goodbye", S, "Today you found how many more by matching. Goodnight, Siara!")
    l("k4.open1", N, "Grub hid the gems in bags of ten, with a few loose ones beside them.")
    l("k4.open2", S, "When he takes more than the loose ones, we can take from the ten!")
    l("k4.payoff", S, "Grub is surprised! You can take away from teen numbers too.")
    l("k4.goodbye", S, "Today you took away from numbers up to twenty. Goodnight, Siara!")
    l("k5.open1", N, "Grub sits on his gem pile, looking a little lonely.")
    l("k5.open2", S, "Let's work out the gems with numbers. Maybe Grub will give them back!")
    l("k5.payoff1", S, "Grub says sorry and gives the gems back! Today you learned that subtracting finds what is left, or how many more.")
    l("k5.payoff2", S, "And look, Grub has an invitation... to a Royal Ball! I wonder who will be there.")
    l("k5.goodbye", S, "Goodnight, Siara! Even grumpy goblins can be friends.")
    l("prompt.takeAway.concrete", S, "We have {a} gems. Grub wants {b}. Tap {b} gems to give them to Grub.")
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
