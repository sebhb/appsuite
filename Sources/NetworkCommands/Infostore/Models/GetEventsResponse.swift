import Foundation

struct EventId: Decodable, Encodable {
    let id: String
    let folder: String
}

struct GetEventsResponse: Decodable, Encodable {
    let data: [EventId]
    let timestamp: Int64
}
