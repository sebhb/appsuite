import Foundation

class ImportMailCommand: NetworkCommand<ImportMailResponse> {

    let session: RemoteSession
    let mailData: Data
    let boundary: String = "----Boundary-\(UUID().uuidString)"

    init(session: RemoteSession, mailData: Data) {
        self.session = session
        self.mailData = mailData
        super.init(serverAddress: session.server)
    }

    override func method() -> HTTPMethod {
        .Post
    }

    override func postContentType() -> String {
        return "multipart/form-data; boundary=" + boundary
    }

    override func requestParameters() -> [String : String] {
        return ["action": "import", "folder": "default0/INBOX", "force": "true", "session": session.session]
    }

    override func usesRequestDictionary() -> Bool {
        return false
    }

    override func requestData() -> Data {
        var data = Data()
        let boundaryPrefix = "--\(boundary)\r\n"

        data.append(boundaryPrefix.data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(UUID().uuidString).eml\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: message/rfc822\r\n\r\n".data(using: .utf8)!)
        data.append(mailData)
        data.append("\r\n".data(using: .utf8)!)
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)

        return data

    }

    override func oxFunction() -> String {
        return "appsuite/api/mail"
    }

}
