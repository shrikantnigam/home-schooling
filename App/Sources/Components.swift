import KingdomCore
import SwiftUI

/// The same three corners on every child screen (style frame):
/// castle top left, ear (replay) bottom left, grown-ups lock top right.
struct ChildCorners: View {
    var onCastle: (() -> Void)?
    var onEar: (() -> Void)?
    var onLock: () -> Void
    var dark = false
    /// Back to the Home School home screen, shown top left where there is no castle button (the castle itself).
    var onHome: (() -> Void)? = nil

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                if let onCastle {
                    Button(action: onCastle) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14).fill(Theme.card).frame(width: 72, height: 72).paperCut()
                            CastleArt().scaleEffect(0.11).frame(width: 60, height: 60)
                        }
                    }
                    .accessibilityIdentifier("corner.castle")
                    .accessibilityLabel("Back to the castle")
                } else if let onHome {
                    Button(action: onHome) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14).fill(Theme.card).frame(width: 72, height: 72).paperCut()
                            Image(systemName: "house.fill").font(.system(size: 32, weight: .bold)).foregroundStyle(Theme.clay)
                        }
                    }
                    .accessibilityIdentifier("corner.home")
                    .accessibilityLabel("Home School")
                }
                Spacer()
                // Deliberately quiet: small and low contrast so it does not invite a child's tap.
                Button(action: onLock) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(dark ? Color.white.opacity(0.45) : Theme.muted.opacity(0.55))
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(dark ? Color.white.opacity(0.08) : Color.white.opacity(0.5)))
                }
                .accessibilityIdentifier("corner.lock")
                .accessibilityLabel("Grown-ups")
            }
            Spacer()
            HStack {
                if let onEar {
                    Button(action: onEar) {
                        ZStack {
                            Circle().fill(Theme.card).frame(width: 88, height: 88).paperCut()
                            Image(systemName: "ear.fill").font(.system(size: 38, weight: .bold)).foregroundStyle(Theme.clay)
                        }
                    }
                    .accessibilityIdentifier("corner.ear")
                    .accessibilityLabel("Hear it again")
                }
                Spacer()
            }
        }
        .padding(20)
    }
}

/// Big glowing star button to go on. Appears after the lines are spoken.
struct NextButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(Theme.gold).frame(width: 110, height: 110).paperCut()
                Image(systemName: "arrow.right").font(.system(size: 46, weight: .heavy)).foregroundStyle(Theme.ink)
            }
        }
        .glow()
        .accessibilityIdentifier("next")
        .accessibilityLabel("Next")
    }
}

/// Spoken line as optional text (parent setting; always on during QA runs).
struct Subtitle: View {
    @ObservedObject var speech: SpeechPlayer
    var show: Bool
    var body: some View {
        if show, let line = speech.current {
            Text(line.text)
                .font(Theme.body(20))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 18).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card.opacity(0.95)).paperCut(0.6))
                .frame(maxWidth: 760)
                .accessibilityIdentifier("subtitle")
        }
    }
}

/// Numeral tile that always carries its dots the first time (style frame).
/// Touch once to hear it (lavender ring), touch again to choose.
struct NumeralTile: View {
    let n: Int
    var dots: Bool
    var heard: Bool
    var glow: Bool = false
    var dimmed: Bool = false
    var wobble: CGFloat = 0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(n)").font(Theme.numeral(54)).foregroundStyle(Theme.ink)
                if dots { DotPattern(n: n, dot: n > 10 ? 6 : 9) }
            }
            .frame(width: 112, height: 124)
            .background(RoundedRectangle(cornerRadius: 18).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(heard ? Theme.clay : Theme.tan, lineWidth: heard ? 6 : 3))
            .shadow(color: glow ? Theme.gold : Theme.shadow.opacity(0.28), radius: glow ? 18 : 5, y: glow ? 3 : 6)
            .opacity(dimmed ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .modifier(Wobble(animatableData: wobble))
        .accessibilityIdentifier("tile.\(n)")
        .accessibilityLabel("\(n)")
    }
}

/// Ten-frame drawn as a flower box (2 rows of 5).
struct FlowerBox: View {
    /// Flowers already awake.
    var first: Int
    /// Added flowers, drawn in a second colour so the two parts stay visible.
    var second: Int = 0
    var cellSize: CGFloat = 78
    /// Model hint: empty cells dim and full ones glow.
    var hintGlow = false
    /// Worked step: the cell being counted.
    var countIndex: Int?
    var countStart = 0
    var labels = false
    /// What sits in the cells: flowers in the Garden, planks on the Bridge, gems with the Goblin.
    var style: CounterStyle = .flower
    /// First cell's number, so a second ten-frame counts 11 to 20.
    var labelOffset = 0

    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<2, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { col in
                        cell(row * 5 + col)
                    }
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 22).fill(Theme.soil))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.soilDark, lineWidth: 4))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("flowerBox")
    }

    private func cell(_ i: Int) -> some View {
        let filled = i < first + second
        let counting = countIndex.map { i == countStart + $0 } ?? false
        return ZStack {
            RoundedRectangle(cornerRadius: 12).fill(Theme.soilDark.opacity(filled ? 0.5 : (hintGlow ? 0.2 : 0.65)))
            if filled {
                CounterSprite(style: style, second: i >= first, size: cellSize * 0.72)
            } else if hintGlow {
                RoundedRectangle(cornerRadius: 12).stroke(Theme.gold, style: StrokeStyle(lineWidth: 3, dash: [6, 5]))
            }
            if labels || counting {
                Text("\(labelOffset + i + 1)").font(Theme.numeral(18)).foregroundStyle(.white)
                    .padding(4).background(Circle().fill(Theme.deepLavender))
                    .offset(x: cellSize * 0.3, y: -cellSize * 0.3)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .shadow(color: (hintGlow && filled) || counting ? Theme.gold : .clear, radius: 10)
        .scaleEffect(counting ? 1.12 : 1)
    }
}

/// Number line as stepping stones from 0 to `top`.
struct StoneLine: View {
    var top: Int = 10
    /// Where Sparkle stands, if on the line.
    var sparkleAt: Int?
    /// Hops drawn as dashed arcs from `hopFrom`.
    var hopFrom: Int?
    var hops: Int = 0
    /// Stones per hop (skip counting hops several stones at once).
    var hopSize: Int = 1
    var showNumbers: Set<Int>? = nil
    var showDots = false
    var glowStone: Int?
    var countStone: Int?
    var enabled = true
    /// Custom stone labels, e.g. fractions on the moonbeam.
    var label: ((Int) -> String)? = nil
    var onTap: (Int) -> Void

    var body: some View {
        GeometryReader { geo in
            let n = top + 1
            let step = geo.size.width / CGFloat(n)
            let stone = min(step * 0.86, 96)
            let baseY = geo.size.height * 0.68
            ZStack(alignment: .topLeading) {
                if let from = hopFrom, hops > 0 {
                    Path { p in
                        for h in 0..<hops {
                            let x0 = step * (CGFloat(from + h * hopSize) + 0.5)
                            let x1 = step * (CGFloat(from + (h + 1) * hopSize) + 0.5)
                            p.move(to: CGPoint(x: x0, y: baseY - stone * 0.45))
                            p.addQuadCurve(to: CGPoint(x: x1, y: baseY - stone * 0.45),
                                           control: CGPoint(x: (x0 + x1) / 2, y: baseY - stone * (1.2 + 0.4 * CGFloat(hopSize))))
                        }
                    }
                    .stroke(Theme.lavender, style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [8, 7]))
                }
                ForEach(0..<n, id: \.self) { i in
                    Button { onTap(i) } label: {
                        VStack(spacing: 2) {
                            if showNumbers?.contains(i) ?? true {
                                Text(label?(i) ?? "\(i)").font(Theme.numeral(top > 10 ? 22 : 30)).foregroundStyle(Theme.ink)
                                    .minimumScaleFactor(0.5)
                            } else {
                                Text(" ").font(Theme.numeral(30))
                            }
                            if showDots && i > 0 { DotPattern(n: i, dot: top > 10 ? 3 : 5) }
                        }
                        .frame(width: stone, height: stone * 0.8)
                        .background(Ellipse().fill(Color(hex: 0xEDEAF6)))
                        .overlay(Ellipse().stroke(glowStone == i ? Theme.gold : Color(hex: 0xBDB6D6), lineWidth: glowStone == i ? 6 : 3))
                        .shadow(color: glowStone == i || countStone == i ? Theme.gold : .clear, radius: 12)
                        .frame(minWidth: Theme.minTarget, minHeight: Theme.minTarget)
                    }
                    .buttonStyle(.plain)
                    .disabled(!enabled)
                    .accessibilityIdentifier("stone.\(i)")
                    .position(x: step * (CGFloat(i) + 0.5), y: baseY)
                }
                if let s = sparkleAt {
                    SparkleView(size: min(stone * 1.5, 120))
                        .position(x: step * (CGFloat(s) + 0.5), y: baseY - stone * 1.05)
                        .animation(.spring(response: 0.45, dampingFraction: 0.65), value: s)
                        .allowsHitTesting(false)
                }
            }
        }
    }
}
