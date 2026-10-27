import Foundation
import Testing
@testable import WorldClockCore

@Test func youFirstThenTypedOrder() {
    let rows = makeRows(typed: "London, Denver", userZone: tz("Asia/Manila"), directory: fixture)
    guard case .you(let name, let flag, _) = rows[0] else { Issue.record("no you row"); return }
    #expect(name == "Manila")
    #expect(flag == "🇵🇭")
    #expect(rows.count == 3)
    guard case .city(let second, _, _) = rows[1] else { Issue.record("no city row"); return }
    #expect(second == "London")
}

@Test func dropsDuplicatesAndYourOwnCity() {
    #expect(makeRows(typed: "Manila, Denver, denver", userZone: tz("Asia/Manila"), directory: fixture).count == 2)
}

@Test func unknownKeepsItsPlace() {
    #expect(makeRows(typed: "Atlantis, Denver", userZone: tz("Asia/Manila"), directory: fixture)[1] == .unknown(typed: "Atlantis"))
}

@Test func emptyListIsJustYou() {
    #expect(makeRows(typed: " , ", userZone: tz("Asia/Manila"), directory: fixture).count == 1)
}

@Test func layoutMedium() {
    #expect(layout(rowCount: 3, size: .medium) == RowLayout(style: .full, visibleCount: 3, overflowCount: 0))
    #expect(layout(rowCount: 4, size: .medium) == RowLayout(style: .compact, visibleCount: 4, overflowCount: 0))
    #expect(layout(rowCount: 5, size: .medium) == RowLayout(style: .compact, visibleCount: 5, overflowCount: 0))
    #expect(layout(rowCount: 7, size: .medium) == RowLayout(style: .compact, visibleCount: 4, overflowCount: 3))
}

@Test func layoutLarge() {
    #expect(layout(rowCount: 7, size: .large) == RowLayout(style: .full, visibleCount: 7, overflowCount: 0))
    #expect(layout(rowCount: 10, size: .large) == RowLayout(style: .compact, visibleCount: 10, overflowCount: 0))
    #expect(layout(rowCount: 12, size: .large) == RowLayout(style: .compact, visibleCount: 9, overflowCount: 3))
}
