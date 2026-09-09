import Foundation

/// Single source of truth for product naming.
///
/// Every user-visible occurrence of the game's name reads from here, so the
/// working title can be replaced later without touching views. The Xcode
/// target / module name stays `ParkEmpire` so file paths remain stable.
enum AppInfo {
    static let gameName = "Park Empire"
    static let tagline = "Build the park. Watch it live."
}
