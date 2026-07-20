import Foundation

struct DeletedEvent: Decodable, Encodable {
    let id: String
}

struct DeletedEventsResponse: Decodable, Encodable {
    // Optional: a delete with no conflicts may return an empty/absent data field.
    let data: [DeletedEvent]?
}
