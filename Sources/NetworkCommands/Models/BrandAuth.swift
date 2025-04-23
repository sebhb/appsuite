import Foundation

struct BrandAuth {
    let brand: String
    let brandAuth: String

    func bodyAuth() -> String {
        return "\(brand):\(brandAuth)".toBase64()!
    }
}
