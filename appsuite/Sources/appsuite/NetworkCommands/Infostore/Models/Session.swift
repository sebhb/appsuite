import Foundation

struct Session: Decodable {
    let session: String
    let user: String
    let locale: String
}

struct RemoteSession {
    let session: String
    let server: String
    let cookieJar: CookieJar

    var serverInfo: ServerInfo {
        return ServerInfo(serverAddress: server, cookieJar: cookieJar)
    }
}
