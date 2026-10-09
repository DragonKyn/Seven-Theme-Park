package com.wickedstudios.wonderlot.ads

import android.app.Activity
import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.google.android.gms.ads.AdError
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.FullScreenContentCallback
import com.google.android.gms.ads.LoadAdError
import com.google.android.gms.ads.MobileAds
import com.google.android.gms.ads.rewarded.RewardedAd
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback
import com.google.android.ump.ConsentInformation
import com.google.android.ump.ConsentRequestParameters
import com.google.android.ump.UserMessagingPlatform
import com.wickedstudios.wonderlot.BuildConfig
import kotlinx.coroutines.delay
import kotlinx.coroutines.suspendCancellableCoroutine
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.coroutines.resume

/**
 * Shows a rewarded advert and says whether the reward was earned. Everything the game does with adverts goes through
 * this one door, so the rest of the game never imports an advert SDK.
 *
 * Consent comes first: Google's user messaging platform asks the questions a player in a regulated region must be
 * asked, and the advert SDK is only started once it says adverts may be requested.
 */
class RewardedAdCenter(private val appContext: Context) {

    /** True once there is an advert loaded and ready to show. */
    var isReady by mutableStateOf(false)
        private set

    /** True while one is being fetched, so the button can say so. */
    var isLoading by mutableStateOf(false)
        private set

    /** Set when the last attempt failed, for the sheet to show. */
    var lastError by mutableStateOf<String?>(null)
        private set

    private var consent: ConsentInformation? = null
    private val sdkStarted = AtomicBoolean(false)
    private var started = false
    private var loaded: RewardedAd? = null

    /** What the advert side is doing, plain enough for a player and specific enough to diagnose a quiet failure. */
    val statusLine: String
        get() = when {
            isLoading -> "Fetching an advert."
            isReady -> "An advert is ready."
            !sdkStarted.get() -> "Waiting for the advert service to start."
            else -> "No advert ready yet."
        }

    /** Called once, when the first screen is up. */
    fun start(activity: Activity) {
        if (started) return
        started = true

        val information = UserMessagingPlatform.getConsentInformation(activity)
        consent = information
        val params = ConsentRequestParameters.Builder().build()
        information.requestConsentInfoUpdate(
            activity, params,
            {
                UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity) { _ -> startSdkIfAllowed() }
            },
            { _ -> startSdkIfAllowed() },
        )
        // A returning player who already answered can start straight away.
        startSdkIfAllowed()
    }

    private fun startSdkIfAllowed() {
        if (consent?.canRequestAds() != true) return
        if (!sdkStarted.compareAndSet(false, true)) return
        // The SDK's start-up is heavy and its own documentation asks for a background thread.
        java.util.concurrent.Executors.newSingleThreadExecutor().execute {
            MobileAds.initialize(appContext) { android.os.Handler(android.os.Looper.getMainLooper()).post { load() } }
        }
    }

    /** Whether the player can change their consent answer from the boosts screen. */
    val canChangePrivacyChoices: Boolean
        get() = consent?.privacyOptionsRequirementStatus == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED

    fun showPrivacyOptions(activity: Activity) {
        UserMessagingPlatform.showPrivacyOptionsForm(activity) { _ -> }
    }

    /** Asks for an advert, tried a few times with a short backoff, since an empty exchange is an ordinary event. */
    fun load() {
        if (isReady || isLoading || !sdkStarted.get()) return
        isLoading = true
        attempt(1)
    }

    private fun attempt(number: Int) {
        RewardedAd.load(
            appContext, BuildConfig.REWARDED_UNIT_ID, AdRequest.Builder().build(),
            object : RewardedAdLoadCallback() {
                override fun onAdLoaded(ad: RewardedAd) {
                    loaded = ad
                    isReady = true
                    isLoading = false
                    lastError = null
                }

                override fun onAdFailedToLoad(error: LoadAdError) {
                    loaded = null
                    isReady = false
                    if (number < LOAD_ATTEMPTS) {
                        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({ attempt(number + 1) }, number * 2000L)
                    } else {
                        isLoading = false
                        lastError = explain(error)
                    }
                }
            },
        )
    }

    /** Waits for the advert to be ready, for up to [seconds]. */
    private suspend fun awaitReady(seconds: Int) {
        load()
        var waited = 0
        while (!isReady && isLoading && waited < seconds * 10) {
            delay(100)
            waited += 1
        }
    }

    /** Shows the advert and returns true only when the viewer earned the reward. */
    suspend fun show(activity: Activity): Boolean {
        awaitReady(20)
        val ad = loaded
        if (ad == null) {
            if (lastError == null) lastError = "No advert was available just now. Try again in a moment."
            return false
        }
        loaded = null
        isReady = false

        val earned = suspendCancellableCoroutine { continuation ->
            var reward = false
            ad.fullScreenContentCallback = object : FullScreenContentCallback() {
                override fun onAdDismissedFullScreenContent() {
                    if (continuation.isActive) continuation.resume(reward)
                }

                override fun onAdFailedToShowFullScreenContent(error: AdError) {
                    lastError = "The advert could not be shown. ${error.message} (code ${error.code})"
                    if (continuation.isActive) continuation.resume(false)
                }
            }
            ad.show(activity) { reward = true }
        }

        if (earned) lastError = null
        // The next one starts loading straight away, so a second helping is not a wait on a spinner.
        load()
        return earned
    }

    private fun explain(error: LoadAdError): String {
        val detail = when (error.code) {
            AdRequest.ERROR_CODE_NO_FILL ->
                "No advert was available just now. This is normal for a new app, and it usually clears in a few minutes."
            AdRequest.ERROR_CODE_NETWORK_ERROR -> "Could not reach the advert service. Check the connection and try again."
            AdRequest.ERROR_CODE_INVALID_REQUEST -> "This build asked for an advert the network does not recognise."
            AdRequest.ERROR_CODE_INTERNAL_ERROR -> "The advert service had a problem. Try again shortly."
            else -> error.message
        }
        return "$detail (code ${error.code})"
    }

    private companion object {
        const val LOAD_ATTEMPTS = 3
    }
}
