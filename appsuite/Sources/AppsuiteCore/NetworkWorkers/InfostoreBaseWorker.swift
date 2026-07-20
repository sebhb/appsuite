import Foundation

class InfostoreBaseWorker {

    let credentials: Credentials
    var remoteSession: RemoteSession!

    init(credentials: Credentials) {
        self.credentials = credentials
    }

    func login() async throws {
        let cookieJar = CookieJar()
        let serverInfo = ServerInfo(serverAddress: credentials.server, cookieJar: cookieJar, certificateVerification: credentials.validateCertificate)
        let loginCommand = LoginCommand(userName: credentials.userName, password: credentials.password, serverInfo: serverInfo)

        guard let session = try await loginCommand.execute() else {
            print("Could not acquire session.")
            return
        }
        remoteSession = RemoteSession(session: session.session, server: credentials.server, cookieJar: cookieJar)
    }

    func logout() async throws {
        let logoutCommand = LogoutCommand(session: remoteSession)
        guard let _ = try await logoutCommand.execute() else {
            print("Could not acquire session.")
            return
        }
        remoteSession = nil
    }
    
}
