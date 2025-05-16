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
        var pathcomponents = self.split(separator: FileManager.systemPathSeparator)
        pathcomponents.removeLast()
        return FileManager.systemPathSeparator + pathcomponents.joined(separator: FileManager.systemPathSeparator)
    }

    func appendingPathComponent(_ pathComponent: String) -> String {
        return self + (self.hasSuffix(FileManager.systemPathSeparator) ? "" : FileManager.systemPathSeparator) + pathComponent
    }
}
