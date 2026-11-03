import XCTest

/// QA play-through for Chapter 2: The Bridge of Tens (docs/chapters/chapter-2.md).
final class Kingdom2QATests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    /// AC-2d: the bridge is under mist until the Garden is mastered.
    func test01_BridgeLockedAfterGardenScenesOnly() {
        let p = QAPlayer(self, prefix: "c2-01")
        p.launch(preset: "gardenScenesDone")
        p.tap("castle.play")
        p.wait("map.place.bridge")
        p.snap("map: bridge locked, garden practice offered")
        p.tap("map.place.bridge")
        XCTAssertFalse(p.el("panel.open.B1").exists)
    }

    /// AC-2a, AC-2b, AC-2c: all five scenes, one wrong path per activity kind,
    /// and the full hint ladder on the first making-ten item.
    func test02_Bridge_B1toB5() {
        let p = QAPlayer(self, prefix: "c2-02")
        p.launch(preset: "B1")
        let wrong: [String: [String: Int]] = [
            "B1": ["b1-15": 1],
            "B2": ["b2-15": 1],
            "B3": ["b3-9+3": 3, "b3-8+4": 1],
            "B4": ["b4-9+5": 2],
            "B5": [:],
        ]
        for s in ["B1", "B2", "B3", "B4", "B5"] {
            p.tap("castle.play")
            p.tap("map.place.bridge")
            p.playScene(s, wrongOn: wrong[s] ?? [:])
        }
        p.tap("castle.play")
        p.wait("map.place.bridge")
        p.snap("map after the bridge")
    }
}
