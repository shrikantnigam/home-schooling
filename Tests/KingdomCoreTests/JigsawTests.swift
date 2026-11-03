import Foundation
import XCTest
@testable import KingdomCore

/// Jigsaw widget rules J1 to J14 (docs/features/jigsaw.md).
final class JigsawTests: XCTestCase {
    private func result(pieces: Int, firstFits: Int, hints: Int = 0, maxStep: Int = 0, kind: String = "picture",
                        picture: String? = "castle") -> JigsawResult {
        JigsawResult(kind: kind, pictureID: picture, pieces: pieces, firstFits: firstFits, hintsUsed: hints,
                     maxHintStep: maxStep, strategy: nil, date: Date())
    }

    // J2: each rung moves exactly one knob, sizes go 10 to 50, easiest first.
    func testLadderMovesOneKnobAtATime() {
        let r = JigsawLadder.rungs
        XCTAssertEqual(r.first?.pieces, 10)
        XCTAssertEqual(r.first?.cut, .tabs, "no square pieces (2026-11-03)")
        XCTAssertFalse(r.contains { $0.cut == .squares })
        XCTAssertEqual(r.first?.turning, false)
        XCTAssertEqual(r.last?.pieces, 50)
        for i in 1..<r.count { XCTAssertEqual(r[i].knobsChanged(from: r[i - 1]), 1, "rung \(i)") }
        XCTAssertEqual(Set(r.map(\.pieces)), Set(JigsawLadder.sizes))
    }

    // The grid holds exactly the piece count.
    func testGrids() {
        for n in JigsawLadder.sizes {
            let g = JigsawLadder.grid(n)
            XCTAssertEqual(g.cols * g.rows, n)
            XCTAssertGreaterThanOrEqual(g.cols, g.rows)
        }
    }

    // Neighbouring pieces fit: a tab on one side is a hole on the other; borders are flat.
    func testCutPlanEdgesMatch() {
        let plan = JigsawCutPlan(pieces: 30, seed: 7)
        for i in 0..<plan.count {
            let (c, r) = plan.position(i)
            let e = plan.edges(i)
            if r == 0 { XCTAssertEqual(e[0], 0) }
            if c == 0 { XCTAssertEqual(e[3], 0) }
            if c < plan.cols - 1 { XCTAssertEqual(e[1], -plan.edges(i + 1)[3]); XCTAssertNotEqual(e[1], 0) }
            if r < plan.rows - 1 { XCTAssertEqual(e[2], -plan.edges(i + plan.cols)[0]); XCTAssertNotEqual(e[2], 0) }
        }
        XCTAssertEqual((0..<plan.count).filter(plan.isEdge).count, 2 * plan.cols + 2 * plan.rows - 4)
        XCTAssertEqual(JigsawCutPlan(pieces: 30, seed: 7), plan)
    }

    // J10: the quick check moves up a size after each easy puzzle, and stops at the first one that isn't easy.
    func testQuickCheckSetsStartingSize() {
        var j = JigsawRecord()
        XCTAssertEqual(j.levelSize, 10)
        j.finishPicture(result(pieces: 10, firstFits: 10))
        XCTAssertEqual(j.level.pieces, 20)
        XCTAssertFalse(j.calibrated)
        j.finishPicture(result(pieces: 20, firstFits: 20, picture: "garden"))
        XCTAssertEqual(j.level.pieces, 30)
        j.finishPicture(result(pieces: 30, firstFits: 20, hints: 2, picture: "castle"))
        XCTAssertTrue(j.calibrated)
        XCTAssertEqual(j.level.pieces, 30)
        XCTAssertEqual(j.levelSize, 30)
    }

    // J2, J9: four easy wins step up one knob; being stuck steps down one; a middling puzzle resets the streak.
    func testAdaptsOneKnob() {
        var j = JigsawRecord()
        j.calibrated = true
        j.rung = 3
        for k in 0..<3 { j.finishPicture(result(pieces: 20, firstFits: 20, picture: "p\(k)")) }
        XCTAssertEqual(j.rung, 3)
        j.finishPicture(result(pieces: 20, firstFits: 19, hints: 1, picture: "p3"))
        XCTAssertEqual(j.rung, 4)
        j.finishPicture(result(pieces: 20, firstFits: 15, picture: "p4"))
        XCTAssertEqual(j.easyStreak, 0)
        j.finishPicture(result(pieces: 20, firstFits: 18, hints: 3, maxStep: 3, picture: "p5"))
        XCTAssertEqual(j.rung, 3)
    }

    // J15: the picker is always 10, 20, 30; 20 and 30 open after her first (10-piece) puzzle; the sun ring never
    // sits on a locked size or above 30.
    func testPickerLocksUntilFirstTen() {
        var j = JigsawRecord()
        XCTAssertEqual(JigsawRecord.pickerSizes, [10, 20, 30])
        XCTAssertEqual(JigsawRecord.pickerSizes.map(j.isOpen), [true, false, false])
        j.rung = 4
        XCTAssertEqual(j.levelSize, 10, "a locked size is never suggested")
        j.rung = 0
        j.finishPicture(result(pieces: 10, firstFits: 6, hints: 3))
        XCTAssertEqual(JigsawRecord.pickerSizes.map(j.isOpen), [true, true, true])
        j.rung = JigsawLadder.rungs.count - 1
        XCTAssertEqual(j.levelSize, 30)
        XCTAssertEqual(j.level(pieces: 30).cut, .wavy)
    }

    // J13: the map's suggestion is never the picture just played; otherwise the least recently played.
    func testNextPictureNeverRepeats() {
        var j = JigsawRecord()
        let ids = ["a", "b", "c"]
        var seen: [String] = []
        for _ in 0..<6 {
            let next = j.nextPicture(from: ids)!
            if let last = seen.last { XCTAssertNotEqual(next, last) }
            seen.append(next)
            j.finishPicture(result(pieces: 10, firstFits: 5, picture: next))
        }
        XCTAssertEqual(Set(seen.prefix(3)), Set(ids))
    }

    // J14: a finished picture gets a tick, with the most pieces she has done it in. Old saves rebuild the ticks.
    func testCompletedPictures() throws {
        var j = JigsawRecord()
        XCTAssertFalse(j.isCompleted("castle"))
        j.finishPicture(result(pieces: 20, firstFits: 15, picture: "castle"))
        j.finishPicture(result(pieces: 10, firstFits: 10, picture: "castle"))
        XCTAssertTrue(j.isCompleted("castle"))
        XCTAssertEqual(j.completed["castle"], 20)
        XCTAssertFalse(j.isCompleted("garden"))

        // A save from before J14 has results but no ticks; number-line results don't count.
        var old = JigsawRecord()
        old.results = [result(pieces: 30, firstFits: 20, picture: "ballet"),
                       result(pieces: 10, firstFits: 10, kind: "line", picture: nil)]
        var obj = try JSONSerialization.jsonObject(with: JSONEncoder().encode(old)) as! [String: Any]
        obj.removeValue(forKey: "completed")
        let decoded = try JSONDecoder().decode(JigsawRecord.self, from: JSONSerialization.data(withJSONObject: obj))
        XCTAssertEqual(decoded.completed, ["ballet": 30])
    }

    // J5: the companion slips on every third puzzle.
    func testCompanionSlip() {
        var j = JigsawRecord()
        var due: [Bool] = []
        for k in 0..<6 {
            due.append(j.companionSlipDue)
            j.finishPicture(result(pieces: 10, firstFits: 4, picture: "p\(k)"))
        }
        XCTAssertEqual(due, [false, true, false, false, true, false])
    }

    // Old saves load with an empty jigsaw record.
    func testOldSaveDecodes() throws {
        let data = try JSONEncoder().encode(LearnerState())
        var obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        obj.removeValue(forKey: "jigsaw")
        let old = try JSONSerialization.data(withJSONObject: obj)
        let s = try JSONDecoder().decode(LearnerState.self, from: old)
        XCTAssertEqual(s.jigsaw, JigsawRecord())
        let partial = try JSONDecoder().decode(JigsawRecord.self, from: Data("{\"rung\":4}".utf8))
        XCTAssertEqual(partial.rung, 3, "a ladder-1 save moves down past the removed square rung")
        let current = try JSONDecoder().decode(JigsawRecord.self, from: Data("{\"rung\":4,\"ladder\":2}".utf8))
        XCTAssertEqual(current.rung, 4)
        var j = JigsawRecord()
        j.rung = 5
        XCTAssertEqual(try JSONDecoder().decode(JigsawRecord.self, from: JSONEncoder().encode(j)).rung, 5)
        XCTAssertEqual(partial.maxPieces, 50)
    }

    // J7: every jigsaw line exists and is companion-neutral.
    func testLines() throws {
        let content = try Content.bundled()
        for id in ["home.hello", "jig.intro.picture", "jig.hint.edges", "jig.hint.area", "jig.hint.outline",
                   "jig.hint.slide", "jig.explain", "jig.slip.ask", "jig.slip.caught"] {
            XCTAssertNotNil(content.lines[id], id)
        }
    }
}
