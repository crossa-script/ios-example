// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CrossaBinary",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(
            name: "CrossaBinary",
            targets: ["Crossa"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "Crossa",
            path: "../CrossaBinary/Crossa.xcframework"
        )
    ]
)
