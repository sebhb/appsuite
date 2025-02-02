//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 31.01.25.
//

import Foundation

struct ArrayWrapper<T: Decodable>: Decodable {
    let items: [T]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        items = try container.decode([T].self)
    }
}
