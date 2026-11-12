import Foundation

/// Moves mails into the user's archive folder (`PUT mail?action=archive`), the
/// same call App Suite's "Archive" button uses. With `createIfAbsent` the server
/// creates the archive standard folder if the account doesn't have one yet.
class ArchiveMailsCommand: NetworkCommand<ArchiveMailsResponse> {

    let remoteSession: RemoteSession
    let mails: [MailListElement]

    init(session: RemoteSession, mails: [MailListElement]) {
        self.remoteSession = session
        self.mails = mails
        super.init(serverInfo: session.serverInfo)
    }

    override func method() -> AppsuiteHTTPMethod {
        .Put
    }

    override func requestParameters() -> [String : String] {
        return ["action": "archive", "useDefaultName": "true", "createIfAbsent": "true", "session": remoteSession.session]
    }

    override func oxFunction() -> String {
        return "appsuite/api/mail"
    }

    override func usesRequestDictionary() -> Bool {
        false
    }

    override func requestData() -> Data? {
        try! JSONEncoder().encode(mails)
    }

}
