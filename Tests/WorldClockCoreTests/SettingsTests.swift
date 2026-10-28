import Foundation
import Testing
@testable import WorldClockCore

private func freshDefaults() -> UserDefaults { UserDefaults(suiteName: "wc-test-\(UUID())")! }

private let denver = SavedCity(name: "Denver", countryCode: "US", timeZoneID: "America/Denver")
private let london = SavedCity(name: "London", countryCode: "GB", timeZoneID: "Europe/London")
private let tokyo = SavedCity(name: "Tokyo", countryCode: "JP", timeZoneID: "Asia/Tokyo")

@Test func settingsRoundTrip() {
    let d = freshDefaults()
    let s = ClockSettings(cities: [denver, SavedCity(name: "Somewhere", countryCode: nil, timeZoneID: "UTC")],
                          theme: .clocks, hourCycle: .h24)
    s.save(to: d)
    #expect(ClockSettings.load(from: d) == s)
}

@Test func emptyDefaultsGiveNoCitiesDayNightFollowMac() {
    #expect(ClockSettings.load(from: freshDefaults()) == ClockSettings(cities: [], theme: .dayNight, hourCycle: .system))
}

/// The keys the widget reads, by hand-written `defaults write`, must stay plist-native.
@Test func citiesAreStoredAsPlainDictionaries() {
    let d = freshDefaults()
    ClockSettings(cities: [denver], theme: .dayNight, hourCycle: .system).save(to: d)
    let raw = d.array(forKey: "cities") as? [[String: String]]
    #expect(raw == [["name": "Denver", "countryCode": "US", "timeZoneID": "America/Denver"]])
    #expect(d.string(forKey: "theme") == "dayNight")
    #expect(d.string(forKey: "hourCycle") == "system")
}

@Test func storeSavesAndSignalsEachChangeOnce() {
    let d = freshDefaults()
    var changes = 0
    let store = SettingsStore(defaults: d, onChange: { changes += 1 })
    store.add(london)
    store.add(SavedCity(name: "london", countryCode: "GB", timeZoneID: "Europe/London"))  // duplicate, ignored
    store.setTheme(.list)
    #expect(changes == 2)
    #expect(ClockSettings.load(from: d).cities.count == 1)
    #expect(ClockSettings.load(from: d).theme == .list)
}

@Test func storeMoveKeepsOrder() {
    let d = freshDefaults()
    let store = SettingsStore(defaults: d, onChange: {})
    [denver, london, tokyo].forEach(store.add)
    store.move(from: [2], to: 0)
    #expect(ClockSettings.load(from: d).cities == [tokyo, denver, london])
    store.remove(at: [1])
    #expect(store.settings.cities == [tokyo, london])
}

@Test func storeReloadReadsWithoutSignalling() {
    let d = freshDefaults()
    var changes = 0
    let store = SettingsStore(defaults: d, onChange: { changes += 1 })
    ClockSettings(cities: [tokyo], theme: .spotlight, hourCycle: .h12).save(to: d)
    store.reload()
    #expect(store.settings.cities == [tokyo])
    #expect(changes == 0)
}

@Test func vanishedZoneIsSkipped() {
    let rows = makeRows(saved: [SavedCity(name: "Old", countryCode: nil, timeZoneID: "Europe/Nowhere"), denver],
                        userZone: tz("Asia/Manila"), directory: fixture)
    #expect(rows.count == 2)
}

@Test func macZoneWithoutCityStillShows() {
    guard case .you(let name, let flag, _) = makeRows(saved: [], userZone: tz("Antarctica/Troll"), directory: fixture)[0] else {
        Issue.record("no you row"); return
    }
    #expect(name == "Troll")
    #expect(flag == "🌐")
}

@Test func dropOntoARowTakesThatRowsPlace() {
    let d = freshDefaults()
    let store = SettingsStore(defaults: d, onChange: {})
    let sydney = SavedCity(name: "Sydney", countryCode: "AU", timeZoneID: "Australia/Sydney")
    [denver, london, tokyo, sydney].forEach(store.add)
    store.moveCity(at: 0, onto: 2)   // dragged down: lands after the row it was dropped on
    #expect(store.settings.cities == [london, tokyo, denver, sydney])
    store.moveCity(at: 3, onto: 0)   // dragged up: lands before it
    #expect(store.settings.cities == [sydney, london, tokyo, denver])
    store.moveCity(at: 1, onto: 1)   // onto itself: nothing changes
    #expect(ClockSettings.load(from: d).cities == [sydney, london, tokyo, denver])
}

@Test func renameCopiesOldSettingsOnce() {
    let old = freshDefaults(), new = freshDefaults()
    let saved = ClockSettings(cities: [denver, tokyo], theme: .spotlight, hourCycle: .h24)
    saved.save(to: old)
    #expect(ClockSettings.migrate(from: old, to: new))
    #expect(ClockSettings.load(from: new) == saved)
    // Once the new home has settings of its own, the old ones never overwrite them.
    ClockSettings(cities: [london], theme: .list, hourCycle: .system).save(to: new)
    #expect(!ClockSettings.migrate(from: old, to: new))
    #expect(ClockSettings.load(from: new).cities == [london])
}

@Test func renameWithNothingSavedCopiesNothing() {
    let new = freshDefaults()
    #expect(!ClockSettings.migrate(from: freshDefaults(), to: new))
    #expect(new.object(forKey: "cities") == nil)
}
