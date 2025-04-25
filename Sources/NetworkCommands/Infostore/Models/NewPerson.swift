import Foundation

struct NewPerson: Decodable, Encodable {
    let firstName: String
    let lastName: String
    let displayName: String
    let email1: String?
    let street_home: String?
    let postal_code_home: String?
    let city_home: String?
    let state_home: String?
    let country_home: String?
}
