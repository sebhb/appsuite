import Foundation

class MultipartNetworkCommand<U: Decodable>: NetworkCommand<U> {

    let boundary: String = "----Boundary-\(UUID().uuidString)"

    override func method() -> HTTPMethod {
        .Post
    }

    override func postContentType() -> String {
        return "multipart/form-data; boundary=" + boundary
    }

    override func usesRequestDictionary() -> Bool {
        return false
    }

}
