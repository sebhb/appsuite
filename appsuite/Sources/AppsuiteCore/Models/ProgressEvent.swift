import Foundation

/// A structured progress update emitted while an operation runs.
///
/// The same events drive the CLI (printed to the console) and the web service
/// (forwarded to the browser as Server-Sent Events), so the type is `Codable`
/// for easy serialization and `Sendable` for crossing concurrency boundaries.
public struct ProgressEvent: Sendable, Codable {

    public enum Kind: String, Sendable, Codable {
        case started    // an operation began
        case progress   // an item within an operation completed (current/total)
        case log        // an informational message
        case finished   // an operation completed successfully
        case failed     // an operation could not complete
    }

    /// Category key, e.g. "mails", "files", "tasks", "contacts", "appointments", "drive".
    public let operation: String
    public let kind: Kind
    public let message: String
    public let current: Int?
    public let total: Int?

    public init(operation: String, kind: Kind, message: String, current: Int? = nil, total: Int? = nil) {
        self.operation = operation
        self.kind = kind
        self.message = message
        self.current = current
        self.total = total
    }

    // Convenience factories -------------------------------------------------

    public static func started(_ operation: String, _ message: String) -> ProgressEvent {
        ProgressEvent(operation: operation, kind: .started, message: message)
    }

    public static func progress(_ operation: String, current: Int, total: Int, _ message: String) -> ProgressEvent {
        ProgressEvent(operation: operation, kind: .progress, message: message, current: current, total: total)
    }

    public static func log(_ operation: String, _ message: String) -> ProgressEvent {
        ProgressEvent(operation: operation, kind: .log, message: message)
    }

    public static func finished(_ operation: String, _ message: String) -> ProgressEvent {
        ProgressEvent(operation: operation, kind: .finished, message: message)
    }

    public static func failed(_ operation: String, _ message: String) -> ProgressEvent {
        ProgressEvent(operation: operation, kind: .failed, message: message)
    }
}

/// A sink for progress events. Must be safe to call from async contexts.
public typealias ProgressHandler = @Sendable (ProgressEvent) -> Void

public extension ProgressEvent {
    /// A handler that prints events to standard output — used by the CLI so its
    /// behavior stays comparable to the previous `print`-based output.
    static func consolePrinter() -> ProgressHandler {
        return { event in
            switch event.kind {
                case .started:
                    print(event.message)
                case .progress:
                    if let current = event.current, let total = event.total {
                        print("[\(current)/\(total)] \(event.message)")
                    } else {
                        print(event.message)
                    }
                case .log:
                    print(event.message)
                case .finished:
                    print(event.message)
                case .failed:
                    print("Error: \(event.message)")
            }
        }
    }
}
