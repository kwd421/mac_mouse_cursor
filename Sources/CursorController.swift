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
        case .arrow: return "일반 선택"
        case .text: return "텍스트 선택"
        case .link: return "링크 선택"
        case .location: return "위치 선택"
        case .precision: return "정밀도 선택"
        case .move: return "이동"
        case .unavailable: return "사용 불가"
        case .busy: return "사용 중"
        case .working: return "백그라운드 작업"
        case .help: return "도움말"
        case .handwriting: return "손글씨"
        case .person: return "사람 선택"
        case .alternate: return "바로가기"
        case .verticalResize: return "수직 크기 조절"
        case .horizontalResize: return "수평 크기 조절"
        case .diagonalResizeNWSE: return "대각선 크기 조절 1"
        case .diagonalResizeNESW: return "대각선 크기 조절 2"
        }
    }

    var englishName: String {
        switch self {
        case .arrow: return "Arrow"
        case .text: return "Text"
        case .link: return "Link"
        case .location: return "Location"
        case .precision: return "Precision"
        case .move: return "Move"
        case .unavailable: return "Unavailable"
        case .busy: return "Busy"
        case .working: return "Working"
        case .help: return "Help"
        case .handwriting: return "Handwriting"
        case .person: return "Person"
        case .alternate: return "Alias"
        case .verticalResize: return "Vertical Resize"
        case .horizontalResize: return "Horizontal Resize"
        case .diagonalResizeNWSE: return "Diagonal Resize 1"
        case .diagonalResizeNESW: return "Diagonal Resize 2"
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
}

struct CursorAssignment: Identifiable {
    let role: CursorRole
    let defaultPreview: CursorAnimation
    let appliedPreview: CursorAnimation?
    let sourceURL: URL?
    let isOverride: Bool
    let isResolved: Bool
    let usesArrowFallback: Bool

    var id: CursorRole { role }
}

struct CursorTheme {
    let animations: [CursorRole: CursorAnimation]

    subscript(role: CursorRole) -> CursorAnimation? {
        animations[role]
    }
}

@MainActor
final class CursorController: ObservableObject {
    @Published private(set) var selectedFolderURL: URL?
    @Published private(set) var selectedFolderIsValid = false
    @Published private(set) var resolvedRoleCount = 0
    @Published private(set) var assignments: [CursorAssignment] = []
    @Published private(set) var statusText = "초기화 중..."

    private let defaults = UserDefaults.standard
    private let parser = AniParser()
    private let capeExporter = CapeExporter()
    private let cursorMatcher = CursorMatcher()
    private let themeResolver = ThemeResolver()
    private var overrideURLs: [CursorRole: URL] = [:]

    func start() {
        clearLegacyDefaults()
        assignments = unresolvedAssignments()
        if let folderPath = defaults.string(forKey: Keys.folderPath) {
            selectedFolderURL = URL(fileURLWithPath: folderPath, isDirectory: true)
        }
        overrideURLs = loadOverrides()
        reload()
    }

    func stop() {}

    func chooseThemeFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = selectedFolderURL
        panel.prompt = "폴더 선택"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        setThemeFolder(url)
    }

    func setThemeFolder(_ url: URL) {
        let normalizedNewURL = url.standardizedFileURL
        let previousURL = selectedFolderURL?.standardizedFileURL
        selectedFolderURL = url
        defaults.set(url.path, forKey: Keys.folderPath)
        if previousURL != normalizedNewURL, !overrideURLs.isEmpty {
            overrideURLs.removeAll()
            saveOverrides()
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
        panel.prompt = "커서 선택"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        let ext = url.pathExtension.lowercased()
        guard ext == "ani" || ext == "cur" else {
            statusText = "지원하는 파일은 .ani 또는 .cur 입니다."
            return
        }
        overrideURLs[role] = url
        saveOverrides()
        reload()
    }

    func clearOverride(for role: CursorRole) {
        overrideURLs.removeValue(forKey: role)
        saveOverrides()
        reload()
    }

    func exportMousecapeCape() {
        do {
            let resolution = try loadTheme()
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.data]
            panel.nameFieldStringValue = sanitizedCapeFileName()
            panel.canCreateDirectories = true
            panel.prompt = "내보내기"

            guard panel.runModal() == .OK, var url = panel.url else { return }
            if url.pathExtension.lowercased() != "cape" {
                url.deletePathExtension()
                url.appendPathExtension("cape")
            }

            try capeExporter.exportCape(
                name: capeDisplayName(),
                author: NSFullUserName().isEmpty ? NSUserName() : NSFullUserName(),
                identifier: "local.\(Bundle.main.bundleIdentifier ?? "macmousecursor").\(UUID().uuidString.lowercased())",
                theme: resolution.theme,
                to: url
            )
            statusText = "Mousecape용 cape 내보내기 완료: \(url.lastPathComponent)"
        } catch {
            statusText = "cape 내보내기 실패: \(error.localizedDescription)"
        }
    }

    func reload() {
        do {
            let resolution = try loadTheme()
            assignments = makeAssignments(
                from: resolution.theme,
                resolvedFiles: resolution.filesByRole,
                fallbackRoles: resolution.fallbackRoles
            )
            resolvedRoleCount = assignments.filter(\.isResolved).count
            selectedFolderIsValid = true
            let folderName = selectedFolderURL?.lastPathComponent ?? "폴더 없음"
            statusText = "로드 완료: \(folderName) · \(resolvedRoleCount)/\(CursorRole.allCases.count)개 역할 연결됨"
        } catch {
            assignments = unresolvedAssignments()
            resolvedRoleCount = 0
            selectedFolderIsValid = false
            statusText = "불러오기 실패: \(error.localizedDescription)"
        }
    }

    func assignment(for role: CursorRole) -> CursorAssignment? {
        assignments.first(where: { $0.role == role })
    }

    func placeholderAssignment(for role: CursorRole) -> CursorAssignment? {
        unresolvedAssignments().first(where: { $0.role == role })
    }

    private func loadTheme() throws -> (theme: CursorTheme, filesByRole: [CursorRole: URL], fallbackRoles: Set<CursorRole>) {
        guard let baseDirectory = selectedFolderURL else {
            throw CursorError.missingTheme("테마 폴더가 선택되지 않았습니다.")
        }

        var animations: [CursorRole: CursorAnimation] = [:]
        let resolvedTheme = try themeResolver.resolveTheme(in: baseDirectory)
        var resolvedFiles = resolvedTheme.filesByRole

        for role in CursorRole.allCases {
            if let override = overrideURLs[role], FileManager.default.fileExists(atPath: override.path) {
                animations[role] = try parser.parseCursorFile(at: override)
                resolvedFiles[role] = override
                continue
            }
            guard let url = resolvedFiles[role] else { continue }
            animations[role] = try parser.parseCursorFile(at: url)
        }

        guard animations[.arrow] != nil else {
            throw CursorError.missingTheme(baseDirectory.path)
        }

        return (CursorTheme(animations: animations), resolvedFiles, resolvedTheme.fallbackRoles)
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
                defaultPreview: cursorMatcher.defaultPreview(for: role),
                appliedPreview: applied,
                sourceURL: autoResolved,
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
                defaultPreview: cursorMatcher.defaultPreview(for: role),
                appliedPreview: nil,
                sourceURL: overrideURLs[role],
                isOverride: overrideURLs[role] != nil,
                isResolved: false,
                usesArrowFallback: false
            )
        }
    }

    private func loadOverrides() -> [CursorRole: URL] {
        guard let raw = defaults.dictionary(forKey: Keys.overrides) as? [String: String] else { return [:] }
        var result: [CursorRole: URL] = [:]
        for (key, path) in raw {
            guard let role = CursorRole(rawValue: key) else { continue }
            result[role] = URL(fileURLWithPath: path)
        }
        return result
    }

    private func saveOverrides() {
        let raw = Dictionary(uniqueKeysWithValues: overrideURLs.map { ($0.key.rawValue, $0.value.path) })
        defaults.set(raw, forKey: Keys.overrides)
    }

    private func clearLegacyDefaults() {
        [
            "calibrationOffsets",
            "isEnabled",
            "launchAtLogin",
            "selectedBorder",
            "selectedStyle"
        ].forEach { defaults.removeObject(forKey: $0) }
    }

    private func capeDisplayName() -> String {
        selectedFolderURL?.lastPathComponent.isEmpty == false ? selectedFolderURL!.lastPathComponent : "Mac Mouse Cursor Export"
    }

    private func sanitizedCapeFileName() -> String {
        let raw = capeDisplayName()
        let invalid = CharacterSet(charactersIn: "/:\\")
        let cleaned = raw.components(separatedBy: invalid).joined(separator: "-")
        return cleaned.isEmpty ? "MacMouseCursor.cape" : "\(cleaned).cape"
    }

    private enum Keys {
        static let folderPath = "selectedFolderPath"
        static let overrides = "overridePaths"
    }
}

enum CursorError: LocalizedError {
    case missingTheme(String)
    case invalidANI(String)
    case invalidThemeSelection(String)
    case launchAgentUpdateFailed(String)
    case privateCursorHelperFailed(String)
    case unsupportedCursorPayload

    var errorDescription: String? {
        switch self {
        case .missingTheme(let path):
            return "테마 파일이 없습니다: \(path)"
        case .invalidANI(let message):
            return "ANI 파싱 실패: \(message)"
        case .invalidThemeSelection(let message):
            return message
        case .launchAgentUpdateFailed(let message):
            return "로그인 항목을 적용하지 못했습니다: \(message)"
        case .privateCursorHelperFailed(let message):
            return "시스템 커서 헬퍼 실행 실패: \(message)"
        case .unsupportedCursorPayload:
            return "커서 프레임을 이미지로 읽지 못했습니다."
        }
    }
}
