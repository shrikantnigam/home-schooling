import Foundation

public enum MapPlaceState: Equatable, Sendable {
    /// Under mist: "Not yet. We'll get there together."
    case locked
    /// Open, with the next scene glowing.
    case open(next: SceneID)
    /// Every scene done but skills not yet mastered: offer Practice.
    case practice
    /// Every scene done and every skill mastered.
    case done
}

/// Scene and chapter unlocking (spec section 5, AC-S4, AC-M6, AC-P6).
public struct Progression: Sendable {
    public let content: Content
    public let engine: MasteryEngine

    public init(content: Content, engine: MasteryEngine = MasteryEngine()) {
        self.content = content
        self.engine = engine
    }

    public func chapterMastered(_ chapter: ChapterID, state: LearnerState) -> Bool {
        let skills = content.skills(in: chapter)
        return !skills.isEmpty && skills.allSatisfy { engine.isMastered(state.record(for: $0.id)) }
    }

    public func allScenesDone(_ chapter: ChapterID, state: LearnerState) -> Bool {
        guard let ch = content.chapter(chapter) else { return false }
        return ch.scenes.allSatisfy { state.completedScenes.contains($0) }
    }

    /// First chapter is always open. Later ones need every skill of the chapter before mastered,
    /// or a parent unlock.
    public func isChapterUnlocked(_ chapter: ChapterID, state: LearnerState) -> Bool {
        if state.unlockedChapters.contains(chapter) { return true }
        guard let prev = content.previousChapter(of: chapter) else { return content.chapter(chapter) != nil }
        return isChapterUnlocked(prev.id, state: state) && chapterMastered(prev.id, state: state)
    }

    /// Scenes are a story path: each opens when the one before it is complete.
    public func isSceneUnlocked(_ scene: SceneID, state: LearnerState) -> Bool {
        guard let s = content.scene(scene), let ch = content.chapter(s.chapter),
              isChapterUnlocked(ch.id, state: state),
              let i = ch.scenes.firstIndex(of: scene) else { return false }
        return i == 0 || state.completedScenes.contains(ch.scenes[i - 1])
    }

    public func placeState(_ chapter: ChapterID, state: LearnerState) -> MapPlaceState {
        guard let ch = content.chapter(chapter), isChapterUnlocked(chapter, state: state) else { return .locked }
        if let next = ch.scenes.first(where: { !state.completedScenes.contains($0) }) { return .open(next: next) }
        return chapterMastered(chapter, state: state) ? .done : .practice
    }

    /// The scene the castle's glowing button leads to: the first unfinished scene in story order,
    /// or the practice scene of the latest open chapter.
    public enum Next: Equatable, Sendable {
        case scene(SceneID)
        case practice(ChapterID)
        case allDone
    }

    public func next(state: LearnerState) -> Next {
        var lastOpen: ChapterID?
        for ch in content.chapters where isChapterUnlocked(ch.id, state: state) {
            lastOpen = ch.id
            if case .open(let s) = placeState(ch.id, state: state) { return .scene(s) }
        }
        if let lastOpen, placeState(lastOpen, state: state) == .practice { return .practice(lastOpen) }
        return .allDone
    }

    /// A practice scene for a chapter: "needs practice" items first, then items for unmastered
    /// skills, then the rest. Story-framed with the practice lines.
    public func practiceScene(for chapter: ChapterID, state: LearnerState, size: Int = 8) -> StoryScene {
        let items = content.items(in: chapter)
        let unmastered = Set(content.skills(in: chapter).map(\.id).filter { !engine.isMastered(state.record(for: $0)) })
        let stuck = items.filter { state.needsPractice.contains($0.id) }
        let weak = items.filter { unmastered.contains($0.skill) && !state.needsPractice.contains($0.id) }
            .sorted { (state.lastSeen[$0.id] ?? .distantPast) < (state.lastSeen[$1.id] ?? .distantPast) }
        var picked: [Item] = []
        var seen = Set<String>()
        for i in stuck + weak + items where picked.count < size && seen.insert(i.id).inserted {
            picked.append(i)
        }
        return StoryScene(
            id: "practice-\(chapter)", chapter: chapter, title: "Practice",
            open: ["practice.open1", "practice.open2"], warmupCount: 0,
            items: picked, payoff: ["practice.payoff"], goodbye: "practice.goodbye"
        )
    }

    /// Marks a scene done. Completing a practice scene does not add to the scene list.
    public func complete(_ scene: StoryScene, state: inout LearnerState, at date: Date) {
        if content.scene(scene.id) != nil { state.completedScenes.insert(scene.id) }
        state.time.noteSceneCompleted(at: date, calendar: engine.calendar)
        state.resume = nil
    }
}
