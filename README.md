# Park Empire

An original theme park management simulation for iPhone, built with Swift,
SwiftUI and SpriteKit. Working title — the name lives in one place
(`ParkEmpire/App/AppInfo.swift`) so it can be changed without touching the UI.

## Status: Phase 5 in progress (transport, achievements, modes)

Working today:

- Main menu with three save slots, new game, continue, load, delete, over a
  live demo park that runs the real simulation behind it
- 30×30 tile park with an entrance and a short starting walkway
- SpriteKit map with pinch-to-zoom, drag-to-pan, tap-to-inspect
- Build menu: walkways, water, fifteen rides, six shops and stalls, restroom,
  bench, bin, and seven pieces of scenery, each with a thumbnail of its real
  artwork
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

Added in Phase 3 so far:

- **Distinct artwork.** Every building names a motif and three colour roles;
  the renderer turns that into bezier artwork, so a Carousel and a Sky Plunge
  no longer look alike. Still procedural, still cached, still no image assets.
  Adding a ride is one entry in `GameContent`, which now describes how it
  looks as well as how it plays.
- **Rides that move.** The carousel turns, the galleon swings, the tower car
  climbs and drops, a train runs the coaster loop. The moving part is its own
  sprite, so it can be frozen: a ride standing still is closed or broken.
- **Scenery.** Trees, pines, flower beds, lamps, topiary, statues and a
  fountain. Each names how much prettiness it adds and how far that reaches.
  Placing or removing any of them rebuilds a per-tile beauty field, with
  overlapping pieces stacking at diminishing returns, so spreading decoration
  out beats piling it in one corner.
- **Appearance you can change.** Guests gain happiness a little faster on
  pretty ground, and the appearance score now reads mostly from decoration
  rather than from how much grass is left. It rises from a twentieth of the
  park rating to about an eighth.
- **Safer map gestures.** One finger always moves the camera. Laying a run of
  walkway is behind an explicit Draw toggle, so dragging to look around can
  never place anything by accident.

Added in Phase 4 so far:

- **Eleven more rides.** Spinning teacups, bumper cars, a carpet slide, three
  sizes of go-kart track, a haunted manor, a Ferris wheel, a slingshot, a log
  flume and a large coaster. The big ones are deliberately land-hungry: a
  Grand Prix circuit costs six by eight tiles of park.
- **Water.** Terrain rather than an object, so it is drawn by dragging like a
  walkway and refunded like one. Nothing crosses it and nothing builds on it,
  and it makes the ground around it prettier than anything at the price.
- **Upgrades.** Four tracks apply to every ride rather than being written per
  attraction: extra cars, faster loading, reinforced parts, and theming, which
  both excites guests and decorates the ground around the ride. An upgraded
  ride reports itself through the definition it already had, so every system
  picked the change up without being told about upgrades.
- **Staff training.** One track, three levels: faster on their feet, faster at
  the job, and dearer to keep.
- **Guests who look like people.** Shirt, hair, skin tone and headwear combine
  into far more variety than a set of fixed sprites would, and lean on age.
  Mood shows as a coloured pad on the ground under them, which still reads
  when a guest is six pixels tall without sitting behind the figure.
- **Thought bubbles.** A fresh thought pops a bubble showing what it is about,
  tinted by mood. Only recent thoughts qualify and ten show at once, so a park
  full of complaints reads as trouble without becoming noise.
- **Staff you can tell apart.** Guests and employees share one drawn figure,
  so the body lives in one place and each caller adds what makes it
  recognisable. Employees wear the park's uniform colour, which is a single
  park-wide setting, and stay distinguishable by their hat and what they
  carry: a broom, a spanner, or two balloons.
- **A sign at the gate.** A board on two posts outside the entrance carrying
  the park's name, facing the way an arriving guest walks in.
- **A lighter interface.** Panels are a lit blue-slate gradient rather than
  near-black, and cash has its own gold capsule with the day's profit under it.

Added in Phase 5 so far:

- **Two modes.** A park picks its rules when it is created and keeps them.
  Free build never deducts anything but still records what everything would
  have cost, so the finance screen still says whether the park could support
  itself. It earns no achievements.
- **Transport.** Track is terrain, dragged out like a walkway. A station has
  to touch both a walkway and a track, and sets guests down at another station
  on the same railway, which saves a long walk across a big park. The railway
  is derived from the tiles whenever the map changes, so nothing can fall out
  of step with what is on the ground.
- **Trains that look like trains.** Track tiles are drawn from what they join
  on to, so a straight run reads as a straight run. A locomotive and two
  carriages run each route, each starting a tile further back, so the train
  bends through corners instead of pivoting as one block.
- **Achievements.** Seventeen of them, each a ladder of six tiers rather than a
  single target, each paying out more steeply at every rung. Metrics are
  counters the simulation already kept or values read straight off the park.
  Earning one sets off a card and a confetti burst.
- **A car park.** Outside the gate, below the sign. Nothing simulates it.

Not yet built (later phases, by design): reputation tiers, unlock progression,
objectives, sound, tutorial, custom coaster building.

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
      Entities/   Guest, Attraction, Facility, Staff, SceneryItem
      Systems/    Demand, GuestAI, Movement, Attraction, Facility,
                  Cleanliness, Maintenance, Staff, Economy, Rating,
                  Pathfinding
      SimulationEngine.swift   fixed-tick loop
    World/        GridCoord, Tile, ParkMap, TrackNetwork, placement rules
    Data/         Definitions and the content catalogue, Balance constants,
                  BuildingAppearance and GuestAppearance (what things look
                  like, as data), UpgradeDefinition
    State/        GameState, ledger, clock, alerts, UI snapshots
    GameController.swift       the only thing the UI talks to
    DemoPark.swift             the park that runs behind the main menu
  Rendering/      SpriteKit scene, nodes, programmatic artwork
  Persistence/    Versioned Codable saves
  UI/             SwiftUI menus, HUD, build menu, inspectors, dashboards
```

Rules the code follows:

- Game rules are data (`GameContent`, `Balance`), not switch statements. Adding
  a ride is a new `AttractionDefinition`, not new simulation code.
- Appearance is data too. A definition names a motif and three colour roles,
  and a guest names a shirt, hair, skin tone and hat; only the rendering layer
  knows what those mean in pixels, so the content catalogue never imports UIKit.
- Upgrades change a definition rather than being read separately. A ride hands
  out its upgraded stats through the same property every system already read,
  which is why adding upgrades touched no simulation system.
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
