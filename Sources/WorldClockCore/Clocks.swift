import Foundation

/// Two zones are one clock when they agree now and at every change over the next 12 months:
/// same UTC offset now, same transition instants, same offset after each. America/Detroit and
/// America/New_York are one clock; America/Phoenix (no daylight saving) is not Denver's.
public func clockKey(for zone: TimeZone, from date: Date) -> String {
    var parts = ["\(zone.secondsFromGMT(for: date))"]
    let end = date.addingTimeInterval(366 * 24 * 3600)
    var cursor = date
    while let next = zone.nextDaylightSavingTimeTransition(after: cursor), next < end {
        parts.append("\(Int(next.timeIntervalSince1970)):\(zone.secondsFromGMT(for: next))")
        cursor = next
    }
    return parts.joined(separator: "|")
}

/// Zone identifiers that keep the same clock. The representative is the identifier of the most
/// populous city in the group (US Eastern → America/New_York) and is what a pick stores.
public struct ClockGroup: Equatable {
    public let representativeID: String
    public let memberIDs: [String]
    public let population: Int
}

/// Groups the records' zones into clocks, largest first. `key` lets a caller reuse computed keys.
public func clockGroups(for records: [CityRecord], from date: Date,
                        key: (TimeZone) -> String = { _ in "" }) -> [ClockGroup] {
    var biggest: [String: Int] = [:]  // zone → its most populous city
    for record in records where TimeZone(identifier: record.timeZoneID) != nil {
        biggest[record.timeZoneID] = max(biggest[record.timeZoneID] ?? 0, record.population)
    }
    var byKey: [String: [String]] = [:]
    for id in biggest.keys {
        let zone = TimeZone(identifier: id)!
        let cached = key(zone)
        byKey[cached.isEmpty ? clockKey(for: zone, from: date) : cached, default: []].append(id)
    }
    return byKey.values.map { ids in
        let representative = ids.max { (biggest[$0]!, $1) < (biggest[$1]!, $0) }!  // ties: alphabetical
        return ClockGroup(representativeID: representative, memberIDs: ids.sorted(), population: biggest[representative]!)
    }
    .sorted { ($0.population, $1.representativeID) > ($1.population, $0.representativeID) }
}

/// "Mountain Time (MDT)": the zone's generic name in the Mac's language, then an abbreviation
/// that doesn't depend on the Mac's region (see AbbreviationRecord).
public final class ZoneLabeller {
    private let abbreviations: [AbbreviationRecord]
    private let directory: CityDirectory

    public init(abbreviations: [AbbreviationRecord], directory: CityDirectory) {
        self.abbreviations = abbreviations
        self.directory = directory
    }

    public func label(for zone: TimeZone, at date: Date, displayLocale: Locale) -> String {
        let generic = zone.localizedName(for: .generic, locale: displayLocale) ?? zone.identifier
        return "\(generic) (\(abbreviation(for: zone, at: date)))"
    }

    /// Table row for this zone → table row for a same-country zone keeping the same clock →
    /// macOS's short name in the zone's own country's English → whatever macOS gives ("GMT+11").
    public func abbreviation(for zone: TimeZone, at date: Date) -> String {
        let daylight = zone.isDaylightSavingTime(for: date)
        let rows = abbreviations.filter { $0.isDaylight == daylight }
        if let row = rows.first(where: { $0.timeZoneID == zone.identifier }) { return row.abbreviation }
        let country = directory.countryCode(forTimeZoneID: zone.identifier)
        if let country {
            let key = clockKey(for: zone, from: date)
            if let row = rows.first(where: { row in
                directory.countryCode(forTimeZoneID: row.timeZoneID) == country
                    && TimeZone(identifier: row.timeZoneID).map { clockKey(for: $0, from: date) } == key
            }) { return row.abbreviation }
            if let name = zone.localizedName(for: daylight ? .shortDaylightSaving : .shortStandard,
                                             locale: Locale(identifier: "en_\(country)")),
               !name.hasPrefix("GMT") { return name }
        }
        return zone.abbreviation(for: date) ?? "GMT"
    }
}
