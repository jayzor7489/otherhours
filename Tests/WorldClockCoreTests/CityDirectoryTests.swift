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

@Test func realFileLoadsAndFindsUsualCities() throws {
    let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .appendingPathComponent("../../Resources/cities.tsv").standardized
    let dir = try CityDirectory.load(contentsOf: url)
    for name in ["Denver", "London", "Sydney", "Manila", "San Francisco", "Cebu", "New York"] {
        #expect(dir.resolve(.init(name: name, countryCode: nil)) != nil, "\(name)")
    }
    #expect(dir.resolve(.init(name: "San Francisco", countryCode: nil))?.countryCode == "US")
    #expect(dir.resolve(.init(name: "London", countryCode: nil))?.countryCode == "GB")
    #expect(dir.countryCode(forTimeZoneID: "Asia/Manila") == "PH")
}
