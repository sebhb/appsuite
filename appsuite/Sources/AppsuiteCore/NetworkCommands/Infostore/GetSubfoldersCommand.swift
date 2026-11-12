import Foundation

class GetSubfoldersCommand: NetworkCommand<[Subfolder]> {

    let remoteSession: RemoteSession
    let folder: String
    /// Also list folders the user is not subscribed to (`all=1`).
    let includeUnsubscribed: Bool

    init(folder: String, session: RemoteSession, includeUnsubscribed: Bool = false) {
        self.remoteSession = session
        self.folder = folder
        self.includeUnsubscribed = includeUnsubscribed
        super.init(serverInfo: session.serverInfo)
    }

    override func method() -> AppsuiteHTTPMethod {
        .Get
    }

    override func requestParameters() -> [String : String] {
        var parameters = ["action": "list", "columns": "1,300", "parent": folder, "session": remoteSession.session]
        if includeUnsubscribed {
            parameters["all"] = "1"
        }
        return parameters
    }

    override func oxFunction() -> String {
        return "appsuite/api/folders/"
    }

    override func result(from data: Data) throws -> [Subfolder]? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let columnsResponse = try decoder.decode(GetColumnsResponse.self, from: data)
        let subfolders = columnsResponse.data

        let result = subfolders.map() {
            let id = $0[0]!
            let title = $0[1]!
            return Subfolder(id: id, title: title)
        }

        return result
    }

}
