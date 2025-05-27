import Foundation

typealias Outputtable = Encodable & Listable

protocol Listable {
    static var standardColumns: [String] { get }
    static var availableColumns: [String] { get }

    static func name(for column: String) -> String
    static func configuration(for items: [Listable], formatter: ByteCountFormatter) -> ColumnOutputConfiguration

    func displayValue(for column: String, formatter: ByteCountFormatter) -> String
}

extension Listable {
    func configuration<T: Listable>(on type: T.Type, for items: [Listable], formatter: ByteCountFormatter) -> ColumnOutputConfiguration {
        return type.configuration(for: items, formatter: formatter)
    }
}

struct ColumnOutputConfiguration {
    let columnWidths: [String: Int]
    let columns: [String]
}
