//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 31.01.25.
//

import Foundation

class ListUsersCommand: NetworkCommand<ArrayWrapper<User>> {

    let brandAuth: BrandAuth
    let contextName: String

    init(brandAuth: BrandAuth, contextName: String, serverAddress: String) {
        self.brandAuth = brandAuth
        self.contextName = contextName
        super.init(serverAddress: serverAddress)
    }

    override func method() -> HTTPMethod {
        .Get
    }

    override func requestParameters() -> [String : String] {
        return ["name": contextName]
    }

    override func additionalHTTPHeaderFields() -> [String: String]? {
        return ["Authorization": "Basic \(brandAuth.bodyAuth())"]
    }

    override func oxFunction() -> String {
        return "cloudapi/v2/users"
    }

}
