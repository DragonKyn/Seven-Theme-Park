# Wonder Lot

An original theme park management simulation for iPhone and iPad, built with
Swift, SwiftUI and SpriteKit. The name lives in one place
(`ParkEmpire/App/AppInfo.swift`) so it can be changed without touching the UI;
the Xcode target stays `ParkEmpire` so file paths remain stable.

## Status: 1.0, ready for App Store review

### The game

- **Three modes.** A normal park that has to pay for itself, a free build with
  the accounting switched off, and Park Trials: fifteen rungs of parks built
  to a deadline on harder and harder land.
- **Ten maps** to build on, from open meadow to a scatter of islands and a
  valley zig-zagging through solid rock, plus your own custom layouts.
- **Rides, shops and booths.** Twenty-odd rides including a coaster you lay
  the track for yourself, food and drink stalls, souvenir shops and seven
  carnival booths whose winners carry their prizes round the park.
- **Guests with opinions.** They arrive on real demand, pathfind, queue, eat,
  tire, need the restroom, judge your prices, and tell you what is wrong if
  you tap them.
- **Staff who choose their own work.** Janitors, mechanics, entertainers and
  security, each picking the nearest job that needs doing.
- **Rare events.** A famous visitor who posts about the park, an anonymous
  critic who reviews it, a safety inspector who can shut a ride, a
  troublemaker security has to see off, and tour buses that arrive all at
  once.
- **Progression that lasts.** Rides, shops and booths can all be improved, and
  every trial beaten pays a permanent point into a tree of park-wide perks.
- **Runs on an old phone.** iOS 15 and later, so an iPhone X, 8, 7 or 6s is
  included. A graphics setting turns the drawing down on the phones that need
  it and leaves everything else exactly as it was.

### Technical notes

- No image assets beyond the app icon. Every ride, guest, shop and tile is
  drawn procedurally into a cached texture.
- Fixed-timestep simulation split into systems, none of which know about the
  interface.
- Saves are versioned and decode leniently, so a park from an older build
  still loads.
- Ads are optional and rewarded only. Nothing interrupts the park, there is no
  in-game currency, and nothing is locked behind a purchase.
- The deployment target is iOS 15. Everything SwiftUI added after that has a
  fallback in `ParkEmpire/UI/Common/Compatibility.swift`, which is the whole
  list of things to delete when the floor eventually rises. Swift Charts is the
  one real gap: below iOS 16 the money graph is drawn by hand into a `Canvas`
  from the same palette.
- The graphics setting (`ParkEmpire/Game/Settings/DisplaySettings.swift`)
  only ever changes rendering — frame rate, how many guests are drawn, bubble
  count, texture scale. The simulation never reads it, so a park runs the same
  on every phone and a Park Trial is equally hard on all of them.

## Building

Open `ParkEmpire.xcodeproj` in Xcode 16 or later and build for iOS 15 or
later. The Google Mobile Ads SDK is resolved as a Swift package on first
build.

CI builds an unsigned IPA for sideloading on every push to `main`; the log and
a build report are published to the `ci-logs` branch.

## Releasing

`.github/workflows/app-store-release.yml` archives a signed build and hands it
to Apple. It only ever runs when started by hand, from the Actions tab, and it
defaults to `validate`, which does everything an upload does except deliver —
run it that way first. Nothing in it submits for review or releases to the
public; the build lands in TestFlight and the rest stays a deliberate click in
App Store Connect. Its logs go to the `release-logs` branch.

It needs four repository secrets — `APPSTORE_KEY_ID`, `APPSTORE_ISSUER_ID`,
`APPSTORE_PRIVATE_KEY` (the whole `.p8` file) and `APPLE_TEAM_ID` — and two
optional ones that let it reuse a distribution certificate instead of asking
Apple for a new one each run. The comment at the top of the workflow says what
each is.

## Before submitting

- The bundle identifier is `com.wickedstudios.wonderlot.7X49UN26T8`. It must match both
  the App Store Connect record and the AdMob app, or adverts will not serve.
- `Config/Info.plist` carries the AdMob application id, the tracking usage
  description and the export compliance answer.
- `ParkEmpire/PrivacyInfo.xcprivacy` declares the required-reason API the app
  uses and the advertising identifier the ad network may read.
- Debug builds use Google's test ad unit. Release builds use the live one.
- The oldest supported device is an iPhone 6s on iOS 15. Worth a pass on a
  small screen before uploading: the layouts were drawn for a taller phone,
  and 375x667 is the tightest thing the game has to fit into.
