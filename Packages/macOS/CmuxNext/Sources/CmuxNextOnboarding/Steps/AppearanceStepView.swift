import AppKit
import CmuxNextDesign

/// Appearance: controls on the left, a live picture of cmux on the right.
/// Every control applies at once, so the whole app (this window too)
/// follows; the picture shows what the window behind cannot (font, panes).
final class AppearanceStepView: NSView {
    private let model: AppearanceStepModel
    private let themes: ThemeGridView
    private let mode = SegmentedPill(titles: [OnboardingStrings.modeDark, OnboardingStrings.modeLight, OnboardingStrings.modeSystem])
    private let density = SegmentedPill(titles: [OnboardingStrings.compact, OnboardingStrings.comfortable])
    private let titlebar = SegmentedPill(titles: [OnboardingStrings.titlebarMinimal, OnboardingStrings.titlebarStandard])
    private let border = SegmentedPill(titles: [OnboardingStrings.borderSubtle, OnboardingStrings.borderNone])
    private let padding = SegmentedPill(titles: AppearanceStepModel.paddingChoices.map { "\(Int($0))" })
    private let font = NSPopUpButton()
    private let size = NSPopUpButton()
    private let preview = LivePreviewView()
    private var shownFonts: [String] = []
    private var loop: RenderLoop?

    init(model: AppearanceStepModel) {
        self.model = model
        themes = ThemeGridView(model: model)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        mode.onSelect = { [weak model] in model?.setMode(AppearanceStepModel.Mode.allCases[$0]) }
        density.onSelect = { [weak model] in model?.theme.setDensity($0 == 0 ? .compact : .comfortable) }
        titlebar.onSelect = { [weak model] in model?.setTitlebarMinimal($0 == 0) }
        border.onSelect = { [weak model] in model?.setPaneBorder($0 == 0) }
        padding.onSelect = { [weak model] in model?.setPanePadding(AppearanceStepModel.paddingChoices[$0]) }
        for popup in [font, size] {
            popup.controlSize = .small
            popup.font = Typography.body
            popup.target = self
        }
        font.action = #selector(fontChanged)
        size.action = #selector(sizeChanged)
        size.addItem(withTitle: OnboardingStrings.ghosttyDefault)
        for value in stride(from: AppearanceStepModel.fontSizes.lowerBound, through: AppearanceStepModel.fontSizes.upperBound, by: 1) {
            size.addItem(withTitle: OnboardingStrings.points(Int(value)))
        }
        font.setAccessibilityLabel(OnboardingStrings.terminalFont)
        size.setAccessibilityLabel(OnboardingStrings.fontSize)
        let fontRow = NSStackView(views: [font, size])
        fontRow.spacing = Metrics.space3
        let rows = Column.make([
            SettingRowView(title: OnboardingStrings.density, control: density),
            SettingRowView(title: OnboardingStrings.terminalFont, control: fontRow),
            SettingRowView(title: OnboardingStrings.titlebar, control: titlebar),
            SettingRowView(title: OnboardingStrings.paneBorder, control: border),
            SettingRowView(title: OnboardingStrings.panePadding, control: padding),
        ], spacing: 0)
        Column.fill(rows)
        let themeHeader = NSStackView(views: [OnboardingLabel.make(OnboardingStrings.theme, font: Typography.header, color: Palette.textSecondary),
                                              FlexibleSpace(), mode])
        let left = Column.make([themeHeader, themes, rows], spacing: Metrics.space5)
        Column.fill(left)
        let note = OnboardingLabel.make(OnboardingStrings.themeNote, font: Typography.caption, color: Palette.textTertiary, lines: 2)
        let right = Column.make([GlassCard.make(preview, padding: Metrics.space4), note], spacing: Metrics.space4)
        addSubview(left)
        addSubview(right)
        NSLayoutConstraint.activate([
            left.leadingAnchor.constraint(equalTo: leadingAnchor), left.topAnchor.constraint(equalTo: topAnchor),
            left.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5),
            left.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            right.leadingAnchor.constraint(equalTo: left.trailingAnchor, constant: Metrics.space6 * 2),
            right.trailingAnchor.constraint(equalTo: trailingAnchor), right.topAnchor.constraint(equalTo: topAnchor),
            preview.heightAnchor.constraint(equalTo: preview.widthAnchor, multiplier: 0.66),
            right.arrangedSubviews[0].widthAnchor.constraint(equalTo: right.widthAnchor),
            note.widthAnchor.constraint(equalTo: right.widthAnchor),
            themes.heightAnchor.constraint(equalToConstant: OnboardingMetrics.themeCardSize.height * 2 + Metrics.space4 * 3),
        ])
        loop = RenderLoop { [weak self] in self?.render() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private func render() {
        mode.selectedIndex = AppearanceStepModel.Mode.allCases.firstIndex(of: model.mode) ?? 0
        density.selectedIndex = model.theme.density == .compact ? 0 : 1
        titlebar.selectedIndex = model.titlebarMinimal ? 0 : 1
        border.selectedIndex = model.paneBorder ? 0 : 1
        padding.selectedIndex = AppearanceStepModel.paddingChoices.firstIndex(of: model.panePadding ?? 4) ?? 1
        let fonts = model.fonts
        if fonts != shownFonts {
            shownFonts = fonts
            font.removeAllItems()
            font.addItem(withTitle: OnboardingStrings.ghosttyDefault)
            font.addItems(withTitles: fonts)
        }
        if let family = model.fontFamily, font.item(withTitle: family) != nil { font.selectItem(withTitle: family) } else { font.selectItem(at: 0) }
        if let points = model.fontSize { size.selectItem(at: Int(points - AppearanceStepModel.fontSizes.lowerBound) + 1) } else { size.selectItem(at: 0) }
        preview.options = LivePreviewView.Options(fontFamily: model.fontFamily, fontSize: model.fontSize, titlebarMinimal: model.titlebarMinimal,
                                                  paneBorder: model.paneBorder, panePadding: model.panePadding)
    }

    @objc private func fontChanged() {
        model.setFontFamily(font.indexOfSelectedItem <= 0 ? nil : font.titleOfSelectedItem)
    }

    @objc private func sizeChanged() {
        let index = size.indexOfSelectedItem
        model.setFontSize(index <= 0 ? nil : AppearanceStepModel.fontSizes.lowerBound + Double(index - 1))
    }
}

/// The theme cards of the current mode, in a scrolling grid.
final class ThemeGridView: NSView {
    private let model: AppearanceStepModel
    private let grid = NSGridView()
    private var cards: [String: ThemeCardView] = [:]
    private var shown: [String] = []
    private var loop: RenderLoop?

    init(model: AppearanceStepModel) {
        self.model = model
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        grid.rowSpacing = Metrics.space4
        grid.columnSpacing = Metrics.space4
        grid.translatesAutoresizingMaskIntoConstraints = false
        let document = FlippedView()
        document.translatesAutoresizingMaskIntoConstraints = false
        document.addSubview(grid)
        let scroll = NSScrollView()
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.scrollerStyle = .overlay
        scroll.documentView = document
        scroll.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor), scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroll.topAnchor.constraint(equalTo: topAnchor), scroll.bottomAnchor.constraint(equalTo: bottomAnchor),
            document.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor),
            grid.leadingAnchor.constraint(equalTo: document.leadingAnchor, constant: Metrics.space2),
            grid.topAnchor.constraint(equalTo: document.topAnchor, constant: Metrics.space2),
            grid.bottomAnchor.constraint(equalTo: document.bottomAnchor, constant: -Metrics.space2),
        ])
        loop = RenderLoop { [weak self] in self?.render() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private func render() {
        let choices = model.visibleChoices
        if choices.map(\.id) != shown {
            shown = choices.map(\.id)
            rebuild(choices)
        }
        for choice in choices { cards[choice.id]?.isSelected = model.isSelected(choice) }
    }

    private func rebuild(_ choices: [ThemeChoice]) {
        cards.values.forEach { $0.removeFromSuperview() }
        while grid.numberOfRows > 0 { grid.removeRow(at: 0) }
        cards = [:]
        var row: [NSView] = []
        for choice in choices {
            let card = ThemeCardView(choice: choice, title: choice.name ?? OnboardingStrings.ghosttyTheme)
            card.onSelect = { [weak model] in model?.select(choice) }
            cards[choice.id] = card
            row.append(card)
            if row.count == 4 {
                grid.addRow(with: row)
                row = []
            }
        }
        if !row.isEmpty { grid.addRow(with: row) }
    }
}
