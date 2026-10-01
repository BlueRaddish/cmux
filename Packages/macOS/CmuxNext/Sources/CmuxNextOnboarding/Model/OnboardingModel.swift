public import CmuxNextDesign
public import Foundation
public import Observation

/// The onboarding flow: short, skippable steps. Every step's work is async
/// and cancellable; nothing here blocks the main thread. Changes apply live
/// as the user makes them; Skip on a step (or closing before its Continue)
/// puts that step's settings back.
@MainActor
@Observable
public final class OnboardingModel {
    public enum Step: String, CaseIterable, Sendable {
        case welcome, appearance, browser, keyboard, workflow, accounts, ready
    }

    public private(set) var step: Step
    /// Direction of the last move, for the slide animation.
    public private(set) var movedForward = true
    /// The steps of this flow (`accounts` only when the App supplies it).
    public let steps: [Step]
    public let appearance: AppearanceStepModel
    public let importer: ImportStepModel
    public let defaults: DefaultAppsStepModel
    public let keyboard: KeyboardStepModel
    public let workflow: WorkflowStepModel
    public let tour: TourStepModel
    @ObservationIgnored public let services: any OnboardingServices
    /// Set once the flow ended, so a second close does not report twice.
    public private(set) var ended = false
    /// The window asks to close (the controller observes this).
    public var onEnd: ((Bool) -> Void)?

    public var theme: ThemeStepModel { appearance.theme }

    public init(services: any OnboardingServices, start: Step = .welcome) {
        self.services = services
        steps = Step.allCases.filter { $0 != .accounts || services.hasAccountsStep }
        step = steps.contains(start) ? start : .welcome
        appearance = AppearanceStepModel(services: services)
        importer = ImportStepModel(services: services)
        let defaults = DefaultAppsStepModel(services: services)
        self.defaults = defaults
        keyboard = KeyboardStepModel(services: services)
        workflow = WorkflowStepModel(services: services, defaults: defaults)
        tour = TourStepModel(services: services)
    }

    public var index: Int { steps.firstIndex(of: step) ?? 0 }
    public var isFirst: Bool { step == steps.first }
    public var isLast: Bool { step == steps.last }

    /// Continue: keeps the step's choices, then moves on (or finishes).
    public func next() {
        commit(step)
        guard !isLast else { return finish(completed: true) }
        go(to: steps[index + 1])
    }

    public func back() {
        guard !isFirst else { return }
        go(to: steps[index - 1])
    }

    /// Skip this step: undo what it changed, then move on.
    public func skipStep() {
        revert(step)
        guard !isLast else { return finish(completed: true) }
        go(to: steps[index + 1])
    }

    public func go(to target: Step) {
        guard target != step, steps.contains(target) else { return }
        movedForward = (steps.firstIndex(of: target) ?? 0) > index
        step = target
        stepDidAppear()
    }

    /// Starts the step's lazy work (theme files and fonts, browser
    /// detection, handler state).
    public func stepDidAppear() {
        switch step {
        case .welcome, .appearance: appearance.load()
        case .browser:
            importer.detect()
            defaults.refresh()
        case .workflow: defaults.refresh()
        case .keyboard, .accounts, .ready: break
        }
    }

    private func commit(_ step: Step) {
        switch step {
        case .appearance: appearance.commit()
        case .keyboard: keyboard.commit()
        case .workflow: workflow.draft.commit()
        default: break
        }
    }

    private func revert(_ step: Step) {
        switch step {
        case .appearance: appearance.revert()
        case .keyboard: keyboard.revert()
        case .workflow: workflow.draft.revert()
        default: break
        }
    }

    /// Ends the flow: `completed` false means skipped (Escape, close button).
    /// Steps the user changed but never continued past are put back.
    public func finish(completed: Bool) {
        guard !ended else { return }
        ended = true
        importer.cancel()
        if !completed {
            if !appearance.isCommitted { appearance.revert() }
            if !keyboard.isCommitted { keyboard.revert() }
            if !workflow.draft.isCommitted { workflow.draft.revert() }
        }
        services.onboardingDidEnd(completed: completed)
        onEnd?(completed)
    }
}
