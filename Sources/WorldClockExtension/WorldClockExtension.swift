// The WidgetKit extension. Linked with -e _NSExtensionMain (see Package.swift); without it
// the process starts at Swift main, never handshakes with chronod, and the gallery shows nothing.
// Display only: the cities, theme and time format come from the menu bar app's Settings,
// read from the app's preferences through the shared-preference entitlement.
import os
import SwiftUI
import WidgetKit
import WorldClockCore
import WorldClockViews

private let log = Logger(subsystem: "com.jasonaldemita.otherhours", category: "widget")

struct ClockEntry: TimelineEntry {
    let date: Date
    let rows: [ClockRow]
    let userZone: TimeZone
    let settings: ClockSettings
}

struct ClockProvider: TimelineProvider {
    static let directory: CityDirectory = {
        guard let url = Bundle.main.url(forResource: "cities", withExtension: "tsv"),
              let directory = try? CityDirectory.load(contentsOf: url) else {
            return CityDirectory(records: [])  // own time still shows, with a 🌐 flag
        }
        return directory
    }()

    func placeholder(in context: Context) -> ClockEntry {
        entry(at: Date(), settings: ClockSettings(cities: [], theme: .dayNight, hourCycle: .system))
    }

    func getSnapshot(in context: Context, completion: @escaping (ClockEntry) -> Void) {
        completion(entry(at: Date(), settings: Self.currentSettings()))
    }

    /// One entry per minute for an hour, starting at the current minute (see minuteTimeline).
    func getTimeline(in context: Context, completion: @escaping (Timeline<ClockEntry>) -> Void) {
        let settings = Self.currentSettings()
        log.info("timeline: \(settings.cities.count, privacy: .public) cities")
        let dates = minuteTimeline(from: Date(), count: 60)
        let template = entry(at: dates[0], settings: settings)
        let entries = dates.map { ClockEntry(date: $0, rows: template.rows, userZone: template.userZone, settings: settings) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    /// Read fresh every time: the app saves, then asks WidgetKit to reload.
    static func currentSettings() -> ClockSettings {
        UserDefaults(suiteName: "com.jasonaldemita.otherhours").map(ClockSettings.load(from:))
            ?? ClockSettings(cities: [], theme: .dayNight, hourCycle: .system)
    }

    private func entry(at date: Date, settings: ClockSettings) -> ClockEntry {
        NSTimeZone.resetSystemTimeZone()  // pick up a Mac time zone change at each reload
        let userZone = TimeZone.current
        return ClockEntry(date: date, rows: makeRows(saved: settings.cities, userZone: userZone, directory: Self.directory),
                          userZone: userZone, settings: settings)
    }
}

struct WorldClockEntryView: View {
    let entry: ClockEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ClockWidgetView(rows: entry.rows, date: entry.date, userZone: entry.userZone,
                        size: family == .systemLarge ? .large : .medium,
                        monochrome: renderingMode != .fullColor,
                        locale: .autoupdatingCurrent, hourCycle: entry.settings.hourCycle, theme: entry.settings.theme)
            .padding(9)
            // Handed to the system rather than drawn as content, so tinted/clear styles can replace it.
            .containerBackground(widgetBackground(theme: entry.settings.theme, colorScheme: colorScheme), for: .widget)
    }
}

struct OtherhoursWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Otherhours", provider: ClockProvider()) { entry in
            WorldClockEntryView(entry: entry)
        }
        .configurationDisplayName("Otherhours")
        .description("Any number of cities, coloured by day and night.")
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

@main
struct WorldClockBundle: WidgetBundle {
    var body: some Widget {
        OtherhoursWidget()
    }
}
