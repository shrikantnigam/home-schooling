import Foundation

/// Parent time settings (spec section 6, AC-P2, AC-P4).
public struct TimeSettings: Codable, Equatable, Sendable {
    public static let allowedLimits = Array(stride(from: 5, through: 30, by: 5))
    public static let defaultLimit = 20

    public private(set) var dailyLimitMinutes: Int = TimeSettings.defaultLimit
    /// Quiet hours as minutes after local midnight. Off when nil. May wrap past midnight.
    public var quietStart: Int?
    public var quietEnd: Int?

    public init() {}

    /// Clamps to 5...30 and snaps to 5-minute steps.
    public mutating func setDailyLimit(_ minutes: Int) {
        let snapped = Int((Double(minutes) / 5).rounded()) * 5
        dailyLimitMinutes = Swift.min(30, Swift.max(5, snapped))
    }

    public mutating func stepLimit(up: Bool) { setDailyLimit(dailyLimitMinutes + (up ? 5 : -5)) }

    public var quietHoursOn: Bool { quietStart != nil && quietEnd != nil }
}

/// Why play cannot start right now.
public enum PlayBlock: Equatable, Sendable {
    /// Daily limit used up. Lasts until local midnight (AC-P3).
    case sleeping
    /// Inside quiet hours (AC-P4).
    case quietHours
}

/// Counts minutes played per local day and decides when Sparkle goes to sleep.
public struct TimeKeeper: Codable, Equatable, Sendable {
    /// Seconds played, keyed by local day "yyyy-MM-dd".
    public private(set) var secondsByDay: [String: Int] = [:]
    /// Scenes completed, keyed by local day.
    public private(set) var scenesByDay: [String: Int] = [:]

    public init() {}

    public static func dayKey(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    public mutating func addPlay(seconds: Int, at date: Date, calendar: Calendar) {
        guard seconds > 0 else { return }
        secondsByDay[Self.dayKey(date, calendar: calendar), default: 0] += seconds
    }

    public mutating func noteSceneCompleted(at date: Date, calendar: Calendar) {
        scenesByDay[Self.dayKey(date, calendar: calendar), default: 0] += 1
    }

    public func secondsPlayed(on date: Date, calendar: Calendar) -> Int {
        secondsByDay[Self.dayKey(date, calendar: calendar)] ?? 0
    }

    public func minutesPlayed(on date: Date, calendar: Calendar) -> Int {
        secondsPlayed(on: date, calendar: calendar) / 60
    }

    public func limitReached(at date: Date, settings: TimeSettings, calendar: Calendar) -> Bool {
        secondsPlayed(on: date, calendar: calendar) >= settings.dailyLimitMinutes * 60
    }

    public static func inQuietHours(at date: Date, settings: TimeSettings, calendar: Calendar) -> Bool {
        guard let start = settings.quietStart, let end = settings.quietEnd, start != end else { return false }
        let c = calendar.dateComponents([.hour, .minute], from: date)
        let m = (c.hour ?? 0) * 60 + (c.minute ?? 0)
        return start < end ? (m >= start && m < end) : (m >= start || m < end)
    }

    /// Checked before a scene starts. Never used to stop a scene in the middle.
    public func block(at date: Date, settings: TimeSettings, calendar: Calendar) -> PlayBlock? {
        if limitReached(at: date, settings: settings, calendar: calendar) { return .sleeping }
        if Self.inQuietHours(at: date, settings: settings, calendar: calendar) { return .quietHours }
        return nil
    }

    /// Minutes per day for the 7 days ending on `date`, oldest first (AC-P5).
    public func lastSevenDays(endingOn date: Date, calendar: Calendar) -> [(day: Date, minutes: Int, scenes: Int)] {
        let today = calendar.startOfDay(for: date)
        return (0..<7).reversed().compactMap { back in
            guard let d = calendar.date(byAdding: .day, value: -back, to: today) else { return nil }
            let key = Self.dayKey(d, calendar: calendar)
            return (d, (secondsByDay[key] ?? 0) / 60, scenesByDay[key] ?? 0)
        }
    }
}
