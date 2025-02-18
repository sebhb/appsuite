//
//  File.swift
//  oxcloud
//
//  Created by Sebastian Krauß on 01.02.25.
//

import ArgumentParser
import Foundation

struct OutputFormatOptions: ParsableArguments {
    @Option(name: [.customShort("o"), .customLong("output")], help: "Output format (list, json)"/*, defaultValue: "list"*/)
    var format: OutputFormat = .list
}

enum OutputFormat: String, ExpressibleByArgument {
    case list, json
}
