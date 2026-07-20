import Foundation

class DeleteEventsWorker: InfostoreBaseWorker {

    func deleteEvents(years: Int, onProgress: ProgressHandler = { _ in }) async throws {
        try await login()

        let getEventsCommand = GetEventsCommand(session: remoteSession, years: years)
        guard let events = try await getEventsCommand.execute() else {
            onProgress(.failed("delete", "Could not retrieve calendar events."))
            return
        }

        let count = events.data.count
        onProgress(.log("delete", "Found \(count) appointment(s) in range."))
        guard count > 0 else {
            try await logout()
            return
        }

        // Delete in batches: a single request for the whole range can exceed the
        // request timeout, and batching also lets us report progress. The
        // original folder timestamp is reused for every batch — the events being
        // deleted haven't changed since we fetched them, so it stays valid.
        let batchSize = 100
        var deleted = 0
        var start = 0
        while start < count {
            let end = min(start + batchSize, count)
            let batch = Array(events.data[start..<end])
            let batchPayload = GetEventsResponse(data: batch, timestamp: events.timestamp)

            let deleteEventsCommand = DeleteEventsCommand(session: remoteSession, events: batchPayload)
            guard let _ = try await deleteEventsCommand.execute() else {
                onProgress(.failed("delete", "Could not delete a batch of appointments (deleted \(deleted) of \(count))."))
                return
            }

            deleted += batch.count
            onProgress(.progress("delete", current: deleted, total: count, "Deleted \(deleted) of \(count) appointment(s)…"))
            start = end
        }
        onProgress(.log("delete", "Deleted \(count) appointment(s) without notifying participants."))

        try await logout()
    }

}
