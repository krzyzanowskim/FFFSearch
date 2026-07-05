// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FFFSearch",
    platforms: [
        .macOS(.v13),
        .iOS(.v13),
        .tvOS(.v13),
        .visionOS(.v1),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "FFFSearch",
            targets: ["FFFSearch"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "CFFF",
            url: "https://github.com/krzyzanowskim/FFFSearch/releases/download/0.9.6/CFFF.xcframework.zip",
            checksum: "bbd9b864fab17aa4425a86e5077e2c14e9a7df82ea7f7771c17d05561d1bfdf2"
        ),
        .target(
            name: "FFFSearch",
            dependencies: ["CFFF"],
            path: "Sources/FFFSearch"
        )
    ]
)
