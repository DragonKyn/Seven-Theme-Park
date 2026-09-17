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

### Technical notes

- No image assets beyond the app icon. Every ride, guest, shop and tile is
  drawn procedurally into a cached texture.
- Fixed-timestep simulation split into systems, none of which know about the
  interface.
- Saves are versioned and decode leniently, so a park from an older build
  still loads.
- Ads are optional and rewarded only. Nothing interrupts the park, there is no
  in-game currency, and nothing is locked behind a purchase.

## Building

Open `ParkEmpire.xcodeproj` in Xcode 16 or later and build for iOS 17. The
Google Mobile Ads SDK is resolved as a Swift package on first build.

CI builds an unsigned IPA for sideloading on every push to `main`; the log and
a build report are published to the `ci-logs` branch.

## Before submitting

- The bundle identifier is `com.wickedstudios.wonderlot`. It must match both
  the App Store Connect record and the AdMob app, or adverts will not serve.
- `Config/Info.plist` carries the AdMob application id, the tracking usage
  description and the export compliance answer.
- `ParkEmpire/PrivacyInfo.xcprivacy` declares the required-reason API the app
  uses and the advertising identifier the ad network may read.
- Debug builds use Google's test ad unit. Release builds use the live one.
