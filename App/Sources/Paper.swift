import KingdomCore
import SwiftUI
import UIKit

// Paper theatre pieces (charter v1.2): every place is a stage set of layered cut paper.

extension View {
    /// A cut-paper layer: a soft shadow below, as if it stands a little in front of the layer behind.
    func paperCut(_ depth: CGFloat = 1) -> some View {
        shadow(color: Theme.shadow.opacity(0.28), radius: 5 * depth, x: 0, y: 6 * depth)
    }
}

/// A rolling hill line across the stage, from `y` (fraction of the height) with gentle bumps.
struct HillShape: Shape {
    var y: CGFloat
    var bumps: [CGFloat]
    func path(in r: CGRect) -> Path {
        var p = Path()
        let top = r.height * y
        p.move(to: CGPoint(x: r.minX, y: r.minY + top))
        let n = bumps.count
        for (i, b) in bumps.enumerated() {
            let x0 = r.width * CGFloat(i) / CGFloat(n), x1 = r.width * CGFloat(i + 1) / CGFloat(n)
            p.addQuadCurve(to: CGPoint(x: x1, y: r.minY + top + (i.isMultiple(of: 2) ? 8 : -8)),
                           control: CGPoint(x: (x0 + x1) / 2, y: r.minY + top - r.height * b))
        }
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// A fine paper grain over the whole screen. One small noise tile is drawn once and repeated, so the grain
/// costs nothing when a screen redraws. Never touchable.
struct PaperGrain: View {
    static let tile: UIImage = {
        let size = CGSize(width: 180, height: 180)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            var g = SeededDots(seed: 11)
            for _ in 0..<520 {
                let x = g.next() * size.width, y = g.next() * size.height
                let dark = g.next() < 0.5
                (dark ? UIColor(red: 0.35, green: 0.23, blue: 0.13, alpha: 0.07) : UIColor(white: 1, alpha: 0.08)).setFill()
                ctx.fill(CGRect(x: x, y: y, width: 1.4, height: 1.4))
            }
        }
    }()

    var body: some View {
        Image(uiImage: PaperGrain.tile)
            .resizable(resizingMode: .tile)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .ignoresSafeArea()
    }
}

/// Colours for one place's stage set.
struct StageLook {
    var sky: Color
    var hills: [Color]
    var night: Bool

    static func of(_ chapter: ChapterID?) -> StageLook {
        switch chapter {
        case "prologue": return StageLook(sky: Theme.nightPaper, hills: [Theme.nightPaperLow, Color(hex: 0x3A4A5E), Color(hex: 0x2F4A44)], night: true)
        case "garden": return StageLook(sky: Theme.cream, hills: [Theme.sagePale, Theme.sage, Theme.sageDeep], night: false)
        case "bridge": return StageLook(sky: Theme.cream, hills: [Theme.sagePale, Theme.river, Color(hex: 0x6F9592)], night: false)
        case "goblin": return StageLook(sky: Color(hex: 0x3D3442), hills: [Color(hex: 0x5B4B57), Color(hex: 0x6E5A50), Color(hex: 0x4A3A33)], night: true)
        case "ball": return StageLook(sky: Color(hex: 0xF4E1D2), hills: [Color(hex: 0xE8C2B0), Color(hex: 0xD99A8A), Theme.rose.opacity(0.85)], night: false)
        case "feast": return StageLook(sky: Color(hex: 0xF6E3C4), hills: [Color(hex: 0xEAC88F), Theme.ochre.opacity(0.8), Theme.wood], night: false)
        case "moon": return StageLook(sky: Theme.nightPaper, hills: [Theme.nightPaperLow, Color(hex: 0x3B3F63), Color(hex: 0x2A2D49)], night: true)
        default: return StageLook(sky: Theme.cream, hills: [Theme.sagePale, Theme.sage, Theme.sageDeep], night: false)
        }
    }
}

/// The stage set behind a screen: sky, sun or moon, three layered paper hills, and the grain.
/// `lit` (0...1) wakes the night sky's paper stars or the garden's flowers as she plays.
struct PaperStage: View {
    var chapter: ChapterID?
    var lit: Double = 1
    /// Busy screens with cards (setup) hide the sun or moon so it never sits behind a card.
    var showSky: Bool = true

    var body: some View {
        let look = StageLook.of(chapter)
        GeometryReader { geo in
            ZStack {
                look.sky
                if look.night && showSky {
                    PaperStars(lit: lit).frame(width: geo.size.width, height: geo.size.height * 0.6)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.3)
                    Circle().fill(Theme.card).frame(width: 110, height: 110)
                        .overlay(Circle().fill(look.sky).frame(width: 90, height: 90).offset(x: 28, y: -14))
                        .paperCut()
                        .position(x: geo.size.width * 0.82, y: geo.size.height * 0.16)
                } else if showSky {
                    Circle().fill(Theme.sun).frame(width: 140, height: 140).paperCut()
                        .position(x: geo.size.width * 0.8, y: geo.size.height * 0.17)
                }
                HillShape(y: 0.55, bumps: [0.10, 0.04, 0.08, 0.03]).fill(look.hills[0]).paperCut()
                HillShape(y: 0.66, bumps: [0.05, 0.08, 0.03, 0.06]).fill(look.hills[1]).paperCut()
                if chapter == "garden" {
                    PaperFlowers(bloom: lit).frame(height: geo.size.height * 0.2)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.8)
                }
                HillShape(y: 0.80, bumps: [0.03, 0.05, 0.02, 0.04, 0.03]).fill(look.hills[2]).paperCut()
                PaperGrain()
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// Paper stars pinned to the night sky; unlit ones are pale until she wakes them.
struct PaperStars: View {
    var lit: Double
    var body: some View {
        Canvas { ctx, size in
            var g = SeededDots(seed: 7)
            for i in 0..<28 {
                let x = g.next() * size.width, y = g.next() * size.height * 0.9
                let r = 6 + g.next() * 8
                let on = Double(i) / 28 < lit
                let star = StarShape().path(in: CGRect(x: x, y: y, width: r * 2, height: r * 2))
                ctx.fill(star, with: .color(on ? Theme.sun : Theme.card.opacity(0.28)))
            }
        }
        .allowsHitTesting(false)
    }
}

/// Cut-paper flowers along the garden hill.
struct PaperFlowers: View {
    var bloom: Double
    var body: some View {
        Canvas { ctx, size in
            var g = SeededDots(seed: 3)
            let count = Int(18 * max(0.15, bloom))
            let colors = [Theme.poppy, Theme.rose, Theme.ochre]
            for _ in 0..<count {
                let x = g.next() * size.width, y = size.height * (0.3 + g.next() * 0.6)
                ctx.fill(Path(CGRect(x: x - 1.5, y: y, width: 3, height: 22)), with: .color(Theme.sageDeep))
                ctx.fill(Path(ellipseIn: CGRect(x: x - 9, y: y - 9, width: 18, height: 18)),
                         with: .color(colors[Int(g.next() * 3) % 3]))
                ctx.fill(Path(ellipseIn: CGRect(x: x - 3.5, y: y - 3.5, width: 7, height: 7)), with: .color(Theme.sun))
            }
        }
        .allowsHitTesting(false)
    }
}

/// The theatre curtain (charter v1.2): it rises when a scene starts and falls at its end.
/// Never takes a touch.
struct TheatreCurtain: View {
    /// 0 = closed across the stage, 1 = fully open.
    var open: Double

    var body: some View {
        GeometryReader { geo in
            let half = geo.size.width / 2
            let shift = half * open
            ZStack(alignment: .top) {
                drape(width: half + 20).offset(x: -shift)
                    .frame(width: geo.size.width, alignment: .leading)
                drape(width: half + 20).scaleEffect(x: -1).offset(x: shift)
                    .frame(width: geo.size.width, alignment: .trailing)
                Valance().fill(Theme.clayDark).frame(height: 34).paperCut()
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func drape(width: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { i in
                Rectangle().fill(i.isMultiple(of: 2) ? Theme.clay : Theme.clayDark.opacity(0.9))
            }
        }
        .frame(width: width)
        .overlay(alignment: .trailing) { Rectangle().fill(Theme.sun.opacity(0.85)).frame(width: 6) }
        .paperCut(1.4)
    }
}

/// The scalloped band along the top of the stage.
struct Valance: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: .zero)
        p.addLine(to: CGPoint(x: r.maxX, y: 0))
        p.addLine(to: CGPoint(x: r.maxX, y: r.height * 0.6))
        let n = max(1, Int(r.width / 70))
        let w = r.width / CGFloat(n)
        for i in (0..<n).reversed() {
            let x0 = CGFloat(i + 1) * w, x1 = CGFloat(i) * w
            p.addQuadCurve(to: CGPoint(x: x1, y: r.height * 0.6), control: CGPoint(x: (x0 + x1) / 2, y: r.height * 1.3))
        }
        p.closeSubpath()
        return p
    }
}
