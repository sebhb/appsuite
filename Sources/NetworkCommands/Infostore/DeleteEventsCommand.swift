import Foundation

class DeleteEventsCommand: NetworkCommand<DeletedEventsResponse> {

    let remoteSession: RemoteSession
    let events: GetEventsResponse

    init(session: RemoteSession, events: GetEventsResponse) {
        self.remoteSession = session
        self.events = events
        super.init(serverAddress: remoteSession.server)
    }

    override func method() -> HTTPMethod {
        .Put
    }

    override func requestParameters() -> [String : String] {
        return ["action": "delete", "scheduling": "none", "timestamp": "\(events.timestamp)", "session": remoteSession.session]
    }

    override func oxFunction() -> String {
        return "appsuite/api/chronos"
    }

    override func usesRequestDictionary() -> Bool {
        return false
    }

    override func requestData() -> Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(events.data)
    }

}
