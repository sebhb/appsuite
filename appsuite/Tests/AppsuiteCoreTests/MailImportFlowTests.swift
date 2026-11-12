import Foundation
import Testing
@testable import AppsuiteCore

/// End-to-end tests of the mail import against `FakeAppSuite`: the real
/// commands, workers and service, with only the HTTP transport replaced.
@Suite struct MailImportFlowTests {

    // MARK: Helpers

    final class ProgressRecorder: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: [ProgressEvent] = []
        var events: [ProgressEvent] { lock.withLock { stored } }
        var handler: ProgressHandler { { event in self.lock.withLock { self.stored.append(event) } } }
        func messages(_ kind: ProgressEvent.Kind) -> [String] { events.filter { $0.kind == kind }.map(\.message) }
    }

    private let credentials = Credentials(server: "appsuite.example.com", userName: "anna", password: "secret", validateCertificate: false)

    /// Writes one `.eml` per subject below `root/<folder>`.
    private func writeTree(_ tree: [String: [String]]) throws -> String {
        let root = try TestSupport.makeTemporaryDirectory()
        for (folder, subjects) in tree {
            for (index, subject) in subjects.enumerated() {
                try TestSupport.createFile("\(folder)/\(index).eml", in: root, contents: Self.mail(subject))
            }
            if subjects.isEmpty {
                try TestSupport.createDirectory(folder, in: root)
            }
        }
        return root
    }

    static func mail(_ subject: String) -> String {
        "From: a@example.com\r\nTo: b@example.com\r\nSubject: \(subject)\r\n\r\nBody of \(subject)\r\n"
    }

    @discardableResult
    private func importTree(_ tree: [String: [String]], into server: FakeAppSuite, limits: MailBatchLimits = .default) async throws -> ProgressRecorder {
        let root = try writeTree(tree)
        defer { try? FileManager.default.removeItem(atPath: root) }
        let progress = ProgressRecorder()
        try await AppsuiteService(transport: server)
            .importMailTree(credentials, treeRoot: root, adjustRecipient: false, stretchPeriod: nil, batchLimits: limits, onProgress: progress.handler)
        return progress
    }

    // MARK: Folder hierarchy

    @Test(arguments: ["/", "."])
    func recreatesNestedFoldersWithTheServersSeparator(separator: String) async throws {
        let server = FakeAppSuite()
        server.separator = separator

        try await importTree([
            "INBOX": ["inbox mail"],
            "INBOX/Projects": ["project mail"],
            "INBOX/Projects/Alpha": ["alpha mail"],
            "Customers/ACME": ["acme mail"],
        ], into: server)

        #expect(server.subjects(in: ["INBOX"]) == ["inbox mail"])
        #expect(server.subjects(in: ["INBOX", "Projects"]) == ["project mail"])
        #expect(server.subjects(in: ["INBOX", "Projects", "Alpha"]) == ["alpha mail"])
        #expect(server.subjects(in: ["Customers", "ACME"]) == ["acme mail"])
        #expect(server.folderID(["INBOX", "Projects", "Alpha"]) == "default0/INBOX\(separator)Projects\(separator)Alpha")
    }

    @Test func reusesExistingFoldersInsteadOfCreatingDuplicates() async throws {
        let server = FakeAppSuite()
        let projects = server.addFolder("Projects", under: "default0/INBOX")
        server.addFolder("Alpha", under: projects)

        try await importTree(["INBOX/Projects/Alpha": ["alpha mail"]], into: server)

        #expect(server.requests(module: "folders", action: "new").isEmpty)
        #expect(server.children(of: ["INBOX"]) == ["Projects"])
        #expect(server.subjects(in: ["INBOX", "Projects", "Alpha"]) == ["alpha mail"])
    }

    @Test func mapsStandardFoldersToTheirServerNames() async throws {
        let server = FakeAppSuite()

        try await importTree(["Sent Items": ["sent mail"], "Junk E-Mail": ["junk mail"]], into: server)

        #expect(server.subjects(in: ["Sent"]) == ["sent mail"])
        #expect(server.subjects(in: ["Spam"]) == ["junk mail"])
        #expect(server.requests(module: "folders", action: "new").isEmpty)
    }

    @Test func aFolderThatCannotBeCreatedIsSkippedAndTheRestContinues() async throws {
        let server = FakeAppSuite()
        server.failingFolderTitles = ["Broken"]

        let progress = try await importTree(["Broken": ["lost mail"], "Fine": ["kept mail"]], into: server)

        #expect(server.subjects(in: ["Fine"]) == ["kept mail"])
        #expect(server.allSubjects.contains("lost mail") == false)
        #expect(progress.messages(.failed).contains { $0.hasPrefix("Skipping Broken") })
    }

    // MARK: Archive

    @Test func createsTheArchiveFolderThroughTheServerWhenItIsMissing() async throws {
        let server = FakeAppSuite()

        let progress = try await importTree([
            "Archive/2025/January": ["january mail"],
            "Archive/2025/February": ["february mail"],
        ], into: server)

        #expect(server.subjects(in: ["Archive", "2025", "January"]) == ["january mail"])
        #expect(server.subjects(in: ["Archive", "2025", "February"]) == ["february mail"])
        // Resolved once per run, even with two subtrees below Archive.
        #expect(server.requests(module: "mail", action: "archive").count == 1)
        // Placeholder and the year folder it was archived into are gone.
        #expect(server.allSubjects.allSatisfy { !$0.contains("placeholder") })
        #expect(server.children(of: ["Archive"]) == ["2025"])
        #expect(server.children(of: []).contains("Archive (imported)") == false)
        #expect(progress.messages(.log).contains("Created archive folder Archive."))
        #expect(progress.messages(.failed).isEmpty)
    }

    @Test func usesTheReportedArchiveFolderWithoutArchiving() async throws {
        let server = FakeAppSuite()
        server.addFolder("Archives")
        server.setAccountField("archive_fullname", "Archives")

        try await importTree(["Archive": ["old mail"]], into: server)

        #expect(server.subjects(in: ["Archives"]) == ["old mail"])
        #expect(server.requests(module: "mail", action: "archive").isEmpty)
    }

    @Test func findsAnUnreportedArchiveFolderBelowInbox() async throws {
        let server = FakeAppSuite()
        server.addFolder("Archive", under: "default0/INBOX")

        try await importTree(["Archive": ["old mail"]], into: server)

        #expect(server.subjects(in: ["INBOX", "Archive"]) == ["old mail"])
        #expect(server.requests(module: "mail", action: "archive").isEmpty)
        #expect(server.requests(module: "folders", action: "new").isEmpty)
    }

    @Test func fallsBackToAnImportedFolderWhenArchivingIsUnavailable() async throws {
        let server = FakeAppSuite()
        server.archiveSupported = false

        let progress = try await importTree(["Archive/2025": ["old mail"]], into: server)

        #expect(server.subjects(in: ["Archive (imported)", "2025"]) == ["old mail"])
        // The placeholder imported into INBOX for the failed attempt was removed.
        #expect(server.subjects(in: ["INBOX"]).isEmpty)
        #expect(progress.messages(.log).contains { $0.contains("importing into 'Archive (imported)' instead") })
    }

    @Test func reusesAnImportedFolderFromAnEarlierRun() async throws {
        let server = FakeAppSuite()
        server.archiveSupported = false
        server.addFolder("Archive (imported)")

        try await importTree(["Archive": ["old mail"]], into: server)

        #expect(server.subjects(in: ["Archive (imported)"]) == ["old mail"])
        #expect(server.children(of: []).filter { $0.hasPrefix("Archive") } == ["Archive (imported)"])
    }

    // MARK: Batching

    @Test func uploadsMailsInBatches() async throws {
        let server = FakeAppSuite()
        let subjects = (1...5).map { "mail \($0)" }

        try await importTree(["INBOX": subjects], into: server, limits: MailBatchLimits(maxBytes: 1_000_000, maxCount: 2))

        let imports = server.requests(module: "mail", action: "import")
        #expect(imports.map { FakeAppSuite.subjectsOfMultipartMails($0.body ?? Data()).count } == [2, 2, 1])
        #expect(Set(server.subjects(in: ["INBOX"])) == Set(subjects))
    }

    @Test func retriesARejectedBatchOneMailAtATime() async throws {
        let server = FakeAppSuite()
        server.rejectImport = { $0.count > 1 ? 413 : nil }   // e.g. a proxy body-size limit
        let subjects = (1...3).map { "mail \($0)" }

        let progress = try await importTree(["INBOX": subjects], into: server)

        #expect(Set(server.subjects(in: ["INBOX"])) == Set(subjects))
        #expect(progress.messages(.log).contains { $0.contains("retrying one by one") })
        #expect(progress.messages(.failed).isEmpty)
    }

    @Test func aSingleBrokenMailIsReportedWithoutLosingTheOthers() async throws {
        let server = FakeAppSuite()
        server.rejectImport = { $0.contains("broken") ? 500 : nil }

        let progress = try await importTree(["INBOX": ["good 1", "broken", "good 2"]], into: server)

        #expect(Set(server.subjects(in: ["INBOX"])) == ["good 1", "good 2"])
        #expect(progress.messages(.failed).count == 1)
    }

    @Test func reportsWhenTheServerConfirmsFewerMails() async throws {
        let server = FakeAppSuite()
        server.confirmFewerImports = true

        let progress = try await importTree(["INBOX": ["a", "b", "c"]], into: server)

        #expect(progress.messages(.log).contains { $0.contains("Server confirmed 2 of 3 mails") })
    }

    @Test func progressCountsAllMails() async throws {
        let server = FakeAppSuite()

        let progress = try await importTree(["INBOX": ["a", "b", "c"]], into: server, limits: MailBatchLimits(maxBytes: 1_000_000, maxCount: 2))

        let steps = progress.events.filter { $0.kind == .progress }
        #expect(steps.map(\.current) == [2, 3])
        #expect(steps.allSatisfy { $0.total == 3 })
    }

    // MARK: Session handling

    @Test func everyRequestUsesTheSessionCookieAndCertificateSetting() async throws {
        let server = FakeAppSuite()

        try await importTree(["INBOX/Projects": ["a"]], into: server)

        let afterLogin = server.requests.dropFirst()
        #expect(server.requests.first?.action == "login")
        #expect(afterLogin.isEmpty == false)
        #expect(afterLogin.allSatisfy { $0.headers["Cookie"] == "JSESSIONID=abc123" })
        #expect(server.requests.allSatisfy { $0.certificateVerification == false })
        #expect(server.requests.last?.action == "logout")
    }

    // MARK: Flat import

    @Test func flatImportCreatesANestedTargetFolder() async throws {
        let server = FakeAppSuite()
        let root = try writeTree(["files": ["a", "b"]])
        defer { try? FileManager.default.removeItem(atPath: root) }
        let paths = try FileManager.default.contentsOfDirectory(atPath: root + "/files").map { root + "/files/" + $0 }

        try await AppsuiteService(transport: server)
            .importMails(credentials, mailPaths: paths, targetFolder: "INBOX/Imported/Today", createFolder: true, adjustRecipient: false, stretchPeriod: nil, onProgress: { _ in })

        #expect(Set(server.subjects(in: ["INBOX", "Imported", "Today"])) == ["a", "b"])
    }
}
