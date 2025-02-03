//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 03.02.25.
//

import ArgumentParser
import Foundation

extension OXCloud {

    struct Import: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "import", abstract: "Import operations.", subcommands: [ImportMails.self])
    }

    struct ImportMails: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "mails", abstract: "Upload an email for a user.")

        @OptionGroup var hostOptions: DataCenterOptions
        @OptionGroup var userCredentialsOptions: UserCredentialsOptions
        @OptionGroup var pathOptions: ImportPathOptions

        mutating func run() async throws {
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: pathOptions.path).filter { $0.hasSuffix(".eml") }.map( { pathOptions.path + "/" + $0 } )
                guard files.count > 0 else {
                    print(".eml files not found in \(pathOptions.path)")
                    return
                }

                let loginCommand = LoginCommand(userName: userCredentialsOptions.userName, password: userCredentialsOptions.password, serverAddress: hostOptions.dataCenter.hostName())

                guard let session = try await loginCommand.execute() else {
                    print("Could not acquire session.")
                    return
                }
                // print("Session: \(session.session)")

                for mailPath in files {
                    let importMailCommand = ImportMailCommand(session: session.session, mailPath: mailPath, serverAddress: hostOptions.dataCenter.hostName())
                    guard let _ = try await importMailCommand.execute() else {
                        print("Could not upload mail.")
                        return
                    }
                }
                let logoutCommand = LogoutCommand(session: session.session, serverAddress: hostOptions.dataCenter.hostName())
                guard let _ = try await logoutCommand.execute() else {
                    print("Could not acquire session.")
                    return
                }
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }
}
