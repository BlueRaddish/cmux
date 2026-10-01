public import AppKit
public import CmuxNextBrowserImport
public import CmuxNextDesign
public import Foundation

/// What the onboarding window needs from the app. The App implements it
/// over settings, the browser and the action registry;
/// `MockOnboardingServices` runs the window alone (demo, tests).
@MainActor
public protocol OnboardingServices: AnyObject {
    // Welcome
    /// The colors of the user's own Ghostty config (the default choice).
    var ghosttyTheme: ThemeInput { get }
    /// `appearance.theme` in cmux.json now; nil means the Ghostty config.
    var selectedThemeName: String? { get }
    var density: Density { get }
    /// The curated Ghostty themes available on this Mac.
    func loadThemeChoices() async -> [ThemeChoice]
    /// Writes the theme (nil: back to the Ghostty config) and density.
    func applyAppearance(themeName: String?, density: Density)

    /// Monospaced font families installed on this Mac (for the terminal font).
    func loadMonospacedFonts() async -> [String]

    // Settings (cmux.json) and actions
    /// The value at `path` in cmux.json now, nil when unset.
    func setting(_ path: [String]) -> OnboardingValue?
    /// Writes (nil: removes) the value at `path`; applies live.
    func setSetting(_ path: [String], _ value: OnboardingValue?)
    /// The action's shortcut from the registry's defaults, for display.
    func defaultShortcutDisplay(for actionID: String) -> String?
    /// Runs a registered action (Connect to Machine, New Cloud Machine...).
    func runAction(_ actionID: String)
    func isActionAvailable(_ actionID: String) -> Bool
    /// Whether the App supplies the accounts step (`makeAccountsStepView`).
    var hasAccountsStep: Bool { get }
    /// The accounts step's body (the accounts feature's view), or nil.
    func makeAccountsStepView() -> NSView?

    // Import
    func detectBrowsers() async -> [BrowserSource]
    func runImport(_ plan: ImportPlan, progress: @escaping @MainActor (ImportProgress) -> Void) async throws -> ImportSummary
    /// Opens the extension's Chrome Web Store page in a Chromium tab, where
    /// one click installs it.
    func installExtension(_ item: ImportedExtension)
    /// Opens the store pages of `items` in Chromium tabs of `profileID`, in
    /// the background, and reports which are installed as they install.
    func installExtensions(_ items: [ImportedExtension], profileID: String, installed: @escaping @MainActor (Set<String>) -> Void)
    /// Opens imported tabs as browser tabs in the current window.
    func openTabs(_ tabs: [ImportedTab])
    /// Whether browser profiles exist yet (else imports go to the default one).
    var browserProfilesAvailable: Bool { get }

    // Default browser and terminal
    var defaultApps: any DefaultAppRegistering { get }
    /// Opens a URL with the system (System Settings panes).
    func openExternal(_ url: URL)

    // Tour
    /// The current shortcut of an action, for display ("⇧⌘P"), or nil.
    func shortcutDisplay(for actionID: String) -> String?

    // Lifecycle
    /// The window closed; `completed` is false when the user skipped.
    func onboardingDidEnd(completed: Bool)
}

public extension OnboardingServices {
    var hasAccountsStep: Bool { false }
    func makeAccountsStepView() -> NSView? { nil }
}

/// System Settings deep links.
public enum SystemSettingsLink {
    /// Privacy & Security > Full Disk Access.
    public static let fullDiskAccess = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
    /// Keyboard > Keyboard Shortcuts > Services.
    public static let services = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension?Services")!
    /// Desktop & Dock (the default web browser menu).
    public static let defaultBrowser = URL(string: "x-apple.systempreferences:com.apple.Desktop-Settings.extension")!
}
