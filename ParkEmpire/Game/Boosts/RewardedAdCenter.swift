import Foundation
import UIKit

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
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

    /// What the advert side is doing, for the boosts screen to show. Plain
    /// enough for a player, specific enough to diagnose a quiet failure.
    var statusLine: String {
        if !isSupported { return "Adverts are not part of this build." }
        if isLoading { return "Fetching an advert." }
        if isReady { return "An advert is ready." }
        return "No advert ready yet."
    }

    /// Whether this build can show adverts at all.
    var isSupported: Bool {
        #if canImport(GoogleMobileAds)
        return true
        #else
        return false
        #endif
    }

    /// Called once at launch.
    ///
    /// The first advert is only asked for once the SDK says it has finished
    /// starting up. Asking sooner is the quickest way to a request error:
    /// the SDK has no configuration yet and fails the request rather than
    /// queuing it.
    func start() {
        #if canImport(GoogleMobileAds)
        guard !hasStarted else { return }
        hasStarted = true
        GADMobileAds.sharedInstance().start { [weak self] _ in
            Task { @MainActor in await self?.load() }
        }
        #endif
    }

    /// Asks Apple's tracking question, once, at a moment where it makes
    /// sense.
    ///
    /// Deliberately not at launch. The first thing a new player should see is
    /// their park, not a permission sheet about adverts they have not been
    /// offered yet; this is asked when they open the boosts screen, which is
    /// the first time adverts are anything to do with them. The system only
    /// shows it once however often this is called, and every answer is fine:
    /// a refusal means less relevant adverts and nothing else.
    func requestTrackingPermissionIfNeeded() async {
        #if canImport(AppTrackingTransparency)
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        _ = await ATTrackingManager.requestTrackingAuthorization()
        #endif
    }

    /// Makes sure an advert is on its way, and does not return until the
    /// answer is known either way.
    ///
    /// Callers share one request. The button and the launch-time preload can
    /// easily ask at the same moment, and the second caller waiting on the
    /// first is the difference between "here is your advert" and a button
    /// that says nothing is ready while an advert is in fact seconds away.
    func load() async {
        #if canImport(GoogleMobileAds)
        if isReady { return }

        if let running = inFlight {
            await running.value
            return
        }

        let task: Task<Void, Never> = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.request()
        }
        inFlight = task
        await task.value
        inFlight = nil
        #endif
    }

    #if canImport(GoogleMobileAds)
    /// One request, tried a few times.
    ///
    /// An empty advert exchange is an ordinary event rather than a fault and
    /// usually clears within a minute, so a failure is tried again with a
    /// backoff before the player is told anything.
    private func request() async {
        isLoading = true
        var failure: Error?

        // Deliberately not clearing lastError here. Showing an advert starts
        // a preload for the next one straight afterwards, and clearing on the
        // way in wiped the message explaining what had just gone wrong before
        // anybody could read it. It is cleared on success instead.
        for attempt in 1...Self.loadAttempts {
            do {
                loaded = try await GADRewardedAd.load(withAdUnitID: AdConfiguration.activeRewardedUnitID,
                                                      request: GADRequest())
                isReady = true
                isLoading = false
                lastError = nil
                return
            } catch {
                failure = error
                loaded = nil
                isReady = false
                if attempt < Self.loadAttempts {
                    try? await Task.sleep(nanoseconds: UInt64(attempt) * 2_000_000_000)
                }
            }
        }

        isLoading = false
        if let failure { lastError = Self.explain(failure) }
    }
    #endif

    /// How many times a request is tried before giving up.
    private static let loadAttempts = 3

    #if canImport(GoogleMobileAds)
    /// Turns the SDK's error into something a player can act on, keeping the
    /// code on the end so a report names the real cause.
    private static func explain(_ error: Error) -> String {
        let failure = error as NSError
        let code = GADErrorCode(rawValue: failure.code)
        let detail: String
        switch code {
        case .noFill:
            detail = "No advert was available just now. This is normal for a new app, and it usually clears in a few minutes."
        case .networkError, .timeout:
            detail = "Could not reach the advert service. Check the connection and try again."
        case .invalidRequest:
            detail = "This build asked for an advert the network does not recognise."
        case .serverError, .internalError:
            detail = "The advert service had a problem. Try again shortly."
        default:
            detail = failure.localizedDescription
        }
        return "\(detail) (code \(failure.code))"
    }
    #endif

    /// Shows the advert and returns true only when the viewer earned the
    /// reward. Closing it early, or any failure, returns false.
    func show() async -> Bool {
        #if canImport(GoogleMobileAds)
        // Waits on whatever request is already running rather than racing it.
        await load()

        guard let ad = loaded else {
            if lastError == nil {
                lastError = "No advert was available just now. Try again in a moment."
            }
            return false
        }
        guard let root = Self.rootViewController else {
            lastError = "There is no screen to show the advert over."
            return false
        }

        loaded = nil
        isReady = false

        let presenter = AdPresenter()
        self.presenter = presenter
        let outcome = await presenter.present(ad, from: root)
        self.presenter = nil
        if outcome.earned {
            lastError = nil
        } else if let failure = outcome.failure {
            lastError = failure
        }

        // The next one starts loading straight away, so a player who wants a
        // second helping is not left waiting on a spinner.
        Task { await load() }
        return outcome.earned
        #else
        lastError = "Adverts are not part of this build."
        return false
        #endif
    }

    #if canImport(GoogleMobileAds)
    /// The SDK is only started once, however many times `start()` is called.
    private var hasStarted = false
    /// The request in progress, so everybody who asks waits on the same one.
    private var inFlight: Task<Void, Never>?
    private var loaded: GADRewardedAd?
    /// Held for as long as the advert is on screen, because the SDK keeps
    /// only a weak reference to its delegate.
    private var presenter: AdPresenter?

    /// The view controller an advert is presented over.
    ///
    /// The topmost one, not the window's root. The boosts screen is a sheet
    /// presented over the root, and UIKit refuses to present anything over a
    /// controller that is already presenting: the advert would be turned away
    /// the instant it was asked for, which looks from the outside like a
    /// button that flashes and does nothing.
    private static var rootViewController: UIViewController? {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
        var top = root
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
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

    /// What came of showing an advert: whether the reward was earned, and if
    /// it was not, why, so the screen can say something rather than nothing.
    struct Outcome {
        let earned: Bool
        let failure: String?
    }

    private var finish: ((Outcome) -> Void)?
    private var earned = false

    func present(_ ad: GADRewardedAd, from root: UIViewController) async -> Outcome {
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
        let failure = error as NSError
        complete(Outcome(earned: false,
                         failure: "The advert could not be shown. \(failure.localizedDescription) (code \(failure.code))"))
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        complete(Outcome(earned: earned, failure: nil))
    }

    /// Guarded, because resuming a continuation twice is a crash.
    private func complete(_ outcome: Outcome) {
        let handler = finish
        finish = nil
        handler?(outcome)
    }
}
#endif
