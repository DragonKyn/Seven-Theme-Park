import Foundation
import UIKit

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

/// Identifiers for the advert network, in one place.
enum AdConfiguration {
    /// The app as the network knows it. Also has to appear in the Info.plist
    /// as `GADApplicationIdentifier`, or the SDK refuses to start.
    static let applicationID = "ca-app-pub-6085748649825153~1304019904"
    /// The rewarded placement both boosts are paid for with.
    static let rewardedUnitID = "ca-app-pub-6085748649825153/1635192393"
    /// Google's own always-fills test unit. Used automatically in debug
    /// builds, because serving live adverts to yourself while developing is
    /// how advert accounts get closed.
    static let testRewardedUnitID = "ca-app-pub-3940256099942544/1712485313"

    static var activeRewardedUnitID: String {
        #if DEBUG
        return testRewardedUnitID
        #else
        return rewardedUnitID
        #endif
    }
}

/// Shows a rewarded advert and says whether the reward was earned.
///
/// Everything the game does with adverts goes through this one door, so the
/// rest of the game never imports an advert SDK, and a build without the SDK
/// linked still compiles and simply reports that adverts are unavailable.
@MainActor
final class RewardedAdCenter: ObservableObject {

    static let shared = RewardedAdCenter()

    /// True once there is an advert loaded and ready to show.
    @Published private(set) var isReady = false
    /// True while one is being fetched, so the button can say so.
    @Published private(set) var isLoading = false
    /// Set when the last attempt failed, for the sheet to show.
    @Published private(set) var lastError: String?

    /// Whether this build can show adverts at all.
    var isSupported: Bool {
        #if canImport(GoogleMobileAds)
        return true
        #else
        return false
        #endif
    }

    /// Called once at launch.
    func start() {
        #if canImport(GoogleMobileAds)
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        Task { await load() }
        #endif
    }

    /// Fetches the next advert, so one is ready before the button is pressed.
    func load() async {
        #if canImport(GoogleMobileAds)
        guard !isLoading, !isReady else { return }
        isLoading = true
        lastError = nil
        do {
            loaded = try await GADRewardedAd.load(withAdUnitID: AdConfiguration.activeRewardedUnitID,
                                                  request: GADRequest())
            isReady = true
        } catch {
            loaded = nil
            isReady = false
            lastError = error.localizedDescription
        }
        isLoading = false
        #endif
    }

    /// Shows the advert and returns true only when the viewer earned the
    /// reward. Closing it early, or any failure, returns false.
    func show() async -> Bool {
        #if canImport(GoogleMobileAds)
        if !isReady { await load() }
        guard let ad = loaded, let root = Self.rootViewController else {
            if lastError == nil { lastError = "No advert is ready just now." }
            return false
        }

        loaded = nil
        isReady = false

        let presenter = AdPresenter()
        self.presenter = presenter
        let earned = await presenter.present(ad, from: root)
        self.presenter = nil

        // The next one starts loading straight away, so a player who wants a
        // second helping is not left waiting on a spinner.
        Task { await load() }
        return earned
        #else
        lastError = "Adverts are not part of this build."
        return false
        #endif
    }

    #if canImport(GoogleMobileAds)
    private var loaded: GADRewardedAd?
    /// Held for as long as the advert is on screen, because the SDK keeps
    /// only a weak reference to its delegate.
    private var presenter: AdPresenter?

    /// The view controller an advert is presented over.
    private static var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }
    #endif
}

#if canImport(GoogleMobileAds)
/// Bridges the SDK's delegate callbacks into one await.
///
/// The reward handler fires while the advert is still up, and the answer is
/// not final until it is dismissed, so the two have to be joined: remember
/// whether the reward landed, and resolve on dismissal.
private final class AdPresenter: NSObject, GADFullScreenContentDelegate {

    private var finish: ((Bool) -> Void)?
    private var earned = false

    func present(_ ad: GADRewardedAd, from root: UIViewController) async -> Bool {
        await withCheckedContinuation { continuation in
            finish = { continuation.resume(returning: $0) }
            ad.fullScreenContentDelegate = self
            ad.present(fromRootViewController: root) { [weak self] in
                self?.earned = true
            }
        }
    }

    func ad(_ ad: GADFullScreenPresentingAd,
            didFailToPresentFullScreenContentWithError error: Error) {
        complete(false)
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        complete(earned)
    }

    /// Guarded, because resuming a continuation twice is a crash.
    private func complete(_ value: Bool) {
        let handler = finish
        finish = nil
        handler?(value)
    }
}
#endif
