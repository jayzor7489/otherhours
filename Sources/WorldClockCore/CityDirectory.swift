import Foundation

/// One row of Resources/cities.tsv (GeoNames cities15000). `admin1` is the GeoNames first-level
/// region code (a US state, an Australian state), "" when the row has none.
public struct CityRecord {
    public let name: String
    public let asciiName: String
    public let countryCode: String
    public let timeZoneID: String
    public let population: Int
    public let admin1: String

    public init(name: String, asciiName: String, countryCode: String, timeZoneID: String, population: Int, admin1: String = "") {
        self.name = name
        self.asciiName = asciiName
        self.countryCode = countryCode
        self.timeZoneID = timeZoneID
        self.population = population
        self.admin1 = admin1
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
                              timeZoneID: String(f[3]), population: Int(f[4]) ?? 0, admin1: f.count > 5 ? String(f[5]) : "")
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

/// One row of Resources/regions.tsv (GeoNames admin1CodesASCII): "US.CO", "Colorado", "Colorado".
public struct RegionRecord: Equatable {
    public let countryCode: String
    public let code: String
    public let name: String
    public let asciiName: String

    public init(countryCode: String, code: String, name: String, asciiName: String) {
        self.countryCode = countryCode
        self.code = code
        self.name = name
        self.asciiName = asciiName
    }
}

public func loadRegions(contentsOf url: URL) throws -> [RegionRecord] {
    try tsvRows(url).compactMap { f in
        let key = f[0].split(separator: ".", maxSplits: 1)
        guard f.count >= 3, key.count == 2 else { return nil }
        return RegionRecord(countryCode: String(key[0]), code: String(key[1]), name: f[1], asciiName: f[2])
    }
}

/// One row of Resources/abbreviations.tsv, a hand-made table: macOS's own abbreviations depend
/// on the Mac's locale (Sydney is "GMT+11" in en_PH) and miss common ones (AEST, IST outside India).
public struct AbbreviationRecord: Equatable {
    public let abbreviation: String
    public let isDaylight: Bool
    public let timeZoneID: String

    public init(abbreviation: String, isDaylight: Bool, timeZoneID: String) {
        self.abbreviation = abbreviation
        self.isDaylight = isDaylight
        self.timeZoneID = timeZoneID
    }
}

/// "MDT \t d \t America/Denver"; `#` lines and blank lines are skipped.
public func loadAbbreviations(contentsOf url: URL) throws -> [AbbreviationRecord] {
    try tsvRows(url).compactMap { f in
        guard f.count >= 3, f[1] == "s" || f[1] == "d" else { return nil }
        return AbbreviationRecord(abbreviation: f[0], isDaylight: f[1] == "d", timeZoneID: f[2])
    }
}

private func tsvRows(_ url: URL) throws -> [[String]] {
    try String(contentsOf: url, encoding: .utf8).split(separator: "\n").compactMap { line in
        let text = line.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !text.hasPrefix("#") else { return nil }
        return line.split(separator: "\t", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
    }
}
