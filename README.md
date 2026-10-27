# World Clock

A macOS desktop widget that shows your own time plus as many cities as you want. Each city gets its flag and a bar coloured by its sky right now (night, dawn, day, dusk), so you can see at a glance who's asleep. It replaces Apple's World Clock widget, which is fixed at four cities.

Personal build for one Mac. Built with the Xcode Command Line Tools only, no Xcode.

## Install

```sh
scripts/build.sh
```

This builds `World Clock.app` with its widget extension, checks it, signs it ad-hoc, installs it to `~/Applications`, registers the widget and opens the app. Then right-click the desktop > **Edit Widgets**, search **World Clock**, and add the medium or large size.

## Use

- **Cities:** right-click the widget > **Edit "World Clock"** and type a comma-separated list: `Denver, London, Sydney`. Any number. Your own time is always the first row and doesn't need typing.
- **Namesakes:** the most populous city of a name wins. Add a country code in brackets for another: `Sydney (CA)`. Short forms work: NYC, LA, SF, KL, HCMC, DC.
- **Unknown names** show as ❓ in grey, so typos are visible.
- **Daylight saving** is automatic. Time, day and colours update every minute by themselves.
- **Too many cities:** rows turn compact, then the last row reads "+N more". Use a large widget, or a second widget, for more.

## If the widget turns grey

Open **World Clock** from Applications. On every launch it re-registers the widget, restarts it and reloads it.

## How it's built (and why it's unusual)

Widgets normally need Xcode. This one doesn't:

- `Package.swift` links the extension with `-e _NSExtensionMain`. Without it the extension starts at Swift `main`, never handshakes, and the gallery shows nothing.
- `scripts/make_metadata.py` hand-writes `Metadata.appintents`, which Xcode would generate, by copying the shape of Apple's own Journal widget. This is what makes the **Edit** panel exist.
- The only setting is a `String`. A dropdown (`AppEnum`) shows in the panel, but without Xcode's metadata it never decodes in the extension.
- The extension is ad-hoc signed with the app sandbox.

**Risk:** the metadata format is undocumented. If a macOS update breaks the Edit panel, regenerate it against the newest system widget's `extract.actionsdata`. Design and evidence: `docs/specs/2026-10-27-world-clock-design.md`.

## Develop

- Tests: `scripts/test.sh` (Swift Testing, WorldClockCore).
- Visual check without a desktop: `swift run WorldClockPreview Resources/cities.tsv docs/previews` renders PNGs.
- Logs: `/usr/bin/log show --last 5m --style compact --info --predicate 'process == "WorldClockWidget"'`. Use the full path: zsh has its own `log` command.
- City data: `python3 -I scripts/make_cities.py` regenerates `Resources/cities.tsv`.
- Manual checks: `docs/manual-checklist.md`.

## Credits

City data from GeoNames (geonames.org), CC BY 4.0.
