import Foundation

extension Dictionary where Key == String, Value == AnyObject {
    var httpBodyData: Data? {
        guard count > 0 else { return nil }

        let bodyString = encodedAsURLParameters()

        return bodyString.data(using: .utf8)
    }
}

extension Dictionary where Key == String, Value == Any {
    var httpBodyData: Data? {
        (self as [String: AnyObject]).httpBodyData
    }
}

extension Dictionary where Key == String, Value == String {
    var httpBodyData: Data? {
        (self as [String: AnyObject]).httpBodyData
    }
}
