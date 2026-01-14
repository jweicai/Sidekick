// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Sidekick",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Sidekick",
            targets: ["Sidekick"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/CoreOffice/CoreXLSX.git", from: "0.14.0")
    ],
    targets: [
        .executableTarget(
            name: "Sidekick",
            dependencies: ["CoreXLSX"],
            path: "Sources",
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        ),
        .testTarget(
            name: "SidekickTests",
            dependencies: ["Sidekick"],
            path: "Tests"
        )
    ]
)
