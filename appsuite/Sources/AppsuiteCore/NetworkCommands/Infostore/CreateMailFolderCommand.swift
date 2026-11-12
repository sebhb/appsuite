import Foundation

class CreateMailFolderCommand: NetworkCommand<CreateFolderResponse> {

    let remoteSession: RemoteSession
    let folderName: String
    /// Full ID of the parent folder, e.g. `default0` (account root) or
    /// `default0/INBOX`. Child IDs are server-defined, so always pass an ID the
    /// server returned rather than one assembled from folder names.
    let parentID: String

    init(session: RemoteSession, folderName: String, parentID: String = "default0") {
        self.remoteSession = session
        self.folderName = folderName
        self.parentID = parentID
        super.init(serverInfo: remoteSession.serverInfo)
    }

    override func method() -> AppsuiteHTTPMethod {
        .Put
    }

    override func requestParameters() -> [String : String] {
        return ["action": "new", "autorename": "true", "folder_id": parentID, "session": remoteSession.session]
    }

    override func oxFunction() -> String {
        return "appsuite/api/folders"
    }

    override func requestDictionary() -> [String: AnyObject]? {
        return ["module": "mail", "subscribed": "1", "title": folderName, "silent": "false"] as [String: AnyObject]
    }

}
