import Foundation

extension String {
    func toBase64() -> String? {
        return self.data(using: .utf8)?.base64EncodedString()
    }
}

extension String {
    func pathExtension() -> String {
        return self.components(separatedBy: ".").last?.lowercased() ?? ""
    }

    func removingLastPathComponent() -> String {
#if os(Windows)
        let pathSeparator = "\\"
#else
        let pathSeparator = "/"
#endif
        var pathcomponents = self.split(separator: pathSeparator)
        pathcomponents.removeLast()
        return pathSeparator + pathcomponents.joined(separator: pathSeparator)
    }

    func appendingPathComponent(_ pathComponent: String) -> String {
#if os(Windows)
        let pathSeparator = "\\"
#else
        let pathSeparator = "/"
#endif
        return self + (self.hasSuffix(pathSeparator) ? "" : pathSeparator) + pathComponent
    }
}
