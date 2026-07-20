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
            let progress = ProgressEvent.consolePrinter()
            let service = AppsuiteService()
            do {
                let path = pathOptions.resolvedPath
                if importFolderTree.importFolderTree {
                    try await service.importMailTree(userCredentialsOptions.credentials, treeRoot: path, adjustRecipient: importMailOptions.adjustRecipient, stretchPeriod: importStretchOptions.stretchPeriod, onProgress: progress)
                }
                else {
                    let files = try FileManager.default.contentsOfDirectory(atPath: path).filter { $0.hasSuffix(".eml") }.map { path.appendingPathComponent($0) }
                    guard files.count > 0 else {
                        print(".eml files not found in \(path)")
                        return
                    }
                    try await service.importMails(userCredentialsOptions.credentials, mailPaths: files, targetFolder: importMailOptions.targetFolderName, createFolder: createTargetFolderIfNecessary.createTargetFolderIfNecessary, adjustRecipient: importMailOptions.adjustRecipient, stretchPeriod: importStretchOptions.stretchPeriod, onProgress: progress)
                }
            }
            catch {
                print("An error occurred: \(error)")
            }
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
            do {
                try await AppsuiteService().importAppointments(userCredentialsOptions.credentials, jsonPath: pathOptions.resolvedPath, onProgress: ProgressEvent.consolePrinter())
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }

    struct ImportFiles: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "files", abstract: "Uploads Files.", discussion: "Uploads all files at `source` to the specified user's Drive root folder. This command does not do any validation whether the user has Drive capabilities enabled or whether there is enough quoata available. This does upload folder hierarchies. Any subfolders will be created if necessary and contents will be uploaded. If you want to upload files to any of the \"Standard Folders\" (Documents, Music, Pictures, Videos), remember that they might have localized names shown in the UI but their names are always English and the English names have to be used in order to populate these.")

        @OptionGroup var userCredentialsOptions: UserCredentialsOptions
        @OptionGroup var pathOptions: ImportPathOptions

        mutating func run() async throws {
            do {
                let path = pathOptions.resolvedPath

                let files = try FileManager.default.contentsOfDirectory(atPath: path).filter { !$0.hasPrefix(".") }.map { path.appendingPathComponent($0) }
                guard files.count > 0 else {
                    print("No files found in \(path)")
                    return
                }

                try await AppsuiteService().importFiles(userCredentialsOptions.credentials, paths: files, onProgress: ProgressEvent.consolePrinter())
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
            do {
                try await AppsuiteService().importTasks(userCredentialsOptions.credentials, jsonPath: pathOptions.resolvedPath, onProgress: ProgressEvent.consolePrinter())
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
            do {
                try await AppsuiteService().importContacts(userCredentialsOptions.credentials, jsonPath: pathOptions.resolvedPath, onProgress: ProgressEvent.consolePrinter())
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }
}
