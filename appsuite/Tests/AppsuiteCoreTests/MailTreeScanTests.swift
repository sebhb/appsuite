import Foundation
import Testing
@testable import AppsuiteCore

@Suite struct MailTreeScanTests {

    private func scan(_ root: String) throws -> [(folder: String, mails: [String])] {
        try AppsuiteService().mailUploadsForTree(at: root).map { upload in
            (upload.targetFolder.joined(separator: "/"),
             upload.mailPaths.map { URL(fileURLWithPath: $0).lastPathComponent }.sorted())
        }
    }

    @Test func flatTreeYieldsOneUploadPerFolder() throws {
        let root = try TestSupport.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: root) }
        try TestSupport.createFile("INBOX/1.eml", in: root)
        try TestSupport.createFile("INBOX/2.eml", in: root)
        try TestSupport.createFile("Sent Items/3.eml", in: root)

        let result = try scan(root)
        #expect(result.map(\.folder) == ["INBOX", "Sent Items"])
        #expect(result[0].mails == ["1.eml", "2.eml"])
        #expect(result[1].mails == ["3.eml"])
    }

    @Test func nestedFoldersKeepTheirPathAndParentsComeFirst() throws {
        let root = try TestSupport.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: root) }
        try TestSupport.createFile("INBOX/1.eml", in: root)
        try TestSupport.createFile("INBOX/Projects/2.eml", in: root)
        try TestSupport.createFile("INBOX/Projects/Alpha/3.eml", in: root)

        #expect(try scan(root).map(\.folder) == ["INBOX", "INBOX/Projects", "INBOX/Projects/Alpha"])
    }

    @Test func foldersWithoutMailsAreOnlyPartOfTheirChildrensPath() throws {
        let root = try TestSupport.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: root) }
        try TestSupport.createFile("Archive/2025/January/1.eml", in: root)
        try TestSupport.createDirectory("Drafts", in: root)

        let result = try scan(root)
        #expect(result.map(\.folder) == ["Archive/2025/January"])
        #expect(result.first?.mails == ["1.eml"])
    }

    @Test func ignoresHiddenEntriesAndNonEmlFiles() throws {
        let root = try TestSupport.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: root) }
        try TestSupport.createFile("INBOX/1.eml", in: root)
        try TestSupport.createFile("INBOX/notes.txt", in: root)
        try TestSupport.createFile("INBOX/.DS_Store", in: root)
        try TestSupport.createFile(".hidden/2.eml", in: root)
        try TestSupport.createFile("INBOX/.Hidden/3.eml", in: root)
        try TestSupport.createFile("loose.eml", in: root)

        let result = try scan(root)
        #expect(result.map(\.folder) == ["INBOX"])
        #expect(result.first?.mails == ["1.eml"])
    }

    @Test func emptyRootYieldsNothing() throws {
        let root = try TestSupport.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: root) }
        #expect(try scan(root).isEmpty)
    }

    @Test func missingRootThrows() {
        #expect(throws: (any Error).self) {
            try AppsuiteService().mailUploadsForTree(at: "/nonexistent-\(UUID().uuidString)")
        }
    }
}
