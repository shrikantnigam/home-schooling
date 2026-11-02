import XCTest

/// A QA "player": plays the app through the simulator like Siara would, and saves a
/// screenshot of every screen it sees. Screenshots are exported by CI for review.
final class QAPlayer {
    let app = XCUIApplication()
    let test: XCTestCase
    private var shot = 0
    let prefix: String

    init(_ test: XCTestCase, prefix: String) {
        self.test = test
        self.prefix = prefix
    }

    func launch(reset: Bool = true, preset: String? = nil, extra: [String] = []) {
        app.launchArguments = ["-uiTesting"] + (reset ? ["-reset"] : []) + (preset.map { ["-preset", $0] } ?? []) + extra
        XCUIDevice.shared.orientation = .landscapeLeft
        app.launch()
        XCUIDevice.shared.orientation = .landscapeLeft
    }

    /// Launches like a real install on her iPad: no QA flags, real speech, real animations, the real saved state.
    func launchLikeHerIPad() {
        app.launchArguments = []
        XCUIDevice.shared.orientation = .landscapeLeft
        app.launch()
        XCUIDevice.shared.orientation = .landscapeLeft
    }

    /// Saves a screenshot named for the report, e.g. "01-03 P1 open".
    func snap(_ name: String) {
        shot += 1
        // The screen, not the app element: app.screenshot() comes out cropped in landscape.
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        if shot == 1 {
            print("QA-FRAME window=\(app.windows.firstMatch.frame) orientation=\(XCUIDevice.shared.orientation.rawValue)")
        }
        a.name = String(format: "%@-%02d %@", prefix, shot, name)
        a.lifetime = .keepAlways
        test.add(a)
    }

    func el(_ id: String) -> XCUIElement { app.descendants(matching: .any)[id] }

    @discardableResult
    func wait(_ id: String, timeout: TimeInterval = 8, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let e = el(id)
        let found = e.waitForExistence(timeout: timeout)
        // A failed wait keeps a picture of what was on screen instead, so the cause is never a guess.
        if !found { snap("FAILED waiting for \(id)") }
        XCTAssertTrue(found, "missing \(id)", file: file, line: line)
        return e
    }

    func tap(_ id: String, file: StaticString = #filePath, line: UInt = #line) {
        let e = wait(id, file: file, line: line)
        e.tap()
    }

    func tapNext(file: StaticString = #filePath, line: UInt = #line) {
        let n = el("next")
        XCTAssertTrue(n.waitForExistence(timeout: 10), "next button never appeared", file: file, line: line)
        n.tap()
    }

    // MARK: Items

    struct ItemInfo {
        let id: String
        let kind: String
        let a: Int
        let b: Int
        let answer: Int
        let level: String
        /// e.g. "tap:3", "tapAnswers:5", "place:2", "hop:3" or "none".
        let steps: String
        let onLine: Bool
    }

    /// The item on screen, read from its accessibility description.
    func currentItem(timeout: TimeInterval = 8) -> ItemInfo? {
        let q = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'item.'"))
        let first = q.firstMatch
        guard first.waitForExistence(timeout: timeout) else { return nil }
        let ident = first.identifier
        let value = (first.value as? String) ?? ""
        var f: [String: String] = [:]
        for part in value.split(separator: ";") {
            let kv = part.split(separator: "=", maxSplits: 1)
            if kv.count == 2 { f[String(kv[0])] = String(kv[1]) }
        }
        let parts = ident.split(separator: ".")
        return ItemInfo(
            id: parts.count > 1 ? String(parts[1]) : ident,
            kind: f["kind"] ?? "", a: Int(f["a"] ?? "") ?? 0, b: Int(f["b"] ?? "") ?? 0,
            answer: Int(f["answer"] ?? "") ?? 0, level: f["level"] ?? "",
            steps: f["steps"] ?? "none", onLine: f["line"] == "true"
        )
    }

    /// Does the hands-on part of a concrete item: tap objects, place things, or hop.
    func doConcreteSteps(_ i: ItemInfo) {
        let parts = i.steps.split(separator: ":")
        guard parts.count == 2, let n = Int(parts[1]) else { return }
        switch parts[0] {
        case "tap", "tapAnswers":
            for k in 0..<n {
                // Stars and gems are tapped by index; flowers waiting for a bed are always the first one.
                if i.kind == "parts" {
                    // Crystal parts are pie wedges that share one square frame: touch the middle of wedge k.
                    let mid: Double = (-90 + 360 * (Double(k) + 0.5) / Double(n)) * Double.pi / 180
                    wait("obj.\(k)").coordinate(withNormalizedOffset: CGVector(dx: CGFloat(0.5 + 0.3 * cos(mid)), dy: CGFloat(0.5 + 0.3 * sin(mid)))).tap()
                }
                else if el("star.\(k)").exists { tap("star.\(k)") }
                else if el("obj.\(k)").exists { tap("obj.\(k)") }
                else { tap("pot.0") }
            }
        case "place":
            for _ in 0..<n { tap(el("seed.0").exists ? "seed.0" : "source") }
        case "hop":
            for k in 0..<n { tap(el("horseshoe.\(k)").exists ? "horseshoe.\(k)" : "hopper") }
        default: break
        }
    }

    var answersOnLine: (ItemInfo) -> Bool = { $0.onLine }

    /// Gives an answer: a stone on the line, or a tile touched twice (hear, then choose).
    func answer(_ n: Int, for i: ItemInfo) {
        if answersOnLine(i) {
            tap("stone.\(n)")
        } else {
            tap("tile.\(n)")
            tap("tile.\(n)")
        }
    }

    /// A wrong choice that is on screen.
    func wrongChoice(for i: ItemInfo) -> Int {
        if answersOnLine(i) { return i.answer == 0 ? 1 : i.answer - 1 }
        for n in 0...20 where n != i.answer && el("tile.\(n)").exists { return n }
        return i.answer + 1
    }

    /// Plays the item. `wrongTries` wrong answers first (0 to 3).
    func solve(_ i: ItemInfo, wrongTries: Int = 0, snapEach: Bool = true) {
        if snapEach { snap("\(i.id) \(i.level) asks") }
        doConcreteSteps(i)
        if i.steps.hasPrefix("tapAnswers") {
            // Counting every star is the answer.
            if snapEach { snap("\(i.id) counted") }
            tapNext()
            return
        }
        for w in 0..<wrongTries {
            answer(wrongChoice(for: i), for: i)
            if snapEach { snap("\(i.id) wrong \(w + 1)") }
            if w == 2 { tapNext(); return }
        }
        answer(i.answer, for: i)
        // A touch can be lost on a busy simulator. If the right tile was only "heard", one more touch chooses it.
        if !answersOnLine(i), !el("next").waitForExistence(timeout: 4), el("tile.\(i.answer)").exists {
            tap("tile.\(i.answer)")
        }
        if snapEach { snap("\(i.id) correct") }
        tapNext()
    }

    /// Plays a whole scene from its open panel to the castle.
    func playScene(_ id: String, wrongOn: [String: Int] = [:], snapItems: Bool = true) {
        wait("panel.open.\(id)", timeout: 10)
        snap("\(id) story open")
        tapNext()
        var last = ""
        var loops = 0
        while loops < 200 {
            loops += 1
            if el("panel.payoff.\(id)").exists { break }
            guard let item = currentItem(timeout: 1), item.id != last else { continue }
            last = item.id
            solve(item, wrongTries: wrongOn[item.id] ?? 0, snapEach: snapItems)
        }
        wait("panel.payoff.\(id)", timeout: 10)
        snap("\(id) payoff")
        tapNext()
        wait("panel.goodbye.\(id)")
        snap("\(id) goodbye")
        tapNext()
        // F1: the last scene of a place ends with "Write it down". Chapter 7 plays it; other runs step past it.
        if el("write.equals").waitForExistence(timeout: 2) {
            snap("\(id) write it down")
            tap("corner.castle")
        }
    }

    // MARK: Problem solving (Chapter 7)

    /// The fields of an element's "k=v;k=v" accessibility value.
    func fields(_ id: String) -> [String: String] {
        let value = (wait(id).value as? String) ?? ""
        var f: [String: String] = [:]
        for part in value.split(separator: ";") {
            let kv = part.split(separator: "=", maxSplits: 1)
            if kv.count == 2 { f[String(kv[0])] = String(kv[1]) }
        }
        return f
    }

    /// The first element whose identifier starts with `prefix`.
    func first(_ prefix: String, timeout: TimeInterval = 8) -> XCUIElement? {
        let e = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix)).firstMatch
        return e.waitForExistence(timeout: timeout) ? e : nil
    }

    static func opName(_ sign: String) -> String {
        switch sign {
        case "+": return "add"
        case "−", "-": return "subtract"
        case "×": return "multiply"
        default: return "divide"
        }
    }

    func openParentArea() {
        tap("corner.lock")
        tap("gate.qaHold")
        let year = Calendar.current.component(.year, from: Date())
        wait("gate.year").tap()
        el("gate.year").typeText("\(year)")
        tap("gate.continue")
        wait("parent.back")
    }
}
