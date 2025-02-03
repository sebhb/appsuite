//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 02.02.25.
//

import Foundation

class LogoutCommand: NetworkCommand<EmptyResponse> {

    let session: String

    init(session: String, serverAddress: String) {
        self.session = session
        super.init(serverAddress: serverAddress)
    }

    override func method() -> HTTPMethod {
        .Get
    }

    override func requestParameters() -> [String : String] {
        return ["action": "logout", "session": session]
    }
    
    override func oxFunction() -> String {
        return "appsuite/api/login"
    }

}
