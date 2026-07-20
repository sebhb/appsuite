import Foundation

class PersonCreationWorker: InfostoreBaseWorker {

    var addressbookRootFolder: String!

    func createPersons(_ personCreationRequests: [NewPersonWithAvatar], onProgress: ProgressHandler = { _ in }) async throws {
        try await login()
        try await getUserSettings()

        let total = personCreationRequests.count
        for (index, request) in personCreationRequests.enumerated() {
            let creationRequest = NewPerson.from(request, folder: addressbookRootFolder)

            let avatarData = request.avatarData
            let imageKind = request.avatarContentType

            if let avatarData, let imageKind {
                let creationCommand = NewPersonWithAvatarCommand(session: remoteSession, newPerson: creationRequest, avatarData: avatarData, contentType: imageKind.contentType())
                guard let _ = try await creationCommand.execute() else {
                    onProgress(.failed("contacts", "Could not create contact \(index + 1) of \(total)."))
                    return
                }
            }
            else {
                let creationCommand = NewPersonWithoutAvatarCommand(session: remoteSession, newPerson: creationRequest)
                guard let _ = try await creationCommand.execute() else {
                    onProgress(.failed("contacts", "Could not create contact \(index + 1) of \(total)."))
                    return
                }
            }
            onProgress(.progress("contacts", current: index + 1, total: total, "Created contact \(index + 1) of \(total)"))
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
