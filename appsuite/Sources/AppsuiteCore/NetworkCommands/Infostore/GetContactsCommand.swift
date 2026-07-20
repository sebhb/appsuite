import Foundation

class GetContactsCommand: NetworkCommand<[Person]> {

    let remoteSession: RemoteSession
    let folder: String

    init(folder: String, session: RemoteSession) {
        self.remoteSession = session
        self.folder = folder
        super.init(serverInfo: session.serverInfo)
    }

    override func method() -> AppsuiteHTTPMethod {
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

        let result = contacts.compactMap() { columns -> Person? in
            let firstName = columns[1]
            let lastName = columns[2]
            let displayName = columns[3] ?? ""
            let email1 = columns[4] ?? ""
            let id = Int(columns[0] ?? "0") ?? 0

            // A contact without an email address cannot be a calendar guest: it would
            // produce a `mailto:` attendee URI with no address, which App Suite 7.10.6
            // rejects with "The calendar user \"mailto:\" is invalid." Skip such contacts.
            guard !email1.isEmpty else { return nil }

            return Person(firstName: firstName, lastName: lastName, displayName: displayName, userId: id, email1: email1)
        }

        return result
    }

}
