import AppKit
import Foundation

struct CursorFrame {
    let image: NSImage
    let delay: TimeInterval
}

struct CursorAnimation {
    let frames: [CursorFrame]
    let hotspot: CGPoint
    let canvasSize: CGSize
}

enum CursorRole: String, CaseIterable, Identifiable {
    case arrow
    case text
    case link
    case location
    case precision
    case move
    case unavailable
    case busy
    case working
    case help
    case handwriting
    case person
    case alternate
    case verticalResize
    case horizontalResize
    case diagonalResizeNWSE
    case diagonalResizeNESW

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .arrow: return Localized.string("role.arrow")
        case .text: return Localized.string("role.text")
        case .link: return Localized.string("role.link")
        case .location: return Localized.string("role.location")
        case .precision: return Localized.string("role.precision")
        case .move: return Localized.string("role.move")
        case .unavailable: return Localized.string("role.unavailable")
        case .busy: return Localized.string("role.busy")
        case .working: return Localized.string("role.working")
        case .help: return Localized.string("role.help")
        case .handwriting: return Localized.string("role.handwriting")
        case .person: return Localized.string("role.person")
        case .alternate: return Localized.string("role.alternate")
        case .verticalResize: return Localized.string("role.verticalResize")
        case .horizontalResize: return Localized.string("role.horizontalResize")
        case .diagonalResizeNWSE: return Localized.string("role.diagonalResizeNWSE")
        case .diagonalResizeNESW: return Localized.string("role.diagonalResizeNESW")
        }
    }

    var themeFileName: String {
        switch self {
        case .arrow: return "독케익_일반선택.ani"
        case .text: return "독케익_텍스트 선택.ani"
        case .link: return "독케익_연결,위치,사용자 선택.ani"
        case .location: return "Pin.ani"
        case .precision: return "독케익_정밀도 선택.ani"
        case .move: return "독케익_이동.ani"
        case .unavailable: return "독케익_사용할 수 없음.ani"
        case .busy: return "Busy.ani"
        case .working: return "독케익_백그라운드 작업,사용중.ani"
        case .help: return "Help.ani"
        case .handwriting: return "Handwriting.ani"
        case .person: return "Person.ani"
        case .alternate: return "Alternate.ani"
        case .verticalResize: return "독케익_수직 크기 조절.ani"
        case .horizontalResize: return "독케익_수평 크기 조절.ani"
        case .diagonalResizeNWSE: return "독케익_대각선 방향 크기 조절 1.ani"
        case .diagonalResizeNESW: return "독케익_대각선 방향 크기 조절 2.ani"
        }
    }

    var mousecapeMappingDescription: String {
        switch self {
        case .arrow:
            return "Arrow"
        case .text:
            return "IBeam, IBeamXOR"
        case .link:
            return "Link, Pointing"
        case .location:
            return "Copy, Copy Drag"
        case .precision:
            return "Crosshair, Crosshair 2"
        case .move:
            return "Move, Closed, Open"
        case .unavailable:
            return "Forbidden"
        case .busy:
            return "Busy"
        case .working:
            return "Wait"
        case .help:
            return "Help"
        case .handwriting:
            return "Cell XOR"
        case .person:
            return "Cell"
        case .alternate:
            return "Alias"
        case .verticalResize:
            return "Resize N, Resize S, Resize N-S, Window N, Window S, Window N-S"
        case .horizontalResize:
            return "Resize W, Resize E, Resize W-E, Window W, Window E, Window E-W"
        case .diagonalResizeNWSE:
            return "Window NW, Window NW-SE, Window SE"
        case .diagonalResizeNESW:
            return "Window NE, Window NE-SW, Window SW"
        }
    }

}

struct CursorAssignment: Identifiable {
    let role: CursorRole
    let appliedPreview: CursorAnimation?
    let sourceURL: URL?
    let isOverride: Bool
    let isResolved: Bool
    let usesArrowFallback: Bool

    var id: CursorRole { role }
}

struct CursorTheme {
    let animations: [CursorRole: CursorAnimation]
    let supplementalAnimations: [SupplementalCursorRole: CursorAnimation]

    init(
        animations: [CursorRole: CursorAnimation],
        supplementalAnimations: [SupplementalCursorRole: CursorAnimation] = [:]
    ) {
        self.animations = animations
        self.supplementalAnimations = supplementalAnimations
    }

    subscript(role: CursorRole) -> CursorAnimation? {
        animations[role]
    }

    subscript(role: SupplementalCursorRole) -> CursorAnimation? {
        supplementalAnimations[role]
    }
}

enum SupplementalCursorRole: String, CaseIterable, Identifiable {
    case contextualMenu
    case dragCopy
    case dragLink
    case disappearingItem
    case resizeUp
    case resizeDown
    case resizeLeft
    case resizeRight
    case verticalIBeam

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .contextualMenu: return Localized.string("role.contextualMenu")
        case .dragCopy: return Localized.string("role.dragCopy")
        case .dragLink: return Localized.string("role.dragLink")
        case .disappearingItem: return Localized.string("role.disappearingItem")
        case .resizeUp: return Localized.string("role.resizeUp")
        case .resizeDown: return Localized.string("role.resizeDown")
        case .resizeLeft: return Localized.string("role.resizeLeft")
        case .resizeRight: return Localized.string("role.resizeRight")
        case .verticalIBeam: return Localized.string("role.verticalIBeam")
        }
    }

    var mousecapeMappingDescription: String {
        switch self {
        case .contextualMenu: return "Contextual Menu"
        case .dragCopy: return "Drag Copy"
        case .dragLink: return "Drag Link"
        case .disappearingItem: return "Disappearing Item"
        case .resizeUp: return "Resize Up"
        case .resizeDown: return "Resize Down"
        case .resizeLeft: return "Resize Left"
        case .resizeRight: return "Resize Right"
        case .verticalIBeam: return "Vertical IBeam"
        }
    }

    var mappedPrimaryRole: CursorRole {
        switch self {
        case .contextualMenu: return .link
        case .dragCopy: return .location
        case .dragLink: return .alternate
        case .disappearingItem: return .unavailable
        case .resizeUp, .resizeDown: return .verticalResize
        case .resizeLeft, .resizeRight: return .horizontalResize
        case .verticalIBeam: return .text
        }
    }
}

enum SidebarCursorItem: Hashable, Identifiable {
    case primary(CursorRole)
    case supplemental(SupplementalCursorRole)

    var id: String {
        switch self {
        case .primary(let role): return "primary.\(role.rawValue)"
        case .supplemental(let role): return "supplemental.\(role.rawValue)"
        }
    }
}

struct SupplementalCursorAssignment: Identifiable {
    let role: SupplementalCursorRole
    let mappedRole: CursorRole
    let appliedPreview: CursorAnimation?
    let sourceURL: URL?
    let isOverride: Bool
    let isResolved: Bool

    var id: SupplementalCursorRole { role }
}

@MainActor
final class CursorController: ObservableObject {
    private enum DefaultsKey {
        static let exportAuthorName = "exportAuthorName"
    }

    private enum StatusState {
        case startingUp
        case chooseCursorFolder
        case supportedFiles
        case exportSuccess(String)
        case exportFailure(String)
        case loaded(folderName: String, resolvedRoleCount: Int, totalRoleCount: Int)
        case loadFailure(String)
    }

    @Published private(set) var selectedFolderURL: URL?
    @Published private(set) var selectedFolderIsValid = false
    @Published private(set) var resolvedRoleCount = 0
    @Published private(set) var assignments: [CursorAssignment] = []
    @Published private(set) var statusText = Localized.string("status.startingUp")
    @Published var exportAuthorName: String {
        didSet {
            let trimmed = exportAuthorName.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                UserDefaults.standard.removeObject(forKey: DefaultsKey.exportAuthorName)
            } else {
                UserDefaults.standard.set(exportAuthorName, forKey: DefaultsKey.exportAuthorName)
            }
        }
    }
    @Published var exportSizeMultiplier: Double {
        didSet {
            let clamped = Self.clampExportSizeMultiplier(exportSizeMultiplier)
            if clamped != exportSizeMultiplier {
                exportSizeMultiplier = clamped
            }
        }
    }

    private let parser = AniParser()
    private let capeExporter = CapeExporter()
    private let themeResolver = ThemeResolver()
    private var overrideURLs: [CursorRole: URL] = [:]
    private var supplementalOverrideURLs: [SupplementalCursorRole: URL] = [:]
    private var currentTheme = CursorTheme(animations: [:], supplementalAnimations: [:])
    private var statusState: StatusState = .startingUp

    init() {
        exportAuthorName = UserDefaults.standard.string(forKey: DefaultsKey.exportAuthorName) ?? ""
        exportSizeMultiplier = 1.0
    }

    func start() {
        clearLegacyDefaults()
        assignments = unresolvedAssignments()
        selectedFolderURL = nil
        selectedFolderIsValid = false
        resolvedRoleCount = 0
        overrideURLs = [:]
        supplementalOverrideURLs = [:]
        setStatus(.chooseCursorFolder)
    }

    func relocalize() {
        statusText = localizedStatusText(for: statusState)
        objectWillChange.send()
    }

    func chooseThemeFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = selectedFolderURL
        panel.prompt = Localized.string("panel.chooseFolder")

        guard panel.runModal() == .OK, let url = panel.url else { return }
        setThemeFolder(url)
    }

    func setThemeFolder(_ url: URL) {
        let normalizedNewURL = url.standardizedFileURL
        let previousURL = selectedFolderURL?.standardizedFileURL
        selectedFolderURL = url
        if previousURL != normalizedNewURL, !overrideURLs.isEmpty {
            overrideURLs.removeAll()
        }
        if previousURL != normalizedNewURL, !supplementalOverrideURLs.isEmpty {
            supplementalOverrideURLs.removeAll()
        }
        reload()
    }

    func chooseOverride(for role: CursorRole) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.data]
        panel.directoryURL = overrideURLs[role]?.deletingLastPathComponent() ?? selectedFolderURL
        panel.prompt = Localized.string("panel.chooseCursor")

        guard panel.runModal() == .OK, let url = panel.url else { return }
        let ext = url.pathExtension.lowercased()
        guard ext == "ani" || ext == "cur" else {
            setStatus(.supportedFiles)
            return
        }
        overrideURLs[role] = url
        reload()
    }

    func chooseOverride(for role: SupplementalCursorRole) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.data]
        panel.directoryURL = supplementalOverrideURLs[role]?.deletingLastPathComponent() ?? selectedFolderURL
        panel.prompt = Localized.string("panel.chooseCursor")

        guard panel.runModal() == .OK, let url = panel.url else { return }
        let ext = url.pathExtension.lowercased()
        guard ext == "ani" || ext == "cur" else {
            setStatus(.supportedFiles)
            return
        }
        if let inheritedURL = effectiveSupplementalInheritedSourceURL(for: role),
           inheritedURL.standardizedFileURL == url.standardizedFileURL {
            supplementalOverrideURLs.removeValue(forKey: role)
        } else {
            supplementalOverrideURLs[role] = url
        }
        reload()
    }

    func exportMousecapeCape(authorName: String) {
        do {
            let resolution = try loadTheme()
            let trimmedAuthor = authorName.trimmingCharacters(in: .whitespacesAndNewlines)
            let author: String
            if trimmedAuthor.isEmpty {
                let fallbackAuthor = defaultAuthorName()
                let alert = NSAlert()
                alert.messageText = Localized.string("export.emptyAuthorTitle")
                alert.informativeText = Localized.string("export.emptyAuthorMessage", fallbackAuthor)
                alert.alertStyle = .warning
                alert.addButton(withTitle: Localized.string("export.useMacUserName"))
                alert.addButton(withTitle: Localized.string("export.cancel"))
                guard alert.runModal() == .alertFirstButtonReturn else { return }
                author = fallbackAuthor
            } else {
                author = trimmedAuthor
            }
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.data]
            panel.nameFieldStringValue = sanitizedCapeFileName()
            panel.canCreateDirectories = true
            panel.prompt = Localized.string("panel.export")

            guard panel.runModal() == .OK, var url = panel.url else { return }
            if url.pathExtension.lowercased() != "cape" {
                url.deletePathExtension()
                url.appendPathExtension("cape")
            }

            let exportName = exportCapeDisplayName(for: url)

            try capeExporter.exportCape(
                name: exportName,
                author: author,
                identifier: "local.\(Bundle.main.bundleIdentifier ?? "capeforge").\(UUID().uuidString.lowercased())",
                theme: resolution.theme,
                sizeMultiplier: exportSizeMultiplier,
                to: url
            )
            setStatus(.exportSuccess(url.lastPathComponent))
        } catch {
            setStatus(.exportFailure(error.localizedDescription))
        }
    }

    func reload() {
        do {
            let resolution = try loadTheme()
            currentTheme = resolution.theme
            assignments = makeAssignments(
                from: resolution.theme,
                resolvedFiles: resolution.filesByRole,
                fallbackRoles: resolution.fallbackRoles
            )
            resolvedRoleCount = assignments.filter(\.isResolved).count
            selectedFolderIsValid = true
            let folderName = selectedFolderURL?.lastPathComponent ?? ""
            setStatus(.loaded(folderName: folderName, resolvedRoleCount: resolvedRoleCount, totalRoleCount: CursorRole.allCases.count))
        } catch {
            currentTheme = CursorTheme(animations: [:], supplementalAnimations: [:])
            assignments = unresolvedAssignments()
            resolvedRoleCount = 0
            selectedFolderIsValid = false
            setStatus(.loadFailure(error.localizedDescription))
        }
    }

    func assignment(for role: CursorRole) -> CursorAssignment? {
        assignments.first(where: { $0.role == role })
    }

    func supplementalAssignment(for role: SupplementalCursorRole) -> SupplementalCursorAssignment {
        let baseRole = role.mappedPrimaryRole
        let baseAssignment = assignment(for: baseRole)
        let overrideURL = supplementalOverrideURLs[role]
        let inheritedURL = baseAssignment?.sourceURL
        let isOverride = {
            guard let overrideURL else { return false }
            guard let inheritedURL else { return true }
            return overrideURL.standardizedFileURL != inheritedURL.standardizedFileURL
        }()
        return SupplementalCursorAssignment(
            role: role,
            mappedRole: baseRole,
            appliedPreview: currentTheme[role] ?? baseAssignment?.appliedPreview,
            sourceURL: isOverride ? overrideURL : inheritedURL,
            isOverride: isOverride,
            isResolved: (currentTheme[role] ?? baseAssignment?.appliedPreview) != nil
        )
    }

    private func loadTheme() throws -> (theme: CursorTheme, filesByRole: [CursorRole: URL], fallbackRoles: Set<CursorRole>) {
        guard let baseDirectory = selectedFolderURL else {
            throw CursorError.missingTheme(Localized.string("error.noThemeFolderSelected"))
        }

        var animations: [CursorRole: CursorAnimation] = [:]
        var supplementalAnimations: [SupplementalCursorRole: CursorAnimation] = [:]
        var parsedAnimationsByURL: [URL: CursorAnimation] = [:]
        let resolvedTheme = try themeResolver.resolveTheme(in: baseDirectory)
        var resolvedFiles = resolvedTheme.filesByRole

        func parsedAnimation(for url: URL) throws -> CursorAnimation {
            let normalizedURL = url.standardizedFileURL
            if let cached = parsedAnimationsByURL[normalizedURL] {
                return cached
            }
            let parsed = try parser.parseCursorFile(at: normalizedURL)
            parsedAnimationsByURL[normalizedURL] = parsed
            return parsed
        }

        for role in CursorRole.allCases {
            if let override = overrideURLs[role], FileManager.default.fileExists(atPath: override.path) {
                animations[role] = try parsedAnimation(for: override)
                resolvedFiles[role] = override
                continue
            }
            guard let url = resolvedFiles[role] else { continue }
            animations[role] = try parsedAnimation(for: url)
        }

        for role in SupplementalCursorRole.allCases {
            if let override = supplementalOverrideURLs[role] {
                if FileManager.default.fileExists(atPath: override.path) {
                    if let inheritedURL = effectiveSupplementalInheritedSourceURL(for: role, resolvedFiles: resolvedFiles),
                       inheritedURL.standardizedFileURL == override.standardizedFileURL,
                       let baseAnimation = animations[role.mappedPrimaryRole] {
                        supplementalOverrideURLs.removeValue(forKey: role)
                        supplementalAnimations[role] = baseAnimation
                    } else {
                        supplementalAnimations[role] = try parsedAnimation(for: override)
                    }
                    continue
                } else {
                    supplementalOverrideURLs.removeValue(forKey: role)
                }
            }
            if let baseAnimation = animations[role.mappedPrimaryRole] {
                supplementalAnimations[role] = baseAnimation
            }
        }

        guard animations[.arrow] != nil else {
            throw CursorError.missingTheme(baseDirectory.path)
        }

        return (CursorTheme(animations: animations, supplementalAnimations: supplementalAnimations), resolvedFiles, resolvedTheme.fallbackRoles)
    }

    var exportSizePercentageText: String {
        "\(Int((exportSizeMultiplier * 100).rounded()))%"
    }

    private static func clampExportSizeMultiplier(_ value: Double) -> Double {
        min(max(value, 1.0), 3.0)
    }

    private func makeAssignments(from theme: CursorTheme, resolvedFiles: [CursorRole: URL], fallbackRoles: Set<CursorRole>) -> [CursorAssignment] {
        CursorRole.allCases.map { role in
            let autoResolved = resolvedFiles[role]
            let overrideURL = overrideURLs[role]
            let isOverride = {
                guard let overrideURL else { return false }
                guard let autoResolved else { return true }
                return overrideURL.standardizedFileURL != autoResolved.standardizedFileURL
            }()
            let applied = theme[role]
        return CursorAssignment(
                role: role,
                appliedPreview: applied,
                sourceURL: overrideURL ?? autoResolved,
                isOverride: isOverride,
                isResolved: applied != nil,
                usesArrowFallback: !isOverride && fallbackRoles.contains(role)
            )
        }
    }

    private func unresolvedAssignments() -> [CursorAssignment] {
        CursorRole.allCases.map { role in
            CursorAssignment(
                role: role,
                appliedPreview: nil,
                sourceURL: overrideURLs[role],
                isOverride: overrideURLs[role] != nil,
                isResolved: false,
                usesArrowFallback: false
            )
        }
    }

    private func clearLegacyDefaults() {
        [
            "calibrationOffsets",
            "isEnabled",
            "selectedBorder",
            "selectedStyle"
        ].forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    private func effectiveSupplementalInheritedSourceURL(
        for role: SupplementalCursorRole,
        resolvedFiles: [CursorRole: URL]? = nil
    ) -> URL? {
        let mappedRole = role.mappedPrimaryRole
        if let primaryOverride = overrideURLs[mappedRole], FileManager.default.fileExists(atPath: primaryOverride.path) {
            return primaryOverride
        }
        return resolvedFiles?[mappedRole]
    }

    private func capeDisplayName() -> String {
        selectedFolderURL?.lastPathComponent.isEmpty == false ? selectedFolderURL!.lastPathComponent : "Cape Forge Export"
    }

    private func sanitizedCapeFileName() -> String {
        let raw = capeDisplayName()
        let invalid = CharacterSet(charactersIn: "/:\\")
        let cleaned = raw.components(separatedBy: invalid).joined(separator: "-")
        return cleaned.isEmpty ? "Cape Forge.cape" : "\(cleaned).cape"
    }

    private func exportCapeDisplayName(for url: URL) -> String {
        let candidate = url.deletingPathExtension().lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines)
        if !candidate.isEmpty {
            return candidate
        }
        return capeDisplayName()
    }

    func defaultAuthorName() -> String {
        let fullName = NSFullUserName().trimmingCharacters(in: .whitespacesAndNewlines)
        if !fullName.isEmpty {
            return fullName
        }

        let userName = NSUserName().trimmingCharacters(in: .whitespacesAndNewlines)
        if !userName.isEmpty {
            return userName
        }

        return Localized.string("export.unknownAuthor")
    }

    private func setStatus(_ state: StatusState) {
        statusState = state
        statusText = localizedStatusText(for: state)
    }

    private func localizedStatusText(for state: StatusState) -> String {
        switch state {
        case .startingUp:
            return Localized.string("status.startingUp")
        case .chooseCursorFolder:
            return Localized.string("status.chooseCursorFolder")
        case .supportedFiles:
            return Localized.string("status.supportedFiles")
        case .exportSuccess(let fileName):
            return Localized.string("status.exportSuccess", fileName)
        case .exportFailure(let message):
            return Localized.string("status.exportFailure", message)
        case .loaded(let folderName, let resolvedRoleCount, let totalRoleCount):
            let displayFolder = folderName.isEmpty ? Localized.string("app.noFolderSelected") : folderName
            return Localized.string("status.loaded", displayFolder, resolvedRoleCount, totalRoleCount)
        case .loadFailure(let message):
            return Localized.string("status.loadFailure", message)
        }
    }

}

enum CursorError: LocalizedError {
    case missingTheme(String)
    case invalidANI(String)
    case invalidThemeSelection(String)
    case unsupportedCursorPayload

    var errorDescription: String? {
        switch self {
        case .missingTheme(let path):
            return Localized.string("error.themeFileMissing", path)
        case .invalidANI(let message):
            return Localized.string("error.aniParsingFailed", message)
        case .invalidThemeSelection(let message):
            return message
        case .unsupportedCursorPayload:
            return Localized.string("error.unsupportedCursorPayload")
        }
    }
}
