// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FFFSearch",
    platforms: [
        .macOS(.v13)
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
            path: "Binary/CFFF.xcframework"
        ),
        .target(
            name: "FFFSearch",
            dependencies: ["CFFF"],
            path: "Sources/FFFSearch"
        )
    ]
)
