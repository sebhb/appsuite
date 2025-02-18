//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 02.02.25.
//

import Foundation

class AlterUserCommand: NetworkCommand<EmptyResponse> {

    let brandAuth: BrandAuth
    let contextName: String
    let username: String

    init(brandAuth: BrandAuth, contextName: String, username: String, serverAddress: String) {
        self.brandAuth = brandAuth
        self.contextName = contextName
        self.username = username
        super.init(serverAddress: serverAddress)
    }

    override func method() -> HTTPMethod {
        .Put
    }

    override func additionalHTTPHeaderFields() -> [String: String]? {
        return ["Authorization": "Basic \(brandAuth.bodyAuth())"]
    }

    override func requestParameters() -> [String : String] {
        return ["name": contextName]
    }

    override func oxFunction() -> String {
        return "cloudapi/v2/users/\(username)"
    }

    override func usesRequestDictionary() -> Bool {
        return false
    }

//    override func requestData() -> Data {
//        let context = Context(name: contextName, maxQuota: nil, usedQuota: nil, maxUser: nil, theme: theme)
//        return try! JSONEncoder().encode(context)
//    }

}
