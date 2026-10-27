// The menu bar panel's state: rows built from the saved settings and the Mac's own zone.
import AppKit
import SwiftUI
import WorldClockCore
import WorldClockViews

final class PanelModel: ObservableObject {
    let store: SettingsStore
    @Published var rows: [ClockRow] = []
    @Published var userZone = TimeZone.current
    @Published var openAtLogin = LoginItem.isOn

    var settings: ClockSettings { store.settings }

    init(store: SettingsStore) {
        self.store = store
    }

    func refresh() {
        userZone = TimeZone.current
        rows = makeRows(saved: store.settings.cities, userZone: userZone, directory: directory)
        openAtLogin = LoginItem.isOn
    }
}

struct PanelHost: View {
    @ObservedObject var model: PanelModel
    let onHowTo: () -> Void
    let onSettings: () -> Void

    var body: some View {
        MenuPanelView(rows: model.rows, userZone: model.userZone, locale: .autoupdatingCurrent,
                      hourCycle: model.settings.hourCycle, theme: model.settings.theme,
                      openAtLogin: Binding(get: { model.openAtLogin },
                                           set: { LoginItem.set($0); model.openAtLogin = LoginItem.isOn }),
                      onSettings: onSettings, onHowTo: onHowTo, onQuit: { NSApp.terminate(nil) })
    }
}
