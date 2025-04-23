import Foundation

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
