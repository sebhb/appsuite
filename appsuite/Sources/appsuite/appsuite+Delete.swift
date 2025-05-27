import ArgumentParser
import Foundation

extension Appsuite {

    struct Delete: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "delete", abstract: "Delete operations.", subcommands: [DeleteAppointments.self])
    }

    struct DeleteAppointments: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "appointments", abstract: "Delete all events in a user's calendar.", discussion: "Deletes all events in a user's calendar in the time range of one year in the past to one year in the future. This does NOT send mail notifications to participants.")

        @OptionGroup var userCredentialsOptions: UserCredentialsOptions
        @OptionGroup var deleteOptions: DeleteAppointmentsOptions

        mutating func run() async throws {
            do {
                let deleteEventsWorker = DeleteEventsWorker(userCredentialsOptions: userCredentialsOptions)
                try await deleteEventsWorker.deleteEvents(years: deleteOptions.years)
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }

}

