# Otherhours (formerly World Clock): manual checklist

Things only the real desktop can show. Install first with `scripts/build.sh`. Debug with
`/usr/bin/log show --last 5m --style compact --info --predicate 'process == "WorldClockWidget"'` (zsh's own `log` is a different command).

Results: ✅ passed, ❌ failed, ⏳ not run yet.

## Install and edit

- ✅ **Gallery lists it.** Edit Widgets > search "World Clock" shows medium and large. (2026-10-27)
- ✅ **Default list.** A new medium shows you + Denver, London, Sydney. (2026-10-27, log `cities = "Denver, London, Sydney"`)
- ~~**Edits apply.** Right-click > Edit "World Clock", type a new list: the widget changes within seconds. Hobart and Cairns both arrived and decoded (`Prepared cities to String(...)`). (2026-10-27)~~ SUPERSEDED 2026-10-27: cities are set in Settings now.
- ✅ **No-DST zone.** Cairns shows AEST (4:42 PM at 2:42 PM Manila). (2026-10-27)
- ✅ **Spike gone.** No "World Clock Spike" in the gallery; `pluginkit -m -p com.apple.widgetkit-extension | grep -i spike` is empty. (2026-10-27)

## Layout

- ⏳ **Large.** Add a large one: up to 7 rows show with the "Today · −14 hrs" line.
- ⏳ **Compact.** Medium with you + 3 or 4 cities: compact rows, bigger names and times.
- ⏳ **Overflow.** Type 12 cities into a medium: 4 rows, then "+N more" with the right count.
- ~~**Unknown name.** `Denver, Qwertyville`: Qwertyville shows as ❓ in grey. (Not "Atlantis": that's a real city in South Africa.)~~ SUPERSEDED 2026-10-27: cities are set in Settings now.
- ~~**Namesake.** `Sydney (CA)` shows 🇨🇦 Sydney on Atlantic time; `Sydney` alone shows 🇦🇺.~~ SUPERSEDED 2026-10-27: cities are set in Settings now.
- ~~**Empty list.** Clear the field: only your row plus "Right-click › Edit Widget to add cities".~~ SUPERSEDED 2026-10-27: cities are set in Settings now.

## Appearance

- ✅ **Light and dark desktop.** Text readable on both. (Jason, 2026-10-28)
- ✅ **Monochrome.** (Jason, 2026-10-28) System Settings > Desktop & Dock > Widgets > Dim widgets on desktop: **Always** (this Mac has no "Widget style" menu): bars differ by brightness, sun/moon become symbols, day vs night still readable.
- ✅ **Tinted / clear style.** Same check with the tinted style. (Jason, 2026-10-28)
- ⏳ **Sharp times.** Times look crisp, not glowing or blurred, once a minute has passed (a soft blur during the minute change is the system's animation).

## Time

- ⏳ **Minute ticks.** Leave it 2 minutes: every row advances by itself.
- ✅ **24-hour Mac.** System Settings > General > Date & Time > 24-hour time on: rows show `17:10` with no AM/PM. (Jason, 2026-10-28)
- ⏳ **DST on Sunday Nov 1.** Denver's line changes from "−14 hrs" to "−15 hrs" by itself.
- ➖ **Time zone change.** Skipped by Jason 2026-10-28. Change the Mac's time zone: within an hour (sooner after an edit) the first row follows.

## Recovery

- ✅ **After a reboot.** The widget comes back on its own, not grey. (Jason, 2026-10-28)
- ⏳ **Repair.** If it is ever grey, opening Otherhours fixes it within a few seconds.

## Menu bar (added 2026-10-27)

- ✅ **Widgets kept their cities** after the module rename (both read back "Denver, London, Cairns").
- ✅ **Login item registered** (enabled, allowed).
- ⏳ **Menu bar icon and panel.** A globe with clock hands sits in the menu bar (the plain globe and then a one-colour day/night clock were tried first; Jason preferred a globe, 2026-10-28); clicking it shows Manila plus Denver, London, Cairns with the widget's colours; clicking again or elsewhere closes it.
- ~~**Follows the widget.** Edit a widget's cities, reopen the panel: the new list shows.~~ SUPERSEDED 2026-10-27: cities are set in Settings now.
- ~~**Two widgets.** Give the large one an extra city: the panel shows it, and shared cities appear once.~~ SUPERSEDED 2026-10-27: cities are set in Settings now.
- ✅ **Long list.** 10+ cities: the panel scrolls; the medium widget ends in "+5 more". (Jason, 2026-10-28)
- ⏳ **Gear menu.** Open at Login tick matches System Settings; How to Use opens the window; Quit removes the icon. (Quit ✅ (Jason, 2026-10-28))
- ⏳ **Ticks.** Leave the panel open across a minute change: times advance.
- ⏳ **No Dock icon**, and the app comes back after a reboot.

## Settings in the menu bar (added 2026-10-27)

- ✅ **Widget reads the app's settings.** After `defaults write`, the real widget process logged `timeline: 3 cities` for both placed widgets; they survived the switch to a display-only widget.
- ⏳ **Start clean.** Your saved cities were cleared at install. Click the menu bar globe › Settings… and add Denver, London, Cairns by searching. The panel and both widgets show them within a few seconds.
- ⏳ **Search by hand.** "Colorado" → Denver, Mountain Time (MDT) first; "Japan" → Tokyo; "PST" → Los Angeles; "syd" → Sydney 🇦🇺 then Sydney 🇨🇦; "Arizona" → Phoenix. Each suggestion shows its local time; an added place shows "added".
- ⏳ **Add slot.** + Add city focuses the search; Return picks the first suggestion; Escape or Cancel closes the slot.
- ✅ **Reorder and remove.** (Jason, 2026-10-28) Drag a city onto another row (it highlights; dragging down lands after it, up lands before it), or right-click › Move Up/Down; the minus button removes it. Widget and panel follow. ❌ 2026-10-28: drag did nothing (`.onMove` only works in a List, Settings is a Form); now drag and drop per row, recheck.
- ⏳ **Themes on the desktop.** Pick each of Day & Night, List, Clocks, Spotlight: widget and panel switch within a few seconds. List and Spotlight in light and dark mode.
- ✅ **Time format.** 24-hour shows `14:10`, no AM/PM, in widget, panel and Settings; Follow Mac goes back to the Mac's setting. (Jason, 2026-10-28: 24-hour works)
- ➖ **Mac time zone change.** Skipped by Jason 2026-10-28. Change the Mac's time zone: the first row, Settings' own row, the panel and the widget all follow within seconds.
- ⏳ **Empty state.** Remove every city: widget says "Add cities from the globe in the menu bar"; panel says "Add cities in Settings" and clicking it opens Settings.
- ✅ **Open at Login** checkbox in Settings matches the gear menu and System Settings. (Jason, 2026-10-28)
- ⏳ **Long names.** Colorado Springs lost its flag in Spotlight and squeezed the sun icon in Day & Night (Jason, 2026-10-28). Rule now, every theme: flag, sky icon, time and difference keep their size and place; a long name is cut ("Colorado Spr…"); the difference shortens first ("−14 hrs" → "−14"). Previews `long-*`, `narrow-*`. Check on the desktop with Colorado Springs and Honolulu.

## Rename to Otherhours (added 2026-10-28)

- ⏳ **Old one gone.** No "World Clock" from this app in the widget gallery (Apple's own World Clock widget stays); old placed widgets go blank and can be removed.
- ⏳ **New one listed.** Edit Widgets > search "Otherhours" shows medium and large; add them back.
- ⏳ **Settings came across.** Settings shows the same cities, theme and time format as before the rename.
- ⏳ **Login item.** System Settings > General > Login Items shows Otherhours. Remove a leftover "World Clock" entry there if one remains.
