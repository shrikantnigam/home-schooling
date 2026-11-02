import KingdomCore
import SwiftUI

/// F1 (charter L11, L16): at the end of a place she writes what happened as number sentences, tapping tiles
/// into slots. "=" is a balance that levels when both sides are filled. The second sentence starts with the answer.
struct WriteItDownView: View {
    @EnvironmentObject var model: AppModel
    let chapter: ChapterID

    @State private var index = 0
    @State private var filler: SlotFiller?
    @State private var wobbleTile: String?
    @State private var wobble: CGFloat = 0
    @State private var finished = false

    private var moment: WriteItDown? { WriteItDown.forPlace(chapter) }
    private var night: Bool { ChapterLook.isNight(chapter) }

    var body: some View {
        ZStack {
            PaperStage(chapter: chapter)
            VStack(spacing: 26) {
                Text("Write it down")
                    .font(Theme.title(40))
                    .foregroundStyle(night ? .white : Theme.ink)
                    .padding(.top, 110)
                    .accessibilityIdentifier("write.title.\(chapter)")
                if let f = filler {
                    picture(for: f.sentence)
                    Balance(filler: f)
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("write.sentence.\(index)")
                        .accessibilityValue(f.balanced ? "balanced" : (f.leftDone ? "right side empty" : "left side empty"))
                }
                Spacer()
                if let m = moment, !finished {
                    HStack(spacing: 18) {
                        ForEach(m.tiles, id: \.self) { t in tile(t) }
                    }
                    .padding(.bottom, 60)
                }
            }
            .padding(.horizontal, 40)
            ChildCorners(onCastle: { model.finishWriteItDown(chapter) },
                         onEar: { speakIntro(replay: true) },
                         onLock: { model.openParentGate() },
                         dark: night)
            if finished {
                VStack { Spacer(); HStack { Spacer(); NextButton { model.finishWriteItDown(chapter) } } }
                    .padding(28)
            }
        }
        .onAppear {
            if filler == nil, let m = moment { filler = SlotFiller(m.sentences[0]) }
            speakIntro(replay: false)
        }
    }

    private func speakIntro(replay: Bool) {
        let lines = index == 0
            ? [model.catalog.spoken("write.intro.\(chapter)"), model.catalog.spoken("write.tap")]
            : [model.catalog.spoken("write.flip")]
        model.speech.say(lines)
    }

    /// What happened, as objects from the place: as many as the sentence's answer (up to 13).
    @ViewBuilder
    private func picture(for s: NumberSentence) -> some View {
        let nums = s.tokens.compactMap { Int($0) }
        let count = min(13, (s.isAnswerFirst ? nums.first : nums.last) ?? 0)
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { _ in ChapterLook.icon(chapter, lit: true, size: 44) }
        }
        .frame(height: 60)
        .accessibilityHidden(true)
    }

    private func tile(_ t: String) -> some View {
        Button { tap(t) } label: {
            Text(t)
                .font(Theme.numeral(Int(t) == nil && t.count > 1 ? 34 : 50))
                .foregroundStyle(Theme.ink)
                .frame(width: 96, height: 104)
                .background(RoundedRectangle(cornerRadius: 16).fill(Theme.card))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.tan, lineWidth: 3))
                .paperCut(0.7)
        }
        .buttonStyle(.plain)
        .modifier(Wobble(animatableData: wobbleTile == t ? wobble : 0))
        .accessibilityIdentifier("write.tile.\(t)")
        .accessibilityLabel(spoken(t))
    }

    private func spoken(_ t: String) -> String {
        if let op = MathOp.from(sign: t) { return op.spoken }
        switch t {
        case "=": return "equals"
        case "½": return "one half"
        default: return t
        }
    }

    private func tap(_ t: String) {
        guard var f = filler, !finished else { return }
        if f.tap(t) {
            filler = f
            if f.isComplete { sentenceDone() }
        } else {
            // AC-W4: nothing is marked wrong; the tile wobbles and the companion gives a hint.
            wobbleTile = t
            withAnimation(.linear(duration: 0.4)) { wobble += 1 }
            model.speech.say([model.catalog.spoken("write.hint")])
        }
    }

    private func sentenceDone() {
        guard let m = moment else { return }
        let last = index + 1 >= m.sentences.count
        let first: [SpokenLine?] = index == 0 ? [model.catalog.spoken("write.balance")] : []
        let rest: [SpokenLine?] = last
            ? [model.catalog.spoken("write.done"), model.catalog.spoken("write.scroll")]
            : [model.catalog.spoken("write.flip")]
        model.speech.say(first + rest) {
            if last {
                finished = true
            } else {
                index += 1
                filler = SlotFiller(m.sentences[index])
            }
        }
    }
}

/// The equals sign as a paper balance (L16): left side on the left pan, right side on the right pan.
/// It tips while a side is empty and levels when both sides hold the same amount.
struct Balance: View {
    let filler: SlotFiller

    var body: some View {
        let tokens = filler.sentence.tokens
        let eq = filler.sentence.equalsIndex ?? tokens.count
        let angle: Double = filler.balanced ? 0 : (filler.leftDone ? -5 : 5)
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 26) {
                pan(Array(0..<eq))
                Text("=").font(Theme.numeral(56)).foregroundStyle(Theme.clay)
                    .frame(width: 70, height: 100)
                    .background(Circle().fill(Theme.sun.opacity(filler.balanced ? 0.9 : 0.35)))
                    .accessibilityIdentifier("write.equals")
                pan(Array((eq + 1)..<max(eq + 1, tokens.count)))
            }
            .rotationEffect(.degrees(angle))
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: angle)
            // The stand.
            Rectangle().fill(Theme.woodDark).frame(width: 18, height: 70)
            Capsule().fill(Theme.woodDark).frame(width: 180, height: 18)
        }
    }

    private func pan(_ slots: [Int]) -> some View {
        HStack(spacing: 10) {
            ForEach(slots, id: \.self) { i in slot(i) }
        }
        .padding(14)
        .background(Capsule().fill(Theme.tan).paperCut(0.6))
    }

    private func slot(_ i: Int) -> some View {
        let filled = i < filler.filled.count
        return ZStack {
            RoundedRectangle(cornerRadius: 14).fill(filled ? Theme.card : Theme.card.opacity(0.5))
            if filled {
                Text(filler.filled[i]).font(Theme.numeral(46)).foregroundStyle(Theme.ink)
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(i == filler.filled.count ? Theme.sun : Theme.muted.opacity(0.5),
                            style: StrokeStyle(lineWidth: 3, dash: [7, 5]))
            }
        }
        .frame(width: 84, height: 92)
        .accessibilityIdentifier("write.slot.\(i)")
        .accessibilityValue(filled ? filler.filled[i] : "empty")
    }
}
