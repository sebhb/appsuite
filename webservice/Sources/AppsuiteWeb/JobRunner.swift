import Foundation
import AppsuiteCore

/// Owns running seed jobs. Each job streams `ProgressEvent`s over an
/// `AsyncStream`; the SSE route consumes that stream. Execution runs in a
/// detached task so long network work never blocks the actor.
actor JobRunner {

    private var streams: [String: AsyncStream<ProgressEvent>] = [:]
    private let demo = DemoData.fromEnvironment()

    func accounts() -> [String] { demo.listGoldAccounts() }
    func demoAvailable() -> Bool { demo.isAvailable }

    /// Creates a job, kicks off execution, and returns its id.
    func start(_ request: RunRequest) -> String {
        let jobId = UUID().uuidString
        let (stream, continuation) = AsyncStream<ProgressEvent>.makeStream()
        streams[jobId] = stream
        let demo = self.demo
        Task.detached {
            await JobRunner.execute(request, demo: demo, continuation: continuation)
        }
        return jobId
    }

    /// Creates a delete-appointments job and returns its id.
    func startDeleteAppointments(_ credentials: CredentialsDTO, years: Int) -> String {
        let jobId = UUID().uuidString
        let (stream, continuation) = AsyncStream<ProgressEvent>.makeStream()
        streams[jobId] = stream
        Task.detached {
            await JobRunner.executeDelete(credentials: credentials, years: years, continuation: continuation)
        }
        return jobId
    }

    /// Hands out a job's event stream. Removing it makes the stream single-use.
    func takeStream(_ jobId: String) -> AsyncStream<ProgressEvent>? {
        streams.removeValue(forKey: jobId)
    }

    private static func executeDelete(credentials: CredentialsDTO, years: Int, continuation: AsyncStream<ProgressEvent>.Continuation) async {
        let service = AppsuiteService()
        let onProgress: ProgressHandler = { continuation.yield($0) }
        defer {
            continuation.yield(.finished("_run", "All done."))
            continuation.finish()
        }
        do {
            try await service.deleteAppointments(credentials.toCredentials, years: years, onProgress: onProgress)
        } catch {
            continuation.yield(.failed("delete", "\(error)"))
        }
    }

    // MARK: - Execution

    private static func execute(_ request: RunRequest, demo: DemoData, continuation: AsyncStream<ProgressEvent>.Continuation) async {
        let service = AppsuiteService()
        let creds = request.credentials.toCredentials
        let onProgress: ProgressHandler = { continuation.yield($0) }

        let workDir = FileManager.default.temporaryDirectory.appendingPathComponent("appsuite-seed-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: workDir)
            continuation.yield(.finished("_run", "All done."))
            continuation.finish()
        }

        // Mails
        if let sel = request.mails, sel.enabled {
            do {
                if sel.isUpload {
                    let paths = try writeUploads(sel.files, to: workDir.appendingPathComponent("mails"))
                    try await service.importMails(creds, mailPaths: paths, targetFolder: "INBOX", createFolder: false, adjustRecipient: false, stretchPeriod: nil, onProgress: onProgress)
                } else {
                    let account = sel.account ?? demo.listGoldAccounts().first ?? ""
                    let tree = demo.goldAccountTree(account).path
                    try await service.importMailTree(creds, treeRoot: tree, adjustRecipient: DemoData.Recipe.mailAdjustRecipient, stretchPeriod: DemoData.Recipe.mailStretchPeriodDays, onProgress: onProgress)
                }
            } catch { continuation.yield(.failed("mails", "\(error)")) }
        }

        // Contacts
        if let sel = request.contacts, sel.enabled {
            do {
                if sel.isUpload {
                    let path = try writeSingleUpload(sel.files, to: workDir.appendingPathComponent("contacts"))
                    try await service.importContacts(creds, jsonPath: path, onProgress: onProgress)
                } else {
                    try await service.generateContacts(creds, templatesPath: demo.contactTemplatesJSON.path, count: DemoData.Recipe.numberOfContacts, onProgress: onProgress)
                }
            } catch { continuation.yield(.failed("contacts", "\(error)")) }
        }

        // Appointments
        if let sel = request.appointments, sel.enabled {
            do {
                if sel.isUpload {
                    let path = try writeSingleUpload(sel.files, to: workDir.appendingPathComponent("appointments"))
                    try await service.importAppointments(creds, jsonPath: path, onProgress: onProgress)
                } else {
                    try await service.generateAppointments(creds, templatesPath: demo.appointmentTemplatesJSON.path, days: DemoData.Recipe.appointmentDays, locale: DemoData.Recipe.appointmentLocale, onProgress: onProgress)
                }
            } catch { continuation.yield(.failed("appointments", "\(error)")) }
        }

        // Tasks
        if let sel = request.tasks, sel.enabled {
            do {
                let path = sel.isUpload
                    ? try writeSingleUpload(sel.files, to: workDir.appendingPathComponent("tasks"))
                    : demo.tasksJSON.path
                try await service.importTasks(creds, jsonPath: path, onProgress: onProgress)
            } catch { continuation.yield(.failed("tasks", "\(error)")) }
        }

        // Files (Drive) — preflight the Drive capability, skip on absence.
        if let sel = request.files, sel.enabled {
            do {
                continuation.yield(.started("files", "Checking whether Drive is enabled…"))
                let enabled = try await service.checkDriveEnabled(creds)
                if !enabled {
                    continuation.yield(.failed("files", "Drive is not enabled for this user — skipping file upload."))
                } else {
                    let paths: [String]
                    if sel.isUpload {
                        paths = try writeUploads(sel.files, to: workDir.appendingPathComponent("files"))
                    } else {
                        paths = childPaths(of: demo.testfilesDir)
                    }
                    try await service.importFiles(creds, paths: paths, onProgress: onProgress)
                }
            } catch { continuation.yield(.failed("files", "\(error)")) }
        }
    }

    // MARK: - Upload helpers

    /// Writes uploaded (base64) files into `dir` and returns their paths.
    /// File names are reduced to their last path component to prevent traversal.
    private static func writeUploads(_ files: [UploadedFile]?, to dir: URL) throws -> [String] {
        guard let files, !files.isEmpty else { return [] }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var paths: [String] = []
        for file in files {
            let safeName = (file.name as NSString).lastPathComponent
            guard !safeName.isEmpty, let data = Data(base64Encoded: file.base64) else { continue }
            let dest = dir.appendingPathComponent(safeName)
            try data.write(to: dest)
            paths.append(dest.path)
        }
        return paths
    }

    /// Like `writeUploads` but expects exactly one file and returns its path.
    private static func writeSingleUpload(_ files: [UploadedFile]?, to dir: URL) throws -> String {
        let paths = try writeUploads(files, to: dir)
        guard let first = paths.first else {
            throw SeedError.noUpload
        }
        return first
    }

    /// The full paths of the (non-dotfile) children of a directory.
    private static func childPaths(of dir: URL) -> [String] {
        let contents = (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
        return contents.filter { !$0.hasPrefix(".") }.map { dir.appendingPathComponent($0).path }
    }

    enum SeedError: Error { case noUpload }
}
