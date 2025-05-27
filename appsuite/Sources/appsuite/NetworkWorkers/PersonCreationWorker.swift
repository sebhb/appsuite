import Foundation

class PersonCreationWorker: InfostoreBaseWorker {

    var addressbookRootFolder: String!

    func createPersons(_ personCreationRequests: [NewPersonWithAvatar]) async throws {
        try await login()
        try await getUserSettings()

        for request in personCreationRequests {
            let creationRequest = NewPerson.from(request, folder: addressbookRootFolder)

            let avatarData = request.avatarData
            let imageKind = request.avatarContentType

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
