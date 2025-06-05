import Foundation

/*

 "error": "Mail folder \"DUMPSTER\" could not be found on mail server 127.0.0.1.",
 "error_params": [
 "DUMPSTER",
 "127.0.0.1",
 "7@12162226",
 7,
 12162226
 ],
 "categories": "USER_INPUT",
 "category": 1,
 "code": "IMAP-1002",
 "error_id": "2054513928-58684204",
 "error_desc": "Mail folder \"DUMPSTER\" could not be found on mail server 127.0.0.1 with login 7@12162226 (user=7, context=12162226)."
 */

struct MailFolderExaminationError: Decodable {
    let error: String?
    let code: String?
}
