import AppKit
import CmuxNextDesign

/// A small picture of the cmux window in the chosen theme, density, font,
/// titlebar and pane chrome: sidebar, tab strip and two terminal panes
/// with colored prompt lines. Redraws when any of those change.
final class LivePreviewView: NSView {
    struct Options: Equatable {
        var fontFamily: String?
        var fontSize: Double?
        var titlebarMinimal = true
        var paneBorder = true
        var panePadding: Double?
    }

    var options = Options() { didSet { if options != oldValue { needsDisplay = true } } }
    private var loop: RenderLoop?

    override init(frame: NSRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.cornerRadius = OnboardingMetrics.cornerRadius
        layer?.cornerCurve = .continuous
        layer?.masksToBounds = true
        setAccessibilityElement(true)
        setAccessibilityRole(.image)
        setAccessibilityLabel(OnboardingStrings.previewLabel)
        // Theme and density are observable: redraw when either changes.
        loop = RenderLoop { [weak self] in
            _ = ThemeStore.shared.input
            _ = DesignSettings.shared.density
            self?.needsDisplay = true
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var isFlipped: Bool { true }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let input = ThemeStore.shared.input
        let scale = min(1, bounds.width / 720)
        Palette.windowBackground.setFill()
        bounds.fill()
        var top: CGFloat = 0
        if !options.titlebarMinimal {
            let bar = NSRect(x: 0, y: 0, width: bounds.width, height: Metrics.titlebarHeight * scale)
            Palette.hoverFill.setFill()
            bar.fill()
            top = bar.maxY
        }
        drawTrafficLights(y: top == 0 ? Metrics.space5 * scale : top / 2, scale: scale)
        let sidebar = NSRect(x: 0, y: top, width: Metrics.sidebarWidth * scale, height: bounds.height - top)
        drawSidebar(sidebar, top: top == 0 ? Metrics.titlebarHeight * scale : Metrics.space4 * scale, scale: scale)
        let content = NSRect(x: sidebar.maxX, y: top, width: bounds.width - sidebar.maxX, height: bounds.height - top)
        let strip = NSRect(x: content.minX, y: content.minY, width: content.width, height: Metrics.tabStripHeight * scale)
        drawTabs(strip, scale: scale)
        let padding = CGFloat(options.panePadding ?? Double(Metrics.panePadding)) * scale + Metrics.space2 * scale
        let panes = NSRect(x: content.minX + padding, y: strip.maxY + padding, width: content.width - 2 * padding,
                           height: content.maxY - strip.maxY - 2 * padding)
        let gap = Metrics.columnGap * scale
        let left = NSRect(x: panes.minX, y: panes.minY, width: (panes.width - gap) / 2, height: panes.height)
        let right = NSRect(x: left.maxX + gap, y: panes.minY, width: left.width, height: panes.height)
        drawPane(left, input: input, scale: scale, lines: Self.sampleLeft)
        drawPane(right, input: input, scale: scale, lines: Self.sampleRight)
    }

    private func drawTrafficLights(y: CGFloat, scale: CGFloat) {
        Palette.textTertiary.withAlphaComponent(0.5).setFill()
        for index in 0..<3 {
            let side = 9 * scale
            NSBezierPath(ovalIn: NSRect(x: (14 + CGFloat(index) * 16) * scale, y: y - side / 2, width: side, height: side)).fill()
        }
    }

    private func drawSidebar(_ rect: NSRect, top: CGFloat, scale: CGFloat) {
        let row = Metrics.sidebarRowHeight * scale
        let widths: [CGFloat] = [0.62, 0.48, 0.7, 0.4]
        for (index, width) in widths.enumerated() {
            let frame = NSRect(x: rect.minX + Metrics.space4 * scale, y: rect.minY + top + CGFloat(index) * (row + 2 * scale),
                               width: rect.width - Metrics.space6 * scale, height: row)
            if index == 0 {
                Palette.selectionFill.setFill()
                NSBezierPath(roundedRect: frame, xRadius: Metrics.itemCornerRadius * scale, yRadius: Metrics.itemCornerRadius * scale).fill()
            }
            (index == 0 ? Palette.textPrimary : Palette.textTertiary).withAlphaComponent(0.7).setFill()
            NSBezierPath(roundedRect: NSRect(x: frame.minX + Metrics.space4 * scale, y: frame.midY - 2.5 * scale,
                                             width: (frame.width - Metrics.space6 * scale) * width, height: 5 * scale),
                         xRadius: 2.5 * scale, yRadius: 2.5 * scale).fill()
        }
    }

    private func drawTabs(_ strip: NSRect, scale: CGFloat) {
        let width = min(Metrics.tabMaxWidth * scale, strip.width / 3.2)
        for index in 0..<3 {
            let tab = NSRect(x: strip.minX + Metrics.space4 * scale + CGFloat(index) * (width + 2 * scale),
                             y: strip.minY + Metrics.tabStripEdgeInset * scale, width: width, height: Metrics.tabHeight * scale)
            if index == 0 {
                Palette.selectionFill.setFill()
                NSBezierPath(roundedRect: tab, xRadius: Metrics.itemCornerRadius * scale, yRadius: Metrics.itemCornerRadius * scale).fill()
            }
            Palette.textSecondary.withAlphaComponent(index == 0 ? 0.8 : 0.4).setFill()
            NSRect(x: tab.minX + Metrics.space4 * scale, y: tab.midY - 2 * scale, width: tab.width * 0.5, height: 4 * scale).fill()
        }
    }

    private func drawPane(_ rect: NSRect, input: ThemeInput, scale: CGFloat, lines: [[(String, Int?)]]) {
        let radius = Metrics.paneCornerRadius * scale
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        input.background.nsColor.setFill()
        path.fill()
        if options.paneBorder {
            Palette.paneBorder.setStroke()
            path.lineWidth = 1
            path.stroke()
        }
        let size = CGFloat(options.fontSize ?? 13) * scale
        let font = options.fontFamily.flatMap { NSFont(name: $0, size: size) ?? NSFontManager.shared.font(withFamily: $0, traits: [], weight: 5, size: size) }
            ?? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        var y = rect.minY + Metrics.space4 * scale
        NSGraphicsContext.saveGraphicsState()
        path.addClip()
        for line in lines where y + font.boundingRectForFont.height < rect.maxY {
            let text = NSMutableAttributedString()
            for (piece, color) in line {
                let rgb = color.flatMap { input.palette.indices.contains($0) ? input.palette[$0] : nil } ?? input.foreground
                text.append(NSAttributedString(string: piece, attributes: [.font: font, .foregroundColor: rgb.nsColor]))
            }
            text.draw(at: NSPoint(x: rect.minX + Metrics.space4 * scale, y: y))
            y += font.ascender - font.descender + font.leading + 2 * scale
        }
        NSGraphicsContext.restoreGraphicsState()
    }

    // Sample output: (text, ANSI palette index or nil for the foreground).
    static let sampleLeft: [[(String, Int?)]] = [
        [("~/cmux", 4), (" main", 5), (" ❯ ", 2), ("git status", nil)],
        [("On branch ", nil), ("main", 2)],
        [("modified: ", 1), ("Sources/App.swift", nil)],
        [("~/cmux", 4), (" ❯ ", 2), ("swift test", nil)],
        [("✔ ", 2), ("142 tests passed", nil)],
    ]
    static let sampleRight: [[(String, Int?)]] = [
        [("claude", 3), (" ❯ ", 2), ("plan the import", nil)],
        [("● ", 6), ("Reading browser.md", 8)],
        [("● ", 6), ("Editing CookieImporter.swift", 8)],
        [("+42 ", 2), ("-7", 1)],
    ]
}
