import AppKit
import CmuxNextDesign

/// One thing cmux can handle (a link kind, a default app): icon, title,
/// detail, and a button that turns into an "In Use" check.
final class ClaimRowView: NSView {
    let action = OnboardingButton(OnboardingStrings.use, style: .secondary)
    private let detailLabel: NSTextField
    private let detailText: String
    private let status = OnboardingLabel.make(OnboardingStrings.inUse, font: Typography.caption, color: Palette.textSecondary)
    private let statusIcon = NSImageView()

    init(symbol: String, title: String, detail: String) {
        detailText = detail
        detailLabel = OnboardingLabel.make(detail, font: Typography.caption, color: Palette.textTertiary)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        let icon = NSImageView()
        icon.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        icon.symbolConfiguration = .init(pointSize: Metrics.iconSize + 2, weight: .regular)
        icon.contentTintColor = Palette.textSecondary
        icon.translatesAutoresizingMaskIntoConstraints = false
        let titleLabel = OnboardingLabel.make(title, font: Typography.bodyEmphasized)
        let text = NSStackView(views: [titleLabel, detailLabel])
        text.orientation = .vertical
        text.alignment = .leading
        text.spacing = Metrics.space1
        statusIcon.image = NSImage(systemSymbolName: "checkmark", accessibilityDescription: nil)
        statusIcon.contentTintColor = Palette.textSecondary
        let statusRow = NSStackView(views: [statusIcon, status])
        statusRow.spacing = Metrics.space2
        let row = NSStackView(views: [icon, text, FlexibleSpace(), statusRow, action])
        row.spacing = Metrics.space5
        row.edgeInsets = NSEdgeInsets(top: Metrics.space5, left: Metrics.space6, bottom: Metrics.space5, right: Metrics.space5)
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor), row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.topAnchor.constraint(equalTo: topAnchor), row.bottomAnchor.constraint(equalTo: bottomAnchor),
            icon.widthAnchor.constraint(equalToConstant: Metrics.space6 + Metrics.space2),
            // The same height with the button or the status, so rows never jump.
            heightAnchor.constraint(greaterThanOrEqualToConstant: OnboardingMetrics.buttonHeight + Metrics.space5 * 2),
        ])
        statusRow.isHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func setState(claimed: Bool, pending: Bool, error: String?) {
        action.isHidden = claimed
        action.isEnabled = !pending
        status.superview?.isHidden = !claimed
        detailLabel.stringValue = error.map(OnboardingStrings.systemRefused) ?? detailText
        detailLabel.textColor = error == nil ? Palette.textTertiary : Palette.danger
    }
}

/// A hairline between list rows.
final class SeparatorView: ThemedView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        fill = { Palette.separator }
        heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
}
