import Foundation

public extension Dictionary {
    func encodedAsURLParameters() -> String {
        var parts = [String]()

        for (key, value) in self {
            parts.append("\(key)=\(value)")
        }

        let result = parts.sorted().joined(separator: "&")
        return result
    }
}
