import Foundation
public import Observation

/// A cmux.json value the onboarding writes (the App converts it to its
/// settings JSON). Nil means "remove the key" (back to the default).
public nonisolated enum OnboardingValue: Sendable, Hashable {
    case string(String)
    case number(Double)
    case bool(Bool)

    public var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    public var numberValue: Double? {
        if case .number(let value) = self { return value }
        return nil
    }
}

/// cmux.json keys the flow edits, each with the path the Settings schema uses.
public nonisolated enum OnboardingSetting: String, Sendable, CaseIterable {
    case terminalFontFamily, terminalFontSize, titlebar, panePadding, paneBorder
    case desktopNotifications, notificationDismissal, quitBehavior

    public var path: [String] {
        switch self {
        case .terminalFontFamily: ["terminal", "fontFamily"]
        case .terminalFontSize: ["terminal", "fontSize"]
        case .titlebar: ["window", "titlebar"]
        case .panePadding: ["layout", "panePadding"]
        case .paneBorder: ["layout", "paneBorder"]
        case .desktopNotifications: ["notifications", "desktop"]
        case .notificationDismissal: ["notifications", "dismissal"]
        case .quitBehavior: ["app", "quitBehavior"]
        }
    }
}

/// Live edits of one step: each write applies at once (so the app shows
/// it), the value from before the first write is remembered, and `revert`
/// puts every touched key back (Skip, or closing before Continue).
@MainActor
@Observable
public final class SettingsDraft {
    public private(set) var values: [OnboardingSetting: OnboardingValue?] = [:]
    @ObservationIgnored private var originals: [OnboardingSetting: OnboardingValue?] = [:]
    @ObservationIgnored private let services: any OnboardingServices
    public private(set) var isCommitted = false

    init(services: any OnboardingServices) {
        self.services = services
    }

    /// The value shown: this step's edit, else the current setting.
    public func value(_ setting: OnboardingSetting) -> OnboardingValue? {
        if let edited = values[setting] { return edited }
        return services.setting(setting.path)
    }

    public func set(_ setting: OnboardingSetting, _ value: OnboardingValue?) {
        if originals[setting] == nil { originals[setting] = .some(services.setting(setting.path)) }
        guard self.value(setting) != value else { return }
        values[setting] = .some(value)
        services.setSetting(setting.path, value)
    }

    public var hasChanges: Bool { !originals.isEmpty }

    func commit() { isCommitted = true }

    func revert() {
        isCommitted = false
        for (setting, original) in originals where values[setting] != nil { services.setSetting(setting.path, original) }
        originals = [:]
        values = [:]
    }
}
