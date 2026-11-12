import Foundation
import AsyncHTTPClient
import NIOCore
import NIOHTTP1
import NIOSSL
import NIOFoundationCompat

/// A fully assembled HTTP request, independent of any HTTP library.
struct HTTPRequest {
    let method: AppsuiteHTTPMethod
    let url: String
    let headers: [String: String]
    let body: Data?
    let timeoutSeconds: Int64
    let certificateVerification: Bool
}

/// An HTTP response. `headers` keeps repeated fields (e.g. `Set-Cookie`).
struct HTTPResponse {
    let status: Int
    let headers: [(name: String, value: String)]
    let body: Data

    init(status: Int, headers: [(name: String, value: String)] = [], body: Data) {
        self.status = status
        self.headers = headers
        self.body = body
    }

    /// All values of the header `name`, matched case-insensitively.
    func headerValues(_ name: String) -> [String] {
        headers.filter { $0.name.caseInsensitiveCompare(name) == .orderedSame }.map(\.value)
    }
}

/// Sends requests on behalf of `NetworkCommand`. Production code uses
/// `AsyncHTTPClientTransport`; tests substitute a fake server.
protocol HTTPTransport: Sendable {
    func send(_ request: HTTPRequest) async throws -> HTTPResponse
}

/// The real transport, backed by AsyncHTTPClient.
struct AsyncHTTPClientTransport: HTTPTransport {

    func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        let client = HTTPClient(eventLoopGroupProvider: .singleton)
        defer {
            let _ = client.shutdown()
        }

        var clientRequest = HTTPClientRequest(url: request.url)
        clientRequest.method = HTTPMethod(rawValue: request.method.rawValue)
        if !request.headers.isEmpty {
            clientRequest.headers = HTTPHeaders(request.headers.map { ($0, $1) })
        }
        if let body = request.body {
            clientRequest.body = .bytes(body)
        }
        if request.certificateVerification == false {
            var tls = TLSConfiguration.makeClientConfiguration()
            tls.certificateVerification = .none
            clientRequest.tlsConfiguration = tls
        }

        let response = try await client.execute(clientRequest, timeout: .seconds(request.timeoutSeconds))
        let expected = response.headers.first(name: "content-length").flatMap(Int.init) ?? 1_048_576 // 1 MiB
        let buffer = try await response.body.collect(upTo: expected)
        return HTTPResponse(
            status: Int(response.status.code),
            headers: response.headers.map { (name: $0.name, value: $0.value) },
            body: Data(buffer: buffer)
        )
    }

}
