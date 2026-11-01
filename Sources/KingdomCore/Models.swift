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

    // Chapter 2: The Bridge of Tens
    /// `a` bundles of ten and `b` loose planks; how many planks? Answer: 10a + b.
    case tensOnes
    /// `a` planks and `b` more, filling one ten-frame before the next. Answer: a + b.
    case bridgeAdd

    // Chapter 3: The Goblin's Gems
    /// `a` gems, the goblin takes `b`; how many are left? Answer: a - b.
    case takeAway
    /// Sparkle on `a` hops back `b` times; where does she land? Answer: a - b.
    case hopBack
    /// Siara has `a` gems, the goblin has `b`; how many more does Siara have? Answer: a - b.
    case compare
    /// `a` minus `b` with numerals, models one tap away. Answer: a - b.
    case subtraction

    // Chapter 4: The Royal Ball
    /// `a` tables with `b` guests at each; how many guests? Answer: a × b.
    case groups
    /// `a` rows of `b` chairs; how many chairs? Answer: a × b.
    case array
    /// Hop `a` times, `b` stones each hop; where does Sparkle land? Answer: a × b.
    case skipHop
    /// `a` times `b` with numerals, models one tap away. Answer: a × b.
    case multiply

    // Chapter 5: The Fair Feast
    /// Share `a` treats fairly onto `b` plates; how many on each plate? Answer: a ÷ b.
    case share
    /// `a` berries, `b` in each basket; how many baskets? Answer: a ÷ b.
    case groupInto
    /// `a` divided by `b` with numerals, models one tap away. Answer: a ÷ b.
    case divide

    // Chapter 6: The Moon Crystal
    /// The crystal is cut into `b` equal parts; how many parts? Answer: b.
    case parts
    /// A moonbeam from 0 to 1 cut into `b` equal steps; tap where `a`/`b` lives. Answer: a.
    case fractionLine
    /// One `b`th of `a` gems (one half, one quarter...); how many is that? Answer: a ÷ b.
    case fractionOf
}

/// The hands-on step a concrete item asks for before the numeral tiles appear.
public enum ConcreteStep: Equatable, Sendable {
    /// Answer straight away (tiles or line).
    case none
    /// Tap `n` objects, each one once. When `answers` is true, tapping them all is the answer itself.
    case tap(Int, answers: Bool)
    /// Place `n` things (seeds, planks, treats) with drag or tap.
    case place(Int)
    /// Make `n` hops on the line.
    case hop(Int)
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
        case .tensOnes: return 10 * a + b
        case .bridgeAdd: return a + b
        case .takeAway, .hopBack, .compare, .subtraction: return a - b
        case .groups, .array, .skipHop, .multiply: return a * b
        case .share, .groupInto, .divide, .fractionOf: return b == 0 ? 0 : a / b
        case .parts: return b
        case .fractionLine: return a
        }
    }

    /// Whether the child answers by tapping a stone on the number line rather than a numeral tile.
    public var answersOnLine: Bool {
        switch kind {
        case .findOnLine, .hop, .hopBack, .skipHop, .fractionLine: return true
        default: return false
        }
    }

    /// Kinds whose answer is a count of things, so 0 is never offered as a choice.
    public var answerIsCount: Bool {
        switch kind {
        case .countTap, .howMany, .quickLook, .tensOnes, .groups, .array, .share, .groupInto, .parts, .fractionOf, .divide, .multiply:
            return true
        default: return false
        }
    }

    /// The symbol shown between the numbers at the abstract level.
    public var operatorSymbol: String {
        switch kind {
        case .takeAway, .hopBack, .compare, .subtraction: return "−"
        case .groups, .array, .skipHop, .multiply: return "×"
        case .share, .groupInto, .divide: return "÷"
        default: return "+"
        }
    }

    /// The concrete step for this item (spec: concrete level means she handles the objects).
    public var concreteStep: ConcreteStep {
        switch kind {
        case .countTap: return .tap(a, answers: true)
        case .addMore: return .place(b)
        case .makeTen: return .place(10 - a)
        case .numberBond: return .tap(a - b, answers: false)
        case .hop: return .hop(b)
        case .tensOnes: return .tap(b, answers: false)
        case .bridgeAdd: return .place(b)
        case .takeAway: return .tap(b, answers: false)
        case .hopBack: return .hop(b)
        case .compare: return .tap(a - b, answers: false)
        case .groups: return .tap(a * b, answers: false)
        case .array: return .tap(a, answers: false)
        case .skipHop: return .hop(a)
        case .share, .groupInto, .fractionOf: return .place(a)
        case .parts: return .tap(b, answers: false)
        case .howMany, .findOnLine, .quickLook, .equation, .subtraction, .multiply, .divide, .fractionLine: return .none
        }
    }
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
