import Foundation

class LogoutCommand: NetworkCommand<EmptyResponse> {

    let remoteSession: RemoteSession

    init(session: RemoteSession) {
        self.remoteSession = session
        super.init(serverInfo: session.serverInfo)
    }

    override func method() -> AppsuiteHTTPMethod {
        .Get
    }

    override func requestParameters() -> [String : String] {
        return ["action": "logout", "session": remoteSession.session]
    }
    
    override func oxFunction() -> String {
        return "appsuite/api/login"
    }

}
