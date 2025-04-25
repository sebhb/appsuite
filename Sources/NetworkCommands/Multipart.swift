import Foundation

class Multipart {

    let name: String
    let filename: String?
    let contentType: String?
    let content: Encodable

    init(name: String, filename: String? = nil, contentType: String? = nil, content: Encodable) {
        self.name = name
        self.filename = filename
        self.contentType = contentType
        self.content = content
    }

}

extension Array where Element: Multipart {

    func multipartFormData(boundary: String) throws -> Data {
        var body = Data()
        let encoder = JSONEncoder()
        let lineBreak = "\r\n"

        for element in self {
            body.append("--\(boundary)\(lineBreak)")
            let filename = if let elementfilename = element.filename {
                "; filename=\"\(elementfilename)\""
            }
            else {
                ""
            }

            body.append("Content-Disposition: form-data; name=\"\(element.name)\"\(filename)\(lineBreak)")
            if let contentType = element.contentType {
                body.append("Content-Type: \(contentType)\(lineBreak)")
            }
            body.append(lineBreak)

            if let data = element.content as? Data {
                body.append(data)
            }
            else {
                let jsonData = try encoder.encode(element.content)
                body.append(jsonData)
            }
            body.append(lineBreak)
        }
        body.append(lineBreak)
        body.append("--\(boundary)--\(lineBreak)")
        return body
    }

}

private extension Data {

    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }

}
