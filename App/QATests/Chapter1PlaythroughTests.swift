import XCTest

/// QA play-through for Chapter 1 (Prologue: Counting Stars, and The Flower Garden).
/// Each test plays the real app in the iPad simulator and saves screenshots.
/// Test names carry the acceptance criteria they cover (docs/product-spec.md section 11).
final class Chapter1PlaythroughTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// AC-S1, AC-S2, AC-S3, AC-A2, AC-A5: fresh install goes to P1, plays it, returns to the castle.
    func test01_FreshInstall_P1_ThenCastle() {
        let p = QAPlayer(self, prefix: "01")
        p.launch()
        p.wait("castle.play")
        p.snap("castle first launch")
        XCTAssertGreaterThanOrEqual(p.el("castle.play").frame.width, 60)
        XCTAssertGreaterThanOrEqual(p.el("corner.ear").frame.width, 60)
        p.tap("castle.play")
        p.wait("panel.open.P1")
        p.tap("corner.ear") // replay works on the story panel
        p.playScene("P1")
        // Back at the castle; nothing starts by itself.
        p.wait("castle.play")
        p.snap("castle after P1")
        XCTAssertFalse(p.el("panel.open.P2").exists)
        p.tap("castle.play")
        p.wait("map.place.prologue")
        p.snap("map after P1")
        XCTAssertTrue(p.el("map.scene.P1").exists)
    }

    /// AC-S4 (partly), AC-M3, AC-M6: the Prologue in one sitting. Counting moves up a CPA level;
    /// the Garden stays locked (mastery needs 2 days) and practice is offered.
    func test02_Prologue_P2toP4_PracticeOffered() {
        let p = QAPlayer(self, prefix: "02")
        p.launch(preset: "P2")
        p.tap("castle.play")
        p.wait("map.place.prologue")
        p.snap("map before P2")
        p.tap("map.place.prologue")
        p.playScene("P2")
        p.tap("castle.play")
        p.tap("map.place.prologue")
        p.playScene("P3")
        p.tap("castle.play")
        p.tap("map.place.prologue")
        p.playScene("P4")
        p.tap("castle.play")
        p.wait("map.place.garden")
        p.snap("map after prologue: garden locked, practice glowing")
        p.tap("map.place.garden") // "Not yet. We'll get there together."
        p.snap("garden locked tap")
        p.tap("map.place.prologue")
        p.wait("panel.open.practice-prologue")
        p.snap("practice scene offered")
    }

    /// AC-M2, AC-A6: the hint ladder on G1 (model hint, worked step, show answer), never red.
    func test03_G1_HintLadder() {
        let p = QAPlayer(self, prefix: "03")
        p.launch(preset: "G1")
        p.tap("castle.play")
        p.tap("map.place.garden")
        p.wait("panel.open.G1")
        p.snap("G1 open")
        p.tapNext()
        // Warm-up items first (from the Prologue).
        var item = p.currentItem()!
        while !item.id.hasPrefix("g1") {
            p.solve(item, snapEach: true)
            item = p.currentItem()!
        }
        XCTAssertEqual(item.level, "concrete")
        p.snap("G1 first item")
        p.doConcreteSteps(item)
        p.snap("seeds planted, tiles shown")
        let wrong = p.wrongChoice(for: item)
        p.answer(wrong, for: item)
        p.snap("wrong 1: model hint (box glows)")
        p.answer(wrong, for: item)
        p.snap("wrong 2: worked step (count on)")
        p.answer(wrong, for: item)
        p.snap("wrong 3: answer shown")
        p.tapNext()
        p.snap("next item after reveal")
    }

    /// AC-S5 and every Garden activity: G1 to G5 all the way to the bridge teaser.
    func test04_Garden_G1toG5() {
        let p = QAPlayer(self, prefix: "04")
        p.launch(preset: "G1")
        for s in ["G1", "G2", "G3", "G4", "G5"] {
            p.tap("castle.play")
            p.tap("map.place.garden")
            p.playScene(s, wrongOn: s == "G4" ? ["g4-8": 1] : [:])
        }
        p.tap("castle.play")
        p.wait("map.place.garden")
        p.snap("map after garden")
    }

    /// G5 help: opening the flower box or the hopping path is allowed but is not first-try.
    func test05_G5_HelpModels() {
        let p = QAPlayer(self, prefix: "05")
        p.launch(preset: "G5")
        p.tap("castle.play")
        p.tap("map.place.garden")
        p.wait("panel.open.G5")
        p.tapNext()
        var item = p.currentItem()!
        while !item.id.hasPrefix("g5") { p.solve(item, snapEach: false); item = p.currentItem()! }
        p.snap("G5 equation with help buttons")
        p.tap("help.flowerBox")
        p.snap("G5 flower box help")
        p.answer(item.answer, for: item)
        p.tapNext()
        let item2 = p.currentItem()!
        p.tap("help.hoppingPath")
        p.snap("G5 hopping path help")
        p.answer(item2.answer, for: item2)
        p.tapNext()
    }

    /// AC-S6: quit mid-scene and reopen at the start of the same item.
    func test06_ResumeMidScene() {
        let p = QAPlayer(self, prefix: "06")
        p.launch()
        p.tap("castle.play")
        p.wait("panel.open.P1")
        p.tapNext()
        p.solve(p.currentItem()!, snapEach: false)
        p.solve(p.currentItem()!, snapEach: false)
        let third = p.currentItem()!
        p.snap("third item before quitting")
        p.app.terminate()
        p.launch(reset: false)
        p.tap("castle.play")
        let resumed = p.currentItem()!
        p.snap("resumed item")
        XCTAssertEqual(resumed.id, third.id)
    }

    /// AC-P3: limit used up. Castle shows Sparkle sleeping and no play button.
    func test07_DailyLimit_Sleeping() {
        let p = QAPlayer(self, prefix: "07")
        p.launch(preset: "limitReached")
        p.wait("castle.sleeping")
        p.snap("sparkle is sleeping")
        XCTAssertFalse(p.el("castle.play").exists)
        XCTAssertTrue(p.el("corner.ear").exists)
        XCTAssertTrue(p.el("corner.lock").exists)
    }

    /// AC-P1, AC-P2, AC-P5, AC-P6, AC-P7, AC-A8: parent gate and parent area.
    func test08_ParentGate_And_Area() {
        let p = QAPlayer(self, prefix: "08")
        p.launch(preset: "sampleProgress")
        p.tap("corner.lock")
        p.wait("gate.hold")
        p.snap("gate step 1: hold two fingers")
        p.tap("gate.cancel")
        p.wait("castle.play")
        p.tap("corner.lock")
        p.tap("gate.qaHold")
        p.wait("gate.year")
        p.snap("gate step 2: type the year")
        p.el("gate.year").typeText("1999")
        p.tap("gate.continue")
        p.snap("gate wrong year")
        XCTAssertFalse(p.el("parent.back").exists)
        let year = Calendar.current.component(.year, from: Date())
        p.el("gate.year").tap()
        p.el("gate.year").typeText("\(year)")
        p.tap("gate.continue")
        p.wait("parent.back")
        p.snap("parent progress")
        XCTAssertTrue(p.el("parent.today").exists)
        p.tap("parent.tab.time")
        p.wait("parent.limit.value")
        XCTAssertEqual(p.el("parent.limit.value").label, "20 min")
        p.tap("parent.limit.plus")
        XCTAssertEqual(p.el("parent.limit.value").label, "25 min")
        for _ in 0..<6 { p.tap("parent.limit.minus") }
        XCTAssertEqual(p.el("parent.limit.value").label, "5 min")
        p.snap("time limits at 5")
        p.tap("parent.tab.sound")
        p.snap("sound and voice")
        p.tap("parent.tab.screenTime")
        p.snap("screen time help")
        p.tap("parent.tab.progress")
        p.tap("parent.unlock")
        p.snap("after unlock next chapter")
        p.tap("parent.tab.reset")
        p.tap("parent.resetAll")
        p.snap("reset confirmation")
        p.app.alerts.buttons["Reset"].tap()
        p.tap("parent.back")
        p.wait("castle.play")
        p.tap("castle.play")
        p.wait("panel.open.P1")
        p.snap("fresh start after reset")
    }

    /// AC-A3: touching a tile once only "hears" it; it is not chosen until touched again.
    func test09_TileTouchOnceToHear() {
        let p = QAPlayer(self, prefix: "09")
        p.launch(preset: "P4")
        p.tap("castle.play")
        p.tap("map.place.prologue")
        p.wait("panel.open.P4")
        p.tapNext()
        var item = p.currentItem()!
        while item.kind != "quickLook" { p.solve(item, snapEach: false); item = p.currentItem()! }
        p.snap("quick look shows stars")
        _ = p.el("quickLook.cloud").waitForExistence(timeout: 4)
        p.snap("quick look hidden behind cloud")
        let wrong = p.wrongChoice(for: item)
        p.tap("tile.\(wrong)")
        p.snap("tile heard once, not chosen")
        XCTAssertFalse(p.el("next").exists)
        p.tap("tile.\(item.answer)")
        p.tap("tile.\(item.answer)")
        p.wait("next")
        p.snap("chosen on second touch")
    }
}
