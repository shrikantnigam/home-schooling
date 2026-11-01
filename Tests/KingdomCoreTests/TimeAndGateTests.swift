import XCTest
@testable import KingdomCore

/// AC-P1 to AC-P5, AC-A6.
final class TimeKeeperTests: XCTestCase {
    let cal = T.calendar

    // AC-P2
    func testDailyLimitDefaultsTo20AndSteps5To30() {
        var s = TimeSettings()
        XCTAssertEqual(s.dailyLimitMinutes, 20)
        s.setDailyLimit(3); XCTAssertEqual(s.dailyLimitMinutes, 5)
        s.setDailyLimit(45); XCTAssertEqual(s.dailyLimitMinutes, 30)
        s.setDailyLimit(17); XCTAssertEqual(s.dailyLimitMinutes, 15)
        s.setDailyLimit(18); XCTAssertEqual(s.dailyLimitMinutes, 20)
        s.stepLimit(up: true); XCTAssertEqual(s.dailyLimitMinutes, 25)
        s.stepLimit(up: true); s.stepLimit(up: true); XCTAssertEqual(s.dailyLimitMinutes, 30)
        for _ in 0..<10 { s.stepLimit(up: false) }
        XCTAssertEqual(s.dailyLimitMinutes, 5)
        XCTAssertEqual(TimeSettings.allowedLimits, [5, 10, 15, 20, 25, 30])
    }

    // AC-P3
    func testSleepingAfterLimitUntilLocalMidnight() {
        var tk = TimeKeeper()
        let settings = TimeSettings()
        tk.addPlay(seconds: 19 * 60, at: T.date(2026, 11, 2, 18), calendar: cal)
        XCTAssertNil(tk.block(at: T.date(2026, 11, 2, 18, 30), settings: settings, calendar: cal))
        tk.addPlay(seconds: 60, at: T.date(2026, 11, 2, 18, 31), calendar: cal)
        XCTAssertEqual(tk.block(at: T.date(2026, 11, 2, 23, 59), settings: settings, calendar: cal), .sleeping)
        XCTAssertNil(tk.block(at: T.date(2026, 11, 3, 0, 1), settings: settings, calendar: cal), "new day")
    }

    func testRaisingLimitWakesSparkle() {
        var tk = TimeKeeper()
        var settings = TimeSettings()
        tk.addPlay(seconds: 20 * 60, at: T.day1, calendar: cal)
        XCTAssertEqual(tk.block(at: T.day1, settings: settings, calendar: cal), .sleeping)
        settings.setDailyLimit(25)
        XCTAssertNil(tk.block(at: T.day1, settings: settings, calendar: cal))
    }

    // AC-P4
    func testQuietHoursBlockStartingAScene() {
        var settings = TimeSettings()
        settings.quietStart = 19 * 60 + 30
        settings.quietEnd = 7 * 60
        let tk = TimeKeeper()
        XCTAssertEqual(tk.block(at: T.date(2026, 11, 2, 19, 30), settings: settings, calendar: cal), .quietHours)
        XCTAssertEqual(tk.block(at: T.date(2026, 11, 2, 3, 0), settings: settings, calendar: cal), .quietHours)
        XCTAssertNil(tk.block(at: T.date(2026, 11, 2, 7, 0), settings: settings, calendar: cal))
        XCTAssertNil(tk.block(at: T.date(2026, 11, 2, 19, 29), settings: settings, calendar: cal))
    }

    func testQuietHoursSameDayWindow() {
        var settings = TimeSettings()
        settings.quietStart = 12 * 60
        settings.quietEnd = 13 * 60
        XCTAssertTrue(TimeKeeper.inQuietHours(at: T.date(2026, 11, 2, 12, 30), settings: settings, calendar: cal))
        XCTAssertFalse(TimeKeeper.inQuietHours(at: T.date(2026, 11, 2, 13, 0), settings: settings, calendar: cal))
    }

    func testQuietHoursOffByDefault() {
        XCTAssertFalse(TimeSettings().quietHoursOn)
        XCTAssertFalse(TimeKeeper.inQuietHours(at: T.day1, settings: TimeSettings(), calendar: cal))
    }

    // AC-P5
    func testLastSevenDays() {
        var tk = TimeKeeper()
        tk.addPlay(seconds: 12 * 60, at: T.date(2026, 11, 8), calendar: cal)
        tk.addPlay(seconds: 5 * 60 + 59, at: T.date(2026, 11, 2), calendar: cal)
        tk.addPlay(seconds: 9 * 60, at: T.date(2026, 11, 1), calendar: cal)
        tk.noteSceneCompleted(at: T.date(2026, 11, 8), calendar: cal)
        let week = tk.lastSevenDays(endingOn: T.date(2026, 11, 8), calendar: cal)
        XCTAssertEqual(week.count, 7)
        XCTAssertEqual(week.first?.minutes, 5, "Nov 2 is the oldest; Nov 1 is outside")
        XCTAssertEqual(week.last?.minutes, 12)
        XCTAssertEqual(week.last?.scenes, 1)
        XCTAssertEqual(week.map(\.minutes).reduce(0, +), 17)
    }

    func testIgnoresNonPositiveSeconds() {
        var tk = TimeKeeper()
        tk.addPlay(seconds: -5, at: T.day1, calendar: cal)
        tk.addPlay(seconds: 0, at: T.day1, calendar: cal)
        XCTAssertEqual(tk.secondsPlayed(on: T.day1, calendar: cal), 0)
    }
}

final class ParentGateTests: XCTestCase {
    // AC-P1
    func testNeedsTwoFingersForThreeSecondsThenYear() {
        var g = ParentGate()
        g.holdEnded(fingers: 1, seconds: 5)
        XCTAssertEqual(g.step, .hold)
        g.holdEnded(fingers: 2, seconds: 2.9)
        XCTAssertEqual(g.step, .hold)
        XCTAssertFalse(g.submitYear("2026", now: T.day1, calendar: T.calendar), "can't skip the hold")
        g.holdEnded(fingers: 2, seconds: 3)
        XCTAssertEqual(g.step, .typeYear)
        XCTAssertFalse(g.submitYear("2025", now: T.day1, calendar: T.calendar))
        XCTAssertEqual(g.step, .typeYear)
        XCTAssertTrue(g.submitYear(" 2026 ", now: T.day1, calendar: T.calendar))
        XCTAssertEqual(g.step, .open)
    }

    func testThreeWrongYearsGoesBackToHold() {
        var g = ParentGate()
        g.holdEnded(fingers: 2, seconds: 3)
        for y in ["1", "22", "333"] { g.submitYear(y, now: T.day1, calendar: T.calendar) }
        XCTAssertEqual(g.step, .hold)
    }

    func testCancelResets() {
        var g = ParentGate()
        g.holdEnded(fingers: 3, seconds: 4)
        g.cancel()
        XCTAssertEqual(g, ParentGate())
    }
}
