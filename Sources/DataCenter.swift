//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 03.02.25.
//

import ArgumentParser
import Foundation

enum DataCenter: String, ExpressibleByArgument {
    case eu, es, asia

    func hostName() -> String {
        return rawValue + ".appsuite.cloud"
    }
}
