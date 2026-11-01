import KingdomCore
import SwiftUI

// One view per activity kind. Each shows the item at its CPA level:
// concrete = objects she moves or taps, pictorial = pictures, abstract = numerals.

private extension SceneController {
    var hintStage: HintStage? { if case .hint(let s) = mood { return s } else { return nil } }
    var revealed: Bool { mood == .hint(.showAnswer) || mood == .correct }
}

/// Fixed, non-overlapping positions for up to 20 counters (counters never overlap).
private func counterPositions(_ n: Int, in size: CGSize, spacing: CGFloat) -> [CGPoint] {
    let cols = n <= 5 ? n : Int(ceil(Double(n) / 2))
    let rows = n <= 5 ? 1 : 2
    var pts: [CGPoint] = []
    var rnd = SeededDots(seed: UInt64(n * 13 + 5))
    let w = CGFloat(cols) * spacing, h = CGFloat(rows) * spacing
    let ox = (size.width - w) / 2 + spacing / 2, oy = (size.height - h) / 2 + spacing / 2
    for i in 0..<n {
        let r = i / cols, c = i % cols
        let jx = (rnd.next() - 0.5) * spacing * 0.25, jy = (rnd.next() - 0.5) * spacing * 0.3
        pts.append(CGPoint(x: ox + CGFloat(c) * spacing + jx, y: oy + CGFloat(r) * spacing + jy))
    }
    return pts
}

// MARK: P1, P2, P4: stars

struct StarsActivity: View {
    let item: Item
    @ObservedObject var controller: SceneController

    private var tappable: Bool {
        guard !controller.revealed else { return false }
        if controller.level == .concrete { return true }
        return controller.hintStage == .modelHint
    }

    var body: some View {
        GeometryReader { geo in
            let pts = counterPositions(item.a, in: geo.size, spacing: min(120, geo.size.width / CGFloat(max(5, (item.a + 1) / 2 + 1))))
            ZStack {
                if item.kind == .howMany {
                    CloudShape().fill(Color.white.opacity(0.18))
                        .frame(width: geo.size.width * 0.92, height: geo.size.height * 0.8)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
                ForEach(0..<item.a, id: \.self) { i in
                    let counted = controller.ui.counted.firstIndex(of: i)
                    let lit = counted != nil || item.kind != .countTap || controller.level != .concrete || controller.revealed
                    Button { controller.tapObject(i, total: item.a) } label: {
                        ZStack {
                            StarSprite(lit: lit, highlighted: controller.ui.countAlong == i, size: 86)
                            if let c = counted, controller.level == .concrete || controller.hintStage != nil {
                                Text("\(c + 1)").font(Theme.numeral(20)).foregroundStyle(.white)
                                    .padding(6).background(Circle().fill(Theme.deepLavender)).offset(x: 34, y: -34)
                            } else if controller.revealed || controller.ui.countAlong.map({ $0 >= i }) == true {
                                Text("\(i + 1)").font(Theme.numeral(20)).foregroundStyle(.white)
                                    .padding(6).background(Circle().fill(Theme.deepLavender)).offset(x: 34, y: -34)
                            }
                        }
                        .frame(width: 100, height: 100)
                    }
                    .buttonStyle(.plain)
                    .disabled(!tappable)
                    .accessibilityIdentifier("star.\(i)")
                    .position(pts[i])
                }
                if item.kind == .quickLook && controller.ui.hidden && !controller.revealed {
                    CloudShape().fill(Color.white)
                        .frame(width: geo.size.width * 0.9, height: geo.size.height * 0.75)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        .accessibilityIdentifier("quickLook.cloud")
                }
            }
        }
        .frame(height: 360)
    }
}

struct CloudShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addRoundedRect(in: r.insetBy(dx: r.width * 0.05, dy: r.height * 0.2), cornerSize: CGSize(width: r.height * 0.3, height: r.height * 0.3))
        for i in 0..<4 {
            let d = r.height * 0.5
            p.addEllipse(in: CGRect(x: r.minX + r.width * (0.12 + Double(i) * 0.2), y: r.minY + (i.isMultiple(of: 2) ? 0 : r.height * 0.08), width: d, height: d))
        }
        return p
    }
}

// MARK: P3: find a number on the line

struct FindOnLineActivity: View {
    let item: Item
    @ObservedObject var controller: SceneController

    var body: some View {
        let level = controller.level
        let numbers: Set<Int>? = (level == .abstract && controller.hintStage == nil) ? [0, 5, item.top] : nil
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Text("\(item.a)").font(Theme.numeral(64)).foregroundStyle(.white)
                if level != .abstract { DotPattern(n: item.a, dot: 12, color: Theme.gold) }
            }
            StoneLine(
                top: item.top,
                sparkleAt: controller.revealed ? item.answer : 0,
                showNumbers: numbers,
                showDots: level == .concrete || controller.hintStage == .modelHint,
                glowStone: controller.revealed ? item.answer : nil,
                countStone: controller.ui.countAlong.map { $0 + 1 },
                enabled: controller.readyToAnswer
            ) { controller.touchStone($0) }
            .frame(height: 300)
        }
        .padding(.trailing, 30)
    }
}

// MARK: G1: plant more flowers (ten-frame)

/// Seeds she drags up into the flower box (or taps, as a fallback).
struct SeedBag: View {
    let remaining: Int
    let plant: () -> Void
    @State private var drag: [Int: CGSize] = [:]

    var body: some View {
        HStack(spacing: 18) {
            ForEach(0..<remaining, id: \.self) { i in
                SeedSprite(size: 54)
                    .frame(width: 72, height: 72)
                    .background(Circle().fill(Color.white.opacity(0.7)))
                    .offset(drag[i] ?? .zero)
                    .gesture(
                        DragGesture(minimumDistance: 4)
                            .onChanged { drag[i] = $0.translation }
                            .onEnded { v in
                                drag[i] = nil
                                if v.translation.height < -80 { plant() }
                            }
                    )
                    .onTapGesture { plant() }
                    .accessibilityIdentifier("seed.\(i)")
                    .accessibilityAddTraits(.isButton)
            }
        }
        .frame(height: 80)
        .accessibilityIdentifier("seedBag")
    }
}

struct AddMoreActivity: View {
    let item: Item
    @ObservedObject var controller: SceneController

    var body: some View {
        let level = controller.level
        VStack(spacing: 22) {
            if level == .abstract && controller.ui.help == nil && controller.hintStage == nil {
                EquationText(a: item.a, b: item.b, op: "+", showDots: controller.showDots(for: item.a))
                HelpButtons(controller: controller, line: false)
            } else {
                FlowerBox(
                    first: item.a,
                    second: level == .concrete ? controller.ui.planted : item.b,
                    hintGlow: controller.hintStage == .modelHint,
                    countIndex: controller.ui.countAlong,
                    countStart: item.a,
                    labels: controller.revealed
                )
                if level == .concrete {
                    SeedBag(remaining: max(0, item.b - controller.ui.planted)) { controller.plantSeed() }
                }
            }
        }
    }
}

// MARK: G4: make ten

struct MakeTenActivity: View {
    let item: Item
    @ObservedObject var controller: SceneController

    var body: some View {
        let level = controller.level
        VStack(spacing: 22) {
            if level == .abstract && controller.ui.help == nil && controller.hintStage == nil {
                HStack(spacing: 18) {
                    Text("\(item.a) + ").font(Theme.numeral(80))
                    RoundedRectangle(cornerRadius: 16).stroke(Theme.lavender, style: StrokeStyle(lineWidth: 5, dash: [10, 8]))
                        .frame(width: 90, height: 100)
                    Text(" = 10").font(Theme.numeral(80))
                }
                .foregroundStyle(Theme.ink)
                HelpButtons(controller: controller, line: false)
            } else {
                FlowerBox(
                    first: item.a,
                    second: level == .concrete ? controller.ui.planted : (controller.revealed ? 10 - item.a : 0),
                    hintGlow: controller.hintStage == .modelHint || level == .pictorial,
                    countIndex: controller.ui.countAlong,
                    countStart: item.a,
                    labels: controller.revealed
                )
                if level == .concrete {
                    SeedBag(remaining: max(0, 10 - item.a - controller.ui.planted)) { controller.plantSeed() }
                }
                FountainView(awake: controller.mood == .correct)
            }
        }
    }
}

struct FountainView: View {
    var awake: Bool
    var body: some View {
        ZStack(alignment: .bottom) {
            if awake {
                ForEach(0..<3, id: \.self) { i in
                    Capsule().fill(Theme.water).frame(width: 10, height: 50)
                        .rotationEffect(.degrees(Double(i - 1) * 25), anchor: .bottom)
                }
                .offset(y: -30)
            }
            RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0xC9C0EA)).frame(width: 120, height: 34)
        }
        .frame(height: 80)
        .accessibilityIdentifier(awake ? "fountain.awake" : "fountain.asleep")
    }
}

// MARK: G2: flower pairs (number bonds)

struct NumberBondActivity: View {
    let item: Item
    @ObservedObject var controller: SceneController

    var body: some View {
        let level = controller.level
        let other = item.a - item.b
        VStack(spacing: 14) {
            // Whole
            bondCircle(size: 150) {
                if level == .abstract { Text("\(item.a)").font(Theme.numeral(60)).foregroundStyle(Theme.ink) }
                else { flowers(item.a, size: 30) }
            }
            HStack(spacing: 110) {
                bondCircle(size: 170) {
                    if level == .abstract { Text("\(item.b)").font(Theme.numeral(60)).foregroundStyle(Theme.ink) }
                    else { flowers(item.b, size: 34) }
                }
                .accessibilityIdentifier("bed.one")
                bondCircle(size: 170, dashed: true, glow: controller.hintStage == .modelHint) {
                    if controller.revealed {
                        if level == .abstract { Text("\(other)").font(Theme.numeral(60)).foregroundStyle(Theme.ink) }
                        else { flowers(other, size: 34) }
                    } else if level == .concrete {
                        flowers(controller.ui.moved, size: 34)
                    } else {
                        Text("?").font(Theme.numeral(60)).foregroundStyle(Theme.lavender)
                    }
                }
                .accessibilityIdentifier("bed.two")
            }
            if level == .concrete && controller.ui.moved < other && !controller.revealed {
                // Flowers waiting for a bed: tap each to move it into bed two.
                HStack(spacing: 14) {
                    ForEach(0..<(other - controller.ui.moved), id: \.self) { i in
                        Button { controller.moveFlower() } label: {
                            FlowerSprite(color: Theme.gold, size: 54).frame(width: 70, height: 70)
                                .background(Circle().fill(Color.white.opacity(0.6)))
                        }
                        .accessibilityIdentifier("pot.\(i)")
                    }
                }
            }
            if !controller.foundBonds.isEmpty {
                HStack(spacing: 18) {
                    ForEach(Array(controller.foundBonds.enumerated()), id: \.offset) { _, pair in
                        Text("\(pair[0]) and \(pair[1])").font(Theme.numeral(22)).foregroundStyle(Theme.ink)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Capsule().fill(Color.white.opacity(0.85)))
                    }
                }
                .accessibilityIdentifier("foundBonds")
            }
        }
    }

    private func flowers(_ n: Int, size: CGFloat) -> some View {
        let cols = min(max(n, 1), 3)
        return LazyVGrid(columns: Array(repeating: GridItem(.fixed(size), spacing: 4), count: cols), spacing: 4) {
            ForEach(0..<n, id: \.self) { _ in FlowerSprite(size: size) }
        }
        .frame(maxWidth: CGFloat(cols) * (size + 4))
    }

    private func bondCircle<C: View>(size: CGFloat, dashed: Bool = false, glow: Bool = false, @ViewBuilder _ c: () -> C) -> some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.9))
            Circle().stroke(glow ? Theme.gold : Theme.lavender, style: StrokeStyle(lineWidth: 5, dash: dashed ? [10, 8] : []))
            c()
        }
        .frame(width: size, height: size)
        .shadow(color: glow ? Theme.gold : .clear, radius: 12)
    }
}

// MARK: G3: hopping path

struct HopActivity: View {
    let item: Item
    @ObservedObject var controller: SceneController

    var body: some View {
        let level = controller.level
        let hops = level == .concrete ? controller.ui.hopsDone : (level == .pictorial || controller.revealed || controller.hintStage != nil ? item.b : 0)
        VStack(spacing: 12) {
            HStack(spacing: 24) {
                if level == .abstract {
                    EquationText(a: item.a, b: item.b, op: "+", showDots: false, size: 56)
                }
                if level == .concrete {
                    // Horseshoes: the second number made concrete, one used per hop.
                    HStack(spacing: 12) {
                        ForEach(0..<item.b, id: \.self) { i in
                            Button { controller.hop() } label: {
                                Image(systemName: "u.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(i < controller.ui.hopsDone ? Color.white.opacity(0.4) : Theme.gold)
                                    .rotationEffect(.degrees(180))
                                    .frame(width: 70, height: 70)
                            }
                            .disabled(i < controller.ui.hopsDone)
                            .accessibilityIdentifier("horseshoe.\(i)")
                        }
                    }
                }
            }
            StoneLine(
                top: item.top,
                sparkleAt: controller.revealed ? item.answer : item.a + (level == .concrete ? controller.ui.hopsDone : 0),
                hopFrom: item.a,
                hops: hops,
                showNumbers: level == .abstract && controller.hintStage == nil ? [0, item.a, 5, item.top] : nil,
                showDots: false,
                glowStone: controller.revealed ? item.answer : (controller.hintStage == .modelHint ? item.a : nil),
                countStone: controller.ui.countAlong.map { item.a + $0 + 1 },
                enabled: controller.readyToAnswer
            ) { controller.touchStone($0) }
            .frame(height: 300)
        }
        .padding(.trailing, 30)
    }
}

// MARK: G5: garden festival (abstract with support)

struct EquationActivity: View {
    let item: Item
    @ObservedObject var controller: SceneController

    var body: some View {
        VStack(spacing: 20) {
            EquationText(a: item.a, b: item.b, op: "+", showDots: controller.showDots(for: item.a) && controller.showDots(for: item.b))
            switch controller.ui.help {
            case .flowerBox?:
                FlowerBox(first: item.a, second: item.b, cellSize: 60, countIndex: controller.ui.countAlong, countStart: item.a,
                          labels: controller.revealed)
            case .hoppingPath?:
                StoneLine(top: item.top, sparkleAt: item.a + item.b, hopFrom: item.a, hops: item.b, enabled: false) { _ in }
                    .frame(height: 220)
            case nil:
                if controller.hintStage != nil {
                    FlowerBox(first: item.a, second: item.b, cellSize: 60, hintGlow: controller.hintStage == .modelHint,
                              countIndex: controller.ui.countAlong, countStart: item.a, labels: controller.revealed)
                } else {
                    HelpButtons(controller: controller, line: true)
                }
            }
        }
    }
}

/// "If you want help, tap the flower box or the hopping path." Using help means not first-try.
struct HelpButtons: View {
    @ObservedObject var controller: SceneController
    var line: Bool
    var body: some View {
        HStack(spacing: 30) {
            Button { controller.openHelp(.flowerBox) } label: {
                FlowerBox(first: 2, second: 1, cellSize: 22).frame(width: 160, height: 80)
            }
            .accessibilityIdentifier("help.flowerBox")
            .accessibilityLabel("Show the flower box")
            if line {
                Button { controller.openHelp(.hoppingPath) } label: {
                    HStack(spacing: 6) { ForEach(0..<5, id: \.self) { _ in Ellipse().fill(Color(hex: 0xEDEAF6)).frame(width: 26, height: 18) } }
                        .frame(width: 180, height: 80)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.7)))
                }
                .accessibilityIdentifier("help.hoppingPath")
                .accessibilityLabel("Show the hopping path")
            }
        }
        .disabled(!controller.readyToAnswer)
    }
}

struct EquationText: View {
    let a: Int
    let b: Int
    let op: String
    var showDots: Bool
    var size: CGFloat = 96
    var body: some View {
        HStack(alignment: .top, spacing: 22) {
            term(a)
            Text(op).font(Theme.numeral(size))
            term(b)
        }
        .foregroundStyle(Theme.ink)
        .padding(.horizontal, 30).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 26).fill(Color.white.opacity(0.88)))
        .accessibilityIdentifier("equation")
    }

    private func term(_ n: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(n)").font(Theme.numeral(size))
            if showDots { DotPattern(n: n, dot: 12) }
        }
    }
}
