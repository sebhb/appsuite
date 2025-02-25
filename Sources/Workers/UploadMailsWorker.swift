//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 24.02.25.
//

import Foundation

class UploadMailsWorker: InfostoreBaseWorker {

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

}
