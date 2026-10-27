import Foundation

public enum ClockRow: Equatable {
    case you(name: String, flag: String, zone: TimeZone)
    case city(name: String, flag: String, zone: TimeZone)
    case unknown(typed: String)
}

/// The user's own row first (from the Mac's zone), then the typed cities in order.
/// A city matching an earlier row's zone and name (including the user's own) is dropped,
/// and so is a repeated unknown name.
public func makeRows(typed: String, userZone: TimeZone, directory: CityDirectory) -> [ClockRow] {
    let youName = (userZone.identifier.split(separator: "/").last.map(String.init) ?? userZone.identifier)
        .replacingOccurrences(of: "_", with: " ")
    var rows: [ClockRow] = [.you(name: youName, flag: flagEmoji(countryCode: directory.countryCode(forTimeZoneID: userZone.identifier)), zone: userZone)]
    var seen: Set<String> = [seenKey(youName, userZone)]

    for query in parseCityList(typed) {
        guard let city = directory.resolve(query) else {
            if seen.insert("?|\(CityDirectory.normalize(query.name))").inserted {
                rows.append(.unknown(typed: query.name))
            }
            continue
        }
        guard seen.insert(seenKey(city.displayName, city.timeZone)).inserted else { continue }
        rows.append(.city(name: city.displayName, flag: flagEmoji(countryCode: city.countryCode), zone: city.timeZone))
    }
    return rows
}

/// The user's own row first (from the Mac's zone), then the saved cities in order. A saved city
/// equal to the own row (same zone and name), or whose zone no longer exists, is skipped.
public func makeRows(saved: [SavedCity], userZone: TimeZone, directory: CityDirectory) -> [ClockRow] {
    let youName = (userZone.identifier.split(separator: "/").last.map(String.init) ?? userZone.identifier)
        .replacingOccurrences(of: "_", with: " ")
    var rows: [ClockRow] = [.you(name: youName, flag: flagEmoji(countryCode: directory.countryCode(forTimeZoneID: userZone.identifier)), zone: userZone)]
    var seen: Set<String> = [seenKey(youName, userZone)]
    for city in saved {
        guard let zone = TimeZone(identifier: city.timeZoneID),
              seen.insert(seenKey(city.name, zone)).inserted else { continue }
        rows.append(.city(name: city.name, flag: flagEmoji(countryCode: city.countryCode), zone: zone))
    }
    return rows
}

private func seenKey(_ name: String, _ zone: TimeZone) -> String {
    "\(zone.identifier)|\(CityDirectory.normalize(name))"
}

public enum WidgetSize { case medium, large }
public enum RowStyle { case full, compact }

public struct RowLayout: Equatable {
    public let style: RowStyle
    public let visibleCount: Int
    public let overflowCount: Int

    public init(style: RowStyle, visibleCount: Int, overflowCount: Int) {
        self.style = style
        self.visibleCount = visibleCount
        self.overflowCount = overflowCount
    }
}

/// Full rows while they fit, then compact rows, then compact rows with a "+N more" last slot.
public func layout(rowCount: Int, size: WidgetSize) -> RowLayout {
    let (fullLimit, compactLimit) = size == .medium ? (3, 5) : (7, 10)
    if rowCount <= fullLimit { return RowLayout(style: .full, visibleCount: rowCount, overflowCount: 0) }
    if rowCount <= compactLimit { return RowLayout(style: .compact, visibleCount: rowCount, overflowCount: 0) }
    let visible = compactLimit - 1
    return RowLayout(style: .compact, visibleCount: visible, overflowCount: rowCount - visible)
}
