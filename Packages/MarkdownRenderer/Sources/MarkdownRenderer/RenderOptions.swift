import Foundation

public struct RenderOptions: Sendable {
    public var enableSyntaxHighlighting: Bool
    public var enableMath: Bool
    public var enableCallouts: Bool
    public var enableFrontmatter: Bool
    public var enableWikilinks: Bool

    public static let `default` = RenderOptions(
        enableSyntaxHighlighting: true,
        enableMath: true,
        enableCallouts: true,
        enableFrontmatter: true,
        enableWikilinks: true
    )

    public init(
        enableSyntaxHighlighting: Bool = true,
        enableMath: Bool = true,
        enableCallouts: Bool = true,
        enableFrontmatter: Bool = true,
        enableWikilinks: Bool = true
    ) {
        self.enableSyntaxHighlighting = enableSyntaxHighlighting
        self.enableMath = enableMath
        self.enableCallouts = enableCallouts
        self.enableFrontmatter = enableFrontmatter
        self.enableWikilinks = enableWikilinks
    }
}
