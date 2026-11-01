import Foundation

/// Two steps a pre-reader can't do (spec section 6, AC-P1):
/// hold two fingers for 3 seconds, then type the current year.
public struct ParentGate: Equatable, Sendable {
    public enum Step: Equatable, Sendable {
        case hold
        case typeYear
        case open
    }

    public static let holdSeconds: Double = 3
    public static let requiredFingers = 2

    public private(set) var step: Step = .hold
    public private(set) var wrongYearTries = 0

    public init() {}

    /// Called when a hold gesture ends. Moves on only for 2+ fingers held 3+ seconds.
    public mutating func holdEnded(fingers: Int, seconds: Double) {
        guard step == .hold else { return }
        if fingers >= Self.requiredFingers && seconds >= Self.holdSeconds { step = .typeYear }
    }

    /// Accepts the year typed by the parent. Wrong answers reset to the hold step after 3 tries.
    @discardableResult
    public mutating func submitYear(_ text: String, now: Date, calendar: Calendar) -> Bool {
        guard step == .typeYear else { return false }
        let year = calendar.component(.year, from: now)
        if text.trimmingCharacters(in: .whitespaces) == String(year) {
            step = .open
            return true
        }
        wrongYearTries += 1
        if wrongYearTries >= 3 {
            wrongYearTries = 0
            step = .hold
        }
        return false
    }

    public mutating func cancel() { self = ParentGate() }
}
