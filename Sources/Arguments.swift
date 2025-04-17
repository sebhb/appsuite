//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 17.04.25.
//

import Foundation
import ArgumentParser

struct OutputFormatOptions: ParsableArguments {
    @Option(name: [.customShort("o"), .customLong("output")], help: "Output format (list, json)"/*, defaultValue: "list"*/)
    var format: OutputFormat = .list
}

struct BrandOptions: ParsableArguments {
    @Option(name: [.customLong("defaultbrand")], help: "The name of the brand in the defaults")
    var defaultName: String?

    @Option(name: [.customShort("d"), .customLong("datacenter")], help: "App Suite Data Center (eu, us, asia)")
    var dataCenter: DataCenter?

    @Option(name: [.customShort("n"), .customLong("brandname")], help: "Brand name")
    var brandName: String?

    @Option(name: [.customShort("a"), .customLong("brandauth")], help: "Brand auth")
    var brandAuth: String?

    mutating func validate() throws {
        if brandName == nil || brandAuth == nil {
            if let defaultName = defaultName {
                let allBrands = configuredBrands()
                if let brand = allBrands.first(where: { $0.name == defaultName }) {
                    brandName = brand.brandName
                    brandAuth = brand.brandAuth
                    dataCenter = brand.dataCenter
                    return
                }
                throw ValidationError("No default brand with priovided name configured.")
            }

            if let brand = defaultBrand() {
                brandName = brand.brandName
                brandAuth = brand.brandAuth
                dataCenter = brand.dataCenter
                return
            }

            throw ValidationError("Brandname and brandauth have to be set if no brand name is provided.")
        }
    }
}

struct ClassOfServiceOptions: ParsableArguments {
    @Option(name: [.customLong("set")], help: "The classes of service to set")
    var classesToSet: [String] = []

    @Option(name: [.customLong("add")], help: "The classes of service to add")
    var classesToAdd: [String] = []

    mutating func validate() throws {
        let numberOfClassesToSet = classesToSet.count
        let numberOfClassesToAdd = classesToAdd.count

        if numberOfClassesToSet == 0 && numberOfClassesToAdd > 0 { return }
        if numberOfClassesToSet > 0 && numberOfClassesToAdd == 0 { return }

        throw ValidationError("have to either specify classes to set or classes to add. You can not do both or none.")
    }
}

struct SearchOptions: ParsableArguments {
    @Option(name: [.customShort("q"), .customLong("query")], help: "Search query")
    var query: String
}

struct ContextNameOptions: ParsableArguments {
    @Option(name: [.customShort("c"), .customLong("context")], help: "Context name")
    var contextName: String
}

struct UserNameOptions: ParsableArguments {
    @Option(name: [.customLong("name")], help: "User Name")
    var userName: String
}

struct UserCredentialsOptions: ParsableArguments {
    @Option(name: [.customShort("s"), .customLong("server")], help: "Server")
    var server: String

    @Option(name: [.customShort("m"), .customLong("name")], help: "User Name")
    var userName: String

    @Option(name: [.customShort("p"), .customLong("password")], help: "User Password")
    var password: String
}

struct UserCreationOptions: ParsableArguments {
    @Option(name: [.customShort("e"), .customLong("email")], help: "User Email")
    var email: String

    @Option(name: [.customShort("r"), .customLong("surname")], help: "User Surname")
    var userSurname: String

    @Option(name: [.customShort("g"), .customLong("givenname")], help: "User Given Name")
    var userGivenname: String
}

struct ThemeOptions: ParsableArguments {
    // https://documentation.open-xchange.com/8/ui/theming/dynamic-theming.html#specifying-a-theme

    @Option(name: [.customLong("mainColor")], help: "Theme's mainColor")
    var mainColor: String?

    @Option(name: [.customLong("linkColor")], help: "Theme's linkColor")
    var linkColor: String?

    @Option(name: [.customLong("toolbarColor")], help: "Theme's toolbarColor")
    var toolbarColor: String?

    @Option(name: [.customLong("logoUrlLight")], help: "Theme's logoUrlLight")
    var logoUrlLight: String?

    @Option(name: [.customLong("logoUrlDark")], help: "Theme's logoUrlDark")
    var logoUrlDark: String?

    @Option(name: [.customLong("logoWidth")], help: "Theme's logoWidth")
    var logoWidth: String?

    @Option(name: [.customLong("logoHeight")], help: "Theme's logoHeight")
    var logoHeight: String?

    @Option(name: [.customLong("topbarBackground")], help: "Theme's topbarBackground")
    var topbarBackground: String?

    @Option(name: [.customLong("topbarHover")], help: "Theme's topbarHover")
    var topbarHover: String?

    @Option(name: [.customLong("topbarColor")], help: "Theme's topbarColor")
    var topbarColor: String?

    @Option(name: [.customLong("topbarSelected")], help: "Theme's topbarSelected")
    var topbarSelected: String?

    @Option(name: [.customLong("listSelected")], help: "Theme's listSelected")
    var listSelected: String?

    @Option(name: [.customLong("listHover")], help: "Theme's listHover")
    var listHover: String?

    @Option(name: [.customLong("listSelectedFocus")], help: "Theme's listSelectedFocus")
    var listSelectedFocus: String?

    @Option(name: [.customLong("folderBackground")], help: "Theme's folderBackground")
    var folderBackground: String?

    @Option(name: [.customLong("folderSelected")], help: "Theme's folderSelected")
    var folderSelected: String?

    @Option(name: [.customLong("folderHover")], help: "Theme's folderHover")
    var folderHover: String?

    @Option(name: [.customLong("folderSelectedFocus")], help: "Theme's folderSelectedFocus")
    var folderSelectedFocus: String?

    @Option(name: [.customLong("mailDetailCSS")], help: "Theme's mailDetailCSS")
    var mailDetailCSS: String?

    @Option(name: [.customLong("serverContact")], help: "Theme's serverContact")
    var serverContact: String?

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
