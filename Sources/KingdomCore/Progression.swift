import Foundation

public enum MapPlaceState: Equatable, Sendable {
    /// Under mist: "Not yet. We'll get there together."
    case locked
    /// Open, with the next scene glowing.
    case open(next: SceneID)
    /// Open, but the next scene needs another place first (skill map). It shows as open, not glowing.
    case waiting(next: SceneID, on: [ChapterID])
    /// Every scene done but skills not yet secure: offer Practice.
    case practice
    /// Every scene done and the place's gate passed. Tapping it plays the place again (a mixed review).
    case done
}

/// Scene and place unlocking. After the Prologue the kingdom is open (charter S11): a place opens when the
/// places it needs are done, following docs/chapters/skill-map.md, not when the place before it on a line is done.
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

    /// A skill counts as secure when she tested out of it (L12) or meets the engine's secure rule.
    public func skillSecure(_ skill: SkillID, state: LearnerState) -> Bool {
        state.testedOutSkills.contains(skill) || engine.isSecure(state.record(for: skill))
    }

    /// Whether a place has done enough to open the places that need it, under the parent's chosen gate.
    public func chapterPassesGate(_ chapter: ChapterID, state: LearnerState) -> Bool {
        if content.chapter(chapter)?.gate == .scenes { return allScenesDone(chapter, state: state) }
        switch state.chapterGate {
        case .mastered:
            let skills = content.skills(in: chapter)
            return !skills.isEmpty && skills.allSatisfy {
                state.testedOutSkills.contains($0.id) || engine.isMastered(state.record(for: $0.id))
            }
        case .secure:
            let skills = content.skills(in: chapter)
            return !skills.isEmpty && skills.allSatisfy { skillSecure($0.id, state: state) }
        case .scenesOnly:
            return allScenesDone(chapter, state: state)
        }
    }

    /// The places a place needs. Content can name them (`requires`); otherwise the place before it.
    public func requirements(of chapter: ChapterID) -> [ChapterID] {
        if let r = content.chapter(chapter)?.requires { return r }
        return content.previousChapter(of: chapter).map { [$0.id] } ?? []
    }

    /// A requirement is a place (open and past its gate) or a single scene (finished), for example the
    /// Moon opening after the Feast's first scene.
    public func requirementMet(_ req: String, state: LearnerState, visiting: Set<ChapterID> = []) -> Bool {
        if content.scene(req) != nil { return state.completedScenes.contains(req) }
        return isChapterUnlocked(req, state: state, visiting: visiting) && chapterPassesGate(req, state: state)
    }

    /// A place opens when every place it needs is done, or the parent unlocked it.
    public func isChapterUnlocked(_ chapter: ChapterID, state: LearnerState, visiting: Set<ChapterID> = []) -> Bool {
        guard content.chapter(chapter) != nil else { return false }
        if state.unlockedChapters.contains(chapter) { return true }
        guard !visiting.contains(chapter) else { return false }
        let seen = visiting.union([chapter])
        return requirements(of: chapter).allSatisfy { requirementMet($0, state: state, visiting: seen) }
    }

    /// Places a scene still waits for (its `needs` that are not done yet).
    public func missingNeeds(_ scene: SceneID, state: LearnerState) -> [ChapterID] {
        guard let s = content.scene(scene) else { return [] }
        return (s.needs ?? []).filter { !requirementMet($0, state: state) && !state.unlockedChapters.contains(s.chapter) }
    }

    /// Inside a place, scenes are a story path: each opens when the one before it is complete and
    /// the places it needs are done.
    public func isSceneUnlocked(_ scene: SceneID, state: LearnerState) -> Bool {
        guard let s = content.scene(scene), let ch = content.chapter(s.chapter),
              isChapterUnlocked(ch.id, state: state),
              let i = ch.scenes.firstIndex(of: scene) else { return false }
        if state.completedScenes.contains(scene) { return true }
        guard missingNeeds(scene, state: state).isEmpty else { return false }
        return i == 0 || state.completedScenes.contains(ch.scenes[i - 1])
    }

    public func placeState(_ chapter: ChapterID, state: LearnerState) -> MapPlaceState {
        guard let ch = content.chapter(chapter), isChapterUnlocked(chapter, state: state) else { return .locked }
        if let next = ch.scenes.first(where: { !state.completedScenes.contains($0) }) {
            let missing = missingNeeds(next, state: state)
            return missing.isEmpty ? .open(next: next) : .waiting(next: next, on: missing)
        }
        return chapterPassesGate(chapter, state: state) ? .done : .practice
    }

    /// Places that are open but not started yet: the map says they are awake (change list item 16).
    public func newlyOpened(state: LearnerState) -> [ChapterID] {
        content.chapters.map(\.id).filter { id in
            guard let ch = content.chapter(id), isChapterUnlocked(id, state: state) else { return false }
            return requirements(of: id).isEmpty == false && !ch.scenes.contains { state.completedScenes.contains($0) }
        }
    }

    /// The scene the castle's glowing button leads to: the first unfinished scene in story order,
    /// or the practice scene of the latest open chapter.
    public enum Next: Equatable, Sendable {
        case scene(SceneID)
        case practice(ChapterID)
        case allDone
    }

    public func next(state: LearnerState) -> Next {
        var lastPractice: ChapterID?
        for ch in content.chapters where isChapterUnlocked(ch.id, state: state) {
            switch placeState(ch.id, state: state) {
            case .open(let s): return .scene(s)
            case .practice: lastPractice = ch.id
            default: break
            }
        }
        if let lastPractice { return .practice(lastPractice) }
        return .allDone
    }

    /// A practice scene for a chapter: "needs practice" items first, then items for skills not yet secure,
    /// then the rest, least recently seen first. Kinds are interleaved so no more than 3 of a kind come
    /// in a row (L13). Also used to play a finished place again.
    public func practiceScene(for chapter: ChapterID, state: LearnerState, size: Int = 8) -> StoryScene {
        let items = content.items(in: chapter)
        let weakSkills = Set(content.skills(in: chapter).map(\.id).filter { !skillSecure($0, state: state) })
        func seen(_ i: Item) -> Date { state.lastSeen[i.id] ?? .distantPast }
        let stuck = items.filter { state.needsPractice.contains($0.id) }
        let weak = items.filter { weakSkills.contains($0.skill) && !state.needsPractice.contains($0.id) }
            .sorted { seen($0) < seen($1) }
        let rest = items.sorted { seen($0) < seen($1) }
        var picked: [Item] = []
        var used = Set<String>()
        for i in stuck + weak + rest where picked.count < size && used.insert(i.id).inserted {
            picked.append(i)
        }
        return practiceScene(chapter: chapter, items: Progression.interleaved(picked))
    }

    /// The story frame for a practice scene, with the place's own lines when it has them (item 10).
    public func practiceScene(chapter: ChapterID, items: [Item]) -> StoryScene {
        func line(_ base: String) -> LineID {
            content.lines["\(base).\(chapter)"] != nil ? "\(base).\(chapter)" : base
        }
        return StoryScene(
            id: "practice-\(chapter)", chapter: chapter, title: "Practice",
            open: [line("practice.open1"), "practice.open2"], warmupCount: 0,
            items: items, payoff: [line("practice.payoff")], goodbye: "practice.goodbye"
        )
    }

    /// Reorders items so that no more than `maxRun` of the same kind come in a row, where possible.
    public static func interleaved(_ items: [Item], maxRun: Int = 3) -> [Item] {
        var left = items
        var out: [Item] = []
        while !left.isEmpty {
            let run = out.suffix(maxRun)
            let blocked = run.count == maxRun && Set(run.map(\.kind)).count == 1 ? run.first?.kind : nil
            let i = left.firstIndex { $0.kind != blocked } ?? 0
            out.append(left.remove(at: i))
        }
        return out
    }

    /// Marks a scene done. Completing a practice scene does not add to the scene list.
    public func complete(_ scene: StoryScene, state: inout LearnerState, at date: Date) {
        if content.scene(scene.id) != nil { state.completedScenes.insert(scene.id) }
        state.time.noteSceneCompleted(at: date, calendar: engine.calendar)
        state.resume = nil
    }

    /// After a test-out challenge (L12): every skill whose challenge items were all right on the first try
    /// is marked tested out and starts at the Numbers level, and the place's scenes that only teach those
    /// skills are marked done. Returns the skills she tested out of.
    @discardableResult
    public func applyChallenge(_ scene: StoryScene, firstTry: [String: Bool], state: inout LearnerState) -> Set<SkillID> {
        let bySkill = Dictionary(grouping: scene.items, by: \.skill)
        var passed = Set<SkillID>()
        for (skill, items) in bySkill where items.allSatisfy({ firstTry[$0.id] == true }) {
            passed.insert(skill)
            state.testedOutSkills.insert(skill)
            var rec = state.record(for: skill)
            if rec.level < .abstract { rec.level = .abstract; rec.currentLevelTries = [] }
            state.skills[skill] = rec
        }
        guard let ch = content.chapter(scene.chapter) else { return passed }
        for sid in ch.scenes where sid != scene.id {
            guard let s = content.scene(sid), !s.items.isEmpty else { continue }
            if s.items.allSatisfy({ passed.contains($0.skill) }) { state.completedScenes.insert(sid) }
        }
        return passed
    }
}
