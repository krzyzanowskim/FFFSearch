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
            url: "https://github.com/krzyzanowskim/FFFSearch/releases/download/0.11.0/CFFF.xcframework.zip",
            checksum: "3fe729e7d0415c8651da47596ae79d6276200eb3212ba6212053eb99c7d4973f"
        ),
        .target(
            name: "FFFSearch",
            dependencies: ["CFFF"],
            path: "Sources/FFFSearch"
        )
    ]
)
