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
            url: "https://github.com/krzyzanowskim/FFFSearch/releases/download/0.10.5/CFFF.xcframework.zip",
            checksum: "280d5ee79e876d8764ea7b87b1a687e92eae99442d064777ed83999ae4c36a2e"
        ),
        .target(
            name: "FFFSearch",
            dependencies: ["CFFF"],
            path: "Sources/FFFSearch"
        )
    ]
)
