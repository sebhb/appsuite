import Foundation

/// Lists the mails of a folder (`GET mail?action=all`) with their ID and subject.
class GetMailsCommand: NetworkCommand<[MailSummary]> {

    let remoteSession: RemoteSession
    let folder: String

    /// - Parameter folder: full folder ID, e.g. `default0/Archive/2026`.
    init(session: RemoteSession, folder: String) {
        self.remoteSession = session
        self.folder = folder
        super.init(serverInfo: session.serverInfo)
    }

    override func method() -> AppsuiteHTTPMethod {
        .Get
    }

    override func requestParameters() -> [String : String] {
        // 600 = id, 607 = subject
        return ["action": "all", "folder": folder, "columns": "600,607", "session": remoteSession.session]
    }

    override func oxFunction() -> String {
        return "appsuite/api/mail"
    }

    override func result(from data: Data) throws -> [MailSummary]? {
        let response = try JSONDecoder().decode(GetColumnsResponse.self, from: data)
        return response.data.compactMap { row in
            guard let id = row.first ?? nil else { return nil }
            let subject = row.count > 1 ? row[1] : nil
            return MailSummary(id: id, subject: subject)
        }
    }

}

struct MailSummary: Decodable {
    let id: String
    let subject: String?
}
