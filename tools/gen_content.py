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
chapters = [
 dict(id="prologue", title="Counting Stars", place="Night Sky", scenes=["P1","P2","P3","P4"]),
 dict(id="garden", title="The Flower Garden", place="Flower Garden", scenes=["G1","G2","G3","G4","G5"]),
]
def sc(id, ch, title, warm, items, payoff):
    return dict(id=id, chapter=ch, title=title, open=[f"{id.lower()}.open1", f"{id.lower()}.open2"], warmupCount=warm,
                items=items, payoff=payoff, goodbye=f"{id.lower()}.goodbye")
scenes = [
 sc("P1","prologue","Meet Sparkle",0,[it("p1-3","count","countTap",3),it("p1-4","count","countTap",4),it("p1-5","count","countTap",5),it("p1-2","count","countTap",2),it("p1-5b","count","countTap",5)],["p1.payoff"]),
 sc("P2","prologue","How many?",2,[it("p2-4","cardinality","howMany",4),it("p2-6","cardinality","howMany",6),it("p2-3","cardinality","howMany",3),it("p2-7c","count","countTap",7),it("p2-7","cardinality","howMany",7),it("p2-5","cardinality","howMany",5),it("p2-9c","count","countTap",9),it("p2-8","cardinality","howMany",8)],["p2.payoff"]),
 sc("P3","prologue","Star Path",2,[it("p3-4","lineFind","findOnLine",4),it("p3-2","lineFind","findOnLine",2),it("p3-7","lineFind","findOnLine",7),it("p3-5","lineFind","findOnLine",5),it("p3-9","lineFind","findOnLine",9),it("p3-6","lineFind","findOnLine",6),it("p3-10","lineFind","findOnLine",10)],["p3.payoff"]),
 sc("P4","prologue","Quick Look",2,[it("p4-3","subitize","quickLook",3),it("p4-2","subitize","quickLook",2),it("p4-5","subitize","quickLook",5),it("p4-1","subitize","quickLook",1),it("p4-4","subitize","quickLook",4),it("p4-3b","subitize","quickLook",3)],["p4.payoff1","p4.payoff2"]),
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
l("map.gardenAwake",S,"The garden is awake now! Let's plant flowers.")
l("map.practice",S,"The garden wants a little more practice. Tap the glowing flowers!")
l("map.done",S,"You helped the whole kingdom so far! Want to visit a place again?")
l("sleeping",N,"Sparkle is sleeping. She'll be ready to play tomorrow.")
l("quiet",N,"Sparkle is resting now. Let's play together another time.")
l("warmup.intro",S,"Let's warm up with something we did before!")
l("core.intro",S,"Now let's help the kingdom!")
l("wrapup",S,"That was a lot of great thinking. Let's finish our story for today.")
# scenes
l("p1.open1",N,"Once upon a time, in the Kingdom of Numbers, the night sky went dark.")
l("p1.open2",S,"Hi, I'm Sparkle! Oh no, the stars fell asleep. Will you help me wake them up?")
l("p1.payoff",S,"Five stars! The last number tells how many. Look, the sky is starting to glow!")
l("p1.goodbye",S,"Today you learned to count each star just once. Goodnight!")
l("p2.open1",N,"The stars are waking up, but some are hiding in the clouds.")
l("p2.open2",S,"Let's find out how many stars are in each cloud!")
l("p2.payoff",S,"You found every star in the clouds! The sky is getting brighter.")
l("p2.goodbye",S,"Today you learned that the last number you say tells how many. Goodnight!")
l("p3.open1",N,"Sparkle wants to walk across the sky on a path of star stones.")
l("p3.open2",S,"Every stone has a number. Will you show me where to hop?")
l("p3.payoff",S,"We crossed the whole star path! Every number has its own place.")
l("p3.goodbye",S,"Today you learned where numbers live on the line. Goodnight!")
l("p4.open1",N,"The last stars are very shy. They only peek out for a moment.")
l("p4.open2",S,"Look quickly, and tell me how many stars you see!")
l("p4.payoff1",S,"You counted every star back into the sky!")
l("p4.payoff2",S,"Look, the kingdom map is glowing. Today you learned that the last number you say tells how many.")
l("p4.goodbye",S,"Goodnight! Tomorrow we can visit the garden.")
l("g1.open1",N,"Morning came to the kingdom, but the flower garden was still asleep.")
l("g1.open2",S,"I can't find the path through the garden. Can we plant some flowers?")
l("g1.payoff",S,"Look at all the flowers! I can see the start of the path.")
l("g1.goodbye",S,"Today you learned that adding means putting more together. Goodnight!")
l("g2.open1",N,"The garden bees have two flower beds, and they want flowers in both.")
l("g2.open2",S,"Let's share the flowers between the beds in different ways!")
l("g2.payoff",S,"The bees are buzzing happily in both beds!")
l("g2.goodbye",S,"Today you learned that a number can be split into two parts in many ways. Goodnight!")
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
l("practice.open1",N,"Sparkle wants to play in the garden a little more.")
l("practice.open2",S,"Let's practice together. Practice makes our brains strong!")
l("practice.short",S,"Let's practice!")
l("practice.payoff",S,"You worked so hard! The flowers are standing up tall.")
l("practice.goodbye",S,"Thank you for practicing with me. Goodnight!")
# prompts
l("prompt.countTap.concrete",S,"Tap each star to wake it up. Let's count together.")
l("prompt.countTap",S,"How many stars are there? Touch a number to hear it. Touch it again to choose.")
l("prompt.howMany.concrete",S,"How many stars are in the cloud? Tap each star to count it, then touch a number. Touch it again to choose.")
l("prompt.howMany",S,"How many stars are in the cloud? Touch a number to hear it. Touch it again to choose.")
l("prompt.findOnLine",S,"Can you help me hop to {a}? Tap the stone where {a} lives.")
l("prompt.quickLook",S,"Look quickly! How many stars did you see? Touch a number, then touch it again to choose.")
l("prompt.addMore.concrete",S,"{a} flowers are awake. Let's plant {b} more seeds so I can find the path. Drag a seed into the flower box.")
l("ask.addMore",S,"How many flowers are there now?")
l("ask.makeTen",S,"The box is full! How many seeds did we plant to make ten?")
l("ask.numberBond",S,"How many flowers are in the other bed now?")
l("prompt.addMore.pictorial",S,"{a} flowers are awake, and {b} more just bloomed. How many flowers are there now?")
l("prompt.addMore",S,"{a} flowers and {b} more. How many flowers?")
l("prompt.numberBond",S,"The bees want flowers in both beds. We have {a} flowers, and this bed has {b}. How many go in the other bed?")
l("prompt.hop",S,"I'm on {a}. I'll hop {b} times. Count my hops with me! Where will I land?")
l("prompt.makeTen",S,"The fountain wakes up when the box has ten flowers. We have {a}. How many more do we need?")
l("prompt.equation",S,"{a} plus {b}. If you want help, tap the flower box or the hopping path.")
# hints
l("hint.model",S,"Hmm, not quite. Let's look again. Touch each one and count.")
l("hint.model.addMore",S,"Hmm, not quite. Let's count them together. Touch each flower.")
l("hint.model.makeTen",S,"Hmm, not quite. Look at the empty spots in the box. Each empty spot needs a flower.")
l("hint.model.hop",S,"Hmm, not quite. Let's hop again, one stone for each horseshoe.")
l("hint.model.findOnLine",S,"Hmm, not quite. Let's start at zero and count the stones.")
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
content = dict(skills=skills, chapters=chapters, scenes=scenes, lines=L)
json.dump(content, open(os.path.join(ROOT, "Sources/KingdomCore/Resources/content.json"), "w"), indent=1)
print(len(skills), "skills,", len(scenes), "scenes,", sum(len(x["items"]) for x in scenes), "items,", len(L), "lines")
