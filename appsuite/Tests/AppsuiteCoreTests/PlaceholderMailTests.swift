import Foundation
import Testing
@testable import AppsuiteCore

@Suite struct PlaceholderMailTests {

    private let subject = "appsuite seeder: archive folder placeholder 1234"

    private var text: String {
        String(decoding: UploadMailsWorker.placeholderMail(subject: subject), as: UTF8.self)
    }

    @Test func usesCRLFLineEndingsOnly() {
        #expect(text.contains("\r\n"))
        #expect(text.replacingOccurrences(of: "\r\n", with: "").contains("\n") == false)
    }

    @Test func hasRequiredHeadersBeforeTheBody() throws {
        let parts = text.components(separatedBy: "\r\n\r\n")
        #expect(parts.count >= 2)
        let headers = try #require(parts.first).components(separatedBy: "\r\n")
        let names = headers.compactMap { $0.split(separator: ":", maxSplits: 1).first.map(String.init) }
        #expect(Set(names).isSuperset(of: ["From", "To", "Subject", "Date", "Message-ID", "MIME-Version", "Content-Type"]))
        #expect(headers.contains("Subject: \(subject)"))
    }

    @Test func dateHeaderIsParseableAndRecent() throws {
        let line = try #require(text.components(separatedBy: "\r\n").first { $0.hasPrefix("Date: ") })
        let date = try #require(DateFormatter.mailDateFormatter.date(from: String(line.dropFirst("Date: ".count))))
        #expect(abs(date.timeIntervalSinceNow) < 60)
    }

    @Test func usesOnlyExampleDomains() {
        for line in text.components(separatedBy: "\r\n") where line.hasPrefix("From:") || line.hasPrefix("To:") || line.hasPrefix("Message-ID:") {
            #expect(line.contains("@example.com"))
        }
    }

    @Test func messageIDsAreUnique() {
        func messageID(_ data: Data) -> String? {
            String(decoding: data, as: UTF8.self).components(separatedBy: "\r\n").first { $0.hasPrefix("Message-ID:") }
        }
        #expect(messageID(UploadMailsWorker.placeholderMail(subject: subject)) != messageID(UploadMailsWorker.placeholderMail(subject: subject)))
    }
}
