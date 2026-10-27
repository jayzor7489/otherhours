import Foundation
import Testing
@testable import WorldClockCore

@Test func panelWithoutWidgetsShowsTheDefaultCities() {
    #expect(panelCityList(widgetLists: []) == defaultCityList)
    #expect(defaultCityList == "Denver, London, Sydney")
}

@Test func panelCombinesEveryWidgetsCities() {
    #expect(panelCityList(widgetLists: ["Denver, London", "Tokyo"]) == "Denver, London, Tokyo")
}

/// A medium and a large widget usually hold the same list: each city must appear once.
@Test func twoWidgetsWithTheSameListShowEachCityOnce() {
    let typed = panelCityList(widgetLists: ["Denver, Qwertyville", "denver, qwertyville"])
    let rows = makeRows(typed: typed, userZone: tz("Asia/Manila"), directory: fixture)
    #expect(rows.count == 3)  // you, Denver, Qwertyville
}
