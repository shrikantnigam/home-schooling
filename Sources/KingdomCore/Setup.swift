import Foundation

/// Who walks through the kingdom with her (charter v1.3). Chosen once at setup.
public enum Companion: String, Codable, CaseIterable, Sendable {
    case unicorn, superhero, princess, monster, gnome

    /// The companion's name in the story.
    public var name: String {
        switch self {
        case .unicorn: return "Sparkle"
        case .superhero: return "Nova"
        case .princess: return "Lumi"
        case .monster: return "Bloop"
        case .gnome: return "Pip"
        }
    }

    /// What it is, for the setup cards and the parent area.
    public var kind: String {
        switch self {
        case .unicorn: return "unicorn"
        case .superhero: return "superhero"
        case .princess: return "princess"
        case .monster: return "cute monster"
        case .gnome: return "gnome"
        }
    }

    /// Voice pitch on the device voice, so each companion sounds like itself.
    public var voicePitch: Float {
        switch self {
        case .unicorn: return 1.3
        case .superhero: return 1.08
        case .princess: return 1.22
        case .monster: return 0.88
        case .gnome: return 0.98
        }
    }
}

/// The three choices made once at first launch: locked afterwards (charter v1.3).
public struct SetupChoices: Codable, Equatable, Sendable {
    public let heroName: String
    public let companion: Companion
    public let dailyLimitMinutes: Int

    public static let defaultName = "Siara"
    public static let maxNameLength = 20

    public init(heroName: String, companion: Companion, dailyLimitMinutes: Int) {
        self.heroName = SetupChoices.cleanName(heroName)
        self.companion = companion
        var t = TimeSettings()
        t.setDailyLimit(dailyLimitMinutes)
        self.dailyLimitMinutes = t.dailyLimitMinutes
    }

    /// Letters, spaces, hyphens and apostrophes only, trimmed and capped. Empty becomes "Siara".
    public static func cleanName(_ raw: String) -> String {
        let allowed = raw.filter { $0.isLetter || $0 == " " || $0 == "-" || $0 == "'" }
        let trimmed = allowed.trimmingCharacters(in: .whitespaces)
        let capped = String(trimmed.prefix(maxNameLength)).trimmingCharacters(in: .whitespaces)
        return capped.isEmpty ? defaultName : capped
    }
}
