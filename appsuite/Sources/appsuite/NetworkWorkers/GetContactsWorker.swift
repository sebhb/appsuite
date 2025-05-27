import Foundation

class GetContactsWorker: InfostoreBaseWorker {

    var addressbookRootFolder: String!

    func getContacts() async throws -> [Person] {
        try await login()
        try await getUserSettings()

        let getContactsCommand = GetContactsCommand(folder: addressbookRootFolder, session: remoteSession)
        let contacts: [Person] = try await getContactsCommand.execute() ?? []

        try await logout()

        return contacts
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
