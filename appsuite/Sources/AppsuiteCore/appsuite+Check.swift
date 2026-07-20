import ArgumentParser
import Foundation

extension Appsuite {

    struct Check: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "check", abstract: "Check operations.", subcommands: [CheckDrive.self])
    }

    struct CheckDrive: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "drive", abstract: "Check whether the Drive capability is enabled for the user.", discussion: "Logs in, queries the `drive` capability, logs out and reports the result. Exits with a non-zero status if Drive is not enabled.")

        @OptionGroup var userCredentialsOptions: UserCredentialsOptions

        mutating func run() async throws {
            let worker = CapabilityWorker(credentials: userCredentialsOptions.credentials)
            let enabled = try await worker.driveEnabled()
            if enabled {
                print("Drive is enabled.")
            } else {
                print("Drive is NOT enabled.")
                throw ExitCode.failure
            }
        }
    }

}
