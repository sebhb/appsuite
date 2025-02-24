//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 02.02.25.
//

import Foundation

class LogoutCommand: NetworkCommand<EmptyResponse> {

    let remoteSession: RemoteSession

    init(session: RemoteSession) {
        self.remoteSession = session
        super.init(serverAddress: remoteSession.server)
    }

    override func method() -> HTTPMethod {
        .Get
    }

    override func requestParameters() -> [String : String] {
        return ["action": "logout", "session": remoteSession.session]
    }
    
    override func oxFunction() -> String {
        return "appsuite/api/login"
    }

}
