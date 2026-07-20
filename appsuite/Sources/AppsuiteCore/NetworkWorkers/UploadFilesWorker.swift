import Foundation

class UploadFilesWorker: InfostoreBaseWorker {

    var driveRootFolder: String!

    private var onProgress: ProgressHandler = { _ in }
    private var uploadedCount = 0
    private var totalCount = 0

    func uploadFiles(_ paths: [String], onProgress: @escaping ProgressHandler = { _ in }) async throws {
        try await login()
        try await getUserSettings()

        self.onProgress = onProgress
        self.uploadedCount = 0
        self.totalCount = countFiles(paths)

        try await upload(filePaths: paths, id: driveRootFolder)

        try await logout()
    }

    /// Recursively counts the regular files under `paths` so per-file progress
    /// can report an accurate total (subfolders traversed, dotfiles ignored).
    private func countFiles(_ paths: [String]) -> Int {
        var count = 0
        for path in paths {
            if path.isDirectoryPath() {
                let children = (try? FileManager.default.contentsOfDirectory(atPath: path))?
                    .filter { !$0.hasPrefix(".") }
                    .map { path.appendingPathComponent($0) } ?? []
                count += countFiles(children)
            } else {
                count += 1
            }
        }
        return count
    }

    private func upload(filePaths: [String], id: String) async throws {
        for file in filePaths {
            if file.isDirectoryPath() {
                try await uploadDirectory(file, to: id)
                continue
            }
            guard let fileContents = try? Data(contentsOf: URL(fileURLWithPath: file)), fileContents.count > 0 else {
                onProgress(.log("files", "Could not read file '\(file)'. Skipping."))
                continue
            }
            let filename = file.components(separatedBy: FileManager.systemPathSeparator).last!
            let uploadFileCommand = UploadFileCommand(session: remoteSession, filename: filename, fileContents: fileContents, targetfolderId: id)
            guard let _ = try await uploadFileCommand.execute() else {
                onProgress(.failed("files", "Could not upload file '\(filename)'."))
                return
            }
            uploadedCount += 1
            onProgress(.progress("files", current: uploadedCount, total: totalCount, "Uploaded \(filename)"))
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
                onProgress(.failed("files", "Could not create folder '\(folderName)' under parent id '\(parentID)'."))
                return
            }
            targetFolderID = id.data
        }
        let files = try FileManager.default.contentsOfDirectory(atPath: path).filter { !$0.hasPrefix(".") }.map { path.appendingPathComponent($0) }
        guard files.count > 0 else {
            onProgress(.log("files", "No files found in \(path)"))
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
