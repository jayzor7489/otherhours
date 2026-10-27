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

/// The GeoNames city list: names, countries and time zones.
public final class CityDirectory {
    public let records: [CityRecord]
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

    public func countryCode(forTimeZoneID id: String) -> String? {
        countryByZone[id]?.code
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
