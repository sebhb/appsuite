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
    /// Carried over from login so every follow-up request honours
    /// `--validateCertificate`, not just the login itself.
    var certificateVerification = true
    var transport: any HTTPTransport = AsyncHTTPClientTransport()

    var serverInfo: ServerInfo {
        return ServerInfo(serverAddress: server, cookieJar: cookieJar, certificateVerification: certificateVerification, transport: transport)
    }
}
