import Foundation

// Jigsaw widget (issue #25, rules J1 to J12: docs/features/jigsaw.md).
// Picture puzzles build spatial reasoning, part and whole, and strategy. The number-line puzzle builds number order
// and follows the full charter (concrete, then pictures, then numerals).

public enum JigsawCut: String, Codable, CaseIterable, Sendable { case squares, tabs, wavy }
public enum JigsawGuide: String, Codable, CaseIterable, Sendable { case full, faint, none }

/// One rung of the picture-puzzle ladder. Each rung moves exactly one knob from the rung below (J2).
public struct JigsawLevel: Codable, Equatable, Sendable {
    public var pieces: Int
    public var cut: JigsawCut
    public var turning: Bool
    public var guide: JigsawGuide
    public var edgesSorted: Bool

    public init(pieces: Int, cut: JigsawCut, turning: Bool, guide: JigsawGuide, edgesSorted: Bool) {
        self.pieces = pieces
        self.cut = cut
        self.turning = turning
        self.guide = guide
        self.edgesSorted = edgesSorted
    }

    /// The knobs that differ from another level.
    public func knobsChanged(from other: JigsawLevel) -> Int {
        [pieces != other.pieces, cut != other.cut, turning != other.turning, guide != other.guide,
         edgesSorted != other.edgesSorted].filter { $0 }.count
    }
}

public enum JigsawLadder {
    /// Easiest first. Sizes go 10 to 50 in steps of 10 (Shrikant, Nov 2).
    public static let rungs: [JigsawLevel] = {
        var l = JigsawLevel(pieces: 10, cut: .squares, turning: false, guide: .full, edgesSorted: true)
        var out = [l]
        func step(_ change: (inout JigsawLevel) -> Void) { change(&l); out.append(l) }
        step { $0.cut = .tabs }
        step { $0.pieces = 20 }
        step { $0.guide = .faint }
        step { $0.pieces = 30 }
        step { $0.edgesSorted = false }
        step { $0.pieces = 40 }
        step { $0.turning = true }
        step { $0.guide = JigsawGuide.none }
        step { $0.pieces = 50 }
        step { $0.cut = .wavy }
        return out
    }()

    public static let sizes = [10, 20, 30, 40, 50]

    /// Columns and rows for a piece count, wider than tall like the iPad.
    public static func grid(_ pieces: Int) -> (cols: Int, rows: Int) {
        switch pieces {
        case ...10: return (5, 2)
        case ...20: return (5, 4)
        case ...30: return (6, 5)
        case ...40: return (8, 5)
        default: return (10, 5)
        }
    }

    /// The first rung with a bigger size than this one (the quick check jumps by size, J10).
    public static func nextSizeRung(after rung: Int) -> Int {
        let size = rungs[min(rung, rungs.count - 1)].pieces
        return rungs.firstIndex { $0.pieces > size } ?? rungs.count - 1
    }
}

/// How the pieces of one puzzle are cut: each inside edge has a bump on one side (+1) or the other (-1).
public struct JigsawCutPlan: Equatable, Sendable {
    public let cols: Int
    public let rows: Int
    /// Edge between (c, r) and (c+1, r): +1 means a tab sticks out to the right.
    let vertical: [[Int]]
    /// Edge between (c, r) and (c, r+1): +1 means a tab sticks out downwards.
    let horizontal: [[Int]]

    public init(pieces: Int, seed: UInt64) {
        let g = JigsawLadder.grid(pieces)
        self.init(cols: g.cols, rows: g.rows, seed: seed)
    }

    /// A plan with its own shape, e.g. the number line's single row of ten.
    public init(cols: Int, rows: Int, seed: UInt64) {
        let g = (cols: max(1, cols), rows: max(1, rows))
        self.cols = g.cols
        self.rows = g.rows
        var rng = SeededRandom(seed: seed)
        vertical = (0..<max(0, g.cols - 1)).map { _ in (0..<g.rows).map { _ in Bool.random(using: &rng) ? 1 : -1 } }
        horizontal = (0..<g.cols).map { _ in (0..<max(0, g.rows - 1)).map { _ in Bool.random(using: &rng) ? 1 : -1 } }
    }

    public var count: Int { cols * rows }

    public func position(_ index: Int) -> (col: Int, row: Int) { (index % cols, index / cols) }

    /// Edges of a piece as top, right, bottom, left: 0 is a flat border, +1 a tab out, -1 a hole in.
    public func edges(_ index: Int) -> [Int] {
        let (c, r) = position(index)
        let top = r == 0 ? 0 : -horizontal[c][r - 1]
        let bottom = r == rows - 1 ? 0 : horizontal[c][r]
        let left = c == 0 ? 0 : -vertical[c - 1][r]
        let right = c == cols - 1 ? 0 : vertical[c][r]
        return [top, right, bottom, left]
    }

    public func isEdge(_ index: Int) -> Bool { edges(index).contains(0) }
}

/// One finished puzzle, for adapting the level and for the parent area.
public struct JigsawResult: Codable, Equatable, Sendable {
    public var kind: String
    public var pictureID: String?
    public var pieces: Int
    public var firstFits: Int
    public var hintsUsed: Int
    public var maxHintStep: Int
    public var strategy: String?
    public var date: Date

    public init(kind: String, pictureID: String?, pieces: Int, firstFits: Int, hintsUsed: Int, maxHintStep: Int,
                strategy: String?, date: Date) {
        self.kind = kind
        self.pictureID = pictureID
        self.pieces = pieces
        self.firstFits = firstFits
        self.hintsUsed = hintsUsed
        self.maxHintStep = maxHintStep
        self.strategy = strategy
        self.date = date
    }

    public var firstFitRate: Double { pieces == 0 ? 0 : Double(firstFits) / Double(pieces) }
    /// Fits almost all first time, with one hint at most.
    public var isEasy: Bool { firstFitRate >= 0.85 && hintsUsed <= 1 }
    /// Needed the outline or the slide-home hint, or missed half the pieces.
    public var isStuck: Bool { maxHintStep >= 3 || firstFitRate < 0.5 }
}

/// Number-line puzzle rungs (J12): concrete dots, then pictures (hops), then numerals; counting by 1, 2, 5, 10.
public struct NumberLineLevel: Codable, Equatable, Sendable {
    public enum Look: String, Codable, Sendable { case dots, hops, numerals }
    public let step: Int
    public let look: Look

    public init(step: Int, look: Look) {
        self.step = step
        self.look = look
    }

    public static let rungs: [NumberLineLevel] = [
        .init(step: 1, look: .dots), .init(step: 1, look: .hops), .init(step: 1, look: .numerals),
        .init(step: 2, look: .dots), .init(step: 2, look: .numerals),
        .init(step: 5, look: .hops), .init(step: 5, look: .numerals),
        .init(step: 10, look: .hops), .init(step: 10, look: .numerals),
    ]

    /// The ten values, in order: 1 to 10, 2 to 20, 5 to 50 or 10 to 100.
    public var values: [Int] { (1...10).map { $0 * step } }
}

/// What the jigsaw widget remembers.
public struct JigsawRecord: Codable, Equatable, Sendable {
    public var rung = 0
    /// False until the quick check (J10) has found her starting size.
    public var calibrated = false
    public var easyStreak = 0
    public var lineRung = 0
    public var lineCalibrated = false
    public var lineStreak = 0
    /// Picture id or "line", so the same puzzle never comes twice in a row (J9).
    public var lastPuzzle: String?
    public var results: [JigsawResult] = []
    public var introsHeard: Set<String> = []
    public var puzzlesDone = 0
    /// Grown-up limits on the size she is offered.
    public var minPieces = 10
    public var maxPieces = 50

    public init() {}

    enum CodingKeys: String, CodingKey {
        case rung, calibrated, easyStreak, lineRung, lineCalibrated, lineStreak, lastPuzzle, results, introsHeard,
             puzzlesDone, minPieces, maxPieces
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        rung = try c.decodeIfPresent(Int.self, forKey: .rung) ?? 0
        calibrated = try c.decodeIfPresent(Bool.self, forKey: .calibrated) ?? false
        easyStreak = try c.decodeIfPresent(Int.self, forKey: .easyStreak) ?? 0
        lineRung = try c.decodeIfPresent(Int.self, forKey: .lineRung) ?? 0
        lineCalibrated = try c.decodeIfPresent(Bool.self, forKey: .lineCalibrated) ?? false
        lineStreak = try c.decodeIfPresent(Int.self, forKey: .lineStreak) ?? 0
        lastPuzzle = try c.decodeIfPresent(String.self, forKey: .lastPuzzle)
        results = try c.decodeIfPresent([JigsawResult].self, forKey: .results) ?? []
        introsHeard = try c.decodeIfPresent(Set<String>.self, forKey: .introsHeard) ?? []
        puzzlesDone = try c.decodeIfPresent(Int.self, forKey: .puzzlesDone) ?? 0
        minPieces = try c.decodeIfPresent(Int.self, forKey: .minPieces) ?? 10
        maxPieces = try c.decodeIfPresent(Int.self, forKey: .maxPieces) ?? 50
    }

    public var level: JigsawLevel { JigsawLadder.rungs[min(max(0, rung), JigsawLadder.rungs.count - 1)] }
    public var lineLevel: NumberLineLevel {
        NumberLineLevel.rungs[min(max(0, lineRung), NumberLineLevel.rungs.count - 1)]
    }

    /// The level size kept inside the grown-up's range.
    public var levelSize: Int { min(max(level.pieces, minPieces), maxPieces) }

    /// Two or three sizes around her level for her to pick from. The quick check offers only its size (J10).
    public var offeredSizes: [Int] {
        let s = levelSize
        guard calibrated else { return [s] }
        return [s - 10, s, s + 10].filter { $0 >= minPieces && $0 <= maxPieces && JigsawLadder.sizes.contains($0) }
    }

    /// The level she plays at a chosen size: her rung's knobs with that piece count.
    public func level(pieces: Int) -> JigsawLevel {
        var l = level
        l.pieces = pieces
        return l
    }

    /// Sets the grown-up's range, keeping lowest at or below highest.
    public mutating func setRange(min lo: Int, max hi: Int) {
        minPieces = min(max(10, lo), 50)
        maxPieces = max(min(50, hi), minPieces)
    }

    /// A finished picture puzzle moves the level by at most one knob (J2), or by size during the quick check (J10).
    public mutating func finishPicture(_ r: JigsawResult) {
        record(r)
        if !calibrated {
            if r.isEasy && rung < JigsawLadder.rungs.count - 1 && level.pieces < maxPieces {
                rung = JigsawLadder.nextSizeRung(after: rung)
            } else {
                calibrated = true
            }
            return
        }
        if r.isStuck {
            rung = max(0, rung - 1)
            easyStreak = 0
        } else if r.isEasy {
            easyStreak += 1
            if easyStreak >= 4 {
                rung = min(JigsawLadder.rungs.count - 1, rung + 1)
                easyStreak = 0
            }
        } else {
            easyStreak = 0
        }
    }

    public mutating func finishNumberLine(_ r: JigsawResult) {
        record(r)
        if !lineCalibrated {
            if r.isEasy && lineRung < NumberLineLevel.rungs.count - 1 { lineRung += 1 } else { lineCalibrated = true }
            return
        }
        if r.isStuck {
            lineRung = max(0, lineRung - 1)
            lineStreak = 0
        } else if r.isEasy {
            lineStreak += 1
            if lineStreak >= 4 {
                lineRung = min(NumberLineLevel.rungs.count - 1, lineRung + 1)
                lineStreak = 0
            }
        } else {
            lineStreak = 0
        }
    }

    private mutating func record(_ r: JigsawResult) {
        results.append(r)
        if results.count > 60 { results.removeFirst(results.count - 60) }
        lastPuzzle = r.kind == "line" ? "line" : r.pictureID
        puzzlesDone += 1
    }

    /// J5: the companion slips on every third puzzle (the 2nd, 5th, 8th...).
    public var companionSlipDue: Bool { puzzlesDone % 3 == 1 }

    /// The next picture: never the one just played (J9), otherwise the least recently played.
    public func nextPicture(from ids: [String]) -> String? {
        let candidates = ids.filter { $0 != lastPuzzle }
        guard !candidates.isEmpty else { return ids.first }
        func lastPlayed(_ id: String) -> Int { results.lastIndex { $0.pictureID == id } ?? -1 }
        return candidates.min { lastPlayed($0) < lastPlayed($1) }
    }

    /// For the parent area: first-fit rate and hints over the last ten puzzles.
    public var recentFirstFitRate: Double? {
        let r = results.suffix(10)
        let pieces = r.reduce(0) { $0 + $1.pieces }
        return pieces == 0 ? nil : Double(r.reduce(0) { $0 + $1.firstFits }) / Double(pieces)
    }

    public var strategyCounts: [String: Int] {
        results.compactMap(\.strategy).reduce(into: [:]) { $0[$1, default: 0] += 1 }
    }

    /// J11: an idea to try away from the screen, changing with each puzzle.
    public static let homeIdeas = [
        "Cut the front of a cereal box into 6 pieces and put it back together. Ask how she started.",
        "Fold a square of paper into two triangles, then four. Can she make the square again?",
        "Do a real jigsaw together. Sort the flat-edged pieces first and talk about corners and edges.",
        "Draw a picture, cut it into 4 strips, mix them up and rebuild it.",
        "Write 1 to 10 on sticky notes, mix them up and line them up along the floor.",
    ]

    public var homeIdea: String { Self.homeIdeas[puzzlesDone % Self.homeIdeas.count] }
}

/// The hint ladder (J3): a strategy in words, then the area glows, then the outline, then the piece slides home.
public enum JigsawHint: Int, Sendable {
    case strategy = 1, area, outline, slideHome
}
