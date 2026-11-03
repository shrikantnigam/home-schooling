import XCTest

/// QA play-through for Chapter 4: The Royal Ball (docs/chapters/chapter-4.md).
final class Kingdom4QATests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    /// AC-4a to AC-4d: all four scenes, one wrong path per activity kind, the full ladder once.
    func test01_Ball_R1toR4() {
        let p = QAPlayer(self, prefix: "c4-01")
        p.launch(preset: "R1")
        let wrong: [String: [String: Int]] = [
            "R1": ["r1-3x2": 3],
            "R2": ["r2-3x3": 1],
            "R3": ["r3-3x5": 2],
            "R4": ["r4-3x5": 1],
        ]
        for s in ["R1", "R2", "R3", "R4"] {
            p.tap("castle.play")
            p.tap("map.place.ball")
            p.playScene(s, wrongOn: wrong[s] ?? [:])
        }
        p.tap("castle.play")
        p.wait("map.place.ball")
        p.snap("map after the ball")
    }
}
