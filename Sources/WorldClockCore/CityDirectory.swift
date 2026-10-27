import Foundation

/// One row of Resources/cities.tsv (GeoNames cities15000).
public struct CityRecord {
    public let name: String
    public let asciiName: String
    public let countryCode: String
    public let timeZoneID: String
    public let population: Int

    public init(name: String, asciiName: String, countryCode: String, timeZoneID: String, population: Int) {
        self.name = name
        self.asciiName = asciiName
        self.countryCode = countryCode
        self.timeZoneID = timeZoneID
        self.population = population
    }
}

public struct ResolvedCity: Equatable {
    public let displayName: String
    public let countryCode: String?
    public let timeZone: TimeZone
}

/// Turns typed names into cities: aliases, then the GeoNames list, then time zone names.
public final class CityDirectory {
    static let aliases: [String: String] = [
        "nyc": "New York City", "la": "Los Angeles", "sf": "San Francisco",
        "kl": "Kuala Lumpur", "hcmc": "Ho Chi Minh City", "dc": "Washington",
        "calcutta": "Kolkata",
    ]

    /// A namesake smaller than this never hides a place that has its own time zone.
    static let majorCityPopulation = 1_000_000

    private let records: [CityRecord]
    private var byKey: [String: [Int]] = [:]
    private var countryByZone: [String: (code: String, population: Int)] = [:]

    public init(records: [CityRecord]) {
        self.records = records
        for (index, record) in records.enumerated() {
            for key in Set([record.name, record.asciiName].flatMap(Self.keys(for:))) {
                byKey[key, default: []].append(index)
            }
            if record.population > (countryByZone[record.timeZoneID]?.population ?? -1) {
                countryByZone[record.timeZoneID] = (record.countryCode, record.population)
            }
        }
    }

    public static func load(contentsOf url: URL) throws -> CityDirectory {
        let text = try String(contentsOf: url, encoding: .utf8)
        let records: [CityRecord] = text.split(separator: "\n").compactMap { line in
            let f = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard f.count >= 5 else { return nil }
            return CityRecord(name: String(f[0]), asciiName: String(f[1]), countryCode: String(f[2]),
                              timeZoneID: String(f[3]), population: Int(f[4]) ?? 0)
        }
        return CityDirectory(records: records)
    }

    public func resolve(_ query: CityQuery) -> ResolvedCity? {
        let key = Self.normalize(query.name)
        if let target = Self.aliases[key] {
            return resolve(CityQuery(name: target, countryCode: query.countryCode))
        }
        let best = (byKey[key] ?? [])
            .map { records[$0] }
            .filter { query.countryCode == nil || $0.countryCode == query.countryCode }
            .max { $0.population < $1.population }
        let zonePlace = zoneFallback(key: key, countryCode: query.countryCode)
        if let best, let zone = TimeZone(identifier: best.timeZoneID) {
            // "Puerto Rico" is a zone and also a small town in Colombia: the zone wins.
            if let zonePlace, zonePlace.timeZone.identifier != best.timeZoneID,
               best.population < Self.majorCityPopulation {
                return zonePlace
            }
            return ResolvedCity(displayName: best.name, countryCode: best.countryCode, timeZone: zone)
        }
        return zonePlace
    }

    public func countryCode(forTimeZoneID id: String) -> String? {
        countryByZone[id]?.code
    }

    /// "Denver" → America/Denver, for anything the city list lacks.
    private func zoneFallback(key: String, countryCode: String?) -> ResolvedCity? {
        for id in TimeZone.knownTimeZoneIdentifiers {
            let place = (id.split(separator: "/").last.map(String.init) ?? id).replacingOccurrences(of: "_", with: " ")
            guard Self.normalize(place) == key, let zone = TimeZone(identifier: id) else { continue }
            let country = self.countryCode(forTimeZoneID: id)
            if let countryCode, let country, country != countryCode { continue }
            return ResolvedCity(displayName: place, countryCode: country, timeZone: zone)
        }
        return nil
    }

    static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespaces)
    }

    /// The name itself, plus the name without a trailing " City" ("Cebu City" is also "Cebu").
    static func keys(for name: String) -> [String] {
        let key = normalize(name)
        guard key.hasSuffix(" city"), key.count > 5 else { return [key] }
        return [key, String(key.dropLast(5))]
    }
}

/// Regional-indicator flag for a two-letter country code; 🌐 when there is none.
public func flagEmoji(countryCode: String?) -> String {
    guard let code = countryCode?.uppercased(), code.count == 2,
          code.unicodeScalars.allSatisfy({ ("A"..."Z").contains($0) }) else { return "🌐" }
    return String(String.UnicodeScalarView(code.unicodeScalars.compactMap { UnicodeScalar(127397 + $0.value) }))
}
