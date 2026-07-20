import Foundation

/// Locates the bundled demo/seed data (the `Demo/` directory). The root is read
/// from the `APPSUITE_DEMO_DIR` environment variable, defaulting to `../Demo`
/// for local development. In the container it is set to `/app/Demo`.
struct DemoData: Sendable {

    /// The seeding "recipe" used for bundled data, mirroring `Demo/demo.sh`.
    enum Recipe {
        static let mailAdjustRecipient = true
        static let mailStretchPeriodDays = 180
        static let numberOfContacts = 30
        static let appointmentDays = 180
        static let appointmentLocale = "en_US"
    }

    let root: URL

    static func fromEnvironment() -> DemoData {
        let path = ProcessInfo.processInfo.environment["APPSUITE_DEMO_DIR"] ?? "../Demo"
        return DemoData(root: URL(fileURLWithPath: path))
    }

    var goldAccountsDir: URL { root.appendingPathComponent("GoldAccounts") }
    func goldAccountTree(_ name: String) -> URL { goldAccountsDir.appendingPathComponent(name) }
    var testfilesDir: URL { root.appendingPathComponent("testfiles") }
    var tasksJSON: URL { root.appendingPathComponent("tasks.json") }
    var contactTemplatesJSON: URL { root.appendingPathComponent("contactTemplates.json") }
    var appointmentTemplatesJSON: URL { root.appendingPathComponent("appointmentTemplates.json") }

    var isAvailable: Bool {
        FileManager.default.fileExists(atPath: goldAccountsDir.path)
    }

    /// Names of the bundled gold accounts (immediate subdirectories of GoldAccounts).
    func listGoldAccounts() -> [String] {
        let contents = (try? FileManager.default.contentsOfDirectory(at: goldAccountsDir, includingPropertiesForKeys: [.isDirectoryKey])) ?? []
        return contents
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            .map { $0.lastPathComponent }
            .filter { !$0.hasPrefix(".") }
            .sorted()
    }
}
