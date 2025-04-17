// The Swift Programming Language
// https://docs.swift.org/swift-book

import ArgumentParser
import Foundation

@main
struct OXCloud: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "A utility to interact with OX Cloud.", subcommands: [Contexts.self, Users.self, Import.self, Brand.self/*, Context.self, User.self*/])
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





