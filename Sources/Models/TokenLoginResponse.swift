//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 20.02.25.
//

import Foundation

struct TokenLoginResponse: Decodable {
    let serverToken: String
    let url: String
}
