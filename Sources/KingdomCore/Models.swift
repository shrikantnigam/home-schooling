import Foundation

/// Concrete, Pictorial, Abstract (Singapore math). Every item is shown at one level.
public enum CPALevel: Int, Codable, CaseIterable, Comparable, Sendable {
    case concrete = 0
    case pictorial = 1
    case abstract = 2

    public static func < (lhs: CPALevel, rhs: CPALevel) -> Bool { lhs.rawValue < rhs.rawValue }

    public var up: CPALevel { CPALevel(rawValue: min(rawValue + 1, 2)) ?? .abstract }
    public var down: CPALevel { CPALevel(rawValue: max(rawValue - 1, 0)) ?? .concrete }

    /// Words for the parent area.
    public var parentLabel: String {
        switch self {
        case .concrete: return "Objects"
        case .pictorial: return "Pictures"
        case .abstract: return "Numbers"
        }
    }
}

public typealias SkillID = String
public typealias SceneID = String
public typealias ChapterID = String
public typealias LineID = String

public struct Skill: Codable, Hashable, Identifiable, Sendable {
    public let id: SkillID
    public let chapter: ChapterID
    /// Name shown to the parent, e.g. "Make 10".
    public let name: String
    /// One-line off-screen activity for the "Stuck on" list.
    public let homeTip: String

    public init(id: SkillID, chapter: ChapterID, name: String, homeTip: String) {
        self.id = id
        self.chapter = chapter
        self.name = name
        self.homeTip = homeTip
    }
}

/// The kind of activity. Each kind has one view in the app.
public enum ActivityKind: String, Codable, CaseIterable, Sendable {
    /// Tap each star once to count it (P1). Answer: a.
    case countTap
    /// How many are there? Pick a numeral (P2). Answer: a.
    case howMany
    /// Tap the stone where `a` lives on the number line (P3). Answer: a.
    case findOnLine
    /// A short look at up to 5 stars, then say how many (P4). Answer: a.
    case quickLook
    /// `a` flowers are awake, plant `b` more; how many now? (G1). Answer: a + b.
    case addMore
    /// `a` flowers shared between two beds; bed one has `b`; how many in bed two? (G2). Answer: a - b.
    case numberBond
    /// Sparkle starts on `a` and hops `b` times; where does she land? (G3). Answer: a + b.
    case hop
    /// The box has `a` flowers; how many more make ten? (G4). Answer: 10 - a.
    case makeTen
    /// `a` plus `b` with numerals, models one tap away (G5). Answer: a + b.
    case equation
}

public struct Item: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let skill: SkillID
    public let kind: ActivityKind
    public let a: Int
    public let b: Int
    /// Largest number on the line or tiles for this item. Defaults to 10; later chapters use 20.
    public let max: Int?

    public init(id: String, skill: SkillID, kind: ActivityKind, a: Int, b: Int = 0, max: Int? = nil) {
        self.id = id
        self.skill = skill
        self.kind = kind
        self.a = a
        self.b = b
        self.max = max
    }

    enum CodingKeys: String, CodingKey { case id, skill, kind, a, b, max }

    /// The top of the number line and numeral range for this item.
    public var top: Int { max ?? 10 }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        skill = try c.decode(SkillID.self, forKey: .skill)
        kind = try c.decode(ActivityKind.self, forKey: .kind)
        a = try c.decode(Int.self, forKey: .a)
        b = try c.decodeIfPresent(Int.self, forKey: .b) ?? 0
        max = try c.decodeIfPresent(Int.self, forKey: .max)
    }

    /// The single correct answer for this item.
    public var answer: Int {
        switch kind {
        case .countTap, .howMany, .findOnLine, .quickLook: return a
        case .addMore, .hop, .equation: return a + b
        case .numberBond: return a - b
        case .makeTen: return 10 - a
        }
    }

    /// Whether the child answers by tapping a stone on the number line rather than a numeral tile.
    public var answersOnLine: Bool { kind == .findOnLine || kind == .hop }
}

public struct StoryScene: Codable, Hashable, Identifiable, Sendable {
    public let id: SceneID
    public let chapter: ChapterID
    public let title: String
    /// Story open lines, spoken in order.
    public let open: [LineID]
    /// How many warm-up items to draw from earlier skills (0 for the very first scene).
    public let warmupCount: Int
    public let items: [Item]
    public let payoff: [LineID]
    public let goodbye: LineID

    public init(id: SceneID, chapter: ChapterID, title: String, open: [LineID], warmupCount: Int,
                items: [Item], payoff: [LineID], goodbye: LineID) {
        self.id = id
        self.chapter = chapter
        self.title = title
        self.open = open
        self.warmupCount = warmupCount
        self.items = items
        self.payoff = payoff
        self.goodbye = goodbye
    }
}

public struct Chapter: Codable, Hashable, Identifiable, Sendable {
    public let id: ChapterID
    public let title: String
    /// Name of the place on the kingdom map.
    public let place: String
    public let scenes: [SceneID]

    public init(id: ChapterID, title: String, place: String, scenes: [SceneID]) {
        self.id = id
        self.title = title
        self.place = place
        self.scenes = scenes
    }
}

public enum Speaker: String, Codable, Sendable {
    case narrator
    case sparkle
}

public struct Line: Codable, Hashable, Sendable {
    public let speaker: Speaker
    /// Text with optional placeholders: {n}, {a}, {b}, {answer}.
    public let text: String

    public init(speaker: Speaker, text: String) {
        self.speaker = speaker
        self.text = text
    }
}
