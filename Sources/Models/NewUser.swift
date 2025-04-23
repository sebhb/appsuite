import Foundation

struct NewUser: Decodable, Encodable {
    let name: String
    let givenName: String
    let surName: String
    let mail: String
    let password: String
    let classOfService: [String]?
}
