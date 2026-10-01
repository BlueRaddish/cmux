import AppKit
import CmuxNextActions
import CmuxNextOnboarding
import CmuxNextSettings
import Testing

/// What onboarding writes must be what cmux reads: every preset names real
/// actions with valid, display-matching chords that do not take another
/// action's default, and every choice value is one the Settings schema allows.
@MainActor
@Suite struct OnboardingSettingsContractTests {
    let registry = ActionRegistry.standard()

    @Test(arguments: ShortcutPreset.all)
    func presetIsValid(_ preset: ShortcutPreset) throws {
        let rebound = Set(preset.bindings.map(\.actionID))
        for binding in preset.bindings {
            #expect(registry.descriptor(for: ActionID(rawValue: binding.actionID)) != nil, "\(binding.actionID) is not an action")
            let stroke = try #require(ShortcutBindingFormat.parseStroke(binding.chord), "\(binding.chord) does not parse")
            let shortcut = SettingsApplier.shortcut(for: stroke)
            #expect(shortcut.displayString == binding.display, "\(binding.chord) shows as \(shortcut.displayString)")
            let taken = registry.descriptors.filter { $0.defaultShortcut == shortcut && !rebound.contains($0.id.rawValue) }
            #expect(taken.isEmpty, "\(binding.chord) is the default of \(taken.map(\.id.rawValue))")
        }
        #expect(Set(preset.bindings.map(\.chord)).count == preset.bindings.count, "a chord used twice")
    }

    @Test func choiceValuesAreAllowedBySettings() throws {
        let used: [(OnboardingSetting, [String])] = [
            (.desktopNotifications, WorkflowStepModel.desktopModes),
            (.notificationDismissal, WorkflowStepModel.dismissalModes),
            (.quitBehavior, WorkflowStepModel.quitBehaviors),
            (.titlebar, ["minimal", "standard"]),
            (.paneBorder, ["subtle", "none"]),
        ]
        for (setting, values) in used {
            let descriptor = try #require(SettingsSchema.descriptor(for: setting.path), "\(setting.path) is not in the schema")
            guard case .choice(let choices) = descriptor.kind else {
                Issue.record("\(setting.path) is not a choice")
                continue
            }
            #expect(Set(values).isSubset(of: Set(choices.map(\.value))), "\(setting.path): \(values) vs \(choices.map(\.value))")
        }
        let padding = try #require(SettingsSchema.descriptor(for: OnboardingSetting.panePadding.path))
        if case .number(let number) = padding.kind {
            #expect(AppearanceStepModel.paddingChoices.allSatisfy { number.range.contains($0) })
        }
    }
}
