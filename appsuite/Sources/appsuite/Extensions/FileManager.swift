//
//  File.swift
//  appsuite
//
//  Created by Sebastian Krauß on 16.05.25.
//

import Foundation

extension FileManager {

    static var systemPathSeparator: String {
#if os(Windows)
        let pathSeparator = "\\"
#else
        let pathSeparator = "/"
#endif
        return pathSeparator
    }

}
