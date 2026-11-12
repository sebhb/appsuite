import Foundation

/// The public entry point shared by both front-ends (the CLI and the web
/// service). Every operation mirrors what `Demo/demo.sh` does on the command
/// line, but reports progress through a `ProgressHandler` so callers can render
/// live feedback. Errors propagate; callers decide whether to continue with the
/// next operation.
public struct AppsuiteService: Sendable {

    /// How requests reach the server; tests substitute a fake App Suite.
    let transport: any HTTPTransport

    public init() {
        self.init(transport: AsyncHTTPClientTransport())
    }

    init(transport: any HTTPTransport) {
        self.transport = transport
    }

    // MARK: Drive capability

    /// Logs in, checks the `drive` capability, logs out, and returns the result.
    public func checkDriveEnabled(_ credentials: Credentials) async throws -> Bool {
        try await CapabilityWorker(credentials: credentials, transport: transport).driveEnabled()
    }

    // MARK: Mails

    /// Imports a mail folder tree: every subdirectory of `treeRoot` (at any depth)
    /// becomes a target folder with the same hierarchy. Top-level standard
    /// folders are resolved to their real server names, everything else is
    /// created as needed. Mirrors `--importFolderTree`.
    public func importMailTree(_ credentials: Credentials, treeRoot: String, adjustRecipient: Bool, stretchPeriod: Int?, batchLimits: MailBatchLimits = .default, onProgress: @escaping ProgressHandler) async throws {
        onProgress(.started("mails", "Importing mail folder tree"))
        let uploads = try mailUploadsForTree(at: treeRoot)
        guard !uploads.isEmpty else {
            onProgress(.finished("mails", "No mail folders with .eml files found — nothing to import."))
            return
        }

        let worker = UploadMailsWorker(credentials: credentials, adjustrecipient: adjustRecipient, stretchPeriod: stretchPeriod, batchLimits: batchLimits, transport: transport)
        try await worker.prepare()
        for upload in uploads {
            let folder: String
            do {
                folder = try await worker.ensureTargetFolderPath(upload.targetFolder, onProgress: onProgress)
            } catch {
                // Skip this folder (and its mails) but keep importing the rest.
                onProgress(.failed("mails", "Skipping \(upload.targetFolder.joined(separator: "/")): \(error)"))
                continue
            }
            try await worker.uploadMails(paths: upload.mailPaths, to: folder, onProgress: onProgress)
        }
        try await worker.logout()
        onProgress(.finished("mails", "Mail import complete."))
    }

    /// Imports a flat set of `.eml` files into a single target folder.
    public func importMails(_ credentials: Credentials, mailPaths: [String], targetFolder: String = "INBOX", createFolder: Bool = false, adjustRecipient: Bool, stretchPeriod: Int?, batchLimits: MailBatchLimits = .default, onProgress: @escaping ProgressHandler) async throws {
        onProgress(.started("mails", "Importing \(mailPaths.count) mail(s) into \(targetFolder)"))
        let worker = UploadMailsWorker(credentials: credentials, adjustrecipient: adjustRecipient, stretchPeriod: stretchPeriod, batchLimits: batchLimits, transport: transport)
        try await worker.prepare()
        let folder = createFolder ? try await worker.ensureTargetFolderExists(targetFolder, onProgress: onProgress) : targetFolder
        try await worker.uploadMails(paths: mailPaths, to: folder, onProgress: onProgress)
        try await worker.logout()
        onProgress(.finished("mails", "Mail import complete."))
    }

    // MARK: Files

    /// Uploads files (and folder hierarchies) to the user's Drive root.
    public func importFiles(_ credentials: Credentials, paths: [String], onProgress: @escaping ProgressHandler) async throws {
        onProgress(.started("files", "Uploading files to Drive"))
        try await UploadFilesWorker(credentials: credentials, transport: transport).uploadFiles(paths, onProgress: onProgress)
        onProgress(.finished("files", "File upload complete."))
    }

    // MARK: Tasks

    /// Imports tasks from a JSON file (array of `{title, note?, percentComplete?}`).
    public func importTasks(_ credentials: Credentials, jsonPath: String, onProgress: @escaping ProgressHandler) async throws {
        onProgress(.started("tasks", "Importing tasks"))
        let tasks: [TaskRequest] = try decodeJSON(at: jsonPath)
        try await TaskCreationWorker(credentials: credentials, transport: transport).createTasks(tasks, onProgress: onProgress)
        onProgress(.finished("tasks", "Task import complete."))
    }

    // MARK: Contacts

    /// Generates `count` contacts from a templates JSON file (bundled demo data).
    public func generateContacts(_ credentials: Credentials, templatesPath: String, count: Int, onProgress: @escaping ProgressHandler) async throws {
        onProgress(.started("contacts", "Generating \(count) contacts"))
        let templates: [ContactTemplate] = try decodeJSON(at: templatesPath)
        let generator = ContactGenerator(numberOfContacts: count, contactTemplates: templates, basePath: templatesPath.removingLastPathComponent())
        let requests = generator.generateContacts()
        try await PersonCreationWorker(credentials: credentials, transport: transport).createPersons(requests, onProgress: onProgress)
        onProgress(.finished("contacts", "Contact generation complete."))
    }

    /// Imports contacts from a JSON file (array of `NewPersonRequest`).
    public func importContacts(_ credentials: Credentials, jsonPath: String, onProgress: @escaping ProgressHandler) async throws {
        onProgress(.started("contacts", "Importing contacts"))
        let requests: [NewPersonRequest] = try decodeJSON(at: jsonPath)
        let withAvatars = requests.map { NewPersonWithAvatar.from($0, basePath: jsonPath.removingLastPathComponent()) }
        try await PersonCreationWorker(credentials: credentials, transport: transport).createPersons(withAvatars, onProgress: onProgress)
        onProgress(.finished("contacts", "Contact import complete."))
    }

    // MARK: Appointments

    /// Generates appointments over `days` from a templates JSON file (bundled).
    public func generateAppointments(_ credentials: Credentials, templatesPath: String, days: Int, locale localeId: String, onProgress: @escaping ProgressHandler) async throws {
        onProgress(.started("appointments", "Generating appointments over \(days) days"))
        let contacts = try await GetContactsWorker(credentials: credentials, transport: transport).getContacts()
        let templates: [AppointmentTemplate] = try decodeJSON(at: templatesPath)
        let locale = Locale(identifier: localeId)
        let generator = AppointmentGenerator.generator(days: days, appointmentDesciptions: templates, contacts: contacts, locale: locale)
        let requests = generator.generateAppointments()
        try await AppointmentCreationWorker(credentials: credentials, transport: transport).createAppointments(appointmentRequests: requests, onProgress: onProgress)
        onProgress(.finished("appointments", "Appointment generation complete."))
    }

    /// Imports appointments from a JSON file (array of `AppointmentRequest`).
    public func importAppointments(_ credentials: Credentials, jsonPath: String, onProgress: @escaping ProgressHandler) async throws {
        onProgress(.started("appointments", "Importing appointments"))
        let requests: [AppointmentRequest] = try decodeJSON(at: jsonPath)
        try await AppointmentCreationWorker(credentials: credentials, transport: transport).createAppointments(appointmentRequests: requests, onProgress: onProgress)
        onProgress(.finished("appointments", "Appointment import complete."))
    }

    // MARK: Delete

    /// Deletes every appointment within ±`years` of today, **without** sending
    /// cancellation notifications to participants (unlike deleting by hand in the
    /// App Suite UI, which would email everyone involved).
    public func deleteAppointments(_ credentials: Credentials, years: Int, onProgress: @escaping ProgressHandler) async throws {
        onProgress(.started("delete", "Deleting appointments within ±\(years) year(s)"))
        try await DeleteEventsWorker(credentials: credentials, transport: transport).deleteEvents(years: years, onProgress: onProgress)
        onProgress(.finished("delete", "Appointment deletion complete."))
    }

    // MARK: - Helpers

    private func decodeJSON<T: Decodable>(at path: String) throws -> T {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try JSONDecoder().decode(T.self, from: data)
    }

    struct MailUpload {
        /// Folder path relative to the tree root, outermost first.
        let targetFolder: [String]
        let mailPaths: [String]
    }

    private func emlPaths(at path: String) -> [String] {
        let files = (try? FileManager.default.contentsOfDirectory(atPath: path)) ?? []
        return files.filter { $0.hasSuffix(".eml") }.map { path.appendingPathComponent($0) }
    }

    /// Walks the tree below `rootPath` recursively. Every directory containing
    /// `.eml` files becomes one upload; directories without mails are only
    /// created as needed for their descendants. Parents sort before children.
    func mailUploadsForTree(at rootPath: String) throws -> [MailUpload] {
        var result = [MailUpload]()

        func visit(_ path: String, components: [String]) throws {
            let children = try FileManager.default.contentsOfDirectory(atPath: path)
                .filter { !$0.hasPrefix(".") }
                .sorted()
            for child in children {
                let childPath = path.appendingPathComponent(child)
                var isDirectory: ObjCBool = false
                guard FileManager.default.fileExists(atPath: childPath, isDirectory: &isDirectory), isDirectory.boolValue else { continue }
                let childComponents = components + [child]
                let mails = emlPaths(at: childPath)
                if !mails.isEmpty {
                    result.append(MailUpload(targetFolder: childComponents, mailPaths: mails))
                }
                try visit(childPath, components: childComponents)
            }
        }

        try visit(rootPath, components: [])
        return result
    }
}
