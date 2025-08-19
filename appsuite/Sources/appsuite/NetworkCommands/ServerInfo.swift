import Foundation

struct ServerInfo {
    let serverAddress: String
    let cookieJar: CookieJar
    var certificateVerification = true
}
