import Foundation

/// Reference to a single mail as used in request bodies of the mail module
/// (`archive`, `delete`, ...).
struct MailListElement: Codable {
    let id: String
    let folder: String
}

/// One entry of the `mail?action=archive` response: an archive folder the
/// mails were moved into, and whether the server had to create it.
struct ArchiveFolderResult: Decodable {
    let id: String
    let created: Bool?
}

struct ArchiveMailsResponse: Decodable {
    let data: [ArchiveFolderResult]
}
