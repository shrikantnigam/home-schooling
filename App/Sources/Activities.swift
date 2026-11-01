import KingdomCore
import SwiftUI

// One view per activity kind. Each shows the item at its CPA level:
// concrete = objects she moves or taps, pictorial = pictures, abstract = numerals.

extension SceneController {
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
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("bed.one")
                bondCircle(size: 170, dashed: true, glow: controller.hintStage == .modelHint) {
                    if controller.revealed {
                        if level == .abstract { Text("\(other)").font(Theme.numeral(60)).foregroundStyle(Theme.ink) }
                        else { flowers(other, size: 34) }
                    } else if level == .concrete {
                        flowers(controller.ui.counted.count, size: 34)
                    } else {
                        Text("?").font(Theme.numeral(60)).foregroundStyle(Theme.lavender)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("bed.two")
            }
            if level == .concrete && controller.ui.counted.count < other && !controller.revealed {
                // Flowers waiting for a bed: tap each to move it into bed two.
                HStack(spacing: 14) {
                    ForEach(0..<(other - controller.ui.counted.count), id: \.self) { i in
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
                .accessibilityElement(children: .contain)
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
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("equation")
    }

    private func term(_ n: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(n)").font(Theme.numeral(size))
            if showDots { DotPattern(n: n, dot: 12) }
        }
    }
}

// MARK: Chapter 2: the Bridge of Tens

/// Ten and some more: a bundle of ten plus loose planks (B1).
struct TensOnesActivity: View {
    let item: Item
    @ObservedObject var controller: SceneController

    var body: some View {
        let level = controller.level
        VStack(spacing: 24) {
            if level == .abstract && controller.hintStage == nil {
                EquationText(a: 10 * item.a, b: item.b, op: "and", showDots: false)
            } else {
                HStack(alignment: .bottom, spacing: 40) {
                    HStack(spacing: 16) {
                        ForEach(0..<item.a, id: \.self) { _ in TenBundle(glow: controller.hintStage == .modelHint) }
                    }
                    HStack(spacing: 10) {
                        ForEach(0..<item.b, id: \.self) { i in
                            let counted = controller.ui.counted.firstIndex(of: i)
                            Button { controller.tapObject(i, total: item.b) } label: {
                                ZStack(alignment: .top) {
                                    CounterSprite(style: .plank, size: 110)
                                        .frame(width: 60, height: 130)
                                        .shadow(color: controller.ui.countAlong == i ? Theme.gold : .clear, radius: 12)
                                    if let c = counted {
                                        badge(10 * item.a + c + 1)
                                    } else if controller.revealed || controller.ui.countAlong.map({ $0 >= i }) == true {
                                        badge(10 * item.a + i + 1)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(level != .concrete || controller.revealed)
                            .accessibilityIdentifier("obj.\(i)")
                        }
                    }
                }
            }
        }
    }

    private func badge(_ n: Int) -> some View {
        Text("\(n)").font(Theme.numeral(20)).foregroundStyle(.white)
            .padding(6).background(Circle().fill(Theme.deepLavender)).offset(y: -22)
    }
}

/// A pile to drag or tap things from (planks, treats, berries).
struct SourcePile: View {
    let style: CounterStyle
    let remaining: Int
    let place: () -> Void
    @State private var drag: CGSize = .zero

    var body: some View {
        ZStack {
            ForEach(0..<min(remaining, 6), id: \.self) { i in
                CounterSprite(style: style, second: true, size: 56)
                    .offset(x: CGFloat(i % 3) * 14 - 14, y: CGFloat(i / 3) * -10)
            }
            if remaining > 0 {
                Text("\(remaining)").font(Theme.numeral(18)).foregroundStyle(.white)
                    .padding(5).background(Circle().fill(Theme.deepLavender)).offset(x: 44, y: -34)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: 120, height: 90)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.75)))
        .offset(drag)
        .gesture(
            DragGesture(minimumDistance: 4)
                .onChanged { drag = $0.translation }
                .onEnded { v in
                    drag = .zero
                    if v.translation.height < -80 { place() }
                }
        )
        .onTapGesture { place() }
        .opacity(remaining > 0 ? 1 : 0.3)
        .accessibilityElement()
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("source")
    }
}

/// Two ten-frames side by side; the first fills before the second (AC-2b).
struct DoubleFrame: View {
    var first: Int
    var second: Int
    var style: CounterStyle
    var hintGlow = false
    var countIndex: Int?
    var countStart = 0
    var labels = false
    var cellSize: CGFloat = 54

    var body: some View {
        let total = first + second
        HStack(spacing: 18) {
            FlowerBox(first: min(first, 10), second: max(0, min(total, 10) - min(first, 10)), cellSize: cellSize,
                      hintGlow: hintGlow, countIndex: countIndex, countStart: countStart, labels: labels, style: style)
            FlowerBox(first: max(0, first - 10), second: max(0, total - 10) - max(0, first - 10), cellSize: cellSize,
                      countIndex: countIndex.map { $0 + countStart - 10 }, countStart: 0, labels: labels, style: style,
                      labelOffset: 10)
        }
    }
}

/// Add within 20 by making ten (B3, B5).
struct BridgeAddActivity: View {
    let item: Item
    @ObservedObject var controller: SceneController

    var body: some View {
        let level = controller.level
        VStack(spacing: 22) {
            if level == .abstract && controller.ui.help == nil && controller.hintStage == nil {
                EquationText(a: item.a, b: item.b, op: "+", showDots: controller.showDots(for: item.a))
                HelpButtons(controller: controller, line: false)
            } else {
                DoubleFrame(
                    first: item.a,
                    second: level == .concrete && controller.ui.help == nil ? controller.ui.planted : item.b,
                    style: .plank,
                    hintGlow: controller.hintStage == .modelHint,
                    countIndex: controller.ui.countAlong,
                    countStart: item.a,
                    labels: controller.revealed
                )
                if level == .concrete && controller.ui.help == nil {
                    SourcePile(style: .plank, remaining: max(0, item.b - controller.ui.planted)) { controller.plantSeed() }
                }
            }
        }
    }
}

// MARK: Chapters 3 to 6: shared counter and line activities

extension Item {
    /// What the counters look like in each chapter.
    var counterStyle: CounterStyle {
        switch kind {
        case .takeAway, .compare, .subtraction, .hopBack, .fractionOf: return .gem
        case .groups, .array, .multiply, .skipHop: return .guest
        case .share, .divide: return .treat
        case .groupInto: return .berry
        case .parts, .fractionLine: return .crystal
        case .tensOnes, .bridgeAdd: return .plank
        default: return .flower
        }
    }
}

/// Counter activities for subtraction, multiplication, division and fractions of a set.
/// Concrete: she taps or places the objects. Pictorial: the same picture, still. Abstract: numerals.
struct CounterActivity: View {
    let item: Item
    @ObservedObject var controller: SceneController

    var body: some View {
        let level = controller.level
        let abstractOnly = (level == .abstract || item.kind == .subtraction || item.kind == .multiply || item.kind == .divide)
            && controller.ui.help == nil && controller.hintStage == nil
        VStack(spacing: 20) {
            if abstractOnly {
                EquationText(a: item.a, b: item.b, op: item.operatorSymbol, showDots: false)
                if item.kind == .parts || item.kind == .fractionOf {
                    EmptyView()
                } else {
                    HelpButtons(controller: controller, line: false)
                }
            } else {
                picture(level: level)
            }
        }
    }

    @ViewBuilder
    private func picture(level: CPALevel) -> some View {
        let concrete = level == .concrete && controller.ui.help == nil
        switch item.kind {
        case .takeAway, .subtraction:
            // a gems; the goblin's sack takes b. Concrete: tap b gems to give them away.
            VStack(spacing: 16) {
                tapRow(count: item.a, crossed: concrete ? Set(controller.ui.counted) : Set(0..<item.b), tappable: concrete)
                SackView(count: concrete ? controller.ui.counted.count : item.b)
            }
        case .compare:
            VStack(alignment: .leading, spacing: 14) {
                matchRow(count: item.a, matched: item.b, tappable: concrete, label: "Siara")
                matchRow(count: item.b, matched: item.b, tappable: false, label: "Goblin")
            }
        case .groups, .multiply:
            HStack(spacing: 22) {
                ForEach(0..<item.a, id: \.self) { g in
                    groupCircle(index: g, size: item.b, tappableOffset: g * item.b, tappable: concrete)
                }
            }
        case .array:
            VStack(spacing: 10) {
                ForEach(0..<item.a, id: \.self) { r in
                    Button { controller.tapObject(r, total: item.a) } label: {
                        HStack(spacing: 6) {
                            ForEach(0..<item.b, id: \.self) { _ in CounterSprite(style: .guest, second: controller.ui.counted.contains(r), size: 44) }
                            if let k = controller.ui.counted.firstIndex(of: r) { badge(item.b * (k + 1)) }
                        }
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(controller.ui.countAlong == r ? 0.95 : 0.6)))
                    }
                    .buttonStyle(.plain)
                    .disabled(!concrete)
                    .accessibilityIdentifier("obj.\(r)")
                }
            }
        case .share, .divide, .groupInto, .fractionOf:
            let containers = item.kind == .groupInto ? item.answer : item.b
            let placed = concrete ? controller.ui.planted : item.a
            VStack(spacing: 18) {
                HStack(spacing: 18) {
                    ForEach(0..<containers, id: \.self) { c in
                        let inThis = item.kind == .groupInto
                            ? max(0, min(item.b, placed - c * item.b))
                            : placed / containers + (c < placed % containers ? 1 : 0)
                        VStack(spacing: 4) {
                            LazyVGrid(columns: Array(repeating: GridItem(.fixed(34), spacing: 2), count: 3), spacing: 2) {
                                ForEach(0..<inThis, id: \.self) { _ in CounterSprite(style: item.counterStyle, size: 34) }
                            }
                            .frame(width: 112, height: 96)
                            .background(Ellipse().fill(Color.white.opacity(0.85)))
                            .overlay(Ellipse().stroke(c == 0 && controller.hintStage == .modelHint ? Theme.gold : Theme.lavender, lineWidth: 3))
                            .shadow(color: c == 0 && controller.hintStage != nil ? Theme.gold : .clear, radius: 10)
                        }
                    }
                }
                if concrete {
                    SourcePile(style: item.counterStyle, remaining: max(0, item.a - controller.ui.planted)) { controller.plantSeed() }
                }
            }
        case .parts:
            // The crystal cut into b equal parts; tap each part to count it.
            HStack(spacing: 6) {
                ForEach(0..<item.b, id: \.self) { i in
                    Button { controller.tapObject(i, total: item.b) } label: {
                        ZStack {
                            Rectangle().fill(controller.ui.counted.contains(i) ? Theme.gold : Color(hex: 0xBFD8FF))
                                .frame(width: 360 / CGFloat(item.b), height: 220)
                            if let k = controller.ui.counted.firstIndex(of: i) { badge(k + 1) }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!concrete)
                    .accessibilityIdentifier("obj.\(i)")
                }
            }
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 6))
            .frame(width: 380, height: 260)
        default:
            EmptyView()
        }
    }

    private func tapRow(count: Int, crossed: Set<Int>, tappable: Bool) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(64), spacing: 8), count: min(count, 10)), spacing: 8) {
            ForEach(0..<count, id: \.self) { i in
                Button { controller.tapObject(i, total: item.b) } label: {
                    CounterSprite(style: item.counterStyle, size: 52)
                        .opacity(crossed.contains(i) ? 0.25 : 1)
                        .overlay(crossed.contains(i) ? Image(systemName: "arrow.down").foregroundStyle(Theme.muted) : nil)
                        .frame(width: 64, height: 64)
                        .shadow(color: controller.ui.countAlong == i ? Theme.gold : .clear, radius: 10)
                }
                .buttonStyle(.plain)
                .disabled(!tappable || crossed.contains(i))
                .accessibilityIdentifier("obj.\(i)")
            }
        }
    }

    private func matchRow(count: Int, matched: Int, tappable: Bool, label: String) -> some View {
        HStack(spacing: 8) {
            Text(label).font(Theme.title(20)).foregroundStyle(Theme.ink).frame(width: 90, alignment: .leading)
            ForEach(0..<count, id: \.self) { i in
                let extra = i >= matched
                let k = extra ? i - matched : -1
                Button { if extra { controller.tapObject(k, total: count - matched) } } label: {
                    ZStack(alignment: .top) {
                        CounterSprite(style: .gem, second: label != "Siara", size: 48)
                            .frame(width: 56, height: 60)
                            .background(RoundedRectangle(cornerRadius: 10).fill(extra && controller.hintStage == .modelHint ? Theme.gold.opacity(0.35) : .clear))
                        if extra, let c = controller.ui.counted.firstIndex(of: k) { badge(c + 1) }
                    }
                }
                .buttonStyle(.plain)
                .disabled(!tappable || !extra)
                .accessibilityIdentifier(extra && tappable ? "obj.\(k)" : "gem.\(label).\(i)")
            }
        }
    }

    private func groupCircle(index g: Int, size: Int, tappableOffset: Int, tappable: Bool) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(40), spacing: 4), count: min(size, 3)), spacing: 4) {
            ForEach(0..<size, id: \.self) { j in
                let idx = tappableOffset + j
                Button { controller.tapObject(idx, total: item.a * item.b) } label: {
                    ZStack(alignment: .top) {
                        CounterSprite(style: .guest, second: controller.ui.counted.contains(idx), size: 40)
                        if let c = controller.ui.counted.firstIndex(of: idx) { badge(c + 1).scaleEffect(0.7) }
                    }
                }
                .buttonStyle(.plain)
                .disabled(!tappable)
                .accessibilityIdentifier("obj.\(idx)")
            }
        }
        .padding(14)
        .background(Circle().fill(Color.white.opacity(0.8)))
        .overlay(Circle().stroke(controller.hintStage == .modelHint && g == 0 ? Theme.gold : Theme.lavender, lineWidth: 3))
    }

    private func badge(_ n: Int) -> some View {
        Text("\(n)").font(Theme.numeral(18)).foregroundStyle(.white)
            .padding(5).background(Circle().fill(Theme.deepLavender)).offset(y: -18)
    }
}

/// The goblin's sack, showing how many gems went in.
struct SackView: View {
    var count: Int
    var body: some View {
        ZStack {
            Ellipse().fill(Theme.soil).frame(width: 120, height: 90)
            Text("\(count)").font(Theme.numeral(30)).foregroundStyle(.white)
        }
        .accessibilityIdentifier("sack")
    }
}

/// Line activities for hopping back, skip counting and fractions on the moonbeam.
struct LineOpsActivity: View {
    let item: Item
    @ObservedObject var controller: SceneController

    var body: some View {
        let level = controller.level
        let concrete = level == .concrete
        let done = controller.ui.hopsDone
        VStack(spacing: 12) {
            HStack(spacing: 24) {
                if item.kind == .fractionLine {
                    FractionText(numerator: item.a, denominator: item.b)
                } else if level == .abstract {
                    EquationText(a: item.a, b: item.b, op: item.operatorSymbol, showDots: false, size: 56)
                }
                if concrete, case .hop(let n) = item.concreteStep {
                    Button { controller.hop() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: item.kind == .hopBack ? "arrow.uturn.left" : "arrow.right")
                                .font(.system(size: 30, weight: .bold))
                            Text("\(max(0, n - done))").font(Theme.numeral(30))
                        }
                        .foregroundStyle(Theme.ink)
                        .frame(width: 120, height: 70)
                        .background(Capsule().fill(Theme.gold))
                    }
                    .disabled(done >= n)
                    .accessibilityIdentifier("hopper")
                }
            }
            StoneLine(
                top: item.top,
                sparkleAt: controller.revealed ? item.answer : sparklePosition(done: done, level: level),
                hopFrom: hopFrom(done: done, level: level),
                hops: hopCount(done: done, level: level),
                hopSize: item.kind == .skipHop ? item.b : 1,
                showNumbers: level == .abstract && controller.hintStage == nil && item.kind != .fractionLine ? [0, item.top / 2, item.top] : nil,
                showDots: false,
                glowStone: controller.revealed ? item.answer : nil,
                countStone: nil,
                enabled: controller.readyToAnswer,
                label: item.kind == .fractionLine ? fractionLabel : nil
            ) { controller.touchStone($0) }
            .frame(height: 300)
        }
        .padding(.trailing, 30)
    }

    private func fractionLabel(_ i: Int) -> String {
        i == 0 ? "0" : (i == item.b ? "1" : "\(i)/\(item.b)")
    }

    private func sparklePosition(done: Int, level: CPALevel) -> Int {
        switch item.kind {
        case .hopBack: return item.a - (level == .concrete ? done : 0)
        case .skipHop: return item.b * (level == .concrete ? done : 0)
        default: return 0
        }
    }

    private func hopCount(done: Int, level: CPALevel) -> Int {
        let full = item.kind == .skipHop ? item.a : item.b
        if item.kind == .fractionLine { return 0 }
        if controller.revealed || controller.hintStage != nil { return full }
        switch level {
        case .concrete: return done
        case .pictorial: return full
        case .abstract: return 0
        }
    }

    private func hopFrom(done: Int, level: CPALevel) -> Int? {
        switch item.kind {
        case .hopBack: return item.a - hopCount(done: done, level: level)
        case .skipHop: return 0
        default: return nil
        }
    }
}

struct FractionText: View {
    let numerator: Int
    let denominator: Int
    var body: some View {
        VStack(spacing: 0) {
            Text("\(numerator)").font(Theme.numeral(48))
            Rectangle().fill(Theme.ink).frame(width: 50, height: 4)
            Text("\(denominator)").font(Theme.numeral(48))
        }
        .foregroundStyle(Theme.ink)
        .padding(.horizontal, 24).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.9)))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("fraction")
    }
}
