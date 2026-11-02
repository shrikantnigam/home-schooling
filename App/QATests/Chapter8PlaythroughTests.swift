import XCTest

/// QA play-through for the Home School hub (#30) and the jigsaw widget (#25, docs/features/jigsaw.md).
/// The cup shuffle widget has its own chapter (Chapter9PlaythroughTests).
final class Chapter8PlaythroughTests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    /// AC-H1 to AC-H4: the app opens on the home screen; the Kingdom tile opens the castle and the house
    /// button comes back; the jigsaw opens from its tile on the puzzle map (J13, AC-H7).
    func test01_HomeScreen_Widgets() {
        let p = QAPlayer(self, prefix: "c8-01")
        p.launch()
        p.wait("home.title", timeout: 15)
        p.wait("home.widget.kingdom")
        p.wait("home.widget.jigsaw")
        p.wait("home.widget.cups")
        p.snap("home school home screen")
        XCTAssertGreaterThanOrEqual(p.el("home.widget.kingdom").frame.width, 200)
        p.tap("home.widget.kingdom")
        p.wait("castle.play")
        p.snap("kingdom of numbers from its tile")
        p.tap("corner.home")
        p.wait("home.title")
        p.tap("home.widget.jigsaw")
        p.wait("jig.map")
        for id in ["castle", "garden", "companion", "ballet", "karate", "ball", "night", "rainbow"] {
            XCTAssertEqual(p.wait("jig.map.\(id)").value as? String, id == "castle" ? "new;suggested" : "new")
        }
        XCTAssertFalse(p.el("jig.choose.line").exists, "the number-line puzzle is gone")
        p.snap("puzzle map, nothing finished yet")
        p.tap("corner.home")
        p.wait("home.title")
    }

    /// J1 to J4, J10, J14: the first picture puzzle is the 10-piece quick check. A wrong drop does not place the
    /// piece; the hint ladder goes strategy, area, outline, then slides the piece home; the explain moment
    /// comes halfway; the finished picture ends with Next, and the map shows it with a tick.
    func test02_PicturePuzzle_Hints_Explain() {
        let p = QAPlayer(self, prefix: "c8-02")
        p.launch()
        p.tap("home.widget.jigsaw")
        p.tap("jig.map.castle")
        // J15: the picker always shows 10, 20 and 30; before her first 10 only 10 is open.
        XCTAssertEqual(p.wait("jig.size.10").value as? String, "open;suggested")
        XCTAssertEqual(p.el("jig.size.20").value as? String, "locked")
        XCTAssertEqual(p.el("jig.size.30").value as? String, "locked")
        XCTAssertEqual(p.el("jig.size.40").exists, false)
        p.tap("jig.size.30")
        XCTAssertFalse(p.el("jig.board").exists, "a locked size doesn't start a puzzle")
        p.metric("taps-home-to-size-picker", p.taps)
        p.snap("size picker, quick check")
        p.tap("jig.size.10")
        p.wait("jig.board")
        XCTAssertEqual(p.el("jig.board").value as? String, "placed=0/10;pieces=10")
        p.snap("10-piece puzzle")

        // A wrong drop: piece 0 on slot 1 stays in the tray.
        drag(p, 0, to: 1)
        XCTAssertEqual(p.el("jig.board").value as? String, "placed=0/10;pieces=10")
        XCTAssertTrue(p.el("jig.piece.0").exists)
        p.snap("wrong drop wobbles back")

        // The hint ladder for the piece she last touched.
        p.tap("jig.hint")
        XCTAssertEqual(p.el("jig.hint").value as? String, "step=1")
        p.tap("jig.hint")
        p.wait("jig.hint.area")
        p.snap("hint: the area glows")
        p.tap("jig.hint")
        p.wait("jig.hint.outline")
        p.snap("hint: the outline")
        p.tap("jig.hint")
        XCTAssertTrue(p.el("jig.piece.0").waitForNonExistence(timeout: 3), "the last hint slides the piece home")
        XCTAssertEqual(p.el("jig.board").value as? String, "placed=1/10;pieces=10")

        var explained = false
        for i in 1..<10 {
            drag(p, i, to: i)
            if p.el("jig.explain.colour").waitForExistence(timeout: 1) {
                p.snap("explain moment")
                p.tap("jig.explain.edge")
                explained = true
            }
        }
        XCTAssertTrue(explained, "the explain moment came")
        p.wait("jig.done", timeout: 10)
        p.snap("finished picture")
        p.tapNext()
        // J14: the finished picture has a tick with its size; the suggestion moves on (J13).
        XCTAssertEqual(p.wait("jig.map.castle").value as? String, "done=10")
        XCTAssertEqual(p.el("jig.map.garden").value as? String, "new;suggested")
        p.snap("puzzle map with the castle ticked")
        // A finished picture stays open to play again.
        p.tap("jig.map.castle")
        XCTAssertEqual(p.wait("jig.size.20").value as? String, "open;suggested")
        XCTAssertEqual(p.el("jig.size.30").value as? String, "open")
        p.snap("after her first 10: 20 and 30 open, 20 suggested")
    }

    /// J5, J10: an easy 10-piece quick check moves her up to 20 pieces. On that second puzzle the companion
    /// puts a piece in the wrong place and asks; she says no and why.
    func test03_SecondPuzzle_CompanionSlip() {
        let p = QAPlayer(self, prefix: "c8-03")
        p.launch()
        p.tap("home.widget.jigsaw")
        playPicture(p, "castle", size: 10)
        p.tapNext()
        p.tap("jig.map.garden")
        XCTAssertEqual(p.wait("jig.size.20").value as? String, "open;suggested", "an easy quick check moves up a size")
        XCTAssertEqual(p.el("jig.size.10").value as? String, "open", "she can still pick 10")
        p.snap("quick check moved the suggestion up to 20")
        p.tap("jig.size.20")
        p.wait("jig.board")
        var slipped = false
        for i in 0..<20 {
            drag(p, i, to: i)
            if p.el("jig.slip.no").waitForExistence(timeout: 1) {
                p.snap("companion's slip")
                p.tap("jig.slip.no")
                p.wait("jig.slip.why.edge")
                p.snap("why doesn't it fit")
                p.tap("jig.slip.why.edge")
                slipped = true
            }
            if p.el("jig.explain.picture").waitForExistence(timeout: 0.5) { p.tap("jig.explain.picture") }
        }
        XCTAssertTrue(slipped, "the companion slipped on the second puzzle")
        p.wait("jig.done", timeout: 10)
        p.snap("second puzzle finished")
    }

    /// J8, J11: the grown-ups' jigsaw page shows how she plays and the size that fits her.
    func test05_ParentArea_Jigsaw() {
        let p = QAPlayer(self, prefix: "c8-05")
        p.launch()
        p.tap("home.widget.jigsaw")
        playPicture(p, "castle", size: 10)
        p.tap("corner.lock")
        p.tap("gate.qaHold")
        p.wait("gate.year")
        p.el("gate.year").typeText("\(Calendar.current.component(.year, from: Date()))")
        p.tap("gate.continue")
        p.wait("parent.back")
        p.tap("parent.tab.jigsaw")
        p.wait("parent.jig.level")
        p.wait("parent.jig.firstFit")
        p.wait("parent.jig.homeIdea")
        p.snap("grown-ups' jigsaw page")
        XCTAssertEqual(p.el("parent.jig.level").label.hasPrefix("Her level now: 20"), true)
        XCTAssertFalse(p.el("parent.jig.min").exists, "the size range is gone (J15)")
        p.tap("parent.back")
        // Back where the grown-up came from: the jigsaw is a widget, so that is the home screen.
        p.wait("home.title")
        p.tap("home.widget.jigsaw")
        p.tap("jig.map.garden")
        XCTAssertEqual(p.wait("jig.size.20").value as? String, "open;suggested")
        p.snap("picker after one puzzle")
    }

    /// Debug "Jump to" (Shrikant, 2026-11-02): open any scene from the grown-ups' area, then End testing
    /// puts her progress back exactly as it was.
    func test06_DebugJump_RestoresProgress() {
        let p = QAPlayer(self, prefix: "c8-06")
        p.launch()
        openParentArea(p)
        p.tap("parent.tab.debug")
        p.wait("debug.scene.M3")
        p.snap("jump to page")
        p.tap("debug.scene.M3")
        p.wait("panel.open.M3", timeout: 10)
        p.snap("jumped to the Moon, scene 3")
        p.tap("corner.lock")
        p.tap("gate.qaHold")
        p.wait("gate.year")
        p.el("gate.year").typeText("\(Calendar.current.component(.year, from: Date()))")
        p.tap("gate.continue")
        p.tap("parent.tab.debug")
        p.tap("debug.end")
        p.wait("home.title")
        p.tap("home.widget.kingdom")
        p.wait("castle.progress")
        XCTAssertEqual(p.el("castle.progress").label, "0 of 7 places done", "her progress is back as it was")
        p.snap("progress restored after testing")
    }

    private func openParentArea(_ p: QAPlayer) {
        p.tap("corner.lock")
        p.tap("gate.qaHold")
        p.wait("gate.year")
        p.el("gate.year").typeText("\(Calendar.current.component(.year, from: Date()))")
        p.tap("gate.continue")
        p.wait("parent.back")
    }

    // MARK: Helpers

    private func drag(_ p: QAPlayer, _ piece: Int, to slot: Int) {
        let from = p.wait("jig.piece.\(piece)").coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let to = p.wait("jig.slot.\(slot)").coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        from.press(forDuration: 0.15, thenDragTo: to)
    }

    /// Plays one picture puzzle straight through, answering the explain moment if it comes.
    private func playPicture(_ p: QAPlayer, _ picture: String, size: Int) {
        p.tap("jig.map.\(picture)")
        p.tap("jig.size.\(size)")
        p.wait("jig.board")
        for i in 0..<size {
            drag(p, i, to: i)
            if p.el("jig.explain.colour").waitForExistence(timeout: 0.5) { p.tap("jig.explain.colour") }
            if p.el("jig.slip.no").exists { p.tap("jig.slip.no"); p.tap("jig.slip.why.edge") }
        }
        p.wait("jig.done", timeout: 10)
    }
}
