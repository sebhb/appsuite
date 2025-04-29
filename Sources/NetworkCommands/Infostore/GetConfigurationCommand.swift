import Foundation

enum ConfigurationProperty: String {
    
    case calendarFolder
    case timezone
    case driveRootFolder
    case tasksFolder
    case addressbookFolder

    var urlPath: String {
        switch self {
            case .calendarFolder:
                return "folder/calendar"
            case .timezone:
                return "timezone"
            case .driveRootFolder:
                return "folder/infostore"
            case .tasksFolder:
                return "folder/tasks"
            case .addressbookFolder:
                return "folder/contacts"
        }
    }
}

class GetConfigurationCommand: NetworkCommand<ConfigurationResponse> {

    let remoteSession: RemoteSession
    let property: ConfigurationProperty

    init(session: RemoteSession, property: ConfigurationProperty) {
        self.remoteSession = session
        self.property = property
        super.init(serverAddress: remoteSession.server)
    }

    override func method() -> HTTPMethod {
        .Get
    }

    override func requestParameters() -> [String : String] {
        return ["session": remoteSession.session]
    }

    override func oxFunction() -> String {
        return "appsuite/api/config/" + property.urlPath
    }

}
