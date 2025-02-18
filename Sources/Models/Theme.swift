//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 05.02.25.
//

import Foundation

struct Theme: Decodable, Encodable {
    let mainColor: String?
    let linkColor: String?
    let toolbarColor: String?
    let logoUrlLight: String?
    let logoUrlDark: String?
    let logoWidth: String?
    let logoHeight: String?
    let topbarBackground: String?
    let topbarHover: String?
    let topbarColor: String?
    let topbarSelected: String?
    let listSelected: String?
    let listHover: String?
    let listSelectedFocus: String?
    let folderBackground: String?
    let folderSelected: String?
    let folderHover: String?
    let folderSelectedFocus: String?
    let mailDetailCSS: String?
    let serverContact: String?

    static func from(_ themeOptions: ThemeOptions) -> Theme {
        return Theme(mainColor: themeOptions.mainColor, linkColor: themeOptions.linkColor, toolbarColor: themeOptions.toolbarColor, logoUrlLight: themeOptions.logoUrlLight, logoUrlDark: themeOptions.logoUrlDark, logoWidth: themeOptions.logoWidth, logoHeight: themeOptions.logoHeight, topbarBackground: themeOptions.topbarBackground, topbarHover: themeOptions.topbarHover, topbarColor: themeOptions.topbarColor, topbarSelected: themeOptions.topbarSelected, listSelected: themeOptions.listSelected, listHover: themeOptions.listHover, listSelectedFocus: themeOptions.listSelectedFocus, folderBackground: themeOptions.folderBackground, folderSelected: themeOptions.folderSelected, folderHover: themeOptions.folderHover, folderSelectedFocus: themeOptions.folderSelectedFocus, mailDetailCSS: themeOptions.mailDetailCSS, serverContact: themeOptions.serverContact)
    }
}
