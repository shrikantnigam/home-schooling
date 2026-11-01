import KingdomCore
import SwiftUI

/// Plays one scene: story open, warm-up, core items, payoff, goodbye (AC-S2).
struct ScenePlayerView: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject var controller: SceneController

    private var isPrologue: Bool { controller.run.scene.chapter == "prologue" }

    var body: some View {
        ZStack {
            background
            switch controller.run.phase {
            case .open: StoryPanel(kind: .open, controller: controller)
            case .payoff: StoryPanel(kind: .payoff, controller: controller)
            case .goodbye: StoryPanel(kind: .goodbye, controller: controller)
            case .warmup, .core:
                if let item = controller.item { ItemScreen(item: item, controller: controller).id(item.id + "\(controller.run.itemIndex ?? 0)") }
            case .finished: EmptyView()
            }
            ChildCorners(
                onCastle: { model.goCastle() },
                onEar: { controller.replay() },
                onLock: { model.openParentGate() },
                dark: isPrologue
            )
            if controller.showNext {
                VStack { Spacer(); HStack { Spacer(); NextButton { controller.next() } } }
                    .padding(28)
            }
        }
    }

    @ViewBuilder private var background: some View {
        if isPrologue {
            SkyBackground(night: true, litFraction: skyLit)
        } else {
            GardenBackground(bloom: gardenBloom)
        }
    }

    private var skyLit: Double {
        let done = Double(model.state.completedScenes.filter { $0.hasPrefix("P") }.count)
        let payoff = controller.run.phase == .payoff || controller.run.phase == .goodbye ? 1.0 : 0
        return min(1, (done + payoff) / 4)
    }

    private var gardenBloom: Double {
        let done = Double(model.state.completedScenes.filter { $0.hasPrefix("G") }.count)
        let payoff = controller.run.phase == .payoff || controller.run.phase == .goodbye ? 1.0 : 0
        return min(1, (done + payoff) / 5)
    }
}

/// Narrated story panels. The reward is the world changing (P4, G5 payoff).
struct StoryPanel: View {
    enum Kind { case open, payoff, goodbye }
    let kind: Kind
    @ObservedObject var controller: SceneController

    var body: some View {
        let scene = controller.run.scene
        VStack(spacing: 24) {
            Text(scene.title)
                .font(Theme.title(44))
                .foregroundStyle(scene.chapter == "prologue" ? .white : Theme.ink)
                .padding(.top, 60)
                .accessibilityIdentifier("panel.\(kindName).\(scene.id)")
            Spacer()
            HStack(alignment: .bottom, spacing: 40) {
                SiaraView(size: 190, waving: kind != .open)
                if kind == .payoff, scene.id == "G5" {
                    BridgeTeaser()
                } else if kind == .payoff, scene.chapter == "prologue" {
                    HStack { ForEach(0..<5, id: \.self) { _ in StarSprite(lit: true, size: 60) } }
                } else if kind == .payoff {
                    HStack { ForEach(0..<6, id: \.self) { i in FlowerSprite(color: i.isMultiple(of: 2) ? Theme.mane : Theme.gold, size: 60) } }
                }
                SparkleView(mood: kind == .goodbye ? .happy : .happy, size: 260)
            }
            .padding(.bottom, 120)
        }
    }

    private var kindName: String {
        switch kind {
        case .open: return "open"
        case .payoff: return "payoff"
        case .goodbye: return "goodbye"
        }
    }
}

/// Chapter 2 teaser at the end of G5.
struct BridgeTeaser: View {
    var body: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 0, y: 120))
                p.addQuadCurve(to: CGPoint(x: 260, y: 120), control: CGPoint(x: 130, y: 10))
            }
            .stroke(Theme.soil, lineWidth: 18)
            HStack(spacing: 14) {
                ForEach(0..<8, id: \.self) { _ in Rectangle().fill(Theme.soilDark).frame(width: 10, height: 40) }
            }
            .offset(y: 30)
        }
        .frame(width: 260, height: 140)
        .accessibilityIdentifier("bridgeTeaser")
    }
}

/// One item: Sparkle, the activity for its kind and CPA level, and the answer area.
struct ItemScreen: View {
    let item: Item
    @ObservedObject var controller: SceneController

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 90)
            HStack(alignment: .center, spacing: 20) {
                SparkleView(mood: isHint ? .thinking : .happy, size: 170)
                    .padding(.leading, 30)
                ActivityArea(item: item, controller: controller)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
            if !item.answersOnLine {
                AnswerTiles(item: item, controller: controller)
                    .padding(.bottom, 40)
            } else {
                Spacer(minLength: 40)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("item.\(item.id).\(levelName)")
        .accessibilityValue(qaDescription)
    }

    /// Lets the QA play-through act like a player who knows the answer.
    private var qaDescription: String {
        "kind=\(item.kind.rawValue);a=\(item.a);b=\(item.b);answer=\(item.answer);level=\(levelName)"
    }

    private var isHint: Bool { if case .hint = controller.mood { return true } else { return false } }
    private var levelName: String { String(describing: controller.level) }
}

/// Up to four numeral tiles, read aloud on first touch (AC-A3).
struct AnswerTiles: View {
    let item: Item
    @ObservedObject var controller: SceneController

    var body: some View {
        let revealed = controller.mood == .hint(.showAnswer) || controller.mood == .correct
        HStack(spacing: 26) {
            ForEach(ActivityRules.choices(for: item), id: \.self) { n in
                NumeralTile(
                    n: n,
                    dots: controller.showDots(for: n),
                    heard: controller.ui.heardTile == n,
                    glow: revealed && n == item.answer,
                    dimmed: revealed && n != item.answer,
                    wobble: controller.ui.wobbleTile == n ? controller.ui.wobble : 0
                ) { controller.touchTile(n) }
            }
        }
        .opacity(controller.readyToAnswer || revealed ? 1 : 0)
        .allowsHitTesting(controller.readyToAnswer)
        .frame(height: 130)
    }
}

/// Picks the activity view for the item's kind.
struct ActivityArea: View {
    let item: Item
    @ObservedObject var controller: SceneController

    var body: some View {
        switch item.kind {
        case .countTap, .howMany, .quickLook: StarsActivity(item: item, controller: controller)
        case .findOnLine: FindOnLineActivity(item: item, controller: controller)
        case .addMore: AddMoreActivity(item: item, controller: controller)
        case .numberBond: NumberBondActivity(item: item, controller: controller)
        case .hop: HopActivity(item: item, controller: controller)
        case .makeTen: MakeTenActivity(item: item, controller: controller)
        case .equation: EquationActivity(item: item, controller: controller)
        }
    }
}
