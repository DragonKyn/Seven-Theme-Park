# Holiday Park Update: design and status

Event window: **25 November to 5 January**, every year, by the player's local date.

Both apps ship it together. The rules live in the shared simulation (Swift `ParkEmpire/Game`, Kotlin `android/core`),
and everything that draws or lays out is written once per platform.

## Decisions

| Question | Decision |
| --- | --- |
| After 5 January | Holiday rides and decorations already built keep working. They cannot be built again, makeovers show the normal look, holiday trials and the announcement are hidden. Unlocked rewards stay earned and come back next year. |
| New Year's rides | Available the whole window, so a park can mix both. |
| Holiday trials | Twelve, all open from 25 November (no ladder order). Completion is recorded per event year, so they can be played again next year. Rewards, once earned, are permanent. |
| Capacity | 250 becomes 300 for everyone, all year. |
| Holiday party | A new kind of tour bus: bigger, with a festive intro, and its guests carry five times the usual spending money. It only books in season. |
| Makeovers | A fifth upgrade on rides ("Holiday Makeover") that a trial reward unlocks. Once unlocked, new rides are built with it already on, and older rides can be upgraded from their panel. |
| Santa and Mrs. Claus | Two new entertainer acts, hireable in season. Santa: "Christmas Cheer" (guests near him spend more). Mrs. Claus: "Fresh Cookies" (guests near her get less hungry). |
| Snow | A weather state that comes and goes during the window: falling snow on the map and a white dusting over grass, paths and rock. Purely visual plus a small arrivals lift. |
| Testing | A developer-only override forces the season on or off. It is not reachable from the game's own screens. |

## Content

**Christmas rides (7):** Reindeer Carousel, Sleigh Ride, Candy Cane Coaster, Snow Globe Spinner, North Pole Express,
Gingerbread Manor, Star Topper Drop.

**New Year's rides (4):** Countdown Wheel, Confetti Swing, Ball Drop Tower, Starburst Coaster.

**Decorations:** Christmas tree, snowman, wreath arch, gift stack, string-light pole, candy cane post, fireworks stand,
countdown clock.

**12 Days of Holiday Wonder:** twelve trials, each rewarding a decoration, a ride makeover, or a seasonal item.

## Status

See the commit history. Each stage below is committed on its own.

1. Calendar, capacity, store of unlocks and announcement choice
2. Content definitions (rides, decorations, acts, trials, party bus)
3. Artwork and motion for the new rides and decorations
4. Makeover upgrade, snow weather, seasonal ground
5. Screens: Holiday trials tab, Christmas menu, announcement, event card
6. Checks on emulator and on the iOS build
