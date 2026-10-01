import Foundation
public import Observation

/// Keyboard step: one shortcut preset, applied live; Skip or closing before
/// Continue restores the bindings from before.
@MainActor
@Observable
public final class KeyboardStepModel {
    public private(set) var selected: ShortcutPreset.Kind
    @ObservationIgnored private let services: any OnboardingServices
    @ObservationIgnored private var originals: [String: OnboardingValue?]?
    public private(set) var isCommitted = false

    init(services: any OnboardingServices) {
        self.services = services
        selected = Self.detect(services)
    }

    /// The preset whose bindings match cmux.json now (custom bindings count as cmux).
    static func detect(_ services: any OnboardingServices) -> ShortcutPreset.Kind {
        for preset in ShortcutPreset.all where !preset.bindings.isEmpty {
            let matches = preset.bindings.allSatisfy { services.setting(ShortcutPreset.path(for: $0.actionID))?.stringValue == $0.chord }
            if matches { return preset.kind }
        }
        return .cmux
    }

    public func select(_ kind: ShortcutPreset.Kind) {
        guard kind != selected else { return }
        if originals == nil {
            originals = Dictionary(uniqueKeysWithValues: ShortcutPreset.managedActions.map { ($0, services.setting(ShortcutPreset.path(for: $0))) })
        }
        selected = kind
        let chords = Dictionary(uniqueKeysWithValues: ShortcutPreset.preset(kind).bindings.map { ($0.actionID, $0.chord) })
        for action in ShortcutPreset.managedActions {
            services.setSetting(ShortcutPreset.path(for: action), chords[action].map(OnboardingValue.string))
        }
    }

    /// What a preset card shows for `actionID`: the preset's own chord, else
    /// the action's current shortcut.
    public func display(_ actionID: String, in kind: ShortcutPreset.Kind) -> String? {
        if let binding = ShortcutPreset.preset(kind).bindings.first(where: { $0.actionID == actionID }) { return binding.display }
        return services.defaultShortcutDisplay(for: actionID)
    }

    func commit() { isCommitted = true }

    func revert() {
        isCommitted = false
        guard let originals else { return }
        for (action, value) in originals { services.setSetting(ShortcutPreset.path(for: action), value) }
        self.originals = nil
        selected = Self.detect(services)
    }
}
