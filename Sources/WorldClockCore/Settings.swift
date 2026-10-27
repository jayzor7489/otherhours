import Combine
import Foundation

/// A place the user picked in Settings. Stored as picked, so nothing is re-resolved later.
public struct SavedCity: Equatable, Hashable {
    public let name: String
    public let countryCode: String?
    public let timeZoneID: String

    public init(name: String, countryCode: String?, timeZoneID: String) {
        self.name = name
        self.countryCode = countryCode
        self.timeZoneID = timeZoneID
    }
}

public enum Theme: String, CaseIterable {
    case dayNight, list, clocks, spotlight

    public var title: String {
        switch self {
        case .dayNight: "Day & Night"
        case .list: "List"
        case .clocks: "Clocks"
        case .spotlight: "Spotlight"
        }
    }
}

public enum HourCycle: String, CaseIterable {
    case system, h12, h24

    public var title: String {
        switch self {
        case .system: "Follow Mac"
        case .h12: "12-hour"
        case .h24: "24-hour"
        }
    }
}

/// Everything the user can set. Lives in the app's preferences (com.jasonaldemita.worldclock);
/// the widget reads the same domain through its shared-preference entitlement.
public struct ClockSettings: Equatable {
    public var cities: [SavedCity]
    public var theme: Theme
    public var hourCycle: HourCycle

    public init(cities: [SavedCity], theme: Theme, hourCycle: HourCycle) {
        self.cities = cities
        self.theme = theme
        self.hourCycle = hourCycle
    }

    /// Plain plist values, so `defaults write` can set them by hand.
    public static func load(from defaults: UserDefaults) -> ClockSettings {
        let raw = defaults.array(forKey: "cities") as? [[String: String]] ?? []
        let cities = raw.compactMap { d -> SavedCity? in
            guard let name = d["name"], let zone = d["timeZoneID"] else { return nil }
            return SavedCity(name: name, countryCode: d["countryCode"], timeZoneID: zone)
        }
        return ClockSettings(cities: cities,
                             theme: defaults.string(forKey: "theme").flatMap(Theme.init(rawValue:)) ?? .dayNight,
                             hourCycle: defaults.string(forKey: "hourCycle").flatMap(HourCycle.init(rawValue:)) ?? .system)
    }

    public func save(to defaults: UserDefaults) {
        defaults.set(cities.map { city -> [String: String] in
            var d = ["name": city.name, "timeZoneID": city.timeZoneID]
            d["countryCode"] = city.countryCode
            return d
        }, forKey: "cities")
        defaults.set(theme.rawValue, forKey: "theme")
        defaults.set(hourCycle.rawValue, forKey: "hourCycle")
    }
}

/// The app's one copy of the settings. Every change saves, then calls `onChange` once
/// (the app reloads the widget there).
public final class SettingsStore: ObservableObject {
    @Published public private(set) var settings: ClockSettings
    private let defaults: UserDefaults
    private let onChange: () -> Void

    public init(defaults: UserDefaults, onChange: @escaping () -> Void) {
        self.defaults = defaults
        self.onChange = onChange
        settings = ClockSettings.load(from: defaults)
    }

    /// Ignored when the same place (zone and name) is already saved.
    public func add(_ city: SavedCity) {
        guard !settings.cities.contains(where: { Self.samePlace($0, city) }) else { return }
        change { $0.cities.append(city) }
    }

    public func contains(_ city: SavedCity) -> Bool {
        settings.cities.contains { Self.samePlace($0, city) }
    }

    public func remove(at offsets: IndexSet) {
        change { settings in settings.cities = settings.cities.enumerated().filter { !offsets.contains($0.offset) }.map(\.element) }
    }

    public func move(from source: IndexSet, to destination: Int) {
        // List.onMove semantics: `destination` is an index in the list before the move.
        change { settings in
            let moving = source.map { settings.cities[$0] }
            let before = source.filter { $0 < destination }.count
            settings.cities = settings.cities.enumerated().filter { !source.contains($0.offset) }.map(\.element)
            settings.cities.insert(contentsOf: moving, at: destination - before)
        }
    }

    public func setTheme(_ theme: Theme) {
        change { $0.theme = theme }
    }

    public func setHourCycle(_ hourCycle: HourCycle) {
        change { $0.hourCycle = hourCycle }
    }

    public func reload() {
        settings = ClockSettings.load(from: defaults)
    }

    private func change(_ edit: (inout ClockSettings) -> Void) {
        var next = settings
        edit(&next)
        settings = next
        next.save(to: defaults)
        onChange()
    }

    private static func samePlace(_ a: SavedCity, _ b: SavedCity) -> Bool {
        a.timeZoneID == b.timeZoneID && CityDirectory.normalize(a.name) == CityDirectory.normalize(b.name)
    }
}
