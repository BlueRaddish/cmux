public import CmuxNextBrowserImport
public import CmuxNextDesign
public import Foundation

/// Onboarding services with canned data, for the demo and tests. Records
/// what the flow asked for; never touches settings, browsers or macOS.
@MainActor
public final class MockOnboardingServices: OnboardingServices {
    public var ghosttyTheme: ThemeInput = .ghosttyDefault
    public var selectedThemeName: String?
    public var density: Density = .compact
    public var themeChoices: [ThemeChoice] = []
    public var sources: [BrowserSource] = []
    public var summary = ImportSummary(batches: [])
    /// When set, `runImport` waits here until the test resumes it.
    public var importGate: CheckedContinuation<Void, Never>?
    public var holdsImport = false
    public var browserProfilesAvailable = false
    public let defaultApps: any DefaultAppRegistering

    public private(set) var appliedAppearance: [(String?, Density)] = []
    public private(set) var installed: [String] = []
    public private(set) var openedTabs: [ImportedTab] = []
    public private(set) var opened: [URL] = []
    public private(set) var ended: Bool?
    public private(set) var plans: [ImportPlan] = []
    /// cmux.json as the flow wrote it (dotted paths).
    public var settings: [String: OnboardingValue] = [:]
    public private(set) var settingWrites: [(String, OnboardingValue?)] = []
    public var fonts = ["JetBrains Mono", "Menlo", "SF Mono"]
    public private(set) var ranActions: [String] = []
    public private(set) var extensionInstalls: [(profile: String, ids: [String])] = []
    /// Reports these ids installed as soon as an install starts.
    public var installsAtOnce = true

    public init(defaultApps: any DefaultAppRegistering = RecordingDefaultApps(appBundleURL: URL(fileURLWithPath: "/Applications/cmux.app"))) {
        self.defaultApps = defaultApps
    }

    public func loadThemeChoices() async -> [ThemeChoice] { themeChoices }

    public func applyAppearance(themeName: String?, density: Density) {
        appliedAppearance.append((themeName, density))
        selectedThemeName = themeName
        self.density = density
    }

    public func loadMonospacedFonts() async -> [String] { fonts }

    public func setting(_ path: [String]) -> OnboardingValue? { settings[path.joined(separator: ".")] }

    public func setSetting(_ path: [String], _ value: OnboardingValue?) {
        let key = path.joined(separator: ".")
        settings[key] = value
        settingWrites.append((key, value))
    }

    public func defaultShortcutDisplay(for actionID: String) -> String? {
        ["focusLeft": "⌥⌘←", "focusRight": "⌥⌘→", "splitRight": "⌘D", "splitDown": "⇧⌘D", "nextSurface": "⇧⌘]", "openBrowser": "⇧⌘L"][actionID]
    }

    public func runAction(_ actionID: String) { ranActions.append(actionID) }
    public func isActionAvailable(_ actionID: String) -> Bool { true }

    public func detectBrowsers() async -> [BrowserSource] { sources }

    public func runImport(_ plan: ImportPlan, progress: @escaping @MainActor (ImportProgress) -> Void) async throws -> ImportSummary {
        plans.append(plan)
        if let profile = plan.items.first?.profile {
            progress(ImportProgress(profileIndex: 0, profileCount: plan.items.count, profile: profile, kind: .bookmarks,
                                    fraction: 0.5, counts: ImportCounts(bookmarks: 1)))
        }
        if holdsImport { await withCheckedContinuation { importGate = $0 } }
        try Task.checkCancellation()
        return summary
    }

    public func installExtension(_ item: ImportedExtension) { installed.append(item.id) }

    public func installExtensions(_ items: [ImportedExtension], profileID: String, installed: @escaping @MainActor (Set<String>) -> Void) {
        extensionInstalls.append((profileID, items.map(\.id)))
        if installsAtOnce { installed(Set(items.map(\.id))) }
    }
    public func openTabs(_ tabs: [ImportedTab]) { openedTabs += tabs }
    public func openExternal(_ url: URL) { opened.append(url) }

    public func shortcutDisplay(for actionID: String) -> String? {
        ["commandPalette": "⇧⌘P", "splitRight": "⌘D", "splitDown": "⇧⌘D"][actionID]
    }

    public func onboardingDidEnd(completed: Bool) { ended = completed }
}
