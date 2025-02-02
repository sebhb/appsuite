// The Swift Programming Language
// https://docs.swift.org/swift-book

import ArgumentParser
import Foundation

@main
struct OXCloud: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "A utility to interact with OX Cloud.", subcommands: [Contexts.self, Users.self/*, Context.self, User.self*/])
}

struct HostOptions: ParsableArguments {
    @Option(name: [.customShort("s"), .customLong("host")], help: "App Suite host omitting schema")
    var host: String
}

struct BrandOptions: ParsableArguments {
    @Option(name: [.customShort("n"), .customLong("brandname")], help: "Brand name -- only required for user provisioning")
    var brandName: String

    @Option(name: [.customShort("a"), .customLong("brandauth")], help: "Brand auth -- only required for user provisioning")
    var brandAuth: String
}

struct SearchOptions: ParsableArguments {
    @Option(name: [.customShort("q"), .customLong("query")], help: "Search query")
    var query: String
}

struct ContextNameOptions: ParsableArguments {
    @Option(name: [.customShort("c"), .customLong("context")], help: "Context name")
    var contextName: String
}





extension OXCloud {
    struct Contexts: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "contexts", abstract: "Context related operations.", subcommands: [ListContexts.self, SearchContexts.self])
    }

    struct ListContexts: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "list", abstract: "List all contexts.")

        @OptionGroup var hostOptions: HostOptions
        @OptionGroup var brandOptions: BrandOptions
        @OptionGroup var outputOptions: OutputFormatOptions

        mutating func run() async throws {
            let brandAuth = BrandAuth(brand: brandOptions.brandName, brandAuth: brandOptions.brandAuth)
            let listContextsCommand = ListContextsCommand(brandAuth: brandAuth, serverAddress: hostOptions.host)
            do {
                let contexts = try await listContextsCommand.execute()
                if let contexts {
                    output(items: contexts.items, format: outputOptions.format)
                }
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }

    struct SearchContexts: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "search", abstract: "Search a context.")

        @OptionGroup var hostOptions: HostOptions
        @OptionGroup var brandOptions: BrandOptions
        @OptionGroup var searchOptions: SearchOptions
        @OptionGroup var outputOptions: OutputFormatOptions

        mutating func run() async throws {
            let brandAuth = BrandAuth(brand: brandOptions.brandName, brandAuth: brandOptions.brandAuth)
            let searchContextsCommand = SearchContextsCommand(brandAuth: brandAuth, searchString: searchOptions.query, serverAddress: hostOptions.host)
            do {
                let contexts = try await searchContextsCommand.execute()
                if let contexts {
                    output(items: contexts.items, format: outputOptions.format)
                }
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }

}

extension OXCloud {
    struct Users: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "users", abstract: "User related operations.", subcommands: [ListUsers.self, SearchContexts.self])
    }

    struct ListUsers: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "list", abstract: "List all users in a context.")

        @OptionGroup var hostOptions: HostOptions
        @OptionGroup var brandOptions: BrandOptions
        @OptionGroup var contextOptions: ContextNameOptions
        @OptionGroup var outputOptions: OutputFormatOptions

        mutating func run() async throws {
            let brandAuth = BrandAuth(brand: brandOptions.brandName, brandAuth: brandOptions.brandAuth)
            let listUsersCommand = ListUsersCommand(brandAuth: brandAuth, contextName: contextOptions.contextName, serverAddress: hostOptions.host)
            do {
                let users = try await listUsersCommand.execute()
                if let users {
                    output(items: users.items, format: outputOptions.format)
                }
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }
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

    



