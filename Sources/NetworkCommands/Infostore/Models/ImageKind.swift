import Foundation

enum ImageKind: String, CaseIterable {
    case jpeg
    case png

    func fileExtensions() -> [String] {
        switch self {
            case .jpeg:
                return ["jpeg", "jpg"]
            case .png:
                return ["png"]
        }
    }

    func contentType() -> String {
        switch self {
            case .jpeg:
                return "image/jpeg"
            case .png:
                return "image/png"
        }
    }

    static func fromFileExtension(_ fileExtension: String) -> ImageKind? {
        for kind in allCases {
            if kind.fileExtensions().contains(fileExtension) {
                return kind
            }
        }
        return nil
    }
}
