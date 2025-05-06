import Foundation

class UploadFilesWorker: InfostoreBaseWorker {

    var driveRootFolder: String!

    func uploadFiles(_ paths: [String]) async throws {
        try await login()
        try await getUserSettings()

        for file in paths {
            guard let fileContents = try? Data(contentsOf: URL(fileURLWithPath: file)), fileContents.count > 0 else {
                print("Could not read file \(file) - This could be a directory. Skipping.")
                continue
            }
            let filename = file.components(separatedBy: "/").last!
            let uploadFileCommand = UploadFileCommand(session: remoteSession, filename: filename, fileContents: fileContents, targetfolderId: driveRootFolder)
            print("Uploading \(filename)")
            guard let _ = try await uploadFileCommand.execute() else {
                print("Could not upload file.")
                return
            }
        }

        try await logout()
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
