import ArgumentParser
import Foundation

@main
struct Appsuite: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "A utility to interact with OX App Suite.", subcommands: [Import.self, Generate.self, Delete.self])
}






