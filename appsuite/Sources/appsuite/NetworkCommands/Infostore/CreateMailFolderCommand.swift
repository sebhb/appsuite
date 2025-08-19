import Foundation

class CreateMailFolderCommand: NetworkCommand<CreateFolderResponse> {

    let remoteSession: RemoteSession
    let folderName: String

    init(session: RemoteSession, folderName: String) {
        self.remoteSession = session
        self.folderName = folderName
        super.init(serverInfo: remoteSession.serverInfo)
    }

    override func method() -> AppsuiteHTTPMethod {
        .Put
    }

    override func requestParameters() -> [String : String] {
        return ["action": "new", "autorename": "true", "folder_id": "default0", "session": remoteSession.session]
    }

    override func oxFunction() -> String {
        return "appsuite/api/folders"
    }

    override func requestDictionary() -> [String: AnyObject]? {
        return ["module": "mail", "subscribed": "1", "title": folderName, "silent": "false"] as [String: AnyObject]
    }

}
