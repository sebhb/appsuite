import Foundation

struct Session: Decodable {
    let session: String
    let user: String
    let locale: String
}

struct RemoteSession {
    let session: String
    let server: String
}
