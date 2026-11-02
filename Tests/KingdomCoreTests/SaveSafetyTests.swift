import XCTest
@testable import KingdomCore

/// Her saved play must survive every app update (Shrikant, 2026-11-02: "how can i ensure that my daughters play
/// is not lost"). Two guards:
/// 1. Saves written by earlier versions still load. Each fixture in `Fixtures/` is a real save written by an
///    older build; it must decode to the same state it was written from. Never edit or delete a fixture: a change
///    that breaks one would wipe her progress on her iPad.
/// 2. The store never overwrites a file it couldn't read, and keeps a backup of the last good save.
final class SaveSafetyTests: XCTestCase {

    // MARK: Old saves still load

    static let fixturesDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures")

    /// The state the 2026-11-02 fixture was written from (made-up test data, no personal details).
    static func sampleNov2() -> LearnerState {
        var s = LearnerState()
        s.completeSetup(SetupChoices(heroName: "Test Child", companion: .gnome, dailyLimitMinutes: 30))
        s.hasMetSparkle = true
        s.chapterGate = .secure
        s.completedScenes = ["P1", "P2", "G1", "G2"]
        s.unlockedChapters = ["moon"]
        s.testedOutSkills = ["count-to-10"]
        s.wroteDown = ["garden"]
        s.needsPractice = ["G2-3"]
        s.resume = ResumePoint(sceneID: "G3", itemIDs: ["G3-1", "G3-2", "G3-3"], warmupCount: 1, index: 2)
        for (i, correct) in [true, true, false, true].enumerated() {
            s.apply(T.result("add-within-5", level: .pictorial, correct: correct, date: i < 2 ? T.day1 : T.day2,
                             item: "G1-\(i)"), engine: T.engine)
        }
        s.lastSeen["G1-0"] = T.day1
        s.time.addPlay(seconds: 600, at: T.day1, calendar: T.calendar)
        s.board.record(.add, firstTry: true)
        s.board.record(.add, firstTry: true)
        s.board.record(.subtract, firstTry: false)
        s.board.lanterns = 3
        s.board.puzzlesMade = 1
        s.sheets["garden"] = SheetRecord(finished: T.day2, firstTry: 5, checked: 8, feedback: .easy)
        s.jigsaw.finishPicture(JigsawResult(kind: "picture", pictureID: "castle", pieces: 10, firstFits: 9,
                                            hintsUsed: 1, maxHintStep: 1, strategy: "edges", date: T.day1))
        s.jigsaw.finishNumberLine(JigsawResult(kind: "line", pictureID: nil, pieces: 10, firstFits: 10,
                                               hintsUsed: 0, maxHintStep: 0, strategy: nil, date: T.day2))
        return s
    }

    func testSaveFromNov2StillLoads() throws {
        let url = Self.fixturesDir.appendingPathComponent("learner-2026-11-02.json")
        if ProcessInfo.processInfo.environment["WRITE_SAVE_FIXTURE"] == "1" {
            try StateStore(url: url, keepsBackup: false).save(Self.sampleNov2())
        }
        guard FileManager.default.fileExists(atPath: url.path) else {
            return XCTFail("Missing \(url.lastPathComponent). Write it once with WRITE_SAVE_FIXTURE=1 swift test")
        }
        let loaded = try XCTUnwrap(StateStore.decode(url), "a save from 2026-11-02 no longer decodes")
        XCTAssertEqual(loaded, Self.sampleNov2(), "a save from 2026-11-02 loads with different progress")
        XCTAssertEqual(loaded.heroName, "Test Child")
        XCTAssertFalse(loaded.needsSetup)
    }

    // MARK: The store never loses a save

    private var dir: URL!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent("save-safety-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    private func played(_ scenes: Set<SceneID>) -> LearnerState {
        var s = LearnerState()
        s.completedScenes = scenes
        return s
    }

    func testSecondSaveKeepsTheFirstAsBackup() throws {
        let store = StateStore(url: dir.appendingPathComponent("learner.json"))
        try store.save(played(["P1"]))
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.backupURL.path), "nothing to back up yet")
        try store.save(played(["P1", "P2"]))
        XCTAssertEqual(StateStore.decode(store.backupURL)?.completedScenes, ["P1"])
        XCTAssertEqual(store.load().completedScenes, ["P1", "P2"])
    }

    func testUnreadableSaveIsSetAsideNotOverwritten() throws {
        let store = StateStore(url: dir.appendingPathComponent("learner.json"))
        try store.save(played(["P1"]))
        try store.save(played(["P1", "P2"]))
        let garbage = Data("{\"completedScenes\": 42".utf8)
        try garbage.write(to: store.url)

        let loaded = store.load(now: Date(timeIntervalSince1970: 1_000))
        XCTAssertEqual(loaded.completedScenes, ["P1"], "falls back to the last good backup")
        let aside = dir.appendingPathComponent("learner-unreadable-1000.json")
        XCTAssertEqual(try Data(contentsOf: aside), garbage, "the unreadable file is kept, byte for byte")

        // Playing on and saving never touches the set-aside file.
        try store.save(loaded)
        XCTAssertEqual(try Data(contentsOf: aside), garbage)
    }

    func testBadBackupIsNeverCopiedOverAGoodOne() throws {
        let store = StateStore(url: dir.appendingPathComponent("learner.json"))
        try store.save(played(["P1"]))
        try store.save(played(["P1", "P2"]))
        try Data("not json".utf8).write(to: store.url)
        try store.save(played(["G1"]))
        XCTAssertEqual(StateStore.decode(store.backupURL)?.completedScenes, ["P1"], "the good backup stays")
    }

    func testMissingMainFileUsesBackup() throws {
        let store = StateStore(url: dir.appendingPathComponent("learner.json"))
        try store.save(played(["P1"]))
        try store.save(played(["P1", "P2"]))
        try FileManager.default.removeItem(at: store.url)
        XCTAssertEqual(store.load().completedScenes, ["P1"])
    }

    func testNothingSavedStartsFresh() {
        let store = StateStore(url: dir.appendingPathComponent("learner.json"))
        XCTAssertEqual(store.load(), LearnerState())
    }

    func testSnapshotStoreKeepsNoBackup() throws {
        let store = StateStore(url: dir.appendingPathComponent("debug-snapshot.json"), keepsBackup: false)
        try store.save(played(["P1"]))
        try store.save(played(["P2"]))
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.backupURL.path))
    }
}
