// The widget's setting, shared by the extension and the menu bar app. This module must stay
// named WorldClockWidget: macOS stores the setting under the type's mangled name
// (16WorldClockWidget18SelectCitiesIntentV), and the app can only decode it, via
// WidgetCenter.currentConfigurations(), when its copy of the type has that exact name.
import AppIntents

/// The only setting: a typed list. A String is the one parameter type that decodes without
/// Xcode's metadata processor (dropdowns arrive as nil). Keep in sync with scripts/make_metadata.py.
public struct SelectCitiesIntent: WidgetConfigurationIntent {
    public static let title: LocalizedStringResource = "Choose Cities"
    public static let description = IntentDescription("Type cities separated by commas.")

    @Parameter(title: "Cities", default: "Denver, London, Sydney")  // = defaultCityList
    public var cities: String

    public init() {}
}
