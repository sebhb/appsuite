import Foundation

class CheckMailFolderExistsCommand: NetworkCommand<MailFolderExaminationError> {

    let remoteSession: RemoteSession
    let targetFolder: String

    init(session: RemoteSession, targetFolder: String) {
        self.remoteSession = session
        self.targetFolder = targetFolder
        super.init(serverAddress: remoteSession.server)
    }

    override func method() -> HTTPMethod {
        .Get
    }

    override func requestParameters() -> [String : String] {
        return ["action": "examine", "folder": "default0/" + targetFolder, "session": remoteSession.session]
    }

    override func oxFunction() -> String {
        return "appsuite/api/mail/"
    }

    override func validatesForServerErrors() -> Bool {
        false
    }

}
