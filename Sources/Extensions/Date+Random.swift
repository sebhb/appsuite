//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 11.04.25.
//

import Foundation

extension Date {

    static func randomDateInPast(days: Int) -> Date {
        let daysAgo = Int.random(in: 0...days)
        let now = Date()
        let dateComponents = DateComponents(day: -daysAgo)
        return Calendar.current.date(byAdding: dateComponents, to: now)!
    }

}
