import Foundation
public import Observation

/// Workflow step: macOS banners, how notifications clear, what quitting
/// does to running terminals, and the terminal handlers (`defaults`).
@MainActor
@Observable
public final class WorkflowStepModel {
    public let draft: SettingsDraft
    public let defaults: DefaultAppsStepModel

    /// Raw values of `notifications.desktop`, in display order.
    public static let desktopModes = ["unlessFocused", "always", "whenInactive", "never"]
    /// Raw values of `notifications.dismissal`.
    public static let dismissalModes = ["keystroke", "focus", "never"]
    /// Raw values of `app.quitBehavior`.
    public static let quitBehaviors = ["ask", "keep", "end-keep-layout", "end-everything"]

    init(services: any OnboardingServices, defaults: DefaultAppsStepModel) {
        draft = SettingsDraft(services: services)
        self.defaults = defaults
    }

    public func choice(_ setting: OnboardingSetting, in values: [String], fallback: String) -> Int {
        values.firstIndex(of: draft.value(setting)?.stringValue ?? fallback) ?? 0
    }

    public func choose(_ setting: OnboardingSetting, _ value: String) {
        draft.set(setting, .string(value))
    }
}
