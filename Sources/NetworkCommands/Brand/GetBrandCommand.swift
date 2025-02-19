//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 05.02.25.
//

import Foundation

class GetBrandCommand: NetworkCommand<Theme> {

    let brandAuth: BrandAuth

    init(brandAuth: BrandAuth, serverAddress: String) {
        self.brandAuth = brandAuth
        super.init(serverAddress: serverAddress)
    }

    override func method() -> HTTPMethod {
        .Get
    }

    override func additionalHTTPHeaderFields() -> [String: String]? {
        return ["Authorization": "Basic \(brandAuth.bodyAuth())"]
    }

    override func oxFunction() -> String {
        return "cloudapi/v2/brand/theme"
    }

}
