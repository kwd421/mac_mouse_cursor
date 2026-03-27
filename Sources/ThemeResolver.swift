import Foundation

struct ResolvedTheme {
    let filesByRole: [CursorRole: URL]
    let fallbackRoles: Set<CursorRole>
}

struct ThemeResolver {
    func resolveTheme(in directory: URL) throws -> ResolvedTheme {
        guard FileManager.default.fileExists(atPath: directory.path) else {
            throw CursorError.missingTheme(directory.path)
        }

        let candidates = try directCursorFiles(in: directory)
        guard !candidates.isEmpty else {
            throw CursorError.invalidThemeSelection("""
            이 폴더에는 바로 적용할 커서 파일이 없습니다.
            .ani 또는 .cur 파일이 직접 들어 있는 폴더를 선택하세요.
            """)
        }

        var mapping: [CursorRole: URL] = [:]
        var fallbackRoles = Set<CursorRole>()

        for role in CursorRole.allCases {
            if let exact = candidates.first(where: { canonicalFileName($0.lastPathComponent) == canonicalFileName(role.themeFileName) }) {
                mapping[role] = exact
                continue
            }

            if let exactAlias = candidates.first(where: { Self.aliasStems(for: role).contains(canonicalStem($0)) }) {
                mapping[role] = exactAlias
                continue
            }

            let fuzzyMatches = candidates
                .map { ($0, fuzzyScore(for: role, candidate: $0)) }
                .filter { $0.1 > 0 }
                .sorted {
                    if $0.1 == $1.1 {
                        return canonicalStem($0.0) < canonicalStem($1.0)
                    }
                    return $0.1 > $1.1
                }

            if let best = fuzzyMatches.first?.0 {
                mapping[role] = best
            }
        }

        if mapping[.arrow] == nil, let fallback = fallbackArrowCandidate(from: candidates, excluding: Set(mapping.values.map(\.standardizedFileURL))) {
            mapping[.arrow] = fallback
        }

        if let arrow = mapping[.arrow] {
            for role in CursorRole.allCases where mapping[role] == nil {
                mapping[role] = arrow
                if role != .arrow {
                    fallbackRoles.insert(role)
                }
            }
        }

        return ResolvedTheme(filesByRole: mapping, fallbackRoles: fallbackRoles)
    }

    private func directCursorFiles(in directory: URL) throws -> [URL] {
        let contents = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        return contents.filter {
            ["ani", "cur"].contains($0.pathExtension.lowercased())
        }
    }

    private func fuzzyScore(for role: CursorRole, candidate: URL) -> Int {
        let name = canonicalStem(candidate)
        return Self.fuzzyKeywords[role, default: []].reduce(into: 0) { score, keyword in
            if name.contains(keyword) {
                score += 1
            }
        }
    }

    private static let exactAliases: [CursorRole: [String]] = [
        .arrow: ["일반선택", "일반", "기본선택", "arrow", "normal", "pointer", "default"],
        .text: ["텍스트선택", "텍스트", "text", "ibeam"],
        .location: ["연결위치사용자선택", "위치선택", "location", "loc", "pin", "copy"],
        .link: ["연결위치사용자선택", "연결", "사용자선택", "링크", "link", "pointinghand"],
        .precision: ["정밀도선택", "정밀도", "precision", "crosshair", "cross"],
        .move: ["이동", "move", "openhand", "closedhand"],
        .unavailable: ["사용할수없음", "사용불가", "notallowed", "unavailable"],
        .busy: ["백그라운드작업사용중", "busy", "사용중"],
        .working: ["백그라운드작업사용중", "백그라운드작업", "working"],
        .help: ["help", "도움말"],
        .handwriting: ["handwriting", "손글씨"],
        .person: ["person", "cell", "사람선택"],
        .alternate: ["alternate", "alias", "별칭", "바로가기"],
        .verticalResize: ["수직크기조절", "vertical", "updown", "vert"],
        .horizontalResize: ["수평크기조절", "horizontal", "leftright", "horz"],
        .diagonalResizeNWSE: ["대각선방향크기조절1", "대각선1", "nwse", "diagonal1", "dgn1"],
        .diagonalResizeNESW: ["대각선방향크기조절2", "대각선2", "nesw", "diagonal2", "dgn2"]
    ]

    private static let fuzzyKeywords: [CursorRole: [String]] = [
        .arrow: ["일반선택", "일반", "기본선택", "arrow", "normal", "pointer", "default"],
        .text: ["텍스트선택", "텍스트", "text", "ibeam"],
        .location: ["연결위치사용자선택", "위치선택", "location", "loc", "pin", "copy"],
        .link: ["연결", "사용자선택", "링크", "link", "pointinghand"],
        .precision: ["정밀도선택", "정밀도", "precision", "crosshair", "cross"],
        .move: ["이동", "move", "openhand", "closedhand"],
        .unavailable: ["사용할수없음", "사용불가", "notallowed", "unavailable"],
        .busy: ["백그라운드작업", "사용중", "busy"],
        .working: ["백그라운드작업", "working"],
        .help: ["help", "도움말"],
        .handwriting: ["handwriting", "손글씨"],
        .person: ["person", "cell", "사람선택"],
        .alternate: ["alternate", "alias", "별칭", "바로가기"],
        .verticalResize: ["수직크기조절", "vertical", "updown", "vert"],
        .horizontalResize: ["수평크기조절", "horizontal", "leftright", "horz"],
        .diagonalResizeNWSE: ["대각선방향크기조절1", "대각선1", "nwse", "diagonal1", "dgn1"],
        .diagonalResizeNESW: ["대각선방향크기조절2", "대각선2", "nesw", "diagonal2", "dgn2"]
    ]

    private static func aliasStems(for role: CursorRole) -> Set<String> {
        Set(exactAliases[role, default: []].map {
            $0.precomposedStringWithCanonicalMapping
                .lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .joined()
        })
    }

    private func canonicalFileName(_ value: String) -> String {
        value.precomposedStringWithCanonicalMapping.lowercased()
    }

    private func canonicalStem(_ url: URL) -> String {
        url.deletingPathExtension().lastPathComponent
            .precomposedStringWithCanonicalMapping
            .lowercased()
            .replacingOccurrences(of: "독케익_", with: "")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    private func fallbackArrowCandidate(from candidates: [URL], excluding used: Set<URL>) -> URL? {
        let remaining = candidates.filter { !used.contains($0.standardizedFileURL) }
        guard !remaining.isEmpty else { return nil }

        let preferred = ["pointer", "normal", "default", "arrow", "basic", "main"]
        if let named = remaining.first(where: { url in
            let stem = canonicalStem(url)
            return preferred.contains(where: { stem.contains($0) })
        }) {
            return named
        }

        return remaining.sorted { canonicalStem($0) < canonicalStem($1) }.first
    }
}
