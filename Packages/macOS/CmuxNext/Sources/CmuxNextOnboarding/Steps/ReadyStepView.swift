import AppKit
import CmuxNextDesign

/// Ready: the key ideas tour, plus machines to connect now (each button
/// runs the same action as the palette).
final class ReadyStepView: NSView {
    init(tour: TourStepModel, services: any OnboardingServices) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        let tourView = TourStepView(model: tour)
        var buttons: [NSView] = [OnboardingLabel.make(OnboardingStrings.machinesHeader, font: Typography.header, color: Palette.textSecondary),
                                 FlexibleSpace()]
        for (action, title) in [("remote.connect", OnboardingStrings.connectSSH), ("newCloudMachine", OnboardingStrings.newCloudMachine)]
        where services.isActionAvailable(action) {
            buttons.append(OnboardingButton(title, style: .secondary) { [weak services] in services?.runAction(action) })
        }
        let machines = NSStackView(views: buttons)
        machines.spacing = Metrics.space4
        let card = GlassCard.make(machines, padding: Metrics.space5)
        addSubview(tourView)
        addSubview(card)
        NSLayoutConstraint.activate([
            tourView.leadingAnchor.constraint(equalTo: leadingAnchor), tourView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tourView.topAnchor.constraint(equalTo: topAnchor),
            tourView.bottomAnchor.constraint(equalTo: card.topAnchor, constant: -Metrics.space5),
            card.leadingAnchor.constraint(equalTo: leadingAnchor), card.trailingAnchor.constraint(equalTo: trailingAnchor),
            card.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
}
