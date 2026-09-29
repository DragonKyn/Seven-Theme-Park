import SwiftUI

@main
struct ParkEmpireApp: App {
    @StateObject private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
                .preferredColorScheme(.dark)
                // Asks the tracking question and then, once it has been
                // answered, starts the advert SDK and preloads the first
                // advert, so one is ready by the time anybody opens the
                // boosts sheet.
                .task { RewardedAdCenter.shared.start() }
        }
    }
}
