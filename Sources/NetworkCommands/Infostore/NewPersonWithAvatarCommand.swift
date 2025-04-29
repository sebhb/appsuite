import Foundation

class NewPersonWithAvatarCommand: MultipartNetworkCommand<ContactCreationResponse> {

    let remoteSession: RemoteSession
    let newPerson: NewPerson
    let avatarData: Data
    let avatarContentType: String

    init(session: RemoteSession, newPerson: NewPerson, avatarData: Data, contentType: String) {
        self.remoteSession = session
        self.newPerson = newPerson
        self.avatarData = avatarData
        self.avatarContentType = contentType
        super.init(serverAddress: remoteSession.server)
    }

    override func requestParameters() -> [String : String] {
        return ["action": "new", "force_json_response": "true", "session": remoteSession.session]
    }

    override func oxFunction() -> String {
        return "appsuite/api/addressbooks"
    }

    override func requestData() -> Data? {
        let picturePart = Multipart(name: "file", filename: "cropped.jpeg", contentType: avatarContentType, content: avatarData)
        let jsonPart = Multipart(name: "json", contentType: "application/json", content: newPerson)
        return try? [picturePart, jsonPart].multipartFormData(boundary: boundary)
    }

}
