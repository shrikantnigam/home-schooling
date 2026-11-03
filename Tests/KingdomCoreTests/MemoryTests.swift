import XCTest
@testable import KingdomCore

/// The memory game (docs/features/memory.md, M1 to M10).
final class MemoryTests: XCTestCase {
    // M1, M2: ten characters; each level deals pairs inside its range.
    func testLevelsDealPairsInRange() {
        XCTAssertEqual(MemoryCharacter.allCases.count, 10)
        XCTAssertEqual(MemoryLevel.easy.pairRange, 3...4)
        XCTAssertEqual(MemoryLevel.medium.pairRange, 4...6)
        XCTAssertEqual(MemoryLevel.hard.pairRange, 6...8)
        for level in MemoryLevel.allCases {
            for pairs in 0...10 {
                let d = MemoryDeal(level: level, pairs: pairs, seed: UInt64(pairs + 1))
                XCTAssertTrue(level.pairRange.contains(d.pairs), "\(level) \(pairs)")
                XCTAssertEqual(d.cards.count, d.pairs * 2)
                let counts = Dictionary(grouping: d.cards, by: { $0 }).mapValues(\.count)
                XCTAssertTrue(counts.values.allSatisfy { $0 == 2 }, "two of each character")
                let g = MemoryLevel.grid(cards: d.cards.count)
                XCTAssertGreaterThanOrEqual(g.cols * g.rows, d.cards.count)
            }
        }
    }

    func testDealIsSeededAndMatches() {
        let a = MemoryDeal(level: .medium, pairs: 5, seed: 42)
        XCTAssertEqual(a, MemoryDeal(level: .medium, pairs: 5, seed: 42))
        XCTAssertNotEqual(a.cards, MemoryDeal(level: .medium, pairs: 5, seed: 43).cards)
        let i = 0
        let j = a.cards.indices.first { $0 != i && a.cards[$0] == a.cards[i] }!
        XCTAssertTrue(a.isMatch(i, j))
        XCTAssertFalse(a.isMatch(i, i))
    }

    // M3: Medium opens after an Easy game, Hard after a Medium one.
    func testLevelsOpenInOrder() {
        var m = MemoryRecord()
        XCTAssertEqual(MemoryLevel.allCases.map(m.isOpen), [true, false, false])
        m.finish(MemoryResult(level: .easy, pairs: 3, tries: 9, date: Date()))
        XCTAssertEqual(MemoryLevel.allCases.map(m.isOpen), [true, true, false])
        m.finish(MemoryResult(level: .medium, pairs: 4, tries: 12, date: Date()))
        XCTAssertEqual(MemoryLevel.allCases.map(m.isOpen), [true, true, true])
    }

    // M4, M5: start small; an easy game adds a pair (up to the top), a very hard one takes one away.
    func testSizeGrowsWithinLevel() {
        var m = MemoryRecord()
        XCTAssertEqual(m.pairs(for: .easy), 3)
        m.finish(MemoryResult(level: .easy, pairs: 3, tries: 5, date: Date()))
        XCTAssertEqual(m.pairs(for: .easy), 4)
        m.finish(MemoryResult(level: .easy, pairs: 4, tries: 6, date: Date()))
        XCTAssertEqual(m.pairs(for: .easy), 4, "never above the level's top")
        m.finish(MemoryResult(level: .easy, pairs: 4, tries: 20, date: Date()))
        XCTAssertEqual(m.pairs(for: .easy), 3)
        XCTAssertEqual(m.pairs(for: .hard), 6)
    }

    func testOldSaveHasNoMemoryRecord() throws {
        let data = try JSONEncoder().encode(LearnerState())
        var obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        obj.removeValue(forKey: "memory")
        let s = try JSONDecoder().decode(LearnerState.self, from: JSONSerialization.data(withJSONObject: obj))
        XCTAssertEqual(s.memory, MemoryRecord())
    }
}
