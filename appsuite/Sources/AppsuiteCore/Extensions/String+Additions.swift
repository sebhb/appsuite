import Foundation

extension String {
    func toBase64() -> String? {
        return self.data(using: .utf8)?.base64EncodedString()
    }
}

extension CharacterSet {
    /// Characters that may appear unescaped inside a single URL query-string
    /// value or an `application/x-www-form-urlencoded` field.
    ///
    /// This is the RFC 3986 *unreserved* set plus `/`. Everything else — most
    /// importantly `%`, `#`, `&`, `+`, `=` and space — is percent-encoded, so a
    /// value can never be mistaken for a separator or a stray escape sequence.
    /// `/` is intentionally kept literal so folder identifiers such as
    /// `default0/INBOX` survive untouched.
    static let oxURLComponentAllowed: CharacterSet = {
        var set = CharacterSet.alphanumerics
        set.insert(charactersIn: "-._~/")
        return set
    }()
}

extension String {
    /// Percent-encodes the string so it is safe to drop into a URL query value
    /// or a form-urlencoded body. See ``CharacterSet/oxURLComponentAllowed``.
    func percentEncodedForOX() -> String {
        addingPercentEncoding(withAllowedCharacters: .oxURLComponentAllowed) ?? self
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
