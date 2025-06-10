import Foundation

class CreateDriveFolderCommand: NetworkCommand<CreateFolderResponse> {

    let remoteSession: RemoteSession
    let folderName: String
    let parentID: String

    init(session: RemoteSession, folderName: String, parentID: String) {
        self.remoteSession = session
        self.folderName = folderName
        self.parentID = parentID
        super.init(serverAddress: remoteSession.server)
    }

    override func method() -> HTTPMethod {
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
