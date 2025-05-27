import Foundation

class InfostoreBaseWorker {

    let userCredentialsOptions: UserCredentialsOptions
    var remoteSession: RemoteSession!

    init(userCredentialsOptions: UserCredentialsOptions) {
        self.userCredentialsOptions = userCredentialsOptions
    }

    func login() async throws {
        let loginCommand = LoginCommand(userName: userCredentialsOptions.userName, password: userCredentialsOptions.password, serverAddress: userCredentialsOptions.server)

        guard let session = try await loginCommand.execute() else {
            print("Could not acquire session.")
            return
        }
        remoteSession = RemoteSession(session: session.session, server: userCredentialsOptions.server)
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
