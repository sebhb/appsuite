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

// Path Operations
extension String {
    static func resolvePath(_ input: String) -> String {
        if input.hasPrefix("/") {
            return input
        }
        if input.hasPrefix("~") {
            let home = ProcessInfo.processInfo.environment["HOME"] ?? ""
            return home + input.dropFirst()
        }
        let currentDirectory = FileManager.default.currentDirectoryPath
        return currentDirectory.appendingPathComponent(input)
    }

    func isDirectoryPath() -> Bool {
        var statbuf = stat()
        if stat(self, &statbuf) == 0 {
            return (statbuf.st_mode & S_IFMT) == S_IFDIR
        }
        return false
    }
}
