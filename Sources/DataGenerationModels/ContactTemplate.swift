import Foundation

struct ContactAddress: Encodable, Decodable {
    let street: String
    let city: String
    let state: String?
    let zip: String
    let country: String?
}

struct ContactTemplate: Encodable, Decodable {
    let firstNames: [String]
    let lastNames: [String]
    let addresses: [ContactAddress]?
    let emailDomains: [String]?
    let probabilityOfAddress: Double?
    let avatarsPath: String?
}

class ContactTemplateWithAvatars {
    let firstNames: [String]
    let lastNames: [String]
    var addresses: [ContactAddress]
    let emailDomains: [String]
    let probabilityOfAddress: Double?
    var avatarFilenames: [String]

    static func from(_ template: ContactTemplate, basePath: String) -> ContactTemplateWithAvatars {
        var avatarsPaths: [String] = []
        if let path = template.avatarsPath, let contents = try? FileManager.default.contentsOfDirectory(atPath: basePath.appendingPathComponent(path)) {
            avatarsPaths = contents.filter { !$0.hasPrefix(".") }.map { path.appendingPathComponent($0) }
        }
        return ContactTemplateWithAvatars(
            firstNames: template.firstNames,
            lastNames: template.lastNames,
            addresses: template.addresses ?? [],
            emailDomains: template.emailDomains ?? [],
            probabilityOfAddress: template.probabilityOfAddress,
            avatarFilenames: avatarsPaths)
    }

    init(firstNames: [String], lastNames: [String], addresses: [ContactAddress], emailDomains: [String], probabilityOfAddress: Double?, avatarFilenames: [String]) {
        self.firstNames = firstNames
        self.lastNames = lastNames
        self.addresses = addresses
        self.emailDomains = emailDomains
        self.probabilityOfAddress = probabilityOfAddress
        self.avatarFilenames = avatarFilenames
    }

    func avatarFilename() -> String? {
        return avatarFilenames.randomElementByRemoving()
    }

    func address() -> ContactAddress? {
        return addresses.randomElementByRemoving()
    }
}
