// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MarkdownFinder",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "MarkdownRenderer", targets: ["MarkdownRenderer"]),
        .library(name: "MarkdownFinderCore", targets: ["MarkdownFinderCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", exact: "0.8.0")
    ],
    targets: [
        .target(
            name: "MarkdownRenderer",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown")
            ],
            path: "Packages/MarkdownRenderer/Sources/MarkdownRenderer"
        ),
        .target(
            name: "MarkdownFinderCore",
            dependencies: ["MarkdownRenderer"],
            path: "Shared"
        ),
        .testTarget(
            name: "MarkdownFinderTests",
            dependencies: ["MarkdownFinderCore", "MarkdownRenderer"],
            path: "Tests",
            exclude: ["TestRunner.swift"]
        ),
        .testTarget(
            name: "MarkdownRendererTests",
            dependencies: ["MarkdownRenderer"],
            path: "Packages/MarkdownRenderer/Tests/MarkdownRendererTests",
            resources: [
                .copy("Fixtures")
            ]
        )
    ]
)
