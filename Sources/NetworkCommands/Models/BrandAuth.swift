//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 31.01.25.
//

import Foundation

struct BrandAuth {
    let brand: String
    let brandAuth: String

    func bodyAuth() -> String {
        return "\(brand):\(brandAuth)".toBase64()!
    }
}
