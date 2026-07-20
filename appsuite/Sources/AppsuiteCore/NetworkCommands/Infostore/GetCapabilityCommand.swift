import Foundation

/// Queries a single capability for the logged-in user, e.g. `drive`.
///
/// The capabilities endpoint answers with `{ "data": { "id": "drive", ... } }`
/// when the capability is present. When it is absent the `data` is missing, so
/// callers treat a missing/mismatched `id` as "not enabled".
class GetCapabilityCommand: NetworkCommand<CapabilityResponse> {

    let remoteSession: RemoteSession
    let capabilityId: String

    init(session: RemoteSession, capabilityId: String) {
        self.remoteSession = session
        self.capabilityId = capabilityId
        super.init(serverInfo: remoteSession.serverInfo)
    }

    override func method() -> AppsuiteHTTPMethod {
        .Get
    }

    override func requestParameters() -> [String : String] {
        return ["action": "get", "id": capabilityId, "session": remoteSession.session]
    }

    override func oxFunction() -> String {
        return "appsuite/api/capabilities"
    }

    // A missing capability comes back as data (or an error body), not a thrown
    // server error — decode it and let the worker decide.
    override func validatesForServerErrors() -> Bool {
        false
    }

}
