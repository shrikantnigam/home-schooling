import XCTest
@testable import KingdomCore

/// AC-S1, AC-S2, AC-S3, AC-S4, AC-S6, AC-M6, AC-M7, AC-M8, AC-P6, AC-P7.
final class ProgressionTests: XCTestCase {
    let content = T.content()
    var progression: Progression { Progression(content: content, engine: T.engine) }

    // AC-S1
    func testFreshInstallStartsAtP1() {
        XCTAssertEqual(progression.next(state: LearnerState()), .scene("P1"))
        XCTAssertTrue(progression.isSceneUnlocked("P1", state: LearnerState()))
        XCTAssertFalse(progression.isSceneUnlocked("P2", state: LearnerState()))
    }

    func testScenesUnlockInStoryOrder() {
        var s = LearnerState()
        s.completedScenes = ["P1"]
        XCTAssertTrue(progression.isSceneUnlocked("P2", state: s))
        XCTAssertFalse(progression.isSceneUnlocked("P3", state: s))
        XCTAssertEqual(progression.next(state: s), .scene("P2"))
    }

    // AC-M6
    func testGardenLockedUntilPrologueMasteredAndPracticeOffered() {
        var s = LearnerState()
        T.completeScenes("prologue", in: &s, content: content)
        XCTAssertFalse(progression.isChapterUnlocked("garden", state: s))
        XCTAssertFalse(progression.isSceneUnlocked("G1", state: s))
        XCTAssertEqual(progression.placeState("prologue", state: s), .practice)
        XCTAssertEqual(progression.placeState("garden", state: s), .locked)
        XCTAssertEqual(progression.next(state: s), .practice("prologue"))
    }

    // AC-S4
    func testMasteringPrologueUnlocksGarden() {
        var s = LearnerState()
        T.completeScenes("prologue", in: &s, content: content)
        T.master("prologue", in: &s, content: content)
        XCTAssertTrue(progression.isChapterUnlocked("garden", state: s))
        XCTAssertEqual(progression.placeState("prologue", state: s), .done)
        XCTAssertEqual(progression.placeState("garden", state: s), .open(next: "G1"))
        XCTAssertEqual(progression.next(state: s), .scene("G1"))
    }

    // AC-P6
    func testParentUnlockOpensChapterImmediately() {
        var s = LearnerState()
        s.unlockedChapters.insert("garden")
        XCTAssertTrue(progression.isChapterUnlocked("garden", state: s))
        XCTAssertTrue(progression.isSceneUnlocked("G1", state: s))
    }

    func testParentResetSkillTakesEffect() {
        var s = LearnerState()
        T.master("prologue", in: &s, content: content)
        s.needsPractice = ["p1-3"]
        s.resetSkill("count", content: content)
        XCTAssertEqual(T.engine.status(s.skills["count"]), .notStarted)
        XCTAssertFalse(s.needsPractice.contains("p1-3"))
        XCTAssertFalse(progression.chapterMastered("prologue", state: s))
    }

    // AC-P7
    func testResetAllReturnsToFreshInstallButKeepsParentSettings() {
        var s = LearnerState()
        T.completeScenes("prologue", in: &s, content: content)
        s.timeSettings.setDailyLimit(10)
        s.hasMetSparkle = true
        s.resetAllProgress()
        XCTAssertEqual(progression.next(state: s), .scene("P1"))
        XCTAssertFalse(s.hasMetSparkle)
        XCTAssertEqual(s.timeSettings.dailyLimitMinutes, 10)
    }

    func testPracticeScenePutsNeedsPracticeItemsFirst() {
        var s = LearnerState()
        T.completeScenes("prologue", in: &s, content: content)
        s.needsPractice = ["p3-7", "p4-5"]
        let p = progression.practiceScene(for: "prologue", state: s)
        XCTAssertEqual(Array(p.items.prefix(2)).map(\.id).sorted(), ["p3-7", "p4-5"])
        XCTAssertEqual(p.items.count, 8)
        XCTAssertEqual(Set(p.items.map(\.id)).count, 8, "no repeats")
    }

    func testCompletingPracticeDoesNotAddScene() {
        var s = LearnerState()
        let p = progression.practiceScene(for: "prologue", state: s)
        progression.complete(p, state: &s, at: T.day1)
        XCTAssertTrue(s.completedScenes.isEmpty)
        XCTAssertEqual(s.time.scenesByDay.values.reduce(0, +), 1)
    }

    func testApplyUpdatesPracticeListAndLevel() {
        var s = LearnerState()
        s.apply(T.result("add", level: .concrete, correct: false, needsPractice: true, item: "g1-3+2"), engine: T.engine)
        XCTAssertTrue(s.needsPractice.contains("g1-3+2"))
        s.apply(T.result("add", level: .concrete, correct: true, item: "g1-3+2"), engine: T.engine)
        XCTAssertFalse(s.needsPractice.contains("g1-3+2"))
        XCTAssertEqual(s.lastSeen["g1-3+2"], T.day1)
    }

    // AC-M8
    func testStateSurvivesSaveAndLoad() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString).appendingPathComponent("learner.json")
        let store = StateStore(url: url)
        var s = LearnerState()
        s.apply(T.result("add", level: .concrete, correct: true, item: "g1-3+2"), engine: T.engine)
        s.completedScenes = ["P1", "P2"]
        s.unlockedChapters = ["garden"]
        s.resume = ResumePoint(sceneID: "P3", itemIDs: ["a", "b"], warmupCount: 1, index: 1)
        s.time.addPlay(seconds: 300, at: T.day1, calendar: T.calendar)
        try store.save(s)
        let loaded = store.load()
        XCTAssertEqual(loaded, s)
    }

    func testCorruptFileLoadsFreshState() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        try Data("not json".utf8).write(to: url)
        XCTAssertEqual(StateStore(url: url).load(), LearnerState())
    }
}

final class SceneRunTests: XCTestCase {
    let content = T.content()

    // AC-S2
    func testPhasesRunInOrder() {
        let scene = content.scene("P2")!
        let warm = Array(content.scene("P1")!.items.prefix(2))
        var run = SceneRun(scene: scene, warmups: warm)
        var phases: [StoryPhase] = [run.phase]
        while run.phase != .finished { run.advance(); phases.append(run.phase) }
        XCTAssertEqual(phases.first, .open)
        XCTAssertEqual(phases[1], .warmup(index: 0))
        XCTAssertEqual(phases[2], .warmup(index: 1))
        XCTAssertEqual(phases[3], .core(index: 0))
        XCTAssertEqual(phases.suffix(3), [.payoff, .goodbye, .finished])
        XCTAssertEqual(phases.count, 1 + 2 + scene.items.count + 3)
        XCTAssertTrue(run.completedAllItems)
    }

    func testP1HasNoWarmup() {
        XCTAssertEqual(content.scene("P1")!.warmupCount, 0)
        var run = SceneRun(scene: content.scene("P1")!, warmups: [])
        run.advance()
        XCTAssertEqual(run.phase, .core(index: 0))
    }

    // AC-P3: finish the current item, then payoff and goodbye.
    func testWrapUpFinishesCurrentItemThenPayoff() {
        var run = SceneRun(scene: content.scene("G1")!, warmups: [])
        run.advance() // core 0
        run.advance() // core 1
        run.beginWrapUp()
        XCTAssertEqual(run.phase, .core(index: 1), "never cut off mid-item")
        run.advance()
        XCTAssertEqual(run.phase, .payoff)
        run.advance()
        XCTAssertEqual(run.phase, .goodbye)
        run.advance()
        XCTAssertFalse(run.completedAllItems, "skipped items mean the scene stays open")
    }

    func testWrapUpOnLastItemStillCompletes() {
        let scene = content.scene("P1")!
        var run = SceneRun(scene: scene, warmups: [], resumeAt: scene.items.count - 1)
        run.beginWrapUp()
        while run.phase != .finished { run.advance() }
        XCTAssertTrue(run.completedAllItems)
    }

    // AC-S6
    func testResumeStartsAtSameItem() {
        let scene = content.scene("P2")!
        let warm = Array(content.scene("P1")!.items.prefix(2))
        var run = SceneRun(scene: scene, warmups: warm)
        run.advance(); run.advance(); run.advance(); run.advance()
        let point = run.resumePoint()!
        XCTAssertEqual(point.index, 3)
        let resumed = SceneRun(scene: scene, warmups: warm, resumeAt: point.index)
        XCTAssertEqual(resumed.currentItem, run.currentItem)
        XCTAssertEqual(resumed.phase, .core(index: 1))
    }

    // AC-M7
    func testWarmupIncludesNeedsPracticeItem() {
        var s = LearnerState()
        s.completedScenes = ["P1", "P2", "P3"]
        s.needsPractice = ["p2-7"]
        for i in content.scene("P1")!.items + content.scene("P3")!.items { s.lastSeen[i.id] = T.day2 }
        let picker = WarmupPicker(content: content, calendar: T.calendar)
        for seed in 0..<20 as Range<UInt64> {
            let w = picker.pick(for: content.scene("P4")!, count: 2, state: s, now: T.day2, seed: seed)
            XCTAssertEqual(w.count, 2)
            XCTAssertTrue(w.contains { $0.id == "p2-7" }, "seed \(seed)")
        }
    }

    func testWarmupMixesRecentAndOlderChapters() {
        var s = LearnerState()
        s.completedScenes = ["P1", "P2", "P3", "P4", "G1", "G2"]
        let picker = WarmupPicker(content: content, calendar: T.calendar)
        let w = picker.pick(for: content.scene("G3")!, count: 5, state: s, now: T.day1, seed: 7)
        XCTAssertEqual(w.count, 5)
        let garden = w.filter { content.skill($0.skill)?.chapter == "garden" }.count
        XCTAssertEqual(garden, 3, "60% of 5 from the latest chapter")
        XCTAssertEqual(Set(w.map(\.id)).count, 5)
        XCTAssertTrue(w.allSatisfy { !content.scene("G3")!.items.contains($0) })
    }

    func testWarmupIsEmptyBeforeAnythingIsDone() {
        let picker = WarmupPicker(content: content, calendar: T.calendar)
        XCTAssertTrue(picker.pick(for: content.scene("P1")!, count: 2, state: LearnerState(), now: T.day1, seed: 1).isEmpty)
    }

    func testWarmupIsRepeatableForASeed() {
        var s = LearnerState()
        s.completedScenes = ["P1", "P2", "P3"]
        let picker = WarmupPicker(content: content, calendar: T.calendar)
        let a = picker.pick(for: content.scene("P4")!, count: 2, state: s, now: T.day1, seed: 42)
        let b = picker.pick(for: content.scene("P4")!, count: 2, state: s, now: T.day1, seed: 42)
        XCTAssertEqual(a, b)
    }
}

/// The chapter gate chosen after the Chapter 1 retro.
final class ChapterGateTests: XCTestCase {
    let content = T.content()
    var progression: Progression { Progression(content: content, engine: T.engine) }

    /// Puts every skill of a chapter at Abstract with 5 first-try results over 2 days.
    func secure(_ chapter: ChapterID, in s: inout LearnerState, correct: Int = 5, days: Int = 2) {
        for sk in content.skills(in: chapter) {
            var rec = SkillRecord()
            rec.level = .abstract
            for i in 0..<5 {
                rec.history.append(T.result(sk.id, level: .abstract, correct: i < correct, date: days == 2 && i >= 3 ? T.day2 : T.day1))
            }
            s.skills[sk.id] = rec
        }
    }

    func testSecureIsTheDefault() {
        XCTAssertEqual(LearnerState().chapterGate, .secure)
    }

    func testSecureGateOpensAtFourOfFiveOverTwoDays() {
        var s = LearnerState()
        T.completeScenes("prologue", in: &s, content: content)
        secure("prologue", in: &s)
        XCTAssertTrue(progression.isChapterUnlocked("garden", state: s))
        XCTAssertEqual(progression.placeState("prologue", state: s), .done)
        XCTAssertFalse(progression.chapterMastered("prologue", state: s), "secure is not yet mastered")
    }

    func testSecureGateNeedsTwoDaysAndFourRight() {
        var s = LearnerState()
        secure("prologue", in: &s, days: 1)
        XCTAssertFalse(progression.isChapterUnlocked("garden", state: s))
        secure("prologue", in: &s, correct: 3)
        XCTAssertFalse(progression.isChapterUnlocked("garden", state: s))
    }

    func testSecureNeedsAbstractLevel() {
        var rec = SkillRecord()
        rec.level = .pictorial
        for i in 0..<5 { rec.history.append(T.result(level: .pictorial, correct: true, date: i < 3 ? T.day1 : T.day2)) }
        XCTAssertFalse(T.engine.isSecure(rec))
    }

    func testMasteredGateIsStricter() {
        var s = LearnerState()
        s.chapterGate = .mastered
        secure("prologue", in: &s)
        XCTAssertFalse(progression.isChapterUnlocked("garden", state: s))
        T.master("prologue", in: &s, content: content)
        XCTAssertTrue(progression.isChapterUnlocked("garden", state: s))
    }

    func testScenesOnlyGate() {
        var s = LearnerState()
        s.chapterGate = .scenesOnly
        XCTAssertFalse(progression.isChapterUnlocked("garden", state: s))
        T.completeScenes("prologue", in: &s, content: content)
        XCTAssertTrue(progression.isChapterUnlocked("garden", state: s))
    }

    func testOldSaveFilesDecodeWithDefaultGate() throws {
        let json = #"{"version":1,"hasMetSparkle":true}"#
        let s = try JSONDecoder().decode(LearnerState.self, from: Data(json.utf8))
        XCTAssertEqual(s.chapterGate, .secure)
        XCTAssertTrue(s.hasMetSparkle)
    }

    func testResetKeepsGate() {
        var s = LearnerState()
        s.chapterGate = .scenesOnly
        s.resetAllProgress()
        XCTAssertEqual(s.chapterGate, .scenesOnly)
    }
}
