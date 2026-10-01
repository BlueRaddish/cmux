public import CmuxNextDesign
import Foundation
public import Observation

/// Appearance step: the theme (one theme, or a light/dark pair that
/// follows macOS), density, the terminal font, the window titlebar and
/// pane chrome. Every change applies live; Skip or closing before Continue
/// puts the old values back.
@MainActor
@Observable
public final class AppearanceStepModel {
    public enum Mode: String, Sendable, CaseIterable {
        case dark, light, system
    }

    public let theme: ThemeStepModel
    public let draft: SettingsDraft
    public private(set) var fonts: [String] = []
    public private(set) var mode: Mode = .dark
    /// The two halves of a `light:A,dark:B` theme while `mode` is `.system`.
    public private(set) var lightPick: String?
    public private(set) var darkPick: String?
    @ObservationIgnored private let services: any OnboardingServices
    @ObservationIgnored private var fontTask: Task<Void, Never>?

    public static let fontSizes: ClosedRange<Double> = 9...24
    public static let paddingChoices: [Double] = [0, 4, 8, 12]

    init(services: any OnboardingServices) {
        self.services = services
        theme = ThemeStepModel(services: services)
        draft = SettingsDraft(services: services)
        if let pair = Self.pair(theme.selected) {
            mode = .system
            lightPick = pair.light
            darkPick = pair.dark
        } else {
            mode = Self.isLight(theme.selectedChoice) ? .light : .dark
        }
    }

    /// `light:A,dark:B` (Ghostty's syntax, either order) as its halves.
    static func pair(_ name: String?) -> (light: String, dark: String)? {
        guard let name, name.contains("light:"), name.contains("dark:") else { return nil }
        var light: String?, dark: String?
        for part in name.split(separator: ",") {
            let piece = part.trimmingCharacters(in: .whitespaces)
            if piece.hasPrefix("light:") { light = String(piece.dropFirst(6)) }
            if piece.hasPrefix("dark:") { dark = String(piece.dropFirst(5)) }
        }
        guard let light, let dark, !light.isEmpty, !dark.isEmpty else { return nil }
        return (light, dark)
    }

    static func isLight(_ choice: ThemeChoice) -> Bool { choice.input.background.relativeLuminance > 0.4 }

    /// Theme cards for the current mode (the user's Ghostty theme always first).
    public var visibleChoices: [ThemeChoice] {
        theme.choices.filter { choice in
            guard choice.name != nil else { return true }
            switch mode {
            case .dark: return !Self.isLight(choice)
            case .light: return Self.isLight(choice)
            case .system: return true
            }
        }
    }

    public func isSelected(_ choice: ThemeChoice) -> Bool {
        guard mode == .system else { return theme.selected == choice.name }
        guard let name = choice.name else { return false }
        return name == lightPick || name == darkPick
    }

    public func load() {
        theme.load()
        guard fontTask == nil else { return }
        fontTask = Task { [weak self, services] in
            let found = await services.loadMonospacedFonts()
            self?.fonts = found
        }
    }

    public func setMode(_ value: Mode) {
        guard value != mode else { return }
        mode = value
        guard value == .system else {
            // Keep the pick when it fits the mode; else the first fitting theme.
            if theme.selected.map({ Self.pair($0) != nil }) ?? false || !visibleChoices.contains(where: { $0.name == theme.selected }) {
                theme.select(visibleChoices.first(where: { $0.name != nil })?.name)
            }
            return
        }
        let current = theme.selectedChoice
        darkPick = Self.isLight(current) ? theme.choices.first { $0.name != nil && !Self.isLight($0) }?.name : current.name
        lightPick = Self.isLight(current) ? current.name : theme.choices.first { $0.name != nil && Self.isLight($0) }?.name
        applyPair()
    }

    public func select(_ choice: ThemeChoice) {
        guard mode == .system, let name = choice.name else { return theme.select(choice.name) }
        if Self.isLight(choice) { lightPick = name } else { darkPick = name }
        applyPair()
    }

    private func applyPair() {
        guard let lightPick, let darkPick else { return }
        theme.select("light:\(lightPick),dark:\(darkPick)")
    }

    // Font, titlebar, panes (cmux.json overrides; nil keeps Ghostty's own).
    public var fontFamily: String? { draft.value(.terminalFontFamily)?.stringValue }
    public var fontSize: Double? { draft.value(.terminalFontSize)?.numberValue }
    public var titlebarMinimal: Bool { (draft.value(.titlebar)?.stringValue ?? "minimal") == "minimal" }
    public var paneBorder: Bool { (draft.value(.paneBorder)?.stringValue ?? "subtle") != "none" }
    public var panePadding: Double? { draft.value(.panePadding)?.numberValue }

    public func setFontFamily(_ family: String?) { draft.set(.terminalFontFamily, family.map(OnboardingValue.string)) }

    public func setFontSize(_ size: Double?) {
        draft.set(.terminalFontSize, size.map { .number(min(max($0.rounded(), Self.fontSizes.lowerBound), Self.fontSizes.upperBound)) })
    }

    public func setTitlebarMinimal(_ minimal: Bool) { draft.set(.titlebar, .string(minimal ? "minimal" : "standard")) }
    public func setPaneBorder(_ on: Bool) { draft.set(.paneBorder, .string(on ? "subtle" : "none")) }
    public func setPanePadding(_ points: Double?) { draft.set(.panePadding, points.map(OnboardingValue.number)) }

    public var isCommitted: Bool { theme.isCommitted }

    func commit() {
        theme.commit()
        draft.commit()
    }

    func revert() {
        theme.revert()
        draft.revert()
    }
}
