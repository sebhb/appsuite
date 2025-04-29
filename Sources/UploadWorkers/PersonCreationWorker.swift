import Foundation

class PersonCreationWorker: InfostoreBaseWorker {

    var addressbookRootFolder: String!

    func createPersons(_ personCreationRequests: [NewPersonRequest], basePath: String) async throws {
        try await login()
        try await getUserSettings()

        for request in personCreationRequests {
            let creationRequest = NewPerson.from(request, folder: addressbookRootFolder)

            var avatarData: Data? = nil
            var imageKind: ImageKind? = nil
            if let avatarPath = request.avatarPath {
                if let kind = ImageKind.fromFileExtension(avatarPath.pathExtension()) {
                    imageKind = kind
#if os(Windows)
                    let pathSeparator = "\\"
#else
                    let pathSeparator = "/"
#endif
                    let avatarBasePath = basePath.removingLastPathComponent()
                    let separator = avatarBasePath.hasSuffix(pathSeparator) ? "" : pathSeparator
                    let completeAvatarPath = avatarBasePath + separator + avatarPath
                    if let data = try? Data(contentsOf: URL(fileURLWithPath: completeAvatarPath)) {
                        avatarData = data
                    }
                }
            }

            if let avatarData, let imageKind {
                let creationCommand = NewPersonWithAvatarCommand(session: remoteSession, newPerson: creationRequest, avatarData: avatarData, contentType: imageKind.contentType())
                guard let _ = try await creationCommand.execute() else {
                    print("Could not create contact.")
                    return
                }
            }
            else {
                let creationCommand = NewPersonWithoutAvatarCommand(session: remoteSession, newPerson: creationRequest)
                guard let _ = try await creationCommand.execute() else {
                    print("Could not create contact.")
                    return
                }
            }
        }

        try await logout()
    }

    private func getUserSettings() async throws {
        let getRootFolderCommand = GetConfigurationCommand(session: remoteSession, property: .addressbookFolder)
        guard let rootFolder = try await getRootFolderCommand.execute() else {
            print("Could not acquire root folder.")
            return
        }
        addressbookRootFolder = rootFolder.data
    }

}
