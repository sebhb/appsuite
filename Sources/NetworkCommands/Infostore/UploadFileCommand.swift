//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 03.02.25.
//

import Foundation

class UploadFileCommand: NetworkCommand<UploadFileCommandResponse> {

    let session: RemoteSession
    let filename: String
    let targetFolderId: String
    let fileContents: Data
    let boundary: String = "----Boundary-\(UUID().uuidString)"

    init(session: RemoteSession, filename: String, fileContents: Data, targetfolderId: String) {
        self.session = session
        self.filename = filename
        self.targetFolderId = targetfolderId
        self.fileContents = fileContents
        super.init(serverAddress: session.server)
    }

    override func method() -> HTTPMethod {
        .Post
    }

    override func postContentType() -> String {
        return "multipart/form-data; boundary=" + boundary
    }

    override func requestParameters() -> [String : String] {
        return ["action": "new", "extendedResponse": "true", "force_json_response": "true", "session": session.session]
    }

    override func usesRequestDictionary() -> Bool {
        return false
    }

    override func requestData() -> Data {
        var data = Data()
        let boundaryPrefix = "--\(boundary)\r\n"
        data.append(boundaryPrefix.data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"json\"\r\n\r\n".data(using: .utf8)!)
        data.append("{\"folder_id\":\"\(targetFolderId)\",\"description\":\"\"}\r\n".data(using: .utf8)!)
        data.append(boundaryPrefix.data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n\r\n".data(using: .utf8)!)
        data.append(fileContents)
        data.append("\r\n".data(using: .utf8)!)
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)

        return data

    }

    override func oxFunction() -> String {
        return "appsuite/api/files"
    }

}
