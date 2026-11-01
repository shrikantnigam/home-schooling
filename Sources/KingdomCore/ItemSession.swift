import Foundation

/// The three kinds of help, in order (spec section 5, AC-M2).
public enum HintStage: Int, Codable, Sendable {
    /// First wrong try: the model lights up (e.g. empty ten-frame cells glow).
    case modelHint = 1
    /// Second wrong try: count on together, pausing for her to tap.
    case workedStep = 2
    /// Third wrong try: show the answer with the model and explain. Item is marked needs practice.
    case showAnswer = 3
}

public enum Feedback: Equatable, Sendable {
    /// Right answer. `firstTry` is true only if no wrong try came before (AC-M1).
    case correct(firstTry: Bool)
    case hint(HintStage)
}

/// How one item ended, for the mastery engine.
public struct ItemResult: Codable, Equatable, Sendable {
    public let itemID: String
    public let skill: SkillID
    public let level: CPALevel
    /// Right on the first try with no hint. The only thing that counts toward mastery.
    public let firstTryCorrect: Bool
    /// True when the answer had to be shown (third wrong try).
    public let needsPractice: Bool
    public let date: Date

    public init(itemID: String, skill: SkillID, level: CPALevel, firstTryCorrect: Bool, needsPractice: Bool, date: Date) {
        self.itemID = itemID
        self.skill = skill
        self.level = level
        self.firstTryCorrect = firstTryCorrect
        self.needsPractice = needsPractice
        self.date = date
    }
}

/// Tracks tries on one item and decides the feedback.
public struct ItemSession: Equatable, Sendable {
    public let item: Item
    public let level: CPALevel
    public private(set) var wrongTries = 0
    /// Help asked for without a wrong answer (e.g. G5's "tap the flower box" support) also
    /// means the item no longer counts as first-try correct.
    public private(set) var usedHelp = false
    public private(set) var finished = false

    public init(item: Item, level: CPALevel) {
        self.item = item
        self.level = level
    }

    public mutating func noteHelpUsed() { usedHelp = true }

    /// Records an answer. After the third wrong try the item is finished and the answer is shown.
    @discardableResult
    public mutating func submit(_ answer: Int) -> Feedback {
        precondition(!finished, "item already finished")
        if answer == item.answer {
            finished = true
            return .correct(firstTry: wrongTries == 0 && !usedHelp)
        }
        wrongTries += 1
        let stage = HintStage(rawValue: min(wrongTries, 3)) ?? .showAnswer
        if stage == .showAnswer { finished = true }
        return .hint(stage)
    }

    /// The result to store once the item is finished.
    public func result(at date: Date) -> ItemResult {
        ItemResult(
            itemID: item.id,
            skill: item.skill,
            level: level,
            firstTryCorrect: finished && wrongTries == 0 && !usedHelp,
            needsPractice: wrongTries >= 3,
            date: date
        )
    }
}
