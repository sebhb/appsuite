import Foundation

struct ServerInfo {
    let serverAddress: String
    let cookieJar: CookieJar
    var certificateVerification = true
    var transport: any HTTPTransport = AsyncHTTPClientTransport()
}
