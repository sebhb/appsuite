//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 03.02.25.
//

import Foundation

class ImportMailCommand: NetworkCommand<GenericDataResponse> {

    let session: RemoteSession
    let mailPath: String
    let boundary: String = "----Boundary-\(UUID().uuidString)"

    init(session: RemoteSession, mailPath: String) {
        self.session = session
        self.mailPath = mailPath
        super.init(serverAddress: session.server)
    }

    override func method() -> HTTPMethod {
        .Post
    }

    override func postContentType() -> String {
        return "multipart/form-data; boundary=" + boundary
    }

    override func requestParameters() -> [String : String] {
        return ["action": "import", "folder": "default0/INBOX", "force": "true", "session": session.session]
    }

    override func usesRequestDictionary() -> Bool {
        return false
    }

    override func requestData() -> Data {
        let fileContents = try! Data(contentsOf: URL(fileURLWithPath: mailPath))

        var data = Data()
        let boundaryPrefix = "--\(boundary)\r\n"

        data.append(boundaryPrefix.data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(UUID().uuidString).eml\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: message/rfc822\r\n\r\n".data(using: .utf8)!)
        data.append(fileContents)
        data.append("\r\n".data(using: .utf8)!)
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)

        return data

    }

    override func oxFunction() -> String {
        return "appsuite/api/mail"
    }

}
