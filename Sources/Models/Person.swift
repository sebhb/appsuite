//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 22.02.25.
//

import Foundation

struct Person: Decodable, Encodable {
    let firstName: String?
    let lastName: String?
    let displayName: String
    let userId: Int
    let email1: String

    var computedFirstName: String {
        if let firstName {
            return firstName
        }
        let nameComponents = displayName.components(separatedBy: " ")
        guard nameComponents.count > 0 else {
            return ""
        }
        return nameComponents.first ?? ""
    }

    var computedLastName: String {
        if let lastName {
            return lastName
        }
        let nameComponents = displayName.components(separatedBy: " ")
        guard nameComponents.count > 0 else {
            return ""
        }
        return nameComponents.last ?? ""
    }

    var attendee: Attendee {
        let attendeeContact = AttendeeContact(first_name: computedFirstName, last_name: computedLastName, display_name: displayName)
        let attendee = Attendee(cuType: "INDIVIDUAL", cn: displayName, partStat: "ACCEPTED", role: "REQ-PARTICIPANT", entity: userId, email: email1, uri: "mailto:\(email1)", contact: attendeeContact)
        return attendee
    }

    var organizer: Organizer {
        let organizerContact = OrganizerContact(first_name: computedFirstName, last_name: computedLastName, email1: email1)
        let organizer = Organizer(cn: displayName, email: email1, uri: "mailto:\(email1)", entity: userId, contact: organizerContact)
        return organizer
    }
}
