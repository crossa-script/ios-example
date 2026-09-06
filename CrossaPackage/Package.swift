// swift-tools-version: 6.0
// Local development override. A published binary target uses url + checksum
// from the generated project-specific Release SDK (not a universal runtime).

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
