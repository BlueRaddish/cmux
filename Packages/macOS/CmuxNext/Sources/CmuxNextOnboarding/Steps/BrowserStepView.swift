import AppKit
import CmuxNextDesign

/// Browser: the import (sources and choices) above one row that makes cmux
/// the default browser (macOS asks to confirm).
final class BrowserStepView: NSView {
    private let defaults: DefaultAppsStepModel
    private let row = ClaimRowView(symbol: "globe", title: OnboardingStrings.makeDefaultBrowser, detail: OnboardingStrings.confirmHint)
    private var loop: RenderLoop?

    init(importer: ImportStepModel, defaults: DefaultAppsStepModel) {
        self.defaults = defaults
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        let imports = ImportStepView(model: importer)
        row.action.title = OnboardingStrings.makeDefault
        row.action.onPress = { [weak defaults] in defaults?.request(.webBrowser) }
        let card = GlassCard.make(row, padding: 0)
        addSubview(imports)
        addSubview(card)
        NSLayoutConstraint.activate([
            imports.leadingAnchor.constraint(equalTo: leadingAnchor), imports.trailingAnchor.constraint(equalTo: trailingAnchor),
            imports.topAnchor.constraint(equalTo: topAnchor),
            imports.bottomAnchor.constraint(equalTo: card.topAnchor, constant: -Metrics.space5),
            card.leadingAnchor.constraint(equalTo: leadingAnchor), card.trailingAnchor.constraint(equalTo: trailingAnchor),
            card.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        loop = RenderLoop { [weak self] in self?.render() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private func render() {
        let claimed = defaults.isClaimed(.webBrowser)
        row.setState(claimed: claimed, pending: defaults.pending.contains(.webBrowser), error: defaults.errors[.webBrowser])
    }
}
