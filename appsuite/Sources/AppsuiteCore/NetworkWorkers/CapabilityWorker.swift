import Foundation

/// Checks whether a given capability (e.g. Drive) is enabled for the user:
/// logs in, queries the capability, logs out, and reports the result.
class CapabilityWorker: InfostoreBaseWorker {

    /// Returns `true` if the `drive` capability is enabled for the user.
    func driveEnabled() async throws -> Bool {
        try await isEnabled("drive")
    }

    /// Logs in, checks a single capability id, and logs out again.
    func isEnabled(_ capabilityId: String) async throws -> Bool {
        try await login()

        let command = GetCapabilityCommand(session: remoteSession, capabilityId: capabilityId)
        let response = try? await command.execute()
        let enabled = response?.data?.id == capabilityId

        try? await logout()
        return enabled
    }

}
