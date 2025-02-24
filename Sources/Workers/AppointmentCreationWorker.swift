//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 22.02.25.
//

import Foundation

class AppointmentCreationWorker {

    let userCredentialsOptions: UserCredentialsOptions
    var remoteSession: RemoteSession!
    var userTimezone: String!
    var calendarFolder: String!
    var invitee: Person!

    init(userCredentialsOptions: UserCredentialsOptions) {
        self.userCredentialsOptions = userCredentialsOptions
    }

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

    private func login() async throws {
        let loginCommand = LoginCommand(userName: userCredentialsOptions.userName, password: userCredentialsOptions.password, serverAddress: userCredentialsOptions.server)

        guard let session = try await loginCommand.execute() else {
            print("Could not acquire session.")
            return
        }
        remoteSession = RemoteSession(session: session.session, server: userCredentialsOptions.server)
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

    private func logout() async throws {
        let logoutCommand = LogoutCommand(session: remoteSession)
        guard let _ = try await logoutCommand.execute() else {
            print("Could not acquire session.")
            return
        }
        remoteSession = nil
    }

}
