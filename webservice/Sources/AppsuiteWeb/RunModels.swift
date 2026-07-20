import Foundation
import AppsuiteCore

/// Connection details submitted from the browser.
struct CredentialsDTO: Codable, Sendable {
    let server: String
    let userName: String
    let password: String
    let validateCertificate: Bool

    var toCredentials: Credentials {
        Credentials(server: server, userName: userName, password: password, validateCertificate: validateCertificate)
    }
}

/// A file the user uploaded for a category, transported as base64 inside JSON so
/// the whole request is a single JSON body (no multipart parsing needed).
struct UploadedFile: Codable, Sendable {
    let name: String
    let base64: String
}

/// One category's selection in a run request. `source` is "bundled" (use the
/// baked-in demo data) or "upload" (use `files`). `account` names the gold
/// account for bundled mails.
struct CategorySelection: Codable, Sendable {
    let enabled: Bool
    let source: String
    let account: String?
    let files: [UploadedFile]?

    var isUpload: Bool { source == "upload" }
}

/// The full run request: credentials plus per-category selections. A missing or
/// disabled category is skipped.
struct RunRequest: Codable, Sendable {
    let credentials: CredentialsDTO
    let mails: CategorySelection?
    let contacts: CategorySelection?
    let appointments: CategorySelection?
    let tasks: CategorySelection?
    let files: CategorySelection?
}

/// Request to delete all appointments within ±`years` of today.
struct DeleteAppointmentsRequest: Codable, Sendable {
    let credentials: CredentialsDTO
    let years: Int
}

struct RunStartedResponse: Codable, Sendable {
    let jobId: String
}

struct DriveCheckResponse: Codable, Sendable {
    let enabled: Bool
}

struct ConfigResponse: Codable, Sendable {
    let accounts: [String]
    let demoAvailable: Bool
}
