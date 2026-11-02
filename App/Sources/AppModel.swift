import KingdomCore
import SwiftUI

/// The app's single source of truth. Holds the saved learner state and routes between screens.
@MainActor
final class AppModel: ObservableObject {
    enum Route: Equatable {
        /// The Home School home screen with one tile per widget (#30).
        case home
        /// The jigsaw widget (#25).
        case jigsaw
        /// The cup shuffle widget (#27).
        case cups
        case castle
        case map
        case scene
        case gate
        case parent
        case setup
        /// F1: write what happened as number sentences, at the end of a place.
        case writeItDown(ChapterID)
        /// F3: the Puzzle Board in the castle.
        case board
        /// F2, F4: one puzzle scroll.
        case sheet(String)

        /// Screens where play time counts toward the daily limit.
        var isPlay: Bool {
            switch self {
            case .scene, .writeItDown, .board, .sheet, .jigsaw, .cups: return true
            default: return false
            }
        }
    }

    @Published var route: Route = .home
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
    /// A QA preset can open straight on a screen.
    private var pendingRoute: Route?
    /// Where the grown-ups' gate goes back to: the castle inside Kingdom of Numbers, else the home screen.
    private var returnRoute: Route = .home

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
        speech = SpeechPlayer(instant: AppEnvironment.current.uiTesting,
                             neverFinishes: AppEnvironment.current.speechNeverFinishes)
        store = env.uiTesting
            ? StateStore(url: FileManager.default.temporaryDirectory.appendingPathComponent("qa-learner.json"))
            : StateStore.defaultStore()
        var loaded = env.reset ? LearnerState() : store.load()
        // A debug jump session that was never ended (app killed): put her real progress back.
        let snap = StateStore(url: store.url.deletingLastPathComponent().appendingPathComponent("debug-snapshot.json"), keepsBackup: false)
        if FileManager.default.fileExists(atPath: snap.url.path) {
            if !env.reset { loaded = snap.load() }
            try? FileManager.default.removeItem(at: snap.url)
            try? store.save(loaded)
        }
        if env.uiTesting { loaded.sound.subtitles = true }
        state = loaded
        if let preset = env.preset { applyPreset(preset) }
        // QA play-throughs use the setup defaults unless they test the setup screen itself.
        if env.uiTesting && !env.showSetup && state.needsSetup {
            state.completeSetup(SetupChoices(heroName: SetupChoices.defaultName, companion: .unicorn,
                                             dailyLimitMinutes: state.timeSettings.dailyLimitMinutes))
        }
        catalog = LineCatalog(lines: content.lines, heroName: state.heroName, companion: state.companion)
        route = state.needsSetup ? .setup : (pendingRoute ?? .home)
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
        route = .home
    }

    func applySound() {
        speech.companionPitch = state.companion.voicePitch
        speech.rate = Float(state.sound.speechRate)
        speech.volume = Float(state.sound.narrationVolume)
        speech.chooseVoices(narrator: state.sound.narratorVoiceID, companion: state.sound.companionVoiceID)
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
        guard isActive, route.isPlay, seconds > 0 else { return }
        if route == .scene && scene == nil { return }
        state.time.addPlay(seconds: min(seconds, 30), at: now, calendar: calendar)
        if state.time.limitReached(at: now, settings: state.timeSettings, calendar: calendar) {
            if route == .scene {
                scene?.beginWrapUp()
            } else if route == .jigsaw || route == .cups {
                goHome()
            } else {
                // Off the story path there is no scene to wrap up: back to the sleeping castle.
                goCastle()
            }
        }
    }

    // MARK: Navigation

    /// The Home School home screen (#30).
    func goHome() {
        speech.stop()
        if let scene { scene.saveResume() }
        scene = nil
        route = state.needsSetup ? .setup : .home
        save()
    }

    /// Opens a widget from its tile on the home screen.
    func open(_ widget: HubWidget) {
        speech.stop()
        lastTick = Date()
        switch widget.id {
        case "kingdom": route = .castle
        case "jigsaw": if block == nil { route = .jigsaw }
        case "cups": if block == nil { route = .cups }
        default: break
        }
    }

    /// Records a finished jigsaw and moves the levels (J10 quick check, J2 adapts).
    func finishJigsaw(_ r: JigsawResult) {
        state.jigsaw.finishPicture(r)
        save()
    }

    /// Records a finished cup shuffle round (C4, C5) and remembers her setting (C1).
    func finishCupRound(_ settings: CupSettings, found: Bool) {
        state.cupShuffle.finish(settings, found: found, at: now)
        save()
    }

    /// Marks the first-time tutorial as done (C7).
    func finishCupTutorial() {
        state.cupShuffle.tutorialDone = true
        save()
    }

    /// True the first time ever a jigsaw intro is asked for; after that she has heard it.
    func jigsawFirstTime(_ key: String) -> Bool {
        let isNew = state.jigsaw.introsHeard.insert(key).inserted
        if isNew { save() }
        return isNew
    }

    /// Back from the grown-ups' gate or area.
    func leaveParentArea() {
        speech.stop()
        route = state.needsSetup ? .setup : returnRoute
    }

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
        // F1: finishing a place for the first time ends with writing it down.
        let ch = run.scene.chapter
        if run.completedAllItems, progression.allScenesDone(ch, state: state), !state.wroteDown.contains(ch),
           WriteItDown.forPlace(ch) != nil, block == nil {
            route = .writeItDown(ch)
        }
        save()
    }

    // MARK: Problem solving (charter v1.5, docs/features/problem-solving.md)

    var problems: ProblemMaker { ProblemMaker(progression: progression) }
    var sheetMaker: WorksheetMaker { WorksheetMaker(content: content, progression: progression) }
    /// The board opens after her first place (AC-B1): scrolls first, puzzles once a sign is taught.
    var boardUnlocked: Bool { progression.allScenesDone("prologue", state: state) }

    func finishWriteItDown(_ chapter: ChapterID) {
        state.wroteDown.insert(chapter)
        save()
        speech.stop()
        route = .castle
    }

    func openBoard() {
        guard block == nil, boardUnlocked else { return }
        speech.stop()
        lastTick = Date()
        route = .board
    }

    /// The next puzzle on the board, at its sign's story level.
    func currentPuzzle() -> BoardPuzzle? {
        guard let op = ProblemMaker.nextOperation(problems.unlocked(state), board: state.board) else { return nil }
        return ProblemMaker.puzzle(op, level: state.board.level(op), n: state.board.puzzlesServed, top: problems.top(state))
    }

    func finishPuzzle(_ puzzle: BoardPuzzle, firstTry: Bool) {
        state.board.record(puzzle.op, firstTry: firstTry)
        state.board.puzzlesServed += 1
        save()
    }

    func madePuzzle() {
        state.board.puzzlesMade += 1
        save()
    }

    func openSheet(_ id: String) {
        guard block == nil else { return }
        speech.stop()
        lastTick = Date()
        route = .sheet(id)
    }

    func sheet(_ id: String) -> Worksheet? { sheetMaker.available(state: state).first { $0.id == id } }

    func finishSheet(_ sheet: Worksheet, firstTry: [String: Bool]) {
        state.finishSheet(sheet, firstTry: firstTry, at: now)
        save()
        speech.stop()
        route = .board
    }

    func sheetFeedback(_ feedback: SheetFeedback, sheetID: String, place: ChapterID?) {
        // A mixed scroll counts against her weakest sign's place.
        let fallback = problems.unlocked(state).max { state.board.weakness($0) < state.board.weakness($1) }?.place
        guard let p = place ?? fallback else { return }
        state.applySheetFeedback(feedback, sheetID: sheetID, place: p, content: content)
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
        returnRoute = (route == .home || route == .jigsaw || route == .cups) ? .home : .castle
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

    // MARK: Debug jump (grown-ups' area, Debug builds only)

    private var debugSnapshotStore: StateStore {
        StateStore(url: store.url.deletingLastPathComponent().appendingPathComponent("debug-snapshot.json"), keepsBackup: false)
    }

    /// True while a grown-up is testing with jumps; her real progress is saved aside until they end it.
    var isDebugSession: Bool { FileManager.default.fileExists(atPath: debugSnapshotStore.url.path) }

    private func beginDebugSession() {
        if !isDebugSession { try? debugSnapshotStore.save(state) }
        // Jumps never stop at the daily limit.
        state.time = TimeKeeper()
        state.hasMetSparkle = true
    }

    /// Opens any scene, with everything before it unlocked.
    func debugJump(scene id: SceneID) {
        beginDebugSession()
        unlockUpTo(id)
        save()
        start(sceneID: id)
    }

    enum DebugTarget: String, CaseIterable, Identifiable {
        case home, castle, map, board, jigsaw, cups
        var id: String { rawValue }
    }

    func debugJump(_ target: DebugTarget) {
        beginDebugSession()
        if target == .board || target == .map {
            for ch in content.chapters { unlockUpTo(ch.scenes.last ?? "") }
        }
        save()
        speech.stop()
        switch target {
        case .home: route = .home
        case .castle: route = .castle
        case .map: route = .map
        case .board: route = .board
        case .jigsaw: route = .jigsaw
        case .cups: route = .cups
        }
    }

    func debugJumpWriteItDown(_ chapter: ChapterID) {
        beginDebugSession()
        unlockUpTo(content.chapter(chapter)?.scenes.last ?? "")
        save()
        speech.stop()
        route = .writeItDown(chapter)
    }

    /// Ends testing: her real progress comes back exactly as it was.
    func endDebugSession() {
        guard isDebugSession else { return }
        speech.stop()
        scene = nil
        state = debugSnapshotStore.load()
        try? FileManager.default.removeItem(at: debugSnapshotStore.url)
        catalog = LineCatalog(lines: content.lines, heroName: state.heroName, companion: state.companion)
        save()
        route = .home
    }

    /// Marks every scene before `id` done (and its places mastered), and `id` itself as the next one.
    private func unlockUpTo(_ id: SceneID) {
        for ch in content.chapters {
            for s in ch.scenes {
                if s == id { return }
                state.completedScenes.insert(s)
            }
            masterChapter(ch.id)
        }
    }

    // MARK: QA presets

    private func applyPreset(_ name: String) {
        switch name {
        case "cupsTutorialDone":
            state.cupShuffle.tutorialDone = true
        case "cupsThreeFinds":
            // C9: three finds in a row at 3 cups, speed 1, so speed 2 is suggested.
            state.cupShuffle.tutorialDone = true
            for _ in 0..<3 { state.cupShuffle.finish(.first, found: true, at: now) }
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
        case "boardReady", "writeItDown.garden":
            // The Garden, the Goblin's Cave and the Royal Ball are finished: three signs on the Puzzle Board.
            let places: [ChapterID] = name == "boardReady" ? ["prologue", "garden", "goblin", "ball"] : ["prologue", "garden"]
            for ch in places {
                for s in content.chapter(ch)?.scenes ?? [] { state.completedScenes.insert(s) }
                masterChapter(ch)
            }
            state.wroteDown = name == "boardReady" ? Set(places) : ["prologue"]
            state.hasMetSparkle = true
            if name == "writeItDown.garden" { pendingRoute = .writeItDown("garden") }
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
