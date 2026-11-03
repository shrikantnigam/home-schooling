import KingdomCore
import SwiftUI

/// First-launch setup (charter v1.3), done by a grown-up with the child: her name, her companion and the
/// daily time limit, plus the grown-ups' PIN (changeable later in the parent area). Saved once and then locked; only "Reset everything" in the parent area starts it again.
struct SetupView: View {
    @EnvironmentObject var model: AppModel
    @State private var name = SetupChoices.defaultName
    @State private var companion: Companion = .unicorn
    @State private var minutes = TimeSettings.defaultLimit
    @State private var confirming = false
    @State private var pin = ""
    @State private var pinAgain = ""

    /// A PIN is asked for only when none is set (a reset keeps the PIN).
    private var needsPin: Bool { model.state.parentPin == nil }

    var body: some View {
        ZStack {
            PaperStage(chapter: nil, showSky: false)
            ScrollView {
                VStack(spacing: 22) {
                    Text("Welcome to the Kingdom of Numbers").font(Theme.title(40)).foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                        .padding(.top, 40)
                    Text("Set up together. These choices can't be changed later.")
                        .font(Theme.body(18)).foregroundStyle(Theme.muted)

                    step("1", "Her name") {
                        TextField("Name", text: $name)
                            .font(Theme.title(30))
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 18).padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.tan, lineWidth: 2))
                            .frame(maxWidth: 420)
                            .accessibilityIdentifier("setup.name")
                    }

                    step("2", "Choose a friend to play with") {
                        HStack(spacing: 16) {
                            ForEach(Companion.allCases, id: \.self) { c in companionCard(c) }
                        }
                    }

                    step("3", "Play time each day") {
                        HStack(spacing: 18) {
                            roundButton("minus", id: "setup.limit.minus") { minutes = max(5, minutes - 5) }
                            Text("\(minutes) min").font(Theme.title(34)).foregroundStyle(Theme.ink)
                                .frame(minWidth: 140)
                                .accessibilityIdentifier("setup.limit.value")
                            roundButton("plus", id: "setup.limit.plus") { minutes = min(55, minutes + 5) }
                        }
                        Text("Always under an hour. When time is up, the story pauses until tomorrow.")
                            .font(Theme.body(15)).foregroundStyle(Theme.muted)
                    }

                    if needsPin {
                        step("4", "A parent PIN") {
                            PinFields(first: $pin, again: $pinAgain, idPrefix: "setup.pin")
                            Text("Four digits she doesn't know. It opens the parent dashboard, and you can change it there later.")
                                .font(Theme.body(15)).foregroundStyle(Theme.muted)
                        }
                    }

                    Button { confirming = true } label: {
                        Text("Start the story").font(Theme.title(28)).foregroundStyle(Theme.ink)
                            .padding(.horizontal, 40).padding(.vertical, 18)
                            .background(Capsule().fill(Theme.sun))
                            .paperCut()
                    }
                    .disabled(needsPin && !PinFields.ready(pin, pinAgain))
                    .opacity(needsPin && !PinFields.ready(pin, pinAgain) ? 0.5 : 1)
                    .accessibilityIdentifier("setup.start")
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 40)
                .frame(maxWidth: .infinity)
            }
        }
        .alert("Start with these choices?", isPresented: $confirming) {
            Button("Change", role: .cancel) {}
            Button("Start") { model.completeSetup(name: name, companion: companion, minutes: minutes, pin: needsPin ? pin : nil) }
        } message: {
            Text("\(SetupChoices.cleanName(name)) plays with \(companion.name) the \(companion.kind), \(minutes) minutes a day. You can't change these later.")
        }
    }

    private func step<C: View>(_ n: String, _ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Text(n).font(Theme.title(20)).foregroundStyle(Theme.card)
                    .frame(width: 36, height: 36).background(Circle().fill(Theme.clay))
                Text(title).font(Theme.title(26)).foregroundStyle(Theme.ink)
            }
            content()
        }
        .padding(20)
        .frame(maxWidth: 980)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.card.opacity(0.92)))
        .paperCut(0.6)
    }

    private func companionCard(_ c: Companion) -> some View {
        let chosen = c == companion
        return Button { companion = c } label: {
            VStack(spacing: 6) {
                SparkleView(size: 130, companion: c)
                Text(c.name).font(Theme.title(20)).foregroundStyle(Theme.ink)
                Text(c.kind).font(Theme.body(14)).foregroundStyle(Theme.muted)
            }
            .padding(10)
            .frame(width: 160)
            .background(RoundedRectangle(cornerRadius: 16).fill(chosen ? Theme.sun.opacity(0.35) : Theme.cream))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(chosen ? Theme.clay : Theme.tan, lineWidth: chosen ? 5 : 2))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("setup.companion.\(c.rawValue)")
        .accessibilityLabel("\(c.name) the \(c.kind)")
        .accessibilityAddTraits(chosen ? .isSelected : [])
    }

    private func roundButton(_ icon: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 28, weight: .bold)).foregroundStyle(Theme.card)
                .frame(width: 64, height: 64).background(Circle().fill(Theme.clay)).paperCut(0.5)
        }
        .accessibilityIdentifier(id)
    }
}
