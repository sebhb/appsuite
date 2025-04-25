import Foundation

class UploadFileCommand: NetworkCommand<UploadFileCommandResponse> {

    let session: RemoteSession
    let filename: String
    let targetFolderId: String
    let fileContents: Data
    let boundary: String = "----Boundary-\(UUID().uuidString)"

    init(session: RemoteSession, filename: String, fileContents: Data, targetfolderId: String) {
        self.session = session
        self.filename = filename
        self.targetFolderId = targetfolderId
        self.fileContents = fileContents
        super.init(serverAddress: session.server)
    }

    override func method() -> HTTPMethod {
        .Post
    }

    override func postContentType() -> String {
        return "multipart/form-data; boundary=" + boundary
    }

    override func requestParameters() -> [String : String] {
        return ["action": "new", "extendedResponse": "true", "force_json_response": "true", "session": session.session]
    }

    override func usesRequestDictionary() -> Bool {
        return false
    }

    override func requestData() -> Data {
        let target = UploadTarget(folder_id: targetFolderId, description: "")
        let targetPart = Multipart(name: "json", content: target)

        let filePart = Multipart(name: "file", filename: filename, content: fileContents)

        let data = try! [targetPart, filePart].multipartFormData(boundary: boundary)

        return data
    }

    override func oxFunction() -> String {
        return "appsuite/api/files"
    }

}

struct UploadTarget: Encodable {
    let folder_id: String
    let description: String
}
