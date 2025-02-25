//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 22.02.25.
//

import Foundation

///
/// Note: Contrary to the belief that /user/me would be more appropriate, it's not.
/// /user/me only contains a display name, but not first and last name separately.
/// What is what in the display name can not be said, this is culture dependent.
///

class GetMeCommand: NetworkCommand<GetMeResponse> {

    let remoteSession: RemoteSession

    init(session: RemoteSession) {
        self.remoteSession = session
        super.init(serverAddress: remoteSession.server)
    }

    override func method() -> HTTPMethod {
        .Get
    }

    override func requestParameters() -> [String : String] {
        return ["action": "get", "session": remoteSession.session]
    }

    override func oxFunction() -> String {
        return "appsuite/api/user/"
    }

}
