# Releasing Wonder Lot on Google Play

Everything here is the part only the account owner can do. The build is already set up to use the results.

## 1. What CI produces

Every push to `main` that touches `android/` builds:

| Artifact | What it is |
| --- | --- |
| `wonderlot-debug-apk` | A debug APK for sideloading or the emulator. Uses Google's test advert IDs. |
| `wonderlot-release` | `app-release.aab` (what Play wants), a release APK, and `mapping.txt` (for de-obfuscating crash reports). |

Until the secrets below exist, the release files are **unsigned** and use Google's **test** advert IDs. That is fine
for checking the build and useless for the store.

## 2. Google Play Console

1. Create a developer account at <https://play.google.com/console> (one-off US$25 fee, and identity verification).
2. Create an app: name **Wonder Lot**, default language, "Game", free, with the declarations the form asks for.
3. Let Play manage the app signing key when asked (the default for new apps). You only need an **upload key**.
4. Fill in the store listing from `android/store/LISTING.md`: the text is ready to paste, and `icon-512.png`,
   `feature-graphic.png` and `screenshots/` are the graphics. (The screenshots come from an emulator; replace them with
   real-phone ones if you like.)
5. Content rating questionnaire, target audience (not designed for children), data safety form, and the privacy policy URL.
   `android/store/LISTING.md` has the answers for each.
   - Data safety: the game collects nothing itself. Google's advertising SDK collects the advertising ID and
     device/usage data for advertising, so declare that under "Advertising or marketing" and "Device or other IDs".
   - The privacy policy must be public. The existing GitHub Pages one only mentions iPhone and iPad:
     `android/store/privacy-policy-draft.html` is the same page with the Android wording added. Review it and, if you are
     happy, copy it over `docs/index.html` and push. It has not been published.
6. Ads declaration: **Yes, contains ads**.

## 3. AdMob

1. In AdMob, add an **Android** app (package `com.wickedstudios.wonderlot`). This gives an app ID like
   `ca-app-pub-XXXXXXXXXXXXXXXX~NNNNNNNNNN`.
2. Add a **Rewarded** ad unit to it. This gives a unit ID like `ca-app-pub-XXXXXXXXXXXXXXXX/NNNNNNNNNN`.
3. Add `app-ads.txt` to the developer website if AdMob asks (the iOS app has the same requirement).
4. In AdMob's *Privacy & messaging*, create a GDPR message and a US state regulations message. The game starts
   Google's consent flow (UMP) at launch, and it shows whatever you publish there.

## 4. Upload key and GitHub secrets

Make an upload key once, and keep the file and passwords somewhere safe (a password manager). Losing it is
recoverable through Play, but slow.

```bash
keytool -genkeypair -v -keystore upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
base64 -w0 upload.jks > upload.jks.b64     # on macOS: base64 -i upload.jks
```

Then in the GitHub repository, **Settings > Secrets and variables > Actions**, add:

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | contents of `upload.jks.b64` |
| `ANDROID_KEYSTORE_PASSWORD` | the keystore password |
| `ANDROID_KEY_ALIAS` | `upload` |
| `ANDROID_KEY_PASSWORD` | the key password |
| `ADMOB_APP_ID` | the Android app ID from step 3 |
| `ADMOB_REWARDED_UNIT_ID` | the rewarded unit ID from step 3 |

The next CI run produces a signed `app-release.aab` with real advert IDs. Its version code is the CI run number, so
it always goes up.

## 5. First upload

1. Play Console > your app > **Testing > Internal testing** > create a release, and upload `app-release.aab`.
2. Add yourself as a tester, install from the opt-in link, and check that the game and a rewarded advert work.
   (Adverts for a brand-new app can take hours to start filling, and "no fill" in the meantime is normal.)
3. New personal developer accounts must run a **closed test with at least 12 testers for 14 days** before they can
   apply for production access. Start that early.
4. Promote to production once it has passed review.

## Local builds

Needs JDK 17 and the Android SDK (platform 36):

```bash
cd android
gradle :app:assembleDebug                       # debug APK
RELEASE_STORE_FILE=... RELEASE_STORE_PASSWORD=... RELEASE_KEY_ALIAS=... RELEASE_KEY_PASSWORD=... \
  gradle :app:bundleRelease -PADMOB_APP_ID=... -PADMOB_REWARDED_UNIT_ID=...
```

## Things worth knowing

- Saves are stored on the device and are **not** compatible with the iOS game. There is no cloud save.
- `minSdk` is 24 (Android 7.0).
- Release builds are minified with R8, so crash stack traces need `mapping.txt` from the matching build.
