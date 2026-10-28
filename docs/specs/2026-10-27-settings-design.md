# World Clock settings in the menu bar: design

Status: draft for Jason's approval, 2026-10-27. Builds on branch `menu-bar` (widget + menu bar globe and panel), on a new branch `settings`.

## Why

Today cities are typed as a comma list into the widget's own Edit panel (right-click the widget > Edit "World Clock"). Jason finds that awkward: typing is error-prone (typos become ❓ rows, namesakes need `(CA)` codes), and settings are hidden on the desktop. He wants one obvious place for settings, the menu bar globe. The widget goes back to being only a display.

Success: a person who has never seen the app clicks the globe, adds "Colorado" and gets Mountain Time without knowing that's what it's called, and the widget and panel both show it.

## Decisions (Jason, 2026-10-27)

| Decision | Choice |
|---|---|
| Where settings live | In the menu bar app. The widget has no settings of its own. |
| The widget | "Exactly what it is, just a widget": same rows, same look; it only displays. |
| Own time | The Mac's clock, whatever it's set to (New York install shows New York). Follows the Mac when it changes country. |
| Adding cities | Search, not typing a list. The search understands what the person means: "Colorado" suggests Denver / Mountain Time (MDT). |
| How many cities | Slots: a **+** button adds another one. Any number. |
| Theme | A setting, offering the four looks from the first mockup (`docs/mockups/visual-style.html`). |
| Long names (2026-10-28) | Flag, sky icon, time and difference keep their size and position in every theme; a long city name is cut ("Colorado Spr…"). The difference shortens before anything else ("−14 hrs" → "−14"). |
| Name (2026-10-28) | **Otherhours**, Jason's pick from seven names that no App Store or Mac App Store app, GitHub clock project or time product was found using (raters averaged it 7.0/10; Skyhours 6.7 and Faraway Hours 6.3 were the runners-up). App, widget, bundle IDs (`com.jasonaldemita.otherhours`) and preferences carry the new name; Swift targets and the repo folder keep WorldClock (Claude's call: renaming them is churn with no user-visible effect). First launch copies settings from the old preferences. Not checked: trademark registers. |
| Menu bar icon (2026-10-28) | A globe with clock hands at 4:00, drawn as a template image. A one-colour day/night clock was tried first; Jason preferred a globe. |
| Earlier answers still standing | Globe icon only in the menu bar; panel shows the same rows; starts at login; no Dock icon; medium and large widgets; compact then "+N more" in the widget when the list is long. |

## What the person sees

### The panel (click the globe)

As built on `menu-bar`: own time first, then each city, in the chosen theme, ticking each minute, scrolling past 8 rows. The footer changes: the note "Edit cities: right-click your widget" goes; a **Settings…** button takes its place, and the gear menu keeps Open at Login, How to Use, Quit (Claude's call: Settings is a visible button because it is now the main way in).

With no cities yet, the panel shows own time plus a row "Add cities in Settings" that opens Settings.

### Settings window (Claude's call: a window, not inside the panel)

Reason: it now holds a search with suggestions, a reorderable list and a theme picker with previews; the panel is transient and closes on any click elsewhere, which fights typing and dragging. A normal window, opened from the panel's Settings… button, sized about 460 × 560, one per app (re-opening brings it to the front).

Three sections, top to bottom:

1. **Cities**
   - First row, fixed and not removable: own time, e.g. "🇵🇭 Manila · your Mac's time zone". It changes when the Mac's time zone changes.
   - Then one row per city slot: drag handle, flag, name, a grey second line (region and country, time zone name with abbreviation, e.g. "Colorado, United States · Mountain Time (MDT)"), and a remove button.
   - A **+ Add city** button below the list adds an empty slot with a focused search field. Typing shows up to 8 suggestions under it; Return or click picks one and the slot becomes a city row. Escape or clicking away with nothing picked removes the empty slot.
   - Changes apply immediately (no Save button); the widget and panel update within a few seconds.
2. **Appearance**: the theme picker. Four tiles, each a small live render of the widget in that theme with the person's own cities; click to choose. Default: Day & Night.
3. **General**: Time format (Follow Mac / 12-hour / 24-hour, default Follow Mac); Open at Login (checkbox, mirrors System Settings).

### The widget

Same rows, same sizes, same compact / "+N more" rule, in the chosen theme. It has no Edit panel any more (no "Edit World Clock" in its right-click menu). With no cities set, it shows own time plus "Add cities from the menu bar 🌐".

## Finding cities (the search)

One search box, matched against five kinds of place, ignoring case and accents, prefix matches on any word ("lake" finds Colorado Springs):

| Typed | Matches | Suggestion shown |
|---|---|---|
| A city: "syd" | GeoNames city names | 🇦🇺 Sydney · New South Wales, Australia · Australian Eastern Time (AEDT); 🇨🇦 Sydney · Nova Scotia, Canada · Atlantic Time (ADT) |
| A state or province: "Colorado" | GeoNames first-level regions | 🇺🇸 Denver · Mountain Time (MDT), "covers Colorado"; plus its biggest cities (Colorado Springs, Colorado) |
| A country: "Japan" | Country names (macOS's own list) | One suggestion per time zone the country uses, named by its biggest city: Japan → Tokyo; United States → New York, Chicago, Denver, Phoenix, Los Angeles, Anchorage, Honolulu |
| An abbreviation: "PST", "MDT", "AEST" | The zone abbreviations macOS knows, plus the generic zone names | 🇺🇸 Los Angeles · Pacific Time (PST) |
| A zone name: "Mountain Time" | macOS's generic time zone names | as above |

Rules:
- **One suggestion per distinct clock, not per time zone identifier** (Claude's call, from the builder check). GeoNames puts US cities in 14 identifiers (Detroit, Indiana/Indianapolis, Kentucky/Louisville, Boise...) but they are 7 clocks. Identifiers are grouped when they have the same UTC offset now and the same offsets at every daylight-saving transition over the next 12 months. Each group is represented by its most populous identifier (US Eastern → America/New_York), and that identifier is what gets stored. So "United States" gives 7 suggestions and "Australia" 5. Arizona stays its own clock (Phoenix), because its offsets differ from Denver's half the year.
- **Naming:** a city match shows the city ("Colorado Springs"). A region, country, abbreviation or zone-name match shows the representative identifier's own city (America/Denver → Denver, Asia/Kolkata → Kolkata, Asia/Manila → Manila), the same naming as the own-time row. A state with two clocks (e.g. Indiana, Florida) shows one suggestion per clock.
- Arizona must suggest Phoenix (Mountain Standard Time all year), not Denver: the zone comes from the data, never from "same abbreviation".
- Ranking: exact name before prefix, then city over region over country over abbreviation, then by population. Up to 8 results.
  - *Accepted deviation (build, 2026-10-27):* an exact-name city under 1 million people ranks after an exact state or country of that name, so "Puerto Rico" gives the island before the town in Colombia. Cost: "Washington" offers the state's clock (Los Angeles · Covers Washington) and Seattle before Washington DC, which is still listed; "DC" goes straight to it.
  - *Added (final review):* everyday country names (USA, UK, UAE, Turkey, China, Holland, Burma...), old city names (Kiev, Bombay, Saigon, Madras, Peking...), zone-name words ("Eastern" ranks New York with provinces named Eastern, by population) and UTC.
- Each suggestion shows the current local time on the right, so the person can tell they picked the right clock.
- A city already in the list is shown greyed with "added".
- Nothing found: "No place called 'xyz'. Try a city, state or country."

Data: GeoNames cities15000 as today, plus the region (admin1) code per city and GeoNames `admin1CodesASCII.txt` for region names (both CC BY 4.0, already credited). Country names come from `Locale.localizedString(forRegionCode:)`. Generic zone names ("Mountain Time") come from `TimeZone.localizedName(for: .generic, locale:)`.

**Abbreviations come from a small bundled table** (Claude's call, from the builder check). macOS's own data can't do the job on this Mac: `abbreviationDictionary` has no AEST/AEDT and maps IST only to Kolkata, and in the Mac's en_PH locale Sydney's short name is "GMT+11"; "AEDT" appears only under en_AU. So `Resources/abbreviations.tsv` lists the common ones by hand, each as abbreviation → standard/daylight → identifier(s): PST/PDT, MST/MDT (Denver; MST also Phoenix), CST/CDT, EST/EDT, AKST/AKDT, HST, AST/ADT, NST/NDT, GMT/BST, IST (Kolkata, Dublin, Jerusalem), CET/CEST, EET/EEST, WET/WEST, MSK, GST (Dubai), PKT, NPT, BST (Dhaka too), ICT, WIB, SGT, HKT, PHT/PHST, JST, KST, AWST, ACST/ACDT, AEST/AEDT, NZST/NZDT, SAST, WAT, EAT, BRT, ART, CLT/CLST. About 60 rows. The table is used both for search (every match is shown, each with its flag: IST gives 3) and for display: a row's second line shows the table's abbreviation for the zone's current period, falling back to `localizedName(.shortStandard / .shortDaylightSaving)` in the zone's own country locale, then to "GMT+11".

## What is stored

The app saves to its own preferences (`com.jasonaldemita.worldclock`):
- `cities`: an ordered list of picked places, each `{name, countryCode, timeZoneID}`. Stored as picked, not as typed text, so nothing is re-resolved later and there are no ❓ rows.
- `theme`: `dayNight` | `list` | `clocks` | `spotlight`.
- `hourCycle`: `system` | `h12` | `h24`.

Own time is not stored; it is read from the Mac every time.

## How the widget gets the settings (proven 2026-10-27)

The widget is sandboxed and there is no paid developer account, so there is no shared App Group. Instead the widget's entitlements gain `com.apple.security.temporary-exception.shared-preference.read-only` = `["com.jasonaldemita.worldclock"]`, and it reads `UserDefaults(suiteName: "com.jasonaldemita.worldclock")`.

Spike (scratchpad, ad-hoc signed sandboxed app bundle): with the exception it read the value the app wrote, and saw a change immediately; an identical bundle without the exception read nil. Still to prove in the real widget process during the build (first task).

After each change the app calls `WidgetCenter.shared.reloadAllTimelines()`.

The widget switches from `AppIntentConfiguration` to `StaticConfiguration` (same kind, `WorldClock`). This deletes the riskiest part of the current build: the hand-written `Metadata.appintents`, `scripts/make_metadata.py`, the `SelectCitiesIntent` type and the `WorldClockWidget` library that existed only to keep its mangled name. The "never rename that module" rule goes away with it.

## Own time follows the Mac

- The app listens for `NSSystemTimeZoneDidChange`. On it: reset the cached zone, refresh the panel and Settings, and call `reloadAllTimelines()` so the widget changes within seconds, not at its next hourly reload.
- The widget's timeline already resets the zone on every reload; keep that.
- Own-time name and flag come from the zone as today (Asia/Manila → 🇵🇭 Manila; America/New_York → 🇺🇸 New York).

## Themes

The four looks from `docs/mockups/visual-style.html`, each in the widget (medium, large) and the panel:

| Theme | Look | Long lists (widget; panel in brackets) |
|---|---|---|
| **Day & Night** (default, today's) | Rows as coloured bars by the city's sky (night, dawn, day, dusk) | As today: full, compact, "+N more" |
| **List** | Clean white list, thin dividers, light time digits. Dark variant when the Mac is in dark mode (Claude's call: a white card at night would glare) | Same row-count rule as Day & Night |
| **Clocks** | Analog faces in a grid, name and day/offset under each | Medium: up to 4 faces in a row (own + 3), then "+N more"; large: 3 × 3 grid. (Panel: 3 per row, scrolling) |
| **Spotlight** | Own time large on the left, cities as a compact list on the right | Medium: own + 3 cities; large: own + 9; then "+N more". (Panel: own time large across the top, cities as a list below it, scrolling) |

**Light and dark** (Claude's call): Day & Night and Clocks are dark always, as in the mockup. List and Spotlight follow the Mac's appearance, white in light mode and a dark variant in dark mode, in both the widget and the panel; the panel stops forcing dark for those two.

Every theme keeps the existing monochrome / tinted rule: when macOS renders the widget without full colour, fall back to brightness-only fills and SF Symbols, as Day & Night does today.

## Non-goals

- Per-widget city lists (one list, shared by every widget and the panel).
- Typing a comma list anywhere.
- Custom colours or fonts beyond the four themes.
- Showing anything other than the globe in the menu bar itself.
- Sync between Macs, iPhone, publishing (not on GitHub unless Jason says).

## Anti-goals (a failure even if it runs)

- Search that needs the person to know time zone names or codes. "Colorado" has to work.
- A search result that lands on the wrong clock (Arizona → Denver would be wrong half the year).
- Settings that save but the widget doesn't follow (stale widget).
- Own time stuck on the zone the Mac had at install.

## Risks

- **Placed widgets after the switch to StaticConfiguration.** Jason's two placed widgets were made as configurable widgets. They may carry on, go grey, or need removing and re-adding. Found out at install; worst case he re-adds them once. His current list (Denver, London, Cairns) is not carried over automatically (Claude's call: carrying it over means keeping the hand-written metadata for one more release); he adds the three cities in Settings, which also exercises the new search.
- **The preference exception inside chronod's widget process.** Proven in a sandboxed app, not yet in the widget. If it fails, fallback: `com.apple.security.temporary-exception.files.home-relative-path.read-only` on a small JSON file the app writes. Decide during task 1, before anything else is built.
- **Analog Clocks theme with many cities** gets small. The caps above keep faces at least 52 pt.

## Testing

- Unit (Swift Testing, WorldClockCore): the search table above as tests, including Colorado → America/Denver, Arizona → America/Phoenix, Japan → Asia/Tokyo, United States → 7 clocks (America/Detroit grouped into New_York), Australia → 5, "syd" → AU first then CA, PST → America/Los_Angeles, IST → 3 results, AEST → Australia/Sydney (and Cairns's clock), a Sydney row's abbreviation reads AEDT in October whatever the Mac's locale, "springs" → Colorado Springs, accents ("sao" → São Paulo), no results. Stored-city round trip. Layout caps per theme.
- Preview renders (WorldClockPreview) of each theme × size, plus monochrome, checked by eye.
- Manual checklist additions: settings change reaches the widget; Mac time zone change; each theme on the desktop; drag reorder; placed-widget behaviour after the switch.

## Left to the builder

Exact layout spacing per theme within the mockup's proportions; search result row design; the empty-state wording beyond what's given; whether the Settings window is SwiftUI `Settings` scene or an NSWindow (the app is AppKit today).
