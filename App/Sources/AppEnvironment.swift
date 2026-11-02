import Foundation

/// Launch options. The QA play-through (UI tests) passes these; normal launches use none.
struct AppEnvironment {
    /// Speech finishes instantly, subtitles show what would be spoken, animations are short.
    let uiTesting: Bool
    /// Start from a fresh install.
    let reset: Bool
    /// A named starting state for QA, e.g. "prologueDone", "limitReached", "midScene".
    let preset: String?
    /// Overrides "now" for QA so day-based rules can be exercised.
    let dayOffset: Int
    /// QA runs skip the first-launch setup with its defaults, unless this is passed to test the setup itself.
    let showSetup: Bool
    /// QA: the voice never reports finishing (as on her iPad, 2026-11-02), so the watchdog must move every screen on.
    let speechNeverFinishes: Bool

    static let current: AppEnvironment = {
        let args = ProcessInfo.processInfo.arguments
        func value(after flag: String) -> String? {
            guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
            return args[i + 1]
        }
        return AppEnvironment(
            uiTesting: args.contains("-uiTesting"),
            reset: args.contains("-reset"),
            preset: value(after: "-preset"),
            dayOffset: Int(value(after: "-dayOffset") ?? "") ?? 0,
            showSetup: args.contains("-showSetup"),
            speechNeverFinishes: args.contains("-speechNeverFinishes")
        )
    }()
}
