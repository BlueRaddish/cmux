import AppKit
import CmuxNextDesign

/// Workflow: notifications, quitting, and terminal handlers, in two glass
/// groups. Each control writes cmux.json at once.
final class WorkflowStepView: NSView {
    private let model: WorkflowStepModel
    private let desktop = SegmentedPill(titles: WorkflowStepModel.desktopModes.map { OnboardingStrings.desktopMode($0) })
    private let dismissal = SegmentedPill(titles: WorkflowStepModel.dismissalModes.map { OnboardingStrings.dismissalMode($0) })
    private let quit = SegmentedPill(titles: WorkflowStepModel.quitBehaviors.map { OnboardingStrings.quitBehavior($0) })
    private let terminal = ClaimRowView(symbol: "terminal", title: OnboardingStrings.terminalHandlersTitle,
                                        detail: OnboardingStrings.terminalHandlersDetail)
    private var loop: RenderLoop?

    init(model: WorkflowStepModel) {
        self.model = model
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        desktop.onSelect = { [weak model] in model?.choose(.desktopNotifications, WorkflowStepModel.desktopModes[$0]) }
        dismissal.onSelect = { [weak model] in model?.choose(.notificationDismissal, WorkflowStepModel.dismissalModes[$0]) }
        quit.onSelect = { [weak model] in model?.choose(.quitBehavior, WorkflowStepModel.quitBehaviors[$0]) }
        terminal.action.onPress = { [weak model] in model?.defaults.requestAllTerminalClaims() }
        let notifications = Column.make([
            OnboardingLabel.make(OnboardingStrings.notificationsHeader, font: Typography.header, color: Palette.textSecondary),
            SettingRowView(title: OnboardingStrings.desktopBanners, control: desktop),
            SettingRowView(title: OnboardingStrings.clearWhen, control: dismissal),
        ], spacing: Metrics.space2)
        Column.fill(notifications)
        let quitting = Column.make([
            OnboardingLabel.make(OnboardingStrings.quitHeader, font: Typography.header, color: Palette.textSecondary),
            SettingRowView(title: OnboardingStrings.whenQuitting, control: quit),
            OnboardingLabel.make(OnboardingStrings.quitNote, font: Typography.caption, color: Palette.textTertiary, lines: 2),
        ], spacing: Metrics.space2)
        Column.fill(quitting)
        let stack = Column.make([GlassCard.make(notifications), GlassCard.make(quitting), GlassCard.make(terminal, padding: Metrics.space3)],
                                spacing: Metrics.space5)
        Column.fill(stack)
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor), stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
        ])
        loop = RenderLoop { [weak self] in self?.render() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private func render() {
        desktop.selectedIndex = model.choice(.desktopNotifications, in: WorkflowStepModel.desktopModes, fallback: "unlessFocused")
        dismissal.selectedIndex = model.choice(.notificationDismissal, in: WorkflowStepModel.dismissalModes, fallback: "read")
        quit.selectedIndex = model.choice(.quitBehavior, in: WorkflowStepModel.quitBehaviors, fallback: "ask")
        let defaults = model.defaults
        let all = DefaultHandlerClaim.terminalClaims.allSatisfy(defaults.isClaimed)
        terminal.action.title = all ? OnboardingStrings.inUse : OnboardingStrings.useCmux
        terminal.action.isEnabled = !all && defaults.pending.isEmpty
    }
}
