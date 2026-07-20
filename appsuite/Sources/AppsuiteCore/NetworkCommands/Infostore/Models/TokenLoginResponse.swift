import Foundation

struct TokenLoginResponse: Decodable {
    let serverToken: String
    let url: String
}
