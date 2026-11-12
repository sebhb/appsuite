import Foundation
import Testing
@testable import AppsuiteCore

@Suite struct ImportBatchOptionsTests {

    @Test func defaultsMatchTheDefaultLimits() throws {
        let limits = try ImportBatchOptions.parse([]).batchLimits
        #expect(limits.maxBytes == MailBatchLimits.default.maxBytes)
        #expect(limits.maxCount == MailBatchLimits.default.maxCount)
        #expect(limits.maxBytes == 8 * 1_048_576)
        #expect(limits.maxCount == 50)
    }

    @Test func optionsAreConvertedToLimits() throws {
        let limits = try ImportBatchOptions.parse(["--maxBatchSizeMB", "2", "--maxBatchCount", "1"]).batchLimits
        #expect(limits.maxBytes == 2 * 1_048_576)
        #expect(limits.maxCount == 1)
    }

    @Test func nonPositiveValuesAreClamped() throws {
        let limits = try ImportBatchOptions.parse(["--maxBatchSizeMB", "0", "--maxBatchCount=-5"]).batchLimits
        #expect(limits.maxBytes == 1)
        #expect(limits.maxCount == 1)
    }

    @Test func rejectsNonNumericValues() {
        #expect(throws: (any Error).self) {
            try ImportBatchOptions.parse(["--maxBatchSizeMB", "lots"])
        }
    }
}
