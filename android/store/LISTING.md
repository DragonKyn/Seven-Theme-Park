# Google Play listing: Wonder Lot

Everything the Play Console form asks for, ready to paste. Character limits are Play's.

## Main store listing

**App name** (30): `Wonder Lot`

**Short description** (80):
`Build rides, shops and a park people love. Turn a little lot into a lot of wonder.`

**Full description** (4000):

```
Turn a little lot into a lot of wonder.

Wonder Lot is a theme park builder. You start with an empty field, a gate and some money. Lay a walkway, put something worth walking to at the end of it, and watch the first guests arrive. Keep them happy and the park grows. Ignore the queues, the litter or the prices and they will tell you about it.

BUILD YOUR WAY
• Three ways to play: a normal park that has to pay for itself, Free Build with the accounting switched off, and Park Trials, fifteen parks built to a deadline on harder and harder land.
• Ten maps, from open meadow to a scatter of islands and a valley zig-zagging through solid rock, plus maps you draw yourself.
• Twenty-odd rides, including a coaster you lay the track for yourself, food and drink stalls, souvenir shops and seven carnival booths whose winners carry their prizes around the park.
• Improve rides, shops and booths, and earn permanent perks for every trial you beat.

GUESTS WITH OPINIONS
Guests arrive on real demand, find their own way, queue, eat, get tired, need the restroom and judge your prices. Tap one and they will tell you what is wrong.

STAFF WHO CHOOSE THEIR OWN WORK
Hire janitors, mechanics, entertainers and security. Each picks the nearest job that needs doing, and you can send them where you need them.

SURPRISES
A famous visitor posts about your park. An anonymous critic reviews it. A safety inspector can shut a ride. Tour buses arrive all at once.

SMALL, FAIR AND OFFLINE
• Plays offline. Your parks stay on your device.
• No accounts and no in-app purchases.
• The only ads are optional: watch one on the Boosts screen for a short in-game boost, or never touch it. Everything in the game can be reached without watching a single ad.
• A graphics setting turns the drawing down for older phones.

Wonder Lot is made by Wicked Studios, a very small team. Questions or ideas: wickedstudiosca@gmail.com
```

**Category:** Games > Simulation
**Tags:** Simulation, Building, Management, Casual
**Contact email:** wickedstudiosca@gmail.com
**Website:** https://dragonkyn.github.io/Seven-Theme-Park/
**Privacy policy URL:** the same page, once the Android wording in `privacy-policy-draft.html` is published (see below).

## Graphics (in this folder)

| Asset | File | Size |
| --- | --- | --- |
| App icon | `icon-512.png` | 512 x 512 |
| Feature graphic | `feature-graphic.png` | 1024 x 500 |
| Phone screenshots | `screenshots/` | 1080 x 2400 (2 to 8 needed) |

## Content rating questionnaire (IARC)

Category: **Game**. Answers that matter, all truthful for this game:

- Violence: **No**. Blood: **No**. Fear/horror: **No**.
- Sexual content / nudity: **No**. Profanity: **No**.
- Controlled substances (drugs, alcohol, tobacco): **No**.
- Gambling or simulated gambling: **No**. The carnival booths are skill/prize stalls using in-game money only, with nothing to buy or win for real. If the questionnaire asks about "simulated gambling", answer **No**.
- User-generated content / user interaction / sharing location: **No**. Custom maps stay on the device.
- In-app purchases: **No**. Contains ads: **Yes**.

Expected rating: PEGI 3 / ESRB Everyone.

## Target audience and content

- Target age: **13 and over** (matches the privacy policy: not directed at children). Not "designed for children", so the Families policy does not apply.
- Ads declaration: **Yes, contains ads**.
- News app / COVID / government / financial / health: **No** to all.

## Data safety form

The game collects nothing itself and has no server. The advertising SDK is the only thing that collects data.

**Does your app collect or share any of the required user data types?** Yes (by the Google Mobile Ads SDK).
**Is all of the user data collected by your app encrypted in transit?** Yes.
**Do you provide a way for users to request that their data be deleted?** No (nothing is held; the game's own data is on the device and is removed by uninstalling).

| Data type | Collected | Shared | Purpose | Optional |
| --- | --- | --- | --- | --- |
| Device or other IDs (Advertising ID) | Yes | Yes (Google) | Advertising or marketing | No, collected by the ad SDK; users can reset or opt out in Android settings |
| Approximate location (derived from IP) | Yes | Yes (Google) | Advertising or marketing; fraud prevention | No |
| App activity: app interactions (ad views/taps) | Yes | Yes (Google) | Advertising or marketing; analytics | No |
| App info and performance: crash logs, diagnostics | Yes | Yes (Google) | Analytics; fraud prevention | No |

Everything else (name, email, contacts, photos, precise location, financial info, health, messages, files) is **not collected**.

> Check this against what AdMob currently documents at https://support.google.com/admob/answer/6128543 before submitting, because Google updates the list of what its SDK collects.

## App access / other declarations

- App access: **All functionality is available without special access.**
- Ads: **contains ads** (rewarded, opt-in).
- Government apps / financial features / health: none.
- Advertising ID: **the app uses it** (the ad SDK does). The manifest declares `com.google.android.gms.permission.AD_ID` via the SDK; answer "Yes, for advertising".

## Privacy policy

The live policy at the support page only talks about iPhone and iPad. `privacy-policy-draft.html` is the same page with the Android wording added (Advertising ID, Google's consent form, where to opt out). It has **not** been published. Review it, then copy it over `docs/index.html` and push, so the URL Play checks says the right thing.

## Release notes (first release)

```
First Android release of Wonder Lot. Build your own theme park: rides, shops, staff, a coaster you lay track for, fifteen park trials and ten maps. Plays offline.
```
