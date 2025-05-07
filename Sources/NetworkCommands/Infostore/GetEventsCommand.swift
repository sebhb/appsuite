import Foundation

class GetEventsCommand: NetworkCommand<GetEventsResponse> {

    let remoteSession: RemoteSession
    let years: Int

    init(session: RemoteSession, years: Int) {
        self.remoteSession = session
        self.years = years
        super.init(serverAddress: remoteSession.server)
    }

    override func method() -> HTTPMethod {
        .Get
    }

    override func requestParameters() -> [String : String] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss"

        let now = Date()
        let rangeStartDate = Calendar.current.date(byAdding: .year, value: -years, to: now)!
        let rangeEndDate = Calendar.current.date(byAdding: .year, value: years, to: now)!

        let rangeStart = dateFormatter.string(from: rangeStartDate)
        let rangeEnd = dateFormatter.string(from: rangeEndDate)

        return ["action": "all", "fields": "id,folder", "rangeStart": rangeStart, "rangeEnd": rangeEnd, "session": remoteSession.session]
    }

    override func oxFunction() -> String {
        return "appsuite/api/chronos/"
    }

}
