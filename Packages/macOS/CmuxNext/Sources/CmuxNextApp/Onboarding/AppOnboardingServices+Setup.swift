import AppKit
import CmuxNextAccounts
import CmuxNextActions
import CmuxNextBrowser
import CmuxNextBrowserImport
import CmuxNextDesign
import CmuxNextOnboarding
import CmuxNextSettings
import SwiftUI

/// The parts of `OnboardingServices` the setup steps use: cmux.json reads
/// and writes, the action registry, fonts, the one-step extension install
/// and the accounts step.
extension AppOnboardingServices {
    func loadMonospacedFonts() async -> [String] {
        await Task.detached {
            let manager = NSFontManager.shared
            return manager.availableFontFamilies.filter { family in
                manager.availableMembers(ofFontFamily: family)?.contains { member in
                    ((member[3] as? NSNumber)?.uintValue ?? 0) & NSFontTraitMask.fixedPitchFontMask.rawValue != 0
                } ?? false
            }
        }.value
    }

    func setting(_ path: [String]) -> OnboardingValue? {
        switch appServices.settings?.snapshot.root.value(at: path) {
        case .string(let value): .string(value)
        case .number(let value): .number(value)
        case .bool(let value): .bool(value)
        default: nil
        }
    }

    func setSetting(_ path: [String], _ value: OnboardingValue?) {
        guard let settings = appServices.settings else { return }
        // task-owner: one cmux.json write; the file watcher applies it
        Task {
            switch value {
            case .string(let text): try? await settings.set(.string(text), at: path)
            case .number(let number): try? await settings.set(.number(number), at: path)
            case .bool(let flag): try? await settings.set(.bool(flag), at: path)
            case nil: try? await settings.file.remove(path)
            }
        }
    }

    func defaultShortcutDisplay(for actionID: String) -> String? {
        appServices.registry.descriptor(for: ActionID(rawValue: actionID))?.defaultShortcut?.displayString
    }

    func runAction(_ actionID: String) {
        _ = appServices.registry.perform(ActionID(rawValue: actionID))
    }

    func isActionAvailable(_ actionID: String) -> Bool {
        appServices.registry.isAvailable(ActionID(rawValue: actionID))
    }

    var hasAccountsStep: Bool { true }

    func makeAccountsStepView() -> NSView? {
        NSHostingView(rootView: AccountsStepView(model: appServices.accounts.model, palette: .app))
    }

    /// Opens every store page in a background Chromium tab of the profile,
    /// then follows that profile's extension list (an observation, no
    /// polling) until each one is installed or onboarding closes.
    func installExtensions(_ items: [ImportedExtension], profileID: String, installed: @escaping @MainActor (Set<String>) -> Void) {
        guard !items.isEmpty, let pane = appServices.windows.active?.focusedPane else { return }
        for item in items {
            pane.newBrowserTab(url: item.webStoreURL, engine: BrowserEngineTag.cef.rawValue, background: true, profile: profileID)
        }
        let wanted = Set(items.map(\.id))
        let cef = appServices.cache.cef
        let profile = BrowserProfileRecord.engineProfile(for: profileID) ?? .default
        owner.extensionWatch?.cancel()
        // task-owner: OnboardingService.extensionWatch, cancelled when onboarding closes or a new install starts
        owner.extensionWatch = Task {
            await cef.warmStart(reason: "extensionInstall")
            guard let store = cef.extensionStore(for: profile) else { return }
            for await ids in Observations({ Set(store.extensions.map(\.id)) }) {
                let done = ids.intersection(wanted)
                installed(done)
                if done == wanted { return }
            }
        }
    }
}
