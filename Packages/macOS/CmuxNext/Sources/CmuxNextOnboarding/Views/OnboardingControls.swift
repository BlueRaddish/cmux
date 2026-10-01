import AppKit
import CmuxNextDesign

/// A settings row: a caption on the left, its control on the right edge.
final class SettingRowView: NSView {
    init(title: String, control: NSView) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        let label = OnboardingLabel.make(title, font: Typography.body, color: Palette.textSecondary)
        control.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        addSubview(control)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: control.leadingAnchor, constant: -Metrics.space5),
            control.trailingAnchor.constraint(equalTo: trailingAnchor),
            control.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: OnboardingMetrics.rowHeight),
        ])
        setAccessibilityElement(false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
}

/// A Liquid Glass card (theme-tinted `NSGlassEffectView`) with padded content.
/// Used for the floating groups of each step; never behind terminal text.
enum GlassCard {
    static func make(_ content: NSView, padding: CGFloat = Metrics.space6) -> NSView {
        let inner = NSView()
        inner.translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        inner.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: inner.leadingAnchor, constant: padding),
            content.trailingAnchor.constraint(equalTo: inner.trailingAnchor, constant: -padding),
            content.topAnchor.constraint(equalTo: inner.topAnchor, constant: padding),
            content.bottomAnchor.constraint(equalTo: inner.bottomAnchor, constant: -padding),
        ])
        return Glass.makePanel(content: inner, cornerRadius: OnboardingMetrics.cornerRadius + Metrics.space2)
    }
}

/// A vertical stack with leading alignment and token spacing.
enum Column {
    static func make(_ views: [NSView], spacing: CGFloat = Metrics.space3) -> NSStackView {
        let stack = NSStackView(views: views)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = spacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    /// Pins every arranged subview to the stack's width.
    static func fill(_ stack: NSStackView) {
        for view in stack.arrangedSubviews { view.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true }
    }
}
