import Foundation

class GetEventsCommand: NetworkCommand<GetEventsResponse> {

    let remoteSession: RemoteSession

    init(session: RemoteSession) {
        self.remoteSession = session
        super.init(serverAddress: remoteSession.server)
    }

    override func method() -> HTTPMethod {
        .Get
    }

    override func requestParameters() -> [String : String] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss"

        let now = Date()
        let rangeStartDate = Calendar.current.date(byAdding: .year, value: -1, to: now)!
        let rangeEndDate = Calendar.current.date(byAdding: .year, value: 1, to: now)!

        let rangeStart = dateFormatter.string(from: rangeStartDate)
        let rangeEnd = dateFormatter.string(from: rangeEndDate)

        return ["action": "all", "fields": "id,folder", "rangeStart": rangeStart, "rangeEnd": rangeEnd, "session": remoteSession.session]
    }

    override func oxFunction() -> String {
        return "appsuite/api/chronos/"
    }

}
