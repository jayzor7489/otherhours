import Foundation

/// The widget's default setting. Keep in sync with scripts/make_metadata.py.
public let defaultCityList = "Denver, London, Sydney"

/// The menu bar panel's cities: every World Clock widget's list in order, or the default when
/// there is no widget. Repeats are fine; makeRows drops them.
public func panelCityList(widgetLists: [String]) -> String {
    widgetLists.isEmpty ? defaultCityList : widgetLists.joined(separator: ", ")
}
