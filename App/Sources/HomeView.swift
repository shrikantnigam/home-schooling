import KingdomCore
import SwiftUI

/// One widget in the Home School hub (#30). Adding a widget is one entry in `HubWidget.all`, plus its route.
struct HubWidget: Identifiable, Equatable {
    let id: String
    let name: String
    /// The skill it trains, said in one line for grown-ups (hub rule: every variation trains a named skill).
    let skill: String

    static let all: [HubWidget] = [
        HubWidget(id: "kingdom", name: "Kingdom of Numbers", skill: "Numbers through a story"),
        HubWidget(id: "jigsaw", name: "Jigsaw", skill: "Shapes, parts and wholes, and number order"),
    ]
}

/// The Home School home screen: a paper stage with one tile per widget.
struct HomeView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        let block = model.block
        ZStack {
            PaperStage(chapter: block != nil ? "prologue" : nil, showSky: false)
            VStack(spacing: 0) {
                Spacer()
                Rectangle().fill(block == nil ? Theme.garden : Color(hex: 0x2F5C45)).frame(height: 110)
            }
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Text("Home School")
                    .font(Theme.title(50))
                    .foregroundStyle(block == nil ? Theme.ink : .white)
                    .padding(.top, 104)
                    .accessibilityIdentifier("home.title")
                HStack(alignment: .bottom, spacing: 40) {
                    ForEach(HubWidget.all) { w in tile(w, resting: block != nil) }
                }
                if let block {
                    Text("\(model.state.companion.name) is \(block == .sleeping ? "sleeping" : "resting")")
                        .font(Theme.title(30)).foregroundStyle(.white)
                        .accessibilityIdentifier("home.sleeping")
                }
                Spacer()
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    SparkleView(mood: block == nil ? .happy : .sleeping, size: 170)
                        .padding(.trailing, 60).padding(.bottom, 40)
                }
            }

            ChildCorners(onCastle: nil, onEar: { model.speech.say(model.catalog.spoken("home.hello")) },
                         onLock: { model.openParentGate() }, dark: block != nil)
        }
        .onAppear { if block == nil { model.sayIntroOnce("home", [model.catalog.spoken("home.hello")]) } }
    }

    private func tile(_ w: HubWidget, resting: Bool) -> some View {
        Button { model.open(w) } label: {
            VStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28).fill(Theme.card).paperCut()
                    art(w).padding(18)
                }
                .frame(width: 280, height: 230)
                Text(w.name).font(Theme.title(28)).foregroundStyle(resting ? .white : Theme.ink)
            }
            // Kingdom still opens while resting, to its sleeping castle; other widgets wait for tomorrow.
            .opacity(resting && w.id != "kingdom" ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.widget.\(w.id)")
        .accessibilityLabel(w.name)
    }

    @ViewBuilder
    private func art(_ w: HubWidget) -> some View {
        switch w.id {
        case "kingdom":
            ZStack {
                CastleArt().scaleEffect(0.55).frame(width: 220, height: 180)
                HStack(spacing: 6) {
                    ForEach(1...3, id: \.self) { n in
                        Text("\(n)").font(Theme.numeral(30)).foregroundStyle(Theme.ink)
                            .frame(width: 46, height: 46).background(Circle().fill(Theme.sun))
                    }
                }
                .offset(y: 70)
            }
        default:
            JigsawTileArt()
        }
    }
}

/// Four interlocking paper pieces for the jigsaw tile.
struct JigsawTileArt: View {
    private let colors = [Theme.rose, Theme.sun, Theme.sage, Theme.river]

    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in piece(i) }
        }
        .frame(width: 200, height: 180)
    }

    private func piece(_ i: Int) -> some View {
        let r = i / 2
        let c = i % 2
        let edges = [r == 0 ? 0 : -1, c == 1 ? 0 : 1, r == 1 ? 0 : 1, c == 0 ? 0 : -1]
        let shape = JigsawPieceShape(edges: edges, cut: .tabs, margin: 20)
        return shape.fill(colors[i])
            .overlay(shape.stroke(Theme.ink.opacity(0.45), lineWidth: 2))
            .frame(width: 120, height: 120)
            .offset(x: c == 0 ? -40 : 40, y: r == 0 ? -40 : 40)
    }
}
