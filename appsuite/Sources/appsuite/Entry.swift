import AppsuiteCore
import ArgumentParser

// The command tree lives in AppsuiteCore so the web service can reuse the same
// importers and generators. This executable is just the process entry point.
// The availability annotation is required for an asynchronous root command.
@main
@available(macOS 13, *)
struct Entry {
    static func main() async {
        await Appsuite.main()
    }
}
