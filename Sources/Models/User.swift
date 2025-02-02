//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 01.02.25.
//

import Foundation

struct User: Decodable, Encodable {
    let contextName: String
    let name: String
    let givenName: String?
    let surName: String?
    let mail: String
    let displayName: String
    let classOfService: [String]?
    let isContextAdmin: Bool
    let unifiedQuota: Int?
    let usedQuota: Int?

    func formattedUsedQuota(formatter: ByteCountFormatter) -> String? {
        guard let usedQuota else { return nil }
        return formatter.string(fromByteCount: Int64(usedQuota))
    }
}

extension User: Listable {
    static var standardColumns: [String] {
        return ["name", "isContextAdmin", "displayName", "usedQuota", "classOfService"]
    }

    static var availableColumns: [String] {
        return ["name", "isContextAdmin", "displayName", "usedQuota", "classOfService"]
    }

    static func name(for column: String) -> String {
        switch column {
            case "name": return "Name"
            case "isContextAdmin": return "Admin"
            case "displayName": return "Display Name"
            case "usedQuota": return "Used Quota"
            case "classOfService": return "Class of Service"
            default: return ""
        }
    }

    static func configuration(for items: [Listable], formatter: ByteCountFormatter) -> ColumnOutputConfiguration {
        var columnWidths = [String: Int]()
        for column in User.standardColumns {
            let maxLength = items.map( { $0.displayValue(for: column, formatter: formatter).count } ).max() ?? 0
            columnWidths[column] = max(maxLength, name(for: column).count) + 2
        }
        let result = ColumnOutputConfiguration(columnWidths: columnWidths, columns: User.standardColumns)
        return result
    }

    func displayValue(for column: String, formatter: ByteCountFormatter) -> String {
        switch column {
            case "name": return name
            case "isContextAdmin": return isContextAdmin ? "Y" : "N"
            case "displayName": return displayName
            case "usedQuota": return formattedUsedQuota(formatter: formatter) ?? "-"
            case "classOfService": return classOfService?.joined(separator: ", ") ?? "-"
            default: return ""
        }
    }
}
