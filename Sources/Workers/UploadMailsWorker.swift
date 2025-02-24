//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 24.02.25.
//

import Foundation

class UploadMailsWorker {

    let userCredentialsOptions: UserCredentialsOptions
    var remoteSession: RemoteSession!

    init(userCredentialsOptions: UserCredentialsOptions) {
        self.userCredentialsOptions = userCredentialsOptions
    }

    func uploadMails(paths: [String]) async throws {
        try await login()

        for mailPath in paths {
            let importMailCommand = ImportMailCommand(session: remoteSession, mailPath: mailPath)
            guard let _ = try await importMailCommand.execute() else {
                print("Could not upload mail.")
                return
            }
        }

        try await logout()
    }

    private func login() async throws {
        let loginCommand = LoginCommand(userName: userCredentialsOptions.userName, password: userCredentialsOptions.password, serverAddress: userCredentialsOptions.server)

        guard let session = try await loginCommand.execute() else {
            print("Could not acquire session.")
            return
        }
        remoteSession = RemoteSession(session: session.session, server: userCredentialsOptions.server)
    }

    private func logout() async throws {
        let logoutCommand = LogoutCommand(session: remoteSession)
        guard let _ = try await logoutCommand.execute() else {
            print("Could not acquire session.")
            return
        }
        remoteSession = nil
    }

}
