import Foundation

/// One entry from the typed list, e.g. "Sydney (CA)" → name "Sydney", country "CA".
public struct CityQuery: Equatable {
    public let name: String
    public let countryCode: String?

    public init(name: String, countryCode: String?) {
        self.name = name
        self.countryCode = countryCode
    }
}

/// Splits the Edit Widget text on commas, trims, drops empty items, keeps order and case.
/// A trailing two-letter "(XX)" picks the country; any other bracket stays in the name.
public func parseCityList(_ text: String) -> [CityQuery] {
    text.split(separator: ",").compactMap { part in
        let item = part.trimmingCharacters(in: .whitespaces)
        guard !item.isEmpty else { return nil }
        if let open = item.lastIndex(of: "("), item.hasSuffix(")") {
            let code = item[item.index(after: open)..<item.index(before: item.endIndex)]
                .trimmingCharacters(in: .whitespaces)
            let name = item[..<open].trimmingCharacters(in: .whitespaces)
            if code.count == 2, code.allSatisfy(\.isLetter), !name.isEmpty {
                return CityQuery(name: name, countryCode: code.uppercased())
            }
        }
        return CityQuery(name: item, countryCode: nil)
    }
}
