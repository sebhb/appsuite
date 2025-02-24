//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 22.02.25.
//

import Foundation

struct CreatedAppointment: Decodable, Encodable {
    let id: String
    /*"summary": "Title",
    "startDate": {
        "value": "20250219T180000",
        "tzid": "Europe/Berlin"
    },
    "transp": "OPAQUE",
    "folder": "cal://0/71",
    "createdBy": {
        "uri": "mailto:fred.tester@flintstone.com",
        "cn": "Tester Fred",
        "email": "fred.tester@flintstone.com",
        "entity": 7
    },
    "flags": [
        "organizer",
        "accepted"
    ],
    "timestamp": 1740131733729,
    "location": "Location",
    "lastModified": 1740131733729,
    "endDate": {
        "value": "20250219T200000",
        "tzid": "Europe/Berlin"
    },
    "attendeePrivileges": "DEFAULT"*/
}

struct AppointmentCreation: Decodable, Encodable {
    let created: [CreatedAppointment]
}

struct AppointmentCreationReply: Decodable, Encodable {
    let data: AppointmentCreation
}

class CreateAppointmentCommand: NetworkCommand<AppointmentCreationReply> {

    let remoteSession: RemoteSession
    let appointment: Appointment

    init(session: RemoteSession, appointment: Appointment) {
        self.remoteSession = session
        self.appointment = appointment
        super.init(serverAddress: remoteSession.server)
    }

    override func method() -> HTTPMethod {
        .Put
    }

    override func requestParameters() -> [String : String] {
        return ["action": "new", "expand": "true", "folder": appointment.folder, "session": remoteSession.session]
    }

    override func oxFunction() -> String {
        return "appsuite/api/chronos"
    }

    override func usesRequestDictionary() -> Bool {
        return false
    }

    override func requestData() -> Data? {
        return try! JSONEncoder().encode(appointment)
    }

}
