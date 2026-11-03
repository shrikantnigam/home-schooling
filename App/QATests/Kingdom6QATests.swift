import XCTest

/// QA play-through for Chapter 6: The Moon Crystal (docs/chapters/chapter-6.md).
final class Kingdom6QATests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    /// AC-6a to AC-6d: all four scenes, one wrong path per activity kind, the full ladder once.
    func test01_Moon_M1toM4() {
        let p = QAPlayer(self, prefix: "c6-01")
        p.launch(preset: "M1")
        let wrong: [String: [String: Int]] = [
            "M1": ["m1-4": 1], "M2": ["m2-8/4": 3], "M3": ["m3-3/4": 2], "M4": ["m4-14/2": 1],
        ]
        for s in ["M1", "M2", "M3", "M4"] {
            p.tap("castle.play")
            p.tap("map.place.moon")
            p.playScene(s, wrongOn: wrong[s] ?? [:])
        }
        p.tap("castle.play")
        p.wait("map.place.moon")
        p.snap("map after the moon")
    }
}
