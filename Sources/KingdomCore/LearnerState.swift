import Foundation

/// Where to pick up if the app is closed mid-scene (AC-S6): the start of the same item.
public struct ResumePoint: Codable, Equatable, Sendable {
    public let sceneID: SceneID
    public let itemIDs: [String]
    public let warmupCount: Int
    public let index: Int
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

    public init() {}

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
        self = LearnerState()
        timeSettings = keepTime
        sound = keepSound
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
