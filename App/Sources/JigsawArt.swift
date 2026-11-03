import KingdomCore
import SwiftUI
import UIKit

/// A jigsaw piece: the core square sits inside `margin`, and tabs reach into the margin.
/// Edges are top, right, bottom, left: 0 flat, +1 a tab out, -1 a hole in. The tab profile is symmetric,
/// so a piece's tab matches its neighbour's hole exactly.
struct JigsawPieceShape: Shape {
    let edges: [Int]
    let cut: JigsawCut
    let margin: CGFloat

    func path(in rect: CGRect) -> Path {
        let core = rect.insetBy(dx: margin, dy: margin)
        let tl = CGPoint(x: core.minX, y: core.minY)
        let tr = CGPoint(x: core.maxX, y: core.minY)
        let br = CGPoint(x: core.maxX, y: core.maxY)
        let bl = CGPoint(x: core.minX, y: core.maxY)
        var p = Path()
        p.move(to: tl)
        edge(&p, from: tl, to: tr, normal: CGPoint(x: 0, y: -1), sign: edges[0])
        edge(&p, from: tr, to: br, normal: CGPoint(x: 1, y: 0), sign: edges[1])
        edge(&p, from: br, to: bl, normal: CGPoint(x: 0, y: 1), sign: edges[2])
        edge(&p, from: bl, to: tl, normal: CGPoint(x: -1, y: 0), sign: edges[3])
        p.closeSubpath()
        return p
    }

    private func at(_ a: CGPoint, _ d: CGPoint, _ f: CGFloat, _ n: CGPoint, _ k: CGFloat) -> CGPoint {
        CGPoint(x: a.x + d.x * f + n.x * k, y: a.y + d.y * f + n.y * k)
    }

    private func edge(_ p: inout Path, from a: CGPoint, to b: CGPoint, normal n: CGPoint, sign: Int) {
        guard sign != 0, cut != .squares else { p.addLine(to: b); return }
        let d = CGPoint(x: b.x - a.x, y: b.y - a.y)
        let t: CGFloat = margin * 0.9 * CGFloat(sign)
        if cut == .wavy {
            p.addCurve(to: b, control1: at(a, d, 0.25, n, t * 1.2), control2: at(a, d, 0.75, n, t * 1.2))
            return
        }
        p.addLine(to: at(a, d, 0.37, n, 0))
        p.addCurve(to: at(a, d, 0.5, n, t), control1: at(a, d, 0.29, n, t * 0.6), control2: at(a, d, 0.34, n, t))
        p.addCurve(to: at(a, d, 0.63, n, 0), control1: at(a, d, 0.66, n, t), control2: at(a, d, 0.71, n, t * 0.6))
        p.addLine(to: b)
    }
}

/// The puzzle pictures: paper-theatre scenes drawn in code, so any picture can be cut at any size.
/// Her interests (princesses, unicorns, dancing, martial arts) and the kingdom she knows.
enum JigsawPictures {
    struct Picture: Identifiable, Equatable {
        let id: String
        let name: String
        var group: JigsawGroup = .easy
    }

    static let all: [Picture] = [
        .init(id: "castle", name: "The castle"),
        .init(id: "garden", name: "The flower garden"),
        .init(id: "companion", name: "My friend in the meadow"),
        .init(id: "ballet", name: "The dancer"),
        .init(id: "karate", name: "Martial arts"),
        .init(id: "ball", name: "The royal ball"),
        .init(id: "night", name: "The night sky"),
        .init(id: "rainbow", name: "The rainbow bridge"),
        // J16 Medium: busier scenes, 30 pieces.
        .init(id: "market", name: "Market day", group: .medium),
        .init(id: "pond", name: "The lily pond", group: .medium),
        .init(id: "toyshop", name: "The toy shop", group: .medium),
        .init(id: "dance", name: "Dance class", group: .medium),
        // J16 Hard: the most detail, 50 pieces.
        .init(id: "harbour", name: "The busy harbour", group: .hard),
        .init(id: "forest", name: "The enchanted forest", group: .hard),
        .init(id: "fair", name: "The kingdom fair", group: .hard),
        .init(id: "festival", name: "Lantern festival", group: .hard),
    ]

    static let groups: [String: JigsawGroup] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0.group) })

    static func pictures(in group: JigsawGroup) -> [Picture] { all.filter { $0.group == group } }

    static func group(of id: String) -> JigsawGroup { groups[id] ?? .easy }

    /// Renders a picture once to an image, so pieces can show their part of it.
    @MainActor
    static func render(_ id: String, companion: Companion, size: CGSize) -> UIImage {
        let renderer = ImageRenderer(content: JigsawScene(id: id, companion: companion).frame(width: size.width, height: size.height))
        renderer.scale = 2
        return renderer.uiImage ?? UIImage()
    }
}

/// One scene, drawn to fill whatever size it is given.
struct JigsawScene: View {
    let id: String
    let companion: Companion

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                switch id {
                case "castle": castle(w, h)
                case "garden": garden(w, h)
                case "companion": meadow(w, h)
                case "ballet": ballet(w, h)
                case "karate": karate(w, h)
                case "ball": ball(w, h)
                case "night": night(w, h)
                case "rainbow": rainbow(w, h)
                default: DetailedJigsawScene(id: id, companion: companion)
                }
            }
            .frame(width: w, height: h)
            .clipped()
        }
    }

    // MARK: Building blocks

    private func band(_ color: Color, _ w: CGFloat, _ h: CGFloat, top: CGFloat, height: CGFloat) -> some View {
        Rectangle().fill(color).frame(width: w, height: h * height).position(x: w / 2, y: h * (top + height / 2))
    }

    private func hill(_ color: Color, _ w: CGFloat, _ h: CGFloat, x: CGFloat, y: CGFloat, r: CGFloat) -> some View {
        Ellipse().fill(color).frame(width: w * r * 2, height: h * r * 1.4).position(x: w * x, y: h * y)
    }

    private func sun(_ w: CGFloat, _ h: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle().fill(Theme.sun).frame(width: min(w, h) * 0.22).position(x: w * x, y: h * y)
    }

    private func flowers(_ w: CGFloat, _ h: CGFloat, y: CGFloat, count: Int, colors: [Color]) -> some View {
        ForEach(0..<count, id: \.self) { i in
            FlowerSprite(color: colors[i % colors.count], size: min(w, h) * 0.13)
                .position(x: w * (CGFloat(i) + 0.5) / CGFloat(count), y: h * y + CGFloat(i % 2) * h * 0.06)
        }
    }

    private func scaled<V: View>(_ v: V, natural: CGSize, width: CGFloat, at p: CGPoint) -> some View {
        v.frame(width: natural.width, height: natural.height)
            .scaleEffect(width / natural.width)
            .frame(width: width, height: natural.height * width / natural.width)
            .position(p)
    }

    // MARK: Scenes

    private func castle(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            band(Color(hex: 0xBFD9EA), w, h, top: 0, height: 0.6)
            sun(w, h, x: 0.85, y: 0.18)
            hill(Theme.sagePale, w, h, x: 0.2, y: 0.7, r: 0.4)
            hill(Theme.sage, w, h, x: 0.85, y: 0.75, r: 0.4)
            band(Theme.sageDeep, w, h, top: 0.8, height: 0.2)
            scaled(CastleArt(), natural: CGSize(width: 420, height: 300), width: w * 0.5, at: CGPoint(x: w * 0.5, y: h * 0.58))
            flowers(w, h, y: 0.9, count: 7, colors: [Theme.rose, Theme.sun, Theme.poppy])
        }
    }

    private func garden(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            band(Theme.cream, w, h, top: 0, height: 0.5)
            sun(w, h, x: 0.15, y: 0.2)
            band(Theme.sagePale, w, h, top: 0.45, height: 0.2)
            band(Theme.wood, w, h, top: 0.62, height: 0.38)
            flowers(w, h, y: 0.55, count: 6, colors: [Theme.rose, Theme.sun])
            flowers(w, h, y: 0.8, count: 5, colors: [Theme.poppy, Theme.river, Color(hex: 0xB07CC6)])
        }
    }

    private func meadow(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            band(Color(hex: 0xF6D6E0), w, h, top: 0, height: 0.55)
            sun(w, h, x: 0.8, y: 0.2)
            hill(Theme.sage, w, h, x: 0.3, y: 0.85, r: 0.6)
            hill(Theme.sageDeep, w, h, x: 0.95, y: 0.95, r: 0.4)
            scaled(CompanionArt(companion: companion), natural: CGSize(width: 200, height: 200), width: min(w, h * 1.2) * 0.55,
                   at: CGPoint(x: w * 0.42, y: h * 0.55))
            flowers(w, h, y: 0.92, count: 6, colors: [Theme.sun, Theme.rose])
        }
    }

    private func ballet(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            band(Color(hex: 0x7B2D3F), w, h, top: 0, height: 1)
            // Curtains and stage.
            Rectangle().fill(Theme.rose).frame(width: w * 0.16, height: h).position(x: w * 0.08, y: h / 2)
            Rectangle().fill(Theme.rose).frame(width: w * 0.16, height: h).position(x: w * 0.92, y: h / 2)
            band(Theme.wood, w, h, top: 0.78, height: 0.22)
            Ellipse().fill(Theme.sun.opacity(0.55)).frame(width: w * 0.45, height: h * 0.18).position(x: w * 0.5, y: h * 0.8)
            dancer(w, h, x: 0.5, color: Color(hex: 0xF4A6C1), arms: true)
            ForEach(0..<5, id: \.self) { i in
                StarSprite(lit: true, size: min(w, h) * 0.08).position(x: w * (0.25 + CGFloat(i) * 0.125), y: h * 0.12)
            }
        }
    }

    private func dancer(_ w: CGFloat, _ h: CGFloat, x: CGFloat, color: Color, arms: Bool) -> some View {
        let s = min(w, h)
        return ZStack {
            Circle().fill(Color(hex: 0x8D5A3B)).frame(width: s * 0.11).offset(y: -s * 0.26)
            Circle().fill(Color(hex: 0x3B2A20)).frame(width: s * 0.12).offset(y: -s * 0.3)
            Triangle().fill(color).frame(width: s * 0.3, height: s * 0.2).offset(y: -s * 0.08)
            Capsule().fill(Color(hex: 0x8D5A3B)).frame(width: s * 0.03, height: s * 0.2).offset(x: -s * 0.03, y: s * 0.1)
            Capsule().fill(Color(hex: 0x8D5A3B)).frame(width: s * 0.03, height: s * 0.2)
                .rotationEffect(.degrees(-40)).offset(x: s * 0.07, y: s * 0.08)
            if arms {
                Capsule().fill(Color(hex: 0x8D5A3B)).frame(width: s * 0.03, height: s * 0.17)
                    .rotationEffect(.degrees(-35)).offset(x: -s * 0.08, y: -s * 0.24)
                Capsule().fill(Color(hex: 0x8D5A3B)).frame(width: s * 0.03, height: s * 0.17)
                    .rotationEffect(.degrees(35)).offset(x: s * 0.08, y: -s * 0.24)
            }
        }
        .position(x: w * x, y: h * 0.52)
    }

    private func karate(_ w: CGFloat, _ h: CGFloat) -> some View {
        let s = min(w, h)
        return ZStack {
            band(Color(hex: 0xF3E1B6), w, h, top: 0, height: 0.7)
            // Paper screen panels.
            ForEach(0..<6, id: \.self) { i in
                Rectangle().stroke(Theme.woodDark, lineWidth: 3).frame(width: w / 6, height: h * 0.55)
                    .position(x: w * (CGFloat(i) + 0.5) / 6, y: h * 0.32)
            }
            band(Color(hex: 0x9CC08A), w, h, top: 0.7, height: 0.3)
            Circle().fill(Theme.poppy).frame(width: s * 0.25).position(x: w * 0.82, y: h * 0.25)
            ZStack {
                // A child in a white gi with a yellow belt, mid kick.
                Circle().fill(Color(hex: 0x8D5A3B)).frame(width: s * 0.11).offset(y: -s * 0.28)
                Circle().fill(Color(hex: 0x3B2A20)).frame(width: s * 0.12).offset(x: -s * 0.01, y: -s * 0.31)
                RoundedRectangle(cornerRadius: 6).fill(Color.white).frame(width: s * 0.16, height: s * 0.24).offset(y: -s * 0.1)
                Rectangle().fill(Theme.sun).frame(width: s * 0.17, height: s * 0.03).offset(y: -s * 0.01)
                Capsule().fill(Color.white).frame(width: s * 0.05, height: s * 0.24).rotationEffect(.degrees(70))
                    .offset(x: s * 0.15, y: s * 0.02)
                Capsule().fill(Color.white).frame(width: s * 0.05, height: s * 0.22).offset(x: -s * 0.03, y: s * 0.13)
                Capsule().fill(Color.white).frame(width: s * 0.04, height: s * 0.18).rotationEffect(.degrees(-60))
                    .offset(x: -s * 0.12, y: -s * 0.15)
            }
            .position(x: w * 0.45, y: h * 0.55)
        }
    }

    private func ball(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            band(Color(hex: 0xE9D7F2), w, h, top: 0, height: 0.75)
            // Windows and a chandelier.
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: w * 0.04).fill(Color(hex: 0xBFD3F2))
                    .frame(width: w * 0.12, height: h * 0.35).position(x: w * (0.14 + CGFloat(i) * 0.24), y: h * 0.3)
            }
            Circle().fill(Theme.sun).frame(width: min(w, h) * 0.14).position(x: w * 0.5, y: h * 0.08)
            band(Color(hex: 0xC9A27C), w, h, top: 0.75, height: 0.25)
            dancer(w, h, x: 0.3, color: Theme.rose, arms: true)
            scaled(SiaraView(size: 180), natural: CGSize(width: 180, height: 180), width: min(w, h) * 0.6,
                   at: CGPoint(x: w * 0.68, y: h * 0.58))
        }
    }

    private func night(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            band(Theme.nightPaper, w, h, top: 0, height: 0.75)
            Circle().fill(Theme.card).frame(width: min(w, h) * 0.24).position(x: w * 0.8, y: h * 0.22)
            ForEach(0..<9, id: \.self) { i in
                StarSprite(lit: true, size: min(w, h) * 0.09)
                    .position(x: w * (0.08 + CGFloat(i % 5) * 0.15), y: h * (i < 5 ? 0.15 : 0.38))
            }
            hill(Theme.nightPaperLow, w, h, x: 0.3, y: 0.85, r: 0.55)
            hill(Color(hex: 0x2F5C45), w, h, x: 0.9, y: 0.92, r: 0.4)
        }
    }

    private func rainbow(_ w: CGFloat, _ h: CGFloat) -> some View {
        let colors: [Color] = [Theme.rose, Theme.poppy, Theme.sun, Theme.sage, Theme.river, Color(hex: 0xB07CC6)]
        return ZStack {
            band(Color(hex: 0xCFE6F2), w, h, top: 0, height: 0.7)
            ForEach(0..<colors.count, id: \.self) { i in
                Circle().stroke(colors[i], lineWidth: min(w, h) * 0.06)
                    .frame(width: w * (0.95 - CGFloat(i) * 0.1), height: w * (0.95 - CGFloat(i) * 0.1))
                    .position(x: w * 0.5, y: h * 0.9)
            }
            band(Theme.river, w, h, top: 0.8, height: 0.2)
            CloudShape().fill(Color.white).frame(width: w * 0.25, height: h * 0.15).position(x: w * 0.12, y: h * 0.75)
            CloudShape().fill(Color.white).frame(width: w * 0.25, height: h * 0.15).position(x: w * 0.88, y: h * 0.75)
        }
    }
}
