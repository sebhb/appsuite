import Foundation

/// Imports one or more mails into a folder with a single request. The server
/// accepts several `file` parts and answers with one `{folder_id, id}` entry
/// per imported mail.
class ImportMailCommand: MultipartNetworkCommand<ImportMailResponse> {

    let session: RemoteSession
    let mails: [Data]
    let folder: String

    init(session: RemoteSession, mails: [Data], folder: String? = nil) {
        self.session = session
        self.mails = mails
        self.folder = folder ?? "INBOX"
        super.init(serverInfo: session.serverInfo)
    }

    convenience init(session: RemoteSession, mailData: Data, folder: String? = nil) {
        self.init(session: session, mails: [mailData], folder: folder)
    }

    override func requestParameters() -> [String : String] {
        return ["action": "import", "folder": "default0/" + folder, "force": "true", "force_json_response": "true", "session": session.session]
    }

    override func requestData() -> Data {
        let parts = mails.map {
            Multipart(name: "file", filename: "\(UUID().uuidString).eml", contentType: "message/rfc822", content: $0)
        }
        return try! parts.multipartFormData(boundary: boundary)
    }

    override func oxFunction() -> String {
        return "appsuite/api/mail"
    }

    // The server appends every mail to IMAP within this one request, so allow
    // more time for bigger payloads: 30 s base plus 10 s per MB, at most 5 min.
    override func requestTimeoutSeconds() -> Int64 {
        let payloadMB = Int64(mails.reduce(0) { $0 + $1.count } / 1_048_576)
        return min(30 + payloadMB * 10, 300)
    }

}
