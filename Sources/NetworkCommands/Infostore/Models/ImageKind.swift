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

    static func image(basePath: String, imagePath: String) -> (kind: ImageKind, data: Data)? {
        if let kind = ImageKind.fromFileExtension(imagePath.pathExtension()) {
            let completeAvatarPath = basePath.appendingPathComponent(imagePath)
            if let data = try? Data(contentsOf: URL(fileURLWithPath: completeAvatarPath)) {
                return (kind, data)
            }
        }
        return nil
    }
}
