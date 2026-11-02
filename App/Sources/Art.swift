import KingdomCore
import SwiftUI

// Placeholder art drawn with SwiftUI shapes, following mocks/Sparkle, Siara and Style.
// Final illustrations can replace these views one by one without touching the activities.

struct StarShape: Shape {
    var points = 5
    var inner: CGFloat = 0.45
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        var p = Path()
        for i in 0..<(points * 2) {
            let a = Double(i) * .pi / Double(points) - .pi / 2
            let rr = i.isMultiple(of: 2) ? r : r * inner
            let pt = CGPoint(x: c.x + CGFloat(cos(a)) * rr, y: c.y + CGFloat(sin(a)) * rr)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.midX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
            p.closeSubpath()
        }
    }
}

/// A star counter. Asleep (grey-blue) until counted, then gold with a face.
struct StarSprite: View {
    var lit: Bool
    var highlighted = false
    var size: CGFloat = 76
    var body: some View {
        ZStack {
            StarShape()
                .fill(lit ? Theme.gold : Color(hex: 0x6E6A9E))
                .overlay(StarShape().stroke(Color.white.opacity(lit ? 0.9 : 0.3), lineWidth: 3))
                .shadow(color: lit ? Theme.gold.opacity(0.8) : .clear, radius: 14)
            HStack(spacing: size * 0.14) {
                eye
                eye
            }
            .offset(y: size * 0.02)
        }
        .frame(width: size, height: size)
        .scaleEffect(highlighted ? 1.2 : 1)
        .animation(.spring(response: 0.3), value: highlighted)
    }

    private var eye: some View {
        Group {
            if lit {
                Circle().fill(Theme.ink).frame(width: size * 0.08, height: size * 0.08)
            } else {
                Capsule().fill(Theme.ink.opacity(0.6)).frame(width: size * 0.1, height: size * 0.03)
            }
        }
    }
}

struct FlowerSprite: View {
    var bloom = true
    var color: Color = Theme.mane
    var size: CGFloat = 46
    var body: some View {
        ZStack {
            if bloom {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(color)
                        .frame(width: size * 0.46, height: size * 0.46)
                        .offset(y: -size * 0.26)
                        .rotationEffect(.degrees(Double(i) * 72))
                }
                Circle().fill(Theme.gold).frame(width: size * 0.36, height: size * 0.36)
            } else {
                Capsule().fill(Theme.garden).frame(width: size * 0.3, height: size * 0.5)
            }
        }
        .frame(width: size, height: size)
    }
}

struct SeedSprite: View {
    var size: CGFloat = 40
    var body: some View {
        Ellipse()
            .fill(Theme.soil)
            .overlay(Ellipse().stroke(Theme.soilDark, lineWidth: 2))
            .frame(width: size * 0.7, height: size)
            .rotationEffect(.degrees(20))
            .frame(width: size, height: size)
    }
}

/// Her companion (chosen at setup): the unicorn, superhero, princess, monster or gnome, drawn in cut paper.
/// The name is kept from the first version so every screen picks up the chosen companion.
struct SparkleView: View {
    enum Mood { case happy, thinking, sleeping }
    var mood: Mood = .happy
    var size: CGFloat = 200
    /// Shown explicitly on the setup cards; otherwise the companion chosen at setup.
    var companion: Companion?
    @EnvironmentObject var model: AppModel

    var body: some View {
        let c = companion ?? model.state.companion
        CompanionArt(companion: c, mood: mood)
            .frame(width: 200, height: 200)
            .scaleEffect(size / 200)
            .frame(width: size, height: size)
            .accessibilityElement()
            .accessibilityLabel("\(c.name) the \(c.kind)")
    }
}

/// Princess Siara, the child's character (placeholder look from the Siara mock).
struct SiaraView: View {
    var size: CGFloat = 180
    var waving = false
    var body: some View {
        ZStack {
            // Dress
            Triangle().fill(Theme.mane).frame(width: size * 0.5, height: size * 0.5)
                .offset(y: size * 0.2)
            // Arm
            Capsule().fill(Color(hex: 0x8D5A3B)).frame(width: size * 0.06, height: size * 0.22)
                .rotationEffect(.degrees(waving ? -140 : -20), anchor: .top)
                .offset(x: size * 0.15, y: size * 0.02)
            // Hair back
            Circle().fill(Color(hex: 0x2B1B14)).frame(width: size * 0.34).offset(y: -size * 0.17)
            // Face
            Circle().fill(Color(hex: 0x8D5A3B)).frame(width: size * 0.28).offset(y: -size * 0.15)
            HStack(spacing: size * 0.07) {
                Circle().fill(Theme.ink).frame(width: size * 0.03)
                Circle().fill(Theme.ink).frame(width: size * 0.03)
            }
            .offset(y: -size * 0.16)
            Capsule().fill(Theme.mane.opacity(0.9)).frame(width: size * 0.07, height: size * 0.02).offset(y: -size * 0.09)
            // Crown
            HStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { _ in Triangle().fill(Theme.gold).frame(width: size * 0.06, height: size * 0.07) }
            }
            .offset(y: -size * 0.33)
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel("Princess Siara")
    }
}

struct CastleArt: View {
    var night = false
    var body: some View {
        ZStack(alignment: .bottom) {
            HStack(alignment: .bottom, spacing: 0) {
                tower(h: 220)
                Rectangle().fill(Theme.lilac).frame(width: 220, height: 170)
                    .overlay(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 40).fill(Theme.deepLavender).frame(width: 70, height: 100)
                    }
                tower(h: 220)
            }
        }
    }

    private func tower(h: CGFloat) -> some View {
        VStack(spacing: 0) {
            Triangle().fill(Theme.mane).frame(width: 100, height: 80)
            Rectangle().fill(Color.white).frame(width: 80, height: h)
                .overlay(
                    RoundedRectangle(cornerRadius: 12).fill(night ? Theme.gold : Theme.daySky)
                        .frame(width: 26, height: 40).offset(y: -40)
                )
        }
    }
}

/// Dot pattern under a numeral (dice-like up to 5, then two rows).
struct DotPattern: View {
    let n: Int
    var dot: CGFloat = 9
    var color: Color = Theme.lavender
    var body: some View {
        let top = min(n, 5)
        let bottom = max(0, min(n - 5, 15))
        VStack(spacing: 3) {
            HStack(spacing: 3) { ForEach(0..<top, id: \.self) { _ in Circle().fill(color).frame(width: dot, height: dot) } }
            if bottom > 0 {
                HStack(spacing: 3) { ForEach(0..<min(bottom, 5), id: \.self) { _ in Circle().fill(Theme.mane).frame(width: dot, height: dot) } }
            }
            if bottom > 5 {
                HStack(spacing: 3) { ForEach(0..<(bottom - 5), id: \.self) { _ in Circle().fill(Theme.gold).frame(width: dot, height: dot) } }
            }
        }
        .frame(minHeight: dot)
    }
}

/// Night or day sky background.
struct SkyBackground: View {
    var night = true
    var litFraction: Double = 0
    var body: some View {
        ZStack {
            LinearGradient(
                colors: night ? [Theme.night, Color(hex: 0x3B3578)] : [Theme.daySky, Color(hex: 0xEAF7FC)],
                startPoint: .top, endPoint: .bottom
            )
            if night {
                Canvas { ctx, size in
                    var g = SeededDots(seed: 7)
                    for _ in 0..<60 {
                        let x = g.next() * size.width, y = g.next() * size.height * 0.8
                        let r = 1 + g.next() * 2
                        let bright = g.next() < litFraction
                        ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                                 with: .color(Color.white.opacity(bright ? 0.95 : 0.25)))
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct GardenBackground: View {
    var bloom: Double = 0
    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [Theme.daySky, Color(hex: 0xEAF7FC)], startPoint: .top, endPoint: .bottom)
            Ellipse().fill(Theme.garden.opacity(0.85)).frame(height: 300).offset(y: 140).scaleEffect(x: 1.6)
            Canvas { ctx, size in
                var g = SeededDots(seed: 3)
                let count = Int(40 * bloom)
                for _ in 0..<count {
                    let x = g.next() * size.width, y = size.height - g.next() * 120
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 10, height: 10)),
                             with: .color([Theme.mane, Theme.gold, Theme.lavender][Int(g.next() * 3) % 3]))
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct SeededDots {
    private var s: UInt64
    init(seed: UInt64) { s = seed &* 2654435761 &+ 1 }
    mutating func next() -> Double {
        s = s &* 6364136223846793005 &+ 1442695040888963407
        return Double((s >> 33) % 10_000) / 10_000
    }
}

/// The things counted in each chapter. `second` draws the added part in another colour.
enum CounterStyle {
    case flower, plank, gem, guest, treat, berry, crystal
}

struct CounterSprite: View {
    var style: CounterStyle
    var second = false
    var size: CGFloat = 46
    var body: some View {
        switch style {
        case .flower:
            FlowerSprite(color: second ? Theme.gold : Theme.mane, size: size)
        case .plank:
            RoundedRectangle(cornerRadius: size * 0.12)
                .fill(second ? Color(hex: 0xC98B52) : Theme.soil)
                .overlay(RoundedRectangle(cornerRadius: size * 0.12).stroke(Theme.soilDark, lineWidth: 2))
                .frame(width: size * 0.36, height: size)
                .frame(width: size, height: size)
        case .gem:
            GemShape()
                .fill(second ? Theme.lavender : Color(hex: 0x3FB6C8))
                .overlay(GemShape().stroke(Color.white.opacity(0.8), lineWidth: 2))
                .frame(width: size * 0.8, height: size * 0.8)
                .frame(width: size, height: size)
        case .guest:
            VStack(spacing: 0) {
                Circle().fill(Color(hex: 0xE8B48A)).frame(width: size * 0.38, height: size * 0.38)
                Triangle().fill(second ? Theme.gold : Theme.lavender).frame(width: size * 0.6, height: size * 0.5)
            }
            .frame(width: size, height: size)
        case .treat:
            VStack(spacing: 0) {
                Circle().fill(second ? Theme.gold : Theme.mane).frame(width: size * 0.55, height: size * 0.45)
                Rectangle().fill(Theme.soil).frame(width: size * 0.45, height: size * 0.32)
            }
            .frame(width: size, height: size)
        case .berry:
            Circle().fill(second ? Theme.lavender : Color(hex: 0xD9435F))
                .overlay(Circle().fill(Theme.garden).frame(width: size * 0.18).offset(y: -size * 0.3))
                .frame(width: size * 0.6, height: size * 0.6)
                .frame(width: size, height: size)
        case .crystal:
            GemShape().fill(second ? Theme.gold : Color(hex: 0xBFD8FF))
                .frame(width: size * 0.7, height: size)
                .frame(width: size, height: size)
        }
    }
}

struct GemShape: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.midX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.38))
            p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.38))
            p.closeSubpath()
        }
    }
}

/// A bundle of ten planks tied with a band (Chapter 2).
struct TenBundle: View {
    var glow = false
    var size: CGFloat = 120
    var body: some View {
        ZStack {
            HStack(spacing: 1) {
                ForEach(0..<10, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 3).fill(Theme.soil)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Theme.soilDark, lineWidth: 1))
                        .frame(width: size * 0.085, height: size)
                }
            }
            Rectangle().fill(Theme.mane).frame(width: size * 1.02, height: size * 0.1)
            Text("10").font(Theme.numeral(size * 0.2)).foregroundStyle(.white)
                .padding(4).background(Circle().fill(Theme.deepLavender)).offset(y: -size * 0.62)
        }
        .frame(width: size * 1.05, height: size * 1.3)
        .shadow(color: glow ? Theme.gold : .clear, radius: 14)
        .accessibilityIdentifier("tenBundle")
    }
}
