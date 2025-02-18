//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 31.01.25.
//

import Foundation

class GetUserCommand: NetworkCommand<User> {

    let brandAuth: BrandAuth
    let contextName: String
    let username: String

    init(brandAuth: BrandAuth, contextName: String, usernameQuery: String, serverAddress: String) {
        self.brandAuth = brandAuth
        self.contextName = contextName
        self.username = usernameQuery
        super.init(serverAddress: serverAddress)
    }

    override func method() -> HTTPMethod {
        .Get
    }

    override func requestParameters() -> [String : String] {
        return ["name": contextName, "includepermissions": "true"]
    }

    override func additionalHTTPHeaderFields() -> [String: String]? {
        return ["Authorization": "Basic \(brandAuth.bodyAuth())"]
    }

    override func oxFunction() -> String {
        return "cloudapi/v2/users/\(username)"
    }

}
