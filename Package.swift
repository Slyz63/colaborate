// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "ContextDriftDetector",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ContextDriftDetector",
            targets: ["ContextDriftDetector"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ContextDriftDetector",
            path: "Sources/ContextDriftDetector"
        ),
        .testTarget(
            name: "ContextDriftDetectorTests",
            dependencies: ["ContextDriftDetector"],
            path: "Tests/ContextDriftDetectorTests"
        )
    ]
)
