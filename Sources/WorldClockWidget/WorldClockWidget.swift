// The WidgetKit extension. Linked with -e _NSExtensionMain (see Package.swift); without it
// the process starts at Swift main, never handshakes with chronod, and the gallery shows nothing.
import AppIntents
import SwiftUI
import WidgetKit
import WorldClockCore
import WorldClockViews

/// The only setting: a typed list. A String is the one parameter type that decodes without
/// Xcode's metadata processor (dropdowns arrive as nil). Keep in sync with scripts/make_metadata.py.
struct SelectCitiesIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Choose Cities"
    static let description = IntentDescription("Type cities separated by commas.")

    @Parameter(title: "Cities", default: "Denver, London, Sydney")
    var cities: String
}

struct ClockEntry: TimelineEntry {
    let date: Date
    let rows: [ClockRow]
    let userZone: TimeZone
}

struct ClockProvider: AppIntentTimelineProvider {
    static let directory: CityDirectory = {
        guard let url = Bundle.main.url(forResource: "cities", withExtension: "tsv"),
              let directory = try? CityDirectory.load(contentsOf: url) else {
            return CityDirectory(records: [])  // time zone names still resolve
        }
        return directory
    }()

    func placeholder(in context: Context) -> ClockEntry {
        entry(at: Date(), typed: "Denver, London, Sydney")
    }

    func snapshot(for configuration: SelectCitiesIntent, in context: Context) async -> ClockEntry {
        entry(at: Date(), typed: configuration.cities)
    }

    /// One entry per minute for an hour, starting at the current minute; a timeline that
    /// starts in the future draws an empty placeholder.
    func timeline(for configuration: SelectCitiesIntent, in context: Context) async -> Timeline<ClockEntry> {
        let now = Date()
        let start = Calendar.current.date(bySetting: .second, value: 0, of: now) ?? now
        let template = entry(at: start, typed: configuration.cities)
        let entries = (0..<60).compactMap { minute in
            Calendar.current.date(byAdding: .minute, value: minute, to: start)
                .map { ClockEntry(date: $0, rows: template.rows, userZone: template.userZone) }
        }
        return Timeline(entries: entries, policy: .atEnd)
    }

    private func entry(at date: Date, typed: String) -> ClockEntry {
        NSTimeZone.resetSystemTimeZone()  // pick up a Mac time zone change at each reload
        let userZone = TimeZone.current
        return ClockEntry(date: date, rows: makeRows(typed: typed, userZone: userZone, directory: Self.directory), userZone: userZone)
    }
}

struct WorldClockEntryView: View {
    let entry: ClockEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        ClockWidgetView(rows: entry.rows, date: entry.date, userZone: entry.userZone,
                        size: family == .systemLarge ? .large : .medium,
                        monochrome: renderingMode != .fullColor,
                        locale: .autoupdatingCurrent)
            .padding(9)
            // Handed to the system rather than drawn as content, so tinted/clear styles can replace it.
            .containerBackground(widgetBackground, for: .widget)
    }
}

struct WorldClockWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "WorldClock", intent: SelectCitiesIntent.self, provider: ClockProvider()) { entry in
            WorldClockEntryView(entry: entry)
        }
        .configurationDisplayName("World Clock")
        .description("Any number of cities, coloured by day and night.")
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

@main
struct WorldClockBundle: WidgetBundle {
    var body: some Widget {
        WorldClockWidget()
    }
}
