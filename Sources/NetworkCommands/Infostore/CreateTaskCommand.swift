import Foundation

class CreateTaskCommand: NetworkCommand<CreateTaskResponse> {

    let remoteSession: RemoteSession
    let task: TaskCreationRequest

    init(session: RemoteSession, task: TaskCreationRequest) {
        self.remoteSession = session
        self.task = task
        super.init(serverAddress: remoteSession.server)
    }

    override func method() -> HTTPMethod {
        .Put
    }

    override func requestParameters() -> [String : String] {
        return ["action": "new", "session": remoteSession.session]
    }

    override func oxFunction() -> String {
        return "appsuite/api/tasks"
    }

    override func usesRequestDictionary() -> Bool {
        return false
    }

    override func requestData() -> Data? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return try! encoder.encode(task)
    }

}
