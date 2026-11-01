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
        XCTAssertEqual(content.chapter("prologue")?.scenes, ["P1", "P2", "P3", "P4"])
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
        XCTAssertEqual(c.spoken("p1.goodbye")?.text.contains("Maya"), true)
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
        let item = Item(id: "p4-1", skill: "subitize", kind: .quickLook, a: 1)
        XCTAssertFalse(ActivityRules.choices(for: item).contains(0))
    }

    func testEverySkillHasAHomeTip() {
        for s in content.skills { XCTAssertFalse(s.homeTip.isEmpty, s.id) }
    }

    func testEverySkillHasItems() {
        let used = Set(content.scenes.flatMap(\.items).map(\.skill))
        for s in content.skills { XCTAssertTrue(used.contains(s.id), s.id) }
    }
}
