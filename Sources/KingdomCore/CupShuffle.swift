import Foundation

// Cup shuffle widget (issue #27, rules C1 to C10: docs/features/cup-shuffle.md).
// Trains attention: following one moving cup among look-alikes and holding it in mind until the cups stop.

/// Her choice of cups and speed (C1). Speed 1 is the slowest.
public struct CupSettings: Codable, Equatable, Hashable, Sendable {
    public let cups: Int
    public let speed: Int

    public init(cups: Int, speed: Int) {
        self.cups = cups >= 5 ? 5 : 3
        self.speed = min(3, max(1, speed))
    }

    public static let first = CupSettings(cups: 3, speed: 1)
    public static let cupChoices = [3, 5]
    public static let speedChoices = [1, 2, 3]

    /// How many swaps a round has (C3).
    public var swaps: Int { (cups == 5 ? 5 : 3) + (speed - 1) * 2 }

    /// Seconds for one swap (C3).
    public var swapSeconds: Double { [0.9, 0.6, 0.4][speed - 1] }

    /// The setting one step harder: faster first, then five cups (C9).
    public var harder: CupSettings? {
        if speed < 3 { return CupSettings(cups: cups, speed: speed + 1) }
        if cups == 3 { return CupSettings(cups: 5, speed: 1) }
        return nil
    }

    /// The setting one step easier: slower first, then three cups (C9).
    public var easier: CupSettings? {
        if speed > 1 { return CupSettings(cups: cups, speed: speed - 1) }
        if cups == 5 { return CupSettings(cups: 3, speed: 1) }
        return nil
    }
}

/// One round: which cup hides the bird and the swaps, as pairs of positions (left to right, from 0).
public struct CupShufflePlan: Equatable, Sendable {
    public let cups: Int
    /// The cup (by id) the bird hides under. Cups start in order: cup i at position i.
    public let birdCup: Int
    public let swaps: [[Int]]

    public init(cups: Int, birdCup: Int, swaps: [[Int]]) {
        self.cups = cups
        self.birdCup = birdCup
        self.swaps = swaps
    }

    /// A round for these settings. The bird's cup moves in at least half the swaps, so watching it always matters, and
    /// the same pair never swaps twice in a row (that would look like nothing happened).
    public init(settings: CupSettings, seed: UInt64) {
        var rng = SeededRandom(seed: seed)
        let n = settings.cups
        let count = settings.swaps
        let bird = Int.random(in: 0..<n, using: &rng)
        let needed = (count + 1) / 2
        var order = Array(0..<n)
        var swaps: [[Int]] = []
        var birdSwaps = 0
        for k in 0..<count {
            let birdAt = order.firstIndex(of: bird)!
            let mustMoveBird = needed - birdSwaps >= count - k
            let moveBird = mustMoveBird || Bool.random(using: &rng)
            var pairs: [[Int]] = []
            for a in 0..<n {
                for b in (a + 1)..<n where b - a <= 2 {
                    let hasBird = a == birdAt || b == birdAt
                    if hasBird == moveBird && [a, b] != swaps.last { pairs.append([a, b]) }
                }
            }
            if pairs.isEmpty {
                // Only when the one pair left was just used: take it anyway rather than skip the swap.
                pairs = [swaps.last!]
            }
            let pair = pairs[Int.random(in: 0..<pairs.count, using: &rng)]
            if pair.contains(birdAt) { birdSwaps += 1 }
            order.swapAt(pair[0], pair[1])
            swaps.append(pair)
        }
        self.init(cups: n, birdCup: bird, swaps: swaps)
    }

    /// The tutorial round (C7): three cups and one slow swap that moves the bird's cup.
    public static func tutorial(seed: UInt64) -> CupShufflePlan {
        var rng = SeededRandom(seed: seed)
        let bird = Int.random(in: 0..<3, using: &rng)
        let other = [0, 1, 2].filter { $0 != bird && abs($0 - bird) == 1 }
        let partner = other[Int.random(in: 0..<other.count, using: &rng)]
        return CupShufflePlan(cups: 3, birdCup: bird, swaps: [[min(bird, partner), max(bird, partner)]])
    }

    /// Which cup is at each position after the first `steps` swaps.
    public func order(after steps: Int) -> [Int] {
        var order = Array(0..<cups)
        for pair in swaps.prefix(max(0, steps)) { order.swapAt(pair[0], pair[1]) }
        return order
    }

    /// Where the bird's cup ends up.
    public var birdPosition: Int { order(after: swaps.count).firstIndex(of: birdCup)! }

    /// How many swaps moved the bird's cup.
    public var birdMoves: Int {
        var order = Array(0..<cups)
        var moves = 0
        for pair in swaps {
            if pair.contains(where: { order[$0] == birdCup }) { moves += 1 }
            order.swapAt(pair[0], pair[1])
        }
        return moves
    }
}

/// One finished round, for the suggestion (C9) and the grown-ups' page (C10).
public struct CupRound: Codable, Equatable, Sendable {
    public var cups: Int
    public var speed: Int
    public var found: Bool
    public var date: Date

    public init(settings: CupSettings, found: Bool, date: Date) {
        cups = settings.cups
        speed = settings.speed
        self.found = found
        self.date = date
    }

    public var settings: CupSettings { CupSettings(cups: cups, speed: speed) }
}

/// What the cup shuffle widget remembers.
public struct CupShuffleRecord: Codable, Equatable, Sendable {
    /// False until she has done the first-time tutorial (C7). A grown-up can turn it back on.
    public var tutorialDone = false
    /// Her last choice, offered again next time (C1).
    public var last = CupSettings.first
    public var rounds: [CupRound] = []
    public var roundsPlayed = 0

    public init() {}

    enum CodingKeys: String, CodingKey { case tutorialDone, last, rounds, roundsPlayed }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tutorialDone = try c.decodeIfPresent(Bool.self, forKey: .tutorialDone) ?? false
        last = try c.decodeIfPresent(CupSettings.self, forKey: .last) ?? .first
        rounds = try c.decodeIfPresent([CupRound].self, forKey: .rounds) ?? []
        roundsPlayed = try c.decodeIfPresent(Int.self, forKey: .roundsPlayed) ?? rounds.count
    }

    public mutating func finish(_ settings: CupSettings, found: Bool, at date: Date) {
        last = settings
        rounds.append(CupRound(settings: settings, found: found, date: date))
        if rounds.count > 60 { rounds.removeFirst(rounds.count - 60) }
        roundsPlayed += 1
    }

    /// The rounds at the end of her history played at this setting, newest last.
    private func trailing(_ settings: CupSettings) -> [CupRound] {
        var out: [CupRound] = []
        for r in rounds.reversed() {
            guard r.settings == settings else { break }
            out.insert(r, at: 0)
        }
        return out
    }

    /// C9: three finds in a row suggest one step harder; two misses in a row suggest one step easier.
    /// Nil when there's nothing to suggest. She still chooses.
    public func suggestion(after settings: CupSettings) -> CupSettings? {
        let t = trailing(settings)
        if t.count >= 3 && t.suffix(3).allSatisfy(\.found) { return settings.harder }
        if t.count >= 2 && t.suffix(2).allSatisfy({ !$0.found }) { return settings.easier }
        return nil
    }

    /// For the grown-ups' page: finds and rounds at each setting she has played.
    public var bySetting: [(settings: CupSettings, found: Int, played: Int)] {
        var tally: [CupSettings: (Int, Int)] = [:]
        for r in rounds { tally[r.settings, default: (0, 0)].0 += r.found ? 1 : 0; tally[r.settings, default: (0, 0)].1 += 1 }
        return tally.map { (settings: $0.key, found: $0.value.0, played: $0.value.1) }
            .sorted { ($0.settings.cups, $0.settings.speed) < ($1.settings.cups, $1.settings.speed) }
    }

    /// C10: an idea to try away from the screen, changing with each round.
    public static let homeIdeas = [
        "Hide a coin under one of three cups and shuffle slowly. Let her shuffle for you too.",
        "Play \"What's missing?\": show 5 toys, cover them, take one away and ask which one went.",
        "On a walk, pick one bird or car and follow it with your eyes for as long as you can.",
        "Swap two of her toys on a shelf while she closes her eyes. Can she spot what moved?",
    ]

    public var homeIdea: String { Self.homeIdeas[roundsPlayed % Self.homeIdeas.count] }
}
