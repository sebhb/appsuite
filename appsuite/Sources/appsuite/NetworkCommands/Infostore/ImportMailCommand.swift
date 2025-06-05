import Foundation

class ImportMailCommand: MultipartNetworkCommand<ImportMailResponse> {

    let session: RemoteSession
    let mailData: Data
    let folder: String

    init(session: RemoteSession, mailData: Data, folder: String? = nil) {
        self.session = session
        self.mailData = mailData
        self.folder = folder ?? "INBOX"
        super.init(serverAddress: session.server)
    }

    override func requestParameters() -> [String : String] {
        return ["action": "import", "folder": "default0/" + folder, "force": "true", "force_json_response": "true", "session": session.session]
    }

    override func requestData() -> Data {
        let multipart = Multipart(name: "file", filename: "\(UUID().uuidString).eml", contentType: "message/rfc822", content: mailData)
        return try! [multipart].multipartFormData(boundary: boundary)
    }

    override func oxFunction() -> String {
        return "appsuite/api/mail"
    }

}
