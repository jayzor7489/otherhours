// The host app. macOS only lists a widget whose containing app exists and has been opened,
// so this app's jobs are: register the widget, repair a stale one, and explain how to use it.
import AppKit
import SwiftUI
import WidgetKit

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

struct HowToView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("World Clock").font(.title2.bold())
            step(1, "Right-click the desktop, choose **Edit Widgets**, search for **World Clock** and add the medium or large size.")
            step(2, "Right-click the widget, choose **Edit \"World Clock\"** and type your cities separated by commas, e.g. `Denver, London, Sydney`. Add a country in brackets to pick a namesake: `Sydney (CA)`.")
            step(3, "If the widget ever turns grey, open this app again. It has just repaired the widget.")
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

    func applicationDidFinishLaunching(_ notification: Notification) {
        repairWidget()
        let window = NSWindow(contentViewController: NSHostingController(rootView: HowToView()))
        window.title = "World Clock"
        window.styleMask = [.titled, .closable]
        window.center()
        window.makeKeyAndOrderFront(nil)
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
