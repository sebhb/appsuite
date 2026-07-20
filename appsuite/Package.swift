// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "appsuite",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Library exposing the App Suite logic so other packages (e.g. the web
        // service) can drive the same importers/generators the CLI uses.
        .library(name: "AppsuiteCore", targets: ["AppsuiteCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.20.0"),
        // NIO modules used directly by the networking layer. async-http-client
        // pulls these in transitively, but stricter (Linux) toolchains require
        // the modules we `import` to be declared explicitly.
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.86.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.33.0"),
    ],
    targets: [
        // All networking, workers, models, generators and the ArgumentParser
        // command tree live here so both front-ends share identical behavior.
        .target(
            name: "AppsuiteCore",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOFoundationCompat", package: "swift-nio"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
            ]),
        // Thin executable: just the process entry point calling into AppsuiteCore.
        .executableTarget(
            name: "appsuite",
            dependencies: [
                "AppsuiteCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
    ]
)
