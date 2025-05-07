import Foundation

class DeleteEventsWorker: InfostoreBaseWorker {

    func deleteEvents(years: Int) async throws {
        try await login()

        let getEventsCommand = GetEventsCommand(session: remoteSession, years: years)
        guard let events = try await getEventsCommand.execute() else {
            print("Could not retrieve calendar events")
            return
        }

        let deleteEventsCommand = DeleteEventsCommand(session: remoteSession, events: events)
        guard let _ = try await deleteEventsCommand.execute() else {
            print("Could not delete calendar events")
            return
        }

        try await logout()
    }

}
