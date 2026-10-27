// The menu bar panel's state: rows built from the saved settings and the Mac's own zone.
import AppKit
import SwiftUI
import WorldClockCore
import WorldClockViews

final class PanelModel: ObservableObject {
    @Published var rows: [ClockRow] = []
    @Published var userZone = TimeZone.current
    @Published var settings = ClockSettings(cities: [], theme: .dayNight, hourCycle: .system)
    @Published var openAtLogin = LoginItem.isOn

    func refresh() {
        settings = ClockSettings.load(from: .standard)
        userZone = TimeZone.current
        rows = makeRows(saved: settings.cities, userZone: userZone, directory: directory)
        openAtLogin = LoginItem.isOn
    }
}

struct PanelHost: View {
    @ObservedObject var model: PanelModel
    let onHowTo: () -> Void

    var body: some View {
        MenuPanelView(rows: model.rows, userZone: model.userZone, locale: .autoupdatingCurrent,
                      hourCycle: model.settings.hourCycle, note: "",
                      openAtLogin: Binding(get: { model.openAtLogin },
                                           set: { LoginItem.set($0); model.openAtLogin = LoginItem.isOn }),
                      onHowTo: onHowTo, onQuit: { NSApp.terminate(nil) })
    }
}
