import Foundation

/// One line under the search box. Picking it saves `saved`.
public struct PlaceSuggestion: Equatable, Identifiable {
    public let name: String
    public let detail: String
    public let countryCode: String?
    public let timeZoneID: String

    public var id: String { "\(timeZoneID)|\(name)" }
    public var saved: SavedCity { SavedCity(name: name, countryCode: countryCode, timeZoneID: timeZoneID) }
}

/// Finds a clock from whatever the person types: a city ("syd"), a state ("Colorado"), a country
/// ("Japan"), an abbreviation ("PST") or a zone name ("Mountain Time"). Regions, countries and
/// zone names give one suggestion per distinct clock, named after its zone's own city.
public final class PlaceSearch {
    static let aliases: [String: String] = [
        "nyc": "New York City", "la": "Los Angeles", "sf": "San Francisco",
        "kl": "Kuala Lumpur", "hcmc": "Ho Chi Minh City", "dc": "Washington",
        "calcutta": "Kolkata",
    ]
    /// An exact-name city smaller than this ranks after an exact state or country of that name
    /// ("Puerto Rico" the island before the town in Colombia).
    static let majorCityPopulation = 1_000_000

    private enum Kind: Int { case city = 0, region = 10, country = 20, smallExactCity = 25, zone = 30 }

    private struct Candidate {
        let id: String
        let make: () -> PlaceSuggestion
        let exact: Bool
        let kind: Kind
        let subOrder: Int
        let population: Int
    }

    private let directory: CityDirectory
    private let labeller: ZoneLabeller
    private let displayLocale: Locale
    private let cityKeys: [(keys: [String], words: [String])]  // per record, parallel to directory.records
    private let cityOrder: [Int]  // record indexes, most populous first
    private let regions: [(keys: [String], region: RegionRecord, records: [CityRecord])]
    private let countries: [(keys: [String], code: String, records: [CityRecord])]
    private let abbreviations: [String: [String]]  // "PST" → zone ids
    private let zoneNames: [(key: String, records: [CityRecord])]
    private var keyCache: (hour: Int, keys: [String: String]) = (-1, [:])  // clock keys, valid for one hour
    private let cacheLock = NSLock()  // search may run from several threads (tests do)
    private var regionNames: [String: String] = [:]  // "US.CO" → "Colorado"

    public init(directory: CityDirectory, regions: [RegionRecord], abbreviations: [AbbreviationRecord], displayLocale: Locale) {
        self.directory = directory
        self.displayLocale = displayLocale
        labeller = ZoneLabeller(abbreviations: abbreviations, directory: directory)

        cityKeys = directory.records.map { record in
            let keys = Array(Set([record.name, record.asciiName].flatMap(CityDirectory.keys(for:))))
            return (keys, Array(Set(keys.flatMap(Self.words))))
        }

        cityOrder = directory.records.indices.sorted { directory.records[$0].population > directory.records[$1].population }

        var byRegion: [String: [CityRecord]] = [:]
        var byCountry: [String: [CityRecord]] = [:]
        for record in directory.records {
            if !record.admin1.isEmpty { byRegion["\(record.countryCode).\(record.admin1)", default: []].append(record) }
            byCountry[record.countryCode, default: []].append(record)
        }
        self.regions = regions.compactMap { region in
            let key = "\(region.countryCode).\(region.code)"
            guard let records = byRegion[key] else { return nil }
            return (Array(Set([region.name, region.asciiName].map(CityDirectory.normalize))), region, records)
        }
        for region in regions { regionNames["\(region.countryCode).\(region.code)"] = region.name }

        let english = Locale(identifier: "en_US")
        countries = byCountry.map { code, records in
            let names = [displayLocale, english].compactMap { $0.localizedString(forRegionCode: code) }
            return (Array(Set(names.map(CityDirectory.normalize))), code, records)
        }

        var abbr: [String: [String]] = [:]
        for row in abbreviations where !(abbr[row.abbreviation]?.contains(row.timeZoneID) ?? false) {
            abbr[row.abbreviation, default: []].append(row.timeZoneID)
        }
        self.abbreviations = abbr

        var genericByID: [String: String] = [:]
        for id in Set(directory.records.map(\.timeZoneID)) {
            guard let generic = TimeZone(identifier: id)?.localizedName(for: .generic, locale: displayLocale) else { continue }
            genericByID[id] = CityDirectory.normalize(generic)
        }
        var names: [String: [CityRecord]] = [:]
        for record in directory.records {
            if let name = genericByID[record.timeZoneID] { names[name, default: []].append(record) }
        }
        zoneNames = names.map { ($0.key, $0.value) }
    }

    public func search(_ text: String, at date: Date, limit: Int = 8) -> [PlaceSuggestion] {
        var query = CityDirectory.normalize(text)
        guard !query.isEmpty else { return [] }
        let hour = Int(date.timeIntervalSince1970 / 3600)
        func groups(_ records: [CityRecord]) -> [ClockGroup] {
            clockGroups(for: records, from: date) { zone in
                self.cacheLock.lock()
                defer { self.cacheLock.unlock() }
                if self.keyCache.hour != hour { self.keyCache = (hour, [:]) }
                if let key = self.keyCache.keys[zone.identifier] { return key }
                let key = clockKey(for: zone, from: date)
                self.keyCache.keys[zone.identifier] = key
                return key
            }
        }
        if let alias = Self.aliases[query] { query = CityDirectory.normalize(alias) }

        var candidates: [Candidate] = []
        func match(_ keys: [String], _ words: [String] = []) -> Bool? {  // true exact, false prefix, nil no match
            if keys.contains(query) { return true }
            if keys.contains(where: { $0.hasPrefix(query) }) || words.contains(where: { $0.hasPrefix(query) }) { return false }
            return nil
        }

        // Most populous first, so only the first `limit` partial matches can rank; exact ones all can.
        var partialCities = 0
        for index in cityOrder {
            let entry = cityKeys[index]
            guard let exact = match(entry.keys, entry.words) else { continue }
            if !exact {
                guard partialCities < limit else { continue }
                partialCities += 1
            }
            let record = directory.records[index]
            let kind: Kind = exact && record.population < Self.majorCityPopulation ? .smallExactCity : .city
            candidates.append(Candidate(id: "\(record.timeZoneID)|\(record.name)", make: { self.citySuggestion(record, at: date) },
                                        exact: exact, kind: kind, subOrder: 0, population: record.population))
        }

        for region in regions {
            guard let exact = match(region.keys, region.keys.flatMap(Self.words)) else { continue }
            for group in groups(region.records) {
                let id = group.representativeID, country = region.region.countryCode, place = "Covers \(region.region.name)"
                candidates.append(Candidate(id: "\(id)|\(Self.zoneCity(id))", make: { self.zoneSuggestion(id, country: country, place: place, at: date) },
                                            exact: exact, kind: .region, subOrder: 0, population: group.population))
            }
            for record in region.records.sorted(by: { $0.population > $1.population }).prefix(2) {
                candidates.append(Candidate(id: "\(record.timeZoneID)|\(record.name)", make: { self.citySuggestion(record, at: date) },
                                            exact: exact, kind: .region, subOrder: 1, population: record.population))
            }
        }

        for country in countries {
            guard let exact = match(country.keys, country.keys.flatMap(Self.words)) else { continue }
            for group in groups(country.records) {
                let id = group.representativeID, code = country.code
                candidates.append(Candidate(id: "\(id)|\(Self.zoneCity(id))", make: { self.zoneSuggestion(id, country: code, at: date) },
                                            exact: exact, kind: .country, subOrder: 0, population: group.population))
            }
        }

        for id in abbreviations[text.trimmingCharacters(in: .whitespaces).uppercased()] ?? [] {
            let country = directory.countryCode(forTimeZoneID: id)
            candidates.append(Candidate(id: "\(id)|\(Self.zoneCity(id))", make: { self.zoneSuggestion(id, country: country, at: date) },
                                        exact: true, kind: .zone, subOrder: 0, population: 0))
        }

        if query.count >= 4 {
            // Grouped per country: Denver and Edmonton keep the same clock, but each is its country's answer.
            for entry in zoneNames where entry.key.hasPrefix(query) {
                for (country, records) in Dictionary(grouping: entry.records, by: \.countryCode) {
                    for group in groups(records) {
                        let id = group.representativeID
                        candidates.append(Candidate(id: "\(id)|\(Self.zoneCity(id))", make: { self.zoneSuggestion(id, country: country, at: date) },
                                                    exact: entry.key == query, kind: .zone, subOrder: 1, population: group.population))
                    }
                }
            }
        }

        let ranked = candidates.sorted {
            ($0.exact ? 0 : 1, $0.kind.rawValue, $0.subOrder, -$0.population) < ($1.exact ? 0 : 1, $1.kind.rawValue, $1.subOrder, -$1.population)
        }
        var seen: Set<String> = []
        var results: [PlaceSuggestion] = []
        for candidate in ranked where seen.insert(candidate.id).inserted {
            results.append(candidate.make())
            if results.count == limit { break }
        }
        return results
    }

    /// America/Denver → "Denver", America/Argentina/Buenos_Aires → "Buenos Aires".
    private static func zoneCity(_ id: String) -> String {
        (id.split(separator: "/").last.map(String.init) ?? id).replacingOccurrences(of: "_", with: " ")
    }

    private static func words(_ key: String) -> [String] {
        key.split(whereSeparator: { $0 == " " || $0 == "-" }).map(String.init)
    }

    private func countryName(_ code: String?) -> String? {
        code.map { displayLocale.localizedString(forRegionCode: $0) ?? $0 }
    }

    /// "Colorado Springs" · "Colorado, United States · Mountain Time (MDT)".
    private func citySuggestion(_ record: CityRecord, at date: Date) -> PlaceSuggestion {
        let zone = TimeZone(identifier: record.timeZoneID) ?? .gmt
        let place = [regionNames["\(record.countryCode).\(record.admin1)"], countryName(record.countryCode)]
            .compactMap { $0 }.joined(separator: ", ")
        return PlaceSuggestion(name: record.name, detail: "\(place) · \(labeller.label(for: zone, at: date, displayLocale: displayLocale))",
                               countryCode: record.countryCode, timeZoneID: record.timeZoneID)
    }

    /// Named after the zone's own city (America/Denver → "Denver"); detail "<place> · <label>".
    private func zoneSuggestion(_ id: String, country: String?, place: String? = nil, at date: Date) -> PlaceSuggestion {
        let zone = TimeZone(identifier: id) ?? .gmt
        let name = Self.zoneCity(id)
        let label = labeller.label(for: zone, at: date, displayLocale: displayLocale)
        let detail = [place ?? countryName(country), label].compactMap { $0 }.joined(separator: " · ")
        return PlaceSuggestion(name: name, detail: detail, countryCode: country, timeZoneID: id)
    }
}
