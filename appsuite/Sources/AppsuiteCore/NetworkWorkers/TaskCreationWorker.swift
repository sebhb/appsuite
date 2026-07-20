import Foundation

class TaskCreationWorker: InfostoreBaseWorker {

    var tasksRootFolder: String!

    func createTasks(_ taskCreationRequests: [TaskRequest], onProgress: ProgressHandler = { _ in }) async throws {
        try await login()
        try await getUserSettings()

        let total = taskCreationRequests.count
        for (index, request) in taskCreationRequests.enumerated() {
            let creationRequest = TaskCreationRequest.from(request, folderId: tasksRootFolder)
            let creationCommand = CreateTaskCommand(session: remoteSession, task: creationRequest)
            guard let _ = try await creationCommand.execute() else {
                onProgress(.failed("tasks", "Could not create task \(index + 1) of \(total)."))
                return
            }
            onProgress(.progress("tasks", current: index + 1, total: total, "Created task \(index + 1) of \(total)"))
        }

        try await logout()
    }

    private func getUserSettings() async throws {
        let getRootFolderCommand = GetConfigurationCommand(session: remoteSession, property: .tasksFolder)
        guard let rootFolder = try await getRootFolderCommand.execute() else {
            print("Could not acquire root folder.")
            return
        }
        tasksRootFolder = rootFolder.data
    }

}
