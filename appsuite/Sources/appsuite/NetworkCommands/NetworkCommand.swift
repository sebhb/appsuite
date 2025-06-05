import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class NetworkCommand<T: Decodable>: NSObject {
    let serverAddress: String
    let urlSession = URLSession.shared

    init(serverAddress: String) {
        self.serverAddress = serverAddress
    }

    func method() -> HTTPMethod {
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

        var serverAddress = "https://" + self.serverAddress + "/"

        var cSet = CharacterSet.urlQueryAllowed
        cSet.remove(charactersIn: "/")

        let encodedParameters = parameters.encodedAsURLParameters().addingPercentEncoding(withAllowedCharacters: cSet)

        serverAddress += function
        if parameters.count > 0 {
            serverAddress += "?" + encodedParameters!
        }

        var request = URLRequest(url: URL(string: serverAddress)!)
        request.httpMethod = method().rawValue

        if method() == .Post {
            request.setValue(postContentType(), forHTTPHeaderField: "Content-Type")
            var data: Data?
            if usesRequestDictionary() {
                data = requestDictionary()?.httpBodyData
            }
            else {
                data = requestData()
            }
            request.httpBody = data
        }
        else {
            // GET, PUT

            var data: Data?

            if usesRequestDictionary() {
                if let dictionary = requestDictionary() {
                    data = try! JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
                }
            }
            else {
                data = requestData()
            }

            if let data {
                request.httpBody = data
            }
        }

        additionalHTTPHeaderFields()?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await urlSession.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            let statusCode = httpResponse.statusCode

            if statusCode != 200 {
                let error = NSError(domain: "NetworkCommand", code: statusCode, userInfo: nil)
                throw error
            }
        }

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
