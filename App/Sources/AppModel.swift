import KingdomCore
import SwiftUI

/// The app's single source of truth. Holds the saved learner state and routes between screens.
@MainActor
final class AppModel: ObservableObject {
    enum Route: Equatable {
        case castle
        case map
        case scene
        case gate
        case parent
        case setup
    }

    @Published var route: Route = .castle
    @Published var state: LearnerState
    @Published private(set) var scene: SceneController?

    let env = AppEnvironment.current
    let content: Content
    /// Lines with her name and her companion filled in. Rebuilt when setup is done.
    private(set) var catalog: LineCatalog
    let engine: MasteryEngine
    let progression: Progression
    let speech: SpeechPlayer
    private let store: StateStore
    private var ticker: Timer?
    private var lastTick = Date()
    private(set) var isActive = true
    /// Screen intros already spoken since the app was opened. Shrikant: a screen's intro plays the first
    /// time it appears after the app opens; after that it stays quiet and the ear button replays it.
    private var introsSpoken: Set<String> = []

    var calendar: Calendar { engine.calendar }

    /// "Now", shifted by whole days for QA when -dayOffset is passed.
    var now: Date {
        Calendar.current.date(byAdding: .day, value: env.dayOffset, to: Date()) ?? Date()
    }

    init() {
        let content: Content
        do { content = try Content.bundled() } catch { fatalError("content.json is missing or invalid: \(error)") }
        self.content = content
        catalog = LineCatalog(lines: content.lines)
        engine = MasteryEngine()
        progression = Progression(content: content, engine: engine)
        speech = SpeechPlayer(instant: AppEnvironment.current.uiTesting)
        store = env.uiTesting
            ? StateStore(url: FileManager.default.temporaryDirectory.appendingPathComponent("qa-learner.json"))
            : StateStore.defaultStore()
        var loaded = env.reset ? LearnerState() : store.load()
        if env.uiTesting { loaded.sound.subtitles = true }
        state = loaded
        if let preset = env.preset { applyPreset(preset) }
        // QA play-throughs use the setup defaults unless they test the setup screen itself.
        if env.uiTesting && !env.showSetup && state.needsSetup {
            state.completeSetup(SetupChoices(heroName: SetupChoices.defaultName, companion: .unicorn,
                                             dailyLimitMinutes: state.timeSettings.dailyLimitMinutes))
        }
        catalog = LineCatalog(lines: content.lines, heroName: state.heroName, companion: state.companion)
        route = state.needsSetup ? .setup : .castle
        applySound()
        startTicker()
    }

    /// True the first time `key` is asked for since the app opened, false after that.
    func firstTimeThisSession(_ key: String) -> Bool { introsSpoken.insert(key).inserted }

    /// Speaks a screen's intro only the first time the screen appears after the app opens.
    func sayIntroOnce(_ key: String, _ lines: [SpokenLine?]) {
        guard firstTimeThisSession(key) else { return }
        speech.say(lines)
    }

    // MARK: Persistence

    func save() {
        try? store.save(state)
    }

    /// First-launch setup (charter v1.3): saved once, then locked.
    func completeSetup(name: String, companion: Companion, minutes: Int) {
        guard state.completeSetup(SetupChoices(heroName: name, companion: companion, dailyLimitMinutes: minutes)) else { return }
        catalog = LineCatalog(lines: content.lines, heroName: state.heroName, companion: state.companion)
        applySound()
        save()
        route = .castle
    }

    func applySound() {
        speech.companionPitch = state.companion.voicePitch
        speech.rate = Float(state.sound.speechRate)
        speech.volume = Float(state.sound.narrationVolume)
    }

    // MARK: Time limit

    var block: PlayBlock? { state.time.block(at: now, settings: state.timeSettings, calendar: calendar) }

    func setActive(_ active: Bool) {
        if active { lastTick = Date() } else { tick() ; save() }
        isActive = active
    }

    private func startTicker() {
        lastTick = Date()
        ticker = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    /// Counts play time only while a scene is on screen and the app is active.
    func tick() {
        let t = Date()
        let seconds = Int(t.timeIntervalSince(lastTick).rounded())
        lastTick = t
        guard isActive, route == .scene, scene != nil, seconds > 0 else { return }
        state.time.addPlay(seconds: min(seconds, 30), at: now, calendar: calendar)
        if state.time.limitReached(at: now, settings: state.timeSettings, calendar: calendar) {
            scene?.beginWrapUp()
        }
    }

    // MARK: Navigation

    func goCastle() {
        speech.stop()
        if let scene { scene.saveResume() }
        scene = nil
        route = state.needsSetup ? .setup : .castle
        save()
    }

    func goMap() {
        guard block == nil else { route = .castle; return }
        speech.stop()
        route = .map
    }

    /// The castle's big glowing button: resume a scene left mid-way, start P1 on a fresh
    /// install (AC-S1), otherwise open the kingdom map.
    func castlePlay() {
        guard block == nil else { return }
        if let resume = state.resume, startFromResume(resume) { return }
        if state.completedScenes.isEmpty { playNext() } else { goMap() }
    }

    /// Starts whatever comes next in the story.
    func playNext() {
        guard block == nil else { return }
        if let resume = state.resume, startFromResume(resume) { return }
        switch progression.next(state: state) {
        case .scene(let id): start(sceneID: id)
        case .practice(let ch): startPractice(ch)
        case .allDone: goMap()
        }
    }

    func start(sceneID: SceneID) {
        guard block == nil, let s = content.scene(sceneID), progression.isSceneUnlocked(sceneID, state: state) else { return }
        let seed = UInt64(abs(sceneID.hashValue) % 10_000) &+ UInt64(state.time.secondsByDay.count)
        let warm = WarmupPicker(content: content, calendar: calendar)
            .pick(for: s, count: s.warmupCount, state: state, now: now, seed: env.uiTesting ? 1 : seed)
        begin(scene: s, warmups: warm, resumeAt: nil)
    }

    /// A finished place played again (item 15): a fresh mix of its items, least recently seen first.
    func replay(_ chapter: ChapterID) { startPractice(chapter) }

    func startPractice(_ chapter: ChapterID) {
        guard block == nil else { return }
        begin(scene: progression.practiceScene(for: chapter, state: state), warmups: [], resumeAt: nil)
    }

    private func startFromResume(_ r: ResumePoint) -> Bool {
        let items = r.itemIDs.compactMap { content.item($0) }
        guard items.count == r.itemIDs.count, r.warmupCount <= items.count else { state.resume = nil; return false }
        let warm = Array(items.prefix(r.warmupCount))
        let scene: StoryScene
        if let s = content.scene(r.sceneID) {
            scene = s
        } else if r.sceneID.hasPrefix("practice-") {
            let ch = String(r.sceneID.dropFirst("practice-".count))
            scene = progression.practiceScene(chapter: ch, items: Array(items.dropFirst(r.warmupCount)))
        } else {
            state.resume = nil
            return false
        }
        begin(scene: scene, warmups: warm, resumeAt: r.index)
        return true
    }

    private func begin(scene s: StoryScene, warmups: [Item], resumeAt: Int?) {
        speech.stop()
        let controller = SceneController(scene: s, warmups: warmups, resumeAt: resumeAt, model: self)
        scene = controller
        route = .scene
        lastTick = Date()
        controller.start()
    }

    /// Called by the scene after its goodbye (AC-S3: back to the castle, nothing starts by itself).
    func sceneFinished(_ run: SceneRun) {
        if run.completedAllItems {
            if run.scene.isChallenge {
                lastTestOut = progression.applyChallenge(run.scene, firstTry: run.firstTry, state: &state)
            }
            progression.complete(run.scene, state: &state, at: now)
        } else {
            // Cut short by the daily limit: pick up tomorrow at the next item (item 11).
            state.resume = run.pausePoint()
        }
        scene = nil
        route = .castle
        save()
    }

    /// Skills the last challenge showed she knows, for QA and the parent area.
    private(set) var lastTestOut: Set<SkillID> = []

    func record(_ result: ItemResult) {
        state.apply(result, engine: engine)
        save()
    }

    // MARK: Parent area

    func openParentGate() {
        speech.stop()
        scene?.saveResume()
        scene = nil
        route = .gate
    }

    func unlockNextChapter() {
        if let ch = content.chapters.first(where: { !progression.isChapterUnlocked($0.id, state: state) }) {
            state.unlockedChapters.insert(ch.id)
            save()
        }
    }

    func resetSkill(_ id: SkillID) {
        state.resetSkill(id, content: content)
        save()
    }

    func resetAll() {
        state.resetAllProgress()
        catalog = LineCatalog(lines: content.lines, heroName: state.heroName, companion: state.companion)
        introsSpoken = []
        save()
    }

    // MARK: QA presets

    private func applyPreset(_ name: String) {
        switch name {
        case "prologueDone":
            for s in content.chapter("prologue")?.scenes ?? [] { state.completedScenes.insert(s) }
            masterChapter("prologue")
            state.hasMetSparkle = true
        case "prologueScenesDone":
            for s in content.chapter("prologue")?.scenes ?? [] { state.completedScenes.insert(s) }
            state.hasMetSparkle = true
        case "gardenScenesDone":
            for ch in ["prologue", "garden"] {
                for s in content.chapter(ch)?.scenes ?? [] { state.completedScenes.insert(s) }
            }
            masterChapter("prologue")
            state.hasMetSparkle = true
        case "nearLimit":
            // A few seconds of play left: the limit runs out during the first scene (item 11).
            state.time.addPlay(seconds: state.timeSettings.dailyLimitMinutes * 60 - 3, at: now, calendar: calendar)
            state.hasMetSparkle = true
        case "limitReached":
            state.time.addPlay(seconds: state.timeSettings.dailyLimitMinutes * 60, at: now, calendar: calendar)
            state.hasMetSparkle = true
        case "sampleProgress":
            for s in content.chapter("prologue")?.scenes ?? [] { state.completedScenes.insert(s) }
            masterChapter("prologue")
            state.completedScenes.insert("G1")
            for (i, item) in (content.scene("G1")?.items ?? []).enumerated() {
                state.apply(ItemResult(itemID: item.id, skill: item.skill, level: .concrete, firstTryCorrect: i % 3 != 0,
                                       needsPractice: i == 0, date: now), engine: engine)
            }
            for back in 0..<6 {
                let d = calendar.date(byAdding: .day, value: -back, to: now) ?? now
                state.time.addPlay(seconds: (8 + back * 2) * 60, at: d, calendar: calendar)
            }
            state.hasMetSparkle = true
        default:
            if content.scene(name) != nil {
                // Unlock everything up to and including the named scene.
                for ch in content.chapters {
                    for s in ch.scenes {
                        if s == name { state.hasMetSparkle = true; return }
                        state.completedScenes.insert(s)
                    }
                    masterChapter(ch.id)
                }
            }
        }
    }

    private func masterChapter(_ ch: ChapterID) {
        let days = [calendar.date(byAdding: .day, value: -2, to: now) ?? now, calendar.date(byAdding: .day, value: -1, to: now) ?? now]
        for s in content.skills(in: ch) {
            var rec = SkillRecord()
            rec.level = .abstract
            for i in 0..<10 {
                rec.history.append(ItemResult(itemID: "preset-\(i)", skill: s.id, level: .abstract,
                                              firstTryCorrect: true, needsPractice: false, date: days[i % 2]))
            }
            state.skills[s.id] = rec
        }
    }
}
