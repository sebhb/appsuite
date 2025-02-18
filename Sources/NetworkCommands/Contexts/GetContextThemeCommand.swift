//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 05.02.25.
//

import Foundation

class GetContextThemeCommand: NetworkCommand<Theme> {

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
        return ["pattern": "\(contextName)"]
    }

    override func additionalHTTPHeaderFields() -> [String: String]? {
        return ["Authorization": "Basic \(brandAuth.bodyAuth())"]
    }

    override func oxFunction() -> String {
        return "cloudapi/v2/contexts"
    }

    override func result(from data: Data) throws -> Theme? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let contexts = try decoder.decode([Context].self, from: data)
        guard let firstContext = contexts.first else {
            return nil
        }
        return firstContext.theme
    }
}
