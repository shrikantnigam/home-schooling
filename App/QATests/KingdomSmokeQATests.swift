import XCTest

/// Quick Kingdom check (Shrikant, 2026-11-03): one short scene from each place after Kingdom 1, so a change to
/// shared code (speech, the app model, saved progress) is caught in minutes without replaying every scene.
/// The full Kingdom2 to Kingdom6 suites still run before every merge to main (`tools/qa_run.sh all`).
final class KingdomSmokeQATests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private func firstScene(_ scene: String, place: String) {
        let p = QAPlayer(self, prefix: "smoke-\(scene.lowercased())")
        p.launch(preset: scene)
        p.tap("castle.play")
        p.tap("map.place.\(place)")
        p.playScene(scene, snapItems: false)
        p.tap("castle.play")
        p.wait("map.place.\(place)")
    }

    func test01_Bridge_B1() { firstScene("B1", place: "bridge") }
    func test02_Goblin_K1() { firstScene("K1", place: "goblin") }
    func test03_Ball_R1() { firstScene("R1", place: "ball") }
    func test04_Feast_F1() { firstScene("F1", place: "feast") }
    func test05_Moon_M1() { firstScene("M1", place: "moon") }
}
