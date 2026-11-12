import Foundation
import Testing
@testable import AppsuiteCore

@Suite struct MailCommandRequestTests {

    private let session = TestSupport.session

    // MARK: Import

    @Test func importBuildsOneFilePartPerMail() throws {
        let mails = ["first mail", "second mail", "third mail"].map { Data($0.utf8) }
        let command = ImportMailCommand(session: session, mails: mails, folder: "INBOX/Projects")
        let body = try #require(String(data: command.requestData(), encoding: .utf8))

        let parts = body.components(separatedBy: "--\(command.boundary)\r\n").dropFirst()
        #expect(parts.count == 3)
        for (part, text) in zip(parts, ["first mail", "second mail", "third mail"]) {
            #expect(part.contains("Content-Disposition: form-data; name=\"file\"; filename=\""))
            #expect(part.contains(".eml\"\r\n"))
            #expect(part.contains("Content-Type: message/rfc822\r\n"))
            #expect(part.contains("\r\n\r\n\(text)\r\n"))
        }
        #expect(body.hasSuffix("--\(command.boundary)--\r\n"))
        #expect(command.postContentType() == "multipart/form-data; boundary=\(command.boundary)")
    }

    @Test func importTargetsTheFolderBelowTheAccount() {
        let params = ImportMailCommand(session: session, mailData: Data(), folder: "INBOX/Projects").requestParameters()
        #expect(params["action"] == "import")
        #expect(params["folder"] == "default0/INBOX/Projects")
        #expect(params["session"] == "test-session")
    }

    @Test func importDefaultsToInbox() {
        #expect(ImportMailCommand(session: session, mailData: Data()).requestParameters()["folder"] == "default0/INBOX")
    }

    @Test(arguments: [
        (0, 30),                        // tiny payload: base timeout
        (1_048_576, 40),                // 1 MB
        (8 * 1_048_576, 110),           // default batch size
        (100 * 1_048_576, 300),         // capped
    ] as [(Int, Int64)])
    func importTimeoutScalesWithPayload(bytes: Int, expected: Int64) {
        let command = ImportMailCommand(session: session, mails: [Data(count: bytes)])
        #expect(command.requestTimeoutSeconds() == expected)
    }

    // MARK: Archive / delete

    @Test func archiveAsksServerToCreateTheFolder() throws {
        let command = ArchiveMailsCommand(session: session, mails: [MailListElement(id: "42", folder: "default0/INBOX")])
        #expect(command.method() == .Put)
        #expect(command.oxFunction() == "appsuite/api/mail")
        #expect(command.requestParameters() == ["action": "archive", "useDefaultName": "true", "createIfAbsent": "true", "session": "test-session"])
        #expect(command.usesRequestDictionary() == false)
        let body = try TestSupport.jsonObject(command.requestData()) as? [[String: String]]
        #expect(body == [["id": "42", "folder": "default0/INBOX"]])
    }

    @Test func deleteMailsIsPermanent() throws {
        let command = DeleteMailsCommand(session: session, mails: [MailListElement(id: "7", folder: "default0/Archive/2026")])
        #expect(command.method() == .Put)
        #expect(command.requestParameters()["action"] == "delete")
        #expect(command.requestParameters()["harddelete"] == "true")
        let body = try TestSupport.jsonObject(command.requestData()) as? [[String: String]]
        #expect(body == [["id": "7", "folder": "default0/Archive/2026"]])
    }

    @Test func deleteFoldersIsPermanent() throws {
        let command = DeleteFoldersCommand(session: session, folderIDs: ["default0/Archive/2026"])
        #expect(command.method() == .Put)
        #expect(command.oxFunction() == "appsuite/api/folders")
        #expect(command.requestParameters()["action"] == "delete")
        #expect(command.requestParameters()["hardDelete"] == "true")
        #expect(try TestSupport.jsonObject(command.requestData()) as? [String] == ["default0/Archive/2026"])
    }

    @Test func getMailsRequestsIdAndSubject() throws {
        let command = GetMailsCommand(session: session, folder: "default0/Archive/2026")
        #expect(command.method() == .Get)
        #expect(command.requestParameters()["action"] == "all")
        #expect(command.requestParameters()["folder"] == "default0/Archive/2026")
        #expect(command.requestParameters()["columns"] == "600,607")

        let response = Data(#"{"data":[["1","Hello"],["2",null],[null,"no id"]]}"#.utf8)
        let mails = try #require(try command.result(from: response))
        #expect(mails.map(\.id) == ["1", "2"])
        #expect(mails.map(\.subject) == ["Hello", nil])
    }

    @Test func archiveResponseDecodes() throws {
        let json = Data(#"{"data":[{"id":"default0/Archive/2026","created":true},{"id":"default0/Archive"}]}"#.utf8)
        let response = try JSONDecoder().decode(ArchiveMailsResponse.self, from: json)
        #expect(response.data.map(\.id) == ["default0/Archive/2026", "default0/Archive"])
        #expect(response.data.map(\.created) == [true, nil])
    }

    // MARK: Folder commands

    @Test func createMailFolderUsesTheGivenParent() throws {
        let command = CreateMailFolderCommand(session: session, folderName: "Alpha", parentID: "default0/INBOX/Projects")
        #expect(command.requestParameters()["folder_id"] == "default0/INBOX/Projects")
        #expect(command.requestDictionary()?["title"] as? String == "Alpha")
        #expect(command.requestDictionary()?["module"] as? String == "mail")
        #expect(CreateMailFolderCommand(session: session, folderName: "X").requestParameters()["folder_id"] == "default0")
    }

    @Test func listSubfoldersCanIncludeUnsubscribed() {
        #expect(GetSubfoldersCommand(folder: "default0", session: session).requestParameters()["all"] == nil)
        #expect(GetSubfoldersCommand(folder: "default0", session: session, includeUnsubscribed: true).requestParameters()["all"] == "1")
    }
}
