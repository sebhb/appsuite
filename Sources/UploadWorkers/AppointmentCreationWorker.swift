//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 22.02.25.
//

import Foundation

class AppointmentCreationWorker: InfostoreBaseWorker {

    var userTimezone: String!
    var calendarFolder: String!
    var invitee: Person!

    func createAppointments(appointmentRequests: [AppointmentRequest]) async throws {
        try await login()
        try await getUserSettings()
        
        for request in appointmentRequests {
            let appointment = Appointment.from(request, person: invitee, folder: calendarFolder, timezone: userTimezone)
            let createAppointmentCommand = CreateAppointmentCommand(session: remoteSession, appointment: appointment)
            guard let _ = try await createAppointmentCommand.execute() else {
                print("Could not crate appointment.")
                return
            }
        }

        try await logout()
    }
    
    private func getUserSettings() async throws {
        let getTimezoneCommand = GetConfigurationCommand(session: remoteSession, property: .timezone)
        guard let timezone = try await getTimezoneCommand.execute() else {
            print("Could not acquire timezone.")
            return
        }
        //print("Timezone: \(timezone.data)")

        let getCalendarCommand = GetConfigurationCommand(session: remoteSession, property: .calendarFolder)
        guard let calendar = try await getCalendarCommand.execute() else {
            print("Could not acquire calendar.")
            return
        }
        //print("Calendar: \(calendar.data)")

        let getMeCommand = GetMeCommand(session: remoteSession)
        guard let me = try await getMeCommand.execute() else {
            print("Could not acquire calendar.")
            return
        }
        //print("Me: \(me.data)")

        userTimezone = timezone.data
        calendarFolder = calendar.data
        invitee = me.data
    }

}
