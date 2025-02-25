//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 25.02.25.
//

import Foundation

class TaskCreationWorker: InfostoreBaseWorker {

    var tasksRootFolder: String!

    func createTasks(_ taskCreationRequests: [TaskRequest]) async throws {
        try await login()
        try await getUserSettings()

        for request in taskCreationRequests {
            let creationRequest = TaskCreationRequest.from(request, folderId: tasksRootFolder)
            let creationCommand = CreateTaskCommand(session: remoteSession, task: creationRequest)
            guard let _ = try await creationCommand.execute() else {
                print("Could not create task.")
                return
            }
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
