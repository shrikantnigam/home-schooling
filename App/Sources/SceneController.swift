import KingdomCore
import SwiftUI

/// What the child sees around the current item.
enum ItemMood: Equatable {
    /// Waiting for her answer.
    case asking
    /// A wrong try: show this hint and let her try again (or show the answer at stage 3).
    case hint(HintStage)
    /// Right answer; praise is playing.
    case correct
}

/// Optional support she can open in G5-style abstract items (counts as help, AC-M1).
enum HelpModel: Equatable {
    case flowerBox
    case hoppingPath
}

/// Per-item interaction state for the activity views.
struct ItemUIState: Equatable {
    /// Objects she has tapped to count (stars), by index.
    var counted: [Int] = []
    /// Seeds planted into the flower box (addMore, makeTen concrete).
    var planted = 0
    /// Hops Sparkle has made (hop concrete).
    var hopsDone = 0
    /// Quick look: stars are hidden behind the cloud.
    var hidden = false
    /// The numeral tile touched once ("heard it" state, AC-A3).
    var heardTile: Int?
    /// Tile that wobbles after a wrong try.
    var wobbleTile: Int?
    var wobble: CGFloat = 0
    var help: HelpModel?
    /// Worked step: the object index being counted aloud.
    var countAlong: Int?
}

/// Drives one scene on screen: speaks, collects answers, records results.
@MainActor
final class SceneController: ObservableObject {
    @Published private(set) var run: SceneRun
    @Published private(set) var session: ItemSession?
    @Published var ui = ItemUIState()
    @Published private(set) var mood: ItemMood = .asking
    /// The big "next" star appears once the current lines are spoken.
    @Published private(set) var showNext = false
    /// Number bonds found in this scene, shown as pictures at the bottom (G2).
    @Published private(set) var foundBonds: [[Int]] = []
    /// Numerals already shown with dots in this scene (spec: dots the first time).
    private(set) var numeralsSeen: Set<Int> = []

    unowned let model: AppModel
    private var praiseVariant = 0
    /// Kinds whose teaching praise was already said in this scene (Shrikant: once per scene is enough).
    private var taughtKinds: Set<ActivityKind> = []
    private var lastInstruction: [SpokenLine?] = []
    /// How many times each how-to prompt was said in this scene: full twice, then short (item 8).
    private var promptsAsked: [String: Int] = [:]
    /// Bumped on every new item so a late quick-look timer from an earlier item does nothing.
    private var itemToken = 0

    init(scene: StoryScene, warmups: [Item], resumeAt: Int?, model: AppModel) {
        self.run = SceneRun(scene: scene, warmups: warmups, resumeAt: resumeAt)
        self.model = model
    }

    var catalog: LineCatalog { model.catalog }
    var item: Item? { run.currentItem }
    var level: CPALevel { session?.level ?? .concrete }

    /// Concrete pre-steps (tap, place, hop) come before the numeral tiles.
    var readyToAnswer: Bool {
        guard let item, mood != .correct else { return false }
        if case .hint(.showAnswer) = mood { return false }
        guard level == .concrete else { return true }
        switch item.concreteStep {
        case .none: return true
        case .tap(_, answers: true): return false // answered by tapping every object
        case .tap(let n, answers: false): return ui.counted.count >= n
        case .place(let n): return ui.planted >= n
        case .hop(let n): return ui.hopsDone >= n
        }
    }

    /// The concrete step still to do, for the QA play-through.
    var concreteStepDescription: String {
        guard let item, level == .concrete else { return "none" }
        switch item.concreteStep {
        case .none: return "none"
        case .tap(let n, let answers): return answers ? "tapAnswers:\(n)" : "tap:\(n)"
        case .place(let n): return "place:\(n)"
        case .hop(let n): return "hop:\(n)"
        }
    }

    /// Whether a numeral tile should show its dots.
    func showDots(for n: Int) -> Bool { level != .abstract || !numeralsSeen.contains(n) || ui.help != nil }

    func start() { enterPhase() }

    // MARK: Phases

    private func enterPhase() {
        showNext = false
        switch run.phase {
        case .open:
            if model.firstTimeThisSession("open.\(run.scene.id)") {
                speak(run.scene.open.map { catalog.spoken($0) }, thenShowNext: true)
            } else if run.scene.id.hasPrefix("practice-") {
                speak([catalog.spoken("practice.short")], thenShowNext: true)
            } else {
                // Heard already since the app opened: stay quiet; the ear replays it.
                quiet(lines: run.scene.open.map { catalog.spoken($0) })
            }
        case .warmup, .core:
            beginItem()
        case .payoff:
            speak(payoffLines, thenShowNext: true)
        case .goodbye:
            if model.firstTimeThisSession("goodbye.\(run.scene.id)") {
                speak([catalog.spoken(run.scene.goodbye)], thenShowNext: true)
            } else {
                quiet(lines: [catalog.spoken(run.scene.goodbye)])
            }
        case .finished:
            model.sceneFinished(run)
        }
    }

    /// What the payoff panel says. Cut short by the daily limit: "we'll finish tomorrow", not the success
    /// story (item 11). Ended early after a run of right answers: a word on that, then the payoff (L13).
    var payoffLines: [SpokenLine?] {
        if run.cutShort { return [catalog.spoken("wrapup.pause")] }
        var lines = run.scene.payoff.map { catalog.spoken($0) }
        if run.endedEarly { lines.insert(catalog.spoken("stepup"), at: 0) }
        if run.wrappingUp { lines.insert(catalog.spoken("wrapup"), at: 0) }
        return lines
    }

    /// The big star button: next phase or next item.
    func next() {
        guard showNext else { return }
        model.speech.stop()
        run.advance()
        enterPhase()
    }

    func beginWrapUp() { run.beginWrapUp() }

    func saveResume() {
        guard run.currentItem != nil else { return }
        model.state.resume = run.resumePoint()
        model.save()
    }

    private func beginItem() {
        guard let item else { return }
        // A test-out challenge asks with numbers (L12); numeral-only kinds are always at that level.
        let lvl = item.isAbstractOnly || run.scene.isChallenge ? CPALevel.abstract : model.state.level(for: item.skill)
        session = ItemSession(item: item, level: lvl)
        ui = ItemUIState()
        mood = .asking
        itemToken += 1
        saveResume()
        var lines: [SpokenLine?] = []
        if case .warmup(0) = run.phase { lines.append(catalog.spoken("warmup.intro")) }
        if case .core(0) = run.phase, !run.warmups.isEmpty { lines.append(catalog.spoken("core.intro")) }
        if item.kind == .quickLook {
            ui.hidden = true
            quickLook(intro: lines)
            return
        }
        let key = "\(item.kind.rawValue).\(lvl)"
        let asked = promptsAsked[key, default: 0]
        promptsAsked[key] = asked + 1
        // The ear always replays the full how-to; the voice says the short one after the first two.
        lastInstruction = [catalog.prompt(for: item, level: lvl)]
        lines.append(catalog.prompt(for: item, level: lvl, timesAsked: asked))
        speak(lines, thenShowNext: false)
    }

    /// Quick look (item 14): "Ready? Look!" is said first with the stars under the cloud. When the voice
    /// finishes, the stars show for a short look, hide again, and only then the question is asked. The look
    /// is a viewing time, not a timer on her answer (AC-A6).
    private func quickLook(intro: [SpokenLine?]) {
        let token = itemToken
        let n = promptsAsked["ask.quickLook", default: 0]
        promptsAsked["ask.quickLook"] = n + 1
        let full = catalog.spoken("ask.quickLook")
        let ask = n >= 2 ? (catalog.spoken("ask.quickLook.short") ?? full) : full
        lastInstruction = [catalog.spoken("quickLook.ready"), full]
        model.speech.say(intro + [catalog.spoken("quickLook.ready")]) { [weak self] in
            guard let self, token == self.itemToken else { return }
            withAnimation(.easeOut(duration: 0.25)) { self.ui.hidden = false }
            let look = self.model.env.uiTesting ? 1.0 : 2.0
            DispatchQueue.main.asyncAfter(deadline: .now() + look) { [weak self] in
                guard let self, token == self.itemToken, !self.revealedOrDone else { return }
                withAnimation(.easeInOut(duration: 0.4)) { self.ui.hidden = true }
                self.model.speech.say(ask)
            }
        }
    }

    private var revealedOrDone: Bool { mood == .correct || mood == .hint(.showAnswer) }

    /// The ear button (AC-A2): replay the current instruction in full.
    func replay() {
        switch run.phase {
        case .open: speak(run.scene.open.map { catalog.spoken($0) }, thenShowNext: true)
        case .payoff: speak(run.scene.payoff.map { catalog.spoken($0) }, thenShowNext: true)
        case .goodbye: speak([catalog.spoken(run.scene.goodbye)], thenShowNext: true)
        default:
            if item?.kind == .quickLook, !revealedOrDone {
                itemToken += 1
                ui.hidden = true
                quickLook(intro: [])
                return
            }
            model.speech.say(lastInstruction)
        }
    }

    // MARK: Interactions

    /// Countable objects: tapping each one once counts it aloud (one-to-one).
    func tapObject(_ index: Int, total: Int) {
        guard let item, mood != .correct, !ui.counted.contains(index) else { return }
        if case .tap(let n, _) = item.concreteStep, level == .concrete, ui.counted.count >= n { return }
        ui.counted.append(index)
        let n = ui.counted.count
        let spoken = catalog.count(spokenCount(for: item, steps: n))
        if case .tap(let need, answers: true) = item.concreteStep, level == .concrete, n == need {
            model.speech.say(spoken) { [weak self] in self?.submit(item.answer) }
        } else if case .tap(let need, answers: false) = item.concreteStep, level == .concrete, n == need {
            model.speech.say([spoken, askLine(for: item)])
        } else {
            model.speech.say(spoken)
        }
    }

    /// Bond flowers: move the next one into bed two.
    func moveFlower() {
        guard let item else { return }
        tapObject(ui.counted.count, total: item.a - item.b)
    }

    /// Places one seed, plank, treat or berry.
    func plantSeed() {
        guard let item, mood != .correct, case .place(let need) = item.concreteStep, ui.planted < need else { return }
        ui.planted += 1
        let spoken = catalog.count(spokenCount(for: item, steps: ui.planted))
        if ui.planted == need {
            model.speech.say([spoken, askLine(for: item)])
        } else {
            model.speech.say(spoken)
        }
    }

    func hop() {
        guard let item, mood != .correct, case .hop(let need) = item.concreteStep, ui.hopsDone < need else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { ui.hopsDone += 1 }
        model.speech.say(catalog.count(spokenCount(for: item, steps: ui.hopsDone)))
    }

    /// What Sparkle says on each concrete step: counting on, skip counting or plain counting.
    func spokenCount(for item: Item, steps n: Int) -> Int {
        switch item.kind {
        case .addMore, .bridgeAdd: return item.a + n
        case .tensOnes: return 10 * item.a + n
        case .array: return item.b * n
        case .skipHop: return item.b * n
        default: return n
        }
    }

    /// The question asked once the hands-on step is done.
    /// Asked in full the first two times in a scene, then in its short form (item 8).
    private func askLine(for item: Item) -> SpokenLine? {
        let id = "ask.\(item.kind.rawValue)"
        let full = catalog.spoken(id, item: item) ?? catalog.prompt(for: item, level: .abstract)
        lastInstruction = [full]
        let n = promptsAsked[id, default: 0]
        promptsAsked[id] = n + 1
        return n >= 2 ? (catalog.spoken(id + ".short", item: item) ?? full) : full
    }

    func openHelp(_ h: HelpModel) {
        session?.noteHelpUsed()
        ui.help = h
    }

    /// Numeral tiles: touch once to hear, touch again to choose (AC-A3).
    func touchTile(_ n: Int) {
        guard readyToAnswer else { return }
        if ui.heardTile == n {
            submit(n)
        } else {
            ui.heardTile = n
            model.speech.say(catalog.number(n))
        }
    }

    /// Number line stones answer directly (one touch), and say the number.
    func touchStone(_ n: Int) {
        guard readyToAnswer else { return }
        submit(n)
    }

    func submit(_ answer: Int) {
        guard var s = session, !s.finished, let item else { return }
        let fb = s.submit(answer)
        session = s
        ui.heardTile = nil
        for n in ActivityRules.choices(for: item) { numeralsSeen.insert(n) }
        switch fb {
        case .correct:
            mood = .correct
            if item.kind == .numberBond { foundBonds.append([item.b, item.answer]) }
            praiseVariant += 1
            let teach = taughtKinds.insert(item.kind).inserted
            finishItem(s, lines: [catalog.praise(for: item, level: s.level, variant: praiseVariant, teach: teach)])
        case .hint(let stage):
            mood = .hint(stage)
            ui.wobbleTile = answer
            withAnimation(.linear(duration: 0.5)) { ui.wobble += 1 }
            let hint = catalog.hint(stage, for: item, level: s.level)
            switch stage {
            case .modelHint where item.kind == .quickLook:
                // Another short look, then the question again.
                itemToken += 1
                ui.hidden = true
                quickLook(intro: [hint])
            case .modelHint:
                lastInstruction = [hint]
                model.speech.say(hint)
            case .workedStep:
                lastInstruction = [hint]
                countAlong(item: item, intro: hint)
            case .showAnswer:
                finishItem(s, lines: [hint])
            }
        }
    }

    /// Worked step: count along with her, lighting each object as its number is spoken (item 13).
    /// The light follows the voice's own line callbacks, so a slower voice never drifts out of step.
    private func countAlong(item: Item, intro: SpokenLine?) {
        let (start, count) = countAlongRange(item)
        var lines: [SpokenLine?] = [intro]
        for i in 0..<count { lines.append(catalog.count(start + i + 1)) }
        if item.kind == .quickLook { ui.hidden = false }
        ui.countAlong = nil
        model.speech.say(lines, each: { [weak self] index in
            guard index >= 1 else { return }
            withAnimation(.easeOut(duration: 0.15)) { self?.ui.countAlong = index - 1 }
        }, then: { [weak self] in self?.ui.countAlong = nil })
    }

    /// Where counting on starts and how many steps, per activity.
    func countAlongRange(_ item: Item) -> (start: Int, count: Int) {
        switch item.kind {
        case .addMore, .hop, .equation, .bridgeAdd: return (item.a, item.b)
        case .makeTen: return (0, 10 - item.a)
        case .numberBond: return (0, item.a - item.b)
        case .tensOnes: return (10 * item.a, item.b)
        default: return (0, item.answer)
        }
    }

    private func finishItem(_ s: ItemSession, lines: [SpokenLine?]) {
        let result = s.result(at: model.now)
        // Challenge answers decide the test-out at the end (L12); they don't move CPA levels one by one.
        if run.scene.isChallenge { model.state.lastSeen[result.itemID] = result.date } else { model.record(result) }
        run.noteResult(firstTry: result.firstTryCorrect, atTopLevel: model.state.level(for: s.item.skill) == .abstract)
        speak(lines, thenShowNext: true)
    }

    /// Shows the Next button without speaking; the ear button still replays `lines`.
    private func quiet(lines: [SpokenLine?]) {
        lastInstruction = lines
        withAnimation { showNext = true }
    }

    private func speak(_ lines: [SpokenLine?], thenShowNext: Bool) {
        if thenShowNext { lastInstruction = lines }
        model.speech.say(lines) { [weak self] in
            if thenShowNext { withAnimation { self?.showNext = true } }
        }
    }
}
