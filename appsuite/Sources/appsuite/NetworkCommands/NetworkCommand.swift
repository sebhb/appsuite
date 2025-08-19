import Foundation
import AsyncHTTPClient
import NIOHTTP1

class NetworkCommand<T: Decodable>: NSObject {
    let serverInfo: ServerInfo
    let urlSession = URLSession.shared

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

    func execute() async throws -> T? {
        let function = oxFunction()
        let parameters = requestParameters()

        var serverAddress = "https://" + self.serverInfo.serverAddress + "/"

        var cSet = CharacterSet.urlQueryAllowed
        cSet.remove(charactersIn: "/")

        let encodedParameters = parameters.encodedAsURLParameters().addingPercentEncoding(withAllowedCharacters: cSet)

        serverAddress += function
        if parameters.count > 0 {
            serverAddress += "?" + encodedParameters!
        }

        let client = HTTPClient(eventLoopGroupProvider: .singleton)
        defer {
            let _ = client.shutdown()
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

        var request = HTTPClientRequest(url: serverAddress)
        request.method = HTTPMethod(rawValue: method().rawValue)
        if headers.count > 0 {
            request.headers = HTTPHeaders(headers.map { ($0, $1) })
        }
        if let bodyData = bodyData {
            request.body = .bytes(bodyData)
        }

        // Apply cookies
        serverInfo.cookieJar.applyCookies(to: &request, for: self.serverInfo.serverAddress)

        let response = try await client.execute(request, timeout: .seconds(30))
        if response.status.code != 200 {
            let error = NSError(domain: "NetworkCommand", code: Int(response.status.code), userInfo: nil)
            throw error
        }

        // Save cookies
        serverInfo.cookieJar.storeCookies(from: response, for: self.serverInfo.serverAddress)

        let expected = response.headers.first(name: "content-length").flatMap(Int.init) ?? 1_048_576 // 1 MiB
        let buf = try await response.body.collect(upTo: expected)
        let data = Data(buffer: buf)

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
