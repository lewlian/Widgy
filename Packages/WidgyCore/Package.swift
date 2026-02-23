// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "WidgyCore",
    platforms: [
        .iOS(.v26),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "WidgyCore",
            targets: ["WidgyCore"]
        )
    ],
    targets: [
        .target(
            name: "WidgyCore",
            path: "Sources/WidgyCore"
        ),
        .testTarget(
            name: "WidgyCoreTests",
            dependencies: ["WidgyCore"],
            path: "Tests/WidgyCoreTests"
        )
    ]
)
