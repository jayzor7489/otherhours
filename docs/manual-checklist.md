# World Clock: manual checklist

Things only the real desktop can show. Install first with `scripts/build.sh`. Debug with
`/usr/bin/log show --last 5m --style compact --info --predicate 'process == "WorldClockWidget"'` (zsh's own `log` is a different command).

Results: ✅ passed, ❌ failed, ⏳ not run yet.

## Install and edit

- ✅ **Gallery lists it.** Edit Widgets > search "World Clock" shows medium and large. (2026-10-27)
- ✅ **Default list.** A new medium shows you + Denver, London, Sydney. (2026-10-27, log `cities = "Denver, London, Sydney"`)
- ✅ **Edits apply.** Right-click > Edit "World Clock", type a new list: the widget changes within seconds. Hobart and Cairns both arrived and decoded (`Prepared cities to String(...)`). (2026-10-27)
- ✅ **No-DST zone.** Cairns shows AEST (4:42 PM at 2:42 PM Manila). (2026-10-27)
- ✅ **Spike gone.** No "World Clock Spike" in the gallery; `pluginkit -m -p com.apple.widgetkit-extension | grep -i spike` is empty. (2026-10-27)

## Layout

- ⏳ **Large.** Add a large one: up to 7 rows show with the "Today · −14 hrs" line.
- ⏳ **Compact.** Medium with you + 3 or 4 cities: compact rows, bigger names and times.
- ⏳ **Overflow.** Type 12 cities into a medium: 4 rows, then "+N more" with the right count.
- ⏳ **Unknown name.** `Denver, Qwertyville`: Qwertyville shows as ❓ in grey. (Not "Atlantis": that's a real city in South Africa.)
- ⏳ **Namesake.** `Sydney (CA)` shows 🇨🇦 Sydney on Atlantic time; `Sydney` alone shows 🇦🇺.
- ⏳ **Empty list.** Clear the field: only your row plus "Right-click › Edit Widget to add cities".

## Appearance

- ⏳ **Light and dark desktop.** Text readable on both.
- ⏳ **Monochrome.** System Settings > Desktop & Dock > Widget style "Automatic", then bring a window in front of the desktop: bars differ by brightness, sun/moon become symbols, day vs night still readable.
- ⏳ **Tinted / clear style.** Same check with the tinted style.
- ⏳ **Sharp times.** Times look crisp, not glowing or blurred, once a minute has passed (a soft blur during the minute change is the system's animation).

## Time

- ⏳ **Minute ticks.** Leave it 2 minutes: every row advances by itself.
- ⏳ **24-hour Mac.** System Settings > General > Date & Time > 24-hour time on: rows show `17:10` with no AM/PM.
- ⏳ **DST on Sunday Nov 1.** Denver's line changes from "−14 hrs" to "−15 hrs" by itself.
- ⏳ **Time zone change.** Change the Mac's time zone: within an hour (sooner after an edit) the first row follows.

## Recovery

- ⏳ **After a reboot.** The widget comes back on its own, not grey.
- ⏳ **Repair.** If it is ever grey, opening World Clock fixes it within a few seconds.
