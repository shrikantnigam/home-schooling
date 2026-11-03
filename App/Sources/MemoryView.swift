import KingdomCore
import SwiftUI

/// The memory game (docs/features/memory.md, M1 to M10): pick a level, then turn cards over two at a time to find
/// the pairs. It trains memory: keeping where each character is in mind. Quiet (one-time intro, M6) and without
/// timers, points or stars (M8): finding the last pair is the reward.
struct MemoryView: View {
    @EnvironmentObject var model: AppModel

    /// The deal is made once when a game starts and kept here, so nothing reshuffles while she plays.
    enum Stage: Equatable { case choose, play(MemoryDeal) }

    @State private var stage: Stage = .choose
    @State private var round = 0
    @State private var lockedWobble: [MemoryLevel: CGFloat] = [:]

    var body: some View {
        ZStack {
            PaperStage(chapter: nil, showSky: false)
            switch stage {
            case .choose: chooser
            case .play(let d):
                MemoryBoard(deal: d, onAgain: { start(d.level) }, onChange: { stage = .choose })
                    .id(round)
            }
            ChildCorners(onCastle: nil, onEar: { model.speech.say([model.catalog.spoken("memory.intro")]) },
                         onLock: { model.openParentGate() }, onHome: { model.goHome() })
        }
        .onAppear {
            if model.memoryFirstTime() { model.speech.say([model.catalog.spoken("memory.intro")]) }
        }
    }

    private func start(_ level: MemoryLevel) {
        round += 1
        stage = .play(deal(level))
    }

    private func deal(_ level: MemoryLevel) -> MemoryDeal {
        let m = model.state.memory
        let seed = model.env.uiTesting ? UInt64(m.gamesPlayed + 1) : UInt64.random(in: 1...UInt64.max / 2)
        return MemoryDeal(level: level, pairs: m.pairs(for: level), seed: seed)
    }

    // MARK: Choose a level (M3)

    private var chooser: some View {
        VStack(spacing: 30) {
            Text("Memory").font(Theme.title(44)).foregroundStyle(Theme.ink).padding(.top, 96)
            HStack(spacing: 34) {
                ForEach(MemoryLevel.allCases, id: \.self) { level in levelCard(level) }
            }
            Spacer()
        }
    }

    private func levelCard(_ level: MemoryLevel) -> some View {
        let open = model.state.memory.isOpen(level)
        let pairs = model.state.memory.pairs(for: level)
        return Button {
            if open {
                start(level)
            } else {
                model.speech.say([model.catalog.spoken(level == .medium ? "memory.locked.medium" : "memory.locked.hard")])
                withAnimation(.linear(duration: 0.4)) { lockedWobble[level, default: 0] += 1 }
            }
        } label: {
            VStack(spacing: 12) {
                // Face-down cards, as many as the game will have: the size is shown, not written.
                let g = MemoryLevel.grid(cards: pairs * 2)
                VStack(spacing: 4) {
                    ForEach(0..<g.rows, id: \.self) { r in
                        HStack(spacing: 4) {
                            ForEach(0..<g.cols, id: \.self) { c in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(r * g.cols + c < pairs * 2 ? Theme.deepLavender : Color.clear)
                                    .frame(width: 22, height: 28)
                            }
                        }
                    }
                }
                .frame(height: 130)
                Text(level.title).font(Theme.title(30)).foregroundStyle(Theme.ink)
            }
            .frame(width: 240, height: 220)
            .background(RoundedRectangle(cornerRadius: 24).fill(Theme.card).paperCut(0.7))
            .opacity(open ? 1 : 0.45)
            .overlay(alignment: .topTrailing) {
                if !open {
                    Image(systemName: "lock.fill").font(.system(size: 30)).foregroundStyle(Theme.ink).padding(14)
                }
            }
        }
        .buttonStyle(.plain)
        .modifier(Wobble(animatableData: lockedWobble[level, default: 0]))
        .accessibilityIdentifier("memory.level.\(level.rawValue)")
        .accessibilityLabel(level.title)
        .accessibilityValue(open ? "open;pairs=\(pairs)" : "locked")
    }
}

/// One game: the cards, two turned at a time. A pair stays face up; two different cards turn back after a moment.
struct MemoryBoard: View {
    @EnvironmentObject var model: AppModel
    let deal: MemoryDeal
    let onAgain: () -> Void
    let onChange: () -> Void

    @State private var faceUp: Set<Int> = []
    @State private var matched: Set<Int> = []
    @State private var first: Int?
    @State private var busy = false
    @State private var tries = 0
    @State private var recorded = false

    private var done: Bool { matched.count == deal.cards.count }

    var body: some View {
        let g = MemoryLevel.grid(cards: deal.cards.count)
        let card = cardSize(g)
        VStack(spacing: 24) {
            Spacer(minLength: 110)
            VStack(spacing: 16) {
                ForEach(0..<g.rows, id: \.self) { r in
                    HStack(spacing: 16) {
                        ForEach(0..<g.cols, id: \.self) { c in
                            let i = r * g.cols + c
                            if i < deal.cards.count { cardView(i, size: card) } else { Color.clear.frame(width: card.width, height: card.height) }
                        }
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("memory.board")
            .accessibilityValue("found=\(matched.count / 2)/\(deal.pairs);tries=\(tries)")
            if done {
                HStack(spacing: 40) {
                    Button(action: onChange) {
                        Image(systemName: "square.grid.3x2.fill").font(.system(size: 36)).foregroundStyle(Theme.ink)
                            .frame(width: 90, height: 90).background(Circle().fill(Theme.card)).paperCut(0.5)
                    }
                    .accessibilityIdentifier("memory.change")
                    .accessibilityLabel("Choose a level")
                    NextButton(action: onAgain)
                }
            }
            Spacer()
        }
    }

    /// Cards as big as the screen allows, a little taller than wide.
    private func cardSize(_ g: (cols: Int, rows: Int)) -> CGSize {
        let w = min(170, (1000 - CGFloat(g.cols - 1) * 16) / CGFloat(g.cols))
        let h = min(w * 1.25, (560 - CGFloat(g.rows - 1) * 16) / CGFloat(g.rows))
        return CGSize(width: min(w, h / 1.25), height: h)
    }

    private func cardBackStar(_ side: CGFloat) -> some View {
        StarShape()
            .fill(Theme.card)
            .overlay(StarShape().stroke(Theme.tan, lineWidth: 3))
            .frame(width: side, height: side)
    }

    private func cardView(_ i: Int, size: CGSize) -> some View {
        let up = faceUp.contains(i) || matched.contains(i)
        return Button { turn(i) } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(up ? Theme.card : Theme.deepLavender)
                if up {
                    MemoryCharacterArt(character: deal.cards[i], companion: model.state.companion)
                        .padding(size.width * 0.1)
                } else {
                    // The back: a cream paper star, the same on every card. Light on dark so the backs read
                    // clearly (the unlit sky star was too faint here); no face, so it isn't a character.
                    cardBackStar(size.width * 0.42)
                }
            }
            .frame(width: size.width, height: size.height)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(matched.contains(i) ? Theme.sageDeep : Theme.tan,
                                                               lineWidth: matched.contains(i) ? 5 : 2))
            .paperCut(0.5)
            .rotation3DEffect(.degrees(up ? 0 : 180), axis: (x: 0, y: 1, z: 0))
            .animation(.easeInOut(duration: 0.3), value: up)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("memory.card.\(i)")
        .accessibilityLabel("Card \(i + 1)")
        // QA reads which character a card holds; she never hears it before turning it.
        .accessibilityValue(model.env.uiTesting ? "\(deal.cards[i].rawValue);\(matched.contains(i) ? "matched" : (up ? "up" : "down"))" : (up ? "up" : "down"))
    }

    private func turn(_ i: Int) {
        guard !busy, !done, !faceUp.contains(i), !matched.contains(i) else { return }
        faceUp.insert(i)
        guard let a = first else { first = i; return }
        first = nil
        tries += 1
        if deal.isMatch(a, i) {
            matched.formUnion([a, i])
            faceUp.subtract([a, i])
            ChirpPlayer.shared.play(volume: 0.4 * model.state.sound.narrationVolume)
            if done { finish() }
        } else {
            busy = true
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                faceUp.subtract([a, i])
                busy = false
            }
        }
    }

    private func finish() {
        guard !recorded else { return }
        recorded = true
        model.finishMemory(MemoryResult(level: deal.level, pairs: deal.pairs, tries: tries, date: model.now))
        model.speech.say([model.catalog.spoken("memory.done")])
    }
}

/// The ten memory characters (M1), drawn from the app's own art where it has them.
struct MemoryCharacterArt: View {
    let character: MemoryCharacter
    let companion: Companion

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                switch character {
                case .unicorn: companionArt(.unicorn, s)
                case .superhero: companionArt(.superhero, s)
                case .princess: companionArt(.princess, s)
                case .monster: companionArt(.monster, s)
                case .gnome: companionArt(.gnome, s)
                case .siara:
                    SiaraView(size: 180).frame(width: 180, height: 180).scaleEffect(s / 180).frame(width: s, height: s)
                case .bird: BirdView(happy: false).frame(width: s * 0.9, height: s * 0.7)
                case .frog: frog(s)
                case .teddy: teddy(s)
                case .cat: cat(s)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func companionArt(_ c: Companion, _ s: CGFloat) -> some View {
        CompanionArt(companion: c).frame(width: 200, height: 200).scaleEffect(s / 200).frame(width: s, height: s)
    }

    private func eyes(_ s: CGFloat, y: CGFloat, gap: CGFloat) -> some View {
        HStack(spacing: s * gap) {
            Circle().fill(Theme.ink).frame(width: s * 0.08)
            Circle().fill(Theme.ink).frame(width: s * 0.08)
        }
        .offset(y: s * y)
    }

    private func frog(_ s: CGFloat) -> some View {
        ZStack {
            Ellipse().fill(Theme.garden).frame(width: s * 0.8, height: s * 0.6).offset(y: s * 0.1)
            Circle().fill(Theme.garden).frame(width: s * 0.28).offset(x: -s * 0.2, y: -s * 0.18)
            Circle().fill(Theme.garden).frame(width: s * 0.28).offset(x: s * 0.2, y: -s * 0.18)
            Circle().fill(Color.white).frame(width: s * 0.16).offset(x: -s * 0.2, y: -s * 0.2)
            Circle().fill(Color.white).frame(width: s * 0.16).offset(x: s * 0.2, y: -s * 0.2)
            eyes(s, y: -0.2, gap: 0.32)
            Capsule().fill(Theme.rose).frame(width: s * 0.3, height: s * 0.05).offset(y: s * 0.15)
        }
    }

    private func teddy(_ s: CGFloat) -> some View {
        ZStack {
            Circle().fill(Theme.ochre).frame(width: s * 0.26).offset(x: -s * 0.24, y: -s * 0.26)
            Circle().fill(Theme.ochre).frame(width: s * 0.26).offset(x: s * 0.24, y: -s * 0.26)
            Circle().fill(Theme.ochre).frame(width: s * 0.7)
            Ellipse().fill(Theme.cream).frame(width: s * 0.3, height: s * 0.22).offset(y: s * 0.12)
            Circle().fill(Theme.ink).frame(width: s * 0.09).offset(y: s * 0.07)
            eyes(s, y: -0.08, gap: 0.2)
        }
    }

    private func cat(_ s: CGFloat) -> some View {
        ZStack {
            Triangle().fill(Theme.muted).frame(width: s * 0.26, height: s * 0.3).offset(x: -s * 0.2, y: -s * 0.27)
            Triangle().fill(Theme.muted).frame(width: s * 0.26, height: s * 0.3).offset(x: s * 0.2, y: -s * 0.27)
            Circle().fill(Theme.muted).frame(width: s * 0.66)
            eyes(s, y: -0.05, gap: 0.2)
            Triangle().fill(Theme.rose).frame(width: s * 0.08, height: s * 0.06).rotationEffect(.degrees(180)).offset(y: s * 0.07)
            ForEach(0..<2, id: \.self) { side in
                ForEach(0..<2, id: \.self) { k in
                    Capsule().fill(Theme.ink).frame(width: s * 0.22, height: 2)
                        .rotationEffect(.degrees(Double(k == 0 ? -8 : 8)))
                        .offset(x: CGFloat(side == 0 ? -1 : 1) * s * 0.24, y: s * (0.09 + CGFloat(k) * 0.05))
                }
            }
        }
    }
}
