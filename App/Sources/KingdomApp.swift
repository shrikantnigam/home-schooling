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
            case .castle: CastleView()
            case .map: MapView()
            case .scene:
                if let scene = model.scene { ScenePlayerView(controller: scene) } else { CastleView() }
            case .gate: ParentGateView()
            case .parent: ParentAreaView()
            }
            if model.route != .gate && model.route != .parent {
                VStack {
                    Spacer()
                    Subtitle(speech: model.speech, show: model.state.sound.subtitles)
                        .padding(.bottom, 150)
                }
                .allowsHitTesting(false)
            }
        }
        .preferredColorScheme(.light)
        .transaction { if model.env.uiTesting { $0.animation = nil } }
    }
}
