import Foundation
import Testing
@testable import AppsuiteCore

@Suite struct MailBatchingTests {

    private let overhead = UploadMailsWorker.multipartOverheadPerMail

    /// A mail whose batching footprint (size + overhead) is exactly `footprint` bytes.
    private func mail(footprint: Int, tag: UInt8 = 0) -> Data {
        Data(repeating: tag, count: footprint - overhead)
    }

    @Test func emptyInputYieldsNoBatches() {
        #expect(UploadMailsWorker.batches([], limits: .default).isEmpty)
    }

    @Test func countCapSplitsTinyMails() {
        let mails = (0..<7).map { _ in mail(footprint: 1_000) }
        let batches = UploadMailsWorker.batches(mails, limits: MailBatchLimits(maxBytes: 1_000_000, maxCount: 3))
        #expect(batches.map(\.count) == [3, 3, 1])
    }

    @Test func byteCapSplitsMixedSizes() {
        let mails = [4_000, 4_000, 3_000, 5_000, 1_000].map { mail(footprint: $0) }
        let batches = UploadMailsWorker.batches(mails, limits: MailBatchLimits(maxBytes: 10_000, maxCount: 50))
        // 4+4 = 8 (adding 3 → 11 > 10), 3+5+1 = 9
        #expect(batches.map(\.count) == [2, 3])
    }

    @Test func exactlyAtByteCapStaysInOneBatch() {
        let mails = [mail(footprint: 5_000), mail(footprint: 5_000)]
        let batches = UploadMailsWorker.batches(mails, limits: MailBatchLimits(maxBytes: 10_000, maxCount: 50))
        #expect(batches.map(\.count) == [2])
    }

    @Test func oversizedMailIsSentAlone() {
        let mails = [mail(footprint: 1_000), mail(footprint: 50_000), mail(footprint: 1_000)]
        let batches = UploadMailsWorker.batches(mails, limits: MailBatchLimits(maxBytes: 10_000, maxCount: 50))
        #expect(batches.map(\.count) == [1, 1, 1])
        #expect(batches[1][0].count == 50_000 - overhead)
    }

    @Test func orderIsPreserved() {
        let mails = (0..<10).map { mail(footprint: 1_000, tag: UInt8($0)) }
        let batches = UploadMailsWorker.batches(mails, limits: MailBatchLimits(maxBytes: 3_500, maxCount: 50))
        #expect(batches.flatMap { $0 } == mails)
        #expect(batches.map(\.count) == [3, 3, 3, 1])
    }

    @Test func limitsAreClampedToAtLeastOne() {
        let limits = MailBatchLimits(maxBytes: 0, maxCount: 0)
        #expect(limits.maxBytes == 1)
        #expect(limits.maxCount == 1)
        let batches = UploadMailsWorker.batches([mail(footprint: 1_000), mail(footprint: 1_000)], limits: limits)
        #expect(batches.map(\.count) == [1, 1])
    }
}
