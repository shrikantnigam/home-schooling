import KingdomCore
import SwiftUI

/// One round of the cup shuffle (C2 to C5, and the C7 tutorial): hide the bird, swap cups in arcs, then her guess.
@MainActor
final class CupGame: ObservableObject {
    enum Phase: Equatable { case hiding, shuffling, choosing, revealed(found: Bool) }

    let settings: CupSettings
    let plan: CupShufflePlan
    let tutorial: Bool
    /// Slows nothing down for her; QA plays the same moves faster.
    let pace: Double

    @Published var phase: Phase = .hiding
    /// Swaps finished so far.
    @Published var step = 0
    /// 0 to 1 through the swap in progress.
    @Published var swapProgress: Double = 0
    @Published var lifted: Set<Int> = []
    @Published var picked: Int?
    @Published var wobbleCup: Int?
    @Published var wobbleAmount: CGFloat = 0
    @Published var pointAtBird = false
    @Published var birdHappy = false

    init(settings: CupSettings, plan: CupShufflePlan, tutorial: Bool, pace: Double) {
        self.settings = settings
        self.plan = plan
        self.tutorial = tutorial
        self.pace = pace
    }

    var cupCount: Int { plan.cups }
    /// Cup ids, left to right, after the finished swaps.
    var order: [Int] { plan.order(after: step) }
    func position(of cup: Int) -> Int { order.firstIndex(of: cup) ?? cup }
    var birdPosition: Int { position(of: plan.birdCup) }
    /// The swap being animated, as positions, or nil between swaps.
    var currentSwap: [Int]? { phase == .shuffling && step < plan.swaps.count ? plan.swaps[step] : nil }

    /// Seconds for one swap: the tutorial's single swap is extra slow (C7).
    var swapSeconds: Double { (tutorial ? 1.6 : settings.swapSeconds) * pace }
}

/// The cup shuffle widget (#27, docs/features/cup-shuffle.md): choose cups and speed, then find the bird.
/// Quiet (C6) and without timers, points or streaks (C8): the chirp is the reward.
struct CupShuffleView: View {
    @EnvironmentObject var model: AppModel

    enum Stage: Equatable { case choose, play }

    @State private var stage: Stage = .choose
    @State private var cups = CupSettings.first.cups
    @State private var speed = CupSettings.first.speed
    @State private var game: CupGame?
    @State private var round = 0

    var body: some View {
        ZStack {
            PaperStage(chapter: nil, showSky: false)
            switch stage {
            case .choose: chooser
            case .play:
                if let game {
                    CupTable(game: game, onAgain: { startRound() }, onChange: { stage = .choose; self.game = nil },
                             onTutorialDone: {
                                 model.finishCupTutorial()
                                 stage = .choose
                                 self.game = nil
                             })
                    .id(round)
                }
            }
            ChildCorners(onCastle: nil, onEar: { model.speech.say([model.catalog.spoken("cup.intro")]) },
                         onLock: { model.openParentGate() }, onHome: { model.goHome() })
        }
        .onAppear {
            cups = model.state.cupShuffle.last.cups
            speed = model.state.cupShuffle.last.speed
            if !model.state.cupShuffle.tutorialDone { startTutorial() }
        }
    }

    private var settings: CupSettings { CupSettings(cups: cups, speed: speed) }

    /// C9: a sun ring on the next setting after three finds in a row (or the easier one after two misses).
    private var suggestion: CupSettings? {
        model.state.cupShuffle.suggestion(after: model.state.cupShuffle.last)
    }

    // MARK: Choose (C1)

    private var chooser: some View {
        VStack(spacing: 26) {
            Text("Cup shuffle").font(Theme.title(44)).foregroundStyle(Theme.ink).padding(.top, 96)
            HStack(alignment: .top, spacing: 60) {
                VStack(spacing: 14) {
                    Text("Cups").font(Theme.title(28)).foregroundStyle(Theme.ink)
                    HStack(spacing: 20) {
                        ForEach(CupSettings.cupChoices, id: \.self) { n in
                            option(id: "cup.count.\(n)", selected: cups == n,
                                   suggested: suggestion.map { $0.cups == n && $0.cups != cups } ?? false) {
                                cups = n
                            } label: {
                                HStack(spacing: 2) {
                                    ForEach(0..<n, id: \.self) { _ in CupShape().fill(Theme.poppy).frame(width: 22, height: 26) }
                                }
                                Text("\(n)").font(Theme.numeral(34)).foregroundStyle(Theme.ink)
                            }
                        }
                    }
                }
                VStack(spacing: 14) {
                    Text("Speed").font(Theme.title(28)).foregroundStyle(Theme.ink)
                    HStack(spacing: 20) {
                        ForEach(CupSettings.speedChoices, id: \.self) { v in
                            option(id: "cup.speed.\(v)", selected: speed == v,
                                   suggested: suggestion.map { $0.speed == v && $0.speed != speed && $0.cups == cups } ?? false) {
                                speed = v
                            } label: {
                                HStack(spacing: 0) {
                                    ForEach(0..<v, id: \.self) { _ in
                                        Image(systemName: "chevron.right").font(.system(size: 22, weight: .heavy))
                                            .foregroundStyle(Theme.clay)
                                    }
                                }
                                .frame(height: 26)
                                Text("\(v)").font(Theme.numeral(34)).foregroundStyle(Theme.ink)
                            }
                        }
                    }
                }
            }
            Button { startRound() } label: {
                ZStack {
                    Circle().fill(Theme.gold).frame(width: 120, height: 120).paperCut()
                    Image(systemName: "play.fill").font(.system(size: 50, weight: .heavy)).foregroundStyle(Theme.ink)
                }
            }
            .glow()
            .accessibilityIdentifier("cup.start")
            .accessibilityLabel("Start")
            .padding(.top, 10)
            Spacer()
        }
    }

    private func option<L: View>(id: String, selected: Bool, suggested: Bool, action: @escaping () -> Void,
                                 @ViewBuilder label: () -> L) -> some View {
        Button(action: action) {
            VStack(spacing: 8) { label() }
                .frame(width: 130, height: 110)
                // A selected choice changes fill, not just tint (batch 3A ux-art rule).
                .background(RoundedRectangle(cornerRadius: 20).fill(selected ? Theme.sagePale : Theme.card).paperCut(0.6))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(selected ? Theme.sageDeep : .clear, lineWidth: 4))
                .overlay(suggested ? RoundedRectangle(cornerRadius: 24).stroke(Theme.sun, lineWidth: 5).padding(-7) : nil)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
        .accessibilityValue((selected ? "selected" : "") + (suggested ? "suggested" : ""))
    }

    // MARK: Rounds

    private var pace: Double { model.env.uiTesting ? 0.25 : 1 }

    private func seed() -> UInt64 {
        model.env.uiTesting ? UInt64(model.state.cupShuffle.roundsPlayed + 1) : UInt64.random(in: 1...UInt64.max / 2)
    }

    private func startRound() {
        let s = settings
        game = CupGame(settings: s, plan: CupShufflePlan(settings: s, seed: seed()), tutorial: false, pace: pace)
        round += 1
        stage = .play
        model.sayIntroOnce("cups", [model.catalog.spoken("cup.intro")])
    }

    private func startTutorial() {
        game = CupGame(settings: .first, plan: .tutorial(seed: seed()), tutorial: true, pace: pace)
        round += 1
        stage = .play
    }
}

/// The table: the cups, the bird, and the round's moves.
struct CupTable: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject var game: CupGame
    let onAgain: () -> Void
    let onChange: () -> Void
    let onTutorialDone: () -> Void

    @State private var runner: Task<Void, Never>?
    @State private var chirps = 0

    private static let cupSize = CGSize(width: 130, height: 150)
    private static let tableY: CGFloat = 520

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 18).fill(Theme.wood)
                    .frame(width: geo.size.width - 120, height: 46)
                    .paperCut()
                    .position(x: geo.size.width / 2, y: Self.tableY + Self.cupSize.height / 2 + 14)
                bird(in: geo.size)
                ForEach(0..<game.cupCount, id: \.self) { cup in cupView(cup, in: geo.size) }
                if game.pointAtBird {
                    Image(systemName: "hand.point.down.fill").font(.system(size: 64)).foregroundStyle(Theme.clay)
                        .accessibilityIdentifier("cup.point")
                        .position(x: x(game.birdPosition, in: geo.size), y: Self.tableY - Self.cupSize.height / 2 - 50)
                }
                controls(in: geo.size)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("cup.table")
            .accessibilityValue(qaValue)
        }
        .ignoresSafeArea()
        .onAppear { runner = Task { await play() } }
        .onDisappear { runner?.cancel(); model.speech.stop() }
    }

    /// QA only: the phase, where the bird is, and how many chirps played.
    private var qaValue: String {
        guard model.env.uiTesting else { return "" }
        let phase: String
        switch game.phase {
        case .hiding: phase = "hiding"
        case .shuffling: phase = "shuffling"
        case .choosing: phase = "choosing"
        case .revealed(let found): phase = found ? "found" : "missed"
        }
        return "phase=\(phase);bird=\(game.birdPosition);chirps=\(chirps);tutorial=\(game.tutorial ? 1 : 0)"
    }

    // MARK: Layout

    private func x(_ position: Int, in size: CGSize) -> CGFloat {
        let gap: CGFloat = game.cupCount == 5 ? 180 : 230
        let start = size.width / 2 - gap * CGFloat(game.cupCount - 1) / 2
        return start + gap * CGFloat(position)
    }

    private func cupView(_ cup: Int, in size: CGSize) -> some View {
        let pos = game.position(of: cup)
        let fromX = x(pos, in: size)
        var toX = fromX
        var lift: CGFloat = 0
        let moving = game.currentSwap?.contains(pos) == true
        if let pair = game.currentSwap, moving {
            let other = pair[0] == pos ? pair[1] : pair[0]
            toX = x(other, in: size)
            // The cup moving right arcs up and the other arcs down, so she can tell them apart.
            lift = other > pos ? 70 : -40
        }
        let isLifted = game.lifted.contains(cup)
        let glowing = game.tutorial && cup == game.plan.birdCup && game.phase != .choosing
        return Button { tapped(cup) } label: {
            CupShape().fill(Theme.poppy)
                .overlay(CupShape().stroke(Theme.ink.opacity(0.5), lineWidth: 2))
                .overlay(
                    VStack(spacing: 18) {
                        Rectangle().fill(Color.white.opacity(0.55)).frame(height: 8)
                        Rectangle().fill(Color.white.opacity(0.55)).frame(height: 8)
                    }
                    .padding(.horizontal, 24).padding(.top, 50)
                    .clipShape(CupShape())
                )
                .overlay(glowing ? CupShape().stroke(Theme.sun, lineWidth: 6) : nil)
                .frame(width: Self.cupSize.width, height: Self.cupSize.height)
                .paperCut(0.8)
        }
        .buttonStyle(.plain)
        .disabled(game.phase != .choosing)
        .modifier(Wobble(animatableData: game.wobbleCup == cup ? game.wobbleAmount : 0))
        .modifier(CupArc(progress: moving ? game.swapProgress : 0, distance: toX - fromX, lift: lift))
        .offset(y: isLifted ? -120 : 0)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isLifted)
        .accessibilityIdentifier("cup.at.\(pos)")
        .accessibilityLabel("Cup \(pos + 1)")
        // Last, so each cup's frame is the cup and not the whole table.
        .position(x: fromX, y: Self.tableY)
    }

    @ViewBuilder
    private func bird(in size: CGSize) -> some View {
        let showBird = game.lifted.contains(game.plan.birdCup)
        BirdView(happy: game.birdHappy)
            .frame(width: 80, height: 70)
            .opacity(showBird ? 1 : 0)
            .accessibilityHidden(!showBird)
            .accessibilityIdentifier("cup.bird")
            .position(x: x(game.birdPosition, in: size), y: Self.tableY + Self.cupSize.height / 2 - 34)
    }

    @ViewBuilder
    private func controls(in size: CGSize) -> some View {
        if case .revealed = game.phase, !game.tutorial {
            HStack(alignment: .bottom) {
                Button { onChange() } label: {
                    Label("Change", systemImage: "slider.horizontal.3").font(Theme.body(20).bold())
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 22).padding(.vertical, 14)
                        .background(Capsule().fill(Theme.card).paperCut(0.6))
                }
                .accessibilityIdentifier("cup.change")
                Spacer()
                NextButton { onAgain() }
            }
            .padding(.horizontal, 40)
            .frame(width: size.width)
            .position(x: size.width / 2, y: size.height - 90)
        }
    }

    // MARK: The round

    private func wait(_ seconds: Double) async -> Bool {
        try? await Task.sleep(nanoseconds: UInt64(max(0, seconds) * 1_000_000_000))
        return !Task.isCancelled
    }

    private func say(_ id: LineID) { model.speech.say([model.catalog.spoken(id)]) }

    private func play() async {
        let pace = game.pace
        // C2: the bird hops under a cup; the cup lifts so she sees it, then comes down.
        game.lifted = [game.plan.birdCup]
        if game.tutorial { say("cup.tut.hide") }
        guard await wait((game.tutorial ? 3.0 : 1.3) * pace) else { return }
        game.lifted = []
        guard await wait(0.7 * pace) else { return }
        if game.tutorial {
            say("cup.tut.watch")
            guard await wait(1.2 * pace) else { return }
        }
        // C3: swap pairs of cups in arcs.
        game.phase = .shuffling
        for _ in game.plan.swaps {
            let seconds = game.swapSeconds
            withAnimation(.easeInOut(duration: seconds)) { game.swapProgress = 1 }
            guard await wait(seconds + 0.05) else { return }
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) {
                game.step += 1
                game.swapProgress = 0
            }
            guard await wait(0.08 * pace) else { return }
        }
        game.phase = .choosing
        if game.tutorial {
            say("cup.tut.tap")
            game.pointAtBird = true
        }
    }

    private func tapped(_ cup: Int) {
        guard game.phase == .choosing else { return }
        let found = cup == game.plan.birdCup
        if game.tutorial {
            // C7: she can't fail the tutorial. A wrong cup wobbles and the hand points again.
            guard found else {
                game.wobbleCup = cup
                withAnimation(.linear(duration: 0.4)) { game.wobbleAmount += 1 }
                game.pointAtBird = true
                say("cup.tut.point")
                return
            }
            game.pointAtBird = false
            reveal(found: true)
            say("cup.tut.done")
            Task {
                guard await wait(2.6 * game.pace) else { return }
                onTutorialDone()
            }
            return
        }
        game.picked = cup
        if found {
            reveal(found: true)
        } else {
            // C5: the empty cup lifts, then the bird's cup, with one short line. Nothing is marked wrong.
            game.lifted = [cup]
            game.phase = .revealed(found: false)
            model.finishCupRound(game.settings, found: false)
            Task {
                guard await wait(0.7 * game.pace) else { return }
                game.lifted.insert(game.plan.birdCup)
                chirp(volume: 0.5)
                say("cup.miss")
            }
        }
    }

    /// C4: the cup lifts, the bird flutters and chirps.
    private func reveal(found: Bool) {
        game.lifted = [game.plan.birdCup]
        game.birdHappy = true
        game.phase = .revealed(found: found)
        chirp(volume: 1)
        if !game.tutorial { model.finishCupRound(game.settings, found: found) }
    }

    private func chirp(volume: Double) {
        chirps += 1
        ChirpPlayer.shared.play(volume: volume * model.state.sound.narrationVolume)
    }
}

/// Moves a cup along an arc to another place `distance` points away as `progress` goes from 0 to 1.
/// A GeometryEffect, so SwiftUI interpolates `progress` frame by frame (it is both Animatable and a ViewModifier).
struct CupArc: GeometryEffect {
    var progress: Double
    var distance: CGFloat
    var lift: CGFloat

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let t = CGFloat(progress)
        return ProjectionTransform(CGAffineTransform(translationX: distance * t, y: -lift * sin(.pi * t)))
    }
}

/// A paper cup, upside down: narrow at the top, wide at the rim, with a rounded base.
struct CupShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let inset = r.width * 0.18
        p.move(to: CGPoint(x: r.minX + inset, y: r.minY + r.height * 0.06))
        p.addQuadCurve(to: CGPoint(x: r.maxX - inset, y: r.minY + r.height * 0.06), control: CGPoint(x: r.midX, y: r.minY - r.height * 0.04))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - r.height * 0.06))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY - r.height * 0.06), control: CGPoint(x: r.midX, y: r.maxY + r.height * 0.05))
        p.closeSubpath()
        return p
    }
}

/// A small paper bird. When happy it hops and flaps.
struct BirdView: View {
    let happy: Bool
    @State private var flap = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Ellipse().fill(Theme.river).frame(width: w * 0.7, height: h * 0.55).offset(x: -w * 0.04, y: h * 0.12)
                Circle().fill(Theme.river).frame(width: w * 0.38).offset(x: w * 0.22, y: -h * 0.14)
                Triangle().fill(Theme.sun).frame(width: w * 0.16, height: h * 0.12)
                    .rotationEffect(.degrees(90)).offset(x: w * 0.47, y: -h * 0.13)
                Circle().fill(Theme.ink).frame(width: w * 0.06).offset(x: w * 0.27, y: -h * 0.18)
                Ellipse().fill(Theme.sageDeep).frame(width: w * 0.36, height: h * 0.24)
                    .rotationEffect(.degrees(flap ? -35 : 10), anchor: .trailing)
                    .offset(x: -w * 0.12, y: h * 0.06)
                Ellipse().fill(Theme.sageDeep).frame(width: w * 0.24, height: h * 0.12).offset(x: -w * 0.42, y: h * 0.02)
            }
            .frame(width: w, height: h)
            .offset(y: happy && flap ? -h * 0.18 : 0)
        }
        .onChange(of: happy) { _, isHappy in
            guard isHappy else { return }
            withAnimation(.easeInOut(duration: 0.18).repeatCount(7, autoreverses: true)) { flap = true }
        }
    }
}

/// Three cups and the bird peeking out, for the home screen tile.
struct CupTileArt: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(Theme.wood).frame(width: 210, height: 18).offset(y: 62)
            HStack(spacing: 10) {
                CupShape().fill(Theme.poppy).frame(width: 56, height: 66)
                CupShape().fill(Theme.poppy).frame(width: 56, height: 66).offset(y: -30).rotationEffect(.degrees(-8))
                CupShape().fill(Theme.poppy).frame(width: 56, height: 66)
            }
            .offset(y: 22)
            BirdView(happy: false).frame(width: 50, height: 44).offset(y: 34)
        }
        .frame(width: 220, height: 180)
    }
}
