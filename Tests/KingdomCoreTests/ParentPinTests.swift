import XCTest
@testable import KingdomCore

/// The grown-ups' PIN (Shrikant, 2026-11-03).
final class ParentPinTests: XCTestCase {
    func testOnlyFourDigits() {
        XCTAssertNil(ParentPin(pin: "123"))
        XCTAssertNil(ParentPin(pin: "12345"))
        XCTAssertNil(ParentPin(pin: "12a4"))
        XCTAssertNil(ParentPin(pin: "١٢٣٤"), "ASCII digits only")
        XCTAssertNotNil(ParentPin(pin: "0420"))
    }

    func testStoresOnlyASaltedHash() throws {
        let pin = try XCTUnwrap(ParentPin(pin: "2580", salt: "s1"))
        XCTAssertTrue(pin.matches("2580"))
        XCTAssertFalse(pin.matches("2581"))
        XCTAssertFalse(pin.hash.contains("2580"))
        XCTAssertNotEqual(pin.hash, ParentPin(pin: "2580", salt: "s2")?.hash, "the salt changes the hash")
        let json = String(decoding: try JSONEncoder().encode(pin), as: UTF8.self)
        XCTAssertFalse(json.contains("2580"))
    }

    func testPadOpensOnTheRightPin() throws {
        let pin = try XCTUnwrap(ParentPin(pin: "2580"))
        var g = PinGate()
        let now = Date()
        XCTAssertEqual(g.type("2", pin: pin, now: now), .typing)
        g.deleteLast()
        XCTAssertEqual(g.entered, "")
        for d in "258" { XCTAssertEqual(g.type(d, pin: pin, now: now), .typing) }
        XCTAssertEqual(g.type("0", pin: pin, now: now), .open)
    }

    func testFiveWrongPinsLockForAMinute() throws {
        let pin = try XCTUnwrap(ParentPin(pin: "2580"))
        var g = PinGate()
        let now = Date()
        for k in 1...5 {
            var last = PinGate.Outcome.typing
            for d in "1111" { last = g.type(d, pin: pin, now: now) }
            XCTAssertEqual(last, k < 5 ? .wrong : .locked)
        }
        XCTAssertEqual(g.type("2", pin: pin, now: now.addingTimeInterval(30)), .locked, "even the right PIN waits")
        let later = now.addingTimeInterval(61)
        for d in "258" { _ = g.type(d, pin: pin, now: later) }
        XCTAssertEqual(g.type("0", pin: pin, now: later), .open)
    }

    func testOldSaveHasNoPinAndResetKeepsIt() throws {
        var s = LearnerState()
        XCTAssertNil(s.parentPin)
        s.parentPin = ParentPin(pin: "2580")
        let back = try JSONDecoder().decode(LearnerState.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(back.parentPin, s.parentPin)
        s.resetAllProgress()
        XCTAssertNotNil(s.parentPin, "reset everything keeps the grown-ups' PIN")
    }
}
