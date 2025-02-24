//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 24.02.25.
//

import Foundation

class UploadFilesWorker {

    let userCredentialsOptions: UserCredentialsOptions
    var remoteSession: RemoteSession!
    var driveRootFolder: String!

    init(userCredentialsOptions: UserCredentialsOptions) {
        self.userCredentialsOptions = userCredentialsOptions
    }

    func uploadFiles(_ paths: [String]) async throws {
        try await login()
        try await getUserSettings()

        for file in paths {
            guard let fileContents = try? Data(contentsOf: URL(fileURLWithPath: file)), fileContents.count > 0 else {
                print("Could not read file \(file) - This could be a directory. Skipping.")
                continue
            }
            let filename = file.components(separatedBy: "/").last!
            let uploadFileCommand = UploadFileCommand(session: remoteSession, filename: filename, fileContents: fileContents, targetfolderId: driveRootFolder)
            guard let _ = try await uploadFileCommand.execute() else {
                print("Could not upload file.")
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

    private func getUserSettings() async throws {
        let getRootFolderCommand = GetConfigurationCommand(session: remoteSession, property: .driveRootFolder)
        guard let rootFolder = try await getRootFolderCommand.execute() else {
            print("Could not acquire root folder.")
            return
        }
        driveRootFolder = rootFolder.data
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
