import Foundation

/// A small set of keyboard shortcuts in one style. Applying a preset writes
/// `shortcuts.bindings.<action>` for its actions and removes the bindings
/// of every other preset, so switching presets never leaves a mix.
public nonisolated struct ShortcutPreset: Sendable, Identifiable, Equatable {
    public enum Kind: String, Sendable, CaseIterable {
        case cmux, vim, tmux, browser
    }

    public struct Binding: Sendable, Equatable {
        public var actionID: String
        /// cmux.json form ("ctrl+cmd+h").
        public var chord: String
        /// Display form ("⌃⌘H").
        public var display: String
    }

    public var kind: Kind
    public var symbol: String
    public var bindings: [Binding]
    public var id: String { kind.rawValue }

    /// Actions shown on the preset card, with the cmux default's display.
    public static let previewActions = ["focusLeft", "focusRight", "splitRight", "splitDown", "nextSurface", "openBrowser"]

    public static let all: [ShortcutPreset] = [
        ShortcutPreset(kind: .cmux, symbol: "command", bindings: []),
        ShortcutPreset(kind: .vim, symbol: "character.cursor.ibeam", bindings: [
            Binding(actionID: "focusLeft", chord: "ctrl+cmd+h", display: "⌃⌘H"),
            Binding(actionID: "focusDown", chord: "ctrl+cmd+j", display: "⌃⌘J"),
            Binding(actionID: "focusUp", chord: "ctrl+cmd+k", display: "⌃⌘K"),
            Binding(actionID: "focusRight", chord: "ctrl+cmd+l", display: "⌃⌘L"),
            Binding(actionID: "splitRight", chord: "ctrl+cmd+v", display: "⌃⌘V"),
            Binding(actionID: "splitDown", chord: "ctrl+cmd+s", display: "⌃⌘S"),
        ]),
        ShortcutPreset(kind: .tmux, symbol: "rectangle.split.3x1", bindings: [
            Binding(actionID: "focusLeft", chord: "ctrl+opt+h", display: "⌃⌥H"),
            Binding(actionID: "focusDown", chord: "ctrl+opt+j", display: "⌃⌥J"),
            Binding(actionID: "focusUp", chord: "ctrl+opt+k", display: "⌃⌥K"),
            Binding(actionID: "focusRight", chord: "ctrl+opt+l", display: "⌃⌥L"),
            Binding(actionID: "splitRight", chord: "ctrl+opt+\\", display: "⌃⌥\\"),
            Binding(actionID: "splitDown", chord: "ctrl+opt+-", display: "⌃⌥-"),
            Binding(actionID: "toggleSplitZoom", chord: "ctrl+opt+z", display: "⌃⌥Z"),
            Binding(actionID: "nextSurface", chord: "ctrl+opt+n", display: "⌃⌥N"),
            Binding(actionID: "prevSurface", chord: "ctrl+opt+p", display: "⌃⌥P"),
        ]),
        ShortcutPreset(kind: .browser, symbol: "globe", bindings: [
            Binding(actionID: "openBrowser", chord: "cmd+t", display: "⌘T"),
            Binding(actionID: "newSurface", chord: "cmd+shift+l", display: "⇧⌘L"),
            Binding(actionID: "nextSurface", chord: "cmd+opt+right", display: "⌥⌘→"),
            Binding(actionID: "prevSurface", chord: "cmd+opt+left", display: "⌥⌘←"),
            Binding(actionID: "focusLeft", chord: "ctrl+cmd+left", display: "⌃⌘←"),
            Binding(actionID: "focusRight", chord: "ctrl+cmd+right", display: "⌃⌘→"),
            Binding(actionID: "focusUp", chord: "ctrl+cmd+up", display: "⌃⌘↑"),
            Binding(actionID: "focusDown", chord: "ctrl+cmd+down", display: "⌃⌘↓"),
        ]),
    ]

    /// Every action any preset binds.
    public static var managedActions: [String] {
        var seen = Set<String>()
        return all.flatMap(\.bindings).map(\.actionID).filter { seen.insert($0).inserted }
    }

    public static func preset(_ kind: Kind) -> ShortcutPreset { all.first { $0.kind == kind }! }

    public static func path(for actionID: String) -> [String] { ["shortcuts", "bindings", actionID] }
}
