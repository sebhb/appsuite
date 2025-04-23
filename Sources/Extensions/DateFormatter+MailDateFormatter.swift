import Foundation

extension DateFormatter {
    static let mailDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z" // RFC 5322 format
        formatter.locale = Locale(identifier: "en_US_POSIX") // POSIX locale ensures consistent parsing
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // Default to UTC
        return formatter
    }()

    static let mailDateFormatters: [DateFormatter] = {
        let formats = [
            "EEE, d MMM yyyy HH:mm:ss zzz",
            "EEE, dd MMM yyyy HH:mm:ss zzz",
            "EEE, d MMM yyyy HH:mm:ss ZZZZ",
            "EEE, dd MMM yyyy HH:mm:ss ZZZZ",
            "EEE, d MMM yyyy HH:mm:ss Z",
            "EEE, dd MMM yyyy HH:mm:ss Z"
        ]
        var result = [DateFormatter]()
        for format in formats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX") // POSIX locale ensures consistent parsing
            result.append(formatter)
        }
        return result
    }()
}
