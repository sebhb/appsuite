// The Swift Programming Language
// https://docs.swift.org/swift-book

import ArgumentParser
import Foundation

@main
struct OXCloud: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "A utility to interact with OX Cloud.", subcommands: [Contexts.self, Users.self, Import.self, Brand.self/*, Context.self, User.self*/])
}

struct BrandOptions: ParsableArguments {
    @Option(name: [.customLong("defaultbrand")], help: "The name of the brand in the defaults")
    var defaultName: String?

    @Option(name: [.customShort("d"), .customLong("datacenter")], help: "App Suite Data Center (eu, us, asia)")
    var dataCenter: DataCenter?

    @Option(name: [.customShort("n"), .customLong("brandname")], help: "Brand name")
    var brandName: String?

    @Option(name: [.customShort("a"), .customLong("brandauth")], help: "Brand auth")
    var brandAuth: String?

    mutating func validate() throws {
        if brandName == nil || brandAuth == nil {
            if let defaultName = defaultName {
                let allBrands = configuredBrands()
                if let brand = allBrands.first(where: { $0.name == defaultName }) {
                    brandName = brand.brandName
                    brandAuth = brand.brandAuth
                    dataCenter = brand.dataCenter
                    return
                }
                throw ValidationError("No default brand with priovided name configured.")
            }

            if let brand = defaultBrand() {
                brandName = brand.brandName
                brandAuth = brand.brandAuth
                dataCenter = brand.dataCenter
                return
            }

            throw ValidationError("Brandname and brandauth have to be set if no brand name is provided.")
        }
    }
}

struct ClassOfServiceOptions: ParsableArguments {
    @Option(name: [.customLong("set")], help: "The classes of service to set")
    var classesToSet: [String] = []

    @Option(name: [.customLong("add")], help: "The classes of service to add")
    var classesToAdd: [String] = []

    mutating func validate() throws {
        let numberOfClassesToSet = classesToSet.count
        let numberOfClassesToAdd = classesToAdd.count

        if numberOfClassesToSet == 0 && numberOfClassesToAdd > 0 { return }
        if numberOfClassesToSet > 0 && numberOfClassesToAdd == 0 { return }

        throw ValidationError("have to either specify classes to set or classes to add. You can not do both or none.")
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

struct UserNameOptions: ParsableArguments {
    @Option(name: [.customLong("name")], help: "User Name")
    var userName: String
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

struct ThemeOptions: ParsableArguments {
    // https://documentation.open-xchange.com/8/ui/theming/dynamic-theming.html#specifying-a-theme

    @Option(name: [.customLong("mainColor")], help: "Theme's mainColor")
    var mainColor: String?

    @Option(name: [.customLong("linkColor")], help: "Theme's linkColor")
    var linkColor: String?

    @Option(name: [.customLong("toolbarColor")], help: "Theme's toolbarColor")
    var toolbarColor: String?

    @Option(name: [.customLong("logoUrlLight")], help: "Theme's logoUrlLight")
    var logoUrlLight: String?

    @Option(name: [.customLong("logoUrlDark")], help: "Theme's logoUrlDark")
    var logoUrlDark: String?

    @Option(name: [.customLong("logoWidth")], help: "Theme's logoWidth")
    var logoWidth: String?

    @Option(name: [.customLong("logoHeight")], help: "Theme's logoHeight")
    var logoHeight: String?

    @Option(name: [.customLong("topbarBackground")], help: "Theme's topbarBackground")
    var topbarBackground: String?

    @Option(name: [.customLong("topbarHover")], help: "Theme's topbarHover")
    var topbarHover: String?

    @Option(name: [.customLong("topbarColor")], help: "Theme's topbarColor")
    var topbarColor: String?

    @Option(name: [.customLong("topbarSelected")], help: "Theme's topbarSelected")
    var topbarSelected: String?

    @Option(name: [.customLong("listSelected")], help: "Theme's listSelected")
    var listSelected: String?

    @Option(name: [.customLong("listHover")], help: "Theme's listHover")
    var listHover: String?

    @Option(name: [.customLong("listSelectedFocus")], help: "Theme's listSelectedFocus")
    var listSelectedFocus: String?

    @Option(name: [.customLong("folderBackground")], help: "Theme's folderBackground")
    var folderBackground: String?

    @Option(name: [.customLong("folderSelected")], help: "Theme's folderSelected")
    var folderSelected: String?

    @Option(name: [.customLong("folderHover")], help: "Theme's folderHover")
    var folderHover: String?

    @Option(name: [.customLong("folderSelectedFocus")], help: "Theme's folderSelectedFocus")
    var folderSelectedFocus: String?

    @Option(name: [.customLong("mailDetailCSS")], help: "Theme's mailDetailCSS")
    var mailDetailCSS: String?

    @Option(name: [.customLong("serverContact")], help: "Theme's serverContact")
    var serverContact: String?

}

struct ImportPathOptions: ParsableArguments {
    @Option(name: [.customShort("u"), .customLong("source")], help: "Import Source Path")
    var path: String
}

struct ImportStretchOptions: ParsableArguments {
    @Option(name: [.customLong("stretchPeriod")], help: "The period (in days) over which to randomly distribute emails. Dates will be left untouched if omitted.")
    var stretchPeriod: Int?
}

struct ImportMailOptions: ParsableArguments {
    @Option(name: [.customLong("adjustRecipient")], help: "Set the recipient to the user importing the mails")
    var adjustRecipient: Bool = false
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
        isDefault = try? container.decode(Bool?.self, forKey: .isDefault) ?? false
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

func output<T: Outputtable>(item: T) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted

    guard let data = try? encoder.encode(item) else { return }
    print(String(data: data, encoding: .utf8)!)
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
        case .json:
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

    



