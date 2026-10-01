import AppKit
import CmuxNextDesign

/// Keyboard: four preset cards, each listing the keys it changes. The pick
/// applies at once; every key stays editable later (palette, Cmd-K).
final class KeyboardStepView: NSView {
    private let model: KeyboardStepModel
    private var cards: [ShortcutPreset.Kind: PresetCardView] = [:]
    private var loop: RenderLoop?

    init(model: KeyboardStepModel) {
        self.model = model
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        let row = NSStackView()
        row.distribution = .fillEqually
        row.spacing = Metrics.space5
        row.alignment = .top
        row.translatesAutoresizingMaskIntoConstraints = false
        for preset in ShortcutPreset.all {
            let card = PresetCardView(preset: preset, model: model)
            card.onSelect = { [weak model] in model?.select(preset.kind) }
            cards[preset.kind] = card
            row.addArrangedSubview(card)
        }
        let note = OnboardingLabel.make(OnboardingStrings.keyboardNote, font: Typography.caption, color: Palette.textTertiary, lines: 2)
        addSubview(row)
        addSubview(note)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor), row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.topAnchor.constraint(equalTo: topAnchor),
            note.leadingAnchor.constraint(equalTo: leadingAnchor), note.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            note.topAnchor.constraint(equalTo: row.bottomAnchor, constant: Metrics.space6),
        ])
        loop = RenderLoop { [weak self] in self?.render() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private func render() {
        for (kind, card) in cards { card.isSelected = kind == model.selected }
    }
}

/// One preset: symbol, name, one line, then action names with key caps.
final class PresetCardView: SelectableCard {
    init(preset: ShortcutPreset, model: KeyboardStepModel) {
        super.init(frame: .zero)
        cornerRadius = OnboardingMetrics.cornerRadius
        let icon = NSImageView(image: NSImage(systemSymbolName: preset.symbol, accessibilityDescription: nil) ?? NSImage())
        icon.contentTintColor = Palette.textPrimary
        icon.symbolConfiguration = .init(pointSize: Metrics.iconSize + Metrics.space2, weight: .regular)
        let title = OnboardingLabel.make(OnboardingStrings.presetName(preset.kind), font: Typography.bodyEmphasized)
        let detail = OnboardingLabel.make(OnboardingStrings.presetDetail(preset.kind), font: Typography.caption, color: Palette.textTertiary, lines: 2)
        var views: [NSView] = [icon, title, detail]
        for action in ShortcutPreset.previewActions {
            guard let keys = model.display(action, in: preset.kind) else { continue }
            let name = OnboardingLabel.make(OnboardingStrings.presetAction(action), font: Typography.caption, color: Palette.textSecondary)
            let line = NSStackView(views: [name, FlexibleSpace(), KeycapView.caps(for: keys)])
            line.spacing = Metrics.space3
            views.append(line)
        }
        let stack = Column.make(views, spacing: Metrics.space3)
        stack.setCustomSpacing(Metrics.space5, after: detail)
        for line in views.dropFirst(3) { line.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true }
        detail.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        addSubview(stack)
        let pad = Metrics.space6
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: pad), stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -pad),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: pad), stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -pad),
        ])
        setAccessibilityRole(.radioButton)
        setAccessibilityLabel(OnboardingStrings.presetName(preset.kind))
    }
}
