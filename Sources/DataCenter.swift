import ArgumentParser
import Foundation

enum DataCenter: String, ExpressibleByArgument {
    case eu, es, asia

    func hostName() -> String {
        return rawValue + ".appsuite.cloud"
    }
}
