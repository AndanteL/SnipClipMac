// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SnipClipMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "SnipClipCore", targets: ["SnipClipCore"]),
        .library(name: "SnipClipUI", targets: ["SnipClipUI"])
    ],
    targets: [
        .target(
            name: "SnipClipCore",
            path: "Sources/SnipClipCore"
        ),
        .target(
            name: "SnipClipUI",
            dependencies: ["SnipClipCore"],
            path: "Sources/SnipClipUI"
        ),
        .testTarget(
            name: "SnipClipCoreTests",
            dependencies: ["SnipClipCore"],
            path: "Tests/SnipClipCoreTests"
        )
    ]
)
