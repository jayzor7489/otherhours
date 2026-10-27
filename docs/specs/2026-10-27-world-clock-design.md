# World Clock: design

A desktop widget for Jason's Mac that shows the time in as many cities as he wants, each with its flag and a background coloured by that city's sky right now. It replaces Apple's World Clock widget, which is fixed at four cities and shows clock faces only.

It lives in the normal macOS widget gallery (right-click the desktop > Edit Widgets) next to his other widgets. Cities are chosen in Apple's own Edit Widget panel by typing a list.

## Why

- Apple's World Clock widget holds exactly four cities and can't be extended. Its binary is on the sealed system volume, so it can't be edited either.
- The everyday use (Claude's guess, not confirmed): checking whether someone in another zone is awake before messaging them, for example Rob and the Trajector team in Denver.
- Success: one glance at the desktop tells him the time and day/night for every place he cares about, his own time included, without opening anything.

## Decisions (Jason, 2026-10-27)

| Topic | Decision |
|---|---|
| Form | A real macOS widget in the Edit Widgets gallery, not a floating window. |
| Look | Style **B, Day / night**: each city is a rounded bar coloured by its local sky (night, dawn, day, dusk), with flag, city name, "Today · −14 hrs" line, sun or moon icon, and the time on the right. Mockup: `docs/mockups/visual-style.html`. |
| Your own time | Always shown as the first row without typing it. |
| Choosing cities | Right-click the widget > Edit, type a comma-separated list (`Denver, London, Sydney`). Any number. |
| Flags | Yes, next to every city. |
| Daylight saving | Automatic (macOS time zone database). |
| Sizes | Medium and large only. No small. |
| Too many cities | Rows switch to a compact form (no "Today · …" line, thinner bars). If they still don't fit, the last row reads "+N more". |
| His usual medium | You + Denver, London, Sydney (4 rows) shows **compact** with bigger names and times (mockup `docs/mockups/medium-four-rows.html`, option 2). So medium is full only up to 3 rows. |
| Refresh | Time, day label and day/night colour update by themselves, every minute, with nothing open. |
| Login | Nothing to start at login: macOS runs the widget itself and keeps it on the desktop across restarts. The host app is only opened to recover a grey widget. |
| Debug text | None in the finished widget. |
| Location | `world-clock/`, named "World Clock". |

## How it gets built (proven by the 2026-10-27 spike)

The Mac has the Command Line Tools only, no Xcode, and not enough free disk to install it. The spike (`scratchpad/spike-worldclock`, throwaway) proved each step below on macOS 27.0.1 (26A434):

1. **Extension binary.** `swiftc -application-extension -parse-as-library -Xlinker -e -Xlinker _NSExtensionMain`. The entry point flag is mandatory: without it the extension starts at Swift `main`, traps or exits, and the gallery shows nothing (the failure in vibes #42, Khayt #1902, CodexBar #1095). The build checks `nm -u <binary> | grep _NSExtensionMain` and fails if missing.
2. **Extension Info.plist.** `CFBundlePackageType XPC!`, `NSExtension > NSExtensionPointIdentifier = com.apple.widgetkit-extension`.
3. **Signing.** Ad-hoc. The `.appex` is signed first with `com.apple.security.app-sandbox = true` (macOS refuses unsandboxed plug-ins), then the host app. No app group: ad-hoc signing can't carry one, and none is needed. The build verifies the sandbox entitlement survived.
4. **Install.** Copy to `~/Applications/World Clock.app` (the real home: in Claude's sandboxed sessions `$HOME` points elsewhere, so the path is absolute), `lsregister -f`, `pluginkit -a`, launch the host once. Bump `CFBundleVersion` on every build and `killall` the running extension, or the desktop keeps showing the old code.
5. **Edit Widget panel without Xcode.** Xcode normally generates `Contents/Resources/Metadata.appintents/{extract.actionsdata,version.json}`; the Command Line Tools have no `appintentsmetadataprocessor`. A Python script writes the file by hand, copying the exact shape Apple's own toolchain (27A200c) emits for Journal's `StreaksWidgetConfigurationIntent`. Mangled names follow `<len><module><len><type>V` and the build checks they exist in the binary.
6. **Only a plain String parameter works.** An `AppEnum` dropdown shows in the panel and macOS sends the choice (seen in the log as `city = 2` and `city = denver`), but the App Intents runtime in the extension can't decode it (`Prepared city to CityChoice(nil)`) and silently falls back to the default. A `String` parameter (`typeIdentifier 0`) decodes correctly. Hence the typed list.

Debugging note: in zsh `log` is a shell builtin. Use `/usr/bin/log show ... --predicate 'process == "WorldClockWidget"'`.

## Architecture

1. **WorldClockCore** (pure Swift, no UI, tested with Swift Testing): parse the typed list; resolve names to cities; compute local time, day label and offset; pick the sky band; decide the layout (full, compact, "+N more") for a size and row count.
2. **Widget extension** (`WorldClockWidget.appex`, SwiftUI + WidgetKit + AppIntents): the configuration intent with one `String` parameter `cities`, the timeline provider, the views. Compiled by `swiftc` together with the WorldClockCore sources.
3. **Host app** (`World Clock.app`, AppKit or SwiftUI): exists so macOS registers the widget. Its one window explains how to add the widget and edit cities, and carries the GeoNames attribution. Clicking the widget opens it. **Recovery** (Claude's call, 2026-10-27): on every launch it re-registers its own extension (`lsregister -f` on itself, `pluginkit -a` on the `.appex`), ends any running extension process older than the installed binary, and calls `WidgetCenter.shared.reloadAllTimelines()`. So "a grey widget after a reboot or update" has one documented fix: open World Clock. The README says so. No separate repair button.
4. **Scripts**: `scripts/build.sh` (build, metadata, sign, verify, install, register), `scripts/test.sh` (Swift Testing with the plugin-path fix from Desk Pet), `scripts/make_metadata.py`, `scripts/make_cities.py` (one-off: turns GeoNames into the bundled city file).

## The widget

### Rows

- **First row: you.** Time zone from the Mac (`TimeZone.current`), so it follows him if the Mac's zone changes. Label: city part of the zone identifier (`Asia/Manila` → Manila) plus "· you". Its sub-line shows the date ("Tue, Oct 27") instead of an offset.
- **Then each typed city, in typed order.** Duplicates (same resolved zone and name) shown once.
- **Full row:** flag · city name · sub-line "Today · −14 hrs" · sky icon · time (with a small AM/PM when the Mac uses 12-hour time).
- **Compact row:** flag · city name · sky icon · time, on a thinner bar. No sub-line.
- **Unrecognised name:** ❓ and the typed text in grey, no time, so typos are visible. Still takes a row.

### Day and offset

- "Today", "Tomorrow" or "Yesterday", relative to the user's own date.
- Offset from the user's zone in hours: `−14 hrs`, `+3 hrs`, `0 hrs` shown as "Same time". Non-whole offsets as `+5:30 hrs`, `+5:45 hrs`.

### Sky bands (by the city's local hour)

| Band | Local time | Background | Icon |
|---|---|---|---|
| Night | 21:00 to 04:59 | deep navy to indigo | 🌙 |
| Dawn | 05:00 to 07:59 | blue-violet to peach | 🌅 |
| Day | 08:00 to 16:59 | sky blue to light blue | ☀️ |
| Dusk | 17:00 to 20:59 | blue to amber | 🌇 |

Colours follow the mockup; white text on every band, checked for contrast. Exact sunrise times are a non-goal (see below).

**When macOS strips colour** (Claude's call, 2026-10-27). Depending on System Settings > Desktop & Dock > Widget style, macOS can draw desktop widgets in monochrome (vibrant) mode, for example while a window covers the desktop, or tinted/clear. Hue and emoji colour are lost there. The widget reads `widgetRenderingMode`:
- `.fullColor`: the sky gradients and emoji icons above.
- `.vibrant` / `.accented`: bands differ by brightness instead (night darkest, day lightest), the sky icon becomes an SF Symbol (`moon.stars.fill`, `sunrise.fill`, `sun.max.fill`, `sunset.fill`) so it survives tinting, and the row card is handed to the system via `containerBackground` (widget-studio's finding: a background drawn as content turns into a white blob in accented mode). Flags stay as emoji; they may render tinted.
The manual checklist covers all three widget styles.

### Fitting rows to the size

- **Medium:** up to 3 full rows. 4 to 5 rows: all compact. More than 5: 4 compact rows plus "+N more".
- **Large:** up to 7 full rows. 8 to 10: all compact. More than 10: 9 compact rows plus "+N more".
- The user's own row counts as a row and is never the one dropped.
- The exact numbers are the builder's to tune by eye on the real widget; the rule (full, then compact, then "+N more") is fixed.

### Refresh

One timeline entry per minute, starting at the current minute (a timeline that starts in the future draws an empty placeholder), 60 entries, policy `.atEnd`. That is about 24 timeline reloads a day, well inside WidgetKit's budget.

Every entry computes everything from its own `entry.date`: each city's time, its Today/Tomorrow/Yesterday label and its sky band. So a city crossing 21:00 turns to night on that minute, and the day label flips at local midnight, without a reload. After the Mac wakes from sleep WidgetKit shows the entry for the current minute, or asks for a new timeline if the old one ran out.

Known limit (Claude's call): the user's own zone is read when the timeline is built, so if the Mac's time zone changes (travel) the "you" row can lag by up to an hour, until the next reload. Other cities stay correct, because they are computed from absolute time. The extension also reloads when the Mac's time zone changes, if WidgetKit delivers that signal; the builder checks this during the manual run.

## Finding cities

- **Bundled list:** GeoNames `cities15000` (about 26,000 cities, CC BY 4.0), preprocessed into a compact file inside the extension: name, ASCII name, country code, time zone, population. Attribution in the host app window and README.
- **Match:** case-insensitive on name or ASCII name ("Sao Paulo" finds São Paulo). If several cities share a name, the most populous wins ("Sydney" is Australia, not Nova Scotia). A country code in brackets picks another: `Sydney (CA)`.
- **Short aliases:** a small built-in table (NYC, LA, SF, KL, HCMC, DC).
- **Fallback:** a time zone identifier's city part (`Denver`), so anything the spike accepted still works.
- **Flag:** from the resolved country code via regional-indicator emoji. Fallback 🌐.

## Non-goals

- App Store, notarisation, or other people's Macs. Personal build for Jason's Mac only. Publishing to GitHub only on Jason's go.
- A dropdown city picker in Edit Widget (proven not to decode without Xcode; see step 6).
- A small widget size.
- Exact sunrise/sunset per city. Hour bands are enough to see who's asleep.
- Weather, alarms, a menu bar clock, a settings window.

## Anti-goals (would make it a failure even if it runs)

- A wrong time or wrong day for any city, including across daylight-saving changes.
- A city silently dropped or swapped: unrecognised names must show as ❓.
- The widget showing a grey placeholder after a normal reboot or macOS update without a clear way to recover.

## Risks

- **Hand-written metadata may break on a macOS update** (undocumented format). Symptom: Edit Widget loses the Cities field, or the widget shows only defaults. Recovery path: compare against the system's newest widget metadata (Journal) and regenerate. Last-resort fallback: a settings window in the host app writing the list into the extension's sandbox container.
- **Ad-hoc signing acceptance could change** in a future macOS. Same recovery story; nothing to do now.

## Testing

- WorldClockCore unit tests (Swift Testing): list parsing (spaces, empty items, duplicates, brackets), name resolution (accents, ties by population, aliases, unknowns), day label and offset across midnight and the date line, half and quarter-hour zones, a DST changeover (Denver on 2026-11-01, London on 2026-10-25), sky bands at band edges, the layout rule per size.
- Build checks in `build.sh`: entry point, sandbox entitlement, mangled names present, metadata JSON valid.
- Manual checklist (`docs/manual-checklist.md`) on the real desktop: add medium and large, type 2, 5 and 12 cities, an unknown name, a bracket country, light and dark desktop, each widget style (full colour, monochrome with a window in front, tinted), after a reboot, and recovery by opening the app.

## Left to the builder

- Exact colours, fonts, spacing and corner sizes within style B.
- File layout inside the package, test names, and the city file format.
- Bundle identifiers (suggested `com.jasonaldemita.worldclock` and `.widget`).

## Cleanup

Remove the spike app (`World Clock Spike.app` in `~/Applications`) and its widgets once World Clock is installed, so the gallery has one entry.
