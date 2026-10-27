import Foundation

public enum DayRelation: Equatable {
    case yesterday, today, tomorrow

    public var label: String {
        switch self {
        case .yesterday: "Yesterday"
        case .today: "Today"
        case .tomorrow: "Tomorrow"
        }
    }
}

/// Is it the same calendar day in the city as for the user?
public func dayRelation(at date: Date, cityZone: TimeZone, userZone: TimeZone) -> DayRelation {
    func dayNumber(in zone: TimeZone) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return c.year! * 10_000 + c.month! * 100 + c.day!
    }
    let city = dayNumber(in: cityZone), user = dayNumber(in: userZone)
    return city == user ? .today : (city < user ? .yesterday : .tomorrow)
}

/// "−14 hrs", "+3 hrs", "−2:30 hrs", or "Same time". Uses the offsets in force at `date`, so DST is handled.
public func offsetLabel(at date: Date, cityZone: TimeZone, userZone: TimeZone) -> String {
    let seconds = cityZone.secondsFromGMT(for: date) - userZone.secondsFromGMT(for: date)
    guard seconds != 0 else { return "Same time" }
    let sign = seconds < 0 ? "\u{2212}" : "+"
    let minutes = abs(seconds) / 60
    let (hours, rest) = (minutes / 60, minutes % 60)
    return rest == 0 ? "\(sign)\(hours) hrs" : "\(sign)\(hours):\(String(format: "%02d", rest)) hrs"
}

/// "12:10" + "AM" on a 12-hour Mac, "17:10" + nil on a 24-hour one.
public func timeParts(_ date: Date, in zone: TimeZone, locale: Locale) -> (time: String, period: String?) {
    let skeleton = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: locale) ?? "h a"
    let twelveHour = skeleton.contains("a")
    let formatter = DateFormatter()
    formatter.locale = locale
    formatter.timeZone = zone
    formatter.dateFormat = twelveHour ? "h:mm" : "HH:mm"
    let time = formatter.string(from: date)
    guard twelveHour else { return (time, nil) }
    formatter.dateFormat = "a"
    return (time, formatter.string(from: date))
}

/// Day/night by the city's local hour: night 21–4, dawn 5–7, day 8–16, dusk 17–20.
public enum SkyBand: Equatable, CaseIterable {
    case night, dawn, day, dusk

    public static func at(_ date: Date, in zone: TimeZone) -> SkyBand {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        switch calendar.component(.hour, from: date) {
        case 5..<8: return .dawn
        case 8..<17: return .day
        case 17..<21: return .dusk
        default: return .night
        }
    }
}
