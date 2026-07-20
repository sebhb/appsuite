import Foundation

/// Response of the capabilities endpoint for a single capability id.
///
/// `data` (and its `id`) are optional so an absent capability — where the server
/// omits `data` or returns an error body — simply decodes to "not present".
struct CapabilityResponse: Decodable {
    struct Capability: Decodable {
        let id: String?
    }
    let data: Capability?
}
