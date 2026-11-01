import XCTest
@testable import KingdomCore

/// AC-S1, AC-S2, AC-S3, AC-S4, AC-S6, AC-M7, AC-M8, AC-P6, AC-P7, charter L12, L13 and S11.
final class ProgressionTests: XCTestCase {
    let content = T.content()
    var progression: Progression { Progression(content: content, engine: T.engine) }

    // AC-S1, L12: a fresh install opens with the Prologue's challenge.
    func testFreshInstallStartsWithTheChallenge() {
        XCTAssertEqual(progression.next(state: LearnerState()), .scene("P0"))
        XCTAssertTrue(progression.isSceneUnlocked("P0", state: LearnerState()))
        XCTAssertFalse(progression.isSceneUnlocked("P1", state: LearnerState()))
        XCTAssertEqual(content.scene("P0")?.isChallenge, true)
    }

    func testScenesUnlockInStoryOrder() {
        var s = LearnerState()
        s.completedScenes = ["P0"]
        XCTAssertTrue(progression.isSceneUnlocked("P1", state: s))
        XCTAssertFalse(progression.isSceneUnlocked("P2", state: s))
        XCTAssertEqual(progression.next(state: s), .scene("P1"))
    }

    // S11: finishing the Prologue's scenes opens several places at once.
    func testFinishingPrologueOpensGardenBallAndFeast() {
        var s = LearnerState()
        T.completeScenes("prologue", in: &s, content: content)
        XCTAssertEqual(progression.placeState("prologue", state: s), .done)
        for ch in ["garden", "ball", "feast"] {
            XCTAssertTrue(progression.isChapterUnlocked(ch, state: s), ch)
        }
        for ch in ["bridge", "goblin", "moon"] {
            XCTAssertEqual(progression.placeState(ch, state: s), .locked, ch)
        }
        XCTAssertEqual(progression.newlyOpened(state: s), ["garden", "ball", "feast"])
        XCTAssertEqual(progression.next(state: s), .scene("G1"))
    }

    // S11 and the skill map: the Garden opens the Bridge and the Cave; the Moon opens after the Feast's first scene.
    func testOpenKingdomFollowsTheSkillMap() {
        var s = LearnerState()
        T.completeScenes("prologue", in: &s, content: content)
        T.completeScenes("garden", in: &s, content: content)
        XCTAssertFalse(progression.isChapterUnlocked("bridge", state: s), "garden skills not secure yet")
        XCTAssertEqual(progression.placeState("garden", state: s), .practice)
        T.master("garden", in: &s, content: content)
        XCTAssertTrue(progression.isChapterUnlocked("bridge", state: s))
        XCTAssertTrue(progression.isChapterUnlocked("goblin", state: s))
        XCTAssertFalse(progression.isChapterUnlocked("moon", state: s))
        s.completedScenes.insert("F1")
        XCTAssertTrue(progression.isChapterUnlocked("moon", state: s))
    }

    // Skill map: the Cave's "take from ten" scenes wait for the Bridge.
    func testSceneWaitsForAnotherPlace() {
        var s = LearnerState()
        T.completeScenes("prologue", in: &s, content: content)
        T.completeScenes("garden", in: &s, content: content)
        T.master("garden", in: &s, content: content)
        for id in ["K1", "K2", "K3"] { s.completedScenes.insert(id) }
        XCTAssertEqual(progression.placeState("goblin", state: s), .waiting(next: "K4", on: ["bridge"]))
        XCTAssertFalse(progression.isSceneUnlocked("K4", state: s))
        T.completeScenes("bridge", in: &s, content: content)
        T.master("bridge", in: &s, content: content)
        XCTAssertEqual(progression.placeState("goblin", state: s), .open(next: "K4"))
    }

    func testMoonFinaleNeedsEveryPlace() {
        var s = LearnerState()
        for ch in ["prologue", "feast"] { T.completeScenes(ch, in: &s, content: content) }
        T.master("ball", in: &s, content: content)
        T.master("feast", in: &s, content: content)
        for id in ["M1", "M2", "M3"] { s.completedScenes.insert(id) }
        guard case .waiting(next: "M4", let on) = progression.placeState("moon", state: s) else {
            return XCTFail("M4 should wait for the other places")
        }
        XCTAssertTrue(on.contains("garden"))
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
        s.needsPractice = ["p1-4"]
        s.testedOutSkills = ["count"]
        s.resetSkill("count", content: content)
        XCTAssertEqual(T.engine.status(s.skills["count"]), .notStarted)
        XCTAssertFalse(s.needsPractice.contains("p1-4"))
        XCTAssertFalse(s.testedOutSkills.contains("count"))
        XCTAssertFalse(progression.chapterMastered("prologue", state: s))
    }

    // AC-P7
    func testResetAllReturnsToFreshInstallButKeepsParentSettings() {
        var s = LearnerState()
        T.completeScenes("prologue", in: &s, content: content)
        s.timeSettings.setDailyLimit(10)
        s.hasMetSparkle = true
        s.resetAllProgress()
        XCTAssertEqual(progression.next(state: s), .scene("P0"))
        XCTAssertFalse(s.hasMetSparkle)
        XCTAssertEqual(s.timeSettings.dailyLimitMinutes, 10)
    }

    func testPracticeScenePutsNeedsPracticeItemsFirst() {
        var s = LearnerState()
        T.completeScenes("prologue", in: &s, content: content)
        s.needsPractice = ["p1-7", "p2-q5"]
        let p = progression.practiceScene(for: "prologue", state: s)
        XCTAssertEqual(Array(p.items.prefix(2)).map(\.id).sorted(), ["p1-7", "p2-q5"])
        XCTAssertEqual(p.items.count, 8)
        XCTAssertEqual(Set(p.items.map(\.id)).count, 8, "no repeats")
    }

    // Item 10: practice uses the place's own lines.
    func testPracticeLinesBelongToThePlace() {
        let p = progression.practiceScene(for: "bridge", state: LearnerState())
        XCTAssertEqual(p.open.first, "practice.open1.bridge")
        XCTAssertEqual(p.payoff, ["practice.payoff.bridge"])
        for ch in content.chapters {
            XCTAssertNotNil(content.lines["practice.open1.\(ch.id)"], ch.id)
            XCTAssertNotNil(content.lines["map.practice.\(ch.id)"], ch.id)
            if ch.id != "prologue" { XCTAssertNotNil(content.lines["map.awake.\(ch.id)"], ch.id) }
        }
    }

    // L13: practice and replay never ask more than 3 of a kind in a row when there is a choice.
    func testInterleavedBreaksLongRunsOfOneKind() {
        let items = content.items(in: "garden")
        let mixed = Progression.interleaved(items)
        XCTAssertEqual(Set(mixed.map(\.id)), Set(items.map(\.id)))
        var run = 1
        for i in 1..<mixed.count {
            run = mixed[i].kind == mixed[i - 1].kind ? run + 1 : 1
            XCTAssertLessThanOrEqual(run, 3, "at \(i)")
        }
    }

    // L12: a challenge she gets right tests her out of the skills and their scenes.
    func testChallengeAllRightTestsOutOfThePrologue() {
        var s = LearnerState()
        let p0 = content.scene("P0")!
        let firstTry = Dictionary(uniqueKeysWithValues: p0.items.map { ($0.id, true) })
        let passed = progression.applyChallenge(p0, firstTry: firstTry, state: &s)
        progression.complete(p0, state: &s, at: T.day1)
        XCTAssertEqual(passed, ["count", "cardinality", "lineFind", "subitize"])
        XCTAssertEqual(s.completedScenes, ["P0", "P1", "P2"])
        XCTAssertEqual(s.level(for: "count"), .abstract)
        XCTAssertEqual(progression.placeState("prologue", state: s), .done)
        XCTAssertTrue(progression.isChapterUnlocked("garden", state: s), "fast learner reaches the next place in one session")
    }

    func testChallengeWithAMissOnlySkipsWhatSheKnows() {
        var s = LearnerState()
        let p0 = content.scene("P0")!
        var firstTry = Dictionary(uniqueKeysWithValues: p0.items.map { ($0.id, true) })
        firstTry["p0-q5"] = false // quick look missed
        let passed = progression.applyChallenge(p0, firstTry: firstTry, state: &s)
        progression.complete(p0, state: &s, at: T.day1)
        XCTAssertFalse(passed.contains("subitize"))
        XCTAssertTrue(s.completedScenes.contains("P1"), "counting scene skipped")
        XCTAssertFalse(s.completedScenes.contains("P2"), "quick look scene still to play")
        XCTAssertEqual(s.level(for: "subitize"), .concrete)
        XCTAssertEqual(progression.next(state: s), .scene("P2"))
    }

    func testTestedOutSkillCountsAsSecure() {
        var s = LearnerState()
        T.completeScenes("prologue", in: &s, content: content)
        T.completeScenes("garden", in: &s, content: content)
        s.testedOutSkills = Set(content.skills(in: "garden").map(\.id))
        XCTAssertTrue(progression.chapterPassesGate("garden", state: s))
        XCTAssertTrue(progression.isChapterUnlocked("bridge", state: s))
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
        s.resume = ResumePoint(sceneID: "P2", itemIDs: ["a", "b"], warmupCount: 1, index: 1)
        s.testedOutSkills = ["count"]
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

    func testFirstScenesHaveNoWarmup() {
        XCTAssertEqual(content.scene("P0")!.warmupCount, 0)
        XCTAssertEqual(content.scene("P1")!.warmupCount, 0)
        var run = SceneRun(scene: content.scene("P1")!, warmups: [])
        run.advance()
        XCTAssertEqual(run.phase, .core(index: 0))
    }

    // AC-P3 and item 11: finish the current item, say "we'll finish tomorrow", and resume at the next item.
    func testWrapUpFinishesCurrentItemThenPausesForTomorrow() {
        let scene = content.scene("G1")!
        let warm = Array(content.scene("P1")!.items.prefix(2))
        var run = SceneRun(scene: scene, warmups: warm)
        run.advance(); run.advance(); run.advance() // core 0
        run.advance() // core 1
        run.beginWrapUp()
        XCTAssertEqual(run.phase, .core(index: 1), "never cut off mid-item")
        run.advance()
        XCTAssertEqual(run.phase, .payoff)
        XCTAssertTrue(run.cutShort)
        run.advance()
        XCTAssertEqual(run.phase, .finished, "no goodbye story after a pause")
        XCTAssertFalse(run.completedAllItems, "skipped items mean the scene stays open")
        let point = run.pausePoint()!
        XCTAssertEqual(point.index, 2 + 2)
        let resumed = SceneRun(scene: scene, warmups: warm, resumeAt: point.index)
        XCTAssertEqual(resumed.phase, .core(index: 2))
    }

    // L13: four right in a row at the Numbers level ends the scene early with its payoff.
    func testFourRightInARowAtTopLevelEndsEarly() {
        var run = SceneRun(scene: content.scene("G1")!, warmups: [])
        run.advance()
        for _ in 0..<3 { run.noteResult(firstTry: true, atTopLevel: true); run.advance() }
        XCTAssertEqual(run.phase, .core(index: 3))
        run.noteResult(firstTry: true, atTopLevel: true)
        run.advance()
        XCTAssertEqual(run.phase, .payoff)
        XCTAssertTrue(run.endedEarly)
        while run.phase != .finished { run.advance() }
        XCTAssertTrue(run.completedAllItems)
    }

    func testStreakBelowTopLevelDoesNotEndEarlyAndAMissResets() {
        var run = SceneRun(scene: content.scene("G1")!, warmups: [])
        run.advance()
        for ok in [true, true, true, false, true, true, true] {
            run.noteResult(firstTry: ok, atTopLevel: true)
            run.advance()
        }
        XCTAssertFalse(run.endedEarly)
        var low = SceneRun(scene: content.scene("G1")!, warmups: [])
        low.advance()
        for _ in 0..<5 { low.noteResult(firstTry: true, atTopLevel: false); low.advance() }
        XCTAssertFalse(low.endedEarly)
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
        s.completedScenes = ["P0", "P1"]
        s.needsPractice = ["p1-7"]
        for i in content.scene("P0")!.items + content.scene("P1")!.items { s.lastSeen[i.id] = T.day2 }
        let picker = WarmupPicker(content: content, calendar: T.calendar)
        for seed in 0..<20 as Range<UInt64> {
            let w = picker.pick(for: content.scene("P2")!, count: 2, state: s, now: T.day2, seed: seed)
            XCTAssertEqual(w.count, 2)
            XCTAssertTrue(w.contains { $0.id == "p1-7" }, "seed \(seed)")
        }
    }

    func testWarmupMixesRecentAndOlderChapters() {
        var s = LearnerState()
        s.completedScenes = ["P0", "P1", "P2", "G1", "G2"]
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
        s.completedScenes = ["P0", "P1"]
        let picker = WarmupPicker(content: content, calendar: T.calendar)
        let a = picker.pick(for: content.scene("P2")!, count: 2, state: s, now: T.day1, seed: 42)
        let b = picker.pick(for: content.scene("P2")!, count: 2, state: s, now: T.day1, seed: 42)
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

    /// The Prologue is done and the Garden's scenes are finished; the Bridge waits on the Garden's gate.
    func gardenPlayed() -> LearnerState {
        var s = LearnerState()
        T.completeScenes("prologue", in: &s, content: content)
        T.completeScenes("garden", in: &s, content: content)
        return s
    }

    func testSecureGateOpensAtFourOfFive() {
        var s = gardenPlayed()
        secure("garden", in: &s)
        XCTAssertTrue(progression.isChapterUnlocked("bridge", state: s))
        XCTAssertEqual(progression.placeState("garden", state: s), .done)
        XCTAssertFalse(progression.chapterMastered("garden", state: s), "secure is not yet mastered")
    }

    // L12: spacing is for review, not gating. One day is enough; four of five right is still needed.
    func testSecureGateNeedsFourRightButNotTwoDays() {
        var s = gardenPlayed()
        secure("garden", in: &s, days: 1)
        XCTAssertTrue(progression.isChapterUnlocked("bridge", state: s))
        secure("garden", in: &s, correct: 3)
        XCTAssertFalse(progression.isChapterUnlocked("bridge", state: s))
    }

    func testPrologueOpensOnScenesWhateverTheGate() {
        var s = LearnerState()
        s.chapterGate = .mastered
        T.completeScenes("prologue", in: &s, content: content)
        XCTAssertTrue(progression.isChapterUnlocked("garden", state: s))
    }

    func testSecureNeedsAbstractLevel() {
        var rec = SkillRecord()
        rec.level = .pictorial
        for i in 0..<5 { rec.history.append(T.result(level: .pictorial, correct: true, date: i < 3 ? T.day1 : T.day2)) }
        XCTAssertFalse(T.engine.isSecure(rec))
    }

    func testMasteredGateIsStricter() {
        var s = gardenPlayed()
        s.chapterGate = .mastered
        secure("garden", in: &s)
        XCTAssertFalse(progression.isChapterUnlocked("bridge", state: s))
        T.master("garden", in: &s, content: content)
        XCTAssertTrue(progression.isChapterUnlocked("bridge", state: s))
    }

    func testScenesOnlyGate() {
        var s = LearnerState()
        s.chapterGate = .scenesOnly
        T.completeScenes("prologue", in: &s, content: content)
        XCTAssertFalse(progression.isChapterUnlocked("bridge", state: s))
        T.completeScenes("garden", in: &s, content: content)
        XCTAssertTrue(progression.isChapterUnlocked("bridge", state: s))
    }

    func testOldSaveFilesDecodeWithDefaultGate() throws {
        let json = #"{"version":1,"hasMetSparkle":true}"#
        let s = try JSONDecoder().decode(LearnerState.self, from: Data(json.utf8))
        XCTAssertEqual(s.chapterGate, .secure)
        XCTAssertTrue(s.hasMetSparkle)
        XCTAssertTrue(s.testedOutSkills.isEmpty)
    }

    func testResetKeepsGate() {
        var s = LearnerState()
        s.chapterGate = .scenesOnly
        s.resetAllProgress()
        XCTAssertEqual(s.chapterGate, .scenesOnly)
    }
}

final class AbstractOnlySkillTests: XCTestCase {
    func testNumeralOnlySkillStartsAtAbstractSoItCanBecomeSecure() {
        var s = LearnerState()
        for i in 0..<5 {
            s.apply(T.result("subtract20", level: .abstract, correct: true, date: i < 3 ? T.day1 : T.day2, item: "k5-\(i)"),
                    engine: T.engine)
        }
        XCTAssertEqual(s.level(for: "subtract20"), .abstract)
        XCTAssertTrue(T.engine.isSecure(s.record(for: "subtract20")))
    }

    func testExistingSkillLevelIsNotJumped() {
        var s = LearnerState()
        s.apply(T.result("add", level: .concrete, correct: true, item: "g1"), engine: T.engine)
        s.apply(T.result("add", level: .abstract, correct: true, item: "g5"), engine: T.engine)
        XCTAssertEqual(s.level(for: "add"), .concrete)
    }
}
