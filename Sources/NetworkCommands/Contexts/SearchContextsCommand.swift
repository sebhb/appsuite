import Foundation

class SearchContextsCommand: ListContextsCommand {

    let searchString: String

    init(brandAuth: BrandAuth, searchString: String, serverAddress: String) {
        self.searchString = searchString
        super.init(brandAuth: brandAuth, serverAddress: serverAddress)
    }

    override func requestParameters() -> [String : String] {
        return ["pattern": "*\(searchString)*"]
    }

}
