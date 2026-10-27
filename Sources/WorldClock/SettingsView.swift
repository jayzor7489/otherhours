// The Settings window: cities (search, slots, reorder), the theme, and General options.
// Every change goes through SettingsStore, which saves and reloads the widget.
import AppKit
import SwiftUI
import WorldClockCore
import WorldClockViews

/// One Settings window, brought to the front if it is already open.
final class SettingsWindowController {
    private var window: NSWindow?
    private let makeView: () -> SettingsView

    init(makeView: @escaping () -> SettingsView) {
        self.makeView = makeView
    }

    func show() {
        if window == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: makeView()))
            window.title = "World Clock Settings"
            window.styleMask = [.titled, .closable, .resizable]
            window.setContentSize(NSSize(width: 460, height: 560))
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    let search: () -> PlaceSearch
    let labeller: ZoneLabeller

    @State private var adding = false
    @State private var query = ""
    @State private var userZone = TimeZone.current
    @State private var openAtLogin = LoginItem.isOn
    @FocusState private var searchFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    private let locale = Locale.autoupdatingCurrent

    var body: some View {
        Form {
            Section("Cities") {
                ownRow
                ForEach(Array(store.settings.cities.enumerated()), id: \.element) { index, city in
                    cityRow(city, index: index)
                }
                .onMove { store.move(from: $0, to: $1) }
                if adding { addSlot } else {
                    Button { startAdding() } label: { Label("Add city", systemImage: "plus") }
                        .buttonStyle(.borderless)
                }
            }
            Section("Appearance") { themeTiles }
            Section("General") {
                Picker("Time format", selection: Binding(get: { store.settings.hourCycle }, set: { store.setHourCycle($0) })) {
                    ForEach(HourCycle.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                Toggle("Open at Login", isOn: Binding(get: { openAtLogin },
                                                      set: { LoginItem.set($0); openAtLogin = LoginItem.isOn }))
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 420, minHeight: 480)
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in
            userZone = TimeZone.current
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            openAtLogin = LoginItem.isOn  // it may have changed in System Settings
        }
    }

    // MARK: Cities

    private var own: (name: String, flag: String) {
        if case .you(let name, let flag, _) = makeRows(saved: [], userZone: userZone, directory: directory)[0] { return (name, flag) }
        return (userZone.identifier, "🌐")
    }

    private var ownRow: some View {
        HStack(spacing: 10) {
            Text(own.flag).font(.title2)
            VStack(alignment: .leading, spacing: 1) {
                Text(own.name).fontWeight(.semibold)
                Text("Your Mac's time zone · \(labeller.label(for: userZone, at: Date(), displayLocale: locale))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "lock.fill").foregroundStyle(.tertiary).help("Always shown first; follows your Mac")
        }
    }

    private func cityRow(_ city: SavedCity, index: Int) -> some View {
        let zone = TimeZone(identifier: city.timeZoneID) ?? .gmt
        let country = city.countryCode.flatMap { locale.localizedString(forRegionCode: $0) }
        let detail = [country, labeller.label(for: zone, at: Date(), displayLocale: locale)].compactMap { $0 }.joined(separator: " · ")
        return HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal").foregroundStyle(.tertiary).help("Drag to reorder")
            Text(flagEmoji(countryCode: city.countryCode)).font(.title2)
            VStack(alignment: .leading, spacing: 1) {
                Text(city.name).fontWeight(.semibold)
                Text(detail).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Button { store.remove(at: [index]) } label: {
                Image(systemName: "minus.circle.fill").foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Remove \(city.name)")
        }
        .contextMenu {
            Button("Move Up") { store.move(from: [index], to: index - 1) }.disabled(index == 0)
            Button("Move Down") { store.move(from: [index], to: index + 2) }.disabled(index == store.settings.cities.count - 1)
            Divider()
            Button("Remove \(city.name)") { store.remove(at: [index]) }
        }
    }

    private var addSlot: some View {
        let text = query.trimmingCharacters(in: .whitespaces)
        let results = text.isEmpty ? [] : search().search(text, at: Date())
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("City, state, country or time zone", text: $query)
                    .textFieldStyle(.plain)
                    .focused($searchFocused)
                    .onSubmit { if let first = results.first(where: { !store.contains($0.saved) }) { pick(first) } }
                    .onExitCommand { stopAdding() }
                Button("Cancel") { stopAdding() }.buttonStyle(.borderless)
            }
            ForEach(results) { suggestion in suggestionRow(suggestion) }
            if !text.isEmpty && results.isEmpty {
                Text("No place called '\(text)'. Try a city, state or country.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func suggestionRow(_ suggestion: PlaceSuggestion) -> some View {
        let added = store.contains(suggestion.saved)
        let zone = TimeZone(identifier: suggestion.timeZoneID) ?? .gmt
        let parts = timeParts(Date(), in: zone, locale: locale, hourCycle: store.settings.hourCycle)
        return Button { pick(suggestion) } label: {
            HStack(spacing: 10) {
                Text(flagEmoji(countryCode: suggestion.countryCode)).font(.title3)
                VStack(alignment: .leading, spacing: 1) {
                    Text(suggestion.name).fontWeight(.medium)
                    Text(suggestion.detail).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer()
                Text(added ? "added" : [parts.time, parts.period].compactMap { $0 }.joined(separator: " "))
                    .font(.callout).monospacedDigit().foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(added)
        .opacity(added ? 0.5 : 1)
    }

    private func startAdding() {
        query = ""
        adding = true
        DispatchQueue.main.async { searchFocused = true }
    }

    private func stopAdding() {
        adding = false
        query = ""
    }

    private func pick(_ suggestion: PlaceSuggestion) {
        store.add(suggestion.saved)
        stopAdding()
    }

    // MARK: Appearance

    private var themeTiles: some View {
        let rows = makeRows(saved: store.settings.cities, userZone: userZone, directory: directory)
        let scale: CGFloat = 0.52
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(Theme.allCases, id: \.self) { theme in
                let selected = store.settings.theme == theme
                VStack(spacing: 6) {
                    ClockWidgetView(rows: rows, date: Date(), userZone: userZone, size: .medium, monochrome: false,
                                    locale: locale, hourCycle: store.settings.hourCycle, theme: theme)
                        .padding(9)
                        .frame(width: 344, height: 164)
                        .background(widgetBackground(theme: theme, colorScheme: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .scaleEffect(scale)
                        .frame(width: 344 * scale, height: 164 * scale)
                        .overlay(RoundedRectangle(cornerRadius: 28 * scale + 3, style: .continuous)
                            .inset(by: -3)
                            .stroke(selected ? Color.accentColor : .clear, lineWidth: 2.5))
                    Text(theme.title).font(.callout).fontWeight(selected ? .semibold : .regular)
                }
                .contentShape(Rectangle())
                .onTapGesture { store.setTheme(theme) }
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(.vertical, 6)
    }
}
