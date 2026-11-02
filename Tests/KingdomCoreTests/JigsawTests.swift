import Foundation
import XCTest
@testable import KingdomCore

/// Jigsaw widget rules J1 to J12 (docs/features/jigsaw.md).
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
        XCTAssertEqual(r.first?.cut, .squares)
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
        XCTAssertEqual(j.offeredSizes, [10])
        j.finishPicture(result(pieces: 10, firstFits: 10))
        XCTAssertEqual(j.level.pieces, 20)
        XCTAssertFalse(j.calibrated)
        j.finishPicture(result(pieces: 20, firstFits: 20, picture: "garden"))
        XCTAssertEqual(j.level.pieces, 30)
        j.finishPicture(result(pieces: 30, firstFits: 20, hints: 2, picture: "castle"))
        XCTAssertTrue(j.calibrated)
        XCTAssertEqual(j.level.pieces, 30)
        XCTAssertEqual(j.offeredSizes, [20, 30, 40])
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

    // The grown-up's range bounds what she is offered.
    func testParentRange() {
        var j = JigsawRecord()
        j.calibrated = true
        j.rung = JigsawLadder.rungs.count - 1
        j.setRange(min: 20, max: 30)
        XCTAssertEqual(j.levelSize, 30)
        XCTAssertEqual(j.offeredSizes, [20, 30])
        j.setRange(min: 40, max: 20)
        XCTAssertEqual(j.minPieces, 40)
        XCTAssertEqual(j.maxPieces, 40)
        XCTAssertEqual(j.level(pieces: 40).cut, .wavy)
    }

    // J9: never the same picture twice in a row; otherwise the least recently played.
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

    // J12: the number line goes concrete, then pictures, then numerals, and counts by 1, 2, 5 and 10.
    func testNumberLineLadder() {
        let r = NumberLineLevel.rungs
        XCTAssertEqual(r.first, NumberLineLevel(step: 1, look: .dots))
        XCTAssertEqual(r.map(\.step), r.map(\.step).sorted())
        XCTAssertEqual(Set(r.map(\.step)), [1, 2, 5, 10])
        XCTAssertEqual(NumberLineLevel(step: 5, look: .numerals).values, [5, 10, 15, 20, 25, 30, 35, 40, 45, 50])
        var j = JigsawRecord()
        j.finishNumberLine(result(pieces: 10, firstFits: 10, kind: "line", picture: nil))
        XCTAssertEqual(j.lineRung, 1)
        XCTAssertEqual(j.lastPuzzle, "line")
        j.finishNumberLine(result(pieces: 10, firstFits: 6, kind: "line", picture: nil))
        XCTAssertTrue(j.lineCalibrated)
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
        XCTAssertEqual(partial.rung, 4)
        XCTAssertEqual(partial.maxPieces, 50)
    }

    // J7: every jigsaw line exists and is companion-neutral.
    func testLines() throws {
        let content = try Content.bundled()
        for id in ["home.hello", "jig.intro.picture", "jig.intro.line", "jig.hint.edges", "jig.hint.area", "jig.hint.outline",
                   "jig.hint.slide", "jig.hint.line", "jig.explain", "jig.slip.ask", "jig.slip.caught"] {
            XCTAssertNotNil(content.lines[id], id)
        }
    }
}
