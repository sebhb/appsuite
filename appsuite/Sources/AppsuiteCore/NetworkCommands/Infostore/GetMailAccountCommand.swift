import Foundation

/// Fetches the primary mail account (`default0`) so its standard folder
/// full-names (Sent, Trash, Drafts, Spam, Archive) can be discovered instead of
/// being looked up by a hard-coded name.
class GetMailAccountCommand: NetworkCommand<GetMailAccountResponse> {

    let remoteSession: RemoteSession

    init(session: RemoteSession) {
        self.remoteSession = session
        super.init(serverInfo: session.serverInfo)
    }

    override func method() -> AppsuiteHTTPMethod {
        .Get
    }

    override func requestParameters() -> [String : String] {
        return ["action": "get", "id": "0", "session": remoteSession.session]
    }

    override func oxFunction() -> String {
        return "appsuite/api/account/"
    }

}
