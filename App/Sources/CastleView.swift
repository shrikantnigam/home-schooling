import KingdomCore
import SwiftUI

/// 1. Castle home. One action only: the glowing button opens the story.
/// When the daily limit is used up it becomes "Sparkle is sleeping" (no play button).
struct CastleView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        let block = model.block
        ZStack {
            SkyBackground(night: block != nil, litFraction: litFraction)
            VStack(spacing: 0) {
                Spacer()
                HStack(alignment: .bottom, spacing: 30) {
                    SiaraView(size: 200, waving: block == nil)
                    CastleArt(night: block != nil)
                    SparkleView(mood: block == nil ? .happy : .sleeping, size: 230)
                }
                Rectangle().fill(block == nil ? Theme.garden : Color(hex: 0x2F5C45)).frame(height: 120)
            }
            .ignoresSafeArea()

            VStack {
                Text("Kingdom of Numbers")
                    .font(Theme.title(46))
                    .foregroundStyle(block == nil ? Theme.ink : .white)
                    .padding(.top, 44)
                Spacer()
            }

            if block == nil {
                Button { model.castlePlay() } label: {
                    ZStack {
                        Circle().fill(Theme.gold).frame(width: 170, height: 170)
                        Image(systemName: "play.fill").font(.system(size: 70, weight: .heavy)).foregroundStyle(Theme.ink)
                            .offset(x: 6)
                    }
                }
                .glow()
                .accessibilityIdentifier("castle.play")
                .accessibilityLabel("Play")
                .offset(y: -40)
            } else {
                Text(block == .sleeping ? "Sparkle is sleeping" : "Sparkle is resting")
                    .font(Theme.title(40))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("castle.sleeping")
                    .offset(y: -60)
            }

            ChildCorners(
                onCastle: nil,
                onEar: { speakWelcome() },
                onLock: { model.openParentGate() },
                dark: block != nil
            )
        }
        .onAppear { speakWelcome() }
    }

    private var litFraction: Double {
        let total = model.content.scenes.count
        return total == 0 ? 0 : Double(model.state.completedScenes.count) / Double(total)
    }

    private func speakWelcome() {
        switch model.block {
        case .sleeping: model.speech.say(model.catalog.spoken("sleeping"))
        case .quietHours: model.speech.say(model.catalog.spoken("quiet"))
        case nil:
            if model.state.hasMetSparkle {
                model.speech.say(model.catalog.spoken("castle.back"))
            } else {
                model.speech.say(model.catalog.spoken("castle.first"))
                model.state.hasMetSparkle = true
                model.save()
            }
        }
    }
}

/// 2. Kingdom map. Lit places are done, the next scene glows, later lands sit under mist.
struct MapView: View {
    @EnvironmentObject var model: AppModel

    /// Later chapters not in the content yet still show as misty places.
    private let futurePlaces = ["Bridge of Tens", "Goblin's Cave", "Royal Ball", "Fair Feast", "Moon Crystal"]

    var body: some View {
        ZStack {
            SkyBackground(night: false)
            VStack(spacing: 28) {
                Text("The Kingdom").font(Theme.title(40)).foregroundStyle(Theme.ink).padding(.top, 40)
                HStack(spacing: 26) {
                    ForEach(model.content.chapters) { ch in place(ch) }
                    ForEach(futurePlaces.dropFirst(max(0, model.content.chapters.count - 2)), id: \.self) { name in
                        misty(name)
                    }
                }
                .padding(.horizontal, 30)
                Spacer()
            }
            ChildCorners(onCastle: { model.goCastle() }, onEar: { model.speech.say(model.catalog.spoken("map.pick")) },
                         onLock: { model.openParentGate() })
        }
        .onAppear {
            let gardenOpen = model.progression.isChapterUnlocked("garden", state: model.state)
            model.speech.say(model.catalog.spoken(gardenOpen && !model.state.completedScenes.contains("G1") ? "map.gardenAwake" : "map.pick"))
        }
    }

    @ViewBuilder
    private func place(_ ch: Chapter) -> some View {
        let st = model.progression.placeState(ch.id, state: model.state)
        VStack(spacing: 12) {
            Button {
                switch st {
                case .locked: model.speech.say(model.catalog.spoken("map.locked"))
                case .open(let next): model.start(sceneID: next)
                case .practice: model.startPractice(ch.id)
                case .done: model.speech.say(model.catalog.spoken("map.done"))
                }
            } label: {
                ZStack {
                    Circle().fill(ch.id == "prologue" ? Theme.night : Theme.garden).frame(width: 170, height: 170)
                    if ch.id == "prologue" {
                        StarSprite(lit: st != .locked, size: 90)
                    } else {
                        FlowerSprite(bloom: st != .locked, size: 90)
                    }
                    if st == .locked {
                        Circle().fill(Color.white.opacity(0.7)).frame(width: 170, height: 170)
                    }
                }
                .glow(isGlowing(st))
            }
            .accessibilityIdentifier("map.place.\(ch.id)")
            .accessibilityLabel(ch.place)
            sceneDots(ch)
            Text(ch.place).font(Theme.title(22)).foregroundStyle(Theme.ink)
        }
    }

    private func isGlowing(_ st: MapPlaceState) -> Bool {
        if case .open = st { return true }
        return st == .practice
    }

    /// One dot per scene: gold when done. Not a touch target; the place itself is.
    private func sceneDots(_ ch: Chapter) -> some View {
        HStack(spacing: 8) {
            ForEach(ch.scenes, id: \.self) { s in
                Circle().fill(model.state.completedScenes.contains(s) ? Theme.gold : Color.white)
                    .overlay(Circle().stroke(Theme.lavender, lineWidth: 2))
                    .frame(width: 18, height: 18)
                    .accessibilityIdentifier("map.scene.\(s)")
            }
        }
    }

    private func misty(_ name: String) -> some View {
        VStack(spacing: 12) {
            Button { model.speech.say(model.catalog.spoken("map.locked")) } label: {
                Circle().fill(Color.white.opacity(0.75)).frame(width: 110, height: 110)
                    .overlay(Image(systemName: "cloud.fill").font(.system(size: 44)).foregroundStyle(Theme.lilac))
            }
            Text(name).font(Theme.title(16)).foregroundStyle(Theme.muted)
        }
    }
}
