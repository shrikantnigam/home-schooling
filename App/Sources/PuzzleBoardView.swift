import KingdomCore
import SwiftUI

/// F3 (charter L14, L15): the Puzzle Board in the castle. She picks the sign first, then a helper, then the
/// answer. The story fades over three levels: spoken with a picture, then words only, then the bare sentence.
/// Each solved puzzle lights a lantern. On the side: make a puzzle for the companion, and the puzzle scrolls.
struct PuzzleBoardView: View {
    @EnvironmentObject var model: AppModel

    enum Step: Equatable { case sign, tool, answer, lit }
    enum Tool: String, CaseIterable { case counters, line, head }

    @State private var puzzle: BoardPuzzle?
    @State private var step: Step = .sign
    @State private var chosenSign: MathOp?
    @State private var signMisses = 0
    @State private var answerMisses = 0
    @State private var tool: Tool?
    @State private var shownAnswer: Int?
    @State private var making = false
    @State private var wobbleKey: String?
    @State private var wobble: CGFloat = 0

    private var taught: [MathOp] { model.problems.unlocked(model.state) }

    var body: some View {
        ZStack {
            PaperStage(chapter: nil, showSky: false)
            VStack(spacing: 18) {
                lanterns.padding(.top, 104)
                HStack(alignment: .top, spacing: 26) {
                    VStack(spacing: 20) {
                        if making {
                            MakePuzzleView { making = false; nextPuzzle(speak: true) }
                                .padding(24)
                                .background(RoundedRectangle(cornerRadius: 26).fill(Theme.card.opacity(0.95)).paperCut(0.6))
                        } else if let puzzle {
                            card(puzzle)
                        } else {
                            Text("Finish a place on the map to get puzzles here.")
                                .font(Theme.title(26)).foregroundStyle(Theme.ink)
                                .padding(30)
                                .background(RoundedRectangle(cornerRadius: 26).fill(Theme.card.opacity(0.95)).paperCut(0.6))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    side.frame(width: 250)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 36)
            ChildCorners(onCastle: { model.goCastle() }, onEar: { speakPuzzle() }, onLock: { model.openParentGate() })
            if step == .lit && !making {
                VStack { Spacer(); HStack { Spacer(); NextButton { nextPuzzle(speak: true) } } }.padding(28)
            }
        }
        .onAppear {
            if puzzle == nil { puzzle = model.currentPuzzle() }
            let intro = model.firstTimeThisSession("board") ? [model.catalog.spoken("board.intro")] : []
            model.speech.say(intro + puzzleLines())
        }
    }

    // MARK: Lanterns

    private var lanterns: some View {
        let count = model.state.board.lanterns
        let shown = min(count, 12)
        return HStack(spacing: 10) {
            ForEach(0..<12, id: \.self) { i in LanternIcon(lit: i < shown, size: 34) }
            if count > 12 {
                Text("+\(count - 12)").font(Theme.title(22)).foregroundStyle(Theme.ink)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 8)
        .background(Capsule().fill(Theme.card.opacity(0.85)).paperCut(0.4))
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("board.lanterns")
        .accessibilityValue("\(count)")
    }

    // MARK: The puzzle card

    private func card(_ p: BoardPuzzle) -> some View {
        VStack(spacing: 20) {
            if p.level == 2 {
                if let line = model.catalog.spoken(p.storyLine, a: p.a, b: p.b) {
                    Text(line.text).font(Theme.body(24)).foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center).frame(maxWidth: 620)
                        .accessibilityIdentifier("board.storyText")
                }
            }
            if showCounters(p) {
                ProblemPicture(picture: WorksheetMaker.picture(p.op, p.a, p.b), size: 36)
            }
            if (step == .answer || step == .lit) && tool == .line {
                HopLine(puzzle: p).frame(maxWidth: 640, minHeight: 90, maxHeight: 90)
            }
            if (step == .answer || step == .lit) && tool == .head {
                SparkleView(mood: .thinking, size: 110)
            }
            SentenceRow(tokens: tokens(p), box: boxText(p), boxState: boxState(p), size: 50)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("board.sentence")
                .accessibilityValue(tokens(p).joined(separator: " ").replacingOccurrences(of: "○", with: chosenSign?.sign ?? "○"))
            switch step {
            case .sign: signPicker(p)
            case .tool: toolPicker
            case .answer: answerTiles(p)
            case .lit: EmptyView()
            }
        }
        .padding(26)
        .background(RoundedRectangle(cornerRadius: 26).fill(Theme.card.opacity(0.95)).paperCut(0.6))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("board.puzzle")
        .accessibilityValue("op=\(p.op.rawValue);level=\(p.level);answer=\(p.answer);step=\(String(describing: step))")
    }

    private func showCounters(_ p: BoardPuzzle) -> Bool {
        if p.level == 1 { return true }
        return step != .sign && tool == .counters
    }

    /// The sentence: the sign is a box until she picks it; at level 3 the answer is already there.
    private func tokens(_ p: BoardPuzzle) -> [String] {
        let sign = chosenSign?.sign ?? "○"
        let right = p.asksForAnswer ? "?" : String(p.answer)
        return [String(p.a), sign, String(p.b), "=", right]
    }

    private func boxText(_ p: BoardPuzzle) -> String {
        if chosenSign == nil { return "" }
        return shownAnswer.map(String.init) ?? ""
    }

    private func boxState(_ p: BoardPuzzle) -> SentenceRow.BoxState {
        guard step == .lit else { return .waiting }
        return answerMisses >= 2 ? .shown : .right
    }

    private func signPicker(_ p: BoardPuzzle) -> some View {
        HStack(spacing: 16) {
            ForEach(MathOp.allCases, id: \.self) { op in
                let open = taught.contains(op)
                Button { pickSign(op, puzzle: p) } label: {
                    Text(op.sign).font(Theme.numeral(54)).foregroundStyle(Theme.ink)
                        .frame(width: 104, height: 104)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.card))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.tan, lineWidth: 3))
                        .paperCut(0.6)
                }
                .buttonStyle(.plain)
                .disabled(!open)
                .opacity(open ? 1 : 0.3)
                .modifier(Wobble(animatableData: wobbleKey == op.rawValue ? wobble : 0))
                .accessibilityIdentifier("board.op.\(op.rawValue)")
                .accessibilityLabel(op.spoken)
            }
        }
    }

    private var toolPicker: some View {
        HStack(spacing: 20) {
            ForEach(Tool.allCases, id: \.self) { t in
                Button { pickTool(t) } label: {
                    VStack(spacing: 6) {
                        toolIcon(t).frame(width: 90, height: 70)
                        Text(toolName(t)).font(Theme.body(18).bold()).foregroundStyle(Theme.ink)
                    }
                    .frame(width: 150, height: 130)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Theme.sagePale))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.tan, lineWidth: 3))
                    .paperCut(0.6)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("board.tool.\(t.rawValue)")
                .accessibilityLabel(toolName(t))
            }
        }
    }

    private func toolName(_ t: Tool) -> String {
        switch t {
        case .counters: return "Counters"
        case .line: return "Number line"
        case .head: return "In my head"
        }
    }

    @ViewBuilder
    private func toolIcon(_ t: Tool) -> some View {
        switch t {
        case .counters:
            HStack(spacing: 2) { ForEach(0..<3, id: \.self) { _ in CounterSprite(style: .gem, size: 28) } }
        case .line:
            ZStack {
                Capsule().fill(Theme.ink).frame(width: 80, height: 4)
                HStack(spacing: 16) { ForEach(0..<5, id: \.self) { _ in Capsule().fill(Theme.ink).frame(width: 3, height: 16) } }
            }
        case .head:
            Image(systemName: "brain.head.profile").font(.system(size: 44, weight: .bold)).foregroundStyle(Theme.deepLavender)
        }
    }

    private func answerTiles(_ p: BoardPuzzle) -> some View {
        HStack(spacing: 16) {
            ForEach(p.choices, id: \.self) { n in
                Button { pickAnswer(n, puzzle: p) } label: {
                    Text("\(n)").font(Theme.numeral(50)).foregroundStyle(Theme.ink)
                        .frame(width: 104, height: 104)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.card))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.tan, lineWidth: 3))
                        .paperCut(0.6)
                }
                .buttonStyle(.plain)
                .modifier(Wobble(animatableData: wobbleKey == "a\(n)" ? wobble : 0))
                .accessibilityIdentifier("board.answer.\(n)")
            }
        }
    }

    // MARK: Side: make a puzzle, scrolls

    private var side: some View {
        let scrolls = model.sheetMaker.available(state: model.state)
        return VStack(spacing: 14) {
            if !taught.isEmpty {
                Button { making = true } label: {
                    VStack(spacing: 6) {
                        SparkleView(mood: .happy, size: 80)
                        Text("Make a puzzle").font(Theme.title(22)).foregroundStyle(Theme.ink)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Theme.sun.opacity(0.9))).paperCut(0.6)
                }
                .buttonStyle(.plain)
                .disabled(making)
                .accessibilityIdentifier("board.make")
            }
            Text("Puzzle scrolls").font(Theme.title(22)).foregroundStyle(Theme.ink)
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(scrolls, id: \.id) { s in
                        let done = model.state.sheets[s.id]?.finished != nil
                        Button { model.openSheet(s.id) } label: {
                            HStack(spacing: 10) {
                                Image(systemName: done ? "scroll.fill" : "scroll").font(.system(size: 26))
                                    .foregroundStyle(done ? Theme.sage : Theme.clay)
                                Text(scrollTitle(s)).font(Theme.body(18).bold()).foregroundStyle(Theme.ink)
                                    .lineLimit(1).minimumScaleFactor(0.7)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 14).frame(height: 58)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.card)).paperCut(0.4)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("board.scroll.\(s.id)")
                        .accessibilityValue(done ? "done" : "new")
                    }
                }
                .padding(4)
            }
            .frame(maxHeight: 420)
        }
    }

    private func scrollTitle(_ s: Worksheet) -> String {
        guard let place = s.place else { return "Mixed scroll" }
        return model.content.chapters.first { $0.id == place }?.place ?? "Scroll"
    }

    // MARK: Flow

    private func puzzleLines() -> [SpokenLine?] {
        guard let p = puzzle else { return [] }
        var lines: [SpokenLine?] = []
        if p.level < 3 { lines.append(model.catalog.spoken(p.storyLine, a: p.a, b: p.b)) }
        lines.append(model.catalog.spoken(p.asksForAnswer ? "board.pickOp" : "board.pickSign"))
        return lines
    }

    private func speakPuzzle() {
        guard let p = puzzle else { return }
        switch step {
        case .sign: model.speech.say(puzzleLines())
        case .tool: model.speech.say([model.catalog.spoken("board.pickTool")])
        case .answer:
            let story: SpokenLine? = p.level < 3 ? model.catalog.spoken(p.storyLine, a: p.a, b: p.b) : nil
            model.speech.say([story, model.catalog.spoken("board.ask")])
        case .lit: model.speech.say([model.catalog.spoken("board.light")])
        }
    }

    private func pickSign(_ op: MathOp, puzzle p: BoardPuzzle) {
        guard step == .sign else { return }
        if op == p.op {
            chosenSign = op
            if p.asksForAnswer {
                step = .tool
                model.speech.say([model.catalog.spoken("board.showOp.\(op.rawValue)"), model.catalog.spoken("board.pickTool")])
            } else {
                light(p, extra: [model.catalog.spoken("board.showOp.\(op.rawValue)")])
            }
        } else {
            signMisses += 1
            shake(op.rawValue)
            if signMisses >= 2 {
                // Second miss: show the sign and say why, then carry on.
                chosenSign = p.op
                let show = model.catalog.spoken("board.showOp.\(p.op.rawValue)")
                if p.asksForAnswer {
                    step = .tool
                    model.speech.say([show, model.catalog.spoken("board.pickTool")])
                } else {
                    light(p, extra: [show])
                }
            } else {
                model.speech.say([model.catalog.spoken("board.wrongOp")])
            }
        }
    }

    private func pickTool(_ t: Tool) {
        guard step == .tool else { return }
        tool = t
        step = .answer
        model.speech.say([model.catalog.spoken("board.ask")])
    }

    private func pickAnswer(_ n: Int, puzzle p: BoardPuzzle) {
        guard step == .answer else { return }
        if n == p.answer {
            shownAnswer = n
            light(p, extra: [model.catalog.spoken("sheet.right")])
        } else {
            answerMisses += 1
            shake("a\(n)")
            if answerMisses >= 2 {
                shownAnswer = p.answer
                light(p, extra: [model.catalog.spoken("sheet.show")])
            } else {
                model.speech.say([model.catalog.spoken("sheet.tryAgain")])
            }
        }
    }

    private func light(_ p: BoardPuzzle, extra: [SpokenLine?]) {
        if !p.asksForAnswer { shownAnswer = nil }
        step = .lit
        model.finishPuzzle(p, firstTry: signMisses == 0 && answerMisses == 0)
        model.speech.say(extra + [model.catalog.spoken("board.light")])
    }

    private func shake(_ key: String) {
        wobbleKey = key
        withAnimation(.linear(duration: 0.4)) { wobble += 1 }
    }

    private func nextPuzzle(speak: Bool) {
        puzzle = model.currentPuzzle()
        step = .sign
        chosenSign = nil
        signMisses = 0
        answerMisses = 0
        tool = nil
        shownAnswer = nil
        if speak { model.speech.say(puzzleLines()) }
    }
}

/// A paper lantern; lit ones glow gold.
struct LanternIcon: View {
    var lit: Bool
    var size: CGFloat = 34

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Theme.woodDark).frame(width: size * 0.4, height: size * 0.12)
            RoundedRectangle(cornerRadius: size * 0.3)
                .fill(lit ? Theme.gold : Theme.tan.opacity(0.6))
                .overlay(RoundedRectangle(cornerRadius: size * 0.3).stroke(Theme.woodDark, lineWidth: 2))
                .frame(width: size * 0.7, height: size * 0.85)
                .shadow(color: lit ? Theme.gold.opacity(0.8) : .clear, radius: lit ? 8 : 0)
            Capsule().fill(Theme.woodDark).frame(width: size * 0.4, height: size * 0.12)
        }
        .frame(width: size, height: size * 1.15)
    }
}

/// The number line helper: hops drawn for the puzzle's sign.
struct HopLine: View {
    let puzzle: BoardPuzzle

    /// Each hop as (from, to).
    private var hops: [(Int, Int)] {
        let p = puzzle
        switch p.op {
        case .add: return (0..<p.b).map { (p.a + $0, p.a + $0 + 1) }
        case .subtract: return (0..<p.b).map { (p.a - $0, p.a - $0 - 1) }
        case .multiply: return (0..<p.a).map { ($0 * p.b, ($0 + 1) * p.b) }
        case .divide: return (0..<max(0, p.answer)).map { ($0 * p.b, ($0 + 1) * p.b) }
        }
    }

    private var top: Int {
        let p = puzzle
        return max(10, min(25, max(p.a, p.answer, hops.map { max($0.0, $0.1) }.max() ?? 0)))
    }

    private func x(_ n: Int, width: CGFloat) -> CGFloat {
        15 + CGFloat(n) * (width - 30) / CGFloat(top)
    }

    private func axis(width w: CGFloat, baseY: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: x(0, width: w), y: baseY))
        p.addLine(to: CGPoint(x: x(top, width: w), y: baseY))
        for n in 0...top {
            p.move(to: CGPoint(x: x(n, width: w), y: baseY - 8))
            p.addLine(to: CGPoint(x: x(n, width: w), y: baseY + 8))
        }
        return p
    }

    private func arcs(width w: CGFloat, baseY: CGFloat) -> Path {
        var p = Path()
        for h in hops {
            let a = CGPoint(x: x(h.0, width: w), y: baseY - 4)
            let b = CGPoint(x: x(h.1, width: w), y: baseY - 4)
            let lift: CGFloat = min(50, abs(b.x - a.x) * 0.6)
            p.move(to: a)
            p.addQuadCurve(to: b, control: CGPoint(x: (a.x + b.x) / 2, y: baseY - 4 - lift))
        }
        return p
    }

    var body: some View {
        GeometryReader { geo in
            let w: CGFloat = geo.size.width
            let baseY: CGFloat = geo.size.height - 26
            ZStack(alignment: .topLeading) {
                axis(width: w, baseY: baseY).stroke(Theme.ink, lineWidth: 2.5)
                ForEach(0...top, id: \.self) { n in
                    Text("\(n)").font(Theme.body(13).bold()).foregroundStyle(Theme.ink)
                        .position(x: x(n, width: w), y: baseY + 18)
                }
                arcs(width: w, baseY: baseY).stroke(Theme.clay, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
        }
        .accessibilityHidden(true)
    }
}
