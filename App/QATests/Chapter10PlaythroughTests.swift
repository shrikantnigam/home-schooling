import XCTest

/// QA play-through for the memory game (docs/features/memory.md, rules M1 to M10).
/// Each card's QA value reads "<character>;<down|up|matched>"; the board's reads "found=<k>/<n>;tries=<t>".
final class Chapter10PlaythroughTests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    /// M2, M3, M6: the memory tile opens the level chooser. Easy is open at 3 pairs; Medium and Hard are locked,
    /// and a locked level doesn't start a game.
    func test01_Levels_LockedUntilEarned() {
        let p = QAPlayer(self, prefix: "c10-01")
        p.launch()
        p.tap("home.widget.memory")
        XCTAssertEqual(p.wait("memory.level.easy").value as? String, "open;pairs=3")
        XCTAssertEqual(p.el("memory.level.medium").value as? String, "locked")
        XCTAssertEqual(p.el("memory.level.hard").value as? String, "locked")
        p.snap("memory levels")
        p.tap("memory.level.medium")
        XCTAssertFalse(p.el("memory.board").exists, "a locked level doesn't start a game")
    }

    /// M4, M7: an Easy game of 3 pairs. Two different cards turn back; a pair stays up; the last pair ends the
    /// game with Next. After it, Medium is open and Easy grows to 4 pairs.
    func test02_EasyGame_MissThenFindAll() {
        let p = QAPlayer(self, prefix: "c10-02")
        p.launch()
        p.tap("home.widget.memory")
        p.tap("memory.level.easy")
        p.wait("memory.board")
        let cards = characters(p)
        XCTAssertEqual(cards.count, 6, "Easy starts with 3 pairs")
        p.metric("taps-home-to-first-card", p.taps, resetTaps: true)
        p.snap("six cards face down")
        // A miss: two different characters.
        let a = 0
        let b = cards.indices.first { cards[$0] != cards[a] }!
        p.tap("memory.card.\(a)")
        p.tap("memory.card.\(b)")
        p.snap("two different cards")
        waitFor(p, "memory.card.\(a)", suffix: ";down")
        waitFor(p, "memory.card.\(b)", suffix: ";down")
        // Now every pair.
        var done: Set<Int> = []
        for i in cards.indices where !done.contains(i) {
            let j = cards.indices.first { $0 != i && cards[$0] == cards[i] }!
            p.tap("memory.card.\(i)")
            p.tap("memory.card.\(j)")
            done.formUnion([i, j])
            waitFor(p, "memory.card.\(j)", suffix: ";matched")
        }
        XCTAssertEqual(p.el("memory.board").value as? String, "found=3/3;tries=4")
        p.metric("taps-per-game", p.taps)
        p.wait("next")
        p.snap("all pairs found")
        p.tap("memory.change")
        XCTAssertEqual(p.wait("memory.level.medium").value as? String, "open;pairs=4", "Medium opens after Easy")
        XCTAssertEqual(p.el("memory.level.easy").value as? String, "open;pairs=4", "a good game adds a pair")
        p.snap("medium open")
    }

    /// M2: a Medium game deals 4 to 6 pairs; Next starts a new deal.
    func test03_MediumGame_Deals() {
        let p = QAPlayer(self, prefix: "c10-03")
        p.launch(preset: "memoryEasyDone")
        p.tap("home.widget.memory")
        p.tap("memory.level.medium")
        p.wait("memory.board")
        let cards = characters(p)
        XCTAssertTrue((8...12).contains(cards.count), "Medium has 8 to 12 cards, got \(cards.count)")
        XCTAssertEqual(Set(cards).count * 2, cards.count, "two of each character")
        p.snap("medium game")
    }

    /// M9: the parent dashboard's Memory page.
    func test04_ParentPage() {
        let p = QAPlayer(self, prefix: "c10-04")
        p.launch(preset: "memoryEasyDone")
        p.openParentArea()
        p.tap("parent.tab.memory")
        p.wait("parent.memory.recent")
        p.wait("parent.memory.homeIdea")
        p.snap("parent dashboard memory page")
    }

    // MARK: Helpers

    private func characters(_ p: QAPlayer) -> [String] {
        var out: [String] = []
        var i = 0
        while p.el("memory.card.\(i)").exists {
            out.append(((p.el("memory.card.\(i)").value as? String) ?? "").split(separator: ";").first.map(String.init) ?? "")
            i += 1
        }
        return out
    }

    private func waitFor(_ p: QAPlayer, _ id: String, suffix: String, timeout: TimeInterval = 5,
                         file: StaticString = #filePath, line: UInt = #line) {
        let end = Date().addingTimeInterval(timeout)
        while Date() < end {
            if ((p.el(id).value as? String) ?? "").hasSuffix(suffix) { return }
            Thread.sleep(forTimeInterval: 0.2)
        }
        p.snap("FAILED waiting for \(id) \(suffix)")
        XCTFail("\(id) never showed \(suffix); it shows \(p.el(id).value ?? "nil")", file: file, line: line)
    }
}
