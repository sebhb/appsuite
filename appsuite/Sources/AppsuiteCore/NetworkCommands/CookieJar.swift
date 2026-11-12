import Foundation

struct SimpleCookie {
    let name: String
    let value: String
}

class CookieJar {

    var cookieJar: [String: [String: SimpleCookie]] = [:] // host -> name -> cookie

    func storeCookies(fromSetCookieHeaders headers: [String], for host: String) {
        for value in headers {
            // Einfachster Parser (Name=Value; …)
            guard let first = value.split(separator: ";").first,
                  let eq = first.firstIndex(of: "=") else { continue }
            let name  = String(first[..<eq]).trimmingCharacters(in: .whitespaces)
            let value = String(first[first.index(after: eq)...])
            cookieJar[host, default: [:]][name] = SimpleCookie(name: name, value: value)
        }
    }

    /// The `Cookie` header value for `host`, or `nil` if no cookies are stored.
    func cookieHeader(for host: String) -> String? {
        guard let jar = cookieJar[host], !jar.isEmpty else { return nil }
        return jar.values.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
    }

}
