import Foundation

class NewPersonWithoutAvatarCommand: NetworkCommand<ContactCreationResponse> {

    let remoteSession: RemoteSession
    let newPerson: NewPerson

    init(session: RemoteSession, newPerson: NewPerson) {
        self.remoteSession = session
        self.newPerson = newPerson
        super.init(serverInfo: session.serverInfo)
    }

    override func method() -> AppsuiteHTTPMethod {
        .Put
    }

    override func requestParameters() -> [String : String] {
        return ["action": "new", "session": remoteSession.session]
    }

    override func oxFunction() -> String {
        return "appsuite/api/addressbooks"
    }

    override func usesRequestDictionary() -> Bool {
        return false
    }

    override func requestData() -> Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(newPerson)
    }

}
