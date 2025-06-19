import Foundation

class UploadFilesWorker: InfostoreBaseWorker {

    var driveRootFolder: String!

    func uploadFiles(_ paths: [String]) async throws {
        try await login()
        try await getUserSettings()

        try await upload(filePaths: paths, id: driveRootFolder)

        try await logout()
    }

    private func upload(filePaths: [String], id: String) async throws {
        for file in filePaths {
            if file.isDirectoryPath() {
                try await uploadDirectory(file, to: id)
                continue
            }
            guard let fileContents = try? Data(contentsOf: URL(fileURLWithPath: file)), fileContents.count > 0 else {
                print("Could not read file '\(file)'. Skipping.")
                continue
            }
            let filename = file.components(separatedBy: FileManager.systemPathSeparator).last!
            let uploadFileCommand = UploadFileCommand(session: remoteSession, filename: filename, fileContents: fileContents, targetfolderId: id)
            print("Uploading \(filename)")
            guard let _ = try await uploadFileCommand.execute() else {
                print("Could not upload file.")
                return
            }
        }
    }

    private func uploadDirectory(_ path: String, to parentID: String) async throws {
        let folderName = path.components(separatedBy: FileManager.systemPathSeparator).last!

        // Does a subfolder with that name already exist?
        let getSubfoldersCommand = GetSubfoldersCommand(folder: parentID, session: remoteSession)
        let subfolders = try await getSubfoldersCommand.execute() ?? []

        var targetFolderID: String
        if let existingFolder = subfolders.first(where: { $0.title == folderName }) {
            targetFolderID = existingFolder.id
        }
        else {
            // Need to create it
            let createFolderCommand = CreateDriveFolderCommand(session: remoteSession, folderName: folderName, parentID: parentID)
            guard let id = try await createFolderCommand.execute() else {
                print("Could not create folder '\(folderName)' under parent id '\(parentID)'.")
                return
            }
            targetFolderID = id.data
        }
        let files = try FileManager.default.contentsOfDirectory(atPath: path).filter { !$0.hasPrefix(".") }.map { path.appendingPathComponent($0) }
        guard files.count > 0 else {
            print("No files not found in \(path)")
            return
        }
        try await upload(filePaths: files, id: targetFolderID)
    }

    private func getUserSettings() async throws {
        let getRootFolderCommand = GetConfigurationCommand(session: remoteSession, property: .driveRootFolder)
        guard let rootFolder = try await getRootFolderCommand.execute() else {
            print("Could not acquire root folder.")
            return
        }
        driveRootFolder = rootFolder.data
    }

}
