// The Swift Programming Language
// https://docs.swift.org/swift-book

import ArgumentParser
import Foundation

@main
struct OXCloud: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "A utility to interact with OX Cloud.", subcommands: [Contexts.self, Users.self, Import.self/*, Context.self, User.self*/])
}

struct BrandOptions: ParsableArguments {
    @Option(name: [.customLong("defaultbrand")], help: "The name of the brand in the defaults")
    var defaultName: String?

    @Option(name: [.customShort("d"), .customLong("datacenter")], help: "App Suite Data Center (eu, us, in)")
    var dataCenter: DataCenter?

    @Option(name: [.customShort("n"), .customLong("brandname")], help: "Brand name")
    var brandName: String?

    @Option(name: [.customShort("a"), .customLong("brandauth")], help: "Brand auth")
    var brandAuth: String?

    mutating func validate() throws {
        if brandName == nil || brandAuth == nil {
            if let brand = defaultBrand() {
                brandName = brand.brandName
                brandAuth = brand.brandAuth
                dataCenter = brand.dataCenter
                return
            }

            guard let defaultName = defaultName else {
                throw ValidationError("Brandname and brandauth have to be set if no default brand is provided.")
            }

            let allBrands = configuredBrands()
            if let brand = allBrands.first(where: { $0.name == defaultName }) {
                brandName = brand.brandName
                brandAuth = brand.brandAuth
                dataCenter = brand.dataCenter
                return
            }
            throw ValidationError("Brandname and brandauth have to be set if no brand name is provided.")
        }
    }
}

struct SearchOptions: ParsableArguments {
    @Option(name: [.customShort("q"), .customLong("query")], help: "Search query")
    var query: String
}

struct ContextNameOptions: ParsableArguments {
    @Option(name: [.customShort("c"), .customLong("context")], help: "Context name")
    var contextName: String
}

struct UserCredentialsOptions: ParsableArguments {
    @Option(name: [.customShort("s"), .customLong("server")], help: "Server")
    var server: String

    @Option(name: [.customShort("m"), .customLong("name")], help: "User Name")
    var userName: String

    @Option(name: [.customShort("p"), .customLong("password")], help: "User Password")
    var password: String
}

struct UserCreationOptions: ParsableArguments {
    @Option(name: [.customShort("e"), .customLong("email")], help: "User Email")
    var email: String

    @Option(name: [.customShort("r"), .customLong("surname")], help: "User Surname")
    var userSurname: String

    @Option(name: [.customShort("g"), .customLong("givenname")], help: "User Given Name")
    var userGivenname: String
}

struct ImportPathOptions: ParsableArguments {
    @Option(name: [.customShort("u"), .customLong("source")], help: "Import Source Path")
    var path: String
}

struct DefaultContext: Decodable {
    let name: String
    let identifier: String
    let `isDefault`: Bool?
}

struct DefaultBrand: Decodable {
    let name: String
    let dataCenter: DataCenter
    let brandName: String
    let brandAuth: String
    let contexts: [DefaultContext]
    let `isDefault`: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case dataCenter
        case brandName
        case brandAuth
        case contexts
        case `isDefault`
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dataCenterRaw = try container.decode(String.self, forKey: .dataCenter)
        guard let dataCenterTemp = DataCenter(rawValue: dataCenterRaw) else {
            fatalError("Unsupported data center \(dataCenterRaw)")
        }
        dataCenter = dataCenterTemp
        name = try container.decode(String.self, forKey: .name)
        brandName = try container.decode(String.self, forKey: .brandName)
        brandAuth = try container.decode(String.self, forKey: .brandAuth)
        contexts = try container.decode([DefaultContext].self, forKey: .contexts)
        isDefault = try container.decode(Bool?.self, forKey: .isDefault) ?? false
    }
}

func configuredBrands() -> [DefaultBrand] {
    let fileManager = FileManager.default
    let filePath = fileManager.homeDirectoryForCurrentUser.path + "/.oxcloud/brands.json"
    guard fileManager.fileExists(atPath: filePath) else { return [] }
    guard let data = fileManager.contents(atPath: filePath) else { return [] }
    guard let brands = try? JSONDecoder().decode([DefaultBrand].self, from: data) else { return [] }
    return brands
}

func defaultBrand() -> DefaultBrand? {
    return configuredBrands().filter { $0.isDefault ?? false }.first
}

func output<T: Outputtable>(items: [T], format: OutputFormat) {
    guard items.count > 0 else {
        print("0 results")
        return
    }
    switch format {
        case .list:
            let type = type(of: items.first!)

            let byteFormatter = ByteCountFormatter()
            byteFormatter.allowedUnits = .useMB
            byteFormatter.formattingContext = .listItem
            byteFormatter.allowsNonnumericFormatting = false

            let configuration = type.configuration(for: items, formatter: byteFormatter)

            var overallHeaderWidth = 0
            var header = ""
            for column in configuration.columns {
                let columnName = type.name(for: column)
                let width = configuration.columnWidths[column] ?? 0
                header += columnName.padding(toLength: width, withPad: " ", startingAt: 0)
                overallHeaderWidth += width
            }
            print(header)
            print("".padding(toLength: overallHeaderWidth, withPad: "-", startingAt: 0))

            for item in items {
                var line = ""
                for column in configuration.columns {
                    let width = configuration.columnWidths[column] ?? 0
                    line += item.displayValue(for: column, formatter: byteFormatter).padding(toLength: width, withPad: " ", startingAt: 0)
                    overallHeaderWidth += width
                }
                print(line)
            }
        case .yaml:
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted

            guard let data = try? encoder.encode(items) else { return }
            print(String(data: data, encoding: .utf8)!)
    }
}

func showProgress(progress: Double) {
    let barWidth = 50
    let filledWidth = Int(progress * Double(barWidth))
    let emptyWidth = barWidth - filledWidth

    let progressBar = String(repeating: "=", count: filledWidth) + String(repeating: " ", count: emptyWidth)
    let percentage = Int(progress * 100)

    print("\r\u{1B}[K[\(progressBar)] \(percentage)%", terminator: "")
    fflush(__stdoutp)
}

//
//    @Option(name: [.short, .customLong("user")], help: "User name")
//    var userName: String
//
//    @Option(name: [.short, .customLong("pass")], help: "Password")
//    var passWord: String
//
//    @Option(name: [.short, .customLong("context")], help: "Context to provision the user into -- only required for user provisioning. The context will be created if it does not exist.")
//    var contextName: String?
//

//
//    mutating func run() {
//        print("Hello, world!")
//    }

    



