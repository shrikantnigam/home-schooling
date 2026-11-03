import KingdomCore
import SwiftUI

/// Medium and Hard jigsaw pictures (J16, Shrikant 2026-11-03): busier scenes with more small parts, so the
/// colours and shapes on each piece matter more. Medium scenes are cut into 30 pieces, Hard into 50.
/// Drawn in code like the Easy pictures, in the same paper-theatre palette.
struct DetailedJigsawScene: View {
    let id: String
    let companion: Companion

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                switch id {
                case "market": market(w, h)
                case "pond": pond(w, h)
                case "toyshop": toyshop(w, h)
                case "dance": dance(w, h)
                case "harbour": harbour(w, h)
                case "forest": forest(w, h)
                case "fair": fair(w, h)
                default: festival(w, h)
                }
            }
            .frame(width: w, height: h)
            .clipped()
        }
    }

    // MARK: Helpers

    private func rect(_ c: Color, _ w: CGFloat, _ h: CGFloat, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat,
                      corner: CGFloat = 0) -> some View {
        RoundedRectangle(cornerRadius: corner).fill(c).frame(width: w * width, height: h * height).position(x: w * x, y: h * y)
    }

    private func dot(_ c: Color, _ w: CGFloat, _ h: CGFloat, x: CGFloat, y: CGFloat, d: CGFloat) -> some View {
        Circle().fill(c).frame(width: min(w, h) * d).position(x: w * x, y: h * y)
    }

    private func tri(_ c: Color, _ w: CGFloat, _ h: CGFloat, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat,
                     flip: Bool = false) -> some View {
        Triangle().fill(c).frame(width: w * width, height: h * height).rotationEffect(.degrees(flip ? 180 : 0))
            .position(x: w * x, y: h * y)
    }

    /// A fixed scatter in 0...1, the same every time, so a picture never changes between pieces.
    private func spot(_ i: Int, _ salt: Int) -> CGFloat {
        let v = sin(Double(i * 127 + salt * 311) * 12.9898) * 43758.5453
        return CGFloat(v - v.rounded(.down))
    }

    private let palette: [Color] = [Theme.rose, Theme.sun, Theme.river, Theme.sage, Theme.poppy, Theme.lavender, Theme.ochre]

    private func bunting(_ w: CGFloat, _ h: CGFloat, y: CGFloat, count: Int) -> some View {
        ZStack {
            Rectangle().fill(Theme.woodDark).frame(width: w, height: 2).position(x: w / 2, y: h * y)
            ForEach(0..<count, id: \.self) { i in
                tri(palette[i % palette.count], w, h, x: (CGFloat(i) + 0.5) / CGFloat(count), y: y + 0.035,
                    width: 0.6 / CGFloat(count), height: 0.07, flip: true)
            }
        }
    }

    private func person(_ w: CGFloat, _ h: CGFloat, x: CGFloat, y: CGFloat, s: CGFloat, shirt: Color, hair: Color) -> some View {
        let u = min(w, h) * s
        return ZStack {
            Capsule().fill(shirt).frame(width: u * 0.5, height: u * 0.7).offset(y: u * 0.35)
            Circle().fill(Color(hex: 0xC98B62)).frame(width: u * 0.38)
            Circle().fill(hair).frame(width: u * 0.4).offset(y: -u * 0.08).mask(Rectangle().frame(height: u * 0.2).offset(y: -u * 0.12))
        }
        .position(x: w * x, y: h * y)
    }

    // MARK: Medium

    private func market(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            rect(Theme.daySky, w, h, x: 0.5, y: 0.3, width: 1, height: 0.6)
            dot(Theme.sun, w, h, x: 0.9, y: 0.12, d: 0.16)
            ForEach(0..<3, id: \.self) { i in
                CloudShape().fill(Color.white).frame(width: w * 0.16, height: h * 0.09)
                    .position(x: w * (0.15 + CGFloat(i) * 0.3), y: h * (0.1 + CGFloat(i % 2) * 0.06))
            }
            rect(Theme.ochre.opacity(0.5), w, h, x: 0.5, y: 0.82, width: 1, height: 0.36)
            bunting(w, h, y: 0.2, count: 14)
            ForEach(0..<3, id: \.self) { s in
                let x0 = 0.18 + CGFloat(s) * 0.32
                // Striped awning.
                ForEach(0..<6, id: \.self) { k in
                    rect(k % 2 == 0 ? palette[s] : Color.white, w, h, x: x0 - 0.125 + CGFloat(k) * 0.05, y: 0.38,
                         width: 0.05, height: 0.1)
                }
                rect(Theme.wood, w, h, x: x0, y: 0.6, width: 0.27, height: 0.24)
                rect(Theme.woodDark, w, h, x: x0, y: 0.49, width: 0.29, height: 0.03)
                // Fruit and bread on the counter.
                ForEach(0..<7, id: \.self) { f in
                    dot([Theme.poppy, Theme.sun, Theme.sage, Theme.rose][(f + s) % 4], w, h,
                        x: x0 - 0.11 + CGFloat(f) * 0.036, y: 0.465 - CGFloat(f % 2) * 0.02, d: 0.045)
                }
                rect(Theme.woodDark, w, h, x: x0 - 0.12, y: 0.66, width: 0.012, height: 0.34)
                rect(Theme.woodDark, w, h, x: x0 + 0.12, y: 0.66, width: 0.012, height: 0.34)
            }
            person(w, h, x: 0.34, y: 0.78, s: 0.16, shirt: Theme.river, hair: Theme.ink)
            person(w, h, x: 0.66, y: 0.8, s: 0.15, shirt: Theme.rose, hair: Theme.clay)
            // Baskets on the ground.
            ForEach(0..<4, id: \.self) { b in
                Ellipse().fill(Theme.clay).frame(width: w * 0.08, height: h * 0.06)
                    .position(x: w * (0.08 + CGFloat(b) * 0.28), y: h * 0.93)
            }
        }
    }

    private func pond(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            rect(Theme.daySky, w, h, x: 0.5, y: 0.25, width: 1, height: 0.5)
            ForEach(0..<5, id: \.self) { i in
                let x = 0.08 + CGFloat(i) * 0.21
                rect(Theme.woodDark, w, h, x: x, y: 0.38, width: 0.025, height: 0.2)
                dot([Theme.sage, Theme.sageDeep][i % 2], w, h, x: x, y: 0.26, d: 0.2)
            }
            rect(Theme.sage, w, h, x: 0.5, y: 0.75, width: 1, height: 0.5)
            Ellipse().fill(Theme.water).frame(width: w * 0.8, height: h * 0.42).position(x: w * 0.5, y: h * 0.7)
            Ellipse().stroke(Color.white.opacity(0.6), lineWidth: 2).frame(width: w * 0.5, height: h * 0.2)
                .position(x: w * 0.45, y: h * 0.7)
            // Lily pads with flowers.
            ForEach(0..<6, id: \.self) { i in
                let x = 0.2 + spot(i, 1) * 0.6
                let y = 0.58 + spot(i, 2) * 0.22
                Circle().fill(Theme.sageDeep).frame(width: min(w, h) * 0.1).position(x: w * x, y: h * y)
                if i % 2 == 0 { FlowerSprite(color: Theme.rose, size: min(w, h) * 0.06).position(x: w * x, y: h * (y - 0.02)) }
            }
            // Fish.
            ForEach(0..<4, id: \.self) { i in
                let x = 0.25 + CGFloat(i) * 0.15
                let y = 0.66 + CGFloat(i % 2) * 0.12
                Ellipse().fill(Theme.poppy).frame(width: w * 0.06, height: h * 0.04).position(x: w * x, y: h * y)
                tri(Theme.poppy, w, h, x: x - 0.035, y: y, width: 0.025, height: 0.04)
            }
            // Reeds.
            ForEach(0..<9, id: \.self) { i in
                Capsule().fill(Theme.sageDeep).frame(width: 4, height: h * (0.12 + spot(i, 3) * 0.08))
                    .position(x: w * (0.05 + CGFloat(i) * 0.012), y: h * 0.82)
                Capsule().fill(Theme.clay).frame(width: 7, height: h * 0.04)
                    .position(x: w * (0.05 + CGFloat(i) * 0.012), y: h * 0.74)
            }
            // A frog on a stone.
            Ellipse().fill(Theme.muted.opacity(0.6)).frame(width: w * 0.12, height: h * 0.07).position(x: w * 0.86, y: h * 0.86)
            dot(Theme.garden, w, h, x: 0.86, y: 0.8, d: 0.07)
            dot(Color.white, w, h, x: 0.845, y: 0.775, d: 0.02)
            dot(Color.white, w, h, x: 0.875, y: 0.775, d: 0.02)
        }
    }

    private func toyshop(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            rect(Theme.cream, w, h, x: 0.5, y: 0.5, width: 1, height: 1)
            rect(Theme.daySky, w, h, x: 0.82, y: 0.3, width: 0.26, height: 0.36, corner: 8)
            rect(Theme.woodDark, w, h, x: 0.82, y: 0.3, width: 0.01, height: 0.36)
            rect(Theme.woodDark, w, h, x: 0.82, y: 0.3, width: 0.26, height: 0.01)
            ForEach(0..<3, id: \.self) { r in
                let y = 0.28 + CGFloat(r) * 0.25
                rect(Theme.wood, w, h, x: 0.34, y: y, width: 0.62, height: 0.025)
                ForEach(0..<6, id: \.self) { k in
                    let x = 0.08 + CGFloat(k) * 0.105
                    switch (k + r) % 3 {
                    case 0:
                        rect(palette[(k + r) % palette.count], w, h, x: x, y: y - 0.05, width: 0.07, height: 0.09, corner: 3)
                    case 1:
                        dot(palette[(k + 2 * r) % palette.count], w, h, x: x, y: y - 0.05, d: 0.09)
                    default:
                        // A little teddy.
                        dot(Theme.ochre, w, h, x: x, y: y - 0.035, d: 0.07)
                        dot(Theme.ochre, w, h, x: x, y: y - 0.09, d: 0.05)
                        dot(Theme.ochre, w, h, x: x - 0.018, y: y - 0.115, d: 0.02)
                        dot(Theme.ochre, w, h, x: x + 0.018, y: y - 0.115, d: 0.02)
                    }
                }
            }
            rect(Theme.wood.opacity(0.7), w, h, x: 0.5, y: 0.94, width: 1, height: 0.12)
            // Rocking horse and a train on the floor.
            Ellipse().fill(Theme.rose).frame(width: w * 0.16, height: h * 0.1).position(x: w * 0.82, y: h * 0.7)
            dot(Theme.rose, w, h, x: 0.9, y: 0.62, d: 0.07)
            Capsule().fill(Theme.woodDark).frame(width: w * 0.2, height: 6).position(x: w * 0.82, y: h * 0.82)
            ForEach(0..<4, id: \.self) { c in
                rect(palette[c], w, h, x: 0.62 + CGFloat(c) * 0.07, y: 0.9, width: 0.06, height: 0.06, corner: 3)
                dot(Theme.ink, w, h, x: 0.6 + CGFloat(c) * 0.07, y: 0.935, d: 0.022)
                dot(Theme.ink, w, h, x: 0.64 + CGFloat(c) * 0.07, y: 0.935, d: 0.022)
            }
        }
    }

    private func dance(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            rect(Theme.lilac, w, h, x: 0.5, y: 0.35, width: 1, height: 0.7)
            ForEach(0..<4, id: \.self) { i in
                rect(Color(hex: 0xDCE8F4), w, h, x: 0.14 + CGFloat(i) * 0.24, y: 0.33, width: 0.2, height: 0.46, corner: 4)
                rect(Color.white.opacity(0.5), w, h, x: 0.1 + CGFloat(i) * 0.24, y: 0.3, width: 0.03, height: 0.4)
            }
            rect(Theme.woodDark, w, h, x: 0.5, y: 0.5, width: 1, height: 0.015)
            rect(Theme.wood, w, h, x: 0.5, y: 0.85, width: 1, height: 0.3)
            ForEach(0..<8, id: \.self) { k in
                rect(Theme.woodDark.opacity(0.4), w, h, x: CGFloat(k) / 8 + 0.06, y: 0.85, width: 0.004, height: 0.3)
            }
            ForEach(0..<3, id: \.self) { d in
                let x = 0.22 + CGFloat(d) * 0.28
                person(w, h, x: x, y: 0.6, s: 0.15, shirt: [Theme.rose, Theme.river, Theme.sun][d], hair: Theme.ink)
                tri([Theme.rose, Theme.river, Theme.sun][d], w, h, x: x, y: 0.72, width: 0.12, height: 0.08)
                Capsule().fill(Color(hex: 0xC98B62)).frame(width: 5, height: h * 0.1).position(x: w * (x - 0.015), y: h * 0.8)
                Capsule().fill(Color(hex: 0xC98B62)).frame(width: 5, height: h * 0.1).rotationEffect(.degrees(d == 1 ? -50 : 20))
                    .position(x: w * (x + 0.02), y: h * 0.79)
            }
            ForEach(0..<6, id: \.self) { s in
                StarSprite(lit: true, size: min(w, h) * 0.05).position(x: w * (0.1 + CGFloat(s) * 0.16), y: h * 0.06)
            }
        }
    }

    // MARK: Hard

    private func harbour(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            rect(Theme.daySky, w, h, x: 0.5, y: 0.25, width: 1, height: 0.5)
            ForEach(0..<4, id: \.self) { i in
                CloudShape().fill(Color.white).frame(width: w * (0.12 + spot(i, 4) * 0.08), height: h * 0.07)
                    .position(x: w * (0.1 + CGFloat(i) * 0.26), y: h * (0.07 + spot(i, 5) * 0.08))
            }
            // Gulls.
            ForEach(0..<5, id: \.self) { g in
                Path { p in
                    let x = w * (0.2 + spot(g, 6) * 0.6), y = h * (0.12 + spot(g, 7) * 0.12)
                    p.move(to: CGPoint(x: x - 9, y: y)); p.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x - 5, y: y - 6))
                    p.addQuadCurve(to: CGPoint(x: x + 9, y: y), control: CGPoint(x: x + 5, y: y - 6))
                }
                .stroke(Theme.ink, lineWidth: 2)
            }
            // Houses along the quay, each with windows and a roof.
            ForEach(0..<7, id: \.self) { i in
                let x = 0.07 + CGFloat(i) * 0.12
                let ht = 0.16 + spot(i, 8) * 0.1
                rect(palette[i % palette.count].opacity(0.85), w, h, x: x, y: 0.5 - ht / 2, width: 0.11, height: ht)
                tri(Theme.clay, w, h, x: x, y: 0.5 - ht - 0.03, width: 0.12, height: 0.06)
                ForEach(0..<4, id: \.self) { k in
                    rect(Color.white.opacity(0.85), w, h, x: x - 0.025 + CGFloat(k % 2) * 0.05,
                         y: 0.5 - ht + 0.04 + CGFloat(k / 2) * 0.06, width: 0.025, height: 0.035)
                }
            }
            // Lighthouse.
            ForEach(0..<5, id: \.self) { b in
                rect(b % 2 == 0 ? Color.white : Theme.poppy, w, h, x: 0.93, y: 0.46 - CGFloat(b) * 0.06, width: 0.06, height: 0.06)
            }
            dot(Theme.sun, w, h, x: 0.93, y: 0.14, d: 0.05)
            rect(Theme.water, w, h, x: 0.5, y: 0.76, width: 1, height: 0.52)
            ForEach(0..<16, id: \.self) { k in
                Capsule().fill(Color.white.opacity(0.55)).frame(width: w * 0.05, height: 3)
                    .position(x: w * spot(k, 9), y: h * (0.58 + spot(k, 10) * 0.38))
            }
            rect(Theme.woodDark, w, h, x: 0.5, y: 0.52, width: 1, height: 0.03)
            ForEach(0..<9, id: \.self) { p in
                rect(Theme.woodDark, w, h, x: 0.05 + CGFloat(p) * 0.11, y: 0.56, width: 0.012, height: 0.06)
            }
            // Boats with sails and flags.
            ForEach(0..<4, id: \.self) { b in
                let x = 0.16 + CGFloat(b) * 0.23
                let y = 0.72 + CGFloat(b % 2) * 0.12
                rect([Theme.clay, Theme.river, Theme.rose, Theme.ochre][b], w, h, x: x, y: y, width: 0.15, height: 0.05, corner: 8)
                rect(Theme.woodDark, w, h, x: x, y: y - 0.11, width: 0.006, height: 0.18)
                tri(Color.white, w, h, x: x + 0.035, y: y - 0.11, width: 0.07, height: 0.15)
                tri(palette[(b + 3) % palette.count], w, h, x: x - 0.02, y: y - 0.2, width: 0.035, height: 0.03)
            }
        }
    }

    private func forest(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            rect(Theme.sagePale, w, h, x: 0.5, y: 0.5, width: 1, height: 1)
            dot(Theme.sun.opacity(0.8), w, h, x: 0.5, y: 0.1, d: 0.18)
            // Three rows of trees, back to front.
            ForEach(0..<3, id: \.self) { row in
                ForEach(0..<6, id: \.self) { t in
                    let x = (CGFloat(t) + (row % 2 == 0 ? 0.3 : 0.8)) / 6
                    let y = 0.32 + CGFloat(row) * 0.14
                    rect(Theme.woodDark, w, h, x: x, y: y + 0.1, width: 0.018, height: 0.1)
                    tri([Theme.sage, Theme.sageDeep, Theme.garden][row].opacity(row == 0 ? 0.7 : 1), w, h,
                        x: x, y: y, width: 0.13, height: 0.22)
                    tri([Theme.sage, Theme.sageDeep, Theme.garden][row].opacity(row == 0 ? 0.7 : 1), w, h,
                        x: x, y: y - 0.07, width: 0.1, height: 0.16)
                }
            }
            rect(Theme.sage, w, h, x: 0.5, y: 0.88, width: 1, height: 0.26)
            // A winding path.
            Path { p in
                p.move(to: CGPoint(x: w * 0.42, y: h))
                p.addQuadCurve(to: CGPoint(x: w * 0.55, y: h * 0.76), control: CGPoint(x: w * 0.7, y: h * 0.9))
            }
            .stroke(Theme.ochre.opacity(0.7), style: StrokeStyle(lineWidth: w * 0.06, lineCap: .round))
            // Mushrooms.
            ForEach(0..<5, id: \.self) { m in
                let x = 0.08 + CGFloat(m) * 0.2 + (m > 1 ? 0.08 : 0)
                rect(Theme.cream, w, h, x: x, y: 0.89, width: 0.02, height: 0.05)
                Ellipse().fill(Theme.poppy).frame(width: w * 0.06, height: h * 0.05).position(x: w * x, y: h * 0.86)
                dot(Color.white, w, h, x: x - 0.01, y: 0.855, d: 0.015)
                dot(Color.white, w, h, x: x + 0.012, y: 0.865, d: 0.012)
            }
            // Fireflies.
            ForEach(0..<14, id: \.self) { f in
                dot(Theme.sun, w, h, x: 0.05 + spot(f, 11) * 0.9, y: 0.2 + spot(f, 12) * 0.55, d: 0.018)
            }
            FlowerSprite(color: Theme.rose, size: min(w, h) * 0.07).position(x: w * 0.3, y: h * 0.95)
            FlowerSprite(color: Theme.lavender, size: min(w, h) * 0.07).position(x: w * 0.75, y: h * 0.95)
            CompanionArt(companion: companion).frame(width: 200, height: 200)
                .scaleEffect(min(w, h) * 0.3 / 200).frame(width: min(w, h) * 0.3, height: min(w, h) * 0.3)
                .position(x: w * 0.72, y: h * 0.72)
        }
    }

    private func fair(_ w: CGFloat, _ h: CGFloat) -> some View {
        let wheel = min(w, h) * 0.5
        return ZStack {
            rect(Theme.daySky, w, h, x: 0.5, y: 0.35, width: 1, height: 0.7)
            // Big wheel with cabins.
            Circle().stroke(Theme.woodDark, lineWidth: 4).frame(width: wheel).position(x: w * 0.25, y: h * 0.38)
            ForEach(0..<8, id: \.self) { k in
                let a = Double(k) / 8 * 2 * .pi
                Rectangle().fill(Theme.woodDark).frame(width: 2, height: wheel / 2)
                    .offset(y: -wheel / 4).rotationEffect(.radians(a)).position(x: w * 0.25, y: h * 0.38)
                RoundedRectangle(cornerRadius: 3).fill(palette[k % palette.count]).frame(width: wheel * 0.12, height: wheel * 0.1)
                    .position(x: w * 0.25 + CGFloat(sin(a)) * wheel / 2, y: h * 0.38 - CGFloat(cos(a)) * wheel / 2)
            }
            tri(Theme.woodDark, w, h, x: 0.25, y: 0.62, width: 0.2, height: 0.24)
            // Striped tents.
            ForEach(0..<3, id: \.self) { t in
                let x = 0.52 + CGFloat(t) * 0.17
                ForEach(0..<4, id: \.self) { k in
                    rect(k % 2 == 0 ? [Theme.rose, Theme.river, Theme.sun][t] : Color.white, w, h,
                         x: x - 0.06 + CGFloat(k) * 0.04, y: 0.6, width: 0.04, height: 0.16)
                }
                tri([Theme.rose, Theme.river, Theme.sun][t], w, h, x: x, y: 0.46, width: 0.18, height: 0.13)
                tri(palette[t + 3], w, h, x: x + 0.012, y: 0.37, width: 0.025, height: 0.03)
            }
            rect(Theme.sage, w, h, x: 0.5, y: 0.85, width: 1, height: 0.3)
            // Balloons on strings.
            ForEach(0..<9, id: \.self) { b in
                let x = 0.42 + spot(b, 13) * 0.55
                let y = 0.1 + spot(b, 14) * 0.18
                Rectangle().fill(Theme.ink.opacity(0.5)).frame(width: 1, height: h * 0.1).position(x: w * x, y: h * (y + 0.07))
                Ellipse().fill(palette[b % palette.count]).frame(width: w * 0.035, height: h * 0.06).position(x: w * x, y: h * y)
            }
            // The crowd.
            ForEach(0..<8, id: \.self) { p in
                person(w, h, x: 0.06 + CGFloat(p) * 0.125, y: 0.82 + CGFloat(p % 2) * 0.04, s: 0.11,
                       shirt: palette[(p + 2) % palette.count], hair: [Theme.ink, Theme.clay, Theme.ochre][p % 3])
            }
        }
    }

    private func festival(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            rect(Theme.nightPaper, w, h, x: 0.5, y: 0.5, width: 1, height: 1)
            ForEach(0..<24, id: \.self) { s in
                dot(Color.white.opacity(0.8), w, h, x: spot(s, 15), y: spot(s, 16) * 0.4, d: 0.01 + spot(s, 17) * 0.012)
            }
            // Fireworks.
            ForEach(0..<3, id: \.self) { f in
                let cx = 0.2 + CGFloat(f) * 0.3, cy = 0.14 + CGFloat(f % 2) * 0.08
                ForEach(0..<10, id: \.self) { k in
                    Capsule().fill(palette[(f + k) % palette.count]).frame(width: 3, height: min(w, h) * 0.06)
                        .offset(y: -min(w, h) * 0.05).rotationEffect(.degrees(Double(k) * 36))
                        .position(x: w * cx, y: h * cy)
                }
            }
            CastleArt(night: true).frame(width: 420, height: 300)
                .scaleEffect(w * 0.36 / 420).frame(width: w * 0.36, height: 300 * w * 0.36 / 420)
                .position(x: w * 0.72, y: h * 0.5)
            // Strings of lanterns.
            ForEach(0..<2, id: \.self) { r in
                let y = 0.3 + CGFloat(r) * 0.16
                Rectangle().fill(Theme.tan).frame(width: w, height: 1.5).position(x: w / 2, y: h * y)
                ForEach(0..<9, id: \.self) { k in
                    RoundedRectangle(cornerRadius: 5).fill([Theme.poppy, Theme.sun, Theme.rose][(k + r) % 3])
                        .frame(width: w * 0.04, height: h * 0.06)
                        .shadow(color: Theme.sun.opacity(0.7), radius: 6)
                        .position(x: w * (0.05 + CGFloat(k) * 0.11 + CGFloat(r) * 0.04), y: h * (y + 0.04))
                }
            }
            // River with reflections and little boats with candles.
            rect(Theme.nightPaperLow, w, h, x: 0.5, y: 0.85, width: 1, height: 0.3)
            ForEach(0..<12, id: \.self) { k in
                Capsule().fill(Theme.sun.opacity(0.35)).frame(width: w * 0.04, height: 3)
                    .position(x: w * spot(k, 18), y: h * (0.74 + spot(k, 19) * 0.22))
            }
            ForEach(0..<5, id: \.self) { b in
                let x = 0.1 + CGFloat(b) * 0.2
                Ellipse().fill(Theme.cream).frame(width: w * 0.06, height: h * 0.025).position(x: w * x, y: h * 0.86)
                dot(Theme.sun, w, h, x: x, y: 0.835, d: 0.02)
            }
            person(w, h, x: 0.18, y: 0.62, s: 0.13, shirt: Theme.lavender, hair: Theme.ink)
            person(w, h, x: 0.3, y: 0.63, s: 0.12, shirt: Theme.river, hair: Theme.clay)
        }
    }
}
