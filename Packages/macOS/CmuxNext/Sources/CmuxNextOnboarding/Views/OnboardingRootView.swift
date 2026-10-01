import AppKit
import CmuxNextDesign

/// The window's content: step counter, title and subtitle, the step body,
/// and a footer with progress bars, Skip, Back and Continue.
final class OnboardingRootView: ThemedView {
    private let model: OnboardingModel
    private let eyebrow = OnboardingLabel.make(font: Typography.caption, color: Palette.textTertiary)
    private let titleLabel = OnboardingLabel.make(font: Typography.title)
    private let subtitle = OnboardingLabel.make(font: Typography.subtitle, color: Palette.textSecondary, lines: 2)
    private let header = NSStackView()
    private let body = NSView()
    private let progress: StepProgressView
    private let skip = OnboardingButton(OnboardingStrings.skip, style: .plain)
    private let back = OnboardingButton(OnboardingStrings.back, style: .plain)
    private let next = OnboardingButton(OnboardingStrings.continueButton, style: .primary, keyHint: "↵")
    private var shownStep: OnboardingModel.Step?
    private var stepView: NSView?
    private var loop: RenderLoop?

    init(model: OnboardingModel) {
        self.model = model
        progress = StepProgressView(count: model.steps.count)
        super.init(frame: NSRect(origin: .zero, size: OnboardingMetrics.windowSize))
        translatesAutoresizingMaskIntoConstraints = true
        // The window background, redrawn at once on a theme change.
        fill = { Palette.windowBackground }
        header.orientation = .vertical
        header.alignment = .leading
        header.spacing = Metrics.space3
        header.setViews([eyebrow, titleLabel, subtitle], in: .top)
        header.setCustomSpacing(Metrics.space2, after: eyebrow)
        header.translatesAutoresizingMaskIntoConstraints = false
        body.translatesAutoresizingMaskIntoConstraints = false
        skip.onPress = { [weak model] in model?.skipStep() }
        back.onPress = { [weak model] in model?.back() }
        next.onPress = { [weak model] in model?.next() }
        let buttons = NSStackView(views: [skip, back, next])
        buttons.spacing = Metrics.space3
        buttons.translatesAutoresizingMaskIntoConstraints = false
        let footerLine = ThemedView()
        footerLine.fill = { Palette.separator }
        for view in [header, body, progress, buttons, footerLine] as [NSView] { addSubview(view) }
        let inset = OnboardingMetrics.contentInset
        let footer = OnboardingMetrics.footerHeight
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: topAnchor, constant: OnboardingMetrics.titleTop),
            header.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            header.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -inset),
            subtitle.widthAnchor.constraint(lessThanOrEqualToConstant: OnboardingMetrics.windowSize.width * 0.72),
            body.topAnchor.constraint(equalTo: header.bottomAnchor, constant: Metrics.space6 + Metrics.space4),
            body.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            body.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            body.bottomAnchor.constraint(equalTo: footerLine.topAnchor, constant: -Metrics.space6),
            footerLine.leadingAnchor.constraint(equalTo: leadingAnchor), footerLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            footerLine.heightAnchor.constraint(equalToConstant: 1),
            footerLine.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -footer),
            progress.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            progress.centerYAnchor.constraint(equalTo: bottomAnchor, constant: -footer / 2),
            buttons.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset + Metrics.space6),
            buttons.centerYAnchor.constraint(equalTo: progress.centerYAnchor),
        ])
        loop = RenderLoop { [weak self] in self?.render() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var isFlipped: Bool { true }

    private func render() {
        let step = model.step
        progress.current = model.index
        back.isHidden = model.isFirst
        skip.isHidden = model.isLast
        next.title = model.isLast ? OnboardingStrings.finish : (model.isFirst ? OnboardingStrings.getStarted : OnboardingStrings.continueButton)
        next.style = hasOwnPrimaryAction(step) ? .secondary : .primary
        guard step != shownStep else { return }
        let forward = model.movedForward || shownStep == nil
        shownStep = step
        eyebrow.stringValue = OnboardingStrings.stepCounter(model.index + 1, model.steps.count)
        titleLabel.stringValue = title(step)
        subtitle.stringValue = subtitleText(step)
        stepView?.removeFromSuperview()
        let view = makeStepView(step)
        body.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: body.leadingAnchor), view.trailingAnchor.constraint(equalTo: body.trailingAnchor),
            view.topAnchor.constraint(equalTo: body.topAnchor), view.bottomAnchor.constraint(equalTo: body.bottomAnchor),
        ])
        stepView = view
        body.layoutSubtreeIfNeeded()
        StepTransition.reveal(view, forward: forward)
        StepTransition.reveal(header, forward: forward, distance: OnboardingMetrics.slideDistance / 2)
    }

    /// While a step's own main action is still open, Continue steps back to secondary.
    private func hasOwnPrimaryAction(_ step: OnboardingModel.Step) -> Bool {
        guard step == .browser else { return false }
        if case .finished = model.importer.phase { return false }
        return model.importer.canStart || model.importer.isImporting
    }

    private func makeStepView(_ step: OnboardingModel.Step) -> NSView {
        switch step {
        case .welcome: WelcomeHeroView(model: model.appearance)
        case .appearance: AppearanceStepView(model: model.appearance)
        case .browser: BrowserStepView(importer: model.importer, defaults: model.defaults)
        case .keyboard: KeyboardStepView(model: model.keyboard)
        case .workflow: WorkflowStepView(model: model.workflow)
        case .accounts: accountsView()
        case .ready: ReadyStepView(tour: model.tour, services: model.services)
        }
    }

    private func accountsView() -> NSView {
        let view = model.services.makeAccountsStepView() ?? NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    private func title(_ step: OnboardingModel.Step) -> String {
        switch step {
        case .welcome: OnboardingStrings.welcomeTitle
        case .appearance: OnboardingStrings.appearanceTitle
        case .browser: OnboardingStrings.importTitle
        case .keyboard: OnboardingStrings.keyboardTitle
        case .workflow: OnboardingStrings.workflowTitle
        case .accounts: OnboardingStrings.accountsTitle
        case .ready: OnboardingStrings.tourTitle
        }
    }

    private func subtitleText(_ step: OnboardingModel.Step) -> String {
        switch step {
        case .welcome: OnboardingStrings.welcomeSubtitle
        case .appearance: OnboardingStrings.appearanceSubtitle
        case .browser: OnboardingStrings.importSubtitle
        case .keyboard: OnboardingStrings.keyboardSubtitle
        case .workflow: OnboardingStrings.workflowSubtitle
        case .accounts: OnboardingStrings.accountsSubtitle
        case .ready: OnboardingStrings.tourSubtitle
        }
    }
}
