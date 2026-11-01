import XCTest

/// QA play-through for Chapter 3: The Goblin's Gems (docs/chapters/chapter-3.md).
final class Chapter3PlaythroughTests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    /// AC-3a to AC-3d: all five scenes, one wrong path per activity kind, the full ladder once.
    func test01_Goblin_K1toK5() {
        let p = QAPlayer(self, prefix: "c3-01")
        p.launch(preset: "K1")
        let wrong: [String: [String: Int]] = [
            "K1": ["k1-9-4": 3],
            "K2": ["k2-12-4": 1],
            "K3": ["k3-9-5": 2],
            "K4": ["k4-15-6": 1],
            "K5": ["k5-13-5": 1],
        ]
        for s in ["K1", "K2", "K3", "K4", "K5"] {
            p.tap("castle.play")
            p.tap("map.place.goblin")
            p.playScene(s, wrongOn: wrong[s] ?? [:])
        }
        p.tap("castle.play")
        p.wait("map.place.goblin")
        p.snap("map after the goblin")
    }

    /// K5 help: the gems picture is one tap away and counts as help.
    func test02_K5_HelpShowsGems() {
        let p = QAPlayer(self, prefix: "c3-02")
        p.launch(preset: "K5")
        p.tap("castle.play")
        p.tap("map.place.goblin")
        p.wait("panel.open.K5")
        p.tapNext()
        var item = p.currentItem()!
        while !item.id.hasPrefix("k5") { p.solve(item, snapEach: false); item = p.currentItem()! }
        p.snap("K5 numbers with help button")
        p.tap("help.flowerBox")
        p.snap("K5 gems shown as help")
        p.answer(item.answer, for: item)
        p.tapNext()
    }
}
