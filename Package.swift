// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MacGlue",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MacGlue", targets: ["MacGlue"])
    ],
    targets: [
        .executableTarget(
            name: "MacGlue"
        )
    ]
)
