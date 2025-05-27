import Foundation

class LoginCommand: NetworkCommand<Session> {

    let userName: String
    let password: String

    init(userName: String, password: String, serverAddress: String) {
        self.userName = userName
        self.password = password
        super.init(serverAddress: serverAddress)
    }

    override func method() -> HTTPMethod {
        .Post
    }

    override func postContentType() -> String {
        return "application/x-www-form-urlencoded"
    }

    override func requestParameters() -> [String : String] {
        return ["action": "login"]
    }
    
    override func usesRequestDictionary() -> Bool {
        return false
    }

    override func requestData() -> Data {
        return "name=\(userName)&password=\(password)".data(using: .utf8)!
    }

    override func oxFunction() -> String {
        return "appsuite/api/login"
    }

}
