
// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AdaptivePerfKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "AdaptivePerfKit",
            targets: ["AdaptivePerfKit"]
        )
    ],
    targets: [
        .target(
            name: "AdaptivePerfKit"
        ),
        .testTarget(
            name: "AdaptivePerfKitTests",
            dependencies: ["AdaptivePerfKit"]
        )
    ]
)


