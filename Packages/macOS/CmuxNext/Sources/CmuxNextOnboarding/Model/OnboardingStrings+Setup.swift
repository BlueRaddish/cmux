import CmuxNextBrowserImport
import Foundation

/// Text of the appearance, keyboard, workflow, accounts and ready steps.
extension OnboardingStrings {
    static var getStarted: String { String(localized: "onboarding.button.getStarted", defaultValue: "Get Started", bundle: .module) }
    static var welcomePointLook: String { String(localized: "onboarding.welcome.point.look", defaultValue: "Your theme, font and density, live as you pick", bundle: .module) }
    static var welcomePointBrowser: String {
        String(localized: "onboarding.welcome.point.browser", defaultValue: "Your browsers moved in: bookmarks, history, tabs, sign-ins, extensions", bundle: .module)
    }
    static var welcomePointKeys: String { String(localized: "onboarding.welcome.point.keys", defaultValue: "Shortcuts that match the way you already work", bundle: .module) }
    static var welcomePointAgents: String {
        String(localized: "onboarding.welcome.point.agents", defaultValue: "Notifications and accounts set up for your agents", bundle: .module)
    }
    static var welcomeKeysHint: String {
        String(localized: "onboarding.welcome.keysHint", defaultValue: "Return continues. Escape skips the rest. Reopen this any time from the command palette or Settings.", bundle: .module)
    }
    static var previewLabel: String { String(localized: "onboarding.preview.label", defaultValue: "Preview of cmux with your choices", bundle: .module) }

    // Appearance
    static var appearanceTitle: String { String(localized: "onboarding.appearance.title", defaultValue: "Make It Yours", bundle: .module) }
    static var appearanceSubtitle: String {
        String(localized: "onboarding.appearance.subtitle", defaultValue: "Everything applies as you pick it. Skip puts it all back.", bundle: .module)
    }
    static var modeDark: String { String(localized: "onboarding.appearance.mode.dark", defaultValue: "Dark", bundle: .module) }
    static var modeLight: String { String(localized: "onboarding.appearance.mode.light", defaultValue: "Light", bundle: .module) }
    static var modeSystem: String { String(localized: "onboarding.appearance.mode.system", defaultValue: "Match System", bundle: .module) }
    static var terminalFont: String { String(localized: "onboarding.appearance.font", defaultValue: "Terminal Font", bundle: .module) }
    static var fontSize: String { String(localized: "onboarding.appearance.fontSize", defaultValue: "Font Size", bundle: .module) }
    static var ghosttyDefault: String { String(localized: "onboarding.appearance.ghosttyDefault", defaultValue: "From Ghostty", bundle: .module) }
    static func points(_ value: Int) -> String {
        String(format: String(localized: "onboarding.appearance.points", defaultValue: "%lld pt", bundle: .module), value)
    }
    static var titlebar: String { String(localized: "onboarding.appearance.titlebar", defaultValue: "Titlebar", bundle: .module) }
    static var titlebarMinimal: String { String(localized: "onboarding.appearance.titlebar.minimal", defaultValue: "Minimal", bundle: .module) }
    static var titlebarStandard: String { String(localized: "onboarding.appearance.titlebar.standard", defaultValue: "Standard", bundle: .module) }
    static var paneBorder: String { String(localized: "onboarding.appearance.paneBorder", defaultValue: "Pane Borders", bundle: .module) }
    static var borderSubtle: String { String(localized: "onboarding.appearance.border.subtle", defaultValue: "Subtle", bundle: .module) }
    static var borderNone: String { String(localized: "onboarding.appearance.border.none", defaultValue: "None", bundle: .module) }
    static var panePadding: String { String(localized: "onboarding.appearance.panePadding", defaultValue: "Pane Padding", bundle: .module) }

    // Keyboard
    static var keyboardTitle: String { String(localized: "onboarding.keyboard.title", defaultValue: "Your Keys", bundle: .module) }
    static var keyboardSubtitle: String {
        String(localized: "onboarding.keyboard.subtitle", defaultValue: "Start from the style you know. Every shortcut stays editable.", bundle: .module)
    }
    static var keyboardNote: String {
        String(localized: "onboarding.keyboard.note", defaultValue: "Change any shortcut later: highlight an action in the command palette and press ⌘K.", bundle: .module)
    }
    static func presetName(_ kind: ShortcutPreset.Kind) -> String {
        switch kind {
        case .cmux: String(localized: "onboarding.keyboard.preset.cmux", defaultValue: "cmux", bundle: .module)
        case .vim: String(localized: "onboarding.keyboard.preset.vim", defaultValue: "Vim", bundle: .module)
        case .tmux: String(localized: "onboarding.keyboard.preset.tmux", defaultValue: "tmux", bundle: .module)
        case .browser: String(localized: "onboarding.keyboard.preset.browser", defaultValue: "Browser", bundle: .module)
        }
    }
    static func presetDetail(_ kind: ShortcutPreset.Kind) -> String {
        switch kind {
        case .cmux: String(localized: "onboarding.keyboard.preset.cmux.detail", defaultValue: "The defaults: Command for app actions.", bundle: .module)
        case .vim: String(localized: "onboarding.keyboard.preset.vim.detail", defaultValue: "Control-Command with H J K L to move.", bundle: .module)
        case .tmux: String(localized: "onboarding.keyboard.preset.tmux.detail", defaultValue: "Control-Option, tmux's split and zoom keys.", bundle: .module)
        case .browser: String(localized: "onboarding.keyboard.preset.browser.detail", defaultValue: "⌘T opens a web tab, ⌥⌘ arrows switch tabs.", bundle: .module)
        }
    }
    static func presetAction(_ actionID: String) -> String {
        switch actionID {
        case "focusLeft": String(localized: "onboarding.keyboard.action.focusLeft", defaultValue: "Pane left", bundle: .module)
        case "focusRight": String(localized: "onboarding.keyboard.action.focusRight", defaultValue: "Pane right", bundle: .module)
        case "splitRight": String(localized: "onboarding.keyboard.action.splitRight", defaultValue: "Split right", bundle: .module)
        case "splitDown": String(localized: "onboarding.keyboard.action.splitDown", defaultValue: "Split down", bundle: .module)
        case "nextSurface": String(localized: "onboarding.keyboard.action.nextTab", defaultValue: "Next tab", bundle: .module)
        default: String(localized: "onboarding.keyboard.action.webTab", defaultValue: "Web tab", bundle: .module)
        }
    }

    // Workflow
    static var workflowTitle: String { String(localized: "onboarding.workflow.title", defaultValue: "How You Work", bundle: .module) }
    static var workflowSubtitle: String {
        String(localized: "onboarding.workflow.subtitle", defaultValue: "When agents need you, and what happens to terminals when you quit.", bundle: .module)
    }
    static var notificationsHeader: String { String(localized: "onboarding.workflow.notifications", defaultValue: "Notifications", bundle: .module) }
    static var desktopBanners: String { String(localized: "onboarding.workflow.banners", defaultValue: "macOS banners", bundle: .module) }
    static var clearWhen: String { String(localized: "onboarding.workflow.clearWhen", defaultValue: "Clear a notification", bundle: .module) }
    static func desktopMode(_ raw: String) -> String {
        switch raw {
        case "always": String(localized: "onboarding.workflow.banners.always", defaultValue: "Always", bundle: .module)
        case "whenInactive": String(localized: "onboarding.workflow.banners.inactive", defaultValue: "cmux in Back", bundle: .module)
        case "never": String(localized: "onboarding.workflow.banners.never", defaultValue: "Never", bundle: .module)
        default: String(localized: "onboarding.workflow.banners.unlessFocused", defaultValue: "Unless Focused", bundle: .module)
        }
    }
    static func dismissalMode(_ raw: String) -> String {
        raw == "unread"
            ? String(localized: "onboarding.workflow.clear.manual", defaultValue: "When I Mark It", bundle: .module)
            : String(localized: "onboarding.workflow.clear.seen", defaultValue: "When I See It", bundle: .module)
    }
    static var quitHeader: String { String(localized: "onboarding.workflow.quit", defaultValue: "Quitting", bundle: .module) }
    static var whenQuitting: String { String(localized: "onboarding.workflow.whenQuitting", defaultValue: "When cmux quits", bundle: .module) }
    static func quitBehavior(_ raw: String) -> String {
        switch raw {
        case "keep": String(localized: "onboarding.workflow.quit.keep", defaultValue: "Keep Running", bundle: .module)
        case "endKeepLayout": String(localized: "onboarding.workflow.quit.endKeepLayout", defaultValue: "End, Keep Layout", bundle: .module)
        case "endEverything": String(localized: "onboarding.workflow.quit.endAll", defaultValue: "End All", bundle: .module)
        default: String(localized: "onboarding.workflow.quit.ask", defaultValue: "Ask", bundle: .module)
        }
    }
    static var quitNote: String {
        String(localized: "onboarding.workflow.quitNote", defaultValue: "Terminals run in cmux-tui, so agents can keep working after cmux quits.", bundle: .module)
    }
    static var terminalHandlersTitle: String {
        String(localized: "onboarding.workflow.terminal.title", defaultValue: "Open ssh links, man pages and scripts in cmux", bundle: .module)
    }
    static var terminalHandlersDetail: String {
        String(localized: "onboarding.workflow.terminal.detail", defaultValue: "Terminal stays installed; macOS asks to confirm.", bundle: .module)
    }
    static var useCmux: String { String(localized: "onboarding.workflow.terminal.use", defaultValue: "Use cmux", bundle: .module) }

    // Accounts and ready
    static var accountsTitle: String { String(localized: "onboarding.accounts.title", defaultValue: "Connect your AI accounts", bundle: .module) }
    static var accountsSubtitle: String {
        String(localized: "onboarding.accounts.subtitle", defaultValue: "cmux found these sign-ins on this Mac. Nothing is uploaded unless you choose Connect.", bundle: .module)
    }
    static var machinesHeader: String { String(localized: "onboarding.ready.machines", defaultValue: "Work on another machine", bundle: .module) }
    static var connectSSH: String { String(localized: "onboarding.ready.ssh", defaultValue: "Connect over SSH…", bundle: .module) }
    static var newCloudMachine: String { String(localized: "onboarding.ready.cloud", defaultValue: "New Cloud Machine", bundle: .module) }
    static var makeDefault: String { String(localized: "onboarding.browser.makeShort", defaultValue: "Make Default", bundle: .module) }

    // Import additions
    static var cookiesNote: String {
        String(localized: "onboarding.import.cookiesNote", defaultValue: "Sign-ins come from each browser's cookies. macOS asks once per browser before cmux can read its key; Deny skips only that browser's sign-ins.", bundle: .module)
    }
    static var passwordsNote: String {
        String(localized: "onboarding.import.passwordsNote", defaultValue: "Passwords stay where they are: export them from the browser or the Passwords app into your password manager.", bundle: .module)
    }
    static var targetTitle: String { String(localized: "onboarding.import.target", defaultValue: "Import into", bundle: .module) }
    static var targetSeparate: String { String(localized: "onboarding.import.target.separate", defaultValue: "A Profile Each", bundle: .module) }
    static var targetMerged: String { String(localized: "onboarding.import.target.merged", defaultValue: "One Profile", bundle: .module) }
    static var installAll: String { String(localized: "onboarding.import.extensions.installAll", defaultValue: "Install All", bundle: .module) }
    static var installed: String { String(localized: "onboarding.import.extensions.installed", defaultValue: "Installed", bundle: .module) }
    static func installAllCount(_ count: Int) -> String {
        String(format: String(localized: "onboarding.import.extensions.installAllCount", defaultValue: "Install All %lld Extensions", bundle: .module), count)
    }
    static func installedCount(_ done: Int, _ total: Int) -> String {
        String(format: String(localized: "onboarding.import.extensions.progress", defaultValue: "%1$lld of %2$lld Installed", bundle: .module), done, total)
    }
    static func cookieIssue(_ error: CookieImportError, source: String) -> String {
        let format: String = switch error {
        case .keyNotFound: String(localized: "onboarding.import.cookies.noKey", defaultValue: "%@: no sign-in key in the Keychain.", bundle: .module)
        case .keychainDenied: String(localized: "onboarding.import.cookies.denied", defaultValue: "%@: Keychain access denied, sign-ins skipped.", bundle: .module)
        case .undecryptable: String(localized: "onboarding.import.cookies.undecryptable", defaultValue: "%@ encrypts sign-ins in a way cmux cannot read.", bundle: .module)
        case .refused: String(localized: "onboarding.import.cookies.refused", defaultValue: "%@: sign-ins stay in Tor.", bundle: .module)
        case .needsFullDiskAccess: String(localized: "onboarding.import.cookies.fda", defaultValue: "%@: sign-ins need Full Disk Access.", bundle: .module)
        case .storeUnavailable: String(localized: "onboarding.import.cookies.store", defaultValue: "%@: Chromium is not available, sign-ins skipped.", bundle: .module)
        case .malformed: String(localized: "onboarding.import.cookies.malformed", defaultValue: "%@: the sign-in file could not be read.", bundle: .module)
        }
        return String(format: format, source)
    }
}
