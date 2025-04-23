import Foundation

extension String {
    func toBase64() -> String? {
        return self.data(using: .utf8)?.base64EncodedString()
    }
}
