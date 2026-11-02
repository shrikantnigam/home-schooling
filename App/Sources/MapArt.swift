import KingdomCore
import SwiftUI

// The kingdom map (charter v1.3): an imaginary landscape in cut paper, with hills, a river, woods,
// footpaths, the castle, and each place as a small stage set.

/// The land behind the places: sky, far hills, a winding river, woods and fields.
struct KingdomLandscape: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Theme.cream
                Circle().fill(Theme.sun).frame(width: 90, height: 90).paperCut().position(x: w * 0.68, y: h * 0.1)
                // Far hills, then the main land
                HillShape(y: 0.26, bumps: [0.08, 0.12, 0.05, 0.10, 0.06]).fill(Theme.sagePale).paperCut()
                HillShape(y: 0.40, bumps: [0.06, 0.03, 0.08, 0.04, 0.07, 0.03]).fill(Theme.sage).paperCut()
                // The night hill where the stars live, top left
                Ellipse().fill(Theme.nightPaper).frame(width: w * 0.3, height: h * 0.34)
                    .position(x: w * 0.13, y: h * 0.32).paperCut()
                PaperStars(lit: 0.6).frame(width: w * 0.22, height: h * 0.18).position(x: w * 0.13, y: h * 0.25)
                // Moon hill, top right
                Ellipse().fill(Theme.nightPaperLow).frame(width: w * 0.26, height: h * 0.3)
                    .position(x: w * 0.9, y: h * 0.26).paperCut()
                HillShape(y: 0.55, bumps: [0.04, 0.06, 0.03, 0.05]).fill(Theme.sageDeep.opacity(0.85)).paperCut()
                // Fields: a few paper stripes
                ForEach(0..<4, id: \.self) { i in
                    Capsule().fill(i.isMultiple(of: 2) ? Theme.sun.opacity(0.35) : Theme.sagePale.opacity(0.7))
                        .frame(width: w * 0.16, height: 16)
                        .rotationEffect(.degrees(-8))
                        .position(x: w * (0.08 + 0.05 * Double(i)), y: h * (0.88 + 0.025 * Double(i)))
                }
                // The river, from the far hills down through the bridge
                River().fill(Theme.river).paperCut(0.6)
                River().stroke(Theme.card.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [10, 14]))
                    .padding(8)
                // Woods
                ForEach(Array(Self.trees.enumerated()), id: \.offset) { _, t in
                    PaperTree(tone: t.2).frame(width: 34, height: 52).position(x: w * t.0, y: h * t.1)
                }
                // Rocks by the cave
                Ellipse().fill(Color(hex: 0x6E5A50)).frame(width: w * 0.2, height: h * 0.2)
                    .position(x: w * 0.72, y: h * 0.86).paperCut()
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    static let trees: [(CGFloat, CGFloat, Int)] = [
        (0.30, 0.62, 0), (0.33, 0.66, 1), (0.36, 0.61, 0), (0.62, 0.45, 1), (0.65, 0.42, 0), (0.68, 0.46, 1),
        (0.92, 0.70, 0), (0.95, 0.66, 1), (0.08, 0.55, 1), (0.40, 0.88, 0), (0.43, 0.92, 1),
    ]
}

/// A winding river across the map.
struct River: Shape {
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.40, y: h * 0.38))
        p.addCurve(to: CGPoint(x: w * 0.47, y: h * 0.66), control1: CGPoint(x: w * 0.50, y: h * 0.46), control2: CGPoint(x: w * 0.38, y: h * 0.56))
        p.addCurve(to: CGPoint(x: w * 0.56, y: h * 1.02), control1: CGPoint(x: w * 0.54, y: h * 0.76), control2: CGPoint(x: w * 0.48, y: h * 0.90))
        p.addLine(to: CGPoint(x: w * 0.62, y: h * 1.02))
        p.addCurve(to: CGPoint(x: w * 0.51, y: h * 0.66), control1: CGPoint(x: w * 0.54, y: h * 0.90), control2: CGPoint(x: w * 0.60, y: h * 0.76))
        p.addCurve(to: CGPoint(x: w * 0.42, y: h * 0.38), control1: CGPoint(x: w * 0.42, y: h * 0.56), control2: CGPoint(x: w * 0.53, y: h * 0.46))
        p.closeSubpath()
        return p
    }
}

/// A gently bending footpath between two places.
struct FootPath: Shape {
    var from: CGPoint
    var to: CGPoint
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: from)
        let mid = CGPoint(x: (from.x + to.x) / 2, y: (from.y + to.y) / 2 + 40)
        p.addQuadCurve(to: to, control: mid)
        return p
    }
}

/// A paper tree: a trunk and a rounded crown.
struct PaperTree: View {
    var tone: Int
    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle().fill(Theme.woodDark).frame(width: 6, height: 16)
            Ellipse().fill(tone == 0 ? Theme.sageDeep : Color(hex: 0x4E7A5B)).frame(width: 34, height: 42)
                .offset(y: -12).paperCut(0.4)
        }
        .accessibilityHidden(true)
    }
}

/// A ribbon banner for names.
struct Banner: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let n: CGFloat = 10
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - n, y: r.midY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + n, y: r.midY))
        p.closeSubpath()
        return p
    }
}

/// A pennant flown over a finished place.
struct Pennant: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addRect(CGRect(x: r.minX, y: r.minY, width: 3, height: r.height))
        p.move(to: CGPoint(x: r.minX + 3, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.22))
        p.addLine(to: CGPoint(x: r.minX + 3, y: r.minY + r.height * 0.44))
        p.closeSubpath()
        return p
    }
}

/// Paper mist over a place that isn't open yet: a row of soft cloud lumps.
struct PaperMist: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addRoundedRect(in: r.insetBy(dx: 6, dy: r.height * 0.28), cornerSize: CGSize(width: 24, height: 24))
        for i in 0..<4 {
            let d = r.height * 0.55
            p.addEllipse(in: CGRect(x: r.minX + r.width * (0.04 + 0.22 * CGFloat(i)), y: r.minY + (i.isMultiple(of: 2) ? r.height * 0.08 : r.height * 0.18), width: d, height: d))
        }
        return p
    }
}

/// Each place's small stage set on the map.
struct PlaceSet: View {
    let chapter: ChapterID
    var body: some View {
        ZStack {
            Ellipse().fill(Theme.shadow.opacity(0.15)).frame(width: 130, height: 18).offset(y: 46)
            switch chapter {
            case "prologue": observatory
            case "garden": garden
            case "bridge": bridge
            case "goblin": cave
            case "ball": palace
            case "feast": tent
            case "moon": moon
            default: EmptyView()
            }
        }
        .frame(width: 150, height: 110)
        .accessibilityHidden(true)
    }

    private var observatory: some View {
        ZStack {
            Rectangle().fill(Theme.tan).frame(width: 40, height: 60).offset(y: 14).paperCut(0.4)
            Circle().trim(from: 0.5, to: 1).fill(Theme.clay).frame(width: 52, height: 52).offset(y: -2)
            Capsule().fill(Theme.woodDark).frame(width: 40, height: 8).rotationEffect(.degrees(-30)).offset(x: 20, y: -18)
            StarShape().fill(Theme.sun).frame(width: 22, height: 22).offset(x: -42, y: -34)
            StarShape().fill(Theme.sun).frame(width: 16, height: 16).offset(x: 46, y: -42)
            StarShape().fill(Theme.sun).frame(width: 12, height: 12).offset(x: -14, y: -48)
        }
    }

    private var garden: some View {
        ZStack {
            Capsule().fill(Theme.sageDeep).frame(width: 130, height: 34).offset(y: 30).paperCut(0.4)
            ForEach(0..<5, id: \.self) { i in
                let x = CGFloat(i - 2) * 24
                Rectangle().fill(Theme.sageDeep).frame(width: 4, height: 34).offset(x: x, y: 4)
                Circle().fill([Theme.poppy, Theme.rose, Theme.ochre][i % 3]).frame(width: 24, height: 24).offset(x: x, y: -14)
                    .paperCut(0.3)
                Circle().fill(Theme.sun).frame(width: 9, height: 9).offset(x: x, y: -14)
            }
        }
    }

    private var bridge: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 5, y: 80))
                p.addQuadCurve(to: CGPoint(x: 145, y: 80), control: CGPoint(x: 75, y: 10))
            }
            .stroke(Theme.wood, lineWidth: 16).paperCut(0.4)
            ForEach(0..<6, id: \.self) { i in
                Rectangle().fill(Theme.woodDark).frame(width: 6, height: 30)
                    .offset(x: CGFloat(i - 3) * 22 + 11, y: 18 + abs(CGFloat(i) - 2.5) * 6)
            }
        }
        .frame(width: 150, height: 110)
    }

    private var cave: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0x5B4B57)).frame(width: 130, height: 90).offset(y: 10).paperCut(0.4)
            Ellipse().fill(Theme.ink).frame(width: 50, height: 46).offset(y: 22)
            GemShape().fill(Theme.rose).frame(width: 22, height: 24).offset(x: 40, y: 30)
            GemShape().fill(Theme.sun).frame(width: 16, height: 18).offset(x: -42, y: 34)
        }
    }

    private var palace: some View {
        ZStack {
            Rectangle().fill(Theme.card).frame(width: 110, height: 56).offset(y: 22).paperCut(0.4)
            Triangle().fill(Theme.rose).frame(width: 124, height: 34).offset(y: -22)
            ForEach([-48, 48] as [CGFloat], id: \.self) { x in
                Rectangle().fill(Theme.card).frame(width: 18, height: 70).offset(x: x, y: 8)
                Triangle().fill(Theme.clay).frame(width: 24, height: 22).offset(x: x, y: -36)
            }
            RoundedRectangle(cornerRadius: 12).fill(Theme.clay).frame(width: 22, height: 30).offset(y: 34)
            ForEach([-18, 18] as [CGFloat], id: \.self) { x in
                Circle().fill(Theme.sun).frame(width: 12, height: 12).offset(x: x, y: 12)
            }
        }
    }

    private var tent: some View {
        ZStack {
            Triangle().fill(Theme.ochre).frame(width: 130, height: 70).offset(y: -8).paperCut(0.4)
            ForEach(0..<3, id: \.self) { i in
                Triangle().fill(Theme.card).frame(width: 20, height: 70).offset(x: CGFloat(i - 1) * 36, y: -8).opacity(0.65)
            }
            Rectangle().fill(Theme.wood).frame(width: 110, height: 10).offset(y: 34)
            ForEach(0..<4, id: \.self) { i in
                Circle().fill([Theme.rose, Theme.sun, Theme.poppy, Theme.sage][i]).frame(width: 14, height: 14)
                    .offset(x: CGFloat(i) * 26 - 39, y: 24)
            }
        }
    }

    private var moon: some View {
        ZStack {
            Circle().fill(Theme.card).frame(width: 64, height: 64).offset(x: -16, y: -20)
                .overlay(Circle().fill(Theme.nightPaperLow).frame(width: 52, height: 52).offset(x: 6, y: -28))
                .paperCut(0.4)
            GemShape().fill(Color(hex: 0x9FC6E0)).frame(width: 40, height: 54).offset(x: 30, y: 22).paperCut(0.4)
        }
    }
}
