import XCTest

/// QA play-through for Chapter 1 (Prologue: Counting Stars, and The Flower Garden).
/// Each test plays the real app in the iPad simulator and saves screenshots.
/// Test names carry the acceptance criteria they cover (docs/product-spec.md section 11).
final class Chapter1PlaythroughTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// Launch smoke test (operating model rule 4): the app as she gets it, with no QA flags. It must show the
    /// setup screen, reach the castle and the first scene, and come back to the castle on the next launch.
    /// Every other test passes -uiTesting, which hid a black screen on her iPad (2026-11-02).
    func test00_LaunchSmoke_NoTestFlags() {
        let p = QAPlayer(self, prefix: "00")
        p.launchLikeHerIPad()
        let first = ["setup.start", "home.widget.kingdom", "castle.play"].map { p.el($0) }
        let deadline = Date().addingTimeInterval(20)
        while Date() < deadline && !first.contains(where: { $0.exists }) { _ = first[0].waitForExistence(timeout: 1) }
        p.snap("first screen without test flags")
        XCTAssertTrue(first.contains(where: { $0.exists }), "launch shows setup, the home screen or the castle, not a blank screen")
        if p.el("setup.start").exists {
            p.tap("setup.start")
            p.app.alerts.firstMatch.buttons["Start"].firstMatch.tap()
        }
        p.wait("castle.play", timeout: 20)
        p.snap("castle without test flags")
        p.app.terminate()
        p.launchLikeHerIPad()
        p.wait("castle.play", timeout: 20)
        p.snap("castle on the next launch")
        p.tap("castle.play")
        XCTAssertTrue(p.el("panel.open.P0").waitForExistence(timeout: 30), "Play opens the Prologue challenge")
        p.snap("first scene without test flags")
    }

    /// AC-S1, AC-S2, AC-S3, AC-A2, AC-A5, charter L12 and S11 ("fast learner" persona): a fresh install opens
    /// with the Prologue challenge. Everything right first time tests her out of the Prologue, and the open
    /// kingdom (Garden, Ball, Feast) is ready in the same session.
    func test01_FreshInstall_Challenge_FastLearner() {
        let p = QAPlayer(self, prefix: "01")
        p.launch()
        p.wait("castle.play")
        p.snap("castle first launch")
        XCTAssertGreaterThanOrEqual(p.el("castle.play").frame.width, 60)
        XCTAssertGreaterThanOrEqual(p.el("corner.ear").frame.width, 60)
        p.tap("castle.play")
        p.wait("panel.open.P0")
        p.tap("corner.ear") // replay works on the story panel
        p.playScene("P0")
        // Back at the castle; nothing starts by itself.
        p.wait("castle.play")
        p.snap("castle after the challenge")
        XCTAssertEqual(p.el("castle.progress").label, "1 of 7 places done")
        p.tap("castle.play")
        p.wait("map.place.garden")
        p.snap("open kingdom after testing out")
        for place in ["garden", "ball", "feast"] {
            XCTAssertEqual(p.el("map.place.\(place)").value as? String, "open", place)
        }
        for place in ["bridge", "goblin", "moon"] {
            XCTAssertEqual(p.el("map.place.\(place)").value as? String, "locked", place)
        }
        XCTAssertEqual(p.el("map.place.prologue").value as? String, "done")
        p.tap("map.place.feast")
        p.wait("panel.open.F1")
        p.snap("she chose the feast")
    }

    /// L12, items 15 and 16: a miss on the quick look skips only the counting scene. She plays the Star Path,
    /// the map wakes three places, and a finished place can be played again.
    func test02_Prologue_PartialTestOut_ThenReplay() {
        let p = QAPlayer(self, prefix: "02")
        p.launch()
        p.tap("castle.play")
        p.playScene("P0", wrongOn: ["p0-q5": 1])
        p.tap("castle.play")
        p.wait("map.place.prologue")
        p.snap("map: counting skipped, star path next")
        XCTAssertTrue(p.el("map.scene.P1").exists)
        p.tap("map.place.prologue")
        p.playScene("P2")
        p.tap("castle.play")
        p.wait("map.place.garden")
        p.snap("map after the prologue: three places awake")
        XCTAssertEqual(p.el("map.place.garden").value as? String, "open")
        p.tap("map.place.bridge") // "Not yet. We'll get there together."
        p.snap("bridge locked tap")
        p.tap("map.place.prologue")
        p.wait("panel.open.practice-prologue")
        p.snap("finished place played again")
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
        p.wait("panel.open.P0")
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
        // Charter v1.3: set once at setup, then locked.
        XCTAssertEqual(p.el("parent.limit.value").label, "25 min")
        XCTAssertFalse(p.el("parent.limit.plus").exists)
        p.snap("time limit locked after setup")
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
        p.app.alerts.firstMatch.buttons["Reset"].firstMatch.tap()
        p.tap("parent.back")
        // Reset everything starts setup again.
        p.wait("setup.start")
        p.snap("setup again after reset")
        p.tap("setup.start")
        p.app.alerts.firstMatch.buttons["Start"].firstMatch.tap()
        p.wait("castle.play")
        p.tap("castle.play")
        p.wait("panel.open.P0")
        p.snap("fresh start after reset")
    }

    /// AC-A3: touching a tile once only "hears" it; it is not chosen until touched again.
    func test09_TileTouchOnceToHear() {
        let p = QAPlayer(self, prefix: "09")
        p.launch(preset: "P2")
        p.tap("castle.play")
        p.tap("map.place.prologue")
        p.wait("panel.open.P2")
        p.tapNext()
        var item = p.currentItem()!
        while item.kind != "quickLook" { p.solve(item, snapEach: false); item = p.currentItem()! }
        // Item 14: the stars stay under the cloud while "Ready? Look quickly!" is said, then show, then hide.
        p.snap("quick look: ready")
        let cloud = p.el("quickLook.cloud")
        let shown = NSPredicate(format: "exists == false")
        wait(for: [XCTNSPredicateExpectation(predicate: shown, object: cloud)], timeout: 6)
        p.snap("quick look shows stars")
        _ = cloud.waitForExistence(timeout: 4)
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

    /// Play-test changes: the castle shows "N of 7" places done and has a map button.
    func test10_CastleProgressAndMapButton() {
        let p = QAPlayer(self, prefix: "10")
        p.launch(preset: "prologueDone")
        p.wait("castle.progress")
        XCTAssertEqual(p.el("castle.progress").label, "1 of 7 places done")
        XCTAssertGreaterThanOrEqual(p.el("castle.map").frame.width, 60)
        p.snap("castle with progress and map button")
        p.tap("castle.map")
        p.wait("map.place.prologue")
        p.snap("map from the castle map button")
    }

    /// Item 11: the daily limit runs out mid-scene. The scene says "we'll finish tomorrow" (no success story)
    /// and the next day it picks up at the next item, not from the start.
    func test11_LimitMidScene_PausesAndResumes() {
        let p = QAPlayer(self, prefix: "11")
        p.launch(preset: "nearLimit")
        p.tap("castle.play")
        p.wait("panel.open.P0")
        p.tapNext()
        var seen: [String] = []
        var loops = 0
        while !p.el("panel.pause.P0").exists && loops < 40 {
            loops += 1
            guard let item = p.currentItem(timeout: 1), item.id != seen.last else { continue }
            seen.append(item.id)
            p.solve(item, snapEach: false)
        }
        p.wait("panel.pause.P0", timeout: 10)
        p.snap("paused: we'll finish tomorrow")
        XCTAssertFalse(p.el("panel.payoff.P0").exists)
        p.tapNext()
        p.wait("castle.sleeping")
        p.snap("castle: sparkle sleeping")
        p.app.terminate()
        p.launch(reset: false, extra: ["-dayOffset", "1"])
        p.tap("castle.play")
        let resumed = p.currentItem()!
        p.snap("next day: resumed at the next item")
        XCTAssertFalse(seen.contains(resumed.id), "resumes after \(seen), got \(resumed.id)")
    }

    /// Charter v1.3: first-launch setup of name, companion and daily limit, then locked.
    func test12_FirstLaunchSetup() {
        let p = QAPlayer(self, prefix: "12")
        p.launch(extra: ["-showSetup"])
        p.wait("setup.start")
        p.snap("setup: five companions")
        for c in ["unicorn", "superhero", "princess", "monster", "gnome"] {
            XCTAssertTrue(p.el("setup.companion.\(c)").exists, c)
        }
        let name = p.el("setup.name")
        name.tap()
        name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 12))
        name.typeText("Maya")
        p.tap("setup.companion.gnome")
        p.tap("setup.limit.plus")
        XCTAssertEqual(p.el("setup.limit.value").label, "30 min")
        for _ in 0..<10 { p.tap("setup.limit.plus") }
        XCTAssertEqual(p.el("setup.limit.value").label, "55 min", "always under an hour")
        p.snap("setup filled in")
        p.tap("setup.start")
        p.snap("setup confirm")
        p.app.alerts.firstMatch.buttons["Start"].firstMatch.tap()
        p.wait("castle.play")
        p.snap("castle with the gnome")
        XCTAssertTrue(p.app.descendants(matching: .any)["Pip the gnome"].exists)
        p.tap("castle.play")
        p.wait("panel.open.P0")
        p.snap("P0 with the gnome")
    }

    /// Rule 5 check for the hang on her iPad (2026-11-02): the voice never reports finishing, yet every
    /// screen still moves on (Next appears, the quick look reveals, the scene ends) thanks to the watchdog.
    func test13_SpeechNeverFinishes_NoScreenHangs() {
        let p = QAPlayer(self, prefix: "13")
        p.launch(extra: ["-speechNeverFinishes"])
        p.tap("castle.play")
        p.playScene("P0", snapItems: false)
        p.wait("castle.play", timeout: 20)
        p.snap("back at the castle with a silent voice")
    }
}
