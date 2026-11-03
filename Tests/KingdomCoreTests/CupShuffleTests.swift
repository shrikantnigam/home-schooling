import Foundation
import XCTest
@testable import KingdomCore

/// Cup shuffle rules C1 to C10 (docs/features/cup-shuffle.md).
final class CupShuffleTests: XCTestCase {

    // C1, C3: three or five cups, speed 1 to 3; faster means more swaps and quicker ones.
    func testSettings() {
        XCTAssertEqual(CupSettings(cups: 4, speed: 9), CupSettings(cups: 3, speed: 3), "clamped to the choices")
        XCTAssertEqual(CupSettings(cups: 5, speed: 0), CupSettings(cups: 5, speed: 1))
        XCTAssertEqual(CupSettings(cups: 3, speed: 1).swaps, 3)
        XCTAssertEqual(CupSettings(cups: 3, speed: 3).swaps, 7)
        XCTAssertEqual(CupSettings(cups: 5, speed: 1).swaps, 5)
        XCTAssertEqual(CupSettings(cups: 5, speed: 3).swaps, 9)
        XCTAssertGreaterThan(CupSettings(cups: 3, speed: 1).swapSeconds, CupSettings(cups: 3, speed: 3).swapSeconds)
    }

    // C3: every plan has the right swaps, the bird's cup moves in at least half of them, and no pair swaps twice in a row.
    func testPlans() {
        for cups in CupSettings.cupChoices {
            for speed in CupSettings.speedChoices {
                let s = CupSettings(cups: cups, speed: speed)
                for seed in UInt64(1)...200 {
                    let p = CupShufflePlan(settings: s, seed: seed)
                    XCTAssertEqual(p.swaps.count, s.swaps)
                    XCTAssertTrue((0..<cups).contains(p.birdCup))
                    XCTAssertGreaterThanOrEqual(p.birdMoves, (s.swaps + 1) / 2, "bird moves enough: \(s) seed \(seed)")
                    for pair in p.swaps {
                        XCTAssertEqual(pair.count, 2)
                        XCTAssertTrue(pair[0] < pair[1] && pair[1] < cups && pair[1] - pair[0] <= 2)
                    }
                    if cups == 5 {
                        for (a, b) in zip(p.swaps, p.swaps.dropFirst()) { XCTAssertNotEqual(a, b) }
                    }
                    XCTAssertEqual(p.order(after: p.swaps.count)[p.birdPosition], p.birdCup)
                }
            }
        }
    }

    func testPlansAreRepeatableAndVary() {
        let s = CupSettings(cups: 5, speed: 2)
        XCTAssertEqual(CupShufflePlan(settings: s, seed: 7), CupShufflePlan(settings: s, seed: 7))
        let ends = Set((UInt64(1)...60).map { CupShufflePlan(settings: s, seed: $0).birdPosition })
        XCTAssertEqual(ends, Set(0..<5), "the bird can end up under any cup")
    }

    // C7: the tutorial is three cups and one swap that moves the bird's cup.
    func testTutorialPlan() {
        for seed in UInt64(1)...30 {
            let p = CupShufflePlan.tutorial(seed: seed)
            XCTAssertEqual(p.cups, 3)
            XCTAssertEqual(p.swaps.count, 1)
            XCTAssertEqual(p.birdMoves, 1)
            XCTAssertEqual(p.swaps[0][1] - p.swaps[0][0], 1)
        }
    }

    // C1, C9: her last choice is remembered; 3 finds in a row suggest harder, 2 misses in a row suggest easier.
    func testRecordAndSuggestion() {
        var r = CupShuffleRecord()
        XCTAssertFalse(r.tutorialDone)
        XCTAssertEqual(r.last, .first)
        let easy = CupSettings(cups: 3, speed: 1)
        r.finish(easy, found: true, at: T.day1)
        r.finish(easy, found: true, at: T.day1)
        XCTAssertNil(r.suggestion(after: easy))
        r.finish(easy, found: true, at: T.day1)
        XCTAssertEqual(r.suggestion(after: easy), CupSettings(cups: 3, speed: 2))

        let fast5 = CupSettings(cups: 5, speed: 3)
        r.finish(fast5, found: false, at: T.day1)
        XCTAssertEqual(r.last, fast5)
        XCTAssertNil(r.suggestion(after: fast5), "one miss is not a pattern")
        r.finish(fast5, found: false, at: T.day1)
        XCTAssertEqual(r.suggestion(after: fast5), CupSettings(cups: 5, speed: 2))

        XCTAssertEqual(CupSettings(cups: 3, speed: 3).harder, CupSettings(cups: 5, speed: 1))
        XCTAssertNil(CupSettings(cups: 5, speed: 3).harder)
        XCTAssertEqual(CupSettings(cups: 5, speed: 1).easier, CupSettings(cups: 3, speed: 1))
        XCTAssertNil(CupSettings(cups: 3, speed: 1).easier)
    }

    // C10: the grown-ups' tally by setting.
    func testTally() {
        var r = CupShuffleRecord()
        let a = CupSettings(cups: 3, speed: 1)
        let b = CupSettings(cups: 5, speed: 2)
        r.finish(a, found: true, at: T.day1)
        r.finish(a, found: false, at: T.day1)
        r.finish(b, found: true, at: T.day1)
        let t = r.bySetting
        XCTAssertEqual(t.count, 2)
        XCTAssertEqual(t[0].settings, a)
        XCTAssertEqual(t[0].found, 1)
        XCTAssertEqual(t[0].played, 2)
        XCTAssertEqual(t[1].settings, b)
        XCTAssertEqual(r.roundsPlayed, 3)
    }

    // Old saves load with a fresh cup shuffle record, so the tutorial shows once.
    func testOldSaveDecodes() throws {
        var obj = try JSONSerialization.jsonObject(with: JSONEncoder().encode(LearnerState())) as! [String: Any]
        obj.removeValue(forKey: "cupShuffle")
        let s = try JSONDecoder().decode(LearnerState.self, from: JSONSerialization.data(withJSONObject: obj))
        XCTAssertEqual(s.cupShuffle, CupShuffleRecord())
        XCTAssertFalse(s.cupShuffle.tutorialDone)
    }

    // C6, C7: every cup line exists and is speakable.
    func testLines() throws {
        let content = try Content.bundled()
        for id in ["cup.intro", "cup.tut.hide", "cup.tut.watch", "cup.tut.tap", "cup.tut.point", "cup.tut.done", "cup.miss"] {
            XCTAssertNotNil(content.lines[id], id)
        }
    }
}
