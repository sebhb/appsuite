import ArgumentParser
import Foundation

enum OutputFormat: String, ExpressibleByArgument {
    case list, json
}

func output<T: Outputtable>(item: T) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted

    guard let data = try? encoder.encode(item) else { return }
    print(String(data: data, encoding: .utf8)!)
}

func output<T: Outputtable>(items: [T], format: OutputFormat) {
    guard items.count > 0 else {
        print("0 results")
        return
    }
    switch format {
        case .list:
            let type = type(of: items.first!)

            let byteFormatter = ByteCountFormatter()
            byteFormatter.allowedUnits = .useMB
            byteFormatter.formattingContext = .listItem
            byteFormatter.allowsNonnumericFormatting = false

            let configuration = type.configuration(for: items, formatter: byteFormatter)

            var overallHeaderWidth = 0
            var header = ""
            for column in configuration.columns {
                let columnName = type.name(for: column)
                let width = configuration.columnWidths[column] ?? 0
                header += columnName.padding(toLength: width, withPad: " ", startingAt: 0)
                overallHeaderWidth += width
            }
            print(header)
            print("".padding(toLength: overallHeaderWidth, withPad: "-", startingAt: 0))

            for item in items {
                var line = ""
                for column in configuration.columns {
                    let width = configuration.columnWidths[column] ?? 0
                    line += item.displayValue(for: column, formatter: byteFormatter).padding(toLength: width, withPad: " ", startingAt: 0)
                    overallHeaderWidth += width
                }
                print(line)
            }
        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted

            guard let data = try? encoder.encode(items) else { return }
            print(String(data: data, encoding: .utf8)!)
    }
}

func showProgress(progress: Double) {
    let barWidth = 50
    let filledWidth = Int(progress * Double(barWidth))
    let emptyWidth = barWidth - filledWidth

    let progressBar = String(repeating: "=", count: filledWidth) + String(repeating: " ", count: emptyWidth)
    let percentage = Int(progress * 100)

    print("\r\u{1B}[K[\(progressBar)] \(percentage)%", terminator: "")
    fflush(__stdoutp)
}
