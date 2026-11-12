import Foundation

/// Single source of truth for product naming.
///
/// Every user-visible occurrence of the game's name reads from here, so the
/// name can be changed without touching views. The Xcode target and module
/// name stay `ParkEmpire` so file paths remain stable.
enum AppInfo {
    static let gameName = "Wonder Lot"

    /// Shown one at a time under the title, in order. They are all about the
    /// same idea from different angles, so which one a player sees first does
    /// not matter.
    static let taglines = [
        "From empty lot to endless fun.",
        "Your land. Your rides. Your wonder.",
        "Build big. Dream bigger.",
        "Every great park starts with a lot.",
        "Turn a little lot into a lot of wonder."
    ]

    /// What the title screen says while the holiday event is on.
    static let holidayTaglines = [
        "Deck the lot.",
        "Snow on the ground, lights on the rides.",
        "Twelve days of holiday wonder.",
        "Santa is hiring.",
        "Turn a little lot into a lot of wonder, with tinsel."
    ]

    /// The lines to show now: the holiday ones during the event.
    static var activeTaglines: [String] {
        HolidaySeason.isActive() ? holidayTaglines : taglines
    }

    /// Used anywhere a single line is wanted and there is no room to rotate.
    static var tagline: String { taglines[0] }
}
