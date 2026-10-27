// Renders the widget views to PNG for visual checks without a desktop.
//     swift run WorldClockPreview Resources/cities.tsv docs/previews
import AppKit
import SwiftUI
import WorldClockCore
import WorldClockViews

let args = CommandLine.arguments
guard args.count == 3 else {
    FileHandle.standardError.write(Data("usage: WorldClockPreview <cities.tsv> <outdir>\n".utf8))
    exit(2)
}
let directory = try CityDirectory.load(contentsOf: URL(fileURLWithPath: args[1]))
let outDir = URL(fileURLWithPath: args[2])
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let date = ISO8601DateFormatter().date(from: "2026-10-27T06:10:00Z")!  // 2:10 PM Manila
let userZone = TimeZone(identifier: "Asia/Manila")!
let locale = Locale(identifier: "en_US")

/// Preview places, as Settings would save them.
let places: [String: (String, String)] = [
    "Denver": ("US", "America/Denver"), "London": ("GB", "Europe/London"), "Sydney": ("AU", "Australia/Sydney"),
    "Cairns": ("AU", "Australia/Brisbane"), "Tokyo": ("JP", "Asia/Tokyo"), "Dubai": ("AE", "Asia/Dubai"),
    "Honolulu": ("US", "Pacific/Honolulu"), "New York": ("US", "America/New_York"), "Kathmandu": ("NP", "Asia/Kathmandu"),
    "Paris": ("FR", "Europe/Paris"), "Auckland": ("NZ", "Pacific/Auckland"), "Cebu City": ("PH", "Asia/Manila"),
    "San Francisco": ("US", "America/Los_Angeles"),
]
func saved(_ names: String) -> [SavedCity] {
    names.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }.map {
        SavedCity(name: $0, countryCode: places[$0]!.0, timeZoneID: places[$0]!.1)
    }
}

struct Scenario {
    let name: String
    let size: WidgetSize
    let cities: String
    var monochrome = false
    var theme = Theme.dayNight
    var dark = false
}

let usual = "Denver, London, Sydney"
let eight = "Denver, London, Sydney, Tokyo, Dubai, New York, Kathmandu"
let scenarios: [Scenario] = [
    Scenario(name: "medium-usual", size: .medium, cities: usual),
    Scenario(name: "medium-two", size: .medium, cities: "Denver, London"),
    Scenario(name: "medium-overflow", size: .medium, cities: "Denver, London, Sydney, Tokyo, Dubai, Honolulu"),
    Scenario(name: "large-eight", size: .large, cities: eight),
    Scenario(name: "large-overflow", size: .large, cities: "Denver, London, Sydney, Tokyo, Dubai, New York, Kathmandu, Paris, Auckland, Honolulu, Cebu City, San Francisco"),
    Scenario(name: "medium-empty", size: .medium, cities: ""),
    Scenario(name: "medium-usual-mono", size: .medium, cities: usual, monochrome: true),
    Scenario(name: "large-eight-mono", size: .large, cities: eight, monochrome: true),
    Scenario(name: "clocks-medium", size: .medium, cities: usual, theme: .clocks),
    Scenario(name: "clocks-medium-overflow", size: .medium, cities: "Denver, London, Sydney, Tokyo, Dubai", theme: .clocks),
    Scenario(name: "clocks-large", size: .large, cities: eight, theme: .clocks),
    Scenario(name: "clocks-medium-mono", size: .medium, cities: usual, monochrome: true, theme: .clocks),
    Scenario(name: "clocks-medium-empty", size: .medium, cities: "", theme: .clocks),
] + [Theme.list, .spotlight].flatMap { theme in [
    Scenario(name: "\(theme.rawValue)-medium", size: .medium, cities: usual, theme: theme),
    Scenario(name: "\(theme.rawValue)-medium-dark", size: .medium, cities: usual, theme: theme, dark: true),
    Scenario(name: "\(theme.rawValue)-large", size: .large, cities: eight + ", Paris, Auckland, Honolulu", theme: theme),
    Scenario(name: "\(theme.rawValue)-medium-empty", size: .medium, cities: "", theme: theme),
] }

@MainActor func render(_ s: Scenario) throws {
    let (width, height): (CGFloat, CGFloat) = s.size == .medium ? (344, 164) : (344, 354)
    let rows = makeRows(saved: saved(s.cities), userZone: userZone, directory: directory)
    let scheme: ColorScheme = s.dark ? .dark : .light
    let view = ClockWidgetView(rows: rows, date: date, userZone: userZone, size: s.size, monochrome: s.monochrome, locale: locale,
                               hourCycle: .system, theme: s.theme)
        .padding(9)
        .frame(width: width, height: height)
        // Monochrome stands in for the system's vibrant material with a neutral grey card.
        .background(s.monochrome ? Color(white: 0.28) : widgetBackground(theme: s.theme, colorScheme: scheme))
        .clipShape(RoundedRectangle(cornerRadius: 27.88, style: .continuous))
        .environment(\.colorScheme, scheme)
        .padding(16)
        .background(LinearGradient(colors: [Color(red: 0.49, green: 0.61, blue: 0.79), Color(red: 0.11, green: 0.31, blue: 0.61)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
    try write(view, s.name)
}

/// The menu bar panel, on a plain desktop-coloured backdrop.
@MainActor func renderPanel(name: String, cities: String, theme: Theme = .dayNight, dark: Bool = false) throws {
    let rows = makeRows(saved: saved(cities), userZone: userZone, directory: directory)
    let view = MenuPanelView(rows: rows, userZone: userZone, locale: locale, hourCycle: .system, theme: theme,
                             openAtLogin: .constant(true), onSettings: {}, onHowTo: {}, onQuit: {}, fixedDate: date)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .environment(\.colorScheme, dark ? .dark : .light)
        .padding(16)
        .background(Color(red: 0.11, green: 0.31, blue: 0.61))
    try write(view, name)
}

@MainActor func write(_ view: some View, _ name: String) throws {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 2
    guard let cg = renderer.cgImage else { throw CocoaError(.fileWriteUnknown) }
    try NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])!
        .write(to: outDir.appendingPathComponent("\(name).png"))
    print("wrote \(name).png")
}

MainActor.assumeIsolated {
    for s in scenarios { try! render(s) }
    try! renderPanel(name: "panel-usual", cities: "Denver, London, Cairns")
    try! renderPanel(name: "panel-long", cities: "Denver, London, Sydney, Tokyo, Dubai, New York, Kathmandu, Paris, Auckland, Honolulu")
    try! renderPanel(name: "panel-list", cities: "Denver, London, Cairns", theme: .list)
    try! renderPanel(name: "panel-list-dark", cities: "Denver, London, Cairns", theme: .list, dark: true)
    try! renderPanel(name: "panel-spotlight", cities: "Denver, London, Cairns", theme: .spotlight)
    try! renderPanel(name: "panel-clocks", cities: "Denver, London, Cairns, Tokyo", theme: .clocks)
}
