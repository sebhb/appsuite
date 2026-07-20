import ArgumentParser
import Foundation

public struct Appsuite: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(abstract: "A utility to interact with OX App Suite.", subcommands: [Import.self, Generate.self, Delete.self, Check.self])

    public init() {}
}






