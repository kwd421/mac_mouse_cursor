import SwiftUI

private enum LayoutMetrics {
    static let detailOuterPadding: CGFloat = 24
    static let sectionSpacing: CGFloat = 20
    static let cardSpacing: CGFloat = 12
    static let cardHorizontalPadding: CGFloat = 12
    static let cardVerticalPadding: CGFloat = 10
    static let itemSpacing: CGFloat = 8
    static let itemVerticalPadding: CGFloat = 4
}

struct ContentView: View {
    @ObservedObject var controller: CursorController
    @ObservedObject private var localization = LocalizationController.shared

    var body: some View {
        let _ = localization.selectedLanguage
        VStack(alignment: .leading, spacing: 14) {
            Text("Cape Forge")
                .font(.headline)

            Text(controller.selectedFolderURL?.lastPathComponent ?? Localized.string("app.chooseCursorFolder"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Label(
                controller.selectedFolderIsValid
                    ? Localized.string("app.rolesReady", controller.resolvedRoleCount)
                    : Localized.string("app.folderRequired"),
                systemImage: controller.selectedFolderIsValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
            )
            .font(.footnote)
            .foregroundStyle(controller.selectedFolderIsValid ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.orange))

            HStack(spacing: 8) {
                Button(Localized.string("app.openSettings")) {
                    (NSApp.delegate as? AppDelegate)?.openSettingsWindow()
                }
                .buttonStyle(.borderedProminent)
            }

            Divider()

            Text(controller.statusText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(Localized.string("app.quit")) {
                NSApp.terminate(nil)
            }
            .buttonStyle(.bordered)
        }
        .padding(14)
        .frame(width: 280)
    }
}

struct SettingsView: View {
    @ObservedObject var controller: CursorController
    @ObservedObject private var localization = LocalizationController.shared
    @State private var selection: SidebarCursorItem? = .primary(.arrow)
    @State private var isSupplementalExpanded = false

    var body: some View {
        let _ = localization.selectedLanguage
        VStack(spacing: 0) {
            NavigationSplitView {
                List(selection: $selection) {
                    ForEach(CursorRole.allCases) { role in
                        if let assignment = controller.assignment(for: role) {
                            CursorRoleRow(assignment: assignment)
                                .tag(SidebarCursorItem.primary(role))
                        }
                    }

                    Section {
                        Button {
                            isSupplementalExpanded.toggle()
                            if !isSupplementalExpanded, case .supplemental = selection {
                                selection = .primary(.arrow)
                            }
                        } label: {
                            AdditionalCursorsHeader(isExpanded: isSupplementalExpanded)
                        }
                        .buttonStyle(.plain)

                        if isSupplementalExpanded {
                            ForEach(SupplementalCursorRole.allCases) { role in
                                SupplementalCursorRoleRow(assignment: controller.supplementalAssignment(for: role))
                                    .tag(SidebarCursorItem.supplemental(role))
                            }
                        }
                    }
                }
                .frame(minWidth: 230)
                .navigationTitle(Localized.string("app.cursors"))
            } detail: {
                switch selection {
                case .primary(let role):
                    if let assignment = controller.assignment(for: role) {
                        CursorRoleDetailView(controller: controller, assignment: assignment)
                    } else {
                        EmptySelectionView()
                    }
                case .supplemental(let role):
                    SupplementalCursorRoleDetailView(controller: controller, assignment: controller.supplementalAssignment(for: role))
                case nil:
                    EmptySelectionView()
                }
            }
            Divider()
            ExportSection(controller: controller)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
        }
        .frame(minWidth: 860, minHeight: 620)
    }
}

struct AdditionalCursorsHeader: View {
    let isExpanded: Bool
    @State private var isHovering = false
    @ObservedObject private var localization = LocalizationController.shared

    var body: some View {
        let _ = localization.selectedLanguage
        HStack(spacing: 14) {
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .foregroundStyle(.secondary)
                .font(.caption.weight(.semibold))
                .frame(width: 12)

            Text(Localized.string("app.additionalCursors"))
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var backgroundColor: Color {
        if isHovering {
            return Color.primary.opacity(0.09)
        }
        return Color.primary.opacity(0.05)
    }
}

struct EmptySelectionView: View {
    @ObservedObject private var localization = LocalizationController.shared

    var body: some View {
        let _ = localization.selectedLanguage
        VStack(spacing: 12) {
            Image(systemName: "cursorarrow")
                .font(.system(size: 30))
                .foregroundStyle(.secondary)
            Text(Localized.string("app.noCursorLoaded"))
                .font(.headline)
            Text(Localized.string("app.loadCursorFolderHint"))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ExportSection: View {
    @ObservedObject var controller: CursorController
    @ObservedObject private var localization = LocalizationController.shared

    var body: some View {
        let _ = localization.selectedLanguage
        GroupBox {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(Localized.string("export.authorLabel"))
                        .font(.headline)
                    TextField(Localized.string("export.authorPlaceholder"), text: $controller.exportAuthorName)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 320)
                }

                Spacer(minLength: 24)

                Button {
                    controller.exportMousecapeCape(authorName: controller.exportAuthorName)
                } label: {
                    Label(Localized.string("app.exportToMousecape"), systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, LayoutMetrics.cardHorizontalPadding)
            .padding(.vertical, LayoutMetrics.cardVerticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            EmptyView()
        }
    }
}

struct ExportScaleControl: View {
    @ObservedObject var controller: CursorController
    @ObservedObject private var localization = LocalizationController.shared

    var body: some View {
        let _ = localization.selectedLanguage
        GroupBox {
            VStack(alignment: .leading, spacing: LayoutMetrics.itemSpacing) {
                HStack {
                    Text(Localized.string("export.sizeLabel"))
                        .font(.headline)
                    Spacer()
                    Text(controller.exportSizePercentageText)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                VStack(spacing: 8) {
                    Slider(value: $controller.exportSizeMultiplier, in: 1.0...3.0, step: 0.1)
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal, LayoutMetrics.cardHorizontalPadding)
            .padding(.vertical, LayoutMetrics.cardVerticalPadding)
        } label: {
            EmptyView()
        }
    }
}

struct CursorRoleRow: View {
    let assignment: CursorAssignment
    @ObservedObject private var localization = LocalizationController.shared

    var body: some View {
        let _ = localization.selectedLanguage
        HStack(spacing: 10) {
            Image(systemName: statusSymbolName)
                .foregroundStyle(statusColor)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(assignment.role.displayName)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
    }

    private var statusSymbolName: String {
        if !assignment.isResolved { return "exclamationmark.triangle.fill" }
        if assignment.usesArrowFallback { return "exclamationmark.triangle.fill" }
        if assignment.isOverride { return "slider.horizontal.3" }
        return "checkmark.circle.fill"
    }

    private var statusColor: Color {
        if !assignment.isResolved { return .orange }
        if assignment.usesArrowFallback { return .orange }
        if assignment.isOverride { return .accentColor }
        return .secondary
    }

    private var subtitle: String {
        if !assignment.isResolved { return Localized.string("app.automaticMatchFailed") }
        if assignment.usesArrowFallback { return Localized.string("app.automaticMatchFailedArrowFallback") }
        if assignment.isOverride { return assignment.sourceURL?.lastPathComponent ?? Localized.string("app.manualOverride") }
        return assignment.sourceURL?.lastPathComponent ?? Localized.string("app.automaticallyMatched")
    }
}

struct SupplementalCursorRoleRow: View {
    let assignment: SupplementalCursorAssignment
    @ObservedObject private var localization = LocalizationController.shared

    var body: some View {
        let _ = localization.selectedLanguage
        HStack(spacing: 10) {
            Image(systemName: statusSymbolName)
                .foregroundStyle(statusColor)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(assignment.role.displayName)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
    }

    private var statusSymbolName: String {
        if !assignment.isResolved { return "exclamationmark.triangle.fill" }
        if assignment.isOverride { return "slider.horizontal.3" }
        return "checkmark.circle.fill"
    }

    private var statusColor: Color {
        if !assignment.isResolved { return .orange }
        if assignment.isOverride { return .accentColor }
        return .secondary
    }

    private var subtitle: String {
        if !assignment.isResolved { return Localized.string("app.automaticMatchFailed") }
        if assignment.isOverride { return assignment.sourceURL?.lastPathComponent ?? Localized.string("app.manualOverride") }
        return Localized.string("app.additionalCursorUses", assignment.mappedRole.displayName)
    }
}

struct CursorRoleDetailView: View {
    @ObservedObject var controller: CursorController
    let assignment: CursorAssignment
    @ObservedObject private var localization = LocalizationController.shared

    var body: some View {
        let _ = localization.selectedLanguage
        ScrollView {
            VStack(alignment: .leading, spacing: LayoutMetrics.sectionSpacing) {
                SettingsHeader(controller: controller)

                if let appliedPreview = assignment.appliedPreview {
                    PreviewGroup(
                        subtitle: assignment.sourceURL?.lastPathComponent ?? Localized.string("app.automaticallyMatchedFromFolder"),
                        animation: appliedPreview,
                        exportSizeMultiplier: controller.exportSizeMultiplier
                    ) {
                        Button(Localized.string("app.changeCursorFile")) {
                            controller.chooseOverride(for: assignment.role)
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    EmptyPreviewGroup(
                        subtitle: assignment.sourceURL?.lastPathComponent ?? Localized.string("app.noCursorLoaded")
                    ) {
                        Button(Localized.string("app.changeCursorFile")) {
                            controller.chooseOverride(for: assignment.role)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                ExportScaleControl(controller: controller)
                GroupBox {
                    VStack(alignment: .leading, spacing: LayoutMetrics.cardSpacing) {
                        if assignment.usesArrowFallback {
                            Label(Localized.string("app.arrowFallbackDescription"), systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                        DetailItem(title: Localized.string("app.automaticMatchKeywords")) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ThemeResolver.displayKeywords(for: assignment.role, language: Localized.currentLanguage))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        DetailItem(title: Localized.string("app.mousecape")) {
                            Text(assignment.role.mousecapeMappingDescription)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        DetailItem(title: Localized.string("app.currentSource")) {
                            Text(assignment.sourceURL?.path ?? Localized.string("app.automaticallyMatchedInsideSelectedFolder"))
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                        if assignment.usesArrowFallback {
                            DetailItem(title: Localized.string("app.status")) {
                                Text(Localized.string("app.automaticMatchFailedArrowFallbackShort"))
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    .padding(.horizontal, LayoutMetrics.cardHorizontalPadding)
                    .padding(.vertical, LayoutMetrics.cardVerticalPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    EmptyView()
                }
            }
            .padding(LayoutMetrics.detailOuterPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct SupplementalCursorRoleDetailView: View {
    @ObservedObject var controller: CursorController
    let assignment: SupplementalCursorAssignment
    @ObservedObject private var localization = LocalizationController.shared

    var body: some View {
        let _ = localization.selectedLanguage
        ScrollView {
            VStack(alignment: .leading, spacing: LayoutMetrics.sectionSpacing) {
                SettingsHeader(controller: controller)

                if let appliedPreview = assignment.appliedPreview {
                    PreviewGroup(
                        subtitle: assignment.sourceURL?.lastPathComponent ?? Localized.string("app.automaticallyMatchedFromFolder"),
                        animation: appliedPreview,
                        exportSizeMultiplier: controller.exportSizeMultiplier
                    ) {
                        Button(Localized.string("app.changeCursorFile")) {
                            controller.chooseOverride(for: assignment.role)
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    EmptyPreviewGroup(
                        subtitle: assignment.sourceURL?.lastPathComponent ?? Localized.string("app.noCursorLoaded")
                    ) {
                        Button(Localized.string("app.changeCursorFile")) {
                            controller.chooseOverride(for: assignment.role)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                ExportScaleControl(controller: controller)
                GroupBox {
                    VStack(alignment: .leading, spacing: LayoutMetrics.cardSpacing) {
                        Text(Localized.string("app.additionalCursorHint"))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 6)

                        DetailItem(title: Localized.string("app.inheritedMatchKeywords")) {
                            Text(ThemeResolver.displayKeywords(for: assignment.mappedRole, language: Localized.currentLanguage))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        DetailItem(title: Localized.string("app.mousecape")) {
                            Text(assignment.role.mousecapeMappingDescription)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        DetailItem(title: Localized.string("app.currentSource")) {
                            Text(assignment.sourceURL?.path ?? Localized.string("app.automaticallyMatchedInsideSelectedFolder"))
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                        if assignment.isOverride {
                            DetailItem(title: Localized.string("app.status")) {
                                Text(Localized.string("app.manualOverride"))
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .padding(.horizontal, LayoutMetrics.cardHorizontalPadding)
                    .padding(.vertical, LayoutMetrics.cardVerticalPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    EmptyView()
                }
            }
            .padding(LayoutMetrics.detailOuterPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct SettingsHeader: View {
    @ObservedObject var controller: CursorController
    @ObservedObject private var localization = LocalizationController.shared

    var body: some View {
        let _ = localization.selectedLanguage
        GroupBox {
            VStack(alignment: .leading, spacing: LayoutMetrics.cardSpacing) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Localized.string("app.cursorFolder"))
                            .font(.headline)
                        Text(controller.selectedFolderURL?.path ?? Localized.string("app.noFolderSelected"))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    Spacer()
                    Button(Localized.string("app.chooseFolder")) {
                        controller.chooseThemeFolder()
                    }
                    .buttonStyle(.bordered)
                }

            }
            .padding(.horizontal, LayoutMetrics.cardHorizontalPadding)
            .padding(.vertical, LayoutMetrics.cardVerticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct PreviewGroup<TrailingAction: View>: View {
    let subtitle: String
    let animation: CursorAnimation
    let exportSizeMultiplier: Double
    let trailingAction: TrailingAction
    @ObservedObject private var localization = LocalizationController.shared

    init(
        subtitle: String,
        animation: CursorAnimation,
        exportSizeMultiplier: Double,
        @ViewBuilder trailingAction: () -> TrailingAction = { EmptyView() }
    ) {
        self.subtitle = subtitle
        self.animation = animation
        self.exportSizeMultiplier = exportSizeMultiplier
        self.trailingAction = trailingAction()
    }

    var body: some View {
        let _ = localization.selectedLanguage
        GroupBox {
            VStack(alignment: .leading, spacing: LayoutMetrics.cardSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(subtitle)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    trailingAction
                }

                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: LayoutMetrics.itemSpacing) {
                        Text(Localized.string("preview.large"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        CursorPreviewView(animation: animation)
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: LayoutMetrics.itemSpacing) {
                        Text(Localized.string("preview.actualSize"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        CursorActualSizePreviewView(
                            animation: animation,
                            exportSizeMultiplier: exportSizeMultiplier
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal, LayoutMetrics.cardHorizontalPadding)
            .padding(.vertical, LayoutMetrics.cardVerticalPadding)
        } label: {
            EmptyView()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DetailItem<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    @ObservedObject private var localization = LocalizationController.shared

    var body: some View {
        let _ = localization.selectedLanguage
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title3.weight(.semibold))
            content
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, LayoutMetrics.itemVerticalPadding)
    }
}

struct EmptyPreviewGroup<TrailingAction: View>: View {
    let subtitle: String
    let trailingAction: TrailingAction
    @ObservedObject private var localization = LocalizationController.shared

    init(
        subtitle: String,
        @ViewBuilder trailingAction: () -> TrailingAction = { EmptyView() }
    ) {
        self.subtitle = subtitle
        self.trailingAction = trailingAction()
    }

    var body: some View {
        let _ = localization.selectedLanguage
        GroupBox {
            VStack(alignment: .leading, spacing: LayoutMetrics.cardSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(subtitle)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    trailingAction
                }

                VStack(spacing: LayoutMetrics.cardSpacing) {
                    Image(systemName: "cursorarrow")
                        .font(.system(size: 28))
                        .foregroundStyle(.tertiary)
                    Text(Localized.string("app.cursorWillAppearHere"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(height: 220)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, LayoutMetrics.cardHorizontalPadding)
            .padding(.vertical, LayoutMetrics.cardVerticalPadding)
        } label: {
            EmptyView()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CursorPreviewView: View {
    let animation: CursorAnimation

    var body: some View {
        TimelineView(.animation) { context in
            let index = currentIndex(at: context.date)
            Image(nsImage: animation.frames[index].image)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .padding(24)
        }
    }

    private func currentIndex(at date: Date) -> Int {
        guard animation.frames.count > 1 else { return 0 }
        let total = animation.frames.reduce(0.0) { $0 + $1.delay }
        guard total > 0 else { return 0 }
        let elapsed = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: total)
        var running = 0.0
        for (index, frame) in animation.frames.enumerated() {
            running += frame.delay
            if elapsed < running {
                return index
            }
        }
        return animation.frames.count - 1
    }
}

struct CursorActualSizePreviewView: View {
    let animation: CursorAnimation
    let exportSizeMultiplier: Double

    var body: some View {
        TimelineView(.animation) { context in
            let index = currentIndex(at: context.date)
            let displaySize = actualDisplaySize(for: animation, multiplier: exportSizeMultiplier)

            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                    .padding(24)

                Rectangle()
                    .fill(Color.secondary.opacity(0.18))
                    .frame(width: 1, height: 120)
                Rectangle()
                    .fill(Color.secondary.opacity(0.18))
                    .frame(width: 120, height: 1)

                Image(nsImage: animation.frames[index].image)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: displaySize.width, height: displaySize.height)
            }
            .padding(24)
        }
    }

    private func currentIndex(at date: Date) -> Int {
        guard animation.frames.count > 1 else { return 0 }
        let total = animation.frames.reduce(0.0) { $0 + $1.delay }
        guard total > 0 else { return 0 }
        let elapsed = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: total)
        var running = 0.0
        for (index, frame) in animation.frames.enumerated() {
            running += frame.delay
            if elapsed < running {
                return index
            }
        }
        return animation.frames.count - 1
    }

    private func actualDisplaySize(for animation: CursorAnimation, multiplier: Double) -> CGSize {
        CapeExporter.previewDisplaySize(for: animation, sizeMultiplier: multiplier)
    }
}
