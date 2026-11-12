import Foundation
@testable import AppsuiteCore

/// An in-memory stand-in for the App Suite HTTP API, covering the endpoints the
/// mail import uses. It keeps a mail folder tree and mails, records every
/// request, and lets tests switch on server behaviours (hierarchy separator,
/// a missing archive folder, rejected uploads, ...).
final class FakeAppSuite: HTTPTransport, @unchecked Sendable {

    struct Folder {
        let title: String
        let parent: String
    }

    struct Mail {
        let id: String
        let subject: String
    }

    struct RecordedRequest {
        let method: AppsuiteHTTPMethod
        let module: String
        let parameters: [String: String]
        let headers: [String: String]
        let body: Data?
        let certificateVerification: Bool

        var action: String? { parameters["action"] }
    }

    static let root = "default0"

    // MARK: Configuration (set before running)

    /// Hierarchy separator of the simulated IMAP server: "/" or ".".
    var separator = "/"
    /// Whether `mail?action=archive` works (it creates the archive folder).
    var archiveSupported = true
    /// Folder names the server refuses to create at the account root.
    var reservedNames: Set<String> = ["inbox", "sent", "trash", "drafts", "spam", "archive"]
    /// Return an HTTP error status for an import request with these subjects.
    var rejectImport: ([String]) -> Int? = { _ in nil }
    /// Drop mails from the import response (but still store them).
    var confirmFewerImports = false
    /// Refuse to create folders with these titles anywhere.
    var failingFolderTitles: Set<String> = []

    // MARK: State

    private let lock = NSLock()
    private(set) var folders: [String: Folder] = [:]
    private(set) var mails: [String: [Mail]] = [:]
    private(set) var account: [String: String] = [:]
    private(set) var requests: [RecordedRequest] = []
    private var nextMailID = 1

    init() {
        for (title, key) in [("INBOX", nil), ("Sent", "sent_fullname"), ("Trash", "trash_fullname"), ("Drafts", "drafts_fullname"), ("Spam", "spam_fullname")] {
            folders[Self.root + "/" + title] = Folder(title: title, parent: Self.root)
            if let key { account[key] = title }
        }
    }

    // MARK: Test helpers

    /// Adds a folder below `parentID` and returns its ID.
    @discardableResult
    func addFolder(_ title: String, under parentID: String = FakeAppSuite.root) -> String {
        lock.withLock { insertFolder(title, under: parentID) }
    }

    func setAccountField(_ key: String, _ value: String?) {
        lock.withLock { account[key] = value }
    }

    /// Folder ID for a path of titles below the root, e.g. ["INBOX", "Projects"].
    func folderID(_ path: [String]) -> String? {
        lock.withLock {
            var current = Self.root
            for title in path {
                guard let match = folders.first(where: { $0.value.parent == current && $0.value.title == title }) else { return nil }
                current = match.key
            }
            return current
        }
    }

    func subjects(in path: [String]) -> [String] {
        guard let id = folderID(path) else { return [] }
        return lock.withLock { (mails[id] ?? []).map(\.subject) }
    }

    func children(of path: [String]) -> [String] {
        let id = path.isEmpty ? Self.root : folderID(path)
        return lock.withLock { folders.values.filter { $0.parent == id }.map(\.title).sorted() }
    }

    var allSubjects: [String] {
        lock.withLock { mails.values.flatMap { $0.map(\.subject) } }
    }

    func requests(module: String, action: String) -> [RecordedRequest] {
        lock.withLock { requests.filter { $0.module == module && $0.action == action } }
    }

    // MARK: HTTPTransport

    func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        guard let components = URLComponents(string: request.url) else { throw URLError(.badURL) }
        let parameters = Dictionary((components.queryItems ?? []).map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { $1 })
        let module = components.path
            .replacingOccurrences(of: "/appsuite/api/", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        return lock.withLock {
            requests.append(RecordedRequest(method: request.method, module: module, parameters: parameters, headers: request.headers, body: request.body, certificateVerification: request.certificateVerification))
            return route(module: module, parameters: parameters, body: request.body)
        }
    }

    // MARK: Routing (called with the lock held)

    private func route(module: String, parameters: [String: String], body: Data?) -> HTTPResponse {
        switch (module, parameters["action"] ?? "") {
        case ("login", "login"):
            return HTTPResponse(status: 200, headers: [(name: "Set-Cookie", value: "JSESSIONID=abc123; Path=/")],
                                body: json(["session": "fake-session", "user": "1", "locale": "en_US"]))
        case ("login", "logout"):
            return ok([String]())
        case ("account", "get"):
            return ok(account)
        case ("folders", "list"):
            let parent = parameters["parent"] ?? Self.root
            let rows = folders.filter { $0.value.parent == parent }.sorted { $0.key < $1.key }.map { [$0.key, $0.value.title] }
            return ok(rows)
        case ("folders", "new"):
            return createFolder(parent: parameters["folder_id"] ?? Self.root, body: body)
        case ("folders", "delete"):
            let ids = (try? JSONDecoder().decode([String].self, from: body ?? Data())) ?? []
            for id in ids {
                folders[id] = nil
                mails[id] = nil
            }
            return ok([String]())
        case ("mail", "examine"):
            let id = parameters["folder"] ?? ""
            return folders[id] != nil ? ok(["total": mails[id]?.count ?? 0]) : error("Mail folder \"\(id)\" could not be found.", code: "IMAP-1002")
        case ("mail", "import"):
            return importMails(folder: parameters["folder"] ?? "", body: body)
        case ("mail", "archive"):
            return archive(body: body)
        case ("mail", "all"):
            let id = parameters["folder"] ?? ""
            return ok((mails[id] ?? []).map { [$0.id, $0.subject] })
        case ("mail", "delete"):
            let refs = (try? JSONDecoder().decode([MailListElement].self, from: body ?? Data())) ?? []
            for ref in refs {
                mails[ref.folder]?.removeAll { $0.id == ref.id }
            }
            return ok([String]())
        default:
            return error("Unknown action \(module)/\(parameters["action"] ?? "")", code: "SVL-0010")
        }
    }

    private func createFolder(parent: String, body: Data?) -> HTTPResponse {
        guard let object = (try? JSONSerialization.jsonObject(with: body ?? Data())) as? [String: Any],
              let title = object["title"] as? String else {
            return error("Missing title", code: "FLD-0001")
        }
        if parent == Self.root && reservedNames.contains(title.lowercased()) {
            return error("The folder name \"\(title)\" is reserved. Please choose another name.", code: "FLD-1014")
        }
        if failingFolderTitles.contains(title) || folders[parent] == nil && parent != Self.root {
            return error("Could not create folder \(title)", code: "FLD-0002")
        }
        return ok(insertFolder(title, under: parent))
    }

    private func importMails(folder: String, body: Data?) -> HTTPResponse {
        let subjects = Self.subjectsOfMultipartMails(body ?? Data())
        if let status = rejectImport(subjects) {
            return HTTPResponse(status: status, body: Data())
        }
        guard folders[folder] != nil else {
            return error("Mail folder \"\(folder)\" could not be found.", code: "IMAP-1002")
        }
        var entries: [[String: String]] = []
        for subject in subjects {
            let mail = Mail(id: "\(nextMailID)", subject: subject)
            nextMailID += 1
            mails[folder, default: []].append(mail)
            entries.append(["folder_id": folder, "id": mail.id])
        }
        if confirmFewerImports && !entries.isEmpty {
            entries.removeLast()
        }
        return ok(entries)
    }

    private func archive(body: Data?) -> HTTPResponse {
        guard archiveSupported else {
            return error("Archiving is not available.", code: "MSG-1088")
        }
        let refs = (try? JSONDecoder().decode([MailListElement].self, from: body ?? Data())) ?? []
        var created = false
        let archiveID = Self.root + "/Archive"
        if folders[archiveID] == nil {
            folders[archiveID] = Folder(title: "Archive", parent: Self.root)
            account["archive_fullname"] = "Archive"
            created = true
        }
        let year = String(Calendar(identifier: .gregorian).component(.year, from: Date()))
        let yearID = folders.first { $0.value.parent == archiveID && $0.value.title == year }?.key ?? insertFolder(year, under: archiveID)
        for ref in refs {
            guard let index = mails[ref.folder]?.firstIndex(where: { $0.id == ref.id }),
                  let mail = mails[ref.folder]?.remove(at: index) else { continue }
            mails[yearID, default: []].append(mail)
        }
        return ok([["id": yearID, "created": created] as [String: Any]])
    }

    // MARK: Helpers

    private func insertFolder(_ title: String, under parent: String) -> String {
        var name = title
        var counter = 1
        func id(for name: String) -> String { parent == Self.root ? Self.root + "/" + name : parent + separator + name }
        while folders[id(for: name)] != nil {
            name = "\(title) (\(counter))"
            counter += 1
        }
        folders[id(for: name)] = Folder(title: name, parent: parent)
        return id(for: name)
    }

    /// Extracts the Subject header of every mail part in a multipart body.
    static func subjectsOfMultipartMails(_ body: Data) -> [String] {
        let text = String(decoding: body, as: UTF8.self)
        return text.components(separatedBy: "Content-Type: message/rfc822\r\n").dropFirst().map { part in
            part.components(separatedBy: "\r\n")
                .first { $0.hasPrefix("Subject: ") }
                .map { String($0.dropFirst("Subject: ".count)) } ?? ""
        }
    }

    private func ok(_ data: Any) -> HTTPResponse {
        HTTPResponse(status: 200, body: json(["data": data]))
    }

    private func error(_ message: String, code: String) -> HTTPResponse {
        HTTPResponse(status: 200, body: json(["error": message, "code": code, "category": 1, "error_desc": message]))
    }

    private func json(_ object: Any) -> Data {
        try! JSONSerialization.data(withJSONObject: object)
    }
}
