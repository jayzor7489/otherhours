import Foundation
import Testing
@testable import WorldClockCore

private func date(_ iso: String) -> Date { ISO8601DateFormatter().date(from: iso)! }
private let t = date("2026-10-27T06:10:00Z")
private let labeller = ZoneLabeller(abbreviations: bundledAbbreviations, directory: realDirectory)
private let enUS = Locale(identifier: "en_US")

@Test func detroitAndNewYorkAreOneClock() {
    #expect(clockKey(for: tz("America/Detroit"), from: t) == clockKey(for: tz("America/New_York"), from: t))
}

@Test func phoenixIsNotDenver() {
    #expect(clockKey(for: tz("America/Phoenix"), from: t) != clockKey(for: tz("America/Denver"), from: t))
}

@Test func unitedStatesHasSevenClocks() {
    let groups = clockGroups(for: realDirectory.records.filter { $0.countryCode == "US" }, from: t)
    #expect(groups.count == 7, "\(groups.map(\.representativeID))")
}

@Test func australiaHasFiveClocks() {
    let groups = clockGroups(for: realDirectory.records.filter { $0.countryCode == "AU" }, from: t)
    #expect(groups.count == 5, "\(groups.map(\.representativeID))")
}

@Test func easternRepresentativeIsNewYork() {
    let groups = clockGroups(for: realDirectory.records.filter { $0.countryCode == "US" }, from: t)
    #expect(groups.first { $0.memberIDs.contains("America/Detroit") }?.representativeID == "America/New_York")
}

@Test func sydneyReadsAEDTWhateverTheMacLocale() {
    #expect(labeller.label(for: tz("Australia/Sydney"), at: t, displayLocale: Locale(identifier: "en_PH")).hasSuffix("(AEDT)"))
}

@Test func denverReadsMDTInOctoberAndMSTInDecember() {
    #expect(labeller.label(for: tz("America/Denver"), at: t, displayLocale: enUS).hasSuffix("(MDT)"))
    #expect(labeller.label(for: tz("America/Denver"), at: date("2026-12-01T12:00:00Z"), displayLocale: enUS).hasSuffix("(MST)"))
}

@Test func phoenixReadsMSTInJuly() {
    #expect(labeller.label(for: tz("America/Phoenix"), at: date("2026-07-01T12:00:00Z"), displayLocale: enUS).hasSuffix("(MST)"))
}

/// Not in the table: borrowed from a same-country zone that keeps the same clock.
@Test func detroitBorrowsNewYorksAbbreviation() {
    #expect(labeller.label(for: tz("America/Detroit"), at: t, displayLocale: enUS).hasSuffix("(EDT)"))
}

@Test func denverLabelReadsMountainTime() {
    #expect(labeller.label(for: tz("America/Denver"), at: t, displayLocale: enUS) == "Mountain Time (MDT)")
}
