# Park Empire

An original theme park management simulation for iPhone, built with Swift,
SwiftUI and SpriteKit. Working title — the name lives in one place
(`ParkEmpire/App/AppInfo.swift`) so it can be changed without touching the UI.

## Status: Phase 2 (staff, maintenance and cleanliness)

Working today:

- Main menu with three save slots, new game, continue, load, delete
- 30×30 tile park with an entrance and a short starting walkway
- SpriteKit map with pinch-to-zoom, drag-to-pan, tap-to-inspect
- Build menu: walkways, four rides, six shops and stalls, restroom, bench, bin
- Placement preview with valid/invalid feedback, path painting, demolition
  (with a confirmation for anything expensive)
- Guests that arrive based on real demand, pathfind, queue, ride, eat, drink,
  use the restroom, rest, get happy or fed up, and go home
- Guest inspector: needs, personality, live thoughts, spending, rides taken
- Ride and shop inspectors, including a price slider with real consequences
- Park rating, finances (today / lifetime, by category), management dashboard
- Alerts, pause / 1x / 2x / 4x, autosave and manual save

Added in Phase 2:

- **Litter.** Guests leave a food stall holding rubbish. They look for a bin;
  the longer they carry it the likelier they are to drop it, and tidy guests
  hold on much longer than messy ones. Litter on the ground makes guests
  unhappy, drags the rating down, and eventually drives the fussiest ones home.
- **Bins and dirty restrooms.** Bins fill up and stop accepting rubbish;
  restrooms get dirty with use and guests refuse to enter a filthy one. Only a
  janitor reverses either.
- **Staff.** Janitors, mechanics and entertainers, each with a hiring cost and
  a wage charged continuously through the day. They pick their own work,
  walk to it on the paths, and do it — no manual assignment needed.
- **Breakdowns.** Ride condition falls only while running. A well-maintained
  ride essentially never fails; a neglected or uninspected one fails often.
  A breakdown closes the ride, empties it, clears the queue and upsets
  everyone involved until a mechanic walks over and repairs it.
- **Full park rating.** All eight weighted components now have real data,
  including cleanliness, ride reliability and park appearance.

Not yet built (later phases, by design): reputation tiers, unlock progression,
objectives, decorations and landscaping, sound, tutorial, custom coaster
building.

## Opening the project

Requires **Xcode 16 or newer** (the project uses filesystem-synchronised
groups, so new Swift files are picked up automatically without editing the
project file).

```
open ParkEmpire.xcodeproj
```

Pick an iPhone simulator or your device and run. For a device build you will
need to set a Development Team on the target.

## Building an IPA for sideloading

`.github/workflows/ios-unsigned-ipa.yml` builds an **unsigned** `.ipa` on every
push to `main` and on manual dispatch. Download it from the workflow run's
artifacts and install it with Sideloadly, which re-signs it with your own Apple
ID.

To run it manually: Actions → *Build unsigned IPA* → *Run workflow*.

## Playing it

You start with $25,000, an entrance and four tiles of walkway.

**Nobody will arrive until there is a reason to visit.** Demand is computed from
what the park offers versus what you charge, so an empty park at the default $25
gate price attracts zero guests. Either build a ride or drop the admission price
(gear icon, top right) and visitors start showing up.

A good first park: draw a walkway loop, put a Carousel and a Burger Stand on it,
add a Restroom, then watch a guest by tapping them.

Then watch what breaks. Sell food without placing bins and the paths fill with
rubbish within a day; place bins without hiring a janitor and they overflow.
Run rides without a mechanic and they will eventually break and stay broken.
The Staff button on the bottom bar is where you fix all three.

## Architecture

```
ParkEmpire/
  App/            App entry, router, naming
  Game/
    Simulation/
      Entities/   Guest, Attraction, Facility
      Systems/    Demand, GuestAI, Movement, Attraction, Facility,
                  Cleanliness, Maintenance, Staff, Economy, Rating,
                  Pathfinding
      SimulationEngine.swift   fixed-tick loop
    World/        GridCoord, Tile, ParkMap, placement rules
    Data/         Definitions and the content catalogue, Balance constants
    State/        GameState, ledger, clock, alerts, UI snapshots
    GameController.swift       the only thing the UI talks to
  Rendering/      SpriteKit scene, nodes, programmatic textures
  Persistence/    Versioned Codable saves
  UI/             SwiftUI menus, HUD, build menu, inspectors, dashboards
```

Rules the code follows:

- Game rules are data (`GameContent`, `Balance`), not switch statements. Adding
  a ride is a new `AttractionDefinition`, not new simulation code.
- The simulation runs on a fixed 0.1s tick; rendering runs at the display rate.
  Game speed multiplies ticks, so behaviour is identical at 1x and 4x.
- SwiftUI observes snapshot structs published ~5 times a second, never the
  simulation itself.
- Pathfinding builds one cached breadth-first distance field per destination,
  shared by every guest, rebuilt only when the layout changes. Staff job search
  reuses the same machinery in reverse: one sweep outwards from the employee,
  then every candidate job's distance is a lookup.
- Save files are versioned and decode leniently: every type that has gained
  fields falls back to a default rather than failing, so a save from an earlier
  phase still loads. Adding a field in a later phase means adding one line.

## Balancing

Every tuning number is in `ParkEmpire/Game/Data/Balance.swift`.
