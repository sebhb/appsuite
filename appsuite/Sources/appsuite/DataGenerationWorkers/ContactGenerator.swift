import Foundation

class ContactGenerator {
    let numberOfContacts: Int
    let contactTemplates: [ContactTemplateWithAvatars]
    let basePath: String
    var avatarsPaths: [String] = []
    let currentYear: Int

    init(numberOfContacts: Int, contactTemplates: [ContactTemplate], basePath: String) {
        self.numberOfContacts = numberOfContacts
        self.basePath = basePath
        self.contactTemplates = contactTemplates.map () { ContactTemplateWithAvatars.from($0, basePath: basePath) }
        currentYear = Calendar.current.component(.year, from: Date())
    }

    func generateContacts() -> [NewPersonWithAvatar] {
        var result: [NewPersonWithAvatar] = []
        for _ in 0..<numberOfContacts {
            guard let template = contactTemplates.randomElement() else { break }
            let person = generateContact(from: template)
            result.append(person)
        }
        return result
    }

    private func generateContact(from template: ContactTemplateWithAvatars) -> NewPersonWithAvatar {
        let firstName = template.firstNames.randomElement() ?? ""
        let lastName = template.lastNames.randomElement() ?? ""
        let displayName = "\(lastName), \(firstName)"

        var addressTemplate: ContactAddress?
        let hasAddress = Double.random(in: 0..<1) < (template.probabilityOfAddress ?? 1.0)
        if hasAddress {
            addressTemplate = template.address()
        }

        let mailAddress = generatePseudoMailAddress(firstName: firstName, lastName: lastName, domains: template.emailDomains)

        var imageKind: ImageKind?
        var imageData: Data?
        if let path = template.avatarFilename() {
            if let (kind, data) = ImageKind.image(basePath: basePath, imagePath: path) {
                imageData = data
                imageKind = kind
            }
        }

        return NewPersonWithAvatar(firstName: firstName, lastName: lastName, displayName: displayName, email: mailAddress, streetHome: addressTemplate?.street, postalCodeHome: addressTemplate?.zip, cityHome: addressTemplate?.city, stateHome: addressTemplate?.state, countryHome: addressTemplate?.country, avatarData: imageData, avatarContentType: imageKind)
    }

    private func generatePseudoMailAddress(firstName: String, lastName: String, domains: [String]) -> String {
        let usesLastName = Double.random(in: 0..<1) < 0.5 // 50% chance
        let usesPseudoBirthyear = Double.random(in: 0..<1) < 0.5 // 50% chance

        var result = "\(firstName)"
        if usesLastName {
            result += ".\(lastName)"
        }
        
        if usesPseudoBirthyear {
            result += ".\(Int.random(in: (currentYear-60)..<(currentYear-20)))"
        }
        
        result += "@"
        result += domains.randomElement() ?? "example.com"

        return result.lowercased()
    }

}
