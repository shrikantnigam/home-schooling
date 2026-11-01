import KingdomCore
import SwiftUI

/// 1. Castle home. One action only: the glowing button opens the story.
/// When the daily limit is used up it becomes "Sparkle is sleeping" (no play button).
struct CastleView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        let block = model.block
        ZStack {
            PaperStage(chapter: block != nil ? "prologue" : nil, lit: litFraction)
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

            VStack(spacing: 14) {
                Text("Kingdom of Numbers")
                    .font(Theme.title(46))
                    .foregroundStyle(block == nil ? Theme.ink : .white)
                    .padding(.top, 90)
                PlacesProgress(dark: block != nil)
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

                // A second, quieter way in: straight to the kingdom map, even mid-scene.
                Button { model.goMap() } label: {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.9)).frame(width: 96, height: 96)
                            .overlay(Circle().stroke(Theme.lavender, lineWidth: 4))
                        Image(systemName: "map.fill").font(.system(size: 40, weight: .bold)).foregroundStyle(Theme.deepLavender)
                    }
                }
                .accessibilityIdentifier("castle.map")
                .accessibilityLabel("Kingdom map")
                .offset(x: 170, y: -40)
            } else {
                Text("\(model.state.companion.name) is \(block == .sleeping ? "sleeping" : "resting")")
                    .font(Theme.title(40))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("castle.sleeping")
                    .offset(y: -60)
            }

            ChildCorners(
                onCastle: nil,
                onEar: { speakWelcome(replay: true) },
                onLock: { model.openParentGate() },
                dark: block != nil
            )
        }
        .onAppear { speakWelcome(replay: false) }
    }

    private var litFraction: Double {
        let total = model.content.scenes.count
        return total == 0 ? 0 : Double(model.state.completedScenes.count) / Double(total)
    }

    /// The castle's spoken welcome: once after the app opens, or again when she taps the ear.
    private func speakWelcome(replay: Bool) {
        let key: String
        let line: SpokenLine?
        switch model.block {
        case .sleeping: key = "castle.sleeping"; line = model.catalog.spoken("sleeping")
        case .quietHours: key = "castle.quiet"; line = model.catalog.spoken("quiet")
        case nil:
            key = "castle"
            line = model.catalog.spoken(model.state.hasMetSparkle ? "castle.back" : "castle.first")
        }
        if replay {
            model.speech.say(line)
        } else {
            model.sayIntroOnce(key, [line])
        }
        if model.block == nil, !model.state.hasMetSparkle {
            model.state.hasMetSparkle = true
            model.save()
        }
    }
}

/// 2. Kingdom map. Lit places are done, the next scene glows, later lands sit under mist.
/// "3 of 7": the kingdom's places, lit once every scene in them is finished.
struct PlacesProgress: View {
    @EnvironmentObject var model: AppModel
    var dark = false

    var body: some View {
        let chapters = model.content.chapters
        let done = chapters.filter { model.progression.allScenesDone($0.id, state: model.state) }.count
        HStack(spacing: 10) {
            ForEach(chapters) { ch in
                let finished = model.progression.allScenesDone(ch.id, state: model.state)
                ZStack {
                    Circle().fill(finished ? ChapterLook.color(ch.id) : Color.white.opacity(0.5)).frame(width: 40, height: 40)
                    ChapterLook.icon(ch.id, lit: finished, size: 22).opacity(finished ? 1 : 0.35)
                }
            }
            Text("\(done) of \(chapters.count)")
                .font(Theme.title(24))
                .foregroundStyle(dark ? .white : Theme.ink)
                .padding(.leading, 6)
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(Capsule().fill(Color.white.opacity(dark ? 0.15 : 0.6)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(done) of \(chapters.count) places done")
        .accessibilityIdentifier("castle.progress")
    }
}

struct MapView: View {
    @EnvironmentObject var model: AppModel

    /// Later chapters not in the content yet still show as misty places.
    private let futurePlaces = ["Bridge of Tens", "Goblin's Cave", "Royal Ball", "Fair Feast", "Moon Crystal"]
    private var placeSize: CGFloat { model.content.chapters.count > 3 ? 120 : 170 }

    var body: some View {
        ZStack {
            PaperStage(chapter: nil)
            VStack(spacing: 28) {
                Text("The Kingdom").font(Theme.title(40)).foregroundStyle(Theme.ink).padding(.top, 90)
                HStack(alignment: .top, spacing: 18) {
                    ForEach(model.content.chapters) { ch in place(ch) }
                    ForEach(futurePlaces.dropFirst(max(0, model.content.chapters.count - 2)), id: \.self) { name in
                        misty(name)
                    }
                }
                .padding(.horizontal, 30)
                Spacer()
            }
            ChildCorners(onCastle: { model.goCastle() }, onEar: { model.speech.say(mapIntro) },
                         onLock: { model.openParentGate() })
        }
        // Once per app open, and again whenever a new place has woken up since.
        .onAppear { model.sayIntroOnce("map." + newlyOpened.joined(separator: ","), [mapIntro]) }
    }

    private var newlyOpened: [ChapterID] { model.progression.newlyOpened(state: model.state) }

    /// Every newly opened place gets its own "awake" line (item 16); several at once share one line.
    private var mapIntro: SpokenLine? {
        let fresh = newlyOpened
        let c = model.catalog
        if fresh.count == 1, let line = c.spoken("map.awake.\(fresh[0])") { return line }
        if fresh.count > 1 { return c.spoken("map.awakeMany") }
        if let ch = model.content.chapters.first(where: { model.progression.placeState($0.id, state: model.state) == .practice }) {
            return c.spoken("map.practice.\(ch.id)") ?? c.spoken("map.practice")
        }
        return c.spoken("map.pick")
    }

    private func tap(_ ch: Chapter, _ st: MapPlaceState) {
        let c = model.catalog
        switch st {
        case .locked: model.speech.say(c.spoken("map.locked"))
        case .open(let next): model.start(sceneID: next)
        case .waiting(_, let on):
            model.speech.say(on.first.flatMap { c.spoken("map.waiting.\($0)") } ?? c.spoken("map.waiting"))
        case .practice: model.startPractice(ch.id)
        case .done:
            // Item 15: a finished place can be played again, as a fresh mix of its puzzles.
            model.speech.say(c.spoken("map.done")) { model.replay(ch.id) }
        }
    }

    @ViewBuilder
    private func place(_ ch: Chapter) -> some View {
        let st = model.progression.placeState(ch.id, state: model.state)
        VStack(spacing: 12) {
            Button { tap(ch, st) } label: {
                ZStack {
                    Circle().fill(ChapterLook.color(ch.id)).frame(width: placeSize, height: placeSize)
                    ChapterLook.icon(ch.id, lit: st != .locked, size: placeSize * 0.55)
                    if st == .locked {
                        Circle().fill(Color.white.opacity(0.7)).frame(width: placeSize, height: placeSize)
                    }
                }
                .glow(isGlowing(st))
            }
            .accessibilityIdentifier("map.place.\(ch.id)")
            .accessibilityLabel(ch.place)
            .accessibilityValue(stateName(st))
            sceneDots(ch)
            Text(ch.place).font(Theme.title(18)).foregroundStyle(Theme.ink).lineLimit(2).multilineTextAlignment(.center)
                .frame(width: placeSize + 20)
        }
    }

    private func stateName(_ st: MapPlaceState) -> String {
        switch st {
        case .locked: return "locked"
        case .open: return "open"
        case .waiting: return "waiting"
        case .practice: return "practice"
        case .done: return "done"
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

/// Colour and icon for each chapter's place on the map and its scene background.
enum ChapterLook {
    static func color(_ id: ChapterID) -> Color {
        switch id {
        case "prologue": return Theme.night
        case "garden": return Theme.garden
        case "bridge": return Theme.water
        case "goblin": return Color(hex: 0x5E5A7A)
        case "ball": return Theme.mane
        case "feast": return Color(hex: 0xF2A65A)
        case "moon": return Color(hex: 0x2B3A67)
        default: return Theme.lavender
        }
    }

    @ViewBuilder
    static func icon(_ id: ChapterID, lit: Bool, size: CGFloat) -> some View {
        switch id {
        case "prologue": StarSprite(lit: lit, size: size)
        case "garden": FlowerSprite(bloom: lit, size: size)
        case "bridge": CounterSprite(style: .plank, size: size)
        case "goblin": CounterSprite(style: .gem, size: size)
        case "ball": CounterSprite(style: .guest, size: size)
        case "feast": CounterSprite(style: .treat, size: size)
        case "moon": CounterSprite(style: .crystal, size: size)
        default: StarSprite(lit: lit, size: size)
        }
    }

    /// Night chapters use white titles and a night sky.
    static func isNight(_ id: ChapterID) -> Bool { id == "prologue" || id == "moon" || id == "goblin" }

    /// Top and bottom colours for a chapter's scene background (day chapters other than the Garden).
    static func sky(_ id: ChapterID) -> [Color] {
        switch id {
        case "bridge": return [Theme.daySky, Theme.water]
        case "goblin": return [Color(hex: 0x3A3550), Color(hex: 0x5E5A7A)]
        case "ball": return [Color(hex: 0xFCE4EF), Theme.lilac]
        case "feast": return [Color(hex: 0xFFF1D6), Color(hex: 0xF7D3A1)]
        case "moon": return [Theme.night, Color(hex: 0x2B3A67)]
        default: return [Theme.daySky, Color(hex: 0xEAF7FC)]
        }
    }
}
