import Foundation

/// Permanently deletes mails (`PUT mail?action=delete&harddelete=true`), i.e.
/// without leaving a copy in the trash folder.
class DeleteMailsCommand: NetworkCommand<EmptyResponse> {

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
        return ["action": "delete", "harddelete": "true", "session": remoteSession.session]
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
