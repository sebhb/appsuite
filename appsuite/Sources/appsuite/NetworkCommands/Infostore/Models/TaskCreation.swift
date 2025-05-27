import Foundation

struct TaskRequest: Decodable {
    let title: String
    let note: String?
    let percentComplete: Int?
}

struct TaskCreationRequest: Encodable {
    let title: String
    let note: String?
    let folderId: String
    let percentComplete: Int?

    /// * 1 (not started)
    /// * 2 (in progress)
    /// * 3 (done)
    /// * 4 (waiting)
    /// * 5 (deferred)
    let status: Int

    static func from(_ taskRequest: TaskRequest, folderId: String) -> TaskCreationRequest {
        let status = taskRequest.percentComplete ?? 0 == 0 ? 1 : 2
        return TaskCreationRequest(title: taskRequest.title, note: taskRequest.note, folderId: folderId, percentComplete: taskRequest.percentComplete, status: status)
    }
}

struct TaskIdentifier: Decodable {
    let id: Int
}

struct CreateTaskResponse: Decodable {
    let data: TaskIdentifier
}
