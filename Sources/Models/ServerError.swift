//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 21.02.25.
//

import Foundation

struct ServerError: Decodable, Error {
    let error: String
    let category: Int?
    let errorDesc: String?
}
