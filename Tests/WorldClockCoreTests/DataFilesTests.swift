import Foundation
import Testing
@testable import WorldClockCore

private func tempFile(_ text: String) -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("wc-\(UUID()).tsv")
    try! text.write(to: url, atomically: true, encoding: .utf8)
    return url
}

@Test func sixColumnRowsCarryAdmin1() throws {
    let dir = try CityDirectory.load(contentsOf: tempFile("Colorado Springs\tColorado Springs\tUS\tAmerica/Denver\t200000\tCO\n"))
    #expect(dir.records[0].admin1 == "CO")
}

@Test func fiveColumnRowsStillLoad() throws {
    let dir = try CityDirectory.load(contentsOf: tempFile("Denver\tDenver\tUS\tAmerica/Denver\t730000\n"))
    #expect(dir.records[0].admin1 == "")
}

@Test func regionsLoad() throws {
    #expect(try loadRegions(contentsOf: tempFile("US.CO\tColorado\tColorado\n")) ==
            [RegionRecord(countryCode: "US", code: "CO", name: "Colorado", asciiName: "Colorado")])
}

@Test func abbreviationsLoadAndSkipComments() throws {
    let rows = try loadAbbreviations(contentsOf: tempFile("# zone abbreviations\nMDT\td\tAmerica/Denver\n\nMST\ts\tAmerica/Phoenix\n"))
    #expect(rows == [AbbreviationRecord(abbreviation: "MDT", isDaylight: true, timeZoneID: "America/Denver"),
                     AbbreviationRecord(abbreviation: "MST", isDaylight: false, timeZoneID: "America/Phoenix")])
}

@Test func bundledAbbreviationTableIsValid() {
    for row in bundledAbbreviations {
        #expect(TimeZone(identifier: row.timeZoneID) != nil, "\(row.abbreviation) \(row.timeZoneID)")
    }
    #expect(Set(bundledAbbreviations.filter { $0.abbreviation == "IST" }.map(\.timeZoneID)) ==
            ["Asia/Kolkata", "Europe/Dublin", "Asia/Jerusalem"])
}

@Test func bundledDataCarriesRegions() {
    #expect(realDirectory.records.contains { $0.name == "Colorado Springs" && $0.admin1 == "CO" })
    #expect(bundledRegions.contains { $0.countryCode == "US" && $0.code == "CO" && $0.name == "Colorado" })
}
