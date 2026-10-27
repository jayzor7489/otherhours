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

let scenarios: [(name: String, size: WidgetSize, cities: String, monochrome: Bool)] = [
    ("medium-usual", .medium, "Denver, London, Sydney", false),
    ("medium-two", .medium, "Denver, London", false),
    ("medium-overflow", .medium, "Denver, London, Sydney, Tokyo, Dubai, Honolulu", false),
    ("large-eight", .large, "Denver, London, Sydney, Tokyo, Dubai, New York, Kathmandu", false),
    ("large-overflow", .large, "Denver, London, Sydney, Tokyo, Dubai, New York, Kathmandu, Paris, Auckland, Honolulu, Cebu, San Francisco", false),
    ("medium-unknown", .medium, "Denver, Qwertyville", false),
    ("medium-empty", .medium, "", false),
    ("medium-usual-mono", .medium, "Denver, London, Sydney", true),
    ("large-eight-mono", .large, "Denver, London, Sydney, Tokyo, Dubai, New York, Kathmandu", true),
]

@MainActor func render(_ s: (name: String, size: WidgetSize, cities: String, monochrome: Bool)) throws {
    let (width, height): (CGFloat, CGFloat) = s.size == .medium ? (344, 164) : (344, 354)
    let rows = makeRows(typed: s.cities, userZone: userZone, directory: directory)
    let view = ClockWidgetView(rows: rows, date: date, userZone: userZone, size: s.size, monochrome: s.monochrome, locale: locale)
        .padding(9)
        .frame(width: width, height: height)
        // Monochrome stands in for the system's vibrant material with a neutral grey card.
        .background(s.monochrome ? Color(white: 0.28) : widgetBackground)
        .clipShape(RoundedRectangle(cornerRadius: 27.88, style: .continuous))
        .padding(16)
        .background(LinearGradient(colors: [Color(red: 0.49, green: 0.61, blue: 0.79), Color(red: 0.11, green: 0.31, blue: 0.61)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
    let renderer = ImageRenderer(content: view)
    renderer.scale = 2
    guard let cg = renderer.cgImage else { throw CocoaError(.fileWriteUnknown) }
    let png = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])!
    try png.write(to: outDir.appendingPathComponent("\(s.name).png"))
    print("wrote \(s.name).png")
}

/// The menu bar panel, on a plain desktop-coloured backdrop.
@MainActor func renderPanel(name: String, cities: String, note: String) throws {
    let rows = makeRows(typed: cities, userZone: userZone, directory: directory)
    let view = MenuPanelView(rows: rows, userZone: userZone, locale: locale, note: note, openAtLogin: .constant(true),
                             onHowTo: {}, onQuit: {}, fixedDate: date)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(16)
        .background(Color(red: 0.11, green: 0.31, blue: 0.61))
    let renderer = ImageRenderer(content: view)
    renderer.scale = 2
    guard let cg = renderer.cgImage else { throw CocoaError(.fileWriteUnknown) }
    try NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])!
        .write(to: outDir.appendingPathComponent("\(name).png"))
    print("wrote \(name).png")
}

MainActor.assumeIsolated {
    for s in scenarios { try! render(s) }
    try! renderPanel(name: "panel-usual", cities: "Denver, London, Cairns", note: "Edit cities: right-click your widget › Edit")
    try! renderPanel(name: "panel-long", cities: "Denver, London, Sydney, Tokyo, Dubai, New York, Kathmandu, Paris, Auckland, Honolulu",
                     note: "Edit cities: right-click your widget › Edit")
}
