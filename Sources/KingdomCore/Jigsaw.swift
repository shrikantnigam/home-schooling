import Foundation

// Jigsaw widget (issue #25, rules J1 to J14: docs/features/jigsaw.md).
// Picture puzzles build spatial reasoning, part and whole, and strategy. The number-line puzzle (J12) was removed on
// 2026-11-02 at Shrikant's request; old saves may still hold its results, which are ignored.

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

    /// A plan with its own number of columns and rows.
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

/// What the jigsaw widget remembers.
public struct JigsawRecord: Codable, Equatable, Sendable {
    public var rung = 0
    /// False until the quick check (J10) has found her starting size.
    public var calibrated = false
    public var easyStreak = 0
    /// The last picture played.
    public var lastPuzzle: String?
    /// Pictures she has finished at least once, with the most pieces she has done each in (J14).
    public var completed: [String: Int] = [:]
    public var results: [JigsawResult] = []
    public var introsHeard: Set<String> = []
    public var puzzlesDone = 0
    /// Grown-up limits from before J15 (the picker is now fixed at 10, 20, 30). Kept so old saves round-trip.
    public var minPieces = 10
    public var maxPieces = 50

    public init() {}

    enum CodingKeys: String, CodingKey {
        case rung, calibrated, easyStreak, lastPuzzle, results, introsHeard, puzzlesDone, minPieces, maxPieces,
             completed
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        rung = try c.decodeIfPresent(Int.self, forKey: .rung) ?? 0
        calibrated = try c.decodeIfPresent(Bool.self, forKey: .calibrated) ?? false
        easyStreak = try c.decodeIfPresent(Int.self, forKey: .easyStreak) ?? 0
        lastPuzzle = try c.decodeIfPresent(String.self, forKey: .lastPuzzle)
        results = try c.decodeIfPresent([JigsawResult].self, forKey: .results) ?? []
        introsHeard = try c.decodeIfPresent(Set<String>.self, forKey: .introsHeard) ?? []
        puzzlesDone = try c.decodeIfPresent(Int.self, forKey: .puzzlesDone) ?? 0
        minPieces = try c.decodeIfPresent(Int.self, forKey: .minPieces) ?? 10
        maxPieces = try c.decodeIfPresent(Int.self, forKey: .maxPieces) ?? 50
        // Saves from before J14 have no ticks yet: rebuild them from the puzzles in her history.
        completed = try c.decodeIfPresent([String: Int].self, forKey: .completed) ?? Self.completed(from: results)
    }

    static func completed(from results: [JigsawResult]) -> [String: Int] {
        results.reduce(into: [:]) { done, r in
            guard r.kind == "picture", let id = r.pictureID else { return }
            done[id] = max(done[id] ?? 0, r.pieces)
        }
    }

    /// True once she has finished this picture at any size (J14).
    public func isCompleted(_ picture: String) -> Bool { completed[picture] != nil }

    public var level: JigsawLevel { JigsawLadder.rungs[min(max(0, rung), JigsawLadder.rungs.count - 1)] }

    /// The sizes on the picker (Shrikant, 2026-11-02, J15): always 10, 20 and 30, so she sees what's coming.
    public static let pickerSizes = [10, 20, 30]

    /// 10 is always open. 20 and 30 open once she has finished a puzzle (her first one is always a 10, so this
    /// means "after a 10"; saves that already finished a bigger one keep them open).
    public func isOpen(_ size: Int) -> Bool { size <= 10 || !completed.isEmpty }

    /// Her level's size on the picker, for the sun ring: never above 30, and never a locked size.
    public var levelSize: Int {
        let s = min(max(level.pieces, 10), Self.pickerSizes.last ?? 30)
        return isOpen(s) ? s : 10
    }

    /// The level she plays at a chosen size: her rung's knobs with that piece count.
    public func level(pieces: Int) -> JigsawLevel {
        var l = level
        l.pieces = pieces
        return l
    }

    /// A finished picture puzzle moves the level by at most one knob (J2), or by size during the quick check (J10).
    public mutating func finishPicture(_ r: JigsawResult) {
        record(r)
        if let id = r.pictureID { completed[id] = max(completed[id] ?? 0, r.pieces) }
        if !calibrated {
            if r.isEasy && rung < JigsawLadder.rungs.count - 1 && level.pieces < (Self.pickerSizes.last ?? 30) {
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

    private mutating func record(_ r: JigsawResult) {
        results.append(r)
        if results.count > 60 { results.removeFirst(results.count - 60) }
        lastPuzzle = r.pictureID
        puzzlesDone += 1
    }

    /// J5: the companion slips on every third puzzle (the 2nd, 5th, 8th...).
    public var companionSlipDue: Bool { puzzlesDone % 3 == 1 }

    /// The picture the map suggests with a sun ring (J13): never the one just played, otherwise the least recently
    /// played. She can still pick any picture.
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
        "Tear a magazine page into 8 pieces and swap with her: you each rebuild the other's page.",
    ]

    public var homeIdea: String { Self.homeIdeas[puzzlesDone % Self.homeIdeas.count] }
}

/// The hint ladder (J3): a strategy in words, then the area glows, then the outline, then the piece slides home.
public enum JigsawHint: Int, Sendable {
    case strategy = 1, area, outline, slideHome
}
