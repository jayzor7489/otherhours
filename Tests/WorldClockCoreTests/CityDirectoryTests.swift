import Foundation
import Testing
@testable import WorldClockCore

@Test func flags() {
    #expect(flagEmoji(countryCode: "PH") == "🇵🇭")
    #expect(flagEmoji(countryCode: nil) == "🌐")
    #expect(flagEmoji(countryCode: "X") == "🌐")
}

@Test func countryForZoneUsesMostPopulousCity() {
    #expect(fixture.countryCode(forTimeZoneID: "Asia/Manila") == "PH")
    #expect(fixture.countryCode(forTimeZoneID: "Mars/Olympus") == nil)
}

@Test func realFileLoads() {
    #expect(realDirectory.records.count > 30_000)
    #expect(realDirectory.countryCode(forTimeZoneID: "Asia/Manila") == "PH")
    #expect(realDirectory.countryCode(forTimeZoneID: "Europe/London") == "GB")
}
