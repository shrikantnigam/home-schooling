import XCTest

/// QA play-through for the cup shuffle widget (#27, docs/features/cup-shuffle.md, rules C1 to C10).
/// The table's QA value reads "phase=...;bird=<position>;chirps=<n>;tutorial=<0|1>".
final class Chapter9PlaythroughTests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    /// C7, AC-H8: the tutorial shows the first time only. A wrong cup only wobbles and the hand points again;
    /// the right cup chirps; then the choices open. It doesn't come back, even after a relaunch.
    func test01_Tutorial_FirstTimeOnly() {
        let p = QAPlayer(self, prefix: "c9-01")
        p.launch()
        p.tap("home.widget.cups")
        p.wait("cup.table")
        XCTAssertTrue(table(p).contains("tutorial=1"), "the tutorial opens first")
        p.snap("tutorial: the bird hides")
        waitFor(p, "phase=choosing", timeout: 15)
        p.wait("cup.point")
        p.snap("tutorial: the hand points at the bird's cup")
        let bird = birdPosition(p)
        p.tap("cup.at.\((bird + 1) % 3)")
        XCTAssertTrue(table(p).contains("phase=choosing"), "a wrong cup in the tutorial is not a miss")
        XCTAssertTrue(p.el("cup.point").exists, "the hand points again")
        p.tap("cup.at.\(bird)")
        waitFor(p, "chirps=1")
        p.snap("tutorial: found, the bird chirps")
        p.wait("cup.start", timeout: 10)
        p.snap("choices after the tutorial")
        XCTAssertEqual(p.el("cup.count.3").value as? String, "selected")
        XCTAssertEqual(p.el("cup.speed.1").value as? String, "selected")

        p.tap("corner.home")
        p.tap("home.widget.cups")
        p.wait("cup.start")
        XCTAssertFalse(p.el("cup.table").exists, "no tutorial the second time")

        p.launch(reset: false)
        p.tap("home.widget.cups")
        p.wait("cup.start")
        XCTAssertFalse(p.el("cup.table").exists, "no tutorial after a relaunch")
    }

    /// C2 to C5: three cups at speed 1. Finding the bird chirps; "Again" starts a new round; a miss shows the empty
    /// cup, then the bird's cup with a softer chirp, and nothing is marked wrong.
    func test02_ThreeCups_FindThenMiss() {
        let p = QAPlayer(self, prefix: "c9-02")
        p.launch(preset: "cupsTutorialDone")
        p.tap("home.widget.cups")
        p.wait("cup.start")
        p.snap("choose cups and speed")
        p.tap("cup.start")
        p.wait("cup.table")
        XCTAssertTrue(table(p).contains("tutorial=0"))
        p.snap("the bird hides under a cup")
        waitFor(p, "phase=choosing", timeout: 15)
        p.snap("cups stopped: where is the bird?")
        p.tap("cup.at.\(birdPosition(p))")
        waitFor(p, "phase=found")
        waitFor(p, "chirps=1")
        p.snap("found: the bird chirps")

        p.tapNext()
        waitFor(p, "phase=choosing", timeout: 15)
        let bird = birdPosition(p)
        p.tap("cup.at.\((bird + 1) % 3)")
        waitFor(p, "phase=missed")
        waitFor(p, "chirps=1")
        p.snap("missed: the empty cup, then the bird")
        p.wait("next")
        p.wait("cup.change")
    }

    /// C1, C3: five cups at speed 3, and the choice is remembered when she changes it.
    func test03_FiveCupsFast() {
        let p = QAPlayer(self, prefix: "c9-03")
        p.launch(preset: "cupsTutorialDone")
        p.tap("home.widget.cups")
        p.tap("cup.count.5")
        p.tap("cup.speed.3")
        XCTAssertEqual(p.el("cup.count.5").value as? String, "selected")
        XCTAssertEqual(p.el("cup.speed.3").value as? String, "selected")
        p.snap("five cups, speed 3")
        p.tap("cup.start")
        p.wait("cup.at.4")
        p.snap("five cups on the table")
        waitFor(p, "phase=choosing", timeout: 20)
        p.tap("cup.at.\(birdPosition(p))")
        waitFor(p, "phase=found")
        p.snap("found under five cups")
        p.tap("cup.change")
        p.wait("cup.start")
        XCTAssertEqual(p.el("cup.count.5").value as? String, "selected", "her last choice is kept")
        XCTAssertEqual(p.el("cup.speed.3").value as? String, "selected")
    }

    /// C9: after three finds in a row, the next speed wears a sun ring. She still chooses.
    func test04_Suggestion() {
        let p = QAPlayer(self, prefix: "c9-04")
        p.launch(preset: "cupsThreeFinds")
        p.tap("home.widget.cups")
        p.wait("cup.start")
        XCTAssertEqual(p.el("cup.speed.2").value as? String, "suggested")
        XCTAssertEqual(p.el("cup.speed.1").value as? String, "selected")
        p.snap("speed 2 suggested after three finds")
    }

    /// C10: the grown-ups' cup shuffle page, and "Show the tutorial again".
    func test05_ParentPage_TutorialAgain() {
        let p = QAPlayer(self, prefix: "c9-05")
        p.launch(preset: "cupsTutorialDone")
        p.tap("home.widget.cups")
        p.tap("cup.start")
        waitFor(p, "phase=choosing", timeout: 15)
        p.tap("cup.at.\(birdPosition(p))")
        waitFor(p, "phase=found")
        p.tap("corner.lock")
        p.tap("gate.qaHold")
        p.wait("gate.year")
        p.el("gate.year").typeText("\(Calendar.current.component(.year, from: Date()))")
        p.tap("gate.continue")
        p.tap("parent.tab.cups")
        p.wait("parent.cups.recent")
        p.wait("parent.cups.homeIdea")
        p.snap("grown-ups' cup shuffle page")
        p.tap("parent.cups.tutorialAgain")
        p.tap("parent.back")
        p.tap("home.widget.cups")
        p.wait("cup.table")
        XCTAssertTrue(table(p).contains("tutorial=1"), "the tutorial shows again")
        p.snap("tutorial again")
    }

    // MARK: Helpers

    private func table(_ p: QAPlayer) -> String { (p.el("cup.table").value as? String) ?? "" }

    private func birdPosition(_ p: QAPlayer, file: StaticString = #filePath, line: UInt = #line) -> Int {
        let part = table(p).split(separator: ";").first { $0.hasPrefix("bird=") }
        guard let n = part.flatMap({ Int($0.dropFirst(5)) }) else {
            XCTFail("no bird position in \(table(p))", file: file, line: line)
            return 0
        }
        return n
    }

    /// Waits until the table's QA value contains `text`.
    private func waitFor(_ p: QAPlayer, _ text: String, timeout: TimeInterval = 8,
                         file: StaticString = #filePath, line: UInt = #line) {
        let end = Date().addingTimeInterval(timeout)
        while Date() < end {
            if table(p).contains(text) { return }
            _ = p.el("cup.table").waitForExistence(timeout: 0.3)
            Thread.sleep(forTimeInterval: 0.2)
        }
        p.snap("FAILED waiting for \(text)")
        XCTFail("table never showed \(text); it shows \(table(p))", file: file, line: line)
    }
}
