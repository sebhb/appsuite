import Foundation

struct FileResponse: Decodable {
    let lastModified: Int
}

struct UploadFileResponse: Decodable {
    let file: FileResponse
}

struct UploadFileCommandResponse: Decodable {
    let data: UploadFileResponse
}
