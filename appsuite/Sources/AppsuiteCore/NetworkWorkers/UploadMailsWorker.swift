import Foundation

class UploadMailsWorker: InfostoreBaseWorker {

    let adjustRecipient: Bool
    let stretchPeriod: Int?
    let batchLimits: MailBatchLimits
    var recipient: Person?

    /// Maps a standard folder role (see `standardRole(for:)`) to the actual
    /// server-side folder name, discovered from the mail account. Empty when
    /// discovery failed, in which case everything falls back to name lookup.
    private var standardFolders: [StandardFolderRole: String] = [:]

    /// Top-level folder IDs already resolved in this run, keyed by local name,
    /// so each top-level folder is looked up (and possibly created) only once.
    private var resolvedTopLevelFolders: [String: String] = [:]

    init(credentials: Credentials, adjustrecipient: Bool = false, stretchPeriod: Int? = nil, batchLimits: MailBatchLimits = .default, transport: any HTTPTransport = AsyncHTTPClientTransport()) {
        self.adjustRecipient = adjustrecipient
        self.stretchPeriod = stretchPeriod
        self.batchLimits = batchLimits
        super.init(credentials: credentials, transport: transport)
    }

    func prepare() async throws {
        try await login()
        try await getUserSettings()
        await discoverStandardFolders()
    }

    func uploadMails(paths: [String], to folder: String, onProgress: ProgressHandler = { _ in }) async throws {
        guard var mails = try loadMails(from: paths) else { return }

        let mailRecipient = adjustRecipient ? self.recipient!.email1 : nil
        if (mailRecipient != nil) || (stretchPeriod != nil) {
            let modifyWorker = EmailImportModifier(mails: mails, recipient: mailRecipient, stretchPeriod: stretchPeriod)
            mails = modifyWorker.alteredMails()
        }

        let total = mails.count
        let batches = Self.batches(mails, limits: batchLimits)
        var uploaded = 0
        for (index, batch) in batches.enumerated() {
            await uploadBatch(batch, to: folder, onProgress: onProgress)
            uploaded += batch.count
            onProgress(.progress("mails", current: uploaded, total: total, "Uploaded batch \(index + 1) of \(batches.count) (\(uploaded) of \(total) mails) into \(folder)"))
        }
    }

    /// Rough per-mail allowance for the multipart framing (boundary,
    /// Content-Disposition, Content-Type, line breaks) on top of the mail itself.
    static let multipartOverheadPerMail = 512

    /// Splits `mails` into consecutive batches, keeping their order. A new batch
    /// starts when the next mail would push the batch over `limits.maxBytes`
    /// (mail size plus `multipartOverheadPerMail`) or `limits.maxCount`. A mail
    /// that alone exceeds `maxBytes` still gets sent, as a batch of its own.
    static func batches(_ mails: [Data], limits: MailBatchLimits) -> [[Data]] {
        var result: [[Data]] = []
        var current: [Data] = []
        var currentBytes = 0
        for mail in mails {
            let size = mail.count + multipartOverheadPerMail
            if !current.isEmpty && (currentBytes + size > limits.maxBytes || current.count >= limits.maxCount) {
                result.append(current)
                current = []
                currentBytes = 0
            }
            current.append(mail)
            currentBytes += size
        }
        if !current.isEmpty {
            result.append(current)
        }
        return result
    }

    /// Imports `batch` with one request. If that request fails (e.g. a proxy
    /// rejecting the body size, a timeout, or one broken mail failing the whole
    /// request), the mails are resent one by one so a single failure doesn't
    /// lose the entire batch. Failures are reported, never thrown.
    private func uploadBatch(_ batch: [Data], to folder: String, onProgress: ProgressHandler) async {
        do {
            let response = try await ImportMailCommand(session: remoteSession, mails: batch, folder: folder).execute()
            let imported = response?.data.count ?? 0
            if imported < batch.count {
                onProgress(.log("mails", "Server confirmed \(imported) of \(batch.count) mails in this batch for \(folder)."))
            }
            return
        } catch {
            guard batch.count > 1 else {
                onProgress(.failed("mails", "Could not upload mail into \(folder): \(error)"))
                return
            }
            onProgress(.log("mails", "Batch of \(batch.count) mails into \(folder) failed (\(error)); retrying one by one."))
        }

        for (index, mail) in batch.enumerated() {
            do {
                _ = try await ImportMailCommand(session: remoteSession, mailData: mail, folder: folder).execute()
            } catch {
                onProgress(.failed("mails", "Could not upload mail \(index + 1) of \(batch.count) in this batch into \(folder): \(error)"))
            }
        }
    }

    /// Resolves the folder to actually upload into and makes sure it exists.
    ///
    /// `folder` may be a nested path using `/` (e.g. `INBOX/Projects/Alpha`);
    /// see `ensureTargetFolderPath(_:)`.
    func ensureTargetFolderExists(_ folder: String, onProgress: ProgressHandler = { _ in }) async throws -> String {
        let components = folder.split(separator: "/").map(String.init)
        return try await ensureTargetFolderPath(components, onProgress: onProgress)
    }

    /// Makes sure the folder described by `components` (outermost first) exists,
    /// creating missing levels, and returns its name relative to the account
    /// (the form the import/examine commands expect).
    ///
    /// The first component is resolved by `resolveTopLevelFolder(_:onProgress:)`.
    /// Deeper levels are looked up among the parent's children and created
    /// beneath the parent by its server-returned ID, so the server's hierarchy
    /// separator (`/` or `.`) never has to be guessed.
    func ensureTargetFolderPath(_ components: [String], onProgress: ProgressHandler = { _ in }) async throws -> String {
        guard let first = components.first else { return "INBOX" }

        var folderID = try await resolveTopLevelFolder(first, onProgress: onProgress)
        for name in components.dropFirst() {
            folderID = try await ensureChildFolder(named: name, parentID: folderID)
        }
        return Self.relativeName(of: folderID)
    }

    /// Resolves the top-level folder `name` to a full folder ID, in this order:
    /// 1. A standard folder (Sent, Archive, ...) whose server name the mail
    ///    account reported.
    /// 2. An existing folder of that name at the account root (examine).
    /// 3. For standard folders the account did *not* report (e.g. an Archive
    ///    folder the server only creates on first use): an existing folder with a
    ///    matching title at the root or below INBOX (e.g. `INBOX/Archive`).
    /// 4. For Archive only: letting the server create its archive folder the way
    ///    App Suite's "Archive" button does (see `provisionArchiveFolder`).
    /// 5. Creating it at the root. Servers reject reserved standard-folder names
    ///    there, so for standard folders a failed creation falls back to
    ///    `"<name> (imported)"` instead of losing the mails.
    private func resolveTopLevelFolder(_ name: String, onProgress: ProgressHandler) async throws -> String {
        if let cached = resolvedTopLevelFolders[name] {
            return cached
        }
        let id = try await lookUpOrCreateTopLevelFolder(name, onProgress: onProgress)
        resolvedTopLevelFolders[name] = id
        return id
    }

    private func lookUpOrCreateTopLevelFolder(_ name: String, onProgress: ProgressHandler) async throws -> String {
        let role = Self.standardRole(for: name)
        if let role, let serverFolder = standardFolders[role] {
            return Self.accountRootID + "/" + serverFolder
        }
        if try await validateExistenceOfTargetFolder(name) {
            return Self.accountRootID + "/" + name
        }
        guard let role else {
            return try await createFolder(name, parentID: Self.accountRootID)
        }

        // Standard folder the account didn't report: search before creating.
        let inboxID = Self.accountRootID + "/" + (standardFolders[.inbox] ?? "INBOX")
        for parentID in [Self.accountRootID, inboxID] {
            let match = try await findChildFolder(under: parentID) {
                $0.title.caseInsensitiveCompare(name) == .orderedSame || Self.standardRole(for: $0.title) == role
            }
            if let match {
                return match.id
            }
        }

        if role == .archive, let archiveID = await provisionArchiveFolder(onProgress: onProgress) {
            return archiveID
        }

        do {
            return try await createFolder(name, parentID: Self.accountRootID)
        } catch {
            let fallbackName = "\(name) (imported)"
            onProgress(.log("mails", "Could not create standard folder '\(name)' (\(error)); importing into '\(fallbackName)' instead."))
            if let existing = try await findChildFolder(under: Self.accountRootID, where: { $0.title == fallbackName }) {
                return existing.id
            }
            return try await createFolder(fallbackName, parentID: Self.accountRootID)
        }
    }

    /// Makes the server create the account's archive folder, which it only does
    /// when mails are archived for the first time (the folder name is reserved,
    /// so a plain folder creation is rejected):
    /// 1. import a small placeholder mail into INBOX,
    /// 2. archive it with `createIfAbsent`, the same call App Suite's "Archive"
    ///    button makes,
    /// 3. read the mail account again, which now reports the archive folder,
    /// 4. permanently delete the placeholder, and the empty subfolder (e.g. the
    ///    year folder) it was archived into.
    /// Returns the archive folder's full ID, or `nil` if any step before the
    /// cleanup failed; cleanup problems are only logged.
    private func provisionArchiveFolder(onProgress: ProgressHandler) async -> String? {
        let inbox = standardFolders[.inbox] ?? "INBOX"
        let subject = "appsuite seeder: archive folder placeholder \(UUID().uuidString)"

        onProgress(.log("mails", "The account has no archive folder yet; asking the server to create it."))

        let placeholder: MailListElement
        do {
            let response = try await ImportMailCommand(session: remoteSession, mailData: Self.placeholderMail(subject: subject), folder: inbox).execute()
            guard let entry = response?.data.first, let id = entry["id"] else {
                onProgress(.log("mails", "Could not create the archive folder: the placeholder mail was not imported."))
                return nil
            }
            placeholder = MailListElement(id: id, folder: entry["folder_id"] ?? Self.accountRootID + "/" + inbox)
        } catch {
            onProgress(.log("mails", "Could not create the archive folder: importing the placeholder mail failed (\(error))."))
            return nil
        }

        let archiveFolders: [ArchiveFolderResult]
        do {
            archiveFolders = try await ArchiveMailsCommand(session: remoteSession, mails: [placeholder]).execute()?.data ?? []
        } catch {
            onProgress(.log("mails", "Could not create the archive folder: archiving failed (\(error))."))
            await deletePlaceholder(subject: subject, in: [placeholder.folder], onProgress: onProgress)
            return nil
        }

        await discoverStandardFolders()
        let archiveID = standardFolders[.archive].map { Self.accountRootID + "/" + $0 }

        // The placeholder now sits in one of the folders the server reported.
        let usedFolders = archiveFolders.map(\.id)
        await deletePlaceholder(subject: subject, in: usedFolders.isEmpty ? [archiveID].compactMap { $0 } : usedFolders, onProgress: onProgress)
        for folder in usedFolders where folder != archiveID {
            await deleteFolderIfEmpty(folder, onProgress: onProgress)
        }

        if let archiveID {
            onProgress(.log("mails", "Created archive folder \(Self.relativeName(of: archiveID))."))
        } else {
            onProgress(.log("mails", "Archiving worked, but the account still reports no archive folder."))
        }
        return archiveID
    }

    /// Permanently deletes the placeholder mail (found by its unique subject)
    /// from whichever of `folders` contains it. Best effort; problems are logged.
    private func deletePlaceholder(subject: String, in folders: [String], onProgress: ProgressHandler) async {
        for folder in folders {
            do {
                let mails = try await GetMailsCommand(session: remoteSession, folder: folder).execute() ?? []
                let matches = mails.filter { $0.subject == subject }.map { MailListElement(id: $0.id, folder: folder) }
                guard !matches.isEmpty else { continue }
                _ = try await DeleteMailsCommand(session: remoteSession, mails: matches).execute()
                return
            } catch {
                onProgress(.log("mails", "Could not remove the archive placeholder mail from \(Self.relativeName(of: folder)) (\(error)); please delete it manually."))
                return
            }
        }
        onProgress(.log("mails", "Could not find the archive placeholder mail '\(subject)'; please delete it manually."))
    }

    /// Deletes `folder` if it holds no mails and no subfolders. Best effort.
    private func deleteFolderIfEmpty(_ folder: String, onProgress: ProgressHandler) async {
        do {
            let mails = try await GetMailsCommand(session: remoteSession, folder: folder).execute() ?? []
            let children = try await GetSubfoldersCommand(folder: folder, session: remoteSession, includeUnsubscribed: true).execute() ?? []
            guard mails.isEmpty && children.isEmpty else { return }
            _ = try await DeleteFoldersCommand(session: remoteSession, folderIDs: [folder]).execute()
        } catch {
            onProgress(.log("mails", "Could not remove the empty folder \(Self.relativeName(of: folder)) (\(error))."))
        }
    }

    /// A minimal RFC 822 mail used only to trigger archive folder creation.
    static func placeholderMail(subject: String) -> Data {
        let lines = [
            "From: Appsuite Seeder <seeder@example.com>",
            "To: seeder@example.com",
            "Subject: \(subject)",
            "Date: \(DateFormatter.mailDateFormatter.string(from: Date()))",
            "Message-ID: <\(UUID().uuidString)@example.com>",
            "MIME-Version: 1.0",
            "Content-Type: text/plain; charset=utf-8",
            "",
            "Temporary mail used to create the archive folder. It is deleted automatically and can be removed if left over.",
            "",
        ]
        return Data(lines.joined(separator: "\r\n").utf8)
    }

    /// Returns the ID of the child folder `name` of `parentID`, creating it if needed.
    private func ensureChildFolder(named name: String, parentID: String) async throws -> String {
        if let existing = try await findChildFolder(under: parentID, where: { $0.title == name }) {
            return existing.id
        }
        return try await createFolder(name, parentID: parentID)
    }

    /// First child of `parentID` (subscribed or not) matching `predicate`.
    private func findChildFolder(under parentID: String, where predicate: (Subfolder) -> Bool) async throws -> Subfolder? {
        let listCommand = GetSubfoldersCommand(folder: parentID, session: remoteSession, includeUnsubscribed: true)
        let children = try await listCommand.execute() ?? []
        return children.first(where: predicate)
    }

    /// Creates `folderName` beneath `parentID` and returns the new folder's full
    /// ID (which reflects any rename by the server).
    func createFolder(_ folderName: String, parentID: String) async throws -> String {
        let createFolderCommand = CreateMailFolderCommand(session: remoteSession, folderName: folderName, parentID: parentID)
        guard let result = try await createFolderCommand.execute() else {
            throw MailFolderCreationError(folderName: folderName, parentID: parentID)
        }
        return result.data
    }

    static let accountRootID = "default0"

    /// Strips the account prefix: `default0/INBOX/Foo` → `INBOX/Foo`.
    static func relativeName(of folderID: String) -> String {
        let prefix = accountRootID + "/"
        return folderID.hasPrefix(prefix) ? String(folderID.dropFirst(prefix.count)) : folderID
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
    static func standardRole(for folder: String) -> StandardFolderRole? {
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

struct MailFolderCreationError: Error, CustomStringConvertible {
    let folderName: String
    let parentID: String

    var description: String {
        "Could not create mail folder '\(folderName)' under '\(parentID)'."
    }
}

/// Caps for one bulk mail import request; whichever limit is hit first ends a batch.
public struct MailBatchLimits: Sendable {
    public let maxBytes: Int
    public let maxCount: Int

    public init(maxBytes: Int, maxCount: Int) {
        self.maxBytes = max(1, maxBytes)
        self.maxCount = max(1, maxCount)
    }

    public init(maxMegabytes: Int, maxCount: Int) {
        self.init(maxBytes: maxMegabytes * 1_048_576, maxCount: maxCount)
    }

    /// 8 MB / 50 mails: well below common server (100 MB) and proxy body
    /// limits, and small enough to finish within the request timeout.
    public static let `default` = MailBatchLimits(maxMegabytes: 8, maxCount: 50)
}
