import Foundation

/// Plain, dependency-free credentials for connecting to an App Suite instance.
///
/// This is the public entry type used by both front-ends: the CLI maps its
/// ArgumentParser options onto it, and the web service constructs it from the
/// submitted form. Keeping it free of ArgumentParser lets non-CLI callers use
/// the library without depending on argument parsing.
public struct Credentials: Sendable {
    public let server: String
    public let userName: String
    public let password: String
    public let validateCertificate: Bool

    public init(server: String, userName: String, password: String, validateCertificate: Bool = true) {
        self.server = server
        self.userName = userName
        self.password = password
        self.validateCertificate = validateCertificate
    }
}
