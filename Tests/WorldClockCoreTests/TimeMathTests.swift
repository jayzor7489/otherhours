import Foundation
import Testing
@testable import WorldClockCore

private func date(_ iso: String) -> Date { ISO8601DateFormatter().date(from: iso)! }

/// 2:10 PM in Manila.
private let t = date("2026-10-27T06:10:00Z")

@Test func offsets() {
    #expect(offsetLabel(at: t, cityZone: tz("America/Denver"), userZone: tz("Asia/Manila")) == "−14 hrs")
    #expect(offsetLabel(at: t, cityZone: tz("Australia/Sydney"), userZone: tz("Asia/Manila")) == "+3 hrs")
    #expect(offsetLabel(at: t, cityZone: tz("Asia/Kolkata"), userZone: tz("Asia/Manila")) == "−2:30 hrs")
    #expect(offsetLabel(at: t, cityZone: tz("Asia/Kathmandu"), userZone: tz("Asia/Manila")) == "−2:15 hrs")
    #expect(offsetLabel(at: t, cityZone: tz("Asia/Singapore"), userZone: tz("Asia/Manila")) == "Same time")
}

@Test func dstChangeoverDenver() {
    let before = date("2026-11-01T07:00:00Z")  // 01:00 MDT
    let after = date("2026-11-01T10:00:00Z")   // 03:00 MST
    #expect(offsetLabel(at: before, cityZone: tz("America/Denver"), userZone: tz("Asia/Manila")) == "−14 hrs")
    #expect(offsetLabel(at: after, cityZone: tz("America/Denver"), userZone: tz("Asia/Manila")) == "−15 hrs")
}

@Test func dayWords() {
    #expect(dayRelation(at: t, cityZone: tz("America/Denver"), userZone: tz("Asia/Manila")) == .today)        // 00:10 Oct 27
    #expect(dayRelation(at: t, cityZone: tz("Pacific/Honolulu"), userZone: tz("Asia/Manila")) == .yesterday)  // 20:10 Oct 26
    let late = date("2026-10-27T13:00:00Z")  // 21:00 Manila
    #expect(dayRelation(at: late, cityZone: tz("Pacific/Auckland"), userZone: tz("Asia/Manila")) == .tomorrow)
    #expect(DayRelation.tomorrow.label == "Tomorrow")
}

@Test func bandEdges() {
    func at(_ h: Int, _ m: Int) -> SkyBand {
        SkyBand.at(date(String(format: "2026-10-27T%02d:%02d:00Z", h, m)), in: tz("UTC"))
    }
    #expect(at(4, 59) == .night); #expect(at(5, 0) == .dawn); #expect(at(7, 59) == .dawn); #expect(at(8, 0) == .day)
    #expect(at(16, 59) == .day); #expect(at(17, 0) == .dusk); #expect(at(20, 59) == .dusk); #expect(at(21, 0) == .night)
}

@Test func twelveAndTwentyFourHour() {
    let us = timeParts(t, in: tz("America/Denver"), locale: Locale(identifier: "en_US"))
    #expect(us.time == "12:10")
    #expect(us.period == "AM")
    let gb = timeParts(t, in: tz("Australia/Sydney"), locale: Locale(identifier: "en_GB"))
    #expect(gb.time == "17:10")
    #expect(gb.period == nil)
}
