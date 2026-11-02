import KingdomCore
import PencilKit
import SwiftUI

/// F2, F4: a puzzle scroll, one item at a time. She writes the answer with the pen (read on the device) or taps
/// the number keys; the app checks it, gives one retry, then shows the answer. No stars, no score for her.
struct WorksheetView: View {
    @EnvironmentObject var model: AppModel
    let sheet: Worksheet

    @State private var index = 0
    @State private var typed = ""
    @State private var attempts = 0
    @State private var firstTry: [String: Bool] = [:]
    @State private var boxState: SentenceRow.BoxState = .waiting
    @State private var clearToken = 0
    @State private var reading = false
    @State private var itemDone = false
    @State private var allDone = false

    private var item: SheetItem? { index < sheet.items.count ? sheet.items[index] : nil }

    var body: some View {
        ZStack {
            // Scrolls are always on day paper so dark ink reads on every page.
            PaperStage(chapter: nil, showSky: false)
            VStack(spacing: 22) {
                HStack(spacing: 8) {
                    ForEach(sheet.items.indices, id: \.self) { i in
                        Circle().fill(i < index || (i == index && itemDone) ? Theme.sage : Theme.card)
                            .overlay(Circle().stroke(Theme.tan, lineWidth: 2))
                            .frame(width: 18, height: 18)
                    }
                }
                .padding(.top, 108)
                if allDone {
                    finished
                } else if let item {
                    itemView(item)
                        .id(item.id)
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("sheet.item.\(item.id)")
                        .accessibilityValue("kind=\(item.kind.rawValue);answer=\(item.answer)")
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 40)
            ChildCorners(onCastle: { model.goCastle() }, onEar: { speakItem() }, onLock: { model.openParentGate() })
            if itemDone && !allDone {
                VStack { Spacer(); HStack { Spacer(); NextButton { nextItem() } } }.padding(28)
            }
        }
        .onAppear {
            model.speech.say([model.catalog.spoken("sheet.intro"), item.flatMap { model.catalog.spoken($0.promptLine) }])
        }
    }

    // MARK: Items

    @ViewBuilder
    private func itemView(_ item: SheetItem) -> some View {
        switch item.kind {
        case .drawIt:
            VStack(spacing: 16) {
                if !item.tokens.isEmpty { SentenceRow(tokens: item.tokens, size: 44) }
                ZStack {
                    RoundedRectangle(cornerRadius: 22).fill(Color.white).paperCut(0.6)
                    WritingPad(clearToken: clearToken, lineWidth: 8)
                }
                .frame(maxWidth: 820, maxHeight: 380)
                .accessibilityIdentifier("sheet.canvas")
                Button { markDone(nil) } label: {
                    Text("Done").font(Theme.title(28)).foregroundStyle(Theme.ink)
                        .padding(.horizontal, 40).padding(.vertical, 14)
                        .background(Capsule().fill(Theme.sun)).paperCut()
                }
                .accessibilityIdentifier("sheet.drawDone")
                .opacity(itemDone ? 0 : 1)
            }
        case .makePuzzle:
            MakePuzzleView(compact: true) { markDone(nil) }
        default:
            VStack(spacing: 22) {
                ProblemPicture(picture: item.picture, size: 38)
                SentenceRow(tokens: item.tokens, box: typed, boxState: boxState)
                if !itemDone {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22).fill(Color.white.opacity(0.9))
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.tan, style: StrokeStyle(lineWidth: 3, dash: [10, 8])))
                        Text(reading ? "Reading…" : "Write here").font(Theme.body(18)).foregroundStyle(Theme.muted.opacity(0.6))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(12)
                        WritingPad(clearToken: clearToken) { drawing in read(drawing, item: item) }
                    }
                    .frame(width: 360, height: 200)
                    .accessibilityIdentifier("sheet.pad")
                    KeyRow(signs: item.kind == .missingSign ? MathOp.allCases : nil) { key($0, item: item) }
                }
            }
        }
    }

    private var finished: some View {
        VStack(spacing: 24) {
            SparkleView(mood: .happy, size: 220)
            Text("Scroll finished!").font(Theme.title(40)).foregroundStyle(Theme.ink)
            Button { model.finishSheet(sheet, firstTry: firstTry) } label: {
                Text("Back to the Puzzle Board").font(Theme.title(28)).foregroundStyle(Theme.ink)
                    .padding(.horizontal, 36).padding(.vertical, 16)
                    .background(Capsule().fill(Theme.sun)).paperCut()
            }
            .accessibilityIdentifier("sheet.finish")
        }
        .padding(.top, 30)
    }

    // MARK: Input

    private func key(_ k: String, item: SheetItem) {
        guard !itemDone else { return }
        switch k {
        case "⌫": typed = String(typed.dropLast())
        case "✓": if !typed.isEmpty { check(typed, item: item) }
        default:
            if item.kind == .missingSign {
                typed = k
                check(k, item: item)
            } else if typed.count < 3 {
                typed += k
                // A one-digit answer is checked as soon as it's typed; longer ones wait for the check key.
                if item.answer.count == typed.count { check(typed, item: item) }
            }
        }
    }

    private func read(_ drawing: PKDrawing, item: SheetItem) {
        guard !itemDone, !reading else { return }
        reading = true
        Handwriting.read(drawing, wantsSign: item.kind == .missingSign) { result in
            reading = false
            guard !itemDone else { return }
            guard let result else {
                // AC-S3: an unreadable answer never counts as wrong.
                clearToken += 1
                model.speech.say([model.catalog.spoken("sheet.unreadable")])
                return
            }
            typed = result
            check(result, item: item)
        }
    }

    private func check(_ given: String, item: SheetItem) {
        if item.check(given) {
            if firstTry[item.id] == nil { firstTry[item.id] = attempts == 0 }
            boxState = .right
            markDone(model.catalog.spoken("sheet.right"))
        } else {
            attempts += 1
            clearToken += 1
            if attempts >= 2 {
                firstTry[item.id] = false
                typed = item.answer
                boxState = .shown
                markDone(model.catalog.spoken("sheet.show"))
            } else {
                typed = ""
                model.speech.say([model.catalog.spoken("sheet.tryAgain")])
            }
        }
    }

    private func markDone(_ line: SpokenLine?) {
        itemDone = true
        if let line { model.speech.say([line]) }
    }

    private func nextItem() {
        index += 1
        typed = ""
        attempts = 0
        boxState = .waiting
        clearToken += 1
        itemDone = false
        if index >= sheet.items.count {
            allDone = true
            model.speech.say([model.catalog.spoken("sheet.done")])
        } else {
            speakItem()
        }
    }

    private func speakItem() {
        guard let item else { return }
        model.speech.say([model.catalog.spoken(item.promptLine)])
    }
}

/// L15, L6: she picks two numbers and a sign; the companion answers, and sometimes slips for her to catch.
struct MakePuzzleView: View {
    @EnvironmentObject var model: AppModel
    var compact = false
    let onDone: () -> Void

    @State private var a = 6
    @State private var b = 3
    @State private var op: MathOp?
    @State private var companionAnswer: Int?
    @State private var made: MadePuzzle?
    @State private var verdict: String?
    @State private var closed = false

    var body: some View {
        let ops = model.problems.unlocked(model.state)
        VStack(spacing: 20) {
            HStack(spacing: 24) {
                stepper(value: $a, id: "make.a")
                VStack(spacing: 8) {
                    ForEach(ops, id: \.self) { o in
                        Button { op = o; companionAnswer = nil; verdict = nil } label: {
                            Text(o.sign).font(Theme.numeral(40)).foregroundStyle(Theme.ink)
                                .frame(width: 70, height: 60)
                                .background(RoundedRectangle(cornerRadius: 12).fill(op == o ? Theme.sun : Theme.card))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.tan, lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("make.op.\(o.rawValue)")
                    }
                }
                stepper(value: $b, id: "make.b")
            }
            if let op, companionAnswer == nil {
                Button { ask(op) } label: {
                    Text("Ask \(model.state.companion.name)").font(Theme.title(26)).foregroundStyle(Theme.ink)
                        .padding(.horizontal, 30).padding(.vertical, 12)
                        .background(Capsule().fill(Theme.sun)).paperCut()
                }
                .accessibilityIdentifier("make.ask")
            }
            if let made, let answer = companionAnswer {
                HStack(spacing: 20) {
                    SparkleView(mood: .thinking, size: compact ? 120 : 150)
                    // Once she has judged, the box shows the true answer.
                    SentenceRow(tokens: [String(made.a), made.op.sign, String(made.b), "=", "?"],
                                box: String(verdict == nil ? answer : made.answer),
                                boxState: verdict == nil ? .waiting : .right, size: 44)
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("make.companion")
                .accessibilityValue("said=\(answer);right=\(made.answer)")
                if verdict == nil {
                    HStack(spacing: 24) {
                        judge("Right!", correct: true, id: "make.right")
                        judge("Oops!", correct: false, id: "make.oops")
                    }
                } else if !closed {
                    Button { closed = true; onDone() } label: {
                        Text("Done").font(Theme.title(26)).foregroundStyle(Theme.ink)
                            .padding(.horizontal, 36).padding(.vertical, 12)
                            .background(Capsule().fill(Theme.sun)).paperCut()
                    }
                    .accessibilityIdentifier("make.done")
                }
            }
        }
        .onAppear { model.speech.say([model.catalog.spoken("board.make")]) }
    }

    private func stepper(value: Binding<Int>, id: String) -> some View {
        VStack(spacing: 6) {
            Button { value.wrappedValue = min(20, value.wrappedValue + 1); companionAnswer = nil; verdict = nil } label: {
                Image(systemName: "chevron.up").font(.system(size: 30, weight: .bold)).frame(width: 80, height: 50)
            }
            .accessibilityIdentifier("\(id).up")
            Text("\(value.wrappedValue)").font(Theme.numeral(56)).foregroundStyle(Theme.ink)
                .frame(width: 100, height: 80)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.card).paperCut(0.5))
                .accessibilityIdentifier("\(id).value")
            Button { value.wrappedValue = max(0, value.wrappedValue - 1); companionAnswer = nil; verdict = nil } label: {
                Image(systemName: "chevron.down").font(.system(size: 30, weight: .bold)).frame(width: 80, height: 50)
            }
            .accessibilityIdentifier("\(id).down")
        }
        .foregroundStyle(Theme.clay)
    }

    private func judge(_ label: String, correct: Bool, id: String) -> some View {
        Button { decide(saysRight: correct) } label: {
            Text(label).font(Theme.title(28)).foregroundStyle(Theme.ink)
                .padding(.horizontal, 30).padding(.vertical, 14)
                .background(Capsule().fill(correct ? Theme.sagePale : Color(hex: 0xF4C7B8))).paperCut()
        }
        .accessibilityIdentifier(id)
    }

    private func ask(_ op: MathOp) {
        let p = MadePuzzle(op: op, a: a, b: b)
        a = p.a
        b = p.b
        made = p
        let answer = p.companionAnswer(made: model.state.board.puzzlesMade)
        companionAnswer = answer
        model.madePuzzle()
        model.speech.say([model.catalog.spoken("board.make.answer", n: answer)])
    }

    private func decide(saysRight: Bool) {
        guard let made, let answer = companionAnswer else { return }
        let companionRight = answer == made.answer
        let line: LineID
        switch (companionRight, saysRight) {
        case (true, true): line = "board.make.right"
        case (false, false): line = "board.make.caught"
        case (false, true): line = "board.make.missed"
        case (true, false): line = "board.make.wrongCheck"
        }
        verdict = line
        model.speech.say([model.catalog.spoken(line, n: made.answer)])
    }
}
