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
        static let configuration = CommandConfiguration(commandName: "contexts", abstract: "Context related operations.", subcommands: [ListContexts.self, SearchContexts.self])
    }

    struct ListContexts: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "list", abstract: "List all contexts.")

        @OptionGroup var hostOptions: DataCenterOptions
        @OptionGroup var brandOptions: BrandOptions
        @OptionGroup var outputOptions: OutputFormatOptions

        mutating func run() async throws {
            let brandAuth = BrandAuth(brand: brandOptions.brandName, brandAuth: brandOptions.brandAuth)
            let listContextsCommand = ListContextsCommand(brandAuth: brandAuth, serverAddress: hostOptions.dataCenter.hostName())
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

        @OptionGroup var hostOptions: DataCenterOptions
        @OptionGroup var brandOptions: BrandOptions
        @OptionGroup var searchOptions: SearchOptions
        @OptionGroup var outputOptions: OutputFormatOptions

        mutating func run() async throws {
            let brandAuth = BrandAuth(brand: brandOptions.brandName, brandAuth: brandOptions.brandAuth)
            let searchContextsCommand = SearchContextsCommand(brandAuth: brandAuth, searchString: searchOptions.query, serverAddress: hostOptions.dataCenter.hostName())
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
