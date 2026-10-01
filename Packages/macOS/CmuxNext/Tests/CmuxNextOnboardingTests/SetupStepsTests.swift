import CmuxNextBrowserImport
import CmuxNextDesign
import Foundation
import Testing
@testable import CmuxNextOnboarding

/// The appearance, keyboard and workflow steps, and the import's new
/// choices, against the mock services (no settings file, no browsers).
@MainActor
@Suite struct SetupStepsTests {
    func settle(_ condition: () -> Bool) async {
        for _ in 0..<200 where !condition() { await Task.yield() }
    }

    func choice(_ name: String, background: ThemeRGB) -> ThemeChoice {
        var input = ThemeInput.ghosttyDefault
        input.background = background
        return ThemeChoice(name: name, input: input)
    }

    @Test func appearanceAppliesLiveAndSkipRestoresEverything() {
        let services = MockOnboardingServices()
        services.settings["window.titlebar"] = .string("standard")
        let model = OnboardingModel(services: services, start: .appearance)
        model.appearance.setFontFamily("Menlo")
        model.appearance.setFontSize(30)
        model.appearance.setTitlebarMinimal(true)
        model.appearance.setPaneBorder(false)
        #expect(services.settings["terminal.fontFamily"] == .string("Menlo"))
        #expect(services.settings["terminal.fontSize"] == .number(24), "clamped to the offered range")
        #expect(services.settings["window.titlebar"] == .string("minimal"))
        #expect(services.settings["layout.paneBorder"] == .string("none"))
        model.skipStep()
        #expect(services.settings["terminal.fontFamily"] == nil)
        #expect(services.settings["terminal.fontSize"] == nil)
        #expect(services.settings["window.titlebar"] == .string("standard"))
        #expect(services.settings["layout.paneBorder"] == nil)
    }

    @Test func closingAfterContinueKeepsTheStep() {
        let services = MockOnboardingServices()
        let model = OnboardingModel(services: services, start: .appearance)
        model.appearance.setFontFamily("Menlo")
        model.next()
        model.keyboard.select(.vim)
        model.finish(completed: false)
        #expect(services.settings["terminal.fontFamily"] == .string("Menlo"), "continued past appearance")
        #expect(services.settings["shortcuts.bindings.focusLeft"] == nil, "keyboard was never continued")
    }

    @Test func matchSystemWritesALightDarkPair() async {
        let services = MockOnboardingServices()
        services.themeChoices = [choice("Night", background: .black), choice("Paper", background: .white), choice("Dusk", background: .black)]
        let model = OnboardingModel(services: services, start: .appearance)
        model.stepDidAppear()
        await settle { model.theme.choices.count == 4 }
        #expect(model.appearance.visibleChoices.compactMap(\.name) == ["Night", "Dusk"], "dark mode lists dark themes")
        model.appearance.select(model.theme.choices[3])
        model.appearance.setMode(.system)
        #expect(services.selectedThemeName == "light:Paper,dark:Dusk")
        model.appearance.select(model.theme.choices[1])
        #expect(services.selectedThemeName == "light:Paper,dark:Night")
        #expect(AppearanceStepModel.pair("dark:A, light:B")! == (light: "B", dark: "A"))
        model.appearance.setMode(.light)
        #expect(services.selectedThemeName == "Paper")
    }

    @Test func presetsReplaceEachOtherAndSkipRestores() {
        let services = MockOnboardingServices()
        services.settings["shortcuts.bindings.splitRight"] = .string("cmd+opt+d")
        let model = OnboardingModel(services: services, start: .keyboard)
        #expect(model.keyboard.selected == .cmux)
        model.keyboard.select(.tmux)
        #expect(services.settings["shortcuts.bindings.toggleSplitZoom"] == .string("ctrl+opt+z"))
        model.keyboard.select(.vim)
        #expect(services.settings["shortcuts.bindings.toggleSplitZoom"] == nil, "no keys left over from tmux")
        #expect(services.settings["shortcuts.bindings.focusLeft"] == .string("ctrl+cmd+h"))
        #expect(KeyboardStepModel.detect(services) == .vim)
        #expect(model.keyboard.display("nextSurface", in: .vim) == "⇧⌘]", "keys a preset leaves alone show the default")
        model.skipStep()
        #expect(services.settings["shortcuts.bindings.splitRight"] == .string("cmd+opt+d"))
        #expect(services.settings["shortcuts.bindings.focusLeft"] == nil)
    }

    @Test func workflowChoicesWriteTheirKeys() {
        let services = MockOnboardingServices()
        let model = OnboardingModel(services: services, start: .workflow)
        #expect(model.workflow.choice(.quitBehavior, in: WorkflowStepModel.quitBehaviors, fallback: "ask") == 0)
        model.workflow.choose(.quitBehavior, "keep")
        model.workflow.choose(.desktopNotifications, "never")
        #expect(services.settings["app.quitBehavior"] == .string("keep"))
        #expect(services.settings["notifications.desktop"] == .string("never"))
        model.next()
        model.finish(completed: false)
        #expect(services.settings["app.quitBehavior"] == .string("keep"))
    }

    @Test func importPerProfileKindsAndMerge() async {
        let services = MockOnboardingServices()
        services.browserProfilesAvailable = true
        let kinds: [ImportDataKind] = [.bookmarks, .history, .cookies]
        let profiles = ["Default", "Profile 1"].map { dir in
            BrowserSourceProfile(browser: .arc, directoryName: dir, displayName: dir, path: URL(fileURLWithPath: "/tmp/\(dir)"),
                                 availability: Dictionary(uniqueKeysWithValues: kinds.map { ($0, DataAvailability.available) }))
        }
        services.sources = [BrowserSource(browser: .arc, appURL: nil, profiles: profiles)]
        let model = OnboardingModel(services: services, start: .browser)
        model.stepDidAppear()
        await settle { model.importer.phase == .ready }
        model.importer.toggle(profiles[1])
        model.importer.toggle(.cookies, for: profiles[1])
        let plan = model.importer.plan
        #expect(plan.items.map(\.kinds) == [Set(kinds), [.bookmarks, .history]], "cookies only from the first profile")
        #expect(plan.mergeTarget == nil)
        model.importer.setMergeIntoOne(true)
        #expect(model.importer.plan.mergeTarget == ImportPlan.defaultProfileID)
    }

    @Test func installAllExtensionsGroupsByTargetProfile() async {
        let services = MockOnboardingServices()
        func batch(_ dir: String, target: String, ids: [String]) -> ImportBatch {
            var batch = ImportBatch(source: ImportSourceRecord(browser: .chrome, profileDirectory: dir, displayName: dir,
                                                               proposedProfileID: target, targetProfileID: target))
            batch.extensions = ids.map { ImportedExtension(id: $0, name: $0) }
            return batch
        }
        services.summary = ImportSummary(batches: [batch("Default", target: "p1", ids: ["a", "b"]), batch("Profile 1", target: "p2", ids: ["c"])])
        services.sources = [BrowserSource(browser: .chrome, appURL: nil, profiles: [
            BrowserSourceProfile(browser: .chrome, directoryName: "Default", displayName: "D", path: URL(fileURLWithPath: "/tmp/d"),
                                 availability: [.extensions: .available]),
        ])]
        let model = OnboardingModel(services: services, start: .browser)
        model.stepDidAppear()
        await settle { model.importer.phase == .ready }
        model.importer.start()
        await settle { if case .finished = model.importer.phase { true } else { false } }
        model.importer.installAllExtensions()
        #expect(services.extensionInstalls.map(\.profile) == ["p1", "p2"])
        #expect(model.importer.installedExtensions == ["a", "b", "c"])
    }
}
