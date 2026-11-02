import KingdomCore
import SwiftUI

/// Pictures for picture-first items and level-1 board puzzles: the objects of the sign's own place.
struct ProblemPicture: View {
    let picture: SheetPicture
    var size: CGFloat = 40

    var body: some View {
        Group {
            switch picture {
            case .none:
                EmptyView()
            case .dots(let n):
                rows(n) { _ in StarSprite(lit: true, size: size) }
            case .join(let a, let b):
                HStack(spacing: 18) {
                    rows(a) { _ in CounterSprite(style: .flower, size: size) }
                    Image(systemName: "plus").font(.system(size: 30, weight: .heavy)).foregroundStyle(Theme.clay)
                    rows(b) { _ in CounterSprite(style: .flower, second: true, size: size) }
                }
            case .takeAway(let a, let b):
                rows(a) { i in
                    CounterSprite(style: .gem, size: size)
                        .opacity(i >= a - b ? 0.35 : 1)
                        .overlay(i >= a - b ? Image(systemName: "xmark").font(.system(size: size * 0.6, weight: .bold))
                            .foregroundStyle(Theme.clay) : nil)
                }
            case .groups(let a, let b):
                HStack(spacing: 14) {
                    ForEach(0..<a, id: \.self) { _ in
                        rows(b, perRow: 3) { _ in CounterSprite(style: .guest, size: size * 0.8) }
                            .padding(8)
                            .background(Circle().fill(Theme.tan.opacity(0.7)))
                    }
                }
            case .share(let a, let b):
                VStack(spacing: 10) {
                    rows(a) { _ in CounterSprite(style: .treat, size: size * 0.8) }
                    HStack(spacing: 16) {
                        ForEach(0..<b, id: \.self) { _ in
                            Ellipse().fill(Theme.card).overlay(Ellipse().stroke(Theme.tan, lineWidth: 3))
                                .frame(width: size * 1.8, height: size * 0.8)
                        }
                    }
                }
            case .parts(let n):
                PartsCircle(parts: n).frame(width: size * 3, height: size * 3)
            }
        }
        .accessibilityHidden(true)
    }

    private func rows<V: View>(_ n: Int, perRow: Int = 5, @ViewBuilder _ cell: @escaping (Int) -> V) -> some View {
        let count = max(0, min(n, 25))
        let lines = (count + perRow - 1) / perRow
        return VStack(spacing: 4) {
            ForEach(0..<lines, id: \.self) { r in
                HStack(spacing: 4) {
                    ForEach(0..<min(perRow, count - r * perRow), id: \.self) { c in cell(r * perRow + c) }
                }
            }
        }
    }
}

/// A moon crystal cut into equal wedges.
struct PartsCircle: View {
    let parts: Int
    var body: some View {
        GeometryReader { geo in
            let r = min(geo.size.width, geo.size.height) / 2
            let c = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            ZStack {
                Circle().fill(Color(hex: 0xBFD3F2))
                Path { p in
                    for i in 0..<max(1, parts) {
                        let angle = Double(i) / Double(max(1, parts)) * 2 * .pi - .pi / 2
                        p.move(to: c)
                        p.addLine(to: CGPoint(x: c.x + r * cos(angle), y: c.y + r * sin(angle)))
                    }
                }
                .stroke(Theme.nightPaper, lineWidth: 3)
                Circle().stroke(Theme.nightPaper, lineWidth: 3)
            }
        }
    }
}

/// A row of sentence cards; "?" and "○" are the box she fills.
struct SentenceRow: View {
    let tokens: [String]
    /// What goes in the box so far (typed, written or shown).
    var box: String = ""
    var boxState: BoxState = .waiting
    var size: CGFloat = 54

    enum BoxState { case waiting, right, shown }

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(tokens.enumerated()), id: \.offset) { _, t in
                if t == "?" || t == "○" {
                    Text(box.isEmpty ? " " : box)
                        .font(Theme.numeral(size))
                        .foregroundStyle(boxState == .shown ? Theme.clay : Theme.ink)
                        .frame(minWidth: size * 1.7, minHeight: size * 1.5)
                        .background(RoundedRectangle(cornerRadius: 14).fill(boxState == .right ? Theme.sagePale : Theme.card))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(boxState == .waiting ? Theme.sun : Theme.sage, style: StrokeStyle(lineWidth: 4, dash: boxState == .waiting ? [8, 6] : [])))
                        .accessibilityIdentifier("sentence.box")
                        .accessibilityValue(box)
                } else {
                    Text(t).font(Theme.numeral(t.count > 2 ? size * 0.6 : size)).foregroundStyle(Theme.ink)
                }
            }
        }
        .padding(.horizontal, 22).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 20).fill(Theme.card.opacity(0.92)).paperCut(0.6))
    }
}

/// A row of paper key cards: numbers 0 to 9 (or the four signs), back and check.
struct KeyRow: View {
    var signs: [MathOp]? = nil
    let onKey: (String) -> Void

    var body: some View {
        HStack(spacing: 10) {
            if let signs {
                ForEach(signs, id: \.self) { op in key(op.sign, id: "key.\(op.rawValue)") }
            } else {
                ForEach(0..<10, id: \.self) { n in key("\(n)", id: "key.\(n)") }
                key("⌫", id: "key.back")
                key("✓", id: "key.check")
            }
        }
    }

    private func key(_ label: String, id: String) -> some View {
        Button { onKey(label) } label: {
            Text(label).font(Theme.numeral(signs == nil ? 34 : 50)).foregroundStyle(Theme.ink)
                .frame(width: signs == nil ? 64 : 104, height: signs == nil ? 72 : 104)
                .background(RoundedRectangle(cornerRadius: 12).fill(label == "✓" ? Theme.sun : Theme.card))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.tan, lineWidth: 2))
                .paperCut(0.5)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }
}
