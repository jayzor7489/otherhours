import Testing
@testable import WorldClockCore

@Test func splitsOnCommasAndTrims() {
    #expect(parseCityList(" Denver,,London , ") == [
        CityQuery(name: "Denver", countryCode: nil), CityQuery(name: "London", countryCode: nil)])
}

@Test func readsCountryInBrackets() {
    #expect(parseCityList("Sydney (ca)") == [CityQuery(name: "Sydney", countryCode: "CA")])
}

@Test func emptyTextGivesNoCities() {
    #expect(parseCityList("") == [])
    #expect(parseCityList(" , ,") == [])
}

@Test func keepsTypedOrderAndCase() {
    #expect(parseCityList("tokyo, Denver").map(\.name) == ["tokyo", "Denver"])
}
