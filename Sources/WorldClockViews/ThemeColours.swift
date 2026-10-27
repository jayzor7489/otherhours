import SwiftUI
import WorldClockCore

/// The card behind each theme. Day & Night (mockup B, navy) and Clocks (mockup C, graphite) are
/// always dark; List and Spotlight are white in light mode (mockups A, D) and graphite in dark mode.
public func widgetBackground(theme: Theme, colorScheme: ColorScheme) -> Color {
    switch theme {
    case .dayNight: return widgetBackground
    case .clocks: return graphite
    case .list, .spotlight: return colorScheme == .dark ? graphite : .white
    }
}

private let graphite = Color(red: 0x1C / 255, green: 0x1C / 255, blue: 0x1E / 255)

/// Themes that follow the Mac's light or dark appearance.
public extension Theme {
    var followsAppearance: Bool { self == .list || self == .spotlight }
}

/// The parts every theme draws for a row.
struct Place {
    let name: String
    let flag: String
    let zone: TimeZone
    let isYou: Bool

    init(_ row: ClockRow) {
        switch row {
        case .you(let name, let flag, let zone): self.init(name: name, flag: flag, zone: zone, isYou: true)
        case .city(let name, let flag, let zone): self.init(name: name, flag: flag, zone: zone, isYou: false)
        }
    }

    init(name: String, flag: String, zone: TimeZone, isYou: Bool) {
        self.name = name
        self.flag = flag
        self.zone = zone
        self.isYou = isYou
    }
}

/// Own row: "Tue, Oct 27". A city: "Today · −14 hrs".
func subLine(for place: Place, date: Date, userZone: TimeZone, locale: Locale) -> String {
    if place.isYou { return dateLine(date, zone: place.zone, locale: locale, template: "EEEMMMd") }
    let day = dayRelation(at: date, cityZone: place.zone, userZone: userZone).label
    return "\(day) · \(offsetLabel(at: date, cityZone: place.zone, userZone: userZone))"
}

func dateLine(_ date: Date, zone: TimeZone, locale: Locale, template: String) -> String {
    let formatter = DateFormatter()
    formatter.locale = locale
    formatter.timeZone = zone
    formatter.setLocalizedDateFormatFromTemplate(template)
    return formatter.string(from: date)
}

/// "−14 hrs" → "−14", "Same time" → "0" (Spotlight's narrow offset column).
func shortOffset(at date: Date, cityZone: TimeZone, userZone: TimeZone) -> String {
    let label = offsetLabel(at: date, cityZone: cityZone, userZone: userZone)
    return label == "Same time" ? "0" : label.replacingOccurrences(of: " hrs", with: "")
}
