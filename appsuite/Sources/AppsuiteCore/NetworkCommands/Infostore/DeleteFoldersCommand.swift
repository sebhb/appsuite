import Foundation

/// Permanently deletes folders (`PUT folders?action=delete&hardDelete=true`).
class DeleteFoldersCommand: NetworkCommand<EmptyResponse> {

    let remoteSession: RemoteSession
    let folderIDs: [String]

    init(session: RemoteSession, folderIDs: [String]) {
        self.remoteSession = session
        self.folderIDs = folderIDs
        super.init(serverInfo: session.serverInfo)
    }

    override func method() -> AppsuiteHTTPMethod {
        .Put
    }

    override func requestParameters() -> [String : String] {
        return ["action": "delete", "hardDelete": "true", "session": remoteSession.session]
    }

    override func oxFunction() -> String {
        return "appsuite/api/folders"
    }

    override func usesRequestDictionary() -> Bool {
        false
    }

    override func requestData() -> Data? {
        try! JSONEncoder().encode(folderIDs)
    }

}
