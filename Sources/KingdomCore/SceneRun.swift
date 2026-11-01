import Foundation

/// A small seeded random generator so warm-ups are repeatable in tests.
public struct SeededRandom: RandomNumberGenerator, Sendable {
    private var state: UInt64
    public init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// Picks warm-up items: spaced practice from earlier scenes (spec section 5, AC-M7).
/// 60% from the most recent chapter with finished work, 40% from older chapters,
/// favouring "needs practice" items and items not seen for 3+ days.
public struct WarmupPicker: Sendable {
    public let content: Content
    public let calendar: Calendar

    public init(content: Content, calendar: Calendar = .current) {
        self.content = content
        self.calendar = calendar
    }

    public func pick(for scene: StoryScene, count: Int, state: LearnerState, now: Date, seed: UInt64) -> [Item] {
        guard count > 0 else { return [] }
        var rng = SeededRandom(seed: seed)
        let currentIDs = Set(scene.items.map(\.id))
        // Only items from scenes she has already finished.
        let done = content.scenes.filter { state.completedScenes.contains($0.id) }
        let pool = done.flatMap(\.items).filter { !currentIDs.contains($0.id) }
        guard !pool.isEmpty else { return [] }

        let chapterOrder = content.chapters.map(\.id)
        let recentChapter = chapterOrder.last { ch in done.contains { $0.chapter == ch } }
        let recent = pool.filter { content.skill($0.skill)?.chapter == recentChapter }
        let older = pool.filter { content.skill($0.skill)?.chapter != recentChapter }

        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now) ?? now
        func priority(_ i: Item) -> Int {
            if state.needsPractice.contains(i.id) { return 0 }
            if (state.lastSeen[i.id] ?? .distantPast) < threeDaysAgo { return 1 }
            return 2
        }
        func ordered(_ items: [Item]) -> [Item] {
            items.shuffled(using: &rng).sorted { priority($0) < priority($1) }
        }

        let recentTarget = older.isEmpty ? count : Int((Double(count) * 0.6).rounded())
        var picked: [Item] = []
        var used = Set<String>()
        func take(_ items: [Item], upTo n: Int) {
            for i in items where picked.count < n && used.insert(i.id).inserted { picked.append(i) }
        }
        // AC-M7: always include a needs-practice item when any exist.
        if let stuck = ordered(pool).first, priority(stuck) == 0 { take([stuck], upTo: 1) }
        take(ordered(recent), upTo: recentTarget)
        take(ordered(older), upTo: count)
        take(ordered(pool), upTo: count)
        return picked
    }
}

/// The five phases of every scene (AC-S2).
public enum ScenePhase: Equatable, Sendable {
    case open
    case warmup(index: Int)
    case core(index: Int)
    case payoff
    case goodbye
    case finished
}

/// Steps through one scene. Pure state machine so QA and tests can drive it.
public struct SceneRun: Equatable, Sendable {
    public let scene: StoryScene
    public let warmups: [Item]
    public private(set) var phase: ScenePhase = .open
    /// Set when the daily limit is reached: finish the current item, then go to the payoff (AC-P3).
    public private(set) var wrappingUp = false

    public init(scene: StoryScene, warmups: [Item], resumeAt index: Int? = nil) {
        self.scene = scene
        self.warmups = warmups
        if let index, index < warmups.count + scene.items.count {
            phase = index < warmups.count ? .warmup(index: index) : .core(index: index - warmups.count)
        }
    }

    public var allItems: [Item] { warmups + scene.items }

    public var currentItem: Item? {
        switch phase {
        case .warmup(let i): return warmups[i]
        case .core(let i): return scene.items[i]
        default: return nil
        }
    }

    /// Position in `allItems`, for the resume point.
    public var itemIndex: Int? {
        switch phase {
        case .warmup(let i): return i
        case .core(let i): return warmups.count + i
        default: return nil
        }
    }

    public var isWarmup: Bool { if case .warmup = phase { return true } else { return false } }

    public mutating func beginWrapUp() { wrappingUp = true }

    /// True when the wrap-up skipped items, so the scene is not marked complete.
    public private(set) var cutShort = false

    /// Moves to the next phase. Call after the open lines, after each finished item,
    /// after the payoff and after the goodbye.
    public mutating func advance() {
        switch phase {
        case .open:
            if !warmups.isEmpty { phase = .warmup(index: 0) }
            else if !scene.items.isEmpty { phase = .core(index: 0) }
            else { phase = .payoff }
        case .warmup(let i):
            if wrappingUp { cutShort = true; phase = .payoff }
            else if i + 1 < warmups.count { phase = .warmup(index: i + 1) }
            else if !scene.items.isEmpty { phase = .core(index: 0) }
            else { phase = .payoff }
        case .core(let i):
            if i + 1 >= scene.items.count { phase = .payoff }
            else if wrappingUp { cutShort = true; phase = .payoff }
            else { phase = .core(index: i + 1) }
        case .payoff:
            phase = .goodbye
        case .goodbye, .finished:
            phase = .finished
        }
    }

    /// A scene counts as completed only when every item was attempted (spec: scene unlock).
    public var completedAllItems: Bool { phase == .finished && !cutShort }

    public func resumePoint() -> ResumePoint? {
        guard let idx = itemIndex else { return nil }
        return ResumePoint(sceneID: scene.id, itemIDs: allItems.map(\.id), warmupCount: warmups.count, index: idx)
    }
}
