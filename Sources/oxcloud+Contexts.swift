//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 02.02.25.
//

import ArgumentParser
import Foundation

extension OXCloud {
    struct Contexts: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "contexts", abstract: "Context related operations.", subcommands: [ListContexts.self, SearchContexts.self, GetContextTheme.self, SetContextTheme.self])
    }

    struct ListContexts: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "list", abstract: "List all contexts.")

        @OptionGroup var brandOptions: BrandOptions
        @OptionGroup var outputOptions: OutputFormatOptions

        mutating func run() async throws {
            let brandAuth = BrandAuth(brand: brandOptions.brandName!, brandAuth: brandOptions.brandAuth!)
            let listContextsCommand = ListContextsCommand(brandAuth: brandAuth, serverAddress: brandOptions.dataCenter!.hostName())
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

        @OptionGroup var brandOptions: BrandOptions
        @OptionGroup var searchOptions: SearchOptions
        @OptionGroup var outputOptions: OutputFormatOptions

        mutating func run() async throws {
            let brandAuth = BrandAuth(brand: brandOptions.brandName!, brandAuth: brandOptions.brandAuth!)
            let searchContextsCommand = SearchContextsCommand(brandAuth: brandAuth, searchString: searchOptions.query, serverAddress: brandOptions.dataCenter!.hostName())
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

    struct GetContextTheme: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "gettheme", abstract: "Gets a context's theme.")

        @OptionGroup var brandOptions: BrandOptions
        @OptionGroup var contextName: ContextNameOptions

        mutating func run() async throws {
            let brandAuth = BrandAuth(brand: brandOptions.brandName!, brandAuth: brandOptions.brandAuth!)
            let getThemeCommand = GetContextThemeCommand(brandAuth: brandAuth, contextName: contextName.contextName, serverAddress: brandOptions.dataCenter!.hostName())
            do {
                let theme = try await getThemeCommand.execute()
                if let theme {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted

                    guard let data = try? encoder.encode(theme) else { return }
                    print(String(data: data, encoding: .utf8)!)
                }
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }

    struct SetContextTheme: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "settheme", abstract: "Set Context Theme.", discussion: "See https://documentation.open-xchange.com/8/ui/theming/dynamic-theming.html#specifying-a-theme for keys and their meaning.")

        @OptionGroup var brandOptions: BrandOptions
        @OptionGroup var contextName: ContextNameOptions
        @OptionGroup var themeOptions: ThemeOptions

        mutating func run() async throws {
            let theme = Theme.from(themeOptions)

            let brandAuth = BrandAuth(brand: brandOptions.brandName!, brandAuth: brandOptions.brandAuth!)
            let setThemeCommand = SetContextThemeCommand(brandAuth: brandAuth, contextName: contextName.contextName, theme: theme, serverAddress: brandOptions.dataCenter!.hostName())
            do {
                let result = try await setThemeCommand.execute()
                if let _ = result {
                    print("Theme set successfully.")
                }
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }
}
