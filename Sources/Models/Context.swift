//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 31.01.25.
//

import Foundation



struct Context: Decodable, Encodable {
    let name: String
    let maxQuota: Int?
    let usedQuota: Int
    let maxUser: Int?
    let theme: [String: String]?

    func formattedUsedQuota(formatter: ByteCountFormatter) -> String {
        return formatter.string(fromByteCount: Int64(usedQuota))
    }

    func formattedMaxQuota(formatter: ByteCountFormatter) -> String? {
        guard let maxQuota else {
            return nil
        }
        return formatter.string(fromByteCount: Int64(maxQuota))
    }
}

extension Context: Listable {
    static var standardColumns: [String] {
        return ["name", "maxQuota", "usedQuota"]
    }

    static var availableColumns: [String] {
        return ["name", "maxQuota", "usedQuota"]
    }

    static func name(for column: String) -> String {
        switch column {
            case "name": return "Name"
            case "maxQuota": return "Max Quota"
            case "usedQuota": return "Used Quota"
            default: return ""
        }
    }

    static func configuration(for items: [Listable], formatter: ByteCountFormatter) -> ColumnOutputConfiguration {
        var columnWidths = [String: Int]()
        for column in Context.standardColumns {
            let maxLength = items.map( { $0.displayValue(for: column, formatter: formatter).count } ).max() ?? 0
            columnWidths[column] = max(maxLength, name(for: column).count) + 2
        }
        let result = ColumnOutputConfiguration(columnWidths: columnWidths, columns: Context.standardColumns)
        return result
    }

    func displayValue(for column: String, formatter: ByteCountFormatter) -> String {
        switch column {
            case "name": return name
            case "maxQuota": return formattedMaxQuota(formatter: formatter) ?? "-"
            case "usedQuota": return formattedUsedQuota(formatter: formatter)
            default: return ""
        }
    }
}
