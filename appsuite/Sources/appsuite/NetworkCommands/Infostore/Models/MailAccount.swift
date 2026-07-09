import Foundation

/// The primary mail account (`default0`) as returned by the `account` module.
///
/// The `*_fullname` fields carry the *actual* server-side names of the standard
/// folders. These are locale- and configuration-dependent (e.g. the sent folder
/// may be "Sent", "Sent Items" or "INBOX/Sent"), which is why they must be
/// discovered from the server rather than guessed by name.
struct MailAccount: Decodable {
    let sentFullname: String?
    let trashFullname: String?
    let draftsFullname: String?
    let spamFullname: String?
    let archiveFullname: String?
}

struct GetMailAccountResponse: Decodable {
    let data: MailAccount
}
