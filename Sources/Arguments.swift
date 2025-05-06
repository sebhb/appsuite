import Foundation
import ArgumentParser

struct OutputFormatOptions: ParsableArguments {
    @Option(name: [.customShort("o"), .customLong("output")], help: "Output format (list, json)"/*, defaultValue: "list"*/)
    var format: OutputFormat = .list
}

struct UserCredentialsOptions: ParsableArguments {
    @Option(name: [.customShort("s"), .customLong("server")], help: "Server")
    var server: String

    @Option(name: [.customShort("m"), .customLong("name")], help: "User Name")
    var userName: String

    @Option(name: [.customShort("p"), .customLong("password")], help: "User Password")
    var password: String
}

struct ImportPathOptions: ParsableArguments {
    @Option(name: [.customShort("u"), .customLong("source")], help: "Import Source Path")
    var path: String
}

struct ImportStretchOptions: ParsableArguments {
    @Option(name: [.customLong("stretchPeriod")], help: "The period (in days) over which to randomly distribute emails. Dates will be left untouched if omitted.")
    var stretchPeriod: Int?
}

struct ImportMailOptions: ParsableArguments {
    @Option(name: [.customLong("adjustRecipient")], help: "Set the recipient to the user importing the mails")
    var adjustRecipient: Bool = false
}

struct GenerateAppointmentsOptions: ParsableArguments {
    @Option(name: [.customLong("days")], help: "The amount of days into the past and into the future to generate appointments")
    var days: Int = 185

    @Option(name: [.customLong("locale")], help: "The locale used for concatenation of names in appointment titles")
    var locale: String = "en_US"
}

struct GenerateContactsOptions: ParsableArguments {
    @Option(name: [.customLong("numberOfContacts")], help: "The number of contacts to generate")
    var numberOfContacts: Int = 20
}
