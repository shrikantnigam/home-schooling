import Foundation

// From story to problem solving (charter v1.5: L14, L15, L16; docs/features/problem-solving.md).

/// The four operations. Each opens when the place that teaches it is finished.
public enum MathOp: String, Codable, CaseIterable, Sendable {
    case add, subtract, multiply, divide

    public var sign: String {
        switch self {
        case .add: return "+"
        case .subtract: return "−"
        case .multiply: return "×"
        case .divide: return "÷"
        }
    }

    /// How the sign is read aloud.
    public var spoken: String {
        switch self {
        case .add: return "plus"
        case .subtract: return "minus"
        case .multiply: return "times"
        case .divide: return "divided by"
        }
    }

    /// The place whose story teaches it.
    public var place: ChapterID {
        switch self {
        case .add: return "garden"
        case .subtract: return "goblin"
        case .multiply: return "ball"
        case .divide: return "feast"
        }
    }

    /// The result, or nil when it isn't a whole number she has met (negative, or a remainder).
    public func apply(_ a: Int, _ b: Int) -> Int? {
        switch self {
        case .add: return a + b
        case .subtract: return a >= b ? a - b : nil
        case .multiply: return a * b
        case .divide: return b > 0 && a % b == 0 ? a / b : nil
        }
    }

    /// Accepts the typed minus and the plain hyphen alike.
    public static func from(sign: String) -> MathOp? {
        let s = sign.trimmingCharacters(in: .whitespaces)
        if s == "-" { return .subtract }
        if s == "x" || s == "*" { return .multiply }
        if s == "/" { return .divide }
        return allCases.first { $0.sign == s }
    }
}

// MARK: Write it down (F1)

/// A number sentence as the tiles she places, e.g. ["6", "+", "4", "=", "10"].
public struct NumberSentence: Equatable, Sendable {
    public let tokens: [String]
    public init(_ tokens: [String]) { self.tokens = tokens }

    public var equalsIndex: Int? { tokens.firstIndex(of: "=") }

    /// L16: the answer comes first, so "=" can't be read as "the answer comes next".
    public var isAnswerFirst: Bool {
        guard let e = equalsIndex else { return false }
        return e == 1 && tokens.count > 3
    }
}

/// The "write it down" moment at the end of a place: what happened, as number sentences.
public struct WriteItDown: Equatable, Sendable {
    public let chapter: ChapterID
    public let sentences: [NumberSentence]
    /// One distractor number she might pick by mistake.
    public let distractor: String

    /// Every tile on the table: the sentences' numbers and signs plus the distractor. Numbers first.
    public var tiles: [String] {
        var seen: [String] = []
        for t in sentences.flatMap(\.tokens) + [distractor] where !seen.contains(t) { seen.append(t) }
        let numbers = seen.filter { Int($0) != nil }.sorted { (Int($0) ?? 0) < (Int($1) ?? 0) }
        return numbers + seen.filter { Int($0) == nil }
    }

    public static let places: [ChapterID] = ["prologue", "garden", "bridge", "goblin", "ball", "feast", "moon"]

    public static func forPlace(_ chapter: ChapterID) -> WriteItDown? {
        func s(_ t: String) -> NumberSentence { NumberSentence(t.split(separator: " ").map(String.init)) }
        switch chapter {
        case "prologue": return WriteItDown(chapter: chapter, sentences: [s("5 = 5")], distractor: "4")
        case "garden": return WriteItDown(chapter: chapter, sentences: [s("6 + 4 = 10"), s("10 = 6 + 4")], distractor: "5")
        case "bridge": return WriteItDown(chapter: chapter, sentences: [s("10 + 3 = 13"), s("13 = 10 + 3")], distractor: "7")
        case "goblin": return WriteItDown(chapter: chapter, sentences: [s("12 − 5 = 7"), s("7 = 12 − 5")], distractor: "8")
        case "ball": return WriteItDown(chapter: chapter, sentences: [s("3 × 4 = 12"), s("12 = 3 × 4")], distractor: "7")
        case "feast": return WriteItDown(chapter: chapter, sentences: [s("12 ÷ 3 = 4"), s("4 = 12 ÷ 3")], distractor: "9")
        case "moon": return WriteItDown(chapter: chapter, sentences: [s("½ of 8 = 4"), s("4 = ½ of 8")], distractor: "2")
        default: return nil
        }
    }
}

/// She fills a sentence's slots left to right by tapping tiles.
public struct SlotFiller: Equatable, Sendable {
    public let sentence: NumberSentence
    public private(set) var filled: [String] = []

    public init(_ sentence: NumberSentence) { self.sentence = sentence }

    public var isComplete: Bool { filled.count == sentence.tokens.count }
    public var expected: String? { isComplete ? nil : sentence.tokens[filled.count] }

    /// True when the tile is the one that goes next. A wrong tile is not placed.
    @discardableResult
    public mutating func tap(_ tile: String) -> Bool {
        guard let e = expected, e == tile else { return false }
        filled.append(tile)
        return true
    }

    /// The balance: the left pan is full once everything before "=" is placed.
    public var leftDone: Bool { filled.count >= (sentence.equalsIndex ?? sentence.tokens.count) }
    public var balanced: Bool { isComplete }
}

// MARK: Puzzle Board (F3)

/// One puzzle on the board. Level 1: story and picture. Level 2: story words only. Level 3: the bare sentence
/// with the sign missing, where choosing the sign is the whole puzzle (L14).
public struct BoardPuzzle: Equatable, Sendable {
    public let op: MathOp
    public let a: Int
    public let b: Int
    public let level: Int

    public init(op: MathOp, a: Int, b: Int, level: Int) {
        self.op = op
        self.a = a
        self.b = b
        self.level = min(3, max(1, level))
    }

    public var answer: Int { op.apply(a, b) ?? 0 }
    public var storyLine: LineID { "board.story.\(op.rawValue)" }
    public var asksForAnswer: Bool { level < 3 }

    /// Four answer tiles in order, the answer among them.
    public var choices: [Int] {
        let n = answer
        var c: [Int] = [n]
        for d in [1, -1, 2, -2, 3, 4] where c.count < 4 {
            let v = n + d
            if v >= 0 && !c.contains(v) { c.append(v) }
        }
        return c.sorted()
    }
}

/// What the board remembers: the story level per operation, streaks, lanterns, and her weak spots.
public struct BoardRecord: Codable, Equatable, Sendable {
    public var levels: [String: Int] = [:]
    public var streak: [String: Int] = [:]
    public var missStreak: [String: Int] = [:]
    public var solved: [String: Int] = [:]
    public var missed: [String: Int] = [:]
    /// Mistakes on scrolls, by operation (F4).
    public var sheetMistakes: [String: Int] = [:]
    public var lanterns = 0
    public var puzzlesServed = 0
    public var puzzlesMade = 0

    public init() {}

    public func level(_ op: MathOp) -> Int { levels[op.rawValue] ?? 1 }

    /// A finished puzzle. Three first-try solves in a row go up a level; two misses in a row go down.
    public mutating func record(_ op: MathOp, firstTry: Bool) {
        let k = op.rawValue
        lanterns += 1
        if firstTry {
            solved[k, default: 0] += 1
            missStreak[k] = 0
            streak[k, default: 0] += 1
            if streak[k, default: 0] >= 3 {
                levels[k] = min(3, level(op) + 1)
                streak[k] = 0
            }
        } else {
            missed[k, default: 0] += 1
            streak[k] = 0
            missStreak[k, default: 0] += 1
            if missStreak[k, default: 0] >= 2 {
                levels[k] = max(1, level(op) - 1)
                missStreak[k] = 0
            }
        }
    }

    /// Higher means she needs it more: misses and scroll mistakes count against, solves count for.
    public func weakness(_ op: MathOp) -> Int {
        let k = op.rawValue
        return missed[k, default: 0] * 3 + sheetMistakes[k, default: 0] * 3 - solved[k, default: 0]
    }

    enum CodingKeys: String, CodingKey {
        case levels, streak, missStreak, solved, missed, sheetMistakes, lanterns, puzzlesServed, puzzlesMade
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        levels = try c.decodeIfPresent([String: Int].self, forKey: .levels) ?? [:]
        streak = try c.decodeIfPresent([String: Int].self, forKey: .streak) ?? [:]
        missStreak = try c.decodeIfPresent([String: Int].self, forKey: .missStreak) ?? [:]
        solved = try c.decodeIfPresent([String: Int].self, forKey: .solved) ?? [:]
        missed = try c.decodeIfPresent([String: Int].self, forKey: .missed) ?? [:]
        sheetMistakes = try c.decodeIfPresent([String: Int].self, forKey: .sheetMistakes) ?? [:]
        lanterns = try c.decodeIfPresent(Int.self, forKey: .lanterns) ?? 0
        puzzlesServed = try c.decodeIfPresent(Int.self, forKey: .puzzlesServed) ?? 0
        puzzlesMade = try c.decodeIfPresent(Int.self, forKey: .puzzlesMade) ?? 0
    }
}

/// Makes puzzles from what she has been taught.
public struct ProblemMaker: Sendable {
    public let progression: Progression

    public init(progression: Progression) { self.progression = progression }

    /// Operations whose place she has finished, in teaching order.
    public func unlocked(_ state: LearnerState) -> [MathOp] {
        MathOp.allCases.filter { progression.allScenesDone($0.place, state: state) }
    }

    /// Sums and differences go to 20 once the Bridge of Tens is finished.
    public func top(_ state: LearnerState) -> Int {
        progression.allScenesDone("bridge", state: state) ? 20 : 10
    }

    /// The numbers for one puzzle. `n` makes it repeatable (QA) and varied (each new puzzle).
    public static func numbers(_ op: MathOp, n: Int, top: Int) -> (Int, Int) {
        var rng = SeededRandom(seed: UInt64(n) &* 7919 &+ UInt64(op.rawValue.count))
        func r(_ lo: Int, _ hi: Int) -> Int { hi <= lo ? lo : Int.random(in: lo...hi, using: &rng) }
        switch op {
        case .add:
            let a = r(1, top - 2)
            return (a, r(1, min(9, top - a)))
        case .subtract:
            let a = r(3, top)
            return (a, r(1, min(9, a - 1)))
        case .multiply:
            return (r(2, 5), r(2, 5))
        case .divide:
            let b = r(2, 5)
            return (b * r(2, 5), b)
        }
    }

    /// A puzzle at the operation's current story level. At level 3 only one sign may make it true.
    public static func puzzle(_ op: MathOp, level: Int, n: Int, top: Int) -> BoardPuzzle {
        var k = n
        while true {
            let (a, b) = numbers(op, n: k, top: top)
            let p = BoardPuzzle(op: op, a: a, b: b, level: level)
            let others = MathOp.allCases.filter { $0 != op && $0.apply(a, b) == p.answer }
            if level < 3 || others.isEmpty || k > n + 50 { return p }
            k += 1
        }
    }

    /// Which operation comes next: the weakest she has, taking turns so the board stays mixed (L13).
    public static func nextOperation(_ unlocked: [MathOp], board: BoardRecord) -> MathOp? {
        guard !unlocked.isEmpty else { return nil }
        if unlocked.count == 1 { return unlocked[0] }
        let served = board.puzzlesServed
        let turn = unlocked[(served - served / 3) % unlocked.count]
        let weakest = unlocked.max { board.weakness($0) < board.weakness($1) } ?? turn
        // Every third puzzle goes to her weakest operation; the others take turns.
        return served % 3 == 2 ? weakest : turn
    }
}

/// A puzzle she makes for the companion (L15). The companion gets every third one wrong, starting with her
/// second puzzle, so she checks its work (L6).
public struct MadePuzzle: Equatable, Sendable {
    public let op: MathOp
    public let a: Int
    public let b: Int

    /// Keeps her puzzle to whole numbers she has met: no taking away more than there is, no remainders.
    public init(op: MathOp, a: Int, b: Int) {
        var a = max(0, min(20, a)), b = max(0, min(20, b))
        switch op {
        case .subtract: if b > a { swap(&a, &b) }
        case .divide:
            b = max(1, min(10, b))
            a = max(b, a - a % b)
        case .multiply:
            a = min(10, a); b = min(10, b)
        case .add: break
        }
        self.op = op
        self.a = a
        self.b = b
    }

    public var answer: Int { op.apply(a, b) ?? 0 }

    public static func companionMakesMistake(made: Int) -> Bool { made % 3 == 1 }

    /// The companion's answer for her `made`-th puzzle (counting from 0).
    public func companionAnswer(made: Int) -> Int {
        guard Self.companionMakesMistake(made: made) else { return answer }
        return answer + 1
    }
}
