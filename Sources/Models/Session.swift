//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 02.02.25.
//

import Foundation

struct Session: Decodable {
    let session: String
    let user: String
    let locale: String

//    let userId: Int
//    let contextId: Int
}

struct RemoteSession {
    let session: String
    let server: String
}
