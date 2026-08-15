// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MarkdownRenderer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "MarkdownRenderer",
            type: .static,
            targets: ["MarkdownRenderer"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MarkdownRenderer",
            dependencies: []
        ),
        .testTarget(
            name: "MarkdownRendererTests",
            dependencies: ["MarkdownRenderer"]
        ),
    ]
)
