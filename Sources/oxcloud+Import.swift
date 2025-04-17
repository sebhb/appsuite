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
        static let configuration = CommandConfiguration(commandName: "import", abstract: "Import operations.", subcommands: [ImportMails.self, ImportAppointment.self, ImportFiles.self, ImportTasks.self])
    }

    struct ImportMails: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "mails", abstract: "Upload an email for a user.", discussion: "Uploads all eml files in `source` to the specified user's inbox. This command does not validate whether there is enough quoata available.")

        @OptionGroup var userCredentialsOptions: UserCredentialsOptions
        @OptionGroup var pathOptions: ImportPathOptions
        @OptionGroup var importMailOptions: ImportMailOptions
        @OptionGroup var importStretchOptions: ImportStretchOptions

        mutating func run() async throws {
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: pathOptions.path).filter { $0.hasSuffix(".eml") }.map( { pathOptions.path + "/" + $0 } )
                guard files.count > 0 else {
                    print(".eml files not found in \(pathOptions.path)")
                    return
                }

                let uploadMailsWorker = UploadMailsWorker(userCredentialsOptions: userCredentialsOptions, adjustrecipient: importMailOptions.adjustRecipient, stretchPeriod: importStretchOptions.stretchPeriod)
                try await uploadMailsWorker.uploadMails(paths: files)
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }

    struct ImportAppointment: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "appointments", abstract: "Creates appointments.", discussion: """
            Create appointments. The `source` points to a file containing an array of JSON objects describing the appointments to be created.
            The description for an appointment looks like this:
            {
                "title": "Title",
                "description": "Description",
                "startTime": "20250219T200000",
                "endTime": "20250219T210000",
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

    struct ImportFiles: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "files", abstract: "Uploads Files.", discussion: "Uploads all files at `source` to the specified user's Drive root folder. This command does not do any validation whether the user has Drive capabilities enabled or whether there is enough quoata available. Also, this does not import hierarchies. It simply uploads all files at the specified path without traversing any subdirectories.")

        @OptionGroup var userCredentialsOptions: UserCredentialsOptions
        @OptionGroup var pathOptions: ImportPathOptions

        mutating func run() async throws {
            let uploadFilesWorker = UploadFilesWorker(userCredentialsOptions: userCredentialsOptions)
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: pathOptions.path).filter { !$0.hasPrefix(".") }.map( { pathOptions.path + "/" + $0 } )
                guard files.count > 0 else {
                    print("No files not found in \(pathOptions.path)")
                    return
                }

                try await uploadFilesWorker.uploadFiles(files)
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }

    struct ImportTasks: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "tasks", abstract: "Creates Tasks.", discussion: """
            Create Tasks. The `source` points to a file containing an array of JSON objects describing the tasks to be created.
            The description for a task looks like this:
            {
                "title": "Title",
                "note": "A note",
                "percentComplete": 50
            }
            Note that `note` and `percentComplete` are optional values while `title` is required.
            """)

        @OptionGroup var userCredentialsOptions: UserCredentialsOptions
        @OptionGroup var pathOptions: ImportPathOptions

        mutating func run() async throws {
            let taskCreationWorker = TaskCreationWorker(userCredentialsOptions: userCredentialsOptions)
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: pathOptions.path))
                let jsonDecoder = JSONDecoder()
                let tasks: [TaskRequest] = try jsonDecoder.decode([TaskRequest].self, from: data)

                try await taskCreationWorker.createTasks(tasks)
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }
}
