import Foundation

// Digital puzzle scrolls (F2, F4 in docs/features/problem-solving.md). Answered on the iPad with the pen or by
// tapping; the app checks the answers.

public enum SheetItemKind: String, Codable, Sendable {
    /// A picture first, then the sentence with a box.
    case picture
    /// A plain number sentence with a box for the answer.
    case sentence
    /// A number inside the sentence is missing (3 + ? = 7).
    case missing
    /// The answer comes first (? = 6 + 4), L16.
    case answerFirst
    /// The sign is missing (6 ○ 2 = 8), L14.
    case missingSign
    /// How many? (the Night Sky's scroll).
    case count
    /// She draws the puzzle on a paper canvas. Not checked.
    case drawIt
    /// She makes a puzzle for the companion (L15). Not checked.
    case makePuzzle
}

/// What a picture-first item shows above the sentence.
public enum SheetPicture: Equatable, Sendable {
    case none
    case dots(Int)
    case join(Int, Int)
    case takeAway(Int, Int)
    case groups(Int, Int)
    case share(Int, Int)
    case parts(Int)
}

public struct SheetItem: Equatable, Identifiable, Sendable {
    public let id: String
    public let kind: SheetItemKind
    /// The sentence as shown, with "?" for the box (or "○" for a missing sign).
    public let tokens: [String]
    /// What goes in the box: a number, or a sign for `missingSign`.
    public let answer: String
    public let picture: SheetPicture
    public let op: MathOp?

    public init(id: String, kind: SheetItemKind, tokens: [String], answer: String, picture: SheetPicture = .none,
                op: MathOp? = nil) {
        self.id = id
        self.kind = kind
        self.tokens = tokens
        self.answer = answer
        self.picture = picture
        self.op = op
    }

    public var isChecked: Bool { kind != .drawIt && kind != .makePuzzle }

    /// The line the companion says for this item.
    public var promptLine: LineID {
        switch kind {
        case .picture: return "sheet.item.picture"
        case .sentence: return "sheet.item.sentence"
        case .missing: return "sheet.item.missing"
        case .answerFirst: return "sheet.item.answerFirst"
        case .missingSign: return "sheet.item.missingSign"
        case .count: return "sheet.item.count"
        case .drawIt: return "sheet.drawIt"
        case .makePuzzle: return "sheet.make"
        }
    }

    /// True when what she wrote or tapped is the answer.
    public func check(_ given: String) -> Bool {
        let g = given.trimmingCharacters(in: .whitespacesAndNewlines)
        if kind == .missingSign { return MathOp.from(sign: g)?.sign == answer }
        guard let n = Int(g), let a = Int(answer) else { return false }
        return n == a
    }
}

public struct Worksheet: Equatable, Identifiable, Sendable {
    public let id: String
    /// The place it belongs to, or nil for a mixed scroll.
    public let place: ChapterID?
    public let items: [SheetItem]

    public var checkedCount: Int { items.filter(\.isChecked).count }
}

/// How a grown-up felt the scroll went (AC-S5). It feeds the warm-up picker, not a score.
public enum SheetFeedback: String, Codable, CaseIterable, Sendable {
    case easy, ok, hard

    public var parentLabel: String {
        switch self {
        case .easy: return "Easy"
        case .ok: return "OK"
        case .hard: return "Hard"
        }
    }
}

public struct SheetRecord: Codable, Equatable, Sendable {
    public var finished: Date?
    public var firstTry = 0
    public var checked = 0
    public var feedback: SheetFeedback?

    public init(finished: Date? = nil, firstTry: Int = 0, checked: Int = 0, feedback: SheetFeedback? = nil) {
        self.finished = finished
        self.firstTry = firstTry
        self.checked = checked
        self.feedback = feedback
    }
}

/// Builds the place scrolls and the mixed scrolls.
public struct WorksheetMaker: Sendable {
    public let content: Content
    public let progression: Progression

    public init(content: Content, progression: Progression) {
        self.content = content
        self.progression = progression
    }

    static func sentence(_ a: Int, _ op: MathOp, _ b: Int) -> [String] { [String(a), op.sign, String(b), "="] }

    public static func picture(_ op: MathOp, _ a: Int, _ b: Int) -> SheetPicture {
        switch op {
        case .add: return .join(a, b)
        case .subtract: return .takeAway(a, b)
        case .multiply: return .groups(a, b)
        case .divide: return .share(a, b)
        }
    }

    /// Six checked items for one operation: two picture-first, two sentences, a missing number, answer-first.
    static func operationItems(_ op: MathOp, prefix: String, seed: Int, top: Int) -> [SheetItem] {
        var out: [SheetItem] = []
        var used = Set<String>()
        var n = seed
        func next() -> (Int, Int) {
            while true {
                let p = ProblemMaker.numbers(op, n: n, top: top)
                n += 1
                if used.insert("\(p.0),\(p.1)").inserted || n > seed + 60 { return p }
            }
        }
        for i in 0..<2 {
            let (a, b) = next()
            out.append(SheetItem(id: "\(prefix)-pic\(i)", kind: .picture, tokens: sentence(a, op, b) + ["?"],
                                 answer: String(op.apply(a, b) ?? 0), picture: picture(op, a, b), op: op))
        }
        for i in 0..<2 {
            let (a, b) = next()
            out.append(SheetItem(id: "\(prefix)-sen\(i)", kind: .sentence, tokens: sentence(a, op, b) + ["?"],
                                 answer: String(op.apply(a, b) ?? 0), op: op))
        }
        let (a, b) = next()
        out.append(SheetItem(id: "\(prefix)-mis", kind: .missing,
                             tokens: [String(a), op.sign, "?", "=", String(op.apply(a, b) ?? 0)], answer: String(b), op: op))
        let (c, d) = next()
        out.append(SheetItem(id: "\(prefix)-first", kind: .answerFirst,
                             tokens: ["?", "=", String(c), op.sign, String(d)], answer: String(op.apply(c, d) ?? 0), op: op))
        return out
    }

    static func missingSign(_ op: MathOp, id: String, seed: Int, top: Int) -> SheetItem {
        let p = ProblemMaker.puzzle(op, level: 3, n: seed, top: top)
        return SheetItem(id: id, kind: .missingSign, tokens: [String(p.a), "○", String(p.b), "=", String(p.answer)],
                         answer: op.sign, op: op)
    }

    static func extras(prefix: String, drawTokens: [String], make: Bool) -> [SheetItem] {
        var out = [SheetItem(id: "\(prefix)-draw", kind: .drawIt, tokens: drawTokens, answer: "")]
        if make { out.append(SheetItem(id: "\(prefix)-make", kind: .makePuzzle, tokens: [], answer: "")) }
        return out
    }

    /// The scroll for a finished place. Nil for a place that has no scroll.
    public func placeSheet(_ place: ChapterID, state: LearnerState) -> Worksheet? {
        let canMake = !ProblemMaker(progression: progression).unlocked(state).isEmpty
        let id = "sheet.\(place)"
        switch place {
        case "prologue":
            let items: [SheetItem] = [
                SheetItem(id: "\(id)-c6", kind: .count, tokens: ["?"], answer: "6", picture: .dots(6)),
                SheetItem(id: "\(id)-c9", kind: .count, tokens: ["?"], answer: "9", picture: .dots(9)),
                SheetItem(id: "\(id)-c4", kind: .count, tokens: ["?"], answer: "4", picture: .dots(4)),
                SheetItem(id: "\(id)-n7", kind: .missing, tokens: ["5", ",", "6", ",", "?"], answer: "7"),
                SheetItem(id: "\(id)-n3", kind: .missing, tokens: ["?", ",", "4", ",", "5"], answer: "3"),
                SheetItem(id: "\(id)-eq", kind: .answerFirst, tokens: ["?", "=", "8"], answer: "8", picture: .dots(8)),
            ]
            return Worksheet(id: id, place: place, items: items + Self.extras(prefix: id, drawTokens: ["5", "★"], make: canMake))
        case "moon":
            let items: [SheetItem] = [
                SheetItem(id: "\(id)-p4", kind: .picture, tokens: ["?", "parts"], answer: "4", picture: .parts(4)),
                SheetItem(id: "\(id)-h8", kind: .sentence, tokens: ["½", "of", "8", "=", "?"], answer: "4", picture: .share(8, 2)),
                SheetItem(id: "\(id)-q8", kind: .sentence, tokens: ["¼", "of", "8", "=", "?"], answer: "2"),
                SheetItem(id: "\(id)-h6", kind: .sentence, tokens: ["½", "of", "6", "=", "?"], answer: "3"),
                SheetItem(id: "\(id)-m10", kind: .missing, tokens: ["½", "of", "?", "=", "5"], answer: "10"),
                SheetItem(id: "\(id)-f4", kind: .answerFirst, tokens: ["?", "=", "½", "of", "4"], answer: "2"),
            ]
            return Worksheet(id: id, place: place, items: items + Self.extras(prefix: id, drawTokens: ["½", "of", "6"], make: canMake))
        default:
            guard let op = MathOp.allCases.first(where: { $0.place == place }) ?? (place == "bridge" ? .add : nil) else {
                return nil
            }
            let top = place == "bridge" || place == "goblin" ? 20 : 10
            let seed = place == "bridge" ? 500 : 100 * (MathOp.allCases.firstIndex(of: op) ?? 0) + 10
            let items = Self.operationItems(op, prefix: id, seed: seed, top: top)
            let (a, b) = ProblemMaker.numbers(op, n: seed + 99, top: min(top, 10))
            let draw = Self.sentence(a, op, b) + [String(op.apply(a, b) ?? 0)]
            return Worksheet(id: id, place: place, items: items + Self.extras(prefix: id, drawTokens: draw, make: canMake))
        }
    }

    /// A mixed scroll (F4): mostly her weakest operation, one missing sign, and a puzzle to make.
    public func mixedSheet(number: Int, state: LearnerState) -> Worksheet? {
        let maker = ProblemMaker(progression: progression)
        let ops = maker.unlocked(state)
        guard ops.count >= 2 else { return nil }
        let top = maker.top(state)
        let ranked = ops.sorted { state.board.weakness($0) > state.board.weakness($1) }
        let id = "sheet.mixed.\(number)"
        let weak = Self.operationItems(ranked[0], prefix: "\(id)-w", seed: 1000 + number * 37, top: top)
        let other = Self.operationItems(ranked[1], prefix: "\(id)-o", seed: 2000 + number * 41, top: top)
        let third = ranked.count > 2 ? ranked[2] : ranked[1]
        var items = [weak[2], other[0], weak[4], other[3], weak[5]]
        items.append(Self.missingSign(third, id: "\(id)-sign", seed: 3000 + number, top: top))
        return Worksheet(id: id, place: nil, items: items + Self.extras(prefix: id, drawTokens: [], make: true).filter { $0.kind == .makePuzzle })
    }

    /// Scrolls she can open now: one per finished place, then the current mixed scroll.
    public func available(state: LearnerState) -> [Worksheet] {
        var out = WriteItDown.places
            .filter { progression.allScenesDone($0, state: state) }
            .compactMap { placeSheet($0, state: state) }
        let mixedDone = state.sheets.keys.filter { $0.hasPrefix("sheet.mixed.") && state.sheets[$0]?.finished != nil }.count
        if let m = mixedSheet(number: mixedDone + 1, state: state) { out.append(m) }
        return out
    }
}

extension LearnerState {
    /// A finished scroll: her first-try count, and mistakes by operation for the board's weak spots (F4).
    public mutating func finishSheet(_ sheet: Worksheet, firstTry: [String: Bool], at date: Date) {
        var rec = sheets[sheet.id] ?? SheetRecord()
        rec.finished = date
        rec.checked = sheet.checkedCount
        rec.firstTry = sheet.items.filter { $0.isChecked && firstTry[$0.id] == true }.count
        sheets[sheet.id] = rec
        for item in sheet.items where item.isChecked && firstTry[item.id] == false {
            if let op = item.op { board.sheetMistakes[op.rawValue, default: 0] += 1 }
        }
    }

    /// AC-S5: a grown-up's easy, OK or hard. "Hard" puts the place's least recently seen items on the practice
    /// list, so warm-ups bring them back. "Easy" takes the place's items off it.
    public mutating func applySheetFeedback(_ feedback: SheetFeedback, sheetID: String, place: ChapterID, content: Content) {
        var rec = sheets[sheetID] ?? SheetRecord()
        rec.feedback = feedback
        sheets[sheetID] = rec
        let items = content.items(in: place)
        switch feedback {
        case .hard:
            let oldest = items.sorted { (lastSeen[$0.id] ?? .distantPast) < (lastSeen[$1.id] ?? .distantPast) }.prefix(4)
            needsPractice.formUnion(oldest.map(\.id))
        case .easy:
            needsPractice.subtract(items.map(\.id))
        case .ok:
            break
        }
    }
}
