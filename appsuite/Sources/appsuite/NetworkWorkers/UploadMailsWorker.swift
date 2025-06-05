import Foundation

class UploadMailsWorker: InfostoreBaseWorker {

    let adjustRecipient: Bool
    let stretchPeriod: Int?
    var recipient: Person?

    init(userCredentialsOptions: UserCredentialsOptions, adjustrecipient: Bool = false, stretchPeriod: Int? = nil) {
        self.adjustRecipient = adjustrecipient
        self.stretchPeriod = stretchPeriod
        super.init(userCredentialsOptions: userCredentialsOptions)
    }

    func prepare() async throws {
        try await login()
        try await getUserSettings()
    }

    func uploadMails(paths: [String], to folder: String) async throws {
        guard var mails = try loadMails(from: paths) else { return }

        let mailRecipient = adjustRecipient ? self.recipient!.email1 : nil
        if (mailRecipient != nil) || (stretchPeriod != nil) {
            let modifyWorker = EmailImportModifier(mails: mails, recipient: mailRecipient, stretchPeriod: stretchPeriod)
            mails = modifyWorker.alteredMails()
        }

        for mail in mails {
            try await uploadMail(mail, to: folder)
        }
    }

    func ensureTargetFolderExists(_ folder: String) async throws -> String {
        if try await !validateExistenceOfTargetFolder(folder) {
            return try await createFolder(folder)
        }
        return folder
    }

    // Returns the folder name should it have been renamed by the server
    func createFolder(_ folderName: String) async throws -> String {
        let createFolderCommand = CreateMailFolderCommand(session: remoteSession, folderName: folderName)
        guard let result = try? await createFolderCommand.execute() else {
            return folderName
        }
        let components = result.data.split(separator: "/", maxSplits: 1)
        let finalName = components.count > 1 ? components[1] : ""
        return String(finalName)
    }

    /// Returns `true` is the folder exists, otherwise `false`.
    func validateExistenceOfTargetFolder(_ folder: String) async throws -> Bool {
        let checkCommand = CheckMailFolderExistsCommand(session: remoteSession, targetFolder: folder)
        
        let result = try await checkCommand.execute()
        if let errorCode = result?.code, errorCode == "IMAP-1002" {
            return false
        }
        return true
    }

    private func loadMails(from paths: [String]) throws -> [Data]? {
        var mails: [Data] = []
        
        for mailPath in paths {
            guard let mailData = try? Data(contentsOf: URL(fileURLWithPath: mailPath)) else { continue }
            mails.append(mailData)
        }
        return mails
    }

    private func uploadMail(_ mailData: Data, to folder: String) async throws {
        let importMailCommand = ImportMailCommand(session: remoteSession, mailData: mailData, folder: folder)
        guard let _ = try await importMailCommand.execute() else {
            print("Could not upload mail.")
            return
        }
    }

    private func getUserSettings() async throws {
        guard adjustRecipient else { return }

        let getMeCommand = GetMeCommand(session: remoteSession)
        guard let me = try await getMeCommand.execute() else {
            print("Could not acquire calendar.")
            return
        }
        recipient = me.data
    }
    
}
