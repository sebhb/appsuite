import Foundation
import Testing
@testable import AppsuiteCore

@Suite struct RemoteSessionTests {

    @Test(arguments: [true, false])
    func serverInfoKeepsCertificateVerification(verify: Bool) {
        let session = RemoteSession(session: "s", server: "appsuite.example.com", cookieJar: CookieJar(), certificateVerification: verify)
        #expect(session.serverInfo.certificateVerification == verify)
    }

    @Test func commandsBuiltFromTheSessionInheritTheSetting() {
        let session = RemoteSession(session: "s", server: "appsuite.example.com", cookieJar: CookieJar(), certificateVerification: false)
        #expect(ImportMailCommand(session: session, mailData: Data()).serverInfo.certificateVerification == false)
        #expect(GetSubfoldersCommand(folder: "default0", session: session).serverInfo.certificateVerification == false)
    }

    @Test func verificationIsOnByDefault() {
        #expect(TestSupport.session.serverInfo.certificateVerification == true)
    }
}
