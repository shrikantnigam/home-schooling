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

#if canImport(CryptoKit)
import CryptoKit
#endif

/// The grown-ups' PIN (Shrikant, 2026-11-03): four digits set at first-launch setup, changed in the parent area.
/// Only a salted SHA-256 of it is saved, never the digits. A forgotten PIN falls back to the two-finger hold and
/// the year (ParentGate), which then lets a grown-up set a new one.
public struct ParentPin: Codable, Equatable, Sendable {
    public static let length = 4
    public let salt: String
    public let hash: String

    public static func isValid(_ pin: String) -> Bool {
        pin.count == length && pin.allSatisfy { $0.isASCII && $0.isNumber }
    }

    public init?(pin: String, salt: String = UUID().uuidString) {
        guard Self.isValid(pin) else { return nil }
        self.salt = salt
        self.hash = Self.digest(pin, salt: salt)
    }

    public func matches(_ pin: String) -> Bool { Self.isValid(pin) && Self.digest(pin, salt: salt) == hash }

    static func digest(_ pin: String, salt: String) -> String {
        let data = Data((salt + ":" + pin).utf8)
        #if canImport(CryptoKit)
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        #else
        // Only the Linux cloud check builds without CryptoKit; the app and the Mac tests always have it.
        return data.base64EncodedString()
        #endif
    }
}

/// Typing the PIN on the gate's number pad. Five wrong PINs in a row lock the pad for a minute, so a child
/// can't find it by trying every number.
public struct PinGate: Equatable, Sendable {
    public enum Outcome: Equatable, Sendable { case typing, open, wrong, locked }

    public static let maxTries = 5
    public static let lockSeconds: TimeInterval = 60

    public private(set) var entered = ""
    public private(set) var wrongTries = 0
    public private(set) var lockedUntil: Date?

    public init() {}

    public func isLocked(at now: Date) -> Bool { lockedUntil.map { now < $0 } ?? false }

    /// One digit. At four digits it checks the PIN and clears the dots.
    public mutating func type(_ digit: Character, pin: ParentPin, now: Date) -> Outcome {
        if isLocked(at: now) { return .locked }
        if lockedUntil != nil { lockedUntil = nil; wrongTries = 0 }
        guard digit.isASCII, digit.isNumber, entered.count < ParentPin.length else { return .typing }
        entered.append(digit)
        guard entered.count == ParentPin.length else { return .typing }
        let ok = pin.matches(entered)
        entered = ""
        if ok { wrongTries = 0; return .open }
        wrongTries += 1
        if wrongTries >= Self.maxTries {
            lockedUntil = now.addingTimeInterval(Self.lockSeconds)
            return .locked
        }
        return .wrong
    }

    public mutating func deleteLast() { if !entered.isEmpty { entered.removeLast() } }
}
