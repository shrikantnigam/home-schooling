import SwiftUI

/// Colours and type from the style frame mock (mocks/Style.dc.html).
enum Theme {
    static let night = Color(hex: 0x24224F)
    static let ink = Color(hex: 0x2E2650)
    static let lavender = Color(hex: 0x8C6FE0)
    static let deepLavender = Color(hex: 0x5B3FC4)
    static let lilac = Color(hex: 0xE4DDF7)
    static let paper = Color(hex: 0xF4F0FF)
    static let mane = Color(hex: 0xF48FB8)
    static let gold = Color(hex: 0xFFC940)
    static let garden = Color(hex: 0x4FA86A)
    static let soil = Color(hex: 0x8A5A3C)
    static let soilDark = Color(hex: 0x6B4229)
    static let daySky = Color(hex: 0xBFE6F7)
    static let water = Color(hex: 0x9CC9DD)
    static let muted = Color(hex: 0x5A5378)

    /// Numerals and titles. The mocks use Fredoka; until the font file is bundled we use the
    /// system rounded face, which has the same open, child-friendly shapes.
    static func numeral(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func title(_ size: CGFloat) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    /// Grown-up screens (Nunito in the mocks).
    static func body(_ size: CGFloat = 17) -> Font { .system(size: size, weight: .regular, design: .default) }

    /// AC-A5: every child touch target is at least 60 pt.
    static let minTarget: CGFloat = 60
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Gentle "try again" wobble. Never red, no buzzer.
struct Wobble: GeometryEffect {
    var amount: CGFloat = 10
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(animatableData * .pi * 4), y: 0))
    }
}

/// A soft pulsing glow for "tap here next".
struct GlowPulse: ViewModifier {
    var color: Color = Theme.gold
    var on: Bool = true
    @State private var phase = false
    func body(content: Content) -> some View {
        content
            .shadow(color: on ? color.opacity(phase ? 0.95 : 0.35) : .clear, radius: phase ? 22 : 8)
            .scaleEffect(on && phase ? 1.04 : 1)
            .onAppear {
                guard on, !AppEnvironment.current.uiTesting else { return }
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { phase = true }
            }
    }
}

extension View {
    func glow(_ on: Bool = true, color: Color = Theme.gold) -> some View { modifier(GlowPulse(color: color, on: on)) }
}
