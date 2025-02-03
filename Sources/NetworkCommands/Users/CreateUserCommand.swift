//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 02.02.25.
//

import Foundation

class CreateUserCommand: NetworkCommand<User> {

    let brandAuth: BrandAuth
    let contextName: String
    let newUser: NewUser

    init(brandAuth: BrandAuth, contextName: String, newUser: NewUser, serverAddress: String) {
        self.brandAuth = brandAuth
        self.contextName = contextName
        self.newUser = newUser
        super.init(serverAddress: serverAddress)
    }

    override func method() -> HTTPMethod {
        .Post
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

    override func usesRequestDictionary() -> Bool {
        return false
    }

    override func requestData() -> Data {
        return try! JSONEncoder().encode(newUser)
    }

}
