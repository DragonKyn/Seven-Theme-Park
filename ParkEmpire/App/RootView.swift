import SwiftUI

struct RootView: View {
    @EnvironmentObject private var router: AppRouter
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch router.screen {
            case .menu:
                MainMenuView()
            case .game(let controller):
                GameView(controller: controller)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // Guard against the app being killed in the background.
            if phase != .active {
                router.saveActiveGame()
            }
        }
        .alert("Something went wrong",
               isPresented: Binding(get: { router.errorMessage != nil },
                                    set: { if !$0 { router.errorMessage = nil } })) {
            Button("OK", role: .cancel) { router.errorMessage = nil }
        } message: {
            Text(router.errorMessage ?? "")
        }
    }
}
