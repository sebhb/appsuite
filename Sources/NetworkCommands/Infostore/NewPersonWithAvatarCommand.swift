import Foundation

class NewPersonWithAvatarCommand: NetworkCommand<ContactCreationResponse> {

    let remoteSession: RemoteSession
    let newPerson: NewPerson
    let avatarData: Data
    let avatarContentType: String
    let boundary: String = "----Boundary-\(UUID().uuidString)"

    init(session: RemoteSession, newPerson: NewPerson, avatarData: Data, contentType: String) {
        self.remoteSession = session
        self.newPerson = newPerson
        self.avatarData = avatarData
        self.avatarContentType = contentType
        super.init(serverAddress: remoteSession.server)
    }

    override func method() -> HTTPMethod {
        .Post
    }

    override func postContentType() -> String {
        return "multipart/form-data; boundary=" + boundary
    }

    override func requestParameters() -> [String : String] {
        return ["action": "new", "force_json_response": "true", "session": remoteSession.session]
    }

    override func oxFunction() -> String {
        return "appsuite/api/addressbooks"
    }

    override func usesRequestDictionary() -> Bool {
        return false
    }

    override func requestData() -> Data? {
        let picturePart = Multipart(name: "file", filename: "cropped.jpeg", contentType: avatarContentType, content: avatarData)
        let jsonPart = Multipart(name: "json", contentType: "application/json", content: newPerson)
        return try? [picturePart, jsonPart].multipartFormData(boundary: boundary)
    }

}
