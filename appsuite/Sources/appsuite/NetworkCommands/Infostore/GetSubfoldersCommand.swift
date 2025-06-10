import Foundation

class GetSubfoldersCommand: NetworkCommand<[Subfolder]> {

    let remoteSession: RemoteSession
    let folder: String

    init(folder: String, session: RemoteSession) {
        self.remoteSession = session
        self.folder = folder
        super.init(serverAddress: remoteSession.server)
    }

    override func method() -> HTTPMethod {
        .Get
    }

    override func requestParameters() -> [String : String] {
        return ["action": "list", "columns": "1,300", "parent": folder, "session": remoteSession.session]
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
