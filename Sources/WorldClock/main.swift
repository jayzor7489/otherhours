// The host app. macOS only lists a widget whose containing app exists and has been opened,
// so this app registers the widget, repairs a stale one and explains how to use it. It also
// lives in the menu bar (no Dock icon) with a panel of the same cities, and owns the settings.
import AppKit
import ServiceManagement
import SwiftUI
import WidgetKit
import WorldClockCore
import WorldClockViews

/// Re-register the embedded extension and restart it, so a grey widget after a reboot,
/// update or reinstall recovers just by opening the app. Failures are ignored.
func repairWidget() {
    let app = Bundle.main.bundleURL
    let appex = app.appendingPathComponent("Contents/PlugIns/WorldClockWidget.appex")
    let lsregister = "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
    for (tool, args) in [(lsregister, ["-f", app.path]), ("/usr/bin/pluginkit", ["-a", appex.path]),
                         ("/usr/bin/killall", ["WorldClockWidget"])] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tool)
        process.arguments = args
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
    }
    WidgetCenter.shared.reloadAllTimelines()
}

/// The data files are shipped once, inside the widget extension; the app reads those copies.
func bundledData(_ name: String) -> URL {
    Bundle.main.bundleURL.appendingPathComponent("Contents/PlugIns/WorldClockWidget.appex/Contents/Resources/\(name)")
}

let directory: CityDirectory = (try? CityDirectory.load(contentsOf: bundledData("cities.tsv"))) ?? CityDirectory(records: [])
let abbreviations: [AbbreviationRecord] = (try? loadAbbreviations(contentsOf: bundledData("abbreviations.tsv"))) ?? []

enum LoginItem {
    static var isOn: Bool { SMAppService.mainApp.status == .enabled }

    static func set(_ on: Bool) {
        try? on ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
    }

    /// Turned on once, at first launch. After that the user's choice stands, even if they
    /// switch it off in System Settings.
    static func setUpOnce() {
        let key = "loginItemSetUp"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        set(true)
        UserDefaults.standard.set(true, forKey: key)
    }
}

struct HowToView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("World Clock").font(.title2.bold())
            step(1, "Right-click the desktop, choose **Edit Widgets**, search for **World Clock** and add the medium or large size.")
            step(2, "Click the globe clock in the menu bar, then **Settings…**. Add cities by searching for a city, state, country or time zone: \"Colorado\" finds Mountain Time.")
            step(3, "Pick a theme in Settings. The widget and the menu bar panel both follow it.")
            step(4, "If the widget ever turns grey, open this app again. It has just repaired the widget.")
            Divider()
            Text("Your own time is always the first row. Daylight saving is handled by macOS.")
                .font(.callout).foregroundStyle(.secondary)
            Text("City data from GeoNames (geonames.org), CC BY 4.0.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 440)
    }

    private func step(_ n: Int, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(n)").font(.headline).frame(width: 22, height: 22).background(Circle().fill(.quaternary))
            Text(text).fixedSize(horizontal: false, vertical: true)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var statusItem: NSStatusItem?
    let popover = NSPopover()
    lazy var store: SettingsStore = SettingsStore(defaults: .standard) { [weak self] in
        WidgetCenter.shared.reloadAllTimelines()
        self?.model.refresh()
    }
    lazy var model: PanelModel = PanelModel(store: store)
    /// Built on first use: indexing 34,000 cities takes a moment.
    lazy var placeSearch: PlaceSearch = PlaceSearch(directory: directory,
                                       regions: (try? loadRegions(contentsOf: bundledData("regions.tsv"))) ?? [],
                                       abbreviations: abbreviations, displayLocale: .autoupdatingCurrent)
    lazy var settingsWindow: SettingsWindowController = SettingsWindowController { [unowned self] in
        SettingsView(store: store, search: { self.placeSearch },
                     labeller: ZoneLabeller(abbreviations: abbreviations, directory: directory))
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.global(qos: .utility).async(execute: repairWidget)
        LoginItem.setUpOnce()

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = menuBarIcon()   // a globe with clock hands, see MenuBarIcon.swift
        item.button?.target = self
        item.button?.action = #selector(togglePanel)
        statusItem = item

        popover.behavior = .transient
        popover.appearance = NSAppearance(named: .darkAqua)
        let host = NSHostingController(rootView: PanelHost(model: model, onHowTo: { [weak self] in self?.showHowTo() },
                                                           onSettings: { [weak self] in self?.showSettings() }))
        host.sizingOptions = .preferredContentSize
        popover.contentViewController = host

        // Own time follows the Mac: refresh the panel and the widget as soon as the zone changes.
        NotificationCenter.default.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: .main) { [weak self] _ in
            NSTimeZone.resetSystemTimeZone()
            self?.model.refresh()
            WidgetCenter.shared.reloadAllTimelines()
        }

        let howToShownKey = "howToShown"
        if !UserDefaults.standard.bool(forKey: howToShownKey) {
            UserDefaults.standard.set(true, forKey: howToShownKey)
            showHowTo()
        }
    }

    /// Opening the app again while it runs: repair the widget and show the how-to.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        DispatchQueue.global(qos: .utility).async(execute: repairWidget)
        showHowTo()
        return true
    }

    @objc func togglePanel() {
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        guard let button = statusItem?.button else { return }
        model.refresh()
        popover.appearance = model.settings.theme.followsAppearance ? nil : NSAppearance(named: .darkAqua)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    func showSettings() {
        popover.performClose(nil)
        settingsWindow.show()
    }

    func showHowTo() {
        popover.performClose(nil)
        if window == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: HowToView()))
            window.title = "World Clock"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)  // menu bar only, no Dock icon
app.run()
