import KingdomCore
import SwiftUI

@main
struct KingdomOfNumbersApp: App {
    @StateObject private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some SwiftUI.Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .onChange(of: scenePhase) { _, phase in
                    model.setActive(phase == .active)
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        ZStack {
            switch model.route {
            case .home: HomeView()
            case .jigsaw: JigsawView()
            case .cups: CupShuffleView()
            case .castle: CastleView()
            case .map: MapView()
            case .scene:
                if let scene = model.scene { ScenePlayerView(controller: scene) } else { CastleView() }
            case .gate: ParentGateView()
            case .parent: ParentAreaView()
            case .setup: SetupView()
            case .writeItDown(let ch): WriteItDownView(chapter: ch)
            case .board: PuzzleBoardView()
            case .sheet(let id):
                if let sheet = model.sheet(id) { WorksheetView(sheet: sheet) } else { PuzzleBoardView() }
            }
            if model.route != .gate && model.route != .parent && model.route != .setup {
                // Top centre, clear of the answer tiles and the three corner buttons.
                VStack {
                    Subtitle(speech: model.speech, show: model.state.sound.subtitles)
                        .padding(.top, 24)
                        .padding(.horizontal, 120)
                    Spacer()
                }
                .allowsHitTesting(false)
            }
        }
        .preferredColorScheme(.light)
        .transaction { if model.env.uiTesting { $0.animation = nil } }
    }
}
