import XCTest

/// QA play-through for the Home School hub (#30) and the jigsaw widget (#25, docs/features/jigsaw.md).
final class Chapter8PlaythroughTests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    /// AC-H1 to AC-H4: the app opens on the home screen; the Kingdom tile opens the castle and the house
    /// button comes back; the jigsaw opens from its tile.
    func test01_HomeScreen_Widgets() {
        let p = QAPlayer(self, prefix: "c8-01")
        p.launch()
        p.wait("home.title", timeout: 15)
        p.wait("home.widget.kingdom")
        p.wait("home.widget.jigsaw")
        p.snap("home school home screen")
        XCTAssertGreaterThanOrEqual(p.el("home.widget.kingdom").frame.width, 200)
        p.tap("home.widget.kingdom")
        p.wait("castle.play")
        p.snap("kingdom of numbers from its tile")
        p.tap("corner.home")
        p.wait("home.title")
        p.tap("home.widget.jigsaw")
        p.wait("jig.choose.picture")
        p.wait("jig.choose.line")
        p.snap("jigsaw chooser")
        p.tap("corner.home")
        p.wait("home.title")
    }

    /// J1 to J4, J10: the first picture puzzle is the 10-piece quick check. A wrong drop does not place the
    /// piece; the hint ladder goes strategy, area, outline, then slides the piece home; the explain moment
    /// comes halfway; the finished picture ends with Next.
    func test02_PicturePuzzle_Hints_Explain() {
        let p = QAPlayer(self, prefix: "c8-02")
        p.launch()
        p.tap("home.widget.jigsaw")
        p.tap("jig.choose.picture")
        p.wait("jig.size.10")
        XCTAssertFalse(p.el("jig.size.20").exists, "the quick check offers one size only")
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
        p.wait("jig.choose.picture")
        // J9: never the same picture twice in a row.
        XCTAssertNotEqual(p.el("jig.choose.picture").value as? String, "castle")
    }

    /// J5, J10: an easy 10-piece quick check moves her up to 20 pieces. On that second puzzle the companion
    /// puts a piece in the wrong place and asks; she says no and why.
    func test03_SecondPuzzle_CompanionSlip() {
        let p = QAPlayer(self, prefix: "c8-03")
        p.launch()
        p.tap("home.widget.jigsaw")
        playPicture(p, size: 10)
        p.tapNext()
        p.tap("jig.choose.picture")
        p.wait("jig.size.20")
        XCTAssertFalse(p.el("jig.size.10").exists, "an easy quick check moves up a size")
        p.snap("quick check moved up to 20")
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

    /// J12: the number-line puzzle, 1 to 10 with dots, placed in order.
    func test04_NumberLine() {
        let p = QAPlayer(self, prefix: "c8-04")
        p.launch()
        p.tap("home.widget.jigsaw")
        p.tap("jig.choose.line")
        p.wait("jig.board")
        p.snap("number line puzzle")
        p.tap("jig.hint")
        p.snap("number line hint")
        for i in 0..<10 {
            drag(p, i, to: i)
            if p.el("jig.explain.order").waitForExistence(timeout: 1) {
                p.snap("number line explain")
                p.tap("jig.explain.order")
            }
        }
        p.wait("jig.done", timeout: 10)
        p.snap("number line finished")
    }

    /// J8, J11: the grown-ups' jigsaw page shows how she plays and sets the range of sizes.
    func test05_ParentArea_JigsawRange() {
        let p = QAPlayer(self, prefix: "c8-05")
        p.launch()
        p.tap("home.widget.jigsaw")
        playPicture(p, size: 10)
        p.tap("corner.lock")
        p.tap("gate.qaHold")
        p.wait("gate.year")
        p.el("gate.year").typeText("\(Calendar.current.component(.year, from: Date()))")
        p.tap("gate.continue")
        p.wait("parent.back")
        p.tap("parent.tab.jigsaw")
        p.wait("parent.jig.min")
        p.wait("parent.jig.firstFit")
        p.wait("parent.jig.homeIdea")
        p.snap("grown-ups' jigsaw page")
        XCTAssertEqual(p.el("parent.jig.level").label.hasPrefix("Her level now: 20"), true)
        p.tap("parent.jig.min.plus")
        XCTAssertEqual(p.el("parent.jig.min").value as? String, "20")
        p.tap("parent.jig.max.minus")
        p.tap("parent.jig.max.minus")
        p.tap("parent.jig.max.minus")
        XCTAssertEqual(p.el("parent.jig.max").value as? String, "20")
        p.snap("range set to 20 pieces")
        p.tap("parent.back")
        // Back where the grown-up came from: the jigsaw is a widget, so that is the home screen.
        p.wait("home.title")
        p.tap("home.widget.jigsaw")
        p.tap("jig.choose.picture")
        p.wait("jig.size.20")
        XCTAssertFalse(p.el("jig.size.10").exists)
        p.snap("only 20 pieces offered")
    }

    // MARK: Helpers

    private func drag(_ p: QAPlayer, _ piece: Int, to slot: Int) {
        let from = p.wait("jig.piece.\(piece)").coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let to = p.wait("jig.slot.\(slot)").coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        from.press(forDuration: 0.15, thenDragTo: to)
    }

    /// Plays one picture puzzle straight through, answering the explain moment if it comes.
    private func playPicture(_ p: QAPlayer, size: Int) {
        p.tap("jig.choose.picture")
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
