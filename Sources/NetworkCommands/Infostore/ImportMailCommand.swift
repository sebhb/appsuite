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
        return ["action": "import", "folder": "default0/INBOX", "force": "true", "force_json_response": "true", "session": session.session]
    }

    override func usesRequestDictionary() -> Bool {
        return false
    }

    override func requestData() -> Data {
        let multipart = Multipart(name: "file", filename: "\(UUID().uuidString).eml", contentType: "message/rfc822", content: mailData)
        return try! [multipart].multipartFormData(boundary: boundary)
    }

    override func oxFunction() -> String {
        return "appsuite/api/mail"
    }

}
