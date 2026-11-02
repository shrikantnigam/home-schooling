"""Writes Sources/KingdomCore/Resources/content.json.

Content is data: skills, chapters, scenes, items and every spoken line. Edit this script and
re-run it (python3 tools/gen_content.py), then run `swift test` so ContentTests validate it.
"""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def it(id, skill, kind, a, b=0, max=None):
    d = {"id": id, "skill": skill, "kind": kind, "a": a}
    if b: d["b"] = b
    if max: d["max"] = max
    return d
skills = [
 ("count","prologue","Count to 10, one by one","Count the spoons in a drawer together, touching each one as you say its number."),
 ("cardinality","prologue","Last number tells how many","Count 6 grapes, then ask \"so how many grapes?\" and listen for the last number."),
 ("lineFind","prologue","Find numbers on the line","Chalk a number line from 0 to 10 outside and jump to the number you call out."),
 ("subitize","prologue","Quick look up to 5","Flash a few fingers for a moment and ask how many she saw without counting."),
 ("add","garden","Add within 10","Put 3 spoons on the table, add 2 more, and count them all together."),
 ("bonds","garden","Number pairs to 5","Split 5 grapes onto two plates in as many ways as you can."),
 ("lineAdd","garden","Add on the number line","Stand on a number on a chalk line and hop forward 2 or 3 steps. Where did you land?"),
 ("makeTen","garden","Make 10","Fill an egg carton cut to 10 cups with 7 pebbles. How many more fill it?"),
]
skills = [dict(id=a, chapter=b, name=c, homeTip=d) for a,b,c,d in skills]
# The kingdom is open after the Prologue (charter S11, docs/chapters/skill-map.md). `requires` names the places
# (or single scenes) a place needs; scenes can also name `needs`. The Prologue counts as done once its scenes
# are finished (or she tests out of them), because it only checks what she already knows.
chapters = [
 dict(id="prologue", title="Counting Stars", place="Night Sky", scenes=["P0","P1","P2"], requires=[], gate="scenes"),
 dict(id="garden", title="The Flower Garden", place="Flower Garden", scenes=["G1","G2","G3","G4","G5"], requires=["prologue"]),
]
def sc(id, ch, title, warm, items, payoff, needs=None, challenge=False):
    d = dict(id=id, chapter=ch, title=title, open=[f"{id.lower()}.open1", f"{id.lower()}.open2"], warmupCount=warm,
             items=items, payoff=payoff, goodbye=f"{id.lower()}.goodbye")
    if needs: d["needs"] = needs
    if challenge: d["challenge"] = True
    return d
# Prologue (change list item 18, charter L12/L13): she already counts and subitizes, so it opens with a short
# challenge across all four skills, harder ones included. Skills she gets right first try are skipped, and the
# scenes that only teach them are marked done. The two scenes left mix kinds and spread numbers up to 12.
scenes = [
 sc("P0","prologue","Star Challenge",0,[it("p0-c9","count","countTap",9),it("p0-h7","cardinality","howMany",7),it("p0-l8","lineFind","findOnLine",8),it("p0-q5","subitize","quickLook",5),it("p0-h12","cardinality","howMany",12,0,20)],["p0.payoff"],challenge=True),
 sc("P1","prologue","Wake the Stars",0,[it("p1-4","count","countTap",4),it("p1-7","cardinality","howMany",7),it("p1-9","count","countTap",9),it("p1-3","cardinality","howMany",3),it("p1-10","cardinality","howMany",10),it("p1-6","count","countTap",6),it("p1-12","cardinality","howMany",12,0,20)],["p1.payoff"]),
 sc("P2","prologue","Star Path",2,[it("p2-l3","lineFind","findOnLine",3),it("p2-q3","subitize","quickLook",3),it("p2-l8","lineFind","findOnLine",8),it("p2-q5","subitize","quickLook",5),it("p2-l6","lineFind","findOnLine",6),it("p2-q4","subitize","quickLook",4),it("p2-l10","lineFind","findOnLine",10)],["p2.payoff1","p2.payoff2"]),
 sc("G1","garden","More Flowers",2,[it("g1-3+2","add","addMore",3,2),it("g1-2+2","add","addMore",2,2),it("g1-4+1","add","addMore",4,1),it("g1-3+3","add","addMore",3,3),it("g1-5+2","add","addMore",5,2),it("g1-1+3","add","addMore",1,3)],["g1.payoff"]),
 sc("G2","garden","Flower Pairs",2,[it("g2-5-1","bonds","numberBond",5,1),it("g2-5-2","bonds","numberBond",5,2),it("g2-5-3","bonds","numberBond",5,3),it("g2-5-4","bonds","numberBond",5,4),it("g2-4-1","bonds","numberBond",4,1),it("g2-4-2","bonds","numberBond",4,2)],["g2.payoff"]),
 sc("G3","garden","Hopping Path",2,[it("g3-4+3","lineAdd","hop",4,3),it("g3-2+3","lineAdd","hop",2,3),it("g3-5+2","lineAdd","hop",5,2),it("g3-1+4","lineAdd","hop",1,4),it("g3-6+3","lineAdd","hop",6,3),it("g3-3+2","lineAdd","hop",3,2)],["g3.payoff"]),
 sc("G4","garden","Make Ten",2,[it("g4-7","makeTen","makeTen",7),it("g4-8","makeTen","makeTen",8),it("g4-5","makeTen","makeTen",5),it("g4-9","makeTen","makeTen",9),it("g4-6","makeTen","makeTen",6),it("g4-4","makeTen","makeTen",4)],["g4.payoff"]),
 sc("G5","garden","Garden Festival",3,[it("g5-3+4","add","equation",3,4),it("g5-2+5","add","equation",2,5),it("g5-6+2","add","equation",6,2),it("g5-4+4","add","equation",4,4),it("g5-5+3","add","equation",5,3),it("g5-1+6","add","equation",1,6),it("g5-3+3","add","equation",3,3)],["g5.payoff1","g5.payoff2"]),
]
N,S="narrator","sparkle"
L = {}
def l(id, sp, t): L[id]=dict(speaker=sp, text=t)
names = ["Zero","One","Two","Three","Four","Five","Six","Seven","Eight","Nine","Ten",
         "Eleven","Twelve","Thirteen","Fourteen","Fifteen","Sixteen","Seventeen","Eighteen","Nineteen","Twenty"]
for i,n in enumerate(names): l(f"number.{i}", S, n)
for i,n in enumerate(names): l(f"count.{i}", S, n+"!")
l("castle.first",S,"Hi Siara! The stars need our help. Tap the big glowing button!")
l("castle.back",S,"Welcome back, Siara! Tap the big glowing button!")
l("map.pick",S,"Tap the place that is glowing.")
l("map.locked",S,"Not yet. We'll get there together.")
l("map.awakeMany",S,"Look, new places are awake! Which one shall we visit?")
l("map.awake.garden",S,"The garden is awake now! Let's plant flowers.")
l("map.awake.bridge",S,"The Bridge of Tens is awake now! Let's fix the bridge.")
l("map.awake.goblin",S,"Grub's cave is awake now! Let's find the gems.")
l("map.awake.ball",S,"The Royal Ball is awake now! Let's get ready to dance.")
l("map.awake.feast",S,"The Fair Feast is awake now! Let's share the treats.")
l("map.awake.moon",S,"The Moon Crystal is awake now! Let's mend the moon.")
l("map.waiting",S,"This place needs help from another place first. Look for a glowing one!")
l("map.waiting.garden",S,"First we need to help the garden. Then we can come back here!")
l("map.waiting.bridge",S,"First we need to fix the Bridge of Tens. Then we can come back here!")
l("map.waiting.ball",S,"First we need to dance at the Royal Ball. Then we can come back here!")
l("map.waiting.feast",S,"First we need to share at the Fair Feast. Then we can come back here!")
l("map.waiting.goblin",S,"First we need to help Grub. Then we can come back here!")
l("map.waiting.moon",S,"First we need to visit the moon. Then we can come back here!")
l("map.practice",S,"One place wants a little more practice. Tap the glowing place!")
l("map.done",S,"You helped this place already! Let's play here again.")
l("sleeping",N,"Sparkle is sleeping. Let's play again tomorrow.")
l("quiet",N,"Sparkle is resting now. Let's play together another time.")
l("warmup.intro",S,"Let's warm up with something we did before!")
l("core.intro",S,"Now let's help the kingdom!")
l("wrapup",S,"That was a lot of great thinking. Let's finish our story for today.")
l("wrapup.pause",S,"Sparkle is getting sleepy. We'll finish this story tomorrow!")
l("stepup",S,"Wow, you got four right in a row! Let's skip ahead.")
l("quickLook.ready",S,"Ready? Look quickly!")
l("ask.quickLook",S,"How many stars did you see?")
# scenes
l("p0.open1",N,"Once upon a time, the night sky went dark.")
l("p0.open2",S,"Hi, I'm Sparkle! The stars fell asleep. Let's see what you already know!")
l("p0.payoff",S,"You know so much already! Look, some stars are waking up.")
l("p0.goodbye",S,"What a great start! Tap the big button to keep going.")
l("p1.open1",N,"Some stars are still asleep, hiding in the clouds.")
l("p1.open2",S,"Let's count them to wake them up!")
l("p1.payoff",S,"Look, the sky is starting to glow!")
l("p1.goodbye",S,"Goodnight! The stars will be waiting for us.")
l("p2.open1",N,"Sparkle wants to cross the sky on star stones.")
l("p2.open2",S,"Some stars are shy, so look quickly! Will you help me?")
l("p2.payoff1",S,"We crossed the star path! Every number has its own place.")
l("p2.payoff2",S,"Look, the kingdom map is glowing. New places are waking up!")
l("p2.goodbye",S,"Goodnight! Next time, you choose where we go.")
l("g1.open1",N,"Morning came to the kingdom, but the flower garden was still asleep.")
l("g1.open2",S,"I can't find the path through the garden. Can we plant some flowers?")
l("g1.payoff",S,"Look at all the flowers! I can see the start of the path.")
l("g1.goodbye",S,"Today you learned that adding means putting more together. Goodnight!")
l("g2.open1",N,"The garden bees have two flower beds, and they want flowers in both.")
l("g2.open2",S,"Let's share the flowers between the beds in different ways!")
l("g2.payoff",S,"The bees are buzzing happily in both beds!")
l("g2.goodbye",S,"Today you learned a number can split in many ways. Goodnight!")
l("g3.open1",N,"Stepping stones lead deeper into the garden.")
l("g3.open2",S,"I love hopping! Count my hops with me.")
l("g3.payoff",S,"We hopped all the way along the path! Hopping forward is adding.")
l("g3.goodbye",S,"Today you learned to add by hopping on the number line. Goodnight!")
l("g4.open1",N,"In the middle of the garden there is a sleeping fountain.")
l("g4.open2",S,"The fountain wakes up when a flower box has ten flowers!")
l("g4.payoff",S,"Splash! The fountain is awake! Ten is a very special number.")
l("g4.goodbye",S,"Today you learned how many more make ten. Goodnight!")
l("g5.open1",N,"Today is the garden festival, and everyone has come to see the flowers.")
l("g5.open2",S,"Let's add the festival flowers together. You can use numbers now!")
l("g5.payoff1",S,"You made the whole garden bloom! Today you learned that adding means putting together.")
l("g5.payoff2",S,"And look... a bridge! I wonder what's across it.")
l("g5.goodbye",S,"Goodnight! I can't wait to see you again.")
# Practice and replay lines (change list item 10): each place has its own, with plain fallbacks.
l("practice.open1",N,"Sparkle wants to play here a little more.")
l("practice.open2",S,"Let's practice together. Practice makes our brains strong!")
l("practice.short",S,"Let's practice!")
l("practice.payoff",S,"You worked so hard!")
for ch, open1, payoff, mapline in [
 ("prologue","Sparkle wants to look at the stars a little more.","You worked so hard! The stars are twinkling brighter.","The night sky wants a little more practice. Tap the glowing stars!"),
 ("garden","Sparkle wants to play in the garden a little more.","You worked so hard! The flowers are standing up tall.","The garden wants a little more practice. Tap the glowing flowers!"),
 ("bridge","Sparkle wants to walk on the bridge a little more.","You worked so hard! The bridge feels strong now.","The bridge wants a little more practice. Tap the glowing bridge!"),
 ("goblin","Sparkle wants to count gems with Grub a little more.","You worked so hard! Grub's gems are sparkling.","Grub's cave wants a little more practice. Tap the glowing gem!"),
 ("ball","Sparkle wants to dance at the ball a little more.","You worked so hard! The dancers are twirling.","The ball wants a little more practice. Tap the glowing ballroom!"),
 ("feast","Sparkle wants to help at the feast a little more.","You worked so hard! Every plate is fair.","The feast wants a little more practice. Tap the glowing treats!"),
 ("moon","Sparkle wants to look at the moon a little more.","You worked so hard! The moon is shining.","The moon wants a little more practice. Tap the glowing crystal!"),
]:
    l(f"practice.open1.{ch}",N,open1)
    l(f"practice.payoff.{ch}",S,payoff)
    l(f"map.practice.{ch}",S,mapline)
l("practice.goodbye",S,"Thank you for practicing with me. Goodnight!")
# prompts
l("prompt.countTap.concrete",S,"Tap each star to wake it up. Let's count together.")
l("prompt.countTap",S,"How many stars are there? Touch a number to hear it. Touch it again to choose.")
l("prompt.howMany.concrete",S,"How many stars are in the cloud? Tap each star to count it, then touch a number. Touch it again to choose.")
l("prompt.howMany",S,"How many stars are in the cloud?")
l("prompt.findOnLine",S,"Can you help me hop to {a}? Tap the stone where {a} lives.")
l("prompt.quickLook",S,"Look quickly! How many stars did you see? Touch a number, then touch it again to choose.")
# Short how-to forms (change list item 8): the full prompt is said twice in a scene, then these.
l("prompt.countTap.concrete.short",S,"Tap each star.")
l("prompt.countTap.short",S,"How many stars?")
l("prompt.howMany.concrete.short",S,"Count the stars, then pick a number.")
l("prompt.howMany.short",S,"How many stars?")
l("prompt.findOnLine.short",S,"Hop to {a}!")
l("prompt.findOnLine.concrete.short",S,"Hop to {a}!")
l("prompt.addMore.concrete.short",S,"{a} flowers. Plant {b} more.")
l("prompt.addMore.pictorial.short",S,"{a} and {b} more. How many?")
l("prompt.numberBond.short",S,"{a} flowers, {b} here. How many there?")
l("prompt.numberBond.concrete.short",S,"{a} flowers. This bed has {b}. Move the rest.")
l("prompt.hop.short",S,"On {a}, hop {b}!")
l("prompt.makeTen.short",S,"We have {a}. How many more?")
l("prompt.makeTen.concrete.short",S,"We have {a}. Fill it up!")
l("prompt.equation.short",S,"{a} plus {b}.")
l("prompt.addMore.concrete",S,"{a} flowers are awake. Let's plant {b} more seeds so I can find the path. Drag a seed into the flower box.")
l("ask.addMore",S,"How many flowers are there now?")
l("ask.makeTen",S,"The box is full! How many seeds did we plant to make ten?")
l("ask.numberBond",S,"How many flowers are in the other bed now?")
l("prompt.addMore.pictorial",S,"{a} flowers are awake, and {b} more just bloomed. How many flowers are there now?")
l("prompt.addMore",S,"{a} flowers and {b} more. How many flowers?")
l("prompt.numberBond",S,"The bees want flowers in both beds. We have {a} flowers, and this bed has {b}. How many go in the other bed?")
# Concrete G2 and G4 ask nothing until the hands-on step is done, so the question is asked once (item 17).
l("prompt.numberBond.concrete",S,"The bees want flowers in both beds. We have {a} flowers, and this bed has {b}. Move the other flowers to the second bed.")
l("prompt.hop",S,"I'm on {a}. I'll hop {b} times. Count my hops with me! Where will I land?")
l("prompt.makeTen",S,"The fountain wakes up when the box has ten flowers. We have {a}. How many more do we need?")
l("prompt.makeTen.concrete",S,"The fountain wakes up when the box has ten flowers. We have {a}. Plant seeds until the box is full!")
l("prompt.equation",S,"{a} plus {b}. If you want help, tap the flower box or the hopping path.")
# hints
l("hint.model",S,"Hmm, not quite. Let's look again. Touch each one and count.")
l("hint.model.addMore",S,"Hmm, not quite. Let's count them together. Touch each flower.")
l("hint.model.makeTen",S,"Hmm, not quite. Look at the empty spots in the box. Each empty spot needs a flower.")
l("hint.model.hop",S,"Hmm, not quite. Let's hop again, one stone for each horseshoe.")
l("hint.model.findOnLine",S,"Hmm, not quite. Let's start at zero and count the stones.")
l("hint.model.quickLook",S,"Hmm, not quite. Let's peek one more time!")
l("hint.model.numberBond",S,"Hmm, not quite. Count the flowers that still need a bed.")
l("hint.worked",S,"Let's count on together. Start at {a}, and count {b} more.")
l("hint.worked.countTap",S,"Let's count together slowly. Watch each star light up.")
l("hint.worked.howMany",S,"Let's count together slowly. Watch each star light up.")
l("hint.worked.quickLook",S,"Let's look one more time and count together.")
l("hint.worked.findOnLine",S,"Let's count the stones together, from zero to {a}.")
l("hint.worked.makeTen",S,"Let's count the empty spots together.")
l("hint.worked.numberBond",S,"Let's count the flowers that are left, together.")
l("reveal",S,"It's {answer}! Let's see why together. We'll practice this again soon.")
l("praise.1",S,"Yes! You did it!")
l("praise.2",S,"That's right! Great thinking!")
l("praise.3",S,"Wonderful! You figured it out!")
l("praise.countTap",S,"{a} stars! The last number tells how many.")
l("praise.addMore",S,"Yes! {a} and {b} more make {answer}!")
l("praise.makeTen",S,"You made ten by adding {answer}!")
l("praise.hop",S,"We landed on {answer}! {a} and {b} more make {answer}.")
l("praise.numberBond",S,"Yes! {b} and {answer} make {a}.")
l("praise.equation",S,"Yes! {a} plus {b} is {answer}.")
l("tryAgain",S,"Try again. You can do it.")
import chapters_2_to_6
chapters_2_to_6.add(skills, chapters, scenes, l, it, sc, N, S)
# Short how-to forms for chapters 2 to 6 (change list item 8).
for lid, t in [
 ("prompt.tensOnes.concrete.short","Tap each plank."),
 ("prompt.tensOnes.pictorial.short","Ten and {b} more. How many?"),
 ("prompt.bridgeAdd.concrete.short","{a} planks. Add {b} more."),
 ("prompt.bridgeAdd.pictorial.short","{a} and {b} more. How many?"),
 ("prompt.bridgeAdd.short","{a} plus {b}."),
 ("prompt.takeAway.concrete.short","{a} gems. Give Grub {b}."),
 ("prompt.takeAway.short","{a} take away {b}. How many left?"),
 ("prompt.hopBack.concrete.short","On {a}. Hop back {b} times!"),
 ("prompt.hopBack.short","On {a}, back {b}. Tap the stone."),
 ("prompt.compare.concrete.short","{a} and {b}. Tap the extras."),
 ("prompt.compare.short","{a} and {b}. How many more?"),
 ("prompt.subtraction.short","{a} minus {b}."),
 ("prompt.groups.concrete.short","{a} tables, {b} at each. Tap each guest."),
 ("prompt.groups.short","{a} groups of {b}. How many?"),
 ("prompt.array.concrete.short","{a} rows of {b}. Tap each row."),
 ("prompt.skipHop.concrete.short","{b} tiles each hop. Hop {a} times!"),
 ("prompt.skipHop.short","{a} hops of {b}. Tap the tile."),
 ("prompt.multiply.short","{a} times {b}."),
 ("prompt.share.concrete.short","{a} cupcakes, {b} plates. Share them out!"),
 ("prompt.share.short","{a} treats, {b} plates. How many each?"),
 ("prompt.groupInto.concrete.short","{a} berries, {b} in each basket. Fill them!"),
 ("prompt.groupInto.short","{a} berries, {b} in each. How many baskets?"),
 ("prompt.divide.short","{a} divided by {b}."),
 ("prompt.parts.concrete.short","Tap each part."),
 ("prompt.parts.short","How many parts?"),
 ("prompt.fractionOf.concrete.short","{a} moonstones, {b} equal piles. Share them!"),
 ("prompt.fractionOf.short","{a} in {b} equal piles. How many each?"),
 ("prompt.fractionLine.short","Tap {a} out of {b}."),
 ("prompt.tensOnes.short","Ten and {b} more."),
 ("prompt.array.short","{a} rows of {b}. How many?"),
 # The question after a hands-on step, short after the first two (item 8).
 ("ask.addMore.short","How many now?"), ("ask.numberBond.short","How many there?"), ("ask.makeTen.short","Full! How many seeds?"),
 ("ask.tensOnes.short","How many planks?"), ("ask.bridgeAdd.short","How many planks?"), ("ask.takeAway.short","How many left?"),
 ("ask.hopBack.short","Where am I?"), ("ask.skipHop.short","Where am I?"), ("ask.compare.short","How many extra?"),
 ("ask.groups.short","How many guests?"), ("ask.array.short","How many chairs?"), ("ask.share.short","How many each?"),
 ("ask.groupInto.short","How many baskets?"), ("ask.parts.short","How many parts?"), ("ask.fractionOf.short","How many each?"),
 ("ask.quickLook.short","How many stars?"),
]:
    l(lid, S, t)
# Each companion's own hello, said once in the Prologue's opening (charter v1.3).
l("companion.hello.unicorn",S,"I'm a unicorn, and my horn glows when we count!")
l("companion.hello.superhero",S,"I'm a superhero, and my super power is counting!")
l("companion.hello.princess",S,"I'm a princess from the castle, and I love puzzles!")
l("companion.hello.monster",S,"I'm a friendly monster, and I love munching numbers!")
l("companion.hello.gnome",S,"I'm a garden gnome, and I know every path in the kingdom!")
# From story to problem solving (charter v1.5, docs/features/problem-solving.md).
# F1: write it down, at the end of each place.
l("write.intro.prologue",S,"Five stars here, five stars there. Let's write that with numbers!")
l("write.intro.garden",S,"Six flowers and four more made ten. Let's write it down!")
l("write.intro.bridge",S,"Ten planks and three more made thirteen. Let's write it down!")
l("write.intro.goblin",S,"Twelve gems, Grub took five, seven were left. Let's write it down!")
l("write.intro.ball",S,"Three tables with four guests each. Let's write it down!")
l("write.intro.feast",S,"Twelve treats shared on three plates. Let's write it down!")
l("write.intro.moon",S,"Half of eight moonstones is four. Let's write it down!")
l("write.tap",S,"Tap the tiles in order, from left to right.")
l("write.hint",S,"Look at the picture. Which one comes next?")
l("write.flip",S,"Now let's start with the answer. It means the same thing!")
l("write.balance",S,"Both sides are the same, so the scale is level. That's what equals means.")
l("write.done",S,"That's how we write it with numbers!")
l("write.scroll",S,"A new puzzle scroll is waiting on the Puzzle Board!")
# F3: the Puzzle Board.
l("board.intro",S,"Welcome to the Puzzle Board! Every puzzle you solve lights a lantern.")
l("board.pickOp",S,"Which sign do we need? Tap it.")
l("board.pickSign",S,"Which sign makes it true? Tap it.")
l("board.wrongOp",S,"Hmm, think about the story. Are we putting together, taking away, making groups, or sharing?")
l("board.showOp.add",S,"We put them together. That's plus!")
l("board.showOp.subtract",S,"We take some away. That's minus!")
l("board.showOp.multiply",S,"We make equal groups. That's times!")
l("board.showOp.divide",S,"We share them fairly. That's divided by!")
l("board.pickTool",S,"How will you solve it? Pick a helper.")
l("board.ask",S,"What's the answer?")
l("board.light",S,"You did it! Another lantern is shining.")
l("board.story.add",N,"{a} flowers are blooming. Then {b} more flowers open. How many flowers now?")
l("board.story.subtract",N,"Grub has {a} gems. Grub gives away {b} gems. How many are left?")
l("board.story.multiply",N,"There are {a} tables. Each table has {b} guests. How many guests?")
l("board.story.divide",N,"There are {a} cupcakes. We share them on {b} plates. How many on each plate?")
l("board.make",S,"Make a puzzle for me! Pick two numbers and a sign.")
l("board.make.answer",S,"Hmm, let me think. I think it's {n}! Am I right?")
l("board.make.right",S,"Yes! You checked my work. Thank you!")
l("board.make.caught",S,"You caught my mistake! The answer is {n}.")
l("board.make.missed",S,"Oops, I made a mistake. The answer is really {n}.")
l("board.make.wrongCheck",S,"Let's look again. I was right this time. It is {n}!")
# F2 and F4: puzzle scrolls.
l("sheet.intro",S,"Here is your puzzle scroll! Write the number with your finger, or tap the numbers.")
l("sheet.item.picture",S,"Look at the picture. What goes in the box?")
l("sheet.item.sentence",S,"What number goes in the box?")
l("sheet.item.missing",S,"One number is missing. Which one?")
l("sheet.item.answerFirst",S,"Here the answer comes first. What goes in the box?")
l("sheet.item.missingSign",S,"Which sign makes it true?")
l("sheet.item.count",S,"How many? Write the number.")
l("sheet.right",S,"Yes!")
l("sheet.tryAgain",S,"Not quite. Try once more!")
l("sheet.show",S,"Here's the answer. Let's look at it together.")
l("sheet.unreadable",S,"I couldn't read that. Write it again, or tap the numbers.")
l("sheet.drawIt",S,"Draw a picture of this puzzle. Tap done when you finish.")
# Home School hub (#30): one quiet hello per launch.
l("home.hello",S,"Hi! What shall we play today?")
# Jigsaw widget (#25, J7: quiet by default; speech only for a one-time intro, hints and the explain moment).
l("jig.intro.picture",S,"Drag each piece to where it belongs in the picture. Flat edges go around the outside.")
l("jig.intro.turning",S,"Some pieces are turned around. Tap a piece to turn it.")
l("jig.hint.edges",S,"Look for a piece with a flat edge. Flat edges go around the outside.")
l("jig.hint.colour",S,"Look at the colours on the piece. Where are those colours in the picture?")
l("jig.hint.turn",S,"Tap the piece to turn it. Stop when the picture is the right way up.")
l("jig.hint.area",S,"It goes somewhere in the glowing part.")
l("jig.hint.outline",S,"Here is its outline. Can you fit it in?")
l("jig.hint.slide",S,"Watch where it goes. Then try the next one!")
l("jig.explain",S,"How did you find that one? Tap the picture.")
l("jig.explain.colour",S,"You matched the colours. Smart looking!")
l("jig.explain.edge",S,"You looked at the edge shape. That's a great way!")
l("jig.explain.picture",S,"You followed the picture. Nice!")
l("jig.explain.turn",S,"You turned it until it fit. Good thinking!")
l("jig.slip.ask",S,"Let me try one! Does my piece fit here?")
l("jig.slip.why",S,"Why doesn't it fit? Tap the picture.")
l("jig.slip.caught",S,"You're right! It doesn't fit. Thank you for checking my work.")
l("jig.slip.missed",S,"Hmm, look again. The edges don't match, so it doesn't fit. Good thing we checked!")
# Cup shuffle widget (#27, docs/features/cup-shuffle.md). Quiet (C6): the tutorial, the intro and the miss line only.
l("cup.intro",S,"Watch the cup with the bird. When the cups stop, tap the one it's under.")
l("cup.tut.hide",S,"A little bird is hiding under a cup.")
l("cup.tut.watch",S,"Watch its cup move.")
l("cup.tut.tap",S,"Tap the cup with the bird!")
l("cup.tut.point",S,"The bird is under this cup. Tap it!")
l("cup.tut.done",S,"You found it! Now you try.")
l("cup.miss",S,"Here it is! Keep your eyes on its cup.")
l("sheet.make",S,"Now make a puzzle for me!")
l("sheet.done",S,"You finished the scroll! Show it to a grown-up.")
# The companion is chosen at setup: lines name it with {companion}, never "Sparkle" or "unicorn" (charter v1.3).
for v in L.values():
    v["text"] = v["text"].replace("Sparkle", "{companion}")
content = dict(skills=skills, chapters=chapters, scenes=scenes, lines=L)
json.dump(content, open(os.path.join(ROOT, "Sources/KingdomCore/Resources/content.json"), "w"), indent=1)
print(len(skills), "skills,", len(scenes), "scenes,", sum(len(x["items"]) for x in scenes), "items,", len(L), "lines")
