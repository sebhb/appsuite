import Foundation

public extension Dictionary {
    /// Renders the dictionary as an `application/x-www-form-urlencoded` string
    /// (`key=value&key=value`), percent-encoding every key and value so that
    /// special characters (`%`, `#`, `&`, `+`, `=`, space, …) cannot corrupt
    /// the field separators. Suitable for both URL query strings and POST
    /// bodies.
    func encodedAsURLParameters() -> String {
        var parts = [String]()

        for (key, value) in self {
            let encodedKey = "\(key)".percentEncodedForOX()
            let encodedValue = "\(value)".percentEncodedForOX()
            parts.append("\(encodedKey)=\(encodedValue)")
        }

        let result = parts.sorted().joined(separator: "&")
        return result
    }
}
