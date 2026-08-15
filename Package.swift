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
    dependencies: [],
    targets: [
        .target(
            name: "MarkdownRenderer",
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
            path: "Packages/MarkdownRenderer/Tests/MarkdownRendererTests"
        )
    ]
)
