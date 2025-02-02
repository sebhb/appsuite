//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 31.01.25.
//

import Foundation

extension String {
    func toBase64() -> String? {
        return self.data(using: .utf8)?.base64EncodedString()
    }
}
