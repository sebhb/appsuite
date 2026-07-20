import Foundation

struct ServerError: Decodable, Error {
    let error: String
    let category: Int?
    let errorDesc: String?
}
