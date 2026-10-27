import Foundation
import Testing
@testable import WorldClockCore

@Test func mostPopulousWinsATie() {
    #expect(fixture.resolve(.init(name: "sydney", countryCode: nil))?.countryCode == "AU")
}

@Test func bracketCountryPicksAnother() {
    #expect(fixture.resolve(.init(name: "Sydney", countryCode: "CA"))?.timeZone.identifier == "America/Glace_Bay")
}

@Test func asciiNameMatches() {
    #expect(fixture.resolve(.init(name: "sao paulo", countryCode: nil))?.displayName == "São Paulo")
}

@Test func cityWordIsOptional() {
    #expect(fixture.resolve(.init(name: "Cebu", countryCode: nil))?.displayName == "Cebu City")
}

@Test func aliasNYC() {
    #expect(fixture.resolve(.init(name: "NYC", countryCode: nil))?.timeZone.identifier == "America/New_York")
}

@Test func timeZoneFallback() {
    let empty = CityDirectory(records: [])
    let city = empty.resolve(.init(name: "Denver", countryCode: nil))
    #expect(city?.timeZone.identifier == "America/Denver")
    #expect(city?.displayName == "Denver")
}

@Test func unknownIsNil() {
    #expect(fixture.resolve(.init(name: "Atlantis", countryCode: nil)) == nil)
}

@Test func flags() {
    #expect(flagEmoji(countryCode: "PH") == "🇵🇭")
    #expect(flagEmoji(countryCode: nil) == "🌐")
    #expect(flagEmoji(countryCode: "X") == "🌐")
}

@Test func countryForZoneUsesMostPopulousCity() {
    #expect(fixture.countryCode(forTimeZoneID: "Asia/Manila") == "PH")
    #expect(fixture.countryCode(forTimeZoneID: "Mars/Olympus") == nil)
}

private let realDirectory: CityDirectory = {
    let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .appendingPathComponent("../../Resources/cities.tsv").standardized
    return try! CityDirectory.load(contentsOf: url)
}()

/// A small namesake must not hide a place that has its own time zone (review finding:
/// "Puerto Rico" was a town in Colombia, "Jersey" was Jersey City).
@Test func timeZonePlacesBeatSmallNamesakes() {
    let expected = [
        "Puerto Rico": "America/Puerto_Rico", "Jamaica": "America/Jamaica", "Costa Rica": "America/Costa_Rica",
        "Palau": "Pacific/Palau", "Jersey": "Europe/Jersey", "Chatham": "Pacific/Chatham", "Stanley": "Atlantic/Stanley",
    ]
    for (typed, zone) in expected {
        #expect(realDirectory.resolve(.init(name: typed, countryCode: nil))?.timeZone.identifier == zone, "\(typed)")
    }
}

@Test func calcuttaIsKolkata() {
    let city = realDirectory.resolve(.init(name: "Calcutta", countryCode: nil))
    #expect(city?.countryCode == "IN")
}

@Test func bigCitiesStillWinTheirOwnName() {
    #expect(realDirectory.resolve(.init(name: "Denver", countryCode: nil))?.displayName == "Denver")
    #expect(realDirectory.resolve(.init(name: "Guatemala", countryCode: nil))?.timeZone.identifier == "America/Guatemala")
    #expect(realDirectory.resolve(.init(name: "Panama", countryCode: nil))?.timeZone.identifier == "America/Panama")
}

@Test func realFileLoadsAndFindsUsualCities() throws {
    let dir = realDirectory
    for name in ["Denver", "London", "Sydney", "Manila", "San Francisco", "Cebu", "New York"] {
        #expect(dir.resolve(.init(name: name, countryCode: nil)) != nil, "\(name)")
    }
    #expect(dir.resolve(.init(name: "San Francisco", countryCode: nil))?.countryCode == "US")
    #expect(dir.resolve(.init(name: "London", countryCode: nil))?.countryCode == "GB")
    #expect(dir.countryCode(forTimeZoneID: "Asia/Manila") == "PH")
}
