import Foundation


struct CreatedContact: Decodable, Encodable {
    let id: String
}

struct ContactCreationResponse: Decodable, Encodable {
    let data: CreatedContact
}
