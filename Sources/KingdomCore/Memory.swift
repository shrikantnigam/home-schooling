import Foundation

/// The memory game (Shrikant, 2026-11-03; docs/features/memory.md, rules M1 to M10). It trains memory: keeping
/// where things are in mind. Ten characters; Easy, Medium and Hard levels; pairs of the same character.

/// The ten characters on the cards (M1). The art lives in the app; this is only who they are.
public enum MemoryCharacter: String, Codable, CaseIterable, Sendable {
    case unicorn, superhero, princess, monster, gnome, siara, bird, frog, teddy, cat
}

/// M2: the three levels, each a range of pairs (two cards of each character).
public enum MemoryLevel: String, Codable, CaseIterable, Sendable {
    case easy, medium, hard

    /// Characters (pairs) in a game at this level. Easy 3–4 (6–8 cards), Medium 4–6 (8–12), Hard 6–8 (12–16).
    public var pairRange: ClosedRange<Int> {
        switch self {
        case .easy: return 3...4
        case .medium: return 4...6
        case .hard: return 6...8
        }
    }

    public var title: String { rawValue.capitalized }

    /// Columns and rows for a card count, wider than tall like the iPad.
    public static func grid(cards: Int) -> (cols: Int, rows: Int) {
        switch cards {
        case ...6: return (3, 2)
        case ...8: return (4, 2)
        case ...10: return (5, 2)
        case ...12: return (4, 3)
        case ...14: return (5, 3)
        default: return (4, 4)
        }
    }
}

/// One shuffled game: which character is on each card. Seeded, so QA and tests can replay it.
public struct MemoryDeal: Equatable, Sendable {
    public let level: MemoryLevel
    public let cards: [MemoryCharacter]

    public var pairs: Int { cards.count / 2 }

    public init(level: MemoryLevel, pairs: Int, seed: UInt64) {
        self.level = level
        let n = min(max(pairs, level.pairRange.lowerBound), level.pairRange.upperBound)
        var rng = SplitMix(seed: seed)
        // Pick n different characters, then two cards of each, shuffled.
        var pool = MemoryCharacter.allCases
        var chosen: [MemoryCharacter] = []
        for _ in 0..<n { chosen.append(pool.remove(at: Int(rng.next() % UInt64(pool.count)))) }
        var deck = chosen + chosen
        for i in stride(from: deck.count - 1, to: 0, by: -1) {
            deck.swapAt(i, Int(rng.next() % UInt64(i + 1)))
        }
        cards = deck
    }

    public func isMatch(_ a: Int, _ b: Int) -> Bool { a != b && cards[a] == cards[b] }
}

/// A small seeded generator (the app's other games use the same idea).
struct SplitMix {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// One finished game, for the next size (M5) and the parent dashboard (M9).
public struct MemoryResult: Codable, Equatable, Sendable {
    public let level: MemoryLevel
    public let pairs: Int
    /// Pairs of cards turned over (each try is two cards).
    public let tries: Int
    public let date: Date

    public init(level: MemoryLevel, pairs: Int, tries: Int, date: Date) {
        self.level = level
        self.pairs = pairs
        self.tries = tries
        self.date = date
    }

    /// Extra tries beyond a perfect game (one try per pair).
    public var misses: Int { max(0, tries - pairs) }

    /// M5: few enough misses to grow the next game by one pair.
    public var isEasy: Bool { misses <= pairs }
}

/// Everything the memory game remembers.
public struct MemoryRecord: Codable, Equatable, Sendable {
    /// M6: true once she has heard the one-time intro.
    public var introHeard = false
    /// Pairs for her next game at each level (M5).
    public var nextPairs: [MemoryLevel: Int] = [:]
    public var results: [MemoryResult] = []
    public var gamesPlayed = 0

    public init() {}

    enum CodingKeys: String, CodingKey { case introHeard, nextPairs, results, gamesPlayed }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        introHeard = try c.decodeIfPresent(Bool.self, forKey: .introHeard) ?? false
        nextPairs = try c.decodeIfPresent([MemoryLevel: Int].self, forKey: .nextPairs) ?? [:]
        results = try c.decodeIfPresent([MemoryResult].self, forKey: .results) ?? []
        gamesPlayed = try c.decodeIfPresent(Int.self, forKey: .gamesPlayed) ?? results.count
    }

    /// M3: Easy is open; Medium opens after she finishes an Easy game; Hard after a Medium one.
    public func isOpen(_ level: MemoryLevel) -> Bool {
        switch level {
        case .easy: return true
        case .medium: return results.contains { $0.level == .easy }
        case .hard: return results.contains { $0.level == .medium }
        }
    }

    /// M4: her next game at a level starts at its smallest size.
    public func pairs(for level: MemoryLevel) -> Int {
        let r = level.pairRange
        return min(max(nextPairs[level] ?? r.lowerBound, r.lowerBound), r.upperBound)
    }

    /// M5: an easy game (misses no more than the pairs) adds a pair next time, up to the level's top; a hard one
    /// (misses more than twice the pairs) takes one away, down to its bottom.
    public mutating func finish(_ r: MemoryResult) {
        results.append(r)
        if results.count > 60 { results.removeFirst(results.count - 60) }
        gamesPlayed += 1
        let range = r.level.pairRange
        var next = pairs(for: r.level)
        if r.isEasy { next += 1 } else if r.misses > 2 * r.pairs { next -= 1 }
        nextPairs[r.level] = min(max(next, range.lowerBound), range.upperBound)
    }

    /// For the parent dashboard: the last ten games.
    public var recent: [MemoryResult] { Array(results.suffix(10)) }

    /// M10: one off-screen idea for home.
    public var homeIdea: String {
        let ideas = [
            "Put three toys under three cups or cloths, let her look, cover them, and ask where each one is.",
            "Lay out four pairs of socks face down (rolled up) and play pairs together.",
            "After a walk, ask her to remember three things she saw, in order.",
        ]
        return ideas[gamesPlayed % ideas.count]
    }
}
