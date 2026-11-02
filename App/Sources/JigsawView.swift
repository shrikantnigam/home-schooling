import KingdomCore
import SwiftUI
import UIKit

/// The jigsaw widget (#25): pick a picture on the puzzle map (J13), pick a size, then drag pieces into place.
/// Quiet by default (J7): it speaks only a one-time intro per variation, hints, the explain moment and the slip.
/// No timers, points or stickers (J8): the reward is the finished picture.
struct JigsawView: View {
    @EnvironmentObject var model: AppModel

    enum Stage: Equatable { case choose, sizes(String), play }

    @State private var stage: Stage = .choose
    @State private var game: JigsawGame?

    var body: some View {
        ZStack {
            PaperStage(chapter: nil, showSky: false)
            switch stage {
            case .choose: JigsawMap(suggested: nextPicture) { stage = .sizes($0) }
            case .sizes(let picture): sizePicker(picture)
            case .play:
                if let game { JigsawBoard(game: game, onNext: { stage = .choose; self.game = nil }) }
            }
            ChildCorners(onCastle: nil, onEar: { replayIntro() }, onLock: { model.openParentGate() },
                         onHome: { model.goHome() })
        }
    }

    private var nextPicture: String {
        model.state.jigsaw.nextPicture(from: JigsawPictures.all.map(\.id)) ?? "castle"
    }

    // MARK: Pick a size (she stays in charge, from 2 or 3 around her level)

    private func sizePicker(_ picture: String) -> some View {
        let sizes = model.state.jigsaw.offeredSizes
        return VStack(spacing: 26) {
            JigsawScene(id: picture, companion: model.state.companion)
                .frame(width: 420, height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .paperCut()
                .padding(.top, 110)
            Text("How many pieces?").font(Theme.title(32)).foregroundStyle(Theme.ink)
            HStack(spacing: 28) {
                ForEach(sizes, id: \.self) { n in
                    Button { startPicture(picture, pieces: n) } label: {
                        VStack(spacing: 8) {
                            miniGrid(n)
                            Text("\(n)").font(Theme.numeral(40)).foregroundStyle(Theme.ink)
                        }
                        .frame(width: 150, height: 150)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Theme.card).paperCut(0.6))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("jig.size.\(n)")
                }
            }
            Spacer()
        }
    }

    private func miniGrid(_ n: Int) -> some View {
        let g = JigsawLadder.grid(n)
        return VStack(spacing: 2) {
            ForEach(0..<g.rows, id: \.self) { _ in
                HStack(spacing: 2) {
                    ForEach(0..<g.cols, id: \.self) { _ in Rectangle().fill(Theme.sage).frame(width: 8, height: 8) }
                }
            }
        }
        .frame(height: 60)
    }

    // MARK: Start

    private func seed() -> UInt64 {
        model.env.uiTesting ? UInt64(model.state.jigsaw.puzzlesDone + 1) : UInt64.random(in: 1...UInt64.max / 2)
    }

    private func startPicture(_ picture: String, pieces: Int) {
        let level = model.state.jigsaw.level(pieces: pieces)
        let g = JigsawLadder.grid(pieces)
        let cell = JigsawBoard.cell(cols: g.cols, rows: g.rows)
        let image = JigsawPictures.render(picture, companion: model.state.companion,
                                          size: CGSize(width: cell * CGFloat(g.cols), height: cell * CGFloat(g.rows)))
        game = JigsawGame(picture: picture, level: level, seed: seed(),
                          slipDue: model.state.jigsaw.companionSlipDue, image: image)
        stage = .play
        var intros: [LineID] = []
        if model.jigsawFirstTime("picture") { intros.append("jig.intro.picture") }
        if level.turning && model.jigsawFirstTime("turning") { intros.append("jig.intro.turning") }
        model.speech.say(intros.map { model.catalog.spoken($0) })
    }

    private func replayIntro() {
        model.speech.say([model.catalog.spoken("jig.intro.picture")])
    }
}

/// The puzzle map (J13, charter AC-H7): every picture on one paper board, joined by a dotted path. Finished pictures
/// keep their colours and get a green tick with the most pieces she has done (J14). The suggestion wears a sun ring.
struct JigsawMap: View {
    @EnvironmentObject var model: AppModel
    let suggested: String
    let pick: (String) -> Void

    private static let cols = 4
    private static let cardSize = CGSize(width: 220, height: 196)
    private static let gap = CGSize(width: 34, height: 40)

    var body: some View {
        VStack(spacing: 18) {
            Text("Jigsaw").font(Theme.title(44)).foregroundStyle(Theme.ink).padding(.top, 96)
            ZStack(alignment: .topLeading) {
                path
                ForEach(Array(JigsawPictures.all.enumerated()), id: \.element.id) { i, pic in
                    card(pic)
                        .position(center(i))
                }
            }
            .frame(width: Self.boardSize.width, height: Self.boardSize.height)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("jig.map")
            Spacer()
        }
    }

    private static var rows: Int { (JigsawPictures.all.count + cols - 1) / cols }
    private static var boardSize: CGSize {
        CGSize(width: CGFloat(cols) * cardSize.width + CGFloat(cols - 1) * gap.width,
               height: CGFloat(rows) * cardSize.height + CGFloat(rows - 1) * gap.height)
    }

    /// Cards run left to right on the first row and right to left on the next, like a path on a map.
    private func center(_ i: Int) -> CGPoint {
        let r = i / Self.cols
        let c = r % 2 == 0 ? i % Self.cols : Self.cols - 1 - i % Self.cols
        return CGPoint(x: (CGFloat(c) + 0.5) * Self.cardSize.width + CGFloat(c) * Self.gap.width,
                       y: (CGFloat(r) + 0.5) * Self.cardSize.height + CGFloat(r) * Self.gap.height)
    }

    private var path: some View {
        Path { p in
            let n = JigsawPictures.all.count
            guard n > 1 else { return }
            p.move(to: center(0))
            for i in 1..<n { p.addLine(to: center(i)) }
        }
        .stroke(Theme.clay.opacity(0.45), style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [2, 14]))
        .allowsHitTesting(false)
    }

    private func card(_ pic: JigsawPictures.Picture) -> some View {
        let best = model.state.jigsaw.completed[pic.id]
        let isSuggested = pic.id == suggested
        return Button { pick(pic.id) } label: {
            VStack(spacing: 8) {
                JigsawScene(id: pic.id, companion: model.state.companion)
                    .frame(width: 192, height: 124)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Text(pic.name).font(Theme.body(17).bold()).foregroundStyle(Theme.ink).lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(best.map { "\($0) pieces" } ?? " ").font(Theme.body(14)).foregroundStyle(Theme.sageDeep)
            }
            .padding(10)
            .frame(width: Self.cardSize.width - 6, height: Self.cardSize.height - 6)
            .background(RoundedRectangle(cornerRadius: 20).fill(Theme.card).paperCut(0.7))
            .overlay(isSuggested ? RoundedRectangle(cornerRadius: 20).stroke(Theme.sun, lineWidth: 5) : nil)
            .overlay(alignment: .topTrailing) { if best != nil { tick.offset(x: 12, y: -12) } }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("jig.map.\(pic.id)")
        .accessibilityLabel(pic.name + (best != nil ? ", finished" : ""))
        .accessibilityValue("\(best.map { "done=\($0)" } ?? "new")\(isSuggested ? ";suggested" : "")")
    }

    private var tick: some View {
        ZStack {
            Circle().fill(Theme.sageDeep).frame(width: 46, height: 46).paperCut(0.5)
            Image(systemName: "checkmark").font(.system(size: 24, weight: .heavy)).foregroundStyle(.white)
        }
        .accessibilityHidden(true)
    }
}

/// The board, the tray, and the overlays for one puzzle.
struct JigsawBoard: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject var game: JigsawGame
    let onNext: () -> Void

    @State private var dragging: Int?
    @State private var dragPoint: CGPoint = .zero
    @State private var lastTouched: Int?
    @State private var wobbleAmount: CGFloat = 0
    @State private var recorded = false

    static let boardOrigin = CGPoint(x: 36, y: 132)

    /// The size of one piece's core square, so the board fits beside the tray.
    static func cell(cols: Int, rows: Int) -> CGFloat {
        min(660 / CGFloat(cols), 460 / CGFloat(rows))
    }

    private var cell: CGFloat {
        Self.cell(cols: game.plan.cols, rows: game.plan.rows)
    }
    private var margin: CGFloat { game.level.cut == .squares ? cell * 0.04 : cell * 0.24 }
    private var boardSize: CGSize { CGSize(width: cell * CGFloat(game.plan.cols), height: cell * CGFloat(game.plan.rows)) }
    private var boardRect: CGRect { CGRect(origin: Self.boardOrigin, size: boardSize) }

    var body: some View {
        GeometryReader { geo in
            let tray = trayRect(in: geo.size)
            ZStack(alignment: .topLeading) {
                board
                ForEach(game.trayOrder.indices, id: \.self) { slotIndex in
                    let p = game.trayOrder[slotIndex]
                    // The dragged piece stays the same view (it just follows the finger): removing it mid-drag
                    // would cancel the gesture, and the drop would never arrive.
                    if !game.pieces[p].placed {
                        trayPiece(p, center: dragging == p ? dragPoint : trayCenter(slotIndex, in: tray),
                                  scale: dragging == p ? 1 : trayScale(in: tray))
                            .zIndex(dragging == p ? 10 : 0)
                    }
                }
                hintButton.position(x: boardRect.maxX - 40, y: min(geo.size.height - 70, boardRect.maxY + 60))
                overlays(geo.size)
            }
            .coordinateSpace(name: "jig")
        }
        .ignoresSafeArea()
        .onChange(of: game.wobble) { _, w in
            guard w != nil else { return }
            withAnimation(.linear(duration: 0.4)) { wobbleAmount += 1 }
        }
        .onChange(of: game.overlay) { _, o in overlayChanged(o) }
    }

    // MARK: Board

    private var board: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.75))
                .frame(width: boardSize.width, height: boardSize.height)
                .paperCut(0.5)
            Image(uiImage: game.image).resizable().frame(width: boardSize.width, height: boardSize.height)
                .opacity(game.overlay == .done ? 1 : guideOpacity)
            gridLines
            ForEach(game.pieces.filter(\.placed)) { p in
                let (c, r) = game.plan.position(p.id)
                pieceView(p.id)
                    .position(x: (CGFloat(c) + 0.5) * cell, y: (CGFloat(r) + 0.5) * cell)
                    .opacity(game.overlay == .done ? 0 : 1)
            }
            hintMarks
            slipMark
            // Invisible slots for QA and VoiceOver.
            ForEach(0..<game.pieces.count, id: \.self) { i in
                let (c, r) = game.plan.position(i)
                // Identifiers go before .position, which would otherwise make each slot's frame the whole board.
                Rectangle().fill(Color.white.opacity(0.001))
                    .frame(width: cell, height: cell)
                    .accessibilityElement()
                    .accessibilityLabel("Space \(i + 1)")
                    .accessibilityIdentifier("jig.slot.\(i)")
                    .position(x: (CGFloat(c) + 0.5) * cell, y: (CGFloat(r) + 0.5) * cell)
            }
        }
        .frame(width: boardSize.width, height: boardSize.height, alignment: .topLeading)
        .scaleEffect(game.overlay == .done ? 1.03 : 1)
        .animation(.spring(response: 0.6, dampingFraction: 0.5), value: game.overlay == .done)
        .offset(x: Self.boardOrigin.x, y: Self.boardOrigin.y)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("jig.board")
        .accessibilityValue("placed=\(game.placedCount)/\(game.pieces.count);pieces=\(game.pieces.count)")
    }

    private var guideOpacity: Double {
        switch game.level.guide {
        case .full: return 0.35
        case .faint: return 0.14
        case .none: return 0
        }
    }

    private var gridLines: some View {
        Path { p in
            for c in 1..<max(2, game.plan.cols) where c < game.plan.cols {
                p.move(to: CGPoint(x: CGFloat(c) * cell, y: 0))
                p.addLine(to: CGPoint(x: CGFloat(c) * cell, y: boardSize.height))
            }
            for r in 1..<max(2, game.plan.rows) where r < game.plan.rows {
                p.move(to: CGPoint(x: 0, y: CGFloat(r) * cell))
                p.addLine(to: CGPoint(x: boardSize.width, y: CGFloat(r) * cell))
            }
        }
        .stroke(Theme.tan, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var hintMarks: some View {
        if let t = game.hintTarget {
            let (c, r) = game.plan.position(t)
            if game.hintStep >= 2 {
                let x0 = CGFloat(max(0, c - 1)) * cell
                let y0 = CGFloat(max(0, r - 1)) * cell
                let x1 = CGFloat(min(game.plan.cols, c + 2)) * cell
                let y1 = CGFloat(min(game.plan.rows, r + 2)) * cell
                RoundedRectangle(cornerRadius: 10).fill(Theme.sun.opacity(0.35))
                    .frame(width: x1 - x0, height: y1 - y0)
                    .position(x: (x0 + x1) / 2, y: (y0 + y1) / 2)
                    .allowsHitTesting(false)
                    .accessibilityIdentifier("jig.hint.area")
            }
            if game.hintStep >= 3 {
                shape(t).stroke(Theme.clay, style: StrokeStyle(lineWidth: 4, dash: [8, 5]))
                    .frame(width: cell + 2 * margin, height: cell + 2 * margin)
                    .position(x: (CGFloat(c) + 0.5) * cell, y: (CGFloat(r) + 0.5) * cell)
                    .allowsHitTesting(false)
                    .accessibilityIdentifier("jig.hint.outline")
            }
        }
    }

    @ViewBuilder
    private var slipMark: some View {
        if let s = game.slipSlot, let p = game.slipPiece, game.overlay == .slipAsk || game.overlay == .slipWhy {
            let (c, r) = game.plan.position(s)
            pieceView(p)
                .position(x: (CGFloat(c) + 0.5) * cell + cell * 0.15, y: (CGFloat(r) + 0.5) * cell - cell * 0.15)
                .opacity(0.9)
                .allowsHitTesting(false)
        }
    }

    // MARK: Pieces

    private func shape(_ i: Int) -> JigsawPieceShape {
        JigsawPieceShape(edges: game.plan.edges(i), cut: game.level.cut, margin: margin)
    }

    private func pieceView(_ i: Int) -> some View {
        let (c, r) = game.plan.position(i)
        let side = cell + 2 * margin
        let s = shape(i)
        return ZStack(alignment: .topLeading) {
            Image(uiImage: game.image).resizable()
                .frame(width: boardSize.width, height: boardSize.height)
                .offset(x: -CGFloat(c) * cell + margin, y: -CGFloat(r) * cell + margin)
        }
        .frame(width: side, height: side, alignment: .topLeading)
        .clipShape(s)
        .overlay(s.stroke(Theme.ink.opacity(0.55), lineWidth: 1.5))
        .contentShape(s)
    }

    private func trayPiece(_ i: Int, center: CGPoint, scale: CGFloat) -> some View {
        pieceView(i)
            .rotationEffect(.degrees(Double(game.pieces[i].rotation)))
            .scaleEffect(scale)
            .frame(width: (cell + 2 * margin) * scale, height: (cell + 2 * margin) * scale)
            .modifier(Wobble(animatableData: game.wobble == i ? wobbleAmount : 0))
            .overlay(game.hintTarget == i && game.hintStep >= 1
                     ? RoundedRectangle(cornerRadius: 6).stroke(Theme.sun, lineWidth: 4) : nil)
            .gesture(
                DragGesture(minimumDistance: 3, coordinateSpace: .named("jig"))
                    .onChanged { v in
                        if dragging != i { dragging = i; lastTouched = i }
                        dragPoint = v.location
                    }
                    .onEnded { v in
                        drop(i, at: v.location)
                    }
            )
            .simultaneousGesture(TapGesture().onEnded { lastTouched = i; game.turn(i) })
            .accessibilityElement()
            .accessibilityIdentifier("jig.piece.\(i)")
            .accessibilityValue("home=\(i);rot=\(game.pieces[i].rotation)")
            .accessibilityAddTraits(.isButton)
            // Last, so the piece's frame (for touches and for QA) is the piece, not the whole screen.
            .position(center)
    }

    private func drop(_ i: Int, at point: CGPoint) {
        dragging = nil
        let slot: Int?
        if boardRect.contains(point) {
            let c = Int((point.x - boardRect.minX) / cell)
            let r = Int((point.y - boardRect.minY) / cell)
            slot = r * game.plan.cols + c
        } else {
            slot = nil
        }
        // Dropping back in the tray is just tidying, not a try.
        guard slot != nil else { return }
        game.drop(i, on: slot)
    }

    // MARK: Tray

    private func trayRect(in size: CGSize) -> CGRect {
        let x = boardRect.maxX + 28
        return CGRect(x: x, y: boardRect.minY, width: max(200, size.width - x - 24), height: max(200, size.height - boardRect.minY - 120))
    }

    private func trayGrid(in tray: CGRect) -> (cols: Int, rows: Int) {
        let n = game.trayOrder.count
        let cols = max(1, Int((Double(n) * Double(tray.width / tray.height)).squareRoot().rounded(.up)))
        return (cols, Int((Double(n) / Double(cols)).rounded(.up)))
    }

    private func trayScale(in tray: CGRect) -> CGFloat {
        let g = trayGrid(in: tray)
        let slot = min(tray.width / CGFloat(g.cols), tray.height / CGFloat(g.rows))
        return min(1, slot / (cell + 2 * margin) * 1.05)
    }

    private func trayCenter(_ index: Int, in tray: CGRect) -> CGPoint {
        let g = trayGrid(in: tray)
        let w = tray.width / CGFloat(g.cols)
        let h = tray.height / CGFloat(g.rows)
        return CGPoint(x: tray.minX + (CGFloat(index % g.cols) + 0.5) * w, y: tray.minY + (CGFloat(index / g.cols) + 0.5) * h)
    }

    // MARK: Hint button

    private var hintButton: some View {
        Button { askHint() } label: {
            ZStack {
                Circle().fill(Theme.card).frame(width: 76, height: 76).paperCut()
                Image(systemName: "lightbulb.fill").font(.system(size: 34, weight: .bold))
                    .foregroundStyle(game.missesInARow >= 2 ? Theme.sun : Theme.clay)
            }
        }
        .glow(game.missesInARow >= 2)
        .opacity(game.overlay == .none ? 1 : 0)
        .accessibilityIdentifier("jig.hint")
        .accessibilityLabel("Hint")
        .accessibilityValue("step=\(game.hintStep)")
    }

    private func askHint() {
        guard let step = game.hint(lastTouched: lastTouched) else { return }
        let line: LineID
        switch step {
        case .strategy:
            let t = game.hintTarget ?? 0
            line = game.strategyLine(for: t)
        case .area: line = "jig.hint.area"
        case .outline: line = "jig.hint.outline"
        case .slideHome: line = "jig.hint.slide"
        }
        model.speech.say([model.catalog.spoken(line)])
    }

    // MARK: Overlays: explain moment (J4), companion slip (J5), the finished picture

    private func overlayChanged(_ o: JigsawGame.Overlay) {
        switch o {
        case .explain: model.speech.say([model.catalog.spoken("jig.explain")])
        case .slipAsk: model.speech.say([model.catalog.spoken("jig.slip.ask")])
        case .slipWhy: model.speech.say([model.catalog.spoken("jig.slip.why")])
        case .done:
            if !recorded {
                recorded = true
                model.finishJigsaw(game.result(at: model.now))
            }
        case .none: break
        }
    }

    @ViewBuilder
    private func overlays(_ size: CGSize) -> some View {
        switch game.overlay {
        case .none: EmptyView()
        case .explain:
            choiceCard(size, mood: .thinking, title: "How did you find that one?",
                       choices: [("colour", "Colours"), ("edge", "Edge shape"), ("picture", "The picture")]
                           + (game.level.turning ? [("turn", "Turning")] : []),
                       idPrefix: "jig.explain") { choice in
                game.explain(choice)
                model.speech.say([model.catalog.spoken("jig.explain.\(choice)")])
            }
        case .slipAsk:
            choiceCard(size, mood: .thinking, title: "Does my piece fit here?",
                       choices: [("yes", "Yes"), ("no", "No")], idPrefix: "jig.slip") { choice in
                if choice == "yes" { model.speech.say([model.catalog.spoken("jig.slip.missed")]) }
                game.slipAnswer(fits: choice == "yes")
            }
        case .slipWhy:
            choiceCard(size, mood: .thinking, title: "Why doesn't it fit?",
                       choices: [("edge", "Edge shape"), ("colour", "Colours"), ("picture", "The picture")],
                       idPrefix: "jig.slip.why") { _ in
                model.speech.say([model.catalog.spoken("jig.slip.caught")])
                game.endSlip()
            }
        case .done:
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    SparkleView(mood: .happy, size: 170)
                    Spacer()
                    NextButton { onNext() }
                }
                .padding(.horizontal, 40).padding(.bottom, 30)
            }
            .frame(width: size.width, height: size.height)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("jig.done")
        }
    }

    private func choiceCard(_ size: CGSize, mood: SparkleView.Mood, title: String, choices: [(String, String)],
                            idPrefix: String, pick: @escaping (String) -> Void) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 20) {
                SparkleView(mood: mood, size: 140)
                VStack(alignment: .leading, spacing: 14) {
                    Text(title).font(Theme.title(26)).foregroundStyle(Theme.ink)
                    HStack(spacing: 14) {
                        ForEach(choices, id: \.0) { c in
                            Button { pick(c.0) } label: {
                                VStack(spacing: 6) {
                                    choiceIcon(c.0)
                                    Text(c.1).font(Theme.body(17).bold()).foregroundStyle(Theme.ink)
                                }
                                .frame(width: 128, height: 112)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Theme.sagePale))
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("\(idPrefix).\(c.0)")
                        }
                    }
                }
            }
            .padding(22)
            .background(RoundedRectangle(cornerRadius: 26).fill(Theme.card).paperCut())
            .padding(.bottom, 30)
        }
        .frame(width: size.width, height: size.height)
    }

    @ViewBuilder
    private func choiceIcon(_ id: String) -> some View {
        switch id {
        case "colour":
            HStack(spacing: 3) { ForEach([Theme.rose, Theme.sun, Theme.river], id: \.self) { Circle().fill($0).frame(width: 18) } }
                .frame(height: 50)
        case "edge":
            JigsawPieceShape(edges: [0, 1, -1, 0], cut: .tabs, margin: 10).stroke(Theme.ink, lineWidth: 3).frame(width: 56, height: 56)
        case "picture":
            Image(systemName: "photo").font(.system(size: 34)).foregroundStyle(Theme.clay).frame(height: 50)
        case "turn":
            Image(systemName: "arrow.clockwise").font(.system(size: 34, weight: .bold)).foregroundStyle(Theme.clay).frame(height: 50)
        case "yes":
            Image(systemName: "checkmark").font(.system(size: 34, weight: .bold)).foregroundStyle(Theme.sageDeep).frame(height: 50)
        default:
            Image(systemName: "xmark").font(.system(size: 34, weight: .bold)).foregroundStyle(Theme.poppy).frame(height: 50)
        }
    }
}
