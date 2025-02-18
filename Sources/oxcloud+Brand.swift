//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 05.02.25.
//

import ArgumentParser
import Foundation

extension OXCloud {
    struct Brand: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "brand", abstract: "Brand related operations.", subcommands: [GetTheme.self])
    }

    struct GetTheme: AsyncParsableCommand {
        static let configuration = CommandConfiguration(commandName: "get", abstract: "Get Brand Theme.")

        @OptionGroup var brandOptions: BrandOptions

        mutating func run() async throws {
            let brandAuth = BrandAuth(brand: brandOptions.brandName!, brandAuth: brandOptions.brandAuth!)
            let listContextsCommand = GetBrandCommand(brandAuth: brandAuth, serverAddress: brandOptions.dataCenter!.hostName())
            do {
                let theme = try await listContextsCommand.execute()
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

//    struct SetTheme: AsyncParsableCommand {
//        static let configuration = CommandConfiguration(commandName: "set", abstract: "Set Brand Theme.")
//
//        @OptionGroup var brandOptions: BrandOptions
//        @OptionGroup var themeOptions: ThemeOptions
//
//        mutating func run() async throws {
//            let theme = Theme.from(themeOptions)
//
//            let brandAuth = BrandAuth(brand: brandOptions.brandName!, brandAuth: brandOptions.brandAuth!)
//            let listContextsCommand = GetBrandCommand(brandAuth: brandAuth, serverAddress: brandOptions.dataCenter!.hostName())
//            do {
//                let theme = try await listContextsCommand.execute()
//                if let theme {
//                    let encoder = JSONEncoder()
//                    encoder.outputFormatting = .prettyPrinted
//
//                    guard let data = try? encoder.encode(theme) else { return }
//                    print(String(data: data, encoding: .utf8)!)
//                }
//            }
//            catch {
//                print("An error occurred: \(error)")
//            }
//        }
//    }
}
