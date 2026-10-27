import Foundation
import Testing
@testable import WorldClockCore

/// A timeline whose first entry is in the future draws an empty placeholder until it arrives.
@Test func timelineStartsAtTheCurrentMinuteNotTheNext() {
    let now = ISO8601DateFormatter().date(from: "2026-10-27T06:10:27Z")!.addingTimeInterval(0.4)
    let dates = minuteTimeline(from: now, count: 60)
    #expect(dates.count == 60)
    #expect(dates[0] == ISO8601DateFormatter().date(from: "2026-10-27T06:10:00Z")!)
    #expect(dates[0] <= now)
    #expect(dates[59] == ISO8601DateFormatter().date(from: "2026-10-27T07:09:00Z")!)
}

@Test func timelineOnAnExactMinuteStartsThere() {
    let now = ISO8601DateFormatter().date(from: "2026-10-27T06:10:00Z")!
    #expect(minuteTimeline(from: now, count: 2) == [now, now.addingTimeInterval(60)])
}
