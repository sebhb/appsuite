import Foundation

struct EventId: Decodable, Encodable {
    let id: String
    let folder: String
}

struct GetEventsResponse: Decodable, Encodable {
    let data: [EventId]
    // Optional: the chronos `all` response does not always include a top-level
    // timestamp. When absent, the delete falls back to a "now" timestamp.
    let timestamp: Int64?
}
