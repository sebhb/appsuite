import Foundation

class SetContextThemeCommand: NetworkCommand<EmptyResponse> {

    let brandAuth: BrandAuth
    let contextName: String
    let theme: Theme

    init(brandAuth: BrandAuth, contextName: String, theme: Theme, serverAddress: String) {
        self.brandAuth = brandAuth
        self.contextName = contextName
        self.theme = theme
        super.init(serverAddress: serverAddress)
    }

    override func method() -> HTTPMethod {
        .Put
    }

    override func additionalHTTPHeaderFields() -> [String: String]? {
        return ["Authorization": "Basic \(brandAuth.bodyAuth())"]
    }

    override func oxFunction() -> String {
        return "cloudapi/v2/contexts/\(contextName)"
    }

    override func usesRequestDictionary() -> Bool {
        return false
    }

    override func requestData() -> Data {
        let context = Context(name: contextName, maxQuota: nil, usedQuota: nil, maxUser: nil, theme: theme)
        return try! JSONEncoder().encode(context)
    }

}
