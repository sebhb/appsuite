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
        static let configuration = CommandConfiguration(commandName: "import", abstract: "Import operations.", subcommands: [ImportMails.self, ImportAppointment.self])
    }

    struct ImportMails: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "mails", abstract: "Upload an email for a user.")

        @OptionGroup var userCredentialsOptions: UserCredentialsOptions
        @OptionGroup var pathOptions: ImportPathOptions

        mutating func run() async throws {
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: pathOptions.path).filter { $0.hasSuffix(".eml") }.map( { pathOptions.path + "/" + $0 } )
                guard files.count > 0 else {
                    print(".eml files not found in \(pathOptions.path)")
                    return
                }

                let loginCommand = LoginCommand(userName: userCredentialsOptions.userName, password: userCredentialsOptions.password, serverAddress: userCredentialsOptions.server)

                guard let session = try await loginCommand.execute() else {
                    print("Could not acquire session.")
                    return
                }
                let remoteSession = RemoteSession(session: session.session, server: userCredentialsOptions.server)

                for mailPath in files {
                    let importMailCommand = ImportMailCommand(session: remoteSession, mailPath: mailPath)
                    guard let _ = try await importMailCommand.execute() else {
                        print("Could not upload mail.")
                        return
                    }
                }
                let logoutCommand = LogoutCommand(session: remoteSession)
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

    struct ImportAppointment: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "appointment", abstract: "Creates appointments.", discussion: """
            Create appointments. The `source` points to a file containing an array of JSON objects describing the appointments to be created.
            The description for an appointment looks like this:
            {
                "title": "Title"
                "descrpition": "Description"
                "startTime": "20250219T200000"
                "endTime": "20250219T210000"
                "location": "Location"
            }
            Note that `description` and `location` are optional values while `title`, `startTime` and `endTime` are required.
            All times are in the user's local timezone.
            """)

        @OptionGroup var userCredentialsOptions: UserCredentialsOptions
        @OptionGroup var pathOptions: ImportPathOptions

        mutating func run() async throws {
            let appointmentCreationWorker = AppointmentCreationWorker(userCredentialsOptions: userCredentialsOptions)
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: pathOptions.path))
                let jsonDecoder = JSONDecoder()
                let appointments: [AppointmentRequest] = try jsonDecoder.decode([AppointmentRequest].self, from: data)

                try await appointmentCreationWorker.createAppointments(appointmentRequests: appointments)
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }

}
