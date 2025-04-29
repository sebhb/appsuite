import Foundation

struct NewPerson: Decodable, Encodable {
    let first_name: String
    let last_name: String
    let display_name: String
    let email1: String?
    let street_home: String?
    let postal_code_home: String?
    let city_home: String?
    let state_home: String?
    let country_home: String?
    let folder_id: String

    static func from(_ request: NewPersonRequest, folder: String) -> NewPerson {
        return NewPerson(
            first_name: request.firstName,
            last_name: request.lastName,
            display_name: request.displayName,
            email1: request.email,
            street_home: request.streetHome,
            postal_code_home: request.postalCodeHome,
            city_home: request.cityHome,
            state_home: request.stateHome,
            country_home: request.countryHome,
            folder_id: "con://0/" + folder
        )
    }
}

struct NewPersonRequest: Decodable, Encodable {
    let firstName: String
    let lastName: String
    let displayName: String
    let email: String?
    let streetHome: String?
    let postalCodeHome: String?
    let cityHome: String?
    let stateHome: String?
    let countryHome: String?
    let avatarPath: String?
}
