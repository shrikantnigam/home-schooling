import SwiftUI

/// Paper theatre (charter v1.2, board 1, chosen by Shrikant 2026-11-01): layered cut paper, warm muted
/// colours (cream, terracotta, sage, ochre), soft shadows between layers and a paper grain.
enum Theme {
    // Paper palette
    static let cream = Color(hex: 0xF3E6CF)
    static let card = Color(hex: 0xFBF4E8)
    static let tan = Color(hex: 0xE7D3B0)
    static let clay = Color(hex: 0x7A3B22)
    static let clayDark = Color(hex: 0x5A2C18)
    static let sun = Color(hex: 0xF2B25C)
    static let sagePale = Color(hex: 0xC9D6B3)
    static let sage = Color(hex: 0x8FAE86)
    static let sageDeep = Color(hex: 0x5D8A6A)
    static let rose = Color(hex: 0xC9476A)
    static let poppy = Color(hex: 0xD9603B)
    static let ochre = Color(hex: 0xE08A2E)
    static let wood = Color(hex: 0xA8693F)
    static let woodDark = Color(hex: 0x7A4A2C)
    static let nightPaper = Color(hex: 0x2E3352)
    static let nightPaperLow = Color(hex: 0x434A6E)
    static let river = Color(hex: 0x8FB3B0)
    /// The shadow between paper layers.
    static let shadow = Color(hex: 0x5A3A22)

    // Older names, mapped onto the paper palette so every screen follows it.
    static let night = nightPaper
    static let ink = Color(hex: 0x3B2A20)
    static let lavender = clay
    static let deepLavender = clayDark
    static let lilac = tan
    static let paper = card
    static let mane = rose
    static let gold = sun
    static let garden = sageDeep
    static let soil = wood
    static let soilDark = woodDark
    static let daySky = cream
    static let water = river
    static let muted = Color(hex: 0x6B5442)

    /// Numerals stay in the open rounded face, which a 6-year-old reads most easily.
    static func numeral(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    /// Titles in a storybook serif, like the board's Fraunces.
    static func title(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .serif) }
    /// Grown-up screens.
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
