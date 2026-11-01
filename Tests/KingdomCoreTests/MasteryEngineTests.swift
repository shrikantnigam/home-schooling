import XCTest
@testable import KingdomCore

/// AC-M1 to AC-M5.
final class MasteryEngineTests: XCTestCase {
    let engine = T.engine

    // AC-M1
    func testFirstTryCorrectCountsAndHintedDoesNot() {
        let item = Item(id: "i", skill: "add", kind: .addMore, a: 3, b: 2)
        var s1 = ItemSession(item: item, level: .concrete)
        XCTAssertEqual(s1.submit(5), .correct(firstTry: true))
        XCTAssertTrue(s1.result(at: T.day1).firstTryCorrect)

        var s2 = ItemSession(item: item, level: .concrete)
        XCTAssertEqual(s2.submit(4), .hint(.modelHint))
        XCTAssertEqual(s2.submit(5), .correct(firstTry: false))
        XCTAssertFalse(s2.result(at: T.day1).firstTryCorrect)

        var s3 = ItemSession(item: item, level: .abstract)
        s3.noteHelpUsed()
        XCTAssertEqual(s3.submit(5), .correct(firstTry: false))
        XCTAssertFalse(s3.result(at: T.day1).firstTryCorrect)
    }

    // AC-M2
    func testHintLadderThenShowAnswerAndNeedsPractice() {
        let item = Item(id: "i", skill: "makeTen", kind: .makeTen, a: 7)
        var s = ItemSession(item: item, level: .pictorial)
        XCTAssertEqual(s.submit(2), .hint(.modelHint))
        XCTAssertFalse(s.finished)
        XCTAssertEqual(s.submit(4), .hint(.workedStep))
        XCTAssertFalse(s.finished)
        XCTAssertEqual(s.submit(1), .hint(.showAnswer))
        XCTAssertTrue(s.finished)
        let r = s.result(at: T.day1)
        XCTAssertTrue(r.needsPractice)
        XCTAssertFalse(r.firstTryCorrect)
    }

    // AC-M3
    func testMovesUpAfterFourOfLastFive() {
        var rec = SkillRecord()
        for c in [true, false, true, true] { engine.record(T.result(level: .concrete, correct: c), into: &rec) }
        XCTAssertEqual(rec.level, .concrete, "3 of 4 is not enough")
        engine.record(T.result(level: .concrete, correct: true), into: &rec)
        XCTAssertEqual(rec.level, .pictorial)
        for _ in 0..<4 { engine.record(T.result(level: .pictorial, correct: true), into: &rec) }
        XCTAssertEqual(rec.level, .abstract)
        for _ in 0..<10 { engine.record(T.result(level: .abstract, correct: true), into: &rec) }
        XCTAssertEqual(rec.level, .abstract, "never above abstract")
    }

    func testUpWindowOnlyLooksAtLastFive() {
        var rec = SkillRecord()
        for c in [false, false, true, false, true, true, true] {
            engine.record(T.result(level: .concrete, correct: c), into: &rec)
        }
        // Last five: true, false, true, true, true -> 4 of 5.
        XCTAssertEqual(rec.level, .pictorial)
    }

    // AC-M4
    func testDropsOneLevelAfterThreeMissesInARow() {
        var rec = SkillRecord()
        rec.level = .abstract
        engine.record(T.result(level: .abstract, correct: false), into: &rec)
        engine.record(T.result(level: .abstract, correct: false), into: &rec)
        XCTAssertEqual(rec.level, .abstract)
        engine.record(T.result(level: .abstract, correct: false), into: &rec)
        XCTAssertEqual(rec.level, .pictorial)
    }

    func testMissStreakIsBrokenByACorrect() {
        var rec = SkillRecord()
        rec.level = .pictorial
        for c in [false, false, true, false, false] { engine.record(T.result(level: .pictorial, correct: c), into: &rec) }
        XCTAssertEqual(rec.level, .pictorial)
    }

    func testNeverDropsBelowConcrete() {
        var rec = SkillRecord()
        for _ in 0..<6 { engine.record(T.result(level: .concrete, correct: false), into: &rec) }
        XCTAssertEqual(rec.level, .concrete)
    }

    func testResultsAtOtherLevelsDoNotMoveLevel() {
        var rec = SkillRecord()
        rec.level = .pictorial
        for _ in 0..<5 { engine.record(T.result(level: .concrete, correct: true), into: &rec) }
        XCTAssertEqual(rec.level, .pictorial)
        XCTAssertEqual(rec.history.count, 5)
    }

    // AC-M5
    func testMasteryNeedsTenAbstractAtEightyPercentOverTwoDays() {
        var rec = SkillRecord()
        rec.level = .abstract
        for i in 0..<10 {
            rec.history.append(T.result(level: .abstract, correct: i >= 2, date: i < 5 ? T.day1 : T.day2))
        }
        XCTAssertTrue(engine.isMastered(rec), "8 of 10 over 2 days")
    }

    func testNotMasteredOnASingleDay() {
        var rec = SkillRecord()
        for _ in 0..<10 { rec.history.append(T.result(level: .abstract, correct: true, date: T.day1)) }
        XCTAssertFalse(engine.isMastered(rec))
    }

    func testNotMasteredBelowEightyPercent() {
        var rec = SkillRecord()
        for i in 0..<10 {
            rec.history.append(T.result(level: .abstract, correct: i >= 3, date: i < 5 ? T.day1 : T.day2))
        }
        XCTAssertFalse(engine.isMastered(rec), "7 of 10")
    }

    func testNotMasteredWithFewerThanTenAbstract() {
        var rec = SkillRecord()
        for i in 0..<9 { rec.history.append(T.result(level: .abstract, correct: true, date: i < 4 ? T.day1 : T.day2)) }
        for _ in 0..<5 { rec.history.append(T.result(level: .pictorial, correct: true, date: T.day2)) }
        XCTAssertFalse(engine.isMastered(rec), "pictorial items don't count")
    }

    func testMasteryUsesOnlyTheLastTenAbstract() {
        var rec = SkillRecord()
        for _ in 0..<10 { rec.history.append(T.result(level: .abstract, correct: true, date: T.day1)) }
        XCTAssertFalse(engine.isMastered(rec))
        for _ in 0..<3 { rec.history.append(T.result(level: .abstract, correct: true, date: T.day2)) }
        XCTAssertTrue(engine.isMastered(rec))
        for _ in 0..<3 { rec.history.append(T.result(level: .abstract, correct: false, date: T.day2)) }
        XCTAssertFalse(engine.isMastered(rec), "last 10 = 7 correct")
    }

    func testDaysUseLocalMidnight() {
        let late = T.date(2026, 11, 2, 23, 50)
        let early = T.date(2026, 11, 3, 0, 10)
        var rec = SkillRecord()
        for i in 0..<10 { rec.history.append(T.result(level: .abstract, correct: true, date: i < 5 ? late : early)) }
        XCTAssertTrue(engine.isMastered(rec))
    }

    func testStatus() {
        XCTAssertEqual(engine.status(nil), .notStarted)
        var rec = SkillRecord()
        XCTAssertEqual(engine.status(rec), .notStarted)
        engine.record(T.result(level: .concrete, correct: false), into: &rec)
        XCTAssertEqual(engine.status(rec), .practicing)
        rec.masteredOverride = true
        XCTAssertEqual(engine.status(rec), .mastered)
    }
}
