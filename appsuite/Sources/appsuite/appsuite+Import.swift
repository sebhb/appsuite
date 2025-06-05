import ArgumentParser
import Foundation

extension Appsuite {

    struct Import: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "import", abstract: "Import operations.", subcommands: [ImportMails.self, ImportAppointment.self, ImportFiles.self, ImportTasks.self, ImportContacts.self])
    }

    struct ImportMails: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "mails", abstract: "Upload emails for a user.", discussion: """
            Uploads all eml files in `source` to the specified user's inbox. This command does not validate whether there is enough quoata available.
            If the --importFolderTree option is specified, the sourcePath is expected to point to the root of a structure like this
            
            ─── sourcePath
                ├── Drafts
                ├── DUMPSTER
                ├── INBOX
                │   ├── 70.eml
                │   └── 75.eml
                ├── Sent
                ├── Sent Items
                │   ├── 3.eml
                │   └── 4.eml
                ├── Spam
                └── Trash
            
            to upload emails to different target folders at once.
            Should importFolderTree be set, the targetFolderName option gets ignored and createTargetFolderIfNecessary is automatically set. 
            """)

        @OptionGroup var userCredentialsOptions: UserCredentialsOptions
        @OptionGroup var pathOptions: ImportPathOptions
        @OptionGroup var importMailOptions: ImportMailOptions
        @OptionGroup var importStretchOptions: ImportStretchOptions
        @OptionGroup var importFolderTree: ImportFolderTreeOption
        @OptionGroup var createTargetFolderIfNecessary: GenerateTargetFolderOption

        mutating func run() async throws {
            do {
                let path = pathOptions.resolvedPath
                let mailUploads: [MailUpload]

                if importFolderTree.importFolderTree {
                    mailUploads = try mailUploadsForTree(at: path)
                }
                else {
                    guard let files = try emlPaths(at: path) else {
                        return
                    }
                    mailUploads = [MailUpload(targetFolderName: importMailOptions.targetFolderName, mailPaths: files)]
                }

                let ensureTargetFolderExists = importFolderTree.importFolderTree ? true : createTargetFolderIfNecessary.createTargetFolderIfNecessary
                let uploadMailsWorker = UploadMailsWorker(userCredentialsOptions: userCredentialsOptions, adjustrecipient: importMailOptions.adjustRecipient, stretchPeriod: importStretchOptions.stretchPeriod)
                try await uploadMailsWorker.prepare()
                
                for upload in mailUploads {
                    let folder = upload.targetFolderName
                    let files = upload.mailPaths
                    if ensureTargetFolderExists {
                        // TODO: pass on name returned by server!
                        _ = try await uploadMailsWorker.ensureTargetFolderExists(folder)
                    }
                    try await uploadMailsWorker.uploadMails(paths: files, to: folder)
                }
                try await uploadMailsWorker.logout()
            }
            catch {
                print("An error occurred: \(error)")
            }
        }

        struct MailUpload {
            let targetFolderName: String
            let mailPaths: [String]
        }

        func emlPaths(at path: String) throws -> [String]? {
            let files = try FileManager.default.contentsOfDirectory(atPath: path).filter { $0.hasSuffix(".eml") }.map { path.appendingPathComponent($0) }
            guard files.count > 0 else {
                print(".eml files not found in \(path)")
                return nil
            }
            return files
        }

        func mailUploadsForTree(at rootPath: String) throws -> [MailUpload] {
            var result = [MailUpload]()

            let targetFolders = try FileManager.default.contentsOfDirectory(atPath: rootPath).filter { !$0.hasPrefix(".") }
            for folder in targetFolders {
                let basePath = rootPath.appendingPathComponent(folder)
                if let mailsPaths = try emlPaths(at: basePath) {
                    result.append(MailUpload(targetFolderName: folder, mailPaths: mailsPaths))
                }
            }

            return result
        }
    }

    struct ImportAppointment: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "appointments", abstract: "Creates appointments.", discussion: """
            Create appointments. The `source` points to a file containing an array of JSON objects describing the appointments to be created.
            The description for an appointment looks like this:
            {
                "title": "Title",
                "description": "Description",
                "startTime": "20250219T200000",
                "endTime": "20250219T210000",
                "location": "Location"
            }
            Note that `description` and `location` are optional values while `title`, `startTime` and `endTime` are required.
            All times are in the user's local timezone.
            """)

        @OptionGroup var userCredentialsOptions: UserCredentialsOptions
        @OptionGroup var pathOptions: ImportPathOptions

        mutating func run() async throws {
            let appointmentCreationWorker = AppointmentCreationWorker(userCredentialsOptions: userCredentialsOptions)
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: pathOptions.resolvedPath))
                let jsonDecoder = JSONDecoder()
                let appointments: [AppointmentRequest] = try jsonDecoder.decode([AppointmentRequest].self, from: data)

                try await appointmentCreationWorker.createAppointments(appointmentRequests: appointments)
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }

    struct ImportFiles: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "files", abstract: "Uploads Files.", discussion: "Uploads all files at `source` to the specified user's Drive root folder. This command does not do any validation whether the user has Drive capabilities enabled or whether there is enough quoata available. Also, this does not import hierarchies. It simply uploads all files at the specified path without traversing any subdirectories.")

        @OptionGroup var userCredentialsOptions: UserCredentialsOptions
        @OptionGroup var pathOptions: ImportPathOptions

        mutating func run() async throws {
            let uploadFilesWorker = UploadFilesWorker(userCredentialsOptions: userCredentialsOptions)
            do {
                let path = pathOptions.resolvedPath

                let files = try FileManager.default.contentsOfDirectory(atPath: path).filter { !$0.hasPrefix(".") }.map { path.appendingPathComponent($0) }
                guard files.count > 0 else {
                    print("No files not found in \(path)")
                    return
                }

                try await uploadFilesWorker.uploadFiles(files)
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }

    struct ImportTasks: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "tasks", abstract: "Creates Tasks.", discussion: """
            Create Tasks. The `source` points to a file containing an array of JSON objects describing the tasks to be created.
            The description for a task looks like this:
            {
                "title": "Title",
                "note": "A note",
                "percentComplete": 50
            }
            Note that `note` and `percentComplete` are optional values while `title` is required.
            """)

        @OptionGroup var userCredentialsOptions: UserCredentialsOptions
        @OptionGroup var pathOptions: ImportPathOptions

        mutating func run() async throws {
            let taskCreationWorker = TaskCreationWorker(userCredentialsOptions: userCredentialsOptions)
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: pathOptions.resolvedPath))
                let jsonDecoder = JSONDecoder()
                let tasks: [TaskRequest] = try jsonDecoder.decode([TaskRequest].self, from: data)

                try await taskCreationWorker.createTasks(tasks)
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }

    struct ImportContacts: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "contacts", abstract: "Creates Contacts.", discussion: """
            Create Contacts. The `source` points to a file containing an array of JSON objects describing the contacts to be created.
            The description for a contact looks like this:
            {
                "firstName": "Jon",
                "lastName": "Doe",
                "displayName": "Jon Doe",
                "email": "jon.doe@example.com",
                "streetHome": "1 Main Street",
                "postalCodeHome": "04106",
                "cityHome": "South Portland",
                "stateHome": "ME",
                "countryHome": "USA",
                "avatarPath": "jon.png"
            }

            Note that `firstName`, `lastName` and `displayName` are required values while all other values are optional.
            `avatarPath` is the relative path (from source) to an avatar. Supported formats are JPG and PNG.
            Also note that only "simple" path operations are supported. Referencing a subdirectory (e.g. "avatars/marketing/jon_doe.png") does work but traversing the hierarchy up using ".." is not supported. "~" is not evaluated, either.
            If a subdirectory is referenced, the platform's path separator has to be used.
            """)

        @OptionGroup var userCredentialsOptions: UserCredentialsOptions
        @OptionGroup var pathOptions: ImportPathOptions

        mutating func run() async throws {
            let personCreationWorker = PersonCreationWorker(userCredentialsOptions: userCredentialsOptions)
            do {
                let path = pathOptions.resolvedPath
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let jsonDecoder = JSONDecoder()
                let requests: [NewPersonRequest] = try jsonDecoder.decode([NewPersonRequest].self, from: data)
                let requestsWithAvatars = requests.map { NewPersonWithAvatar.from($0, basePath: path.removingLastPathComponent()) }
                try await personCreationWorker.createPersons(requestsWithAvatars)
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }
}
