import Foundation
import Testing
@testable import AppsuiteCore

@Suite struct MailFolderNamingTests {

    @Test(arguments: [
        ("INBOX", StandardFolderRole.inbox), ("inbox", .inbox),
        ("Sent", .sent), ("Sent Items", .sent), ("sent messages", .sent),
        ("Trash", .trash), ("Deleted", .trash), ("Deleted Items", .trash), ("Deleted Messages", .trash),
        ("Drafts", .drafts), ("Draft", .drafts),
        ("Spam", .spam), ("Junk", .spam), ("Junk E-Mail", .spam), ("junk email", .spam),
        ("Archive", .archive), ("ARCHIVE", .archive),
    ])
    func recognizesStandardFolders(name: String, role: StandardFolderRole) {
        #expect(UploadMailsWorker.standardRole(for: name) == role)
    }

    @Test(arguments: ["Projects", "DUMPSTER", "Archive (imported)", "Archives", "Sent Mail Old", ""])
    func customFoldersHaveNoRole(name: String) {
        #expect(UploadMailsWorker.standardRole(for: name) == nil)
    }

    @Test(arguments: [
        ("default0/INBOX", "INBOX"),
        ("default0/INBOX/Projects/Alpha", "INBOX/Projects/Alpha"),
        ("default0/INBOX.Projects", "INBOX.Projects"),
        ("INBOX/Projects", "INBOX/Projects"),
        ("default0", "default0"),
        ("default01/INBOX", "default01/INBOX"),
    ])
    func relativeNameStripsOnlyTheAccountPrefix(id: String, expected: String) {
        #expect(UploadMailsWorker.relativeName(of: id) == expected)
    }
}
