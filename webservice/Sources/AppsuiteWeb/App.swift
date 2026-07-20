import Foundation
import AppsuiteCore
import Hummingbird
import NIOCore

// Response DTOs are returned directly from handlers as JSON.
extension ConfigResponse: ResponseEncodable {}
extension DriveCheckResponse: ResponseEncodable {}
extension RunStartedResponse: ResponseEncodable {}

@main
struct AppsuiteWebApp {
    static func main() async throws {
        let jobRunner = JobRunner()
        let service = AppsuiteService()

        let router = Router()

        // Static UI from Public/ (serves index.html at "/").
        router.addMiddleware {
            FileMiddleware("Public", searchForIndexHtml: true)
        }

        // Configuration for the UI: available gold accounts + demo availability.
        router.get("api/config") { _, _ -> ConfigResponse in
            await ConfigResponse(accounts: jobRunner.accounts(), demoAvailable: jobRunner.demoAvailable())
        }

        // Drive capability check (standalone button + preflight).
        router.post("api/check-drive") { request, context -> DriveCheckResponse in
            let creds = try await request.decode(as: CredentialsDTO.self, context: context)
            let enabled = try await service.checkDriveEnabled(creds.toCredentials)
            return DriveCheckResponse(enabled: enabled)
        }

        // Start a seeding job; returns a job id to subscribe to.
        router.post("api/run") { request, context -> RunStartedResponse in
            let runRequest = try await request.decode(as: RunRequest.self, context: context)
            let jobId = await jobRunner.start(runRequest)
            return RunStartedResponse(jobId: jobId)
        }

        // Delete all appointments in the account (without notifying participants).
        router.post("api/delete-appointments") { request, context -> RunStartedResponse in
            let deleteRequest = try await request.decode(as: DeleteAppointmentsRequest.self, context: context)
            let jobId = await jobRunner.startDeleteAppointments(deleteRequest.credentials, years: deleteRequest.years)
            return RunStartedResponse(jobId: jobId)
        }

        // Server-Sent Events stream of progress for a job.
        router.get("api/run/{jobId}/events") { _, context -> Response in
            guard let jobId = context.parameters.get("jobId"),
                  let stream = await jobRunner.takeStream(jobId) else {
                return Response(status: .notFound)
            }

            var headers = HTTPFields()
            headers[.contentType] = "text/event-stream"
            headers[.cacheControl] = "no-cache"
            headers[.connection] = "keep-alive"

            return Response(
                status: .ok,
                headers: headers,
                body: ResponseBody { writer in
                    let encoder = JSONEncoder()
                    for await event in stream {
                        let json = (try? encoder.encode(event)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
                        try await writer.write(ByteBuffer(string: "data: \(json)\n\n"))
                    }
                    try await writer.finish(nil)
                }
            )
        }

        let port = Int(ProcessInfo.processInfo.environment["PORT"] ?? "8080") ?? 8080
        let app = Application(
            router: router,
            configuration: .init(address: .hostname("0.0.0.0", port: port))
        )
        try await app.runService()
    }
}
