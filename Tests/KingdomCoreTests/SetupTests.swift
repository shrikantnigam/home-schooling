import XCTest
@testable import KingdomCore

/// Charter v1.3: one-time setup of name, companion and daily limit, locked afterwards.
final class SetupTests: XCTestCase {
    func testFreshStateNeedsSetupWithDefaults() {
        let s = LearnerState()
        XCTAssertTrue(s.needsSetup)
        XCTAssertEqual(s.heroName, "Siara")
        XCTAssertEqual(s.companion, .unicorn)
        XCTAssertEqual(s.timeSettings.dailyLimitMinutes, 25)
    }

    func testSetupIsSavedOnceAndLocked() {
        var s = LearnerState()
        XCTAssertTrue(s.completeSetup(SetupChoices(heroName: "Maya", companion: .gnome, dailyLimitMinutes: 40)))
        XCTAssertEqual(s.heroName, "Maya")
        XCTAssertEqual(s.companion, .gnome)
        XCTAssertEqual(s.timeSettings.dailyLimitMinutes, 40)
        XCTAssertFalse(s.completeSetup(SetupChoices(heroName: "Other", companion: .monster, dailyLimitMinutes: 10)),
                       "locked after setup")
        XCTAssertEqual(s.heroName, "Maya")
        XCTAssertEqual(s.companion, .gnome)
        XCTAssertEqual(s.timeSettings.dailyLimitMinutes, 40)
    }

    func testLimitAtSetupIsUnderAnHour() {
        XCTAssertEqual(SetupChoices(heroName: "A", companion: .unicorn, dailyLimitMinutes: 90).dailyLimitMinutes, 55)
        XCTAssertEqual(SetupChoices(heroName: "A", companion: .unicorn, dailyLimitMinutes: 0).dailyLimitMinutes, 5)
    }

    func testNameIsCleaned() {
        XCTAssertEqual(SetupChoices.cleanName("  "), "Siara")
        XCTAssertEqual(SetupChoices.cleanName(" anna-marie "), "anna-marie")
        XCTAssertEqual(SetupChoices.cleanName("Zoë 123!"), "Zoë")
        XCTAssertEqual(SetupChoices.cleanName(String(repeating: "a", count: 40)).count, SetupChoices.maxNameLength)
    }

    func testResetEverythingStartsSetupAgain() {
        var s = LearnerState()
        s.completeSetup(SetupChoices(heroName: "Maya", companion: .monster, dailyLimitMinutes: 45))
        s.resetAllProgress()
        XCTAssertTrue(s.needsSetup)
        XCTAssertEqual(s.timeSettings.dailyLimitMinutes, 25)
    }

    func testSetupSurvivesSaveAndOldFilesNeedSetup() throws {
        var s = LearnerState()
        s.completeSetup(SetupChoices(heroName: "Maya", companion: .superhero, dailyLimitMinutes: 30))
        let data = try JSONEncoder().encode(s)
        XCTAssertEqual(try JSONDecoder().decode(LearnerState.self, from: data).companion, .superhero)
        let old = try JSONDecoder().decode(LearnerState.self, from: Data(#"{"version":1}"#.utf8))
        XCTAssertTrue(old.needsSetup)
    }

    func testLinesNameTheChosenCompanionAndHero() throws {
        let content = try Content.bundled()
        let c = LineCatalog(lines: content.lines, heroName: "Maya", companion: .gnome)
        XCTAssertEqual(c.spoken("sleeping")?.text, "Pip is sleeping. Let's play again tomorrow.")
        XCTAssertEqual(c.spoken("castle.back")?.text.contains("Maya"), true)
        for comp in Companion.allCases {
            XCTAssertNotNil(content.lines["companion.hello.\(comp.rawValue)"], comp.rawValue)
        }
    }

    /// No line hard-codes the unicorn: they name {companion} (charter v1.3).
    func testNoLineHardCodesTheUnicorn() throws {
        let content = try Content.bundled()
        for (id, line) in content.lines where !id.hasPrefix("companion.hello.") {
            let t = line.text.lowercased()
            XCTAssertFalse(t.contains("sparkle") || t.contains("unicorn") || t.contains("hoof") || t.contains("hooves"),
                           "\(id): \(line.text)")
        }
    }
}
