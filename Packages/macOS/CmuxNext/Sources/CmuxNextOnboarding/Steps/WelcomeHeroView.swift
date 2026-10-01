import AppKit
import CmuxNextDesign

/// Welcome: a live picture of cmux in the current theme, and what the next
/// minutes cover. Return starts; Escape skips everything.
final class WelcomeHeroView: NSView {
    init(model: AppearanceStepModel) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        let preview = LivePreviewView()
        let card = GlassCard.make(preview, padding: Metrics.space4)
        let points = [("paintbrush", OnboardingStrings.welcomePointLook), ("globe", OnboardingStrings.welcomePointBrowser),
                      ("keyboard", OnboardingStrings.welcomePointKeys), ("bolt", OnboardingStrings.welcomePointAgents)]
        let list = Column.make(points.map { symbol, text in
            let icon = NSImageView(image: NSImage(systemSymbolName: symbol, accessibilityDescription: nil) ?? NSImage())
            icon.contentTintColor = Palette.textSecondary
            icon.symbolConfiguration = .init(pointSize: Metrics.iconSize, weight: .regular)
            icon.widthAnchor.constraint(equalToConstant: Metrics.space6 + Metrics.space2).isActive = true
            let row = NSStackView(views: [icon, OnboardingLabel.make(text, font: Typography.body, color: Palette.textSecondary, lines: 2)])
            row.spacing = Metrics.space4
            return row
        }, spacing: Metrics.space5)
        let hint = OnboardingLabel.make(OnboardingStrings.welcomeKeysHint, font: Typography.caption, color: Palette.textTertiary, lines: 2)
        let side = Column.make([list, hint], spacing: Metrics.space6 + Metrics.space4)
        addSubview(card)
        addSubview(side)
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: leadingAnchor), card.topAnchor.constraint(equalTo: topAnchor),
            card.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.6),
            preview.heightAnchor.constraint(equalTo: preview.widthAnchor, multiplier: 0.62),
            side.leadingAnchor.constraint(equalTo: card.trailingAnchor, constant: Metrics.space6 * 2),
            side.trailingAnchor.constraint(equalTo: trailingAnchor),
            side.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            hint.widthAnchor.constraint(equalTo: side.widthAnchor),
        ])
        model.load()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
}
