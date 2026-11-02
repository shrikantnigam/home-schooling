import XCTest
@testable import KingdomCore

/// Charter v1.5 (L14, L15, L16) and docs/features/problem-solving.md.
final class ProblemSolvingTests: XCTestCase {
    let content = T.content()
    var progression: Progression { Progression(content: content, engine: T.engine) }

    func finish(_ chapters: [ChapterID], in state: inout LearnerState) {
        for ch in chapters { for s in content.chapter(ch)?.scenes ?? [] { state.completedScenes.insert(s) } }
    }

    // AC-W2, L16: every place writes two sentences (one for the Night Sky), one of them answer-first, and
    // each sentence is true.
    func testWriteItDownForEveryPlace() {
        XCTAssertEqual(Set(WriteItDown.places), Set(content.chapters.map(\.id)), "one moment per place")
        for ch in WriteItDown.places {
            let w = WriteItDown.forPlace(ch)!
            XCTAssertTrue(w.sentences.contains { $0.isAnswerFirst } || ch == "prologue", ch)
            for s in w.sentences {
                XCTAssertNotNil(s.equalsIndex, "\(ch): has =")
                if let op = s.tokens.compactMap({ MathOp.from(sign: $0) }).first {
                    let nums = s.tokens.compactMap { Int($0) }
                    XCTAssertEqual(nums.count, 3, ch)
                    let result = s.isAnswerFirst ? nums[0] : nums[2]
                    let (a, b) = s.isAnswerFirst ? (nums[1], nums[2]) : (nums[0], nums[1])
                    XCTAssertEqual(op.apply(a, b), result, "\(ch): \(s.tokens)")
                    if ch != "bridge" { XCTAssertEqual(op.place, ch, "the sign belongs to the place") }
                }
            }
            for t in w.sentences.flatMap(\.tokens) { XCTAssertTrue(w.tiles.contains(t), "\(ch): tile \(t)") }
            XCTAssertTrue(w.tiles.contains(w.distractor))
        }
    }

    // AC-W2, AC-W3, AC-W4: tiles go in left to right; a wrong tile isn't placed; the balance levels when full.
    func testSlotFillerAndBalance() {
        var f = SlotFiller(WriteItDown.forPlace("garden")!.sentences[0])
        XCTAssertFalse(f.tap("4"), "6 comes first")
        XCTAssertTrue(f.tap("6"))
        XCTAssertTrue(f.tap("+"))
        XCTAssertFalse(f.leftDone)
        XCTAssertTrue(f.tap("4"))
        XCTAssertTrue(f.leftDone)
        XCTAssertFalse(f.balanced)
        XCTAssertTrue(f.tap("="))
        XCTAssertTrue(f.tap("10"))
        XCTAssertTrue(f.balanced)
        XCTAssertFalse(f.tap("10"), "nothing after the last slot")
    }

    // AC-B1: signs open with their places; numbers go to 20 after the Bridge.
    func testOperationsUnlockWithTheirPlaces() {
        var s = LearnerState()
        let maker = ProblemMaker(progression: progression)
        XCTAssertEqual(maker.unlocked(s), [])
        finish(["prologue", "garden"], in: &s)
        XCTAssertEqual(maker.unlocked(s), [.add])
        XCTAssertEqual(maker.top(s), 10)
        finish(["bridge", "goblin", "feast"], in: &s)
        XCTAssertEqual(maker.unlocked(s), [.add, .subtract, .divide])
        XCTAssertEqual(maker.top(s), 20)
    }

    // Every puzzle is a whole-number problem within range, and level 3 has only one sign that works (L14).
    func testPuzzlesAreFairAndLevelThreeIsUnambiguous() {
        for op in MathOp.allCases {
            for n in 0..<200 {
                let p = ProblemMaker.puzzle(op, level: 3, n: n, top: 20)
                XCTAssertNotNil(op.apply(p.a, p.b), "\(op) \(p.a) \(p.b)")
                XCTAssertLessThanOrEqual(p.a, 25)
                let others = MathOp.allCases.filter { $0 != op && $0.apply(p.a, p.b) == p.answer }
                XCTAssertTrue(others.isEmpty, "\(p.a) \(op.sign) \(p.b) = \(p.answer) also works with \(others)")
                XCTAssertTrue(p.choices.contains(p.answer))
                XCTAssertEqual(p.choices.count, 4)
            }
        }
    }

    // AC-B3: three first-try solves go up a level, two misses go down; every finished puzzle lights a lantern.
    func testStoryFadesUpAndDown() {
        var b = BoardRecord()
        XCTAssertEqual(b.level(.add), 1)
        for _ in 0..<3 { b.record(.add, firstTry: true) }
        XCTAssertEqual(b.level(.add), 2)
        for _ in 0..<3 { b.record(.add, firstTry: true) }
        XCTAssertEqual(b.level(.add), 3)
        for _ in 0..<3 { b.record(.add, firstTry: true) }
        XCTAssertEqual(b.level(.add), 3, "three is the top")
        b.record(.add, firstTry: false)
        XCTAssertEqual(b.level(.add), 3)
        b.record(.add, firstTry: false)
        XCTAssertEqual(b.level(.add), 2)
        XCTAssertEqual(b.level(.subtract), 1, "each sign has its own level")
        XCTAssertEqual(b.lanterns, 11)
    }

    // The board mixes signs and sends every third puzzle to her weakest one (L13, F4).
    func testNextOperationMixesAndFavoursTheWeakest() {
        var b = BoardRecord()
        b.missed["subtract"] = 3
        var seen: [MathOp] = []
        for i in 0..<6 {
            b.puzzlesServed = i
            seen.append(ProblemMaker.nextOperation([.add, .subtract, .multiply], board: b)!)
        }
        XCTAssertEqual(Set(seen), [.add, .subtract, .multiply])
        XCTAssertEqual(seen[2], .subtract)
        XCTAssertEqual(seen[5], .subtract)
    }

    // AC-B6, L15, L6: her puzzles stay whole numbers, and the companion gets her second puzzle wrong.
    func testMadePuzzlesAndTheCompanionsMistake() {
        XCTAssertEqual(MadePuzzle(op: .subtract, a: 3, b: 8).answer, 5, "bigger number first")
        let d = MadePuzzle(op: .divide, a: 13, b: 4)
        XCTAssertEqual(d.a % d.b, 0, "no remainders")
        let p = MadePuzzle(op: .add, a: 6, b: 7)
        XCTAssertEqual(p.companionAnswer(made: 0), 13)
        XCTAssertNotEqual(p.companionAnswer(made: 1), 13, "her second puzzle: the companion slips")
        XCTAssertEqual(p.companionAnswer(made: 2), 13)
        XCTAssertNotEqual(p.companionAnswer(made: 4), 13)
    }

    // AC-S1, AC-S2: each place scroll has six checked items, a drawing and a puzzle to make; every answer is right.
    func testPlaceScrolls() {
        var s = LearnerState()
        finish(content.chapters.map(\.id), in: &s)
        let maker = WorksheetMaker(content: content, progression: progression)
        for ch in WriteItDown.places {
            let w = maker.placeSheet(ch, state: s)!
            XCTAssertEqual(w.checkedCount, 6, ch)
            XCTAssertTrue(w.items.contains { $0.kind == .drawIt }, ch)
            XCTAssertTrue(w.items.contains { $0.kind == .makePuzzle }, ch)
            XCTAssertTrue(w.items.contains { $0.kind == .answerFirst }, "\(ch): L16")
            XCTAssertEqual(Set(w.items.map(\.id)).count, w.items.count, "\(ch): ids unique")
            for item in w.items where item.isChecked {
                XCTAssertTrue(item.check(item.answer), item.id)
                if let op = item.op, item.kind == .sentence || item.kind == .picture {
                    let nums = item.tokens.compactMap { Int($0) }
                    XCTAssertEqual(op.apply(nums[0], nums[1]).map(String.init), item.answer, item.id)
                }
            }
        }
        XCTAssertNil(maker.placeSheet("nowhere", state: s))
    }

    // AC-S3, AC-S4: answers are checked as numbers; the sign item accepts the typed minus.
    func testChecking() {
        let item = SheetItem(id: "x", kind: .sentence, tokens: ["3", "+", "4", "=", "?"], answer: "7", op: .add)
        XCTAssertTrue(item.check(" 7 "))
        XCTAssertFalse(item.check("8"))
        XCTAssertFalse(item.check("seven"))
        let sign = SheetItem(id: "y", kind: .missingSign, tokens: ["9", "○", "4", "=", "5"], answer: "−", op: .subtract)
        XCTAssertTrue(sign.check("-"))
        XCTAssertTrue(sign.check("−"))
        XCTAssertFalse(sign.check("+"))
    }

    // AC-M1, AC-M2: mixed scrolls need two signs and lean on her weakest one.
    func testMixedScrollFavoursWeakSpots() {
        var s = LearnerState()
        let maker = WorksheetMaker(content: content, progression: progression)
        finish(["prologue", "garden"], in: &s)
        XCTAssertNil(maker.mixedSheet(number: 1, state: s), "one sign is not enough to mix")
        finish(["goblin", "ball"], in: &s)
        s.board.missed["multiply"] = 4
        let w = maker.mixedSheet(number: 1, state: s)!
        let ops = w.items.compactMap(\.op)
        XCTAssertGreaterThan(ops.filter { $0 == .multiply }.count, ops.filter { $0 == .add }.count)
        XCTAssertTrue(w.items.contains { $0.kind == .missingSign }, "L14")
        XCTAssertTrue(w.items.contains { $0.kind == .makePuzzle }, "L15")
        XCTAssertTrue(maker.available(state: s).contains { $0.id == "sheet.mixed.1" })
    }

    // AC-S5: "hard" brings the place back in warm-ups, "easy" clears it; scroll mistakes count as weak spots.
    func testParentFeedbackFeedsThePracticeList() {
        var s = LearnerState()
        s.applySheetFeedback(.hard, sheetID: "sheet.garden", place: "garden", content: content)
        let garden = Set(content.items(in: "garden").map(\.id))
        XCTAssertEqual(s.needsPractice.intersection(garden).count, 4)
        XCTAssertEqual(s.sheets["sheet.garden"]?.feedback, .hard)
        s.applySheetFeedback(.easy, sheetID: "sheet.garden", place: "garden", content: content)
        XCTAssertTrue(s.needsPractice.intersection(garden).isEmpty)

        var done = LearnerState()
        finish(["prologue", "garden"], in: &done)
        let w = WorksheetMaker(content: content, progression: progression).placeSheet("garden", state: done)!
        var firstTry: [String: Bool] = [:]
        for (i, item) in w.items.enumerated() where item.isChecked { firstTry[item.id] = i != 0 }
        done.finishSheet(w, firstTry: firstTry, at: T.day1)
        XCTAssertEqual(done.sheets["sheet.garden"]?.firstTry, 5)
        XCTAssertEqual(done.board.sheetMistakes["add"], 1)
    }

    // New saved fields decode from an older save (dev rule: optional with a default).
    func testOldSaveStillLoads() throws {
        let old = #"{"version":1,"completedScenes":["P0"]}"#.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let s = try decoder.decode(LearnerState.self, from: old)
        XCTAssertEqual(s.board, BoardRecord())
        XCTAssertTrue(s.wroteDown.isEmpty)
        XCTAssertTrue(s.sheets.isEmpty)
    }

    // The new lines exist for every place and sign.
    func testLinesExist() {
        for ch in WriteItDown.places { XCTAssertNotNil(content.lines["write.intro.\(ch)"], ch) }
        for op in MathOp.allCases {
            XCTAssertNotNil(content.lines["board.story.\(op.rawValue)"])
            XCTAssertNotNil(content.lines["board.showOp.\(op.rawValue)"])
        }
        let kinds: [SheetItemKind] = [.picture, .sentence, .missing, .answerFirst, .missingSign, .count, .drawIt, .makePuzzle]
        for k in kinds {
            let item = SheetItem(id: "x", kind: k, tokens: [], answer: "")
            XCTAssertNotNil(content.lines[item.promptLine], k.rawValue)
        }
    }

    // Board stories fill both numbers.
    func testStoryLineFillsNumbers() {
        let catalog = LineCatalog(lines: content.lines)
        let line = catalog.spoken("board.story.add", a: 4, b: 3)
        XCTAssertEqual(line?.text.contains("4 flowers"), true)
        XCTAssertEqual(line?.text.contains("{"), false)
    }
}
