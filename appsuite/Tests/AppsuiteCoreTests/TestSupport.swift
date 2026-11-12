import Foundation
import Testing
@testable import AppsuiteCore

enum TestSupport {
    static var session: RemoteSession { RemoteSession(session: "test-session", server: "appsuite.example.com", cookieJar: CookieJar()) }

    /// Creates a fresh, empty temporary directory and returns its path.
    static func makeTemporaryDirectory() throws -> String {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("AppsuiteCoreTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url.path
    }

    /// Creates `relativePath` below `root`, including intermediate directories.
    static func createFile(_ relativePath: String, in root: String, contents: String = "x") throws {
        let url = URL(fileURLWithPath: root).appendingPathComponent(relativePath)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(contents.utf8).write(to: url)
    }

    static func createDirectory(_ relativePath: String, in root: String) throws {
        let url = URL(fileURLWithPath: root).appendingPathComponent(relativePath)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    static func jsonObject(_ data: Data?) throws -> Any {
        try JSONSerialization.jsonObject(with: try #require(data))
    }
}
