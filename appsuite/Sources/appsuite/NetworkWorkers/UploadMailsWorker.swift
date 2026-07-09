import Foundation

class UploadMailsWorker: InfostoreBaseWorker {

    let adjustRecipient: Bool
    let stretchPeriod: Int?
    var recipient: Person?

    /// Maps a standard folder role (see `standardRole(for:)`) to the actual
    /// server-side folder name, discovered from the mail account. Empty when
    /// discovery failed, in which case everything falls back to name lookup.
    private var standardFolders: [StandardFolderRole: String] = [:]

    init(userCredentialsOptions: UserCredentialsOptions, adjustrecipient: Bool = false, stretchPeriod: Int? = nil) {
        self.adjustRecipient = adjustrecipient
        self.stretchPeriod = stretchPeriod
        super.init(userCredentialsOptions: userCredentialsOptions)
    }

    func prepare() async throws {
        try await login()
        try await getUserSettings()
        await discoverStandardFolders()
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

    /// Resolves the folder to actually upload into and makes sure it exists.
    ///
    /// If `folder` names a standard folder (Sent, Trash, ...), its server-side
    /// name discovered from the mail account is returned and no creation is
    /// attempted — those folders always exist and creating them is rejected as a
    /// reserved name. Only genuinely custom folders go through examine/create.
    func ensureTargetFolderExists(_ folder: String) async throws -> String {
        if let role = standardRole(for: folder), let serverFolder = standardFolders[role] {
            return serverFolder
        }
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

    /// Best-effort discovery of the standard folders' real server-side names.
    /// On any failure the map stays empty and callers fall back to name lookup.
    private func discoverStandardFolders() async {
        let command = GetMailAccountCommand(session: remoteSession)
        guard let account = try? await command.execute()?.data else { return }

        func store(_ role: StandardFolderRole, _ fullname: String?) {
            guard let fullname, !fullname.isEmpty else { return }
            // Folder full-names are relative to the account; the import/examine
            // commands prepend "default0/" themselves, so strip it if present.
            let normalized = fullname.hasPrefix("default0/")
                ? String(fullname.dropFirst("default0/".count))
                : fullname
            standardFolders[role] = normalized
        }

        store(.inbox, "INBOX")
        store(.sent, account.sentFullname)
        store(.trash, account.trashFullname)
        store(.drafts, account.draftsFullname)
        store(.spam, account.spamFullname)
        store(.archive, account.archiveFullname)
    }

    /// Classifies a local export directory name into a standard folder role,
    /// independent of the server's localized/renamed target. Returns `nil` for
    /// custom folders, which keep going through examine/create.
    private func standardRole(for folder: String) -> StandardFolderRole? {
        switch folder.lowercased() {
            case "inbox":
                return .inbox
            case "sent", "sent items", "sent messages":
                return .sent
            case "trash", "deleted", "deleted items", "deleted messages":
                return .trash
            case "drafts", "draft":
                return .drafts
            case "spam", "junk", "junk e-mail", "junk email":
                return .spam
            case "archive":
                return .archive
            default:
                return nil
        }
    }

}

enum StandardFolderRole {
    case inbox
    case sent
    case trash
    case drafts
    case spam
    case archive
}
