import Foundation
import AsyncHTTPClient
import NIOCore

struct SimpleCookie {
    let name: String
    let value: String
}

class CookieJar {

    var cookieJar: [String: [String: SimpleCookie]] = [:] // host -> name -> cookie

    func storeCookies(from response: HTTPClientResponse, for host: String) {
        // Alle Set-Cookie-Header holen …
        for value in response.headers["set-cookie"] {
            // Einfachster Parser (Name=Value; …)
            guard let first = value.split(separator: ";").first,
                  let eq = first.firstIndex(of: "=") else { continue }
            let name  = String(first[..<eq]).trimmingCharacters(in: .whitespaces)
            let value = String(first[first.index(after: eq)...])
            cookieJar[host, default: [:]][name] = SimpleCookie(name: name, value: value)
        }
    }

    func applyCookies(to request: inout HTTPClientRequest, for host: String) {
        guard let jar = cookieJar[host], !jar.isEmpty else { return }
        let header = jar.values.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
        request.headers.add(name: "Cookie", value: header)
    }

}
