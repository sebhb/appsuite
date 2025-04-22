//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 21.02.25.
//

import Foundation

///
/// Note: Because someone at OX decided it was a good idea to use both camel case AND snake case at the same time
/// for the naming of properties (`cuType` and `partStat` vs `display_name`), for encoding and decoding of any of the structs below,
/// `keyDecodingStrategy` must not be set to `.convertFromSnakeCase`.
///

/// Exclusively used to wrap values for creation of an appointment since quite a few items are required for creation of an appointment
/// `startTime` and `endTime` are in the format `20250219T200000` which looks like a specific form of ISO 8601 in the user's local timezone.
struct AppointmentRequest: Decodable {
    let title: String
    let description: String?
    let startTime: String
    let endTime: String
    let location: String?
    let rrule: String? // Recurrence rules like "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR"; section 3.8.5.3 of https://www.rfc-editor.org/rfc/rfc5545.txt

    static func from(title: String, description: String? = nil, startDate: Date, duration: Int = 60, location: String? = nil, repeatRule: String? = nil) -> AppointmentRequest {
        let endDate = Calendar.current.date(byAdding: .minute, value: duration, to: startDate)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss"
        let startTime = dateFormatter.string(from: startDate)
        let endTime = dateFormatter.string(from: endDate!)
        return AppointmentRequest(title: title, description: description, startTime: startTime, endTime: endTime, location: location, rrule: repeatRule)
    }
}

struct DateTime: Decodable, Encodable {
    let value: String // "20250219T200000"
    let tzid: String // Timezone, e.g. "Europe/Berlin"
}

struct OrganizerContact: Decodable, Encodable {
    let first_name: String
    let last_name: String
    let email1: String
}

struct Organizer: Decodable, Encodable {
    let cn: String // Common Name
    let email: String
    let uri: String
    let entity: Int
    let contact: OrganizerContact
}

struct AttendeeContact: Decodable, Encodable {
    let first_name: String
    let last_name: String
    let display_name: String
}

struct Attendee: Decodable, Encodable {
    let cuType: String // INDIVIDUAL, GROUP, RESOURCE, ROOM, UNKNOWN
    let cn: String // Common Name
    let partStat: String // Participation Status
    let role: String? // CHAIR, REQ-PARTICIPANT, OPT-PARTICIPANT, NON-PARTICIPANT
    let entity: Int // Internal User ID
    let email: String?
    let uri: String?
    let contact: AttendeeContact?
}

struct Appointment: Decodable, Encodable {
    let folder: String // Identifier of the calendar, e.g. "cal://0/71"
    let startDate: DateTime
    let endDate: DateTime
    let `class`: String // "PUBLIC"
    let transp: String // "OPAQUE"/"TRANSPARENT" -- free/busy
    let organizer: Organizer
    let attendees: [Attendee]
    let attendeePrivileges: String // "DEFAULT",
    let summary: String // "Title" -- This really is the title, the naming is confusing
    let location: String?
    let description: String?
    let categories: [String]?

    static func from(_ request: AppointmentRequest, person: Person, folder: String, timezone: String) -> Appointment {
        let folderId = "cal://0/" + folder
        let start = DateTime(value: request.startTime, tzid: timezone)
        let end = DateTime(value: request.endTime, tzid: timezone)

        let organizer = person.organizer
        let attendee = person.attendee

        let appointment = Appointment(folder: folderId, startDate: start, endDate: end, class: "PUBLIC", transp: "OPAQUE", organizer: organizer, attendees: [attendee], attendeePrivileges: "DEFAULT", summary: request.title, location: request.location, description: request.description, categories: nil)

        return appointment
    }
}
