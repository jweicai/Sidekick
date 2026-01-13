// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TableQuery",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "TableQuery",
            targets: ["TableQuery"]
        )
    ],
    targets: [
        .executableTarget(
            name: "TableQuery",
            path: "Sources"
        )
    ]
)
