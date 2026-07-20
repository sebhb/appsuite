import Foundation

class DeleteEventsCommand: NetworkCommand<DeletedEventsResponse> {

    let remoteSession: RemoteSession
    let events: GetEventsResponse

    init(session: RemoteSession, events: GetEventsResponse) {
        self.remoteSession = session
        self.events = events
        super.init(serverInfo: remoteSession.serverInfo)
    }

    override func method() -> AppsuiteHTTPMethod {
        .Put
    }

    override func requestParameters() -> [String : String] {
        // The chronos `all` response may omit a timestamp; fall back to "now"
        // (milliseconds), which is after the events' last modification and so
        // passes the server's concurrent-modification check.
        let timestamp = events.timestamp ?? Int64(Date().timeIntervalSince1970 * 1000)
        return ["action": "delete", "scheduling": "none", "timestamp": "\(timestamp)", "session": remoteSession.session]
    }

    override func oxFunction() -> String {
        return "appsuite/api/chronos"
    }

    // Bulk deletes can take a while server-side; allow more than the default.
    override func requestTimeoutSeconds() -> Int64 {
        120
    }

    override func usesRequestDictionary() -> Bool {
        return false
    }

    override func requestData() -> Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(events.data)
    }

}
