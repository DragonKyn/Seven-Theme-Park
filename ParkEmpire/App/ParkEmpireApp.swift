import SwiftUI

@main
struct ParkEmpireApp: App {
    @StateObject private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
                .preferredColorScheme(.dark)
                // Started here so the first advert is already loaded by the
                // time anybody opens the boosts sheet.
                .task { RewardedAdCenter.shared.start() }
        }
    }
}
