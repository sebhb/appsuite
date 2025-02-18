//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 19.02.25.
//

import Foundation

class AlterUserCOSCommand: AlterUserCommand {

    let classesOfService: [String]

    init(brandAuth: BrandAuth, contextName: String, username: String, classesOfService: [String], serverAddress: String) {
        self.classesOfService = classesOfService
        super.init(brandAuth: brandAuth, contextName: contextName, username: username, serverAddress: serverAddress)
    }

    override func requestData() -> Data {
        let cosStruct = ["classOfService": classesOfService]
        return try! JSONEncoder().encode(cosStruct)
    }

}
