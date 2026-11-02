import Foundation

/// Where to pick up if the app is closed mid-scene (AC-S6): the start of the same item.
public struct ResumePoint: Codable, Equatable, Sendable {
    public let sceneID: SceneID
    public let itemIDs: [String]
    public let warmupCount: Int
    public let index: Int
}

/// What opens the next chapter (decided with Shrikant after the Chapter 1 retro).
public enum ChapterGate: String, Codable, CaseIterable, Sendable {
    /// Every skill at the Numbers level with 4 of the last 5 right (or tested out). Default.
    case secure
    /// The spec's full mastery rule: 80% of the last 10 Numbers items over 2 days.
    case mastered
    /// Story order only: finishing the scenes opens the next chapter.
    case scenesOnly

    public var parentLabel: String {
        switch self {
        case .secure: return "When each skill is secure with numbers"
        case .mastered: return "When each skill is fully mastered"
        case .scenesOnly: return "When the scenes are finished"
        }
    }
}

public struct SoundSettings: Codable, Equatable, Sendable {
    public var narrationVolume: Double = 1.0
    public var musicOn = true
    /// 0.5 is AVSpeechUtteranceDefaultSpeechRate; a little slower suits a 6-year-old.
    public var speechRate: Double = 0.42
    public var subtitles = false
    public init() {}
}

/// Everything saved on the device. One child profile in the MVP.
public struct LearnerState: Codable, Equatable, Sendable {
    public static let currentVersion = 1

    public var version = LearnerState.currentVersion
    public var skills: [SkillID: SkillRecord] = [:]
    public var completedScenes: Set<SceneID> = []
    /// Chapters the parent unlocked by hand (AC-P6).
    public var unlockedChapters: Set<ChapterID> = []
    /// Item IDs whose answer had to be shown. Cleared by a later first-try correct.
    public var needsPractice: Set<String> = []
    public var lastSeen: [String: Date] = [:]
    public var resume: ResumePoint?
    public var time = TimeKeeper()
    public var timeSettings = TimeSettings()
    public var sound = SoundSettings()
    public var hasMetSparkle = false
    public var chapterGate: ChapterGate = .secure
    /// Skills she showed she already knows in a test-out challenge (L12). They count as secure.
    public var testedOutSkills: Set<SkillID> = []
    /// Name, companion and daily limit, chosen once at first launch. Nil until setup is done.
    public private(set) var setup: SetupChoices?
    /// Places whose "write it down" moment she has done (F1, charter v1.5).
    public var wroteDown: Set<ChapterID> = []
    /// The Puzzle Board: story levels, streaks, lanterns and weak spots (F3).
    public var board = BoardRecord()
    /// Puzzle scrolls she has finished, by scroll id (F2, F4).
    public var sheets: [String: SheetRecord] = [:]

    public init() {}

    public var needsSetup: Bool { setup == nil }
    public var heroName: String { setup?.heroName ?? SetupChoices.defaultName }
    public var companion: Companion { setup?.companion ?? .unicorn }

    /// Saves the setup choices. Locked: a second call does nothing (only "reset everything" starts setup again).
    @discardableResult
    public mutating func completeSetup(_ choices: SetupChoices) -> Bool {
        guard setup == nil else { return false }
        setup = choices
        timeSettings.setDailyLimit(choices.dailyLimitMinutes)
        return true
    }

    enum CodingKeys: String, CodingKey {
        case version, skills, completedScenes, unlockedChapters, needsPractice, lastSeen, resume, time,
             timeSettings, sound, hasMetSparkle, chapterGate, testedOutSkills, setup, wroteDown, board, sheets
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decodeIfPresent(Int.self, forKey: .version) ?? LearnerState.currentVersion
        skills = try c.decodeIfPresent([SkillID: SkillRecord].self, forKey: .skills) ?? [:]
        completedScenes = try c.decodeIfPresent(Set<SceneID>.self, forKey: .completedScenes) ?? []
        unlockedChapters = try c.decodeIfPresent(Set<ChapterID>.self, forKey: .unlockedChapters) ?? []
        needsPractice = try c.decodeIfPresent(Set<String>.self, forKey: .needsPractice) ?? []
        lastSeen = try c.decodeIfPresent([String: Date].self, forKey: .lastSeen) ?? [:]
        resume = try c.decodeIfPresent(ResumePoint.self, forKey: .resume)
        time = try c.decodeIfPresent(TimeKeeper.self, forKey: .time) ?? TimeKeeper()
        timeSettings = try c.decodeIfPresent(TimeSettings.self, forKey: .timeSettings) ?? TimeSettings()
        sound = try c.decodeIfPresent(SoundSettings.self, forKey: .sound) ?? SoundSettings()
        hasMetSparkle = try c.decodeIfPresent(Bool.self, forKey: .hasMetSparkle) ?? false
        chapterGate = try c.decodeIfPresent(ChapterGate.self, forKey: .chapterGate) ?? .secure
        testedOutSkills = try c.decodeIfPresent(Set<SkillID>.self, forKey: .testedOutSkills) ?? []
        setup = try c.decodeIfPresent(SetupChoices.self, forKey: .setup)
        wroteDown = try c.decodeIfPresent(Set<ChapterID>.self, forKey: .wroteDown) ?? []
        board = try c.decodeIfPresent(BoardRecord.self, forKey: .board) ?? BoardRecord()
        sheets = try c.decodeIfPresent([String: SheetRecord].self, forKey: .sheets) ?? [:]
    }

    public func record(for skill: SkillID) -> SkillRecord { skills[skill] ?? SkillRecord() }

    public func level(for skill: SkillID) -> CPALevel { record(for: skill).level }

    /// Stores a finished item and updates the CPA level and practice list.
    public mutating func apply(_ result: ItemResult, engine: MasteryEngine) {
        var rec = record(for: result.skill)
        // A skill first met through a numeral-only item starts at that level, so its results count.
        if rec.history.isEmpty && result.level > rec.level { rec.level = result.level }
        engine.record(result, into: &rec)
        skills[result.skill] = rec
        lastSeen[result.itemID] = result.date
        if result.needsPractice {
            needsPractice.insert(result.itemID)
        } else if result.firstTryCorrect {
            needsPractice.remove(result.itemID)
        }
    }

    /// AC-P6: reset one skill to a fresh state.
    public mutating func resetSkill(_ skill: SkillID, content: Content) {
        skills[skill] = nil
        testedOutSkills.remove(skill)
        let ids = Set(content.scenes.flatMap(\.items).filter { $0.skill == skill }.map(\.id))
        needsPractice.subtract(ids)
    }

    /// AC-P7: back to a fresh install, keeping the sound settings, quiet hours and gate. Setup starts again,
    /// since it is the only way to change the name, companion and daily limit (charter v1.3).
    public mutating func resetAllProgress() {
        var keepTime = timeSettings
        keepTime.setDailyLimit(TimeSettings.defaultLimit)
        let keepSound = sound
        let keepGate = chapterGate
        self = LearnerState()
        timeSettings = keepTime
        sound = keepSound
        chapterGate = keepGate
    }
}

/// Saves the learner state as JSON in Application Support. Nothing leaves the device.
public struct StateStore: Sendable {
    public let url: URL

    public init(url: URL) { self.url = url }

    public static func defaultStore() -> StateStore {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return StateStore(url: dir.appendingPathComponent("KingdomOfNumbers/learner.json"))
    }

    public func load() -> LearnerState {
        guard let data = try? Data(contentsOf: url) else { return LearnerState() }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(LearnerState.self, from: data)) ?? LearnerState()
    }

    public func save(_ state: LearnerState) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(state)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }
}
