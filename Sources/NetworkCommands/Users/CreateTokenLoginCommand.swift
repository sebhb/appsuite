//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 20.02.25.
//

import Foundation

class CreateTokenLoginCommand: NetworkCommand<String> {

    let authId = UUID().uuidString
    let clientToken = UUID().uuidString
    let username: String
    let password: String

    init(username: String, password: String, serverAddress: String) {
        self.username = username
        self.password = password
        super.init(serverAddress: serverAddress)
    }

    override func method() -> HTTPMethod {
        .Post
    }

    override func postContentType() -> String {
        return "application/x-www-form-urlencoded"
    }

    override func requestParameters() -> [String : String] {
        return ["action": "tokenLogin", "authId": authId, "jsonResponse": "true"]
    }

    override func oxFunction() -> String {
        return "appsuite/api/login"
    }

    override func requestDictionary() -> [String : AnyObject]? {
        return ["login": username, "password": password, "client": "oxcloud-admin", "version": "1.0", "clientToken": clientToken] as [String: AnyObject]
    }

    override func result(from data: Data) throws -> String? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let token = try decoder.decode(TokenLoginResponse.self, from: data)
        let url = token.url

        return serverAddress + url + "&clientToken=" + clientToken
    }
}
