import XCTest

/// QA play-through for Chapter 5: The Fair Feast (docs/chapters/chapter-5.md).
final class Kingdom5QATests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    /// AC-5a to AC-5d: all four scenes, one wrong path per activity kind, the full ladder once.
    func test01_Feast_F1toF4() {
        let p = QAPlayer(self, prefix: "c5-01")
        p.launch(preset: "F1")
        let wrong: [String: [String: Int]] = [
            "F1": ["f1-9/3": 2], "F2": ["f2-12/3": 1], "F3": ["f3-16/4": 3], "F4": ["f4-12/3": 1],
        ]
        for s in ["F1", "F2", "F3", "F4"] {
            p.tap("castle.play")
            p.tap("map.place.feast")
            p.playScene(s, wrongOn: wrong[s] ?? [:])
        }
        p.tap("castle.play")
        p.wait("map.place.feast")
        p.snap("map after the feast")
    }
}
