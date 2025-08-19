import Foundation

class CreateDriveFolderCommand: NetworkCommand<CreateFolderResponse> {

    let remoteSession: RemoteSession
    let folderName: String
    let parentID: String

    init(session: RemoteSession, folderName: String, parentID: String) {
        self.remoteSession = session
        self.folderName = folderName
        self.parentID = parentID
        super.init(serverInfo: remoteSession.serverInfo)
    }

    override func method() -> AppsuiteHTTPMethod {
        .Put
    }

    override func requestParameters() -> [String : String] {
        return ["action": "new", "folder_id": parentID, "session": remoteSession.session]
    }

    override func oxFunction() -> String {
        return "appsuite/api/folders"
    }

    override func requestDictionary() -> [String: AnyObject]? {
        return ["module": "infostore", "title": folderName] as [String: AnyObject]
    }

}
