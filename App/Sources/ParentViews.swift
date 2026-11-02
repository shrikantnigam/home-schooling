import KingdomCore
import SwiftUI
import UIKit

/// Two steps a pre-reader can't do: hold two fingers for 3 seconds, then type this year.
/// Nothing here is spoken (Gate mock).
struct ParentGateView: View {
    @EnvironmentObject var model: AppModel
    @State private var gate = ParentGate()
    @State private var year = ""
    @State private var wrong = false
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()
            VStack(spacing: 26) {
                Text("For grown-ups").font(Theme.title(34)).foregroundStyle(Theme.ink)
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
                        if gate.step == .open { model.route = .parent }
                    }
                    .font(Theme.body(20).bold())
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.deepLavender)
                    .accessibilityIdentifier("gate.continue")
                case .open:
                    ProgressView()
                }
                Button("Cancel") { model.goCastle() }
                    .font(Theme.body(18))
                    .accessibilityIdentifier("gate.cancel")
            }
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
    @State private var section: ParentTab = .progress
    @State private var confirmReset = false
    @State private var skillToReset: Skill?

    enum ParentTab: String, CaseIterable, Identifiable {
        case progress = "Progress"
        case scrolls = "Puzzle scrolls"
        case time = "Time limits"
        case sound = "Sound and voice"
        case screenTime = "Screen Time help"
        case reset = "Reset progress"
        var id: String { rawValue }
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Button { model.goCastle() } label: {
                    Label("Back to the castle", systemImage: "chevron.left").font(Theme.body(17).bold())
                }
                .accessibilityIdentifier("parent.back")
                .padding(.bottom, 20)
                ForEach(ParentTab.allCases) { s in
                    Button { section = s } label: {
                        Text(s.rawValue).font(Theme.body(18)).foregroundStyle(section == s ? .white : Theme.ink)
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 10).fill(section == s ? Theme.deepLavender : .clear))
                    }
                    .accessibilityIdentifier("parent.tab.\(s)")
                }
                Spacer()
            }
            .padding(24)
            .frame(width: 260)
            .background(Theme.lilac)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    switch section {
                    case .progress: progress
                    case .scrolls: scrolls
                    case .time: time
                    case .sound: sound
                    case .screenTime: screenTime
                    case .reset: reset
                    }
                }
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Theme.paper)
        }
        .ignoresSafeArea(edges: .bottom)
        .foregroundStyle(Theme.ink)
    }

    // MARK: Progress (AC-P5)

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
                    card { week }
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
