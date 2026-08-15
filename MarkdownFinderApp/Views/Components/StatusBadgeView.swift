import SwiftUI

public struct StatusBadgeView: View {
    public let title: String
    public let isEnabled: Bool
    public let subtitle: String?

    public init(title: String, isEnabled: Bool, subtitle: String? = nil) {
        self.title = title
        self.isEnabled = isEnabled
        self.subtitle = subtitle
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundColor(isEnabled ? .green : .orange)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(isEnabled ? "Active" : "Action Required")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(isEnabled ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                        .foregroundColor(isEnabled ? .green : .orange)
                        .clipShape(Capsule())
                }

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
        )
    }
}
