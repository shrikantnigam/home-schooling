import XCTest

/// QA play-through for the problem-solving bridge (docs/features/problem-solving.md):
/// Write it down, the Puzzle Board, making a puzzle, a puzzle scroll and the grown-ups' feedback.
final class Kingdom7QATests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    /// AC-W1 to AC-W5: the Garden's two sentences, one wrong tile, the balance levels, then the board opens.
    func test01_WriteItDown_Garden() {
        let p = QAPlayer(self, prefix: "c7-01")
        p.launch(preset: "writeItDown.garden")
        p.wait("write.title.garden", timeout: 10)
        p.wait("write.sentence.0")
        p.snap("write it down open")
        // A wrong tile first: nothing is marked wrong, the slot stays empty.
        p.tap("write.tile.4")
        XCTAssertEqual(p.el("write.slot.0").value as? String, "empty")
        for t in ["6", "+", "4"] { p.tap("write.tile.\(t)") }
        XCTAssertEqual(p.el("write.sentence.0").value as? String, "right side empty")
        p.snap("left side filled, balance tips")
        for t in ["=", "10"] { p.tap("write.tile.\(t)") }
        // QA speech is quick, so the next sentence may already be up; either way the first one balanced.
        let s0 = p.el("write.sentence.0")
        if s0.exists { XCTAssertEqual(s0.value as? String, "balanced") }
        p.snap("first sentence balanced")
        // The answer-first sentence (L16).
        p.wait("write.sentence.1", timeout: 25)
        p.snap("answer first sentence")
        for t in ["10", "=", "6", "+", "4"] { p.tap("write.tile.\(t)") }
        XCTAssertEqual(p.el("write.sentence.1").value as? String, "balanced")
        p.snap("second sentence balanced")
        p.tapNext()
        p.wait("castle.board", timeout: 10)
        p.snap("castle with the Puzzle Board")
    }

    /// AC-B1 to AC-B7: wrong sign then right, a helper, the answer, a lantern; puzzles until one reaches
    /// story level 3; then make two puzzles and catch the companion's mistake on the second.
    func test02_PuzzleBoard() {
        let p = QAPlayer(self, prefix: "c7-02")
        p.launch(preset: "boardReady")
        p.tap("castle.board")
        p.wait("board.puzzle", timeout: 10)
        XCTAssertEqual(p.el("board.lanterns").value as? String, "0")
        // Only taught signs can be tapped: division (the Feast) is not finished.
        XCTAssertFalse(p.wait("board.op.divide").isEnabled)
        p.snap("board open, level 1 story")

        var f = p.fields("board.puzzle")
        let op = f["op"] ?? ""
        let wrong = ["add", "subtract", "multiply"].first { $0 != op } ?? "add"
        p.tap("board.op.\(wrong)")
        XCTAssertEqual(p.fields("board.puzzle")["step"], "sign")
        p.snap("wrong sign: think about the story")
        p.tap("board.op.\(op)")
        p.wait("board.tool.counters")
        p.snap("pick a helper")
        p.tap("board.tool.line")
        p.wait("board.answer.\(f["answer"] ?? "0")")
        p.snap("number line helper, pick the answer")
        p.tap("board.answer.\(f["answer"] ?? "0")")
        XCTAssertEqual(p.fields("board.puzzle")["step"], "lit")
        XCTAssertEqual(p.el("board.lanterns").value as? String, "1")
        p.snap("lantern lit")
        p.tapNext()

        // First-try solves until a puzzle reaches level 3 (the bare sentence).
        var reached3 = false
        let tools = ["counters", "line", "head"]
        for k in 0..<30 {
            f = p.fields("board.puzzle")
            let level = f["level"] ?? "1"
            if level == "2" && k < 12 { p.snap("level 2: words, no picture") }
            p.tap("board.op.\(f["op"] ?? "")")
            if level == "3" {
                XCTAssertEqual(p.fields("board.puzzle")["step"], "lit")
                p.snap("level 3: bare sentence, sign only")
                reached3 = true
                break
            }
            p.tap("board.tool.\(tools[k % 3])")
            p.tap("board.answer.\(f["answer"] ?? "0")")
            p.tapNext()
        }
        XCTAssertTrue(reached3, "no puzzle reached story level 3")
        p.tapNext()

        // L15: make puzzles for the companion. The second one has a slip to catch.
        for round in 0..<2 {
            p.tap("board.make")
            p.wait("make.a.value")
            p.tap("make.a.up")
            p.tap("make.op.add")
            p.tap("make.ask")
            let c = p.fields("make.companion")
            p.snap("companion answers \(round)")
            if round == 1 { XCTAssertNotEqual(c["said"], c["right"], "the second made puzzle should have a slip") }
            p.tap(c["said"] == c["right"] ? "make.right" : "make.oops")
            p.snap("checked the companion \(round)")
            p.tap("make.done")
            p.wait("board.puzzle")
        }
    }

    /// AC-S1 to AC-S5: a place scroll answered with the keys (one wrong try), then the grown-up's feedback.
    func test03_ScrollAndFeedback() {
        let p = QAPlayer(self, prefix: "c7-03")
        p.launch(preset: "boardReady")
        p.tap("castle.board")
        guard let scroll = p.first("board.scroll.") else { return XCTFail("no scroll on the board") }
        let sheetID = String(scroll.identifier.dropFirst("board.scroll.".count))
        p.snap("board with scrolls")
        scroll.tap()
        p.wait("sheet.pad", timeout: 10)
        p.snap("scroll open")

        var wrongDone = false
        var last = ""
        for _ in 0..<20 {
            if p.el("sheet.finish").exists { break }
            // Wait for the next item to replace the last one.
            var ident = ""
            for _ in 0..<16 {
                ident = p.first("sheet.item.", timeout: 1)?.identifier ?? ""
                if !ident.isEmpty && ident != last { break }
                if p.el("sheet.finish").exists { break }
            }
            if p.el("sheet.finish").exists { break }
            guard !ident.isEmpty, ident != last else { return XCTFail("the scroll did not move on from \(last)") }
            last = ident
            let f = p.fields(ident)
            let kind = f["kind"] ?? ""
            let answer = f["answer"] ?? ""
            p.snap("item \(kind)")
            switch kind {
            case "drawIt":
                p.tap("sheet.drawDone")
            case "makePuzzle":
                p.tap("make.op.add")
                p.tap("make.ask")
                let c = p.fields("make.companion")
                p.tap(c["said"] == c["right"] ? "make.right" : "make.oops")
                p.tap("make.done")
            case "missingSign":
                p.tap("key.\(QAPlayer.opName(answer))")
            default:
                if !wrongDone, let n = Int(answer) {
                    // One wrong try: the box clears and she tries again.
                    // Same length as the answer, so it is checked as soon as it is typed.
                    let wrong = n % 10 == 0 ? n + 1 : n - 1
                    for ch in String(wrong) { p.tap("key.\(ch)") }
                    wrongDone = true
                    p.snap("wrong try")
                }
                for ch in answer { p.tap("key.\(ch)") }
            }
            p.snap("item \(kind) done")
            p.tapNext()
        }
        p.wait("sheet.finish", timeout: 10)
        p.snap("scroll finished")
        p.tap("sheet.finish")
        p.wait("board.scroll.\(sheetID)")
        XCTAssertEqual(p.el("board.scroll.\(sheetID)").value as? String, "done")

        p.openParentArea()
        p.tap("parent.tab.scrolls")
        p.tap("parent.sheet.\(sheetID).hard")
        XCTAssertEqual(p.el("parent.sheet.\(sheetID).hard").value as? String, "selected")
        p.snap("grown-up marks the scroll hard")
    }
}
