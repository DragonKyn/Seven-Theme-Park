import Foundation
import UIKit

/// How much of the park's detail the phone is asked to draw.
enum GraphicsMode: String, CaseIterable, Identifiable {
    /// Full detail on a phone that can take it, compatibility on one that
    /// cannot. What almost everybody should leave it on.
    case automatic
    /// Full detail, whatever the phone. Here because a player who does not
    /// mind a lower frame rate should be allowed to have the prettier park.
    case full
    /// The lighter park, whatever the phone. Here because somebody on a warm
    /// afternoon with a nearly flat battery may want it.
    case compatibility

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: return "Automatic"
        case .full: return "Full detail"
        case .compatibility: return "Compatibility"
        }
    }
}

/// What this particular phone is.
///
/// There is no list of model numbers here, and deliberately so: a list goes
/// stale the moment Apple ships something new. The question being asked is
/// "is this a phone Apple has stopped updating", and the answer is simply
/// whether it can run iOS 17. Every device that cannot is an A11 or older —
/// an iPhone X, 8, 7, 6s, or an iPad of the same vintage. The memory check is
/// there so somebody who has merely put off an update on a modern phone is
/// not quietly given the lighter park.
enum DeviceProfile {

    static let isLegacyHardware: Bool = {
        if #available(iOS 17.0, *) { return false }
        let gigabyte = 1024.0 * 1024.0 * 1024.0
        return Double(ProcessInfo.processInfo.physicalMemory) / gigabyte < 4
    }()

    /// Roughly what the phone is, for the settings screen to show.
    static var summary: String {
        let gigabyte = 1024.0 * 1024.0 * 1024.0
        let memory = Double(ProcessInfo.processInfo.physicalMemory) / gigabyte
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return String(format: "iOS %d.%d, %.0f GB of memory",
                      version.majorVersion, version.minorVersion, memory.rounded())
    }
}

/// The graphics setting, and what it resolves to on this phone.
///
/// App-wide rather than per-park: it describes the phone, not the park, so it
/// has no business inside a save file. Kept in `UserDefaults` alongside the
/// boosts and the perks, which is the pattern the rest of the app already
/// uses for things that outlive a single park.
@MainActor
final class DisplaySettings: ObservableObject {

    static let shared = DisplaySettings()

    @Published var mode: GraphicsMode {
        didSet {
            guard mode != oldValue else { return }
            GraphicsBudget.store(mode)
        }
    }

    /// True when the park is being drawn the lighter way.
    var isReduced: Bool { GraphicsBudget.isReduced }

    private init() {
        mode = GraphicsBudget.storedMode
    }

    /// What the automatic setting decided, for the settings screen to explain
    /// itself with.
    var automaticExplanation: String {
        DeviceProfile.isLegacyHardware
            ? "This phone is one of the older ones, so the park is drawn the lighter way."
            : "This phone can take the full park, so nothing is turned down."
    }
}

/// What the drawing code reads, and where the setting actually lives.
///
/// `ParkScene` and the artwork caches are not observers of anything, so the
/// setting is a plain value they can ask for once a frame or once a texture
/// rather than an object they have to hold. `DisplaySettings` is the
/// observable face of it, for the settings screen.
enum GraphicsBudget {

    private static let modeKey = "display.graphicsMode"

    static var storedMode: GraphicsMode {
        UserDefaults.standard.string(forKey: modeKey)
            .flatMap(GraphicsMode.init(rawValue:)) ?? .automatic
    }

    static func store(_ mode: GraphicsMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: modeKey)
    }

    /// Whether the park should be drawn the lighter way, right now.
    static var isReduced: Bool {
        switch storedMode {
        case .automatic: return DeviceProfile.isLegacyHardware
        case .full: return false
        case .compatibility: return true
        }
    }

    /// Frames a second the park is drawn at. Half rate on an old phone is far
    /// steadier than a full rate it cannot hold.
    static var framesPerSecond: Int { isReduced ? 30 : 60 }

    /// How many guests are drawn at once. The park still simulates all of
    /// them; this is only how many figures are put on the glass.
    static var guestSprites: Int { isReduced ? 130 : Balance.maxGuests }

    /// Thought bubbles on screen together.
    static var bubbles: Int { isReduced ? 3 : 10 }

    /// Whether guests outside the camera's view are skipped entirely.
    static var cullsOffscreenGuests: Bool { isReduced }

    /// Whether the main menu runs a live park behind it.
    static var animatesMenuBackdrop: Bool { !isReduced }

    /// Simulation steps allowed in one frame before the backlog is dropped.
    /// Lower on an old phone, so a slow frame costs a moment of park time
    /// rather than turning into a slower frame still.
    static var maxTicksPerFrame: Int { isReduced ? 12 : Balance.maxTicksPerFrame }

    /// Whether artwork is drawn at 1x rather than the screen's own scale,
    /// which is a quarter to a ninth of the texture memory.
    ///
    /// Read once and then fixed for the life of the process, unlike everything
    /// above it: the textures it produces are cached, and a park half drawn at
    /// one scale and half at another would look wrong. Changing the setting is
    /// honoured by artwork drawn afterwards and completely on the next launch,
    /// and the settings screen says so.
    private static let drawsAtLowScale = isReduced

    /// The format the artwork caches draw into. `preferred()` already carries
    /// this screen's scale, so the only thing ever changed is the way down.
    static func rendererFormat() -> UIGraphicsImageRendererFormat {
        let format = UIGraphicsImageRendererFormat.preferred()
        if drawsAtLowScale { format.scale = 1 }
        format.opaque = false
        return format
    }
}
