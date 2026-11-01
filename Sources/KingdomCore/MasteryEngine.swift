import Foundation

public enum SkillStatus: String, Codable, Sendable {
    case notStarted
    case practicing
    case mastered

    public var parentLabel: String {
        switch self {
        case .notStarted: return "Not started"
        case .practicing: return "Practicing"
        case .mastered: return "Mastered"
        }
    }
}

/// Per-skill learning state. Pure value type, no UI.
public struct SkillRecord: Codable, Equatable, Sendable {
    public var level: CPALevel = .concrete
    /// Every finished item for this skill, oldest first.
    public var history: [ItemResult] = []
    /// First tries at the current level since the last level change, oldest first.
    public var currentLevelTries: [Bool] = []
    public var masteredOverride = false

    public init() {}
}

/// Mastery rules from spec section 5 (AC-M1 to AC-M5).
public struct MasteryRules: Sendable {
    public var upWindow = 5
    public var upNeeded = 4
    public var downAfterMisses = 3
    public var masteryWindow = 10
    public var masteryRatio = 0.8
    public var masteryDays = 2

    public init() {}
}

public struct MasteryEngine: Sendable {
    public let rules: MasteryRules
    public let calendar: Calendar

    public init(rules: MasteryRules = MasteryRules(), calendar: Calendar = .current) {
        self.rules = rules
        self.calendar = calendar
    }

    /// Adds a result and moves the CPA level up or down for the next item.
    public func record(_ result: ItemResult, into record: inout SkillRecord) {
        record.history.append(result)
        // Results at a different level than the current one (e.g. a warm-up shown at an older
        // level) still count for history but do not drive level changes.
        guard result.level == record.level else { return }
        record.currentLevelTries.append(result.firstTryCorrect)

        let lastN = record.currentLevelTries.suffix(rules.upWindow)
        if record.level < .abstract, lastN.filter({ $0 }).count >= rules.upNeeded {
            record.level = record.level.up
            record.currentLevelTries = []
            return
        }
        let tail = record.currentLevelTries.suffix(rules.downAfterMisses)
        if record.level > .concrete, tail.count == rules.downAfterMisses, tail.allSatisfy({ !$0 }) {
            record.level = record.level.down
            record.currentLevelTries = []
        }
    }

    /// AC-M5: at least 80% first-try correct over the last 10 Abstract items, across 2+ calendar days.
    public func isMastered(_ record: SkillRecord) -> Bool {
        if record.masteredOverride { return true }
        let abstractResults = record.history.filter { $0.level == .abstract }
        guard abstractResults.count >= rules.masteryWindow else { return false }
        let window = abstractResults.suffix(rules.masteryWindow)
        let correct = window.filter(\.firstTryCorrect).count
        guard Double(correct) / Double(window.count) >= rules.masteryRatio else { return false }
        let days = Set(window.map { calendar.startOfDay(for: $0.date) })
        return days.count >= rules.masteryDays
    }

    /// Ready to move on: at the Abstract level, at least 4 of the last 5 Abstract items right on the
    /// first try. Lighter than mastery, used for the chapter gate. No calendar-day rule here: charter L12
    /// says spacing is for review, not for gating, so a quick learner never waits a day to move on.
    public func isSecure(_ record: SkillRecord) -> Bool {
        if isMastered(record) { return true }
        guard record.level == .abstract else { return false }
        let window = record.history.filter { $0.level == .abstract }.suffix(rules.upWindow)
        return window.count == rules.upWindow && window.filter(\.firstTryCorrect).count >= rules.upNeeded
    }

    public func status(_ record: SkillRecord?) -> SkillStatus {
        guard let record else { return .notStarted }
        if isMastered(record) { return .mastered }
        return record.history.isEmpty ? .notStarted : .practicing
    }
}
