import Foundation

struct DeletedEvent: Decodable, Encodable {
    let id: String
}

struct DeletedEventsResponse: Decodable, Encodable {
    let data: [DeletedEvent]
}
