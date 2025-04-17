//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 14.04.25.
//

import Foundation

class EmailWorker {

    let email: Data
    var mailText: String
    var header: String = ""
    var body: String = ""
    var separator: String = "\r\n\r\n"
    var headerFieldSeparator: String = "\r\n"

    init?(email: Data) {
        self.email = email
        guard let text = String(data: email, encoding: .utf8) else { return nil }
        mailText = text
        guard let (tmpHeader, tmpBody) = splitEmailIntoHeaderAndBody(emailText: text) else { return nil }
        self.header = tmpHeader
        self.body = tmpBody
    }

    func resultingMail() -> Data {
        let completeMail = [header, body].joined(separator: separator)
        return completeMail.data(using: .utf8)!
    }

    func rewrite(recipient: String?, date: Date?) {
        var headerFields: [String] = header.split(separator: headerFieldSeparator).filter { !$0.isEmpty }.map { String($0) }

        if let recipient {
            headerFields = headerByRemoving(field: "To", from: headerFields)
            headerFields.append("To: \(recipient)")
        }
        if let date {
            headerFields = headerByRemoving(field: "Date", from: headerFields)
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z" // RFC 5322 format
            formatter.locale = Locale(identifier: "en_US_POSIX") // POSIX locale ensures consistent parsing
            formatter.timeZone = TimeZone(secondsFromGMT: 0) // Default to UTC
            headerFields.append("Date: \(formatter.string(from: date))")
        }

        header = headerFields.joined(separator: headerFieldSeparator)
    }

    private func headerByRemoving(field: String, from header: [String]) -> [String] {
        var linesToBeRemoved: [Int] = []
        var insideField = false
        for (index, line) in header.enumerated() {
            if insideField {
                if let firstChar = line.first, firstChar.isWhitespace {
                    linesToBeRemoved.append(index)
                }
                else {
                    insideField = false
                    break
                }
            }
            else {
                if line.hasPrefix(field + ":") {
                    linesToBeRemoved.append(index)
                    insideField = true
                }
            }
        }
        var result = header
        linesToBeRemoved.reversed().forEach { result.remove(at: $0) }
        return result
    }

    private func splitEmailIntoHeaderAndBody(emailText: String) -> (header: String, body: String)? {
        if let result = splitEmailIntoHeaderAndBody(emailText: emailText, separator: separator) {
            return result
        }
        separator = "\n\n"
        headerFieldSeparator = "\n"
        if let result = splitEmailIntoHeaderAndBody(emailText: emailText, separator: separator) {
            return result
        }
        return nil
    }

    private func splitEmailIntoHeaderAndBody(emailText: String, separator: String) -> (header: String, body: String)? {
        // Split the email into header and body using the delimiter "\r\n\r\n"
        let components = emailText.components(separatedBy: separator)

        // Ensure there are at least two parts (header and body)
        guard components.count >= 2 else {
            return nil // If the format is invalid, return nil
        }

        let header = components[0] // The header is the first part
        let body = components[1...].joined(separator: separator) // The body is the rest

        return (header: header, body: body)
    }

    private func emailFrom(header: String, body: String) -> String {
        return [header, body].joined(separator: separator)
    }

}
