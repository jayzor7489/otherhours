// The host app. macOS only lists a widget whose containing app exists and has been opened,
// so this app registers the widget, repairs a stale one and explains how to use it. It also
// lives in the menu bar (no Dock icon) with a panel showing the widget's cities.
import AppKit
import ServiceManagement
import SwiftUI
import WidgetKit
import WorldClockCore
import WorldClockViews
import WorldClockWidget  // SelectCitiesIntent, to decode the widgets' settings

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

/// The typed city list of every World Clock widget on the desktop, and how many widgets there are.
/// The decode works because SelectCitiesIntent's module is named WorldClockWidget (see its file).
func widgetCityLists() async -> (lists: [String], widgetCount: Int) {
    guard #available(macOS 15, *) else { return ([], 0) }
    let widgets = ((try? await WidgetCenter.shared.currentConfigurations()) ?? []).filter { $0.kind == "WorldClock" }
    return (widgets.compactMap { $0.widgetConfigurationIntent(of: SelectCitiesIntent.self)?.cities }, widgets.count)
}

/// The city list is shipped once, inside the widget extension; the app reads that copy.
let directory: CityDirectory = {
    let url = Bundle.main.bundleURL.appendingPathComponent("Contents/PlugIns/WorldClockWidget.appex/Contents/Resources/cities.tsv")
    return (try? CityDirectory.load(contentsOf: url)) ?? CityDirectory(records: [])
}()

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

final class PanelModel: ObservableObject {
    @Published var rows: [ClockRow] = []
    @Published var userZone = TimeZone.current
    @Published var hasWidget = true
    @Published var openAtLogin = LoginItem.isOn

    @MainActor func refresh() async {
        let (lists, widgetCount) = await widgetCityLists()
        NSTimeZone.resetSystemTimeZone()  // pick up a Mac time zone change
        userZone = TimeZone.current
        rows = makeRows(typed: panelCityList(widgetLists: lists), userZone: userZone, directory: directory)
        hasWidget = widgetCount > 0
        openAtLogin = LoginItem.isOn
    }
}

struct PanelHost: View {
    @ObservedObject var model: PanelModel
    let onHowTo: () -> Void

    var body: some View {
        MenuPanelView(rows: model.rows, userZone: model.userZone, locale: .autoupdatingCurrent,
                      note: model.hasWidget ? "Edit cities: right-click your widget › Edit" : "Add the World Clock widget to choose cities",
                      openAtLogin: Binding(get: { model.openAtLogin },
                                           set: { LoginItem.set($0); model.openAtLogin = LoginItem.isOn }),
                      onHowTo: onHowTo, onQuit: { NSApp.terminate(nil) })
    }
}

struct HowToView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("World Clock").font(.title2.bold())
            step(1, "Right-click the desktop, choose **Edit Widgets**, search for **World Clock** and add the medium or large size.")
            step(2, "Right-click the widget, choose **Edit \"World Clock\"** and type your cities separated by commas, e.g. `Denver, London, Sydney`. Add a country in brackets to pick a namesake: `Sydney (CA)`.")
            step(3, "Click the globe in the menu bar to see the same cities. With several widgets, it shows the cities of all of them.")
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
    let model = PanelModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.global(qos: .utility).async(execute: repairWidget)
        LoginItem.setUpOnce()

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "World Clock")
        item.button?.target = self
        item.button?.action = #selector(togglePanel)
        statusItem = item

        popover.behavior = .transient
        popover.appearance = NSAppearance(named: .darkAqua)
        let host = NSHostingController(rootView: PanelHost(model: model, onHowTo: { [weak self] in self?.showHowTo() }))
        host.sizingOptions = .preferredContentSize
        popover.contentViewController = host

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
        Task { @MainActor in
            await model.refresh()  // the cities may have been edited since last time
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
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
