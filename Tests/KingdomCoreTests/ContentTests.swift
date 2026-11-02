import XCTest
@testable import KingdomCore

/// Content checks (AC-A1, AC-A7) and spoken-line resolution.
final class ContentTests: XCTestCase {
    let content = T.content()
    var catalog: LineCatalog { LineCatalog(lines: content.lines) }

    func testBundledContentIsValid() {
        XCTAssertEqual(content.validationErrors(), [])
    }

    func testMVPScenes() {
        XCTAssertEqual(content.chapter("prologue")?.scenes, ["P0", "P1", "P2"])
        XCTAssertEqual(content.chapter("garden")?.scenes, ["G1", "G2", "G3", "G4", "G5"])
    }

    func testEveryItemHasPromptHintsAndPraiseAtEveryLevel() {
        for item in content.scenes.flatMap(\.items) {
            for level in CPALevel.allCases {
                XCTAssertNotNil(catalog.prompt(for: item, level: level), "\(item.id) \(level)")
                for stage in [HintStage.modelHint, .workedStep, .showAnswer] {
                    XCTAssertNotNil(catalog.hint(stage, for: item, level: level), "\(item.id) \(stage)")
                }
                XCTAssertNotNil(catalog.praise(for: item, level: level, variant: 0))
                XCTAssertNotNil(catalog.praise(for: item, level: level, variant: 1))
            }
        }
    }

    func testNoUnfilledPlaceholdersInItemLines() {
        for item in content.scenes.flatMap(\.items) {
            for level in CPALevel.allCases {
                let lines = [catalog.prompt(for: item, level: level), catalog.hint(.workedStep, for: item, level: level),
                             catalog.hint(.showAnswer, for: item, level: level), catalog.praise(for: item, level: level, variant: 0)]
                for l in lines.compactMap({ $0 }) {
                    XCTAssertFalse(l.text.contains("{"), "\(l.id) for \(item.id): \(l.text)")
                }
            }
        }
    }

    func testNumberNamesZeroToTen() {
        for n in 0...10 { XCTAssertNotNil(content.lines["number.\(n)"], "number.\(n)") }
        XCTAssertEqual(catalog.number(3)?.text, "Three")
    }

    // AC-A7
    func testHeroineIsSiaraAndBothVoicesAreUsed() {
        let speakers = Set(content.lines.values.map(\.speaker))
        XCTAssertEqual(speakers, [.narrator, .sparkle])
        XCTAssertTrue(content.lines.values.contains { $0.text.contains("Siara") })
        XCTAssertFalse(content.lines.values.contains { $0.text.lowercased().contains("princess name") })
    }

    func testPlaceholdersAreFilled() {
        let item = Item(id: "x", skill: "lineAdd", kind: .hop, a: 4, b: 3)
        XCTAssertEqual(catalog.prompt(for: item, level: .concrete)?.text,
                       "I'm on 4. I'll hop 3 times. Count my hops with me! Where will I land?")
        XCTAssertEqual(catalog.hint(.showAnswer, for: item, level: .concrete)?.text.hasPrefix("It's 7!"), true)
    }

    func testLevelSpecificPromptWins() {
        let item = Item(id: "x", skill: "add", kind: .addMore, a: 3, b: 2)
        XCTAssertEqual(catalog.prompt(for: item, level: .concrete)?.id, "prompt.addMore.concrete")
        XCTAssertEqual(catalog.prompt(for: item, level: .pictorial)?.id, "prompt.addMore.pictorial")
        XCTAssertEqual(catalog.prompt(for: item, level: .abstract)?.id, "prompt.addMore")
    }

    func testHeroNameCanChange() {
        let c = LineCatalog(lines: content.lines, heroName: "Maya")
        XCTAssertEqual(c.spoken("castle.back")?.text.contains("Maya"), true)
    }

    /// Shrikant: her name is said only in the castle welcome when the app opens.
    func testNameOnlyInCastleWelcome() {
        let named = content.lines.filter { $0.value.text.contains("Siara") }.map(\.key).sorted()
        XCTAssertEqual(named, ["castle.back", "castle.first"])
    }

    func testAnswers() {
        XCTAssertEqual(Item(id: "a", skill: "s", kind: .addMore, a: 3, b: 2).answer, 5)
        XCTAssertEqual(Item(id: "a", skill: "s", kind: .numberBond, a: 5, b: 2).answer, 3)
        XCTAssertEqual(Item(id: "a", skill: "s", kind: .makeTen, a: 7).answer, 3)
        XCTAssertEqual(Item(id: "a", skill: "s", kind: .hop, a: 4, b: 3).answer, 7)
        XCTAssertEqual(Item(id: "a", skill: "s", kind: .countTap, a: 5).answer, 5)
    }

    func testChoicesHoldAnswerAreDistinctAndInRange() {
        for item in content.scenes.flatMap(\.items) where !item.answersOnLine {
            let c = ActivityRules.choices(for: item)
            XCTAssertTrue(c.contains(item.answer), item.id)
            XCTAssertEqual(c.count, 4, item.id)
            XCTAssertEqual(Set(c).count, c.count, item.id)
            XCTAssertTrue(c.allSatisfy { $0 >= 0 && $0 <= item.top }, item.id)
            XCTAssertEqual(c, c.sorted())
            XCTAssertEqual(c, ActivityRules.choices(for: item), "stable")
        }
    }

    func testCountingChoicesNeverOfferZero() {
        let item = Item(id: "q-1", skill: "subitize", kind: .quickLook, a: 1)
        XCTAssertFalse(ActivityRules.choices(for: item).contains(0))
    }

    // L13: a scene has 8 items at most and no more than 3 of a kind in a row; the Prologue spreads its numbers.
    func testScenesAreNeverMundane() {
        for s in content.scenes {
            XCTAssertLessThanOrEqual(s.items.count, 8, s.id)
        }
        for id in ["P0", "P1", "P2"] {
            let items = content.scene(id)!.items
            var run = 1
            for i in 1..<items.count {
                run = items[i].kind == items[i - 1].kind ? run + 1 : 1
                XCTAssertLessThanOrEqual(run, 3, id)
            }
        }
        let counts = content.items(in: "prologue").filter { $0.kind != .quickLook }.map(\.answer)
        XCTAssertGreaterThanOrEqual(counts.max() ?? 0, 10, "wide number range")
        XCTAssertLessThanOrEqual(content.items(in: "prologue").count, 20, "short Prologue")
    }

    // L12: the challenge covers every Prologue skill.
    func testChallengeCoversEveryPrologueSkill() {
        let p0 = content.scene("P0")!
        XCTAssertTrue(p0.isChallenge)
        XCTAssertEqual(Set(p0.items.map(\.skill)), Set(content.skills(in: "prologue").map(\.id)))
        XCTAssertTrue((3...5).contains(p0.items.count))
    }

    // Item 8: full how-to twice per scene, then the short form; the short form keeps the numbers.
    func testShortPromptAfterTwo() {
        let item = Item(id: "x", skill: "add", kind: .addMore, a: 3, b: 2)
        XCTAssertEqual(catalog.prompt(for: item, level: .concrete, timesAsked: 1)?.id, "prompt.addMore.concrete")
        let short = catalog.prompt(for: item, level: .concrete, timesAsked: 2)
        XCTAssertEqual(short?.id, "prompt.addMore.concrete.short")
        XCTAssertEqual(short?.text, "3 flowers. Plant 2 more.")
        // Kinds without a short form keep the full prompt.
        let eq = Item(id: "y", skill: "add", kind: .equation, a: 3, b: 4)
        XCTAssertNotNil(catalog.prompt(for: eq, level: .abstract, timesAsked: 5))
    }

    // Item 17: G2 and G4 ask their question once at the concrete level (after the hands-on step).
    func testConcreteBondAndMakeTenDoNotAskTwice() {
        for kind in [ActivityKind.numberBond, .makeTen] {
            let item = Item(id: "x", skill: "s", kind: kind, a: 5, b: 2)
            XCTAssertFalse(catalog.prompt(for: item, level: .concrete)!.text.contains("?"), kind.rawValue)
        }
    }

    // Item 12: no fraction words before fractions are taught (M1 praise).
    func testPartsPraiseHasNoFractionWords() {
        XCTAssertFalse(content.lines["praise.parts"]!.text.lowercased().contains("fraction"))
    }

    func testEverySkillHasAHomeTip() {
        for s in content.skills { XCTAssertFalse(s.homeTip.isEmpty, s.id) }
    }

    func testEverySkillHasItems() {
        let used = Set(content.scenes.flatMap(\.items).map(\.skill))
        for s in content.skills { XCTAssertTrue(used.contains(s.id), s.id) }
    }
}

/// Answer rules and concrete steps for the activity kinds added after the MVP.
final class ActivityKindTests: XCTestCase {
    func item(_ kind: ActivityKind, _ a: Int, _ b: Int, max: Int? = 20) -> Item {
        Item(id: "t", skill: "s", kind: kind, a: a, b: b, max: max)
    }

    func testChapter2Answers() {
        XCTAssertEqual(item(.tensOnes, 1, 3).answer, 13)
        XCTAssertEqual(item(.tensOnes, 2, 0).answer, 20)
        XCTAssertEqual(item(.bridgeAdd, 8, 5).answer, 13)
        XCTAssertEqual(item(.findOnLine, 17, 0).answer, 17)
        XCTAssertEqual(item(.hop, 12, 4).answer, 16)
    }

    func testLaterChapterAnswers() {
        XCTAssertEqual(item(.takeAway, 9, 4).answer, 5)
        XCTAssertEqual(item(.hopBack, 15, 6).answer, 9)
        XCTAssertEqual(item(.compare, 8, 5).answer, 3)
        XCTAssertEqual(item(.subtraction, 14, 6).answer, 8)
        XCTAssertEqual(item(.groups, 3, 4).answer, 12)
        XCTAssertEqual(item(.array, 4, 5).answer, 20)
        XCTAssertEqual(item(.skipHop, 3, 5).answer, 15)
        XCTAssertEqual(item(.multiply, 2, 6).answer, 12)
        XCTAssertEqual(item(.share, 12, 3).answer, 4)
        XCTAssertEqual(item(.groupInto, 15, 5).answer, 3)
        XCTAssertEqual(item(.divide, 18, 2).answer, 9)
        XCTAssertEqual(item(.parts, 0, 4).answer, 4)
        XCTAssertEqual(item(.fractionLine, 3, 4, max: 4).answer, 3)
        XCTAssertEqual(item(.fractionOf, 12, 4).answer, 3)
    }

    func testConcreteSteps() {
        XCTAssertEqual(item(.countTap, 5, 0).concreteStep, .tap(5, answers: true))
        XCTAssertEqual(item(.tensOnes, 1, 6).concreteStep, .tap(6, answers: false))
        XCTAssertEqual(item(.bridgeAdd, 8, 5).concreteStep, .place(5))
        XCTAssertEqual(item(.makeTen, 7, 0, max: nil).concreteStep, .place(3))
        XCTAssertEqual(item(.hopBack, 15, 6).concreteStep, .hop(6))
        XCTAssertEqual(item(.skipHop, 3, 5).concreteStep, .hop(3))
        XCTAssertEqual(item(.groups, 3, 4).concreteStep, .tap(12, answers: false))
        XCTAssertEqual(item(.array, 4, 5).concreteStep, .tap(4, answers: false))
        XCTAssertEqual(item(.share, 12, 3).concreteStep, .place(12))
        XCTAssertEqual(item(.howMany, 4, 0).concreteStep, .none)
        XCTAssertEqual(item(.fractionLine, 1, 2, max: 2).concreteStep, .none)
    }

    func testLineKinds() {
        for k in [ActivityKind.findOnLine, .hop, .hopBack, .skipHop, .fractionLine] {
            XCTAssertTrue(item(k, 1, 1).answersOnLine, k.rawValue)
        }
        XCTAssertFalse(item(.share, 4, 2).answersOnLine)
    }

    func testOperatorSymbols() {
        XCTAssertEqual(item(.subtraction, 9, 3).operatorSymbol, "−")
        XCTAssertEqual(item(.multiply, 2, 3).operatorSymbol, "×")
        XCTAssertEqual(item(.divide, 6, 3).operatorSymbol, "÷")
        XCTAssertEqual(item(.bridgeAdd, 8, 5).operatorSymbol, "+")
    }

    func testValidationCatchesBadItems() {
        let bad = [
            item(.share, 7, 2),               // does not divide evenly
            item(.takeAway, 3, 5),            // below zero
            item(.fractionLine, 1, 4, max: 3) // line must have b steps
        ]
        let content = Content(
            skills: [Skill(id: "s", chapter: "c", name: "S", homeTip: "tip")],
            chapters: [Chapter(id: "c", title: "C", place: "P", scenes: ["X"])],
            scenes: [StoryScene(id: "X", chapter: "c", title: "X", open: [], warmupCount: 0,
                                items: bad.enumerated().map { Item(id: "i\($0.offset)", skill: "s", kind: $0.element.kind,
                                                                   a: $0.element.a, b: $0.element.b, max: $0.element.max) },
                                payoff: [], goodbye: "g")],
            lines: ["g": Line(speaker: .sparkle, text: "bye"),
                    "prompt.share": Line(speaker: .sparkle, text: "p"),
                    "prompt.takeAway": Line(speaker: .sparkle, text: "p"),
                    "prompt.fractionLine": Line(speaker: .sparkle, text: "p")]
        )
        let errors = content.validationErrors().joined(separator: "\n")
        XCTAssertTrue(errors.contains("does not divide evenly"), errors)
        XCTAssertTrue(errors.contains("below zero"), errors)
        XCTAssertTrue(errors.contains("needs max == b"), errors)
    }

    func testChapter2Content() {
        let c = T.content()
        XCTAssertEqual(c.chapter("bridge")?.scenes, ["B1", "B2", "B3", "B4", "B5"])
        XCTAssertEqual(c.skills(in: "bridge").count, 4)
        for i in c.items(in: "bridge") { XCTAssertEqual(i.top, 20, i.id) }
        // AC-2d and the skill map: locked until the Garden passes its gate.
        var s = LearnerState()
        T.completeScenes("prologue", in: &s, content: c)
        T.master("prologue", in: &s, content: c)
        T.completeScenes("garden", in: &s, content: c)
        let p = Progression(content: c, engine: T.engine)
        XCTAssertFalse(p.isChapterUnlocked("bridge", state: s))
        T.master("garden", in: &s, content: c)
        XCTAssertTrue(p.isChapterUnlocked("bridge", state: s))
        XCTAssertEqual(p.next(state: s), .scene("B1"))
    }
}

final class TeachingPraiseTests: XCTestCase {
    func testTeachingPraiseOnlyWhenAsked() throws {
        let content = try Content.bundled()
        let catalog = LineCatalog(lines: content.lines)
        let item = try XCTUnwrap(content.scenes.flatMap(\.items).first { $0.kind == .countTap })
        let taught = try XCTUnwrap(catalog.praise(for: item, level: .concrete, variant: 0, teach: true))
        XCTAssertTrue(taught.text.contains("last number"))
        for v in 0..<6 {
            let plain = try XCTUnwrap(catalog.praise(for: item, level: .concrete, variant: v, teach: false))
            XCTAssertFalse(plain.text.contains("last number"))
        }
    }
}

final class SentenceSplitTests: XCTestCase {
    func testLinesSplitIntoSentencesForPauses() {
        let line = SpokenLine(id: "x", speaker: .sparkle, text: "Five stars! The last number tells how many. Ready?")
        XCTAssertEqual(line.sentences.map(\.text), ["Five stars!", "The last number tells how many.", "Ready?"])
        XCTAssertEqual(SpokenLine(id: "n", speaker: .sparkle, text: "3.5 is fine").sentences.count, 1)
        XCTAssertEqual(SpokenLine(id: "y", speaker: .narrator, text: "Hello").sentences.map(\.text), ["Hello"])
    }
}
