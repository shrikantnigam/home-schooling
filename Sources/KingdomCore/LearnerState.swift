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
    /// Every skill at the Numbers level with 4 of the last 5 right, across 2 days. Default.
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

    public init() {}

    enum CodingKeys: String, CodingKey {
        case version, skills, completedScenes, unlockedChapters, needsPractice, lastSeen, resume, time,
             timeSettings, sound, hasMetSparkle, chapterGate
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
    }

    public func record(for skill: SkillID) -> SkillRecord { skills[skill] ?? SkillRecord() }

    public func level(for skill: SkillID) -> CPALevel { record(for: skill).level }

    /// Stores a finished item and updates the CPA level and practice list.
    public mutating func apply(_ result: ItemResult, engine: MasteryEngine) {
        var rec = record(for: result.skill)
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
        let ids = Set(content.scenes.flatMap(\.items).filter { $0.skill == skill }.map(\.id))
        needsPractice.subtract(ids)
    }

    /// AC-P7: back to a fresh install, but keep the parent's time and sound settings.
    public mutating func resetAllProgress() {
        let keepTime = timeSettings
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
