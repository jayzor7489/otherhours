import Foundation
@testable import WorldClockCore

func tz(_ id: String) -> TimeZone { TimeZone(identifier: id)! }

/// Small directory for rule tests: two Sydneys, suffix and accent cases, the usual cities.
let fixture = CityDirectory(records: [
    CityRecord(name: "Sydney", asciiName: "Sydney", countryCode: "AU", timeZoneID: "Australia/Sydney", population: 4_600_000),
    CityRecord(name: "Sydney", asciiName: "Sydney", countryCode: "CA", timeZoneID: "America/Glace_Bay", population: 30_000),
    CityRecord(name: "New York City", asciiName: "New York City", countryCode: "US", timeZoneID: "America/New_York", population: 8_800_000),
    CityRecord(name: "São Paulo", asciiName: "Sao Paulo", countryCode: "BR", timeZoneID: "America/Sao_Paulo", population: 12_000_000),
    CityRecord(name: "Cebu City", asciiName: "Cebu City", countryCode: "PH", timeZoneID: "Asia/Manila", population: 960_000),
    CityRecord(name: "Manila", asciiName: "Manila", countryCode: "PH", timeZoneID: "Asia/Manila", population: 1_600_000),
    CityRecord(name: "London", asciiName: "London", countryCode: "GB", timeZoneID: "Europe/London", population: 8_900_000),
    CityRecord(name: "Denver", asciiName: "Denver", countryCode: "US", timeZoneID: "America/Denver", population: 730_000),
])
