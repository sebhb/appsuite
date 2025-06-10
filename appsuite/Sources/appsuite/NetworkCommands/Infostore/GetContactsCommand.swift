import Foundation

class GetContactsCommand: NetworkCommand<[Person]> {

    let remoteSession: RemoteSession
    let folder: String

    init(folder: String, session: RemoteSession) {
        self.remoteSession = session
        self.folder = folder
        super.init(serverAddress: remoteSession.server)
    }

    override func method() -> HTTPMethod {
        .Get
    }

    override func requestParameters() -> [String : String] {
        return ["action": "all", "columns": "1,501,502,500,555", "folder": folder, "session": remoteSession.session]
    }

    override func oxFunction() -> String {
        return "appsuite/api/contacts/"
    }

    override func result(from data: Data) throws -> [Person]? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let contactsArray = try decoder.decode(GetColumnsResponse.self, from: data)
        let contacts = contactsArray.data

        let result = contacts.map() {
            let firstName = $0[1]
            let lastName = $0[2]
            let displayName = $0[3] ?? ""
            let email1 = $0[4] ?? ""
            let id = Int($0[0] ?? "0") ?? 0
            return Person(firstName: firstName, lastName: lastName, displayName: displayName, userId: id, email1: email1)
        }

        return result
    }

}
