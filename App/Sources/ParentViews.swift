import AVFoundation
import KingdomCore
import SwiftUI
import UIKit

/// The way into the grown-ups' area. With a PIN set (Shrikant, 2026-11-03), a number pad. Without one (installs
/// from before), or after "Forgot PIN?", the old two steps: hold two fingers for 3 seconds, then type this year.
/// Nothing here is spoken (Gate mock).
struct ParentGateView: View {
    @EnvironmentObject var model: AppModel
    @State private var gate = ParentGate()
    @State private var pinGate = PinGate()
    @State private var forgot = false
    @State private var pinMessage: String?
    @State private var year = ""
    @State private var wrong = false
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()
            VStack(spacing: 26) {
                Text("Parent dashboard").font(Theme.title(34)).foregroundStyle(Theme.ink)
                if let pin = model.state.parentPin, !forgot {
                    pinPad(pin)
                } else {
                    holdAndYear
                }
                Button("Cancel") { model.leaveParentArea() }
                    .font(Theme.body(18))
                    .accessibilityIdentifier("gate.cancel")
            }
        }
    }

    // MARK: PIN

    private func pinPad(_ pin: ParentPin) -> some View {
        VStack(spacing: 18) {
            Text("Enter your PIN").font(Theme.body(20)).foregroundStyle(Theme.muted)
            HStack(spacing: 18) {
                ForEach(0..<ParentPin.length, id: \.self) { i in
                    Circle()
                        .fill(i < pinGate.entered.count ? Theme.deepLavender : Color.clear)
                        .overlay(Circle().stroke(Theme.deepLavender, lineWidth: 2))
                        .frame(width: 22, height: 22)
                }
            }
            .accessibilityElement()
            .accessibilityIdentifier("gate.pin.dots")
            .accessibilityValue("\(pinGate.entered.count)")
            if let pinMessage {
                Text(pinMessage).font(Theme.body()).foregroundStyle(Theme.muted)
                    .accessibilityIdentifier("gate.pin.message")
            }
            let rows: [[String]] = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["", "0", "⌫"]]
            VStack(spacing: 14) {
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: 14) {
                        ForEach(row, id: \.self) { key in padKey(key, pin: pin) }
                    }
                }
            }
            Button("Forgot PIN?") { forgot = true; pinGate = PinGate(); pinMessage = nil }
                .font(Theme.body(17))
                .accessibilityIdentifier("gate.pin.forgot")
        }
    }

    @ViewBuilder
    private func padKey(_ key: String, pin: ParentPin) -> some View {
        if key.isEmpty {
            Color.clear.frame(width: 84, height: 84)
        } else {
            Button {
                if key == "⌫" { pinGate.deleteLast(); return }
                switch pinGate.type(Character(key), pin: pin, now: Date()) {
                case .open: model.route = .parent
                case .wrong: pinMessage = "That's not it. Try again."
                case .locked: pinMessage = "Too many tries. Wait a minute, or use Forgot PIN."
                case .typing: pinMessage = nil
                }
            } label: {
                Group {
                    if key == "⌫" { Image(systemName: "delete.left").font(.system(size: 28)) }
                    else { Text(key).font(Theme.title(34)) }
                }
                .foregroundStyle(Theme.ink)
                .frame(width: 84, height: 84)
                .background(Circle().fill(Color.white))
                .overlay(Circle().stroke(Theme.tan, lineWidth: 2))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(key == "⌫" ? "gate.pin.delete" : "gate.pin.\(key)")
        }
    }

    // MARK: Hold and year (no PIN yet, or a forgotten PIN)

    @ViewBuilder
    private var holdAndYear: some View {
        if forgot {
            Text("Forgot your PIN? Do these two steps, then set a new PIN in Parent PIN.")
                .font(Theme.body(17)).foregroundStyle(Theme.muted)
                .accessibilityIdentifier("gate.forgotHelp")
        }
        switch gate.step {
        case .hold:
            Text("Hold two fingers on the circle for 3 seconds.")
                .font(Theme.body(20)).foregroundStyle(Theme.muted)
            ZStack {
                Circle().fill(Theme.lilac).frame(width: 220, height: 220)
                Image(systemName: "hand.raised.fingers.spread.fill").font(.system(size: 70)).foregroundStyle(Theme.lavender)
                TwoFingerHold { fingers, seconds in gate.holdEnded(fingers: fingers, seconds: seconds) }
                    .frame(width: 220, height: 220)
                    .accessibilityIdentifier("gate.hold")
            }
            if model.env.uiTesting {
                // XCUITest can't do a two-finger long press; the gate rule itself is unit tested.
                Button("QA: simulate two-finger hold") { gate.holdEnded(fingers: 2, seconds: 3) }
                    .accessibilityIdentifier("gate.qaHold")
            }
        case .typeYear:
            Text("Type the current year.").font(Theme.body(20)).foregroundStyle(Theme.muted)
            TextField("Year", text: $year)
                .keyboardType(.numberPad)
                .font(Theme.title(40))
                .multilineTextAlignment(.center)
                .frame(width: 220)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                .focused($focused)
                .onAppear { focused = true }
                .accessibilityIdentifier("gate.year")
            if wrong { Text("That's not it. Try again.").font(Theme.body()).foregroundStyle(Theme.muted) }
            Button("Continue") {
                wrong = !gate.submitYear(year, now: model.now, calendar: model.calendar)
                year = ""
                if gate.step == .open {
                    model.openPinPageNext = forgot
                    model.route = .parent
                }
            }
            .font(Theme.body(20).bold())
            .buttonStyle(.borderedProminent)
            .tint(Theme.deepLavender)
            .accessibilityIdentifier("gate.continue")
        case .open:
            ProgressView()
        }
    }
}

/// UIKit long-press recogniser that needs two fingers for 3 seconds.
struct TwoFingerHold: UIViewRepresentable {
    let ended: (Int, Double) -> Void

    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        v.backgroundColor = .clear
        let g = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.fire(_:)))
        g.numberOfTouchesRequired = ParentGate.requiredFingers
        g.minimumPressDuration = ParentGate.holdSeconds
        v.addGestureRecognizer(g)
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(ended: ended) }

    final class Coordinator: NSObject {
        let ended: (Int, Double) -> Void
        init(ended: @escaping (Int, Double) -> Void) { self.ended = ended }
        @objc func fire(_ g: UILongPressGestureRecognizer) {
            if g.state == .began { ended(g.numberOfTouches, ParentGate.holdSeconds) }
        }
    }
}

/// Parent area: progress, time limits, sound, Screen Time help, reset (Parent mock).
struct ParentAreaView: View {
    @EnvironmentObject var model: AppModel
    @State private var section: ParentTab = .overview
    @State private var newPin = ""
    @State private var newPinAgain = ""
    @State private var pinSaved: String?
    @State private var confirmReset = false
    @State private var skillToReset: Skill?

    enum ParentTab: String, CaseIterable, Identifiable {
        case overview = "Today"
        case time = "Time limits"
        case sound = "Sound and voice"
        case pin = "Parent PIN"
        case screenTime = "Screen Time help"
        case reset = "Reset progress"
        #if DEBUG
        case debug = "Jump to (testing)"
        #endif
        case progress = "Progress"
        case scrolls = "Puzzle scrolls"
        case jigsaw = "Jigsaw"
        case cups = "Cup shuffle"
        case memory = "Memory"
        var id: String { rawValue }
    }

    /// The dashboard's sidebar (Shrikant, 2026-11-03): General first, then one group per widget that has
    /// something to show or set. A widget with nothing to set gets no group.
    static let groups: [(title: String, tabs: [ParentTab])] = {
        var general: [ParentTab] = [.overview, .time, .sound, .pin, .screenTime, .reset]
        #if DEBUG
        general.append(.debug)
        #endif
        return [
            ("General", general),
            ("Kingdom of Numbers", [.progress, .scrolls]),
            ("Jigsaw", [.jigsaw]),
            ("Cup shuffle", [.cups]),
            ("Memory", [.memory]),
        ]
    }()

    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    Button { model.leaveParentArea() } label: {
                        Label("Back", systemImage: "chevron.left").font(Theme.body(17).bold())
                    }
                    .accessibilityIdentifier("parent.back")
                    .padding(.bottom, 8)
                    Text("Parent dashboard").font(Theme.title(24))
                        .accessibilityIdentifier("parent.title")
                        .padding(.bottom, 8)
                    ForEach(Self.groups, id: \.title) { group in
                        Text(group.title.uppercased()).font(Theme.body(13).bold()).foregroundStyle(Theme.muted)
                            .padding(.top, 12).padding(.leading, 4)
                            .accessibilityIdentifier("parent.group.\(group.title)")
                        ForEach(group.tabs) { s in
                            Button { section = s } label: {
                                Text(s.rawValue).font(Theme.body(18)).foregroundStyle(section == s ? .white : Theme.ink)
                                    .padding(.horizontal, 14).padding(.vertical, 9)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(section == s ? Theme.deepLavender : .clear))
                            }
                            .accessibilityIdentifier("parent.tab.\(s)")
                        }
                    }
                }
                .padding(24)
            }
            .frame(width: 270)
            .background(Theme.lilac)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    switch section {
                    case .overview: overview
                    case .progress: progress
                    case .scrolls: scrolls
                    case .jigsaw: jigsaw
                    case .cups: cups
                    case .memory: memoryPage
                    case .time: time
                    case .sound: sound
                    case .screenTime: screenTime
                    case .reset: reset
                    case .pin: pinPage
                    #if DEBUG
                    case .debug: debugJump
                    #endif
                    }
                }
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Theme.paper)
        }
        .ignoresSafeArea(edges: .bottom)
        .foregroundStyle(Theme.ink)
        .onAppear {
            if model.openPinPageNext { section = .pin; model.openPinPageNext = false }
        }
    }

    // MARK: Progress (AC-P5)

    // MARK: General: today at a glance

    private var overview: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Parent dashboard").font(Theme.title(32))
            if model.state.parentPin == nil {
                card {
                    Text("Set a parent PIN").font(Theme.body(17).bold())
                    Text("A 4-digit PIN replaces the two-finger hold and the year.")
                        .font(Theme.body(15)).foregroundStyle(Theme.muted)
                    Button("Set a PIN") { section = .pin }
                        .buttonStyle(.borderedProminent).tint(Theme.deepLavender)
                        .accessibilityIdentifier("parent.pin.setup")
                }
            }
            card { week }
            Text("Settings are grouped on the left: General for the whole app, then one group for each game.")
                .font(Theme.body(15)).foregroundStyle(Theme.muted)
        }
    }

    // MARK: Kingdom of Numbers

    private var progress: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Siara's progress").font(Theme.title(32))
            HStack(alignment: .top, spacing: 22) {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(model.content.chapters) { ch in
                        card {
                            Text(ch.title).font(Theme.body(19).bold())
                            ForEach(model.content.skills(in: ch.id)) { s in
                                let rec = model.state.skills[s.id]
                                let st = model.engine.status(rec)
                                HStack {
                                    Text(s.name).font(Theme.body())
                                    Spacer()
                                    Text(st == .practicing ? "\(st.parentLabel) · \(model.state.level(for: s.id).parentLabel)" : st.parentLabel)
                                        .font(Theme.body(15).bold())
                                        .foregroundStyle(st == .mastered ? Theme.garden : Theme.muted)
                                }
                                .accessibilityIdentifier("parent.skill.\(s.id)")
                            }
                        }
                    }
                    card {
                        Text("Open the next chapter").font(Theme.body(17).bold())
                        Picker("Open the next chapter", selection: Binding(
                            get: { model.state.chapterGate },
                            set: { model.state.chapterGate = $0; model.save() })) {
                            ForEach(ChapterGate.allCases, id: \.self) { g in Text(g.parentLabel).tag(g) }
                        }
                        .pickerStyle(.menu)
                        .accessibilityIdentifier("parent.gate")
                    }
                    HStack {
                        Button("Unlock next chapter") { model.unlockNextChapter() }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("parent.unlock")
                        Menu("Reset a skill") {
                            ForEach(model.content.skills) { s in Button(s.name) { skillToReset = s } }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                VStack(alignment: .leading, spacing: 18) {
                    card { stuck }
                }
            }
        }
        .confirmationDialog("Reset this skill?", isPresented: Binding(get: { skillToReset != nil }, set: { if !$0 { skillToReset = nil } }),
                            presenting: skillToReset) { s in
            Button("Reset \(s.name)", role: .destructive) { model.resetSkill(s.id) }
        }
    }

    // MARK: Puzzle scrolls and board (F2-F4, AC-S5)

    #if DEBUG
    // MARK: Jump to (Debug builds from Xcode only; never in a normal build)

    private var debugJump: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Jump to (testing)").font(Theme.title(32))
            Text("Opens any screen straight away. Her progress is put aside first and comes back exactly as it was when you tap End testing (or the next time the app opens).")
                .font(Theme.body(16)).foregroundStyle(Theme.muted)
            if model.isDebugSession {
                Button("End testing and restore her progress") { model.endDebugSession() }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("debug.end")
            }
            card {
                Text("Screens").font(Theme.body(17).bold())
                HStack {
                    ForEach(AppModel.DebugTarget.allCases) { t in
                        Button(t.rawValue.capitalized) { model.debugJump(t) }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("debug.to.\(t.rawValue)")
                    }
                }
            }
            ForEach(model.content.chapters) { ch in
                card {
                    Text(ch.title).font(Theme.body(17).bold())
                    HStack {
                        ForEach(ch.scenes, id: \.self) { sid in
                            Button(sid) { model.debugJump(scene: sid) }
                                .buttonStyle(.bordered)
                                .accessibilityIdentifier("debug.scene.\(sid)")
                        }
                        Spacer()
                        Button("Write it down") { model.debugJumpWriteItDown(ch.id) }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("debug.write.\(ch.id)")
                    }
                }
            }
        }
    }
    #endif

    // MARK: Jigsaw (#25, J8 and J11)

    private var jigsaw: some View {
        let j = model.state.jigsaw
        let rate = j.recentFirstFitRate
        let recent = Array(j.results.suffix(10))
        let hints = recent.reduce(0) { $0 + $1.hintsUsed }
        let strategies = j.strategyCounts.sorted { $0.value > $1.value }
        return VStack(alignment: .leading, spacing: 18) {
            Text("Jigsaw").font(Theme.title(32))
            Text("Picture puzzles train shapes and parts of a whole. She picks 10, 20 or 30 pieces; 20 and 30 open after her first 10-piece puzzle, and a sun ring marks the size that fits how she plays. Medium pictures (30 pieces, busier scenes) open after an Easy picture at 30; Hard pictures (50 pieces) open after a Medium one. Finished pictures get a green tick on her puzzle map.")
                .font(Theme.body(16)).foregroundStyle(Theme.muted)
            card {
                Text("Puzzle size").font(Theme.body(17).bold())
                Text("Her level now: \(j.levelSize) pieces\(j.calibrated ? "" : " (still finding her level)")")
                    .font(Theme.body(15)).foregroundStyle(Theme.muted)
                    .accessibilityIdentifier("parent.jig.level")
            }
            card {
                Text("Last ten puzzles").font(Theme.body(17).bold())
                if let rate {
                    Text("Pieces right on the first try: \(Int((rate * 100).rounded()))%").font(Theme.body())
                        .accessibilityIdentifier("parent.jig.firstFit")
                    Text("Hints asked for: \(hints)").font(Theme.body())
                } else {
                    Text("No puzzles finished yet.").font(Theme.body()).foregroundStyle(Theme.muted)
                }
                Text("Puzzles finished: \(j.puzzlesDone)").font(Theme.body())
            }
            if !strategies.isEmpty {
                card {
                    Text("How she says she finds pieces").font(Theme.body(17).bold())
                    ForEach(strategies, id: \.key) { kv in
                        Text("\(strategyName(kv.key)): \(kv.value)").font(Theme.body())
                    }
                }
            }
            card {
                Text("Try at home").font(Theme.body(17).bold())
                Text(j.homeIdea).font(Theme.body())
                    .accessibilityIdentifier("parent.jig.homeIdea")
            }
        }
    }

    // MARK: Memory (docs/features/memory.md, M9)

    private var memoryPage: some View {
        let m = model.state.memory
        return VStack(alignment: .leading, spacing: 18) {
            Text("Memory").font(Theme.title(32))
            Text("Trains memory: keeping where each character is in mind. Easy has 3 to 4 pairs, Medium 4 to 6, Hard 6 to 8. Medium opens after an Easy game and Hard after a Medium one; each game grows by a pair when the last one went well.")
                .font(Theme.body(16)).foregroundStyle(Theme.muted)
            card {
                Text("Last ten games").font(Theme.body(17).bold())
                if m.recent.isEmpty {
                    Text("No games played yet.").font(Theme.body()).foregroundStyle(Theme.muted)
                } else {
                    ForEach(Array(m.recent.reversed().enumerated()), id: \.offset) { _, r in
                        Text("\(r.level.title): \(r.pairs) pairs in \(r.tries) tries").font(Theme.body())
                    }
                }
                Text("Games played: \(m.gamesPlayed)").font(Theme.body())
            }
            .accessibilityIdentifier("parent.memory.recent")
            card {
                Text("Next game size").font(Theme.body(17).bold())
                ForEach(MemoryLevel.allCases, id: \.self) { l in
                    Text("\(l.title): \(m.pairs(for: l)) pairs\(m.isOpen(l) ? "" : " (not open yet)")").font(Theme.body())
                }
            }
            card {
                Text("Try at home").font(Theme.body(17).bold())
                Text(m.homeIdea).font(Theme.body())
                    .accessibilityIdentifier("parent.memory.homeIdea")
            }
        }
    }

    // MARK: Cup shuffle (#27, C10)

    private var cups: some View {
        let c = model.state.cupShuffle
        let recent = Array(c.rounds.suffix(10))
        return VStack(alignment: .leading, spacing: 18) {
            Text("Cup shuffle").font(Theme.title(32))
            Text("Trains attention: keeping her eyes on one moving cup until it stops. She chooses 3 or 5 cups and speed 1 to 3; after three finds in a row the next setting gets a gentle sun ring.")
                .font(Theme.body(16)).foregroundStyle(Theme.muted)
            card {
                Text("Last ten rounds").font(Theme.body(17).bold())
                if recent.isEmpty {
                    Text("No rounds played yet.").font(Theme.body()).foregroundStyle(Theme.muted)
                } else {
                    Text("Found the bird: \(recent.filter(\.found).count) of \(recent.count)").font(Theme.body())
                        .accessibilityIdentifier("parent.cups.recent")
                    HStack(spacing: 6) {
                        ForEach(Array(recent.enumerated()), id: \.offset) { _, r in
                            Text("\(r.cups)·\(r.speed)").font(Theme.body(13).bold())
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 30)
                                .background(RoundedRectangle(cornerRadius: 8).fill(r.found ? Theme.sageDeep : Theme.muted))
                        }
                    }
                    Text("Each box is cups · speed. Green means she found the bird.").font(Theme.body(14))
                        .foregroundStyle(Theme.muted)
                }
                Text("Rounds played: \(c.roundsPlayed)").font(Theme.body())
            }
            if !c.bySetting.isEmpty {
                card {
                    Text("By setting").font(Theme.body(17).bold())
                    ForEach(Array(c.bySetting.enumerated()), id: \.offset) { _, row in
                        Text("\(row.settings.cups) cups, speed \(row.settings.speed): found \(row.found) of \(row.played)")
                            .font(Theme.body())
                    }
                }
            }
            card {
                Text("First-time tutorial").font(Theme.body(17).bold())
                Text(c.tutorialDone ? "She has done it. Show it again next time she opens the cups?"
                                    : "It will show the next time she opens the cups.")
                    .font(Theme.body()).foregroundStyle(Theme.muted)
                if c.tutorialDone {
                    Button {
                        model.state.cupShuffle.tutorialDone = false
                        model.save()
                    } label: {
                        Text("Show the tutorial again").font(Theme.body(17).bold())
                    }
                    .accessibilityIdentifier("parent.cups.tutorialAgain")
                }
            }
            card {
                Text("Try at home").font(Theme.body(17).bold())
                Text(c.homeIdea).font(Theme.body())
                    .accessibilityIdentifier("parent.cups.homeIdea")
            }
        }
    }

    private func strategyName(_ key: String) -> String {
        switch key {
        case "colour": return "Matching colours"
        case "edge": return "Flat edges first"
        case "picture": return "Looking at the picture"
        case "turn": return "Turning pieces"
        case "order": return "Counting in order"
        default: return key
        }
    }

    private var scrolls: some View {
        let sheets = model.sheetMaker.available(state: model.state)
        let finished = sheets.filter { model.state.sheets[$0.id]?.finished != nil }
        let board = model.state.board
        return VStack(alignment: .leading, spacing: 18) {
            Text("Puzzle scrolls").font(Theme.title(32))
            Text("After she finishes a scroll, tell the app how it felt. Hard brings that place's skills back into warm-ups; easy lets them rest. She never sees a score.")
                .font(Theme.body(17)).foregroundStyle(Theme.muted)
            if finished.isEmpty {
                card { Text("No scrolls finished yet.").font(Theme.body()) }
            }
            ForEach(finished, id: \.id) { sheet in
                let rec = model.state.sheets[sheet.id] ?? SheetRecord()
                card {
                    HStack {
                        Text(sheet.place.flatMap { p in model.content.chapters.first { $0.id == p }?.title } ?? "Mixed scroll")
                            .font(Theme.body(19).bold())
                        Spacer()
                        Text("\(rec.firstTry) of \(rec.checked) right first time").font(Theme.body(15)).foregroundStyle(Theme.muted)
                    }
                    HStack(spacing: 12) {
                        ForEach(SheetFeedback.allCases, id: \.self) { f in
                            Button { model.sheetFeedback(f, sheetID: sheet.id, place: sheet.place) } label: {
                                Text(f.parentLabel).font(Theme.body(17).bold())
                                    .foregroundStyle(rec.feedback == f ? Color.white : Theme.ink)
                                    .padding(.horizontal, 18).padding(.vertical, 8)
                                    .background(Capsule().fill(rec.feedback == f ? Theme.deepLavender : Theme.lilac))
                            }
                            .buttonStyle(.plain)
                                .accessibilityIdentifier("parent.sheet.\(sheet.id).\(f.rawValue)")
                                .accessibilityValue(rec.feedback == f ? "selected" : "")
                        }
                    }
                }
            }
            card {
                Text("Puzzle Board").font(Theme.body(19).bold())
                Text("\(board.lanterns) lanterns lit, \(board.puzzlesMade) puzzles made for \(model.state.companion.name)")
                    .font(Theme.body())
                ForEach(model.problems.unlocked(model.state), id: \.self) { op in
                    HStack {
                        Text("\(op.sign)  \(op.spoken)").font(Theme.body())
                        Spacer()
                        Text("story level \(board.level(op)) of 3 · \(board.solved[op.rawValue, default: 0]) first try, \(board.missed[op.rawValue, default: 0]) with help")
                            .font(Theme.body(15)).foregroundStyle(Theme.muted)
                    }
                    .accessibilityIdentifier("parent.board.\(op.rawValue)")
                }
            }
        }
    }

    private var week: some View {
        let days = model.state.time.lastSevenDays(endingOn: model.now, calendar: model.calendar)
        let limit = model.state.timeSettings.dailyLimitMinutes
        let today = model.state.time.minutesPlayed(on: model.now, calendar: model.calendar)
        let f: DateFormatter = { let f = DateFormatter(); f.dateFormat = "EEE"; return f }()
        return VStack(alignment: .leading, spacing: 12) {
            Text("Time").font(Theme.body(19).bold())
            Text("Today: \(today) of \(limit) min").font(Theme.body()).accessibilityIdentifier("parent.today")
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, d in
                    VStack(spacing: 4) {
                        Text("\(d.minutes)").font(Theme.body(12))
                        RoundedRectangle(cornerRadius: 5).fill(Theme.lavender)
                            .frame(width: 26, height: max(4, CGFloat(d.minutes) / 30 * 110))
                        Text(f.string(from: d.day)).font(Theme.body(12))
                        Text(d.scenes > 0 ? "\(d.scenes) scene\(d.scenes == 1 ? "" : "s")" : " ").font(Theme.body(10)).foregroundStyle(Theme.muted)
                    }
                }
            }
        }
    }

    private var stuck: some View {
        let items = model.state.needsPractice.compactMap { model.content.item($0) }.sorted { $0.id < $1.id }
        return VStack(alignment: .leading, spacing: 10) {
            Text("Stuck on").font(Theme.body(19).bold())
            if items.isEmpty {
                Text("Nothing right now.").font(Theme.body()).foregroundStyle(Theme.muted)
            }
            ForEach(items) { i in
                VStack(alignment: .leading, spacing: 4) {
                    Text(describe(i)).font(Theme.body(16).bold())
                    Text("Try at home: \(model.content.skill(i.skill)?.homeTip ?? "")").font(Theme.body(15)).foregroundStyle(Theme.muted)
                }
                .accessibilityIdentifier("parent.stuck.\(i.id)")
            }
        }
        .frame(maxWidth: 380, alignment: .leading)
    }

    private func describe(_ i: Item) -> String {
        switch i.kind {
        case .addMore: return "How many flowers: \(i.a) and \(i.b) more"
        case .numberBond: return "Sharing \(i.a) between two beds"
        case .hop: return "Hopping \(i.b) from \(i.a)"
        case .makeTen: return "\(i.a) and how many make 10"
        case .equation: return "\(i.a) plus \(i.b)"
        case .findOnLine: return "Finding \(i.a) on the line"
        case .quickLook: return "Quick look at \(i.a) stars"
        case .countTap, .howMany: return "Counting \(i.a) stars"
        case .tensOnes: return "Ten and \(i.b) more"
        case .bridgeAdd: return "\(i.a) plus \(i.b), making ten first"
        case .takeAway: return "\(i.a) gems, \(i.b) taken away"
        case .hopBack: return "Hopping back \(i.b) from \(i.a)"
        case .compare: return "How many more: \(i.a) and \(i.b)"
        case .subtraction: return "\(i.a) minus \(i.b)"
        case .groups: return "\(i.a) tables of \(i.b) guests"
        case .array: return "\(i.a) rows of \(i.b) chairs"
        case .skipHop: return "\(i.a) hops of \(i.b)"
        case .multiply: return "\(i.a) times \(i.b)"
        case .share: return "Sharing \(i.a) treats onto \(i.b) plates"
        case .groupInto: return "\(i.a) berries in baskets of \(i.b)"
        case .divide: return "\(i.a) divided by \(i.b)"
        case .parts: return "Counting \(i.b) equal parts"
        case .fractionLine: return "Finding \(i.a)/\(i.b) on the moonbeam"
        case .fractionOf: return "One part in \(i.b) of \(i.a) gems"
        }
    }

    // MARK: Time limits (AC-P2, AC-P4)

    private var time: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Time limits").font(Theme.title(32))
            card {
                Text("Daily limit").font(Theme.body(19).bold())
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill").foregroundStyle(Theme.muted)
                    Text("\(model.state.timeSettings.dailyLimitMinutes) min").font(Theme.title(30))
                        .accessibilityIdentifier("parent.limit.value")
                }
                Text("Set once at setup, with \(model.state.heroName)'s name and companion. To change it, use Reset everything, which starts setup again.")
                    .font(Theme.body(15)).foregroundStyle(Theme.muted)
                Text("When time is up, \(model.state.heroName) finishes the puzzle on screen, hears \"we'll finish tomorrow\", and picks up there the next day.")
                    .font(Theme.body(15)).foregroundStyle(Theme.muted)
            }
            card {
                Toggle("Quiet hours", isOn: Binding(
                    get: { model.state.timeSettings.quietHoursOn },
                    set: { on in
                        model.state.timeSettings.quietStart = on ? 19 * 60 + 30 : nil
                        model.state.timeSettings.quietEnd = on ? 7 * 60 : nil
                        model.save()
                    }))
                .font(Theme.body(19).bold())
                .accessibilityIdentifier("parent.quiet")
                if model.state.timeSettings.quietHoursOn {
                    HStack {
                        DatePicker("From", selection: minutesBinding(\.quietStart), displayedComponents: .hourAndMinute)
                        DatePicker("To", selection: minutesBinding(\.quietEnd), displayedComponents: .hourAndMinute)
                    }
                }
            }
        }
    }

    private func minutesBinding(_ kp: WritableKeyPath<TimeSettings, Int?>) -> Binding<Date> {
        Binding(
            get: {
                let m = model.state.timeSettings[keyPath: kp] ?? 0
                return model.calendar.date(bySettingHour: m / 60, minute: m % 60, second: 0, of: model.now) ?? model.now
            },
            set: { d in
                let c = model.calendar.dateComponents([.hour, .minute], from: d)
                model.state.timeSettings[keyPath: kp] = (c.hour ?? 0) * 60 + (c.minute ?? 0)
                model.save()
            })
    }

    // MARK: Sound (AC-A8)

    private var sound: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Sound and voice").font(Theme.title(32))
            card {
                Text("Narration volume").font(Theme.body(17).bold())
                Slider(value: Binding(get: { model.state.sound.narrationVolume }, set: { model.state.sound.narrationVolume = $0; model.applySound(); model.save() }), in: 0.2...1)
                Text("Speech speed").font(Theme.body(17).bold())
                Slider(value: Binding(get: { model.state.sound.speechRate }, set: { model.state.sound.speechRate = $0; model.applySound(); model.save() }), in: 0.3...0.55)
                Toggle("Show words on screen (subtitles)", isOn: Binding(get: { model.state.sound.subtitles }, set: { model.state.sound.subtitles = $0; model.save() }))
                    .accessibilityIdentifier("parent.subtitles")
                Button("Play a sample") {
                    model.speech.say([model.catalog.spoken("p1.open1"), model.catalog.spoken("p1.open2")])
                }
                .buttonStyle(.bordered)
            }
            card {
                Text("Voices").font(Theme.body(17).bold())
                Text("Pick from the English voices downloaded on this iPad. Siri voices can't be used by apps. To add more, open Settings > Accessibility > Spoken Content > Voices > English and download an Enhanced or Premium voice; it shows up here straight away.")
                    .font(Theme.body(15)).foregroundStyle(Theme.muted)
                voiceRow("Narrator", id: "narrator", current: model.speech.narratorVoice,
                         choice: model.state.sound.narratorVoiceID, pitch: 1) { model.state.sound.narratorVoiceID = $0 }
                voiceRow(model.state.companion.name, id: "companion", current: model.speech.sparkleVoice,
                         choice: model.state.sound.companionVoiceID, pitch: model.state.companion.voicePitch) {
                    model.state.sound.companionVoiceID = $0
                }
            }
            card {
                if model.speech.hasEnhancedVoices {
                    Label("Enhanced voices are installed.", systemImage: "checkmark.circle.fill").foregroundStyle(Theme.garden)
                } else {
                    Text("Better voices are available").font(Theme.body(17).bold())
                    Text("\(model.state.companion.name) is using the basic voice. For a warmer voice, open Settings > Accessibility > Spoken Content > Voices > English, and download an Enhanced or Premium voice (for example Ava and Nicky). The app keeps working while you do this.")
                        .font(Theme.body(15)).foregroundStyle(Theme.muted)
                        .accessibilityIdentifier("parent.voiceHelp")
                }
            }
        }
    }

    /// One speaker's voice: a menu of downloaded English voices ("Automatic" lets the app choose) and Play.
    private func voiceRow(_ who: String, id: String, current: AVSpeechSynthesisVoice?, choice: String?, pitch: Float,
                          set: @escaping (String?) -> Void) -> some View {
        HStack(spacing: 14) {
            Text(who).font(Theme.body()).frame(width: 110, alignment: .leading)
            Menu {
                Button("Automatic (best downloaded)") { set(nil); model.applySound(); model.save() }
                ForEach(SpeechPlayer.englishVoices, id: \.identifier) { v in
                    Button(SpeechPlayer.describe(v)) { set(v.identifier); model.applySound(); model.save() }
                }
            } label: {
                Text(current.map(SpeechPlayer.describe) ?? "Basic system voice")
                    .font(Theme.body(16)).lineLimit(1)
                Text(choice == nil ? "(automatic)" : "").font(Theme.body(14)).foregroundStyle(Theme.muted)
            }
            .accessibilityIdentifier("parent.voice.\(id)")
            Spacer()
            Button("Play") {
                model.speech.sample("Hello! This is how I sound.", voice: current, pitch: pitch)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("parent.voice.\(id).play")
        }
    }

    // MARK: Grown-ups' PIN (Shrikant, 2026-11-03)

    private var pinPage: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Parent PIN").font(Theme.title(32))
            Text(model.state.parentPin == nil
                 ? "No PIN yet: the gate asks for a two-finger hold and the year. Set a 4-digit PIN to use a number pad instead."
                 : "The gate asks for this PIN. If you forget it, tap Forgot PIN? on the gate, do the two-finger hold and the year, then set a new one here.")
                .font(Theme.body(16)).foregroundStyle(Theme.muted)
                .accessibilityIdentifier("parent.pin.status")
            card {
                Text(model.state.parentPin == nil ? "New PIN" : "Change PIN").font(Theme.body(17).bold())
                PinFields(first: $newPin, again: $newPinAgain, idPrefix: "parent.pin")
                if let pinSaved {
                    Text(pinSaved).font(Theme.body(15)).foregroundStyle(Theme.garden)
                        .accessibilityIdentifier("parent.pin.saved")
                }
                Button("Save PIN") {
                    if model.setParentPin(newPin) {
                        pinSaved = "PIN saved."
                        newPin = ""; newPinAgain = ""
                    }
                }
                .buttonStyle(.borderedProminent).tint(Theme.deepLavender)
                .disabled(!PinFields.ready(newPin, newPinAgain))
                .accessibilityIdentifier("parent.pin.save")
            }
        }
    }

    private var screenTime: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Screen Time help").font(Theme.title(32))
            card {
                Text("Guided Access keeps the iPad in this app").font(Theme.body(17).bold())
                Text("Settings > Accessibility > Guided Access: turn it on and set a passcode. Open Kingdom of Numbers, then triple-click the top (or Home) button to start. Triple-click again and enter the passcode to leave.")
                    .font(Theme.body(15)).foregroundStyle(Theme.muted)
            }
            card {
                Text("Screen Time adds a device-wide limit").font(Theme.body(17).bold())
                Text("Settings > Screen Time > App Limits: add a limit for Kingdom of Numbers, a little above the daily limit set here.")
                    .font(Theme.body(15)).foregroundStyle(Theme.muted)
            }
        }
    }

    // MARK: Reset (AC-P7)

    private var reset: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Reset progress").font(Theme.title(32))
            Text("This clears every scene, skill and minute played, and starts the story again from the beginning. Time and sound settings are kept.")
                .font(Theme.body()).foregroundStyle(Theme.muted)
            Button("Reset all progress", role: .destructive) { confirmReset = true }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("parent.resetAll")
        }
        .alert("Reset all progress?", isPresented: $confirmReset) {
            Button("Reset", role: .destructive) { model.resetAll() }
                .accessibilityIdentifier("parent.resetConfirm")
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }

    private func card<C: View>(@ViewBuilder _ c: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10, content: c)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
    }
}

/// Two secure number fields for a new PIN: type it, then type it again (setup and the grown-ups' PIN page).
struct PinFields: View {
    @Binding var first: String
    @Binding var again: String
    let idPrefix: String

    static func ready(_ a: String, _ b: String) -> Bool { ParentPin.isValid(a) && a == b }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                field("4 digits", $first, id: "\(idPrefix).new")
                field("Again", $again, id: "\(idPrefix).again")
            }
            if again.count == ParentPin.length && first != again {
                Text("The two PINs don't match.").font(Theme.body(15)).foregroundStyle(Theme.clay)
            } else if !first.isEmpty && !ParentPin.isValid(first) && first.count >= ParentPin.length {
                Text("Use 4 digits.").font(Theme.body(15)).foregroundStyle(Theme.clay)
            }
        }
    }

    private func field(_ prompt: String, _ text: Binding<String>, id: String) -> some View {
        SecureField(prompt, text: Binding(get: { text.wrappedValue },
                                          set: { text.wrappedValue = String($0.filter(\.isNumber).prefix(ParentPin.length)) }))
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .font(Theme.title(28))
            .multilineTextAlignment(.center)
            .frame(width: 180)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.tan, lineWidth: 2))
            .accessibilityIdentifier(id)
    }
}
