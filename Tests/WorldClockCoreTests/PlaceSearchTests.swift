import Foundation
import Testing
@testable import WorldClockCore

private let t = ISO8601DateFormatter().date(from: "2026-10-27T06:10:00Z")!
private let engine = PlaceSearch(directory: realDirectory, regions: bundledRegions, abbreviations: bundledAbbreviations,
                                 displayLocale: Locale(identifier: "en_US"))
private func search(_ text: String) -> [PlaceSuggestion] { engine.search(text, at: t) }

@Test func coloradoSuggestsDenverFirst() {
    let r = search("Colorado")
    #expect(r.first?.timeZoneID == "America/Denver")
    #expect(r.first?.name == "Denver")
    #expect(r.contains { $0.name == "Colorado Springs" })
}

@Test func coloradoDetailShowsMDT() {
    #expect(search("Colorado").first?.detail == "Covers Colorado · Mountain Time (MDT)")
}

@Test func arizonaSuggestsPhoenix() {
    #expect(search("Arizona").first?.timeZoneID == "America/Phoenix")
}

@Test func japanSuggestsTokyo() {
    #expect(search("Japan").first?.timeZoneID == "Asia/Tokyo")
}

@Test func unitedStatesGivesSevenClocks() {
    #expect(Set(search("United States").map(\.timeZoneID)).count == 7)
}

@Test func sydPrefersAustralia() {
    let r = search("syd")
    #expect(r.first?.countryCode == "AU")
    #expect(r.contains { $0.countryCode == "CA" && $0.name == "Sydney" })
}

@Test func pstIsLosAngeles() {
    #expect(search("PST").first?.timeZoneID == "America/Los_Angeles")
}

/// The three IST zones come first; places starting "Ist" (Istanbul) may follow.
@Test func istGivesThree() {
    #expect(Set(search("IST").prefix(3).map(\.timeZoneID)) == ["Asia/Kolkata", "Europe/Dublin", "Asia/Jerusalem"])
}

@Test func aestFindsSydney() {
    #expect(search("AEST").contains { $0.timeZoneID == "Australia/Sydney" })
}

@Test func wordPrefixFindsColoradoSprings() {
    #expect(search("springs").contains { $0.name == "Colorado Springs" })
}

@Test func accentsIgnored() {
    #expect(search("sao").first?.name == "São Paulo")
}

@Test func mountainTimeZoneName() {
    #expect(search("Mountain Time").contains { $0.timeZoneID == "America/Denver" })
}

@Test func nycAlias() {
    #expect(search("NYC").first?.timeZoneID == "America/New_York")
}

@Test func calcuttaIsKolkata() {
    #expect(search("Calcutta").first?.timeZoneID == "Asia/Kolkata")
}

/// A small namesake (a town in Colombia) must not hide the place with its own clock.
@Test func puertoRicoIsTheIsland() {
    #expect(search("Puerto Rico").first?.timeZoneID == "America/Puerto_Rico")
}

@Test func emptyAndBlankFindNothing() {
    #expect(search("").isEmpty)
    #expect(search("   ").isEmpty)
}

@Test func oneLetterIsCapped() {
    #expect(search("s").count == 8)
}

@Test func nonsenseFindsNothing() {
    #expect(search("qwertyville").isEmpty)
}

@Test func pickSavesWhatWasShown() {
    let pick = search("Colorado")[0]
    #expect(pick.saved == SavedCity(name: "Denver", countryCode: "US", timeZoneID: "America/Denver"))
}

@Test func searchIsFast() {
    let clock = ContinuousClock()
    let elapsed = clock.measure {
        for _ in 0..<7 { for text in ["s", "Colorado", "syd"] { _ = search(text) } }
    }
    #expect(elapsed < .milliseconds(1000), "\(elapsed)")
}
