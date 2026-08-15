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
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", exact: "0.8.0")
    ],
    targets: [
        .target(
            name: "MarkdownRenderer",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown")
            ]
        ),
        .testTarget(
            name: "MarkdownRendererTests",
            dependencies: ["MarkdownRenderer"],
            resources: [
                .copy("Fixtures")
            ]
        ),
    ]
)

