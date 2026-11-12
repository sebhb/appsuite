import Foundation

class NetworkCommand<T: Decodable>: NSObject {
    let serverInfo: ServerInfo

    init(serverInfo: ServerInfo) {
        self.serverInfo = serverInfo
    }

    func method() -> AppsuiteHTTPMethod {
        .Post
    }

    func requestParameters() -> [String: String] {
        Dictionary()
    }

    func oxFunction() -> String {
        assertionFailure("Implement me in subclass!")
        return ""
    }

    func requestDictionary() -> [String: AnyObject]? {
        nil
    }

    func requestData() -> Data? {
        nil
    }

    func usesRequestDictionary() -> Bool {
        true
    }

    func additionalHTTPHeaderFields() -> [String: String]? {
        nil
    }

    func postContentType() -> String {
        return "application/json"
    }

    func validatesForServerErrors() -> Bool {
        true
    }

    /// Per-request timeout in seconds. Overridable for commands that legitimately
    /// take longer than the default (e.g. bulk deletes).
    func requestTimeoutSeconds() -> Int64 {
        30
    }

    func execute() async throws -> T? {
        let function = oxFunction()
        let parameters = requestParameters()

        var serverAddress = "https://" + self.serverInfo.serverAddress + "/"

        // `encodedAsURLParameters()` percent-encodes each key and value, so the
        // joined query string is already safe to append verbatim.
        let encodedParameters = parameters.encodedAsURLParameters()

        serverAddress += function
        if parameters.count > 0 {
            serverAddress += "?" + encodedParameters
        }

        var headers = [String: String]()
        var bodyData: Data?

        if method() == .Post {
            headers["Content-Type"] = postContentType()

            if usesRequestDictionary() {
                bodyData = requestDictionary()?.httpBodyData
            }
            else {
                bodyData = requestData()
            }
        }
        else {
            // GET, PUT

            if usesRequestDictionary() {
                if let dictionary = requestDictionary() {
                    bodyData = try! JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
                }
            }
            else {
                bodyData = requestData()
            }
        }

        additionalHTTPHeaderFields()?.forEach { key, value in
            headers[key] = value
        }

        // Apply cookies
        if let cookieHeader = serverInfo.cookieJar.cookieHeader(for: serverInfo.serverAddress) {
            headers["Cookie"] = cookieHeader
        }

        let request = HTTPRequest(
            method: method(),
            url: serverAddress,
            headers: headers,
            body: bodyData,
            timeoutSeconds: requestTimeoutSeconds(),
            certificateVerification: serverInfo.certificateVerification
        )
        let response = try await serverInfo.transport.send(request)
        if response.status != 200 {
            let error = NSError(domain: "NetworkCommand", code: response.status, userInfo: nil)
            throw error
        }

        // Save cookies
        serverInfo.cookieJar.storeCookies(fromSetCookieHeaders: response.headerValues("set-cookie"), for: serverInfo.serverAddress)

        let data = response.body

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        if validatesForServerErrors() {
            if let error = try? decoder.decode(ServerError?.self, from: data) {
                throw error
            }
        }

        return try result(from: data)
    }

    func result(from data: Data) throws -> T? {
        if T.self is EmptyResponse.Type && data.isEmpty {
            return (EmptyResponse() as! T)
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }

}
