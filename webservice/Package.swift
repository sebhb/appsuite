// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "appsuite-web",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(path: "../appsuite"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "AppsuiteWeb",
            dependencies: [
                .product(name: "AppsuiteCore", package: "appsuite"),
                .product(name: "Hummingbird", package: "hummingbird"),
            ],
            path: "Sources/AppsuiteWeb"
        ),
    ]
)
