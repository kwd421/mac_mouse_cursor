import AppKit
import Foundation
import Testing
@testable import MacMouseCursor

struct ThemeResolverTests {
    @Test
    func resolvesDecomposedHangulFileNames() throws {
        let tempDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let folder = tempDirectory.appendingPathComponent("기본", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let decomposedName = "독케익_일반선택.ani"
        FileManager.default.createFile(atPath: folder.appendingPathComponent(decomposedName).path, contents: Data("x".utf8))

        let resolved = try ThemeResolver().resolveTheme(in: folder)
        #expect(resolved.filesByRole[.arrow]?.lastPathComponent == decomposedName)
    }

    @Test
    func rejectsPackRootWithoutDirectCursorFiles() throws {
        let tempDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let nested = tempDirectory
            .appendingPathComponent("기본", isDirectory: true)
            .appendingPathComponent("테두리 O", isDirectory: true)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        FileManager.default.createFile(
            atPath: nested.appendingPathComponent("독케익_일반선택.ani").path,
            contents: Data("x".utf8)
        )

        #expect(throws: CursorError.self) {
            try ThemeResolver().resolveTheme(in: tempDirectory)
        }
    }

    @Test
    func keepsExistingMatchesAndFallsBackMissingRolesToArrow() throws {
        let tempDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let folder = tempDirectory.appendingPathComponent("세트", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let files = [
            "독케익_일반선택.ani",
            "독케익_텍스트 선택.ani",
            "독케익_이동.ani"
        ]
        for file in files {
            FileManager.default.createFile(atPath: folder.appendingPathComponent(file).path, contents: Data("x".utf8))
        }

        let resolved = try ThemeResolver().resolveTheme(in: folder)
        #expect(resolved.filesByRole[.arrow] != nil)
        #expect(resolved.filesByRole[.text] != nil)
        #expect(resolved.filesByRole[.move] != nil)
        #expect(resolved.filesByRole[.link]?.lastPathComponent == "독케익_일반선택.ani")
    }

    @Test
    func resolvesCombinedKoreanRoleFilesForExpandedMacRoles() throws {
        let tempDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let folder = tempDirectory.appendingPathComponent("기본", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let files = [
            "독케익_일반선택.ani",
            "독케익_연결,위치,사용자 선택.ani",
            "독케익_백그라운드 작업,사용중.ani"
        ]

        for file in files {
            FileManager.default.createFile(atPath: folder.appendingPathComponent(file).path, contents: Data("x".utf8))
        }

        let resolved = try ThemeResolver().resolveTheme(in: folder)
        #expect(resolved.filesByRole[.arrow]?.lastPathComponent == "독케익_일반선택.ani")
        #expect(resolved.filesByRole[.link]?.lastPathComponent == "독케익_연결,위치,사용자 선택.ani")
        #expect(resolved.filesByRole[.location]?.lastPathComponent == "독케익_연결,위치,사용자 선택.ani")
        #expect(resolved.filesByRole[.busy]?.lastPathComponent == "독케익_백그라운드 작업,사용중.ani")
        #expect(resolved.filesByRole[.working]?.lastPathComponent == "독케익_백그라운드 작업,사용중.ani")
    }

    @Test
    func resolvesGenericEnglishCursorNames() throws {
        let tempDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let folder = tempDirectory.appendingPathComponent("Saber", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let files = [
            "Normal.ani",
            "Text.ani",
            "Link.ani",
            "Pin.ani",
            "Precision.ani",
            "Move.ani",
            "Unavailable.ani",
            "Busy.ani",
            "Working.ani",
            "Help.ani",
            "Handwriting.ani",
            "Person.ani",
            "Alternate.ani",
            "Vertical.ani",
            "Horizontal.ani",
            "Diagonal1.ani",
            "Diagonal2.ani"
        ]

        for file in files {
            FileManager.default.createFile(atPath: folder.appendingPathComponent(file).path, contents: Data("x".utf8))
        }

        let resolved = try ThemeResolver().resolveTheme(in: folder)
        #expect(resolved.filesByRole[.arrow]?.lastPathComponent == "Normal.ani")
        #expect(resolved.filesByRole[.text]?.lastPathComponent == "Text.ani")
        #expect(resolved.filesByRole[.link]?.lastPathComponent == "Link.ani")
        #expect(resolved.filesByRole[.location]?.lastPathComponent == "Pin.ani")
        #expect(resolved.filesByRole[.precision]?.lastPathComponent == "Precision.ani")
        #expect(resolved.filesByRole[.move]?.lastPathComponent == "Move.ani")
        #expect(resolved.filesByRole[.unavailable]?.lastPathComponent == "Unavailable.ani")
        #expect(resolved.filesByRole[.busy]?.lastPathComponent == "Busy.ani")
        #expect(resolved.filesByRole[.working]?.lastPathComponent == "Working.ani")
        #expect(resolved.filesByRole[.help]?.lastPathComponent == "Help.ani")
        #expect(resolved.filesByRole[.handwriting]?.lastPathComponent == "Handwriting.ani")
        #expect(resolved.filesByRole[.person]?.lastPathComponent == "Person.ani")
        #expect(resolved.filesByRole[.alternate]?.lastPathComponent == "Alternate.ani")
        #expect(resolved.filesByRole[.verticalResize]?.lastPathComponent == "Vertical.ani")
        #expect(resolved.filesByRole[.horizontalResize]?.lastPathComponent == "Horizontal.ani")
        #expect(resolved.filesByRole[.diagonalResizeNWSE]?.lastPathComponent == "Diagonal1.ani")
        #expect(resolved.filesByRole[.diagonalResizeNESW]?.lastPathComponent == "Diagonal2.ani")
    }

    @Test
    func doesNotMapAlternateToUnavailableWhenUnavailableExists() throws {
        let tempDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let folder = tempDirectory.appendingPathComponent("Ambiguous", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let files = [
            "Normal.ani",
            "Alternate.ani",
            "Unavailable.ani"
        ]

        for file in files {
            FileManager.default.createFile(atPath: folder.appendingPathComponent(file).path, contents: Data("x".utf8))
        }

        let resolved = try ThemeResolver().resolveTheme(in: folder)
        #expect(resolved.filesByRole[.arrow]?.lastPathComponent == "Normal.ani")
        #expect(resolved.filesByRole[.unavailable]?.lastPathComponent == "Unavailable.ani")
    }

    @Test
    func fallsBackToArrowWhenNoExactArrowMatchExists() throws {
        let tempDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let folder = tempDirectory.appendingPathComponent("Fallback", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let files = [
            "Mystery.ani",
            "Help.ani"
        ]

        for file in files {
            FileManager.default.createFile(atPath: folder.appendingPathComponent(file).path, contents: Data("x".utf8))
        }

        let resolved = try ThemeResolver().resolveTheme(in: folder)
        #expect(resolved.filesByRole[.help]?.lastPathComponent == "Help.ani")
        #expect(resolved.filesByRole[.arrow]?.lastPathComponent == "Mystery.ani")
    }

    @Test
    func fallsBackToThemeArrowForUnresolvedRoles() throws {
        let tempDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let folder = tempDirectory.appendingPathComponent("Partial", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let files = [
            "Normal.ani",
            "Help.ani"
        ]

        for file in files {
            FileManager.default.createFile(atPath: folder.appendingPathComponent(file).path, contents: Data("x".utf8))
        }

        let resolved = try ThemeResolver().resolveTheme(in: folder)
        #expect(resolved.filesByRole[.arrow]?.lastPathComponent == "Normal.ani")
        #expect(resolved.filesByRole[.help]?.lastPathComponent == "Help.ani")
        #expect(resolved.filesByRole[.text]?.lastPathComponent == "Normal.ani")
        #expect(resolved.filesByRole[.move]?.lastPathComponent == "Normal.ani")
        #expect(resolved.filesByRole[.verticalResize]?.lastPathComponent == "Normal.ani")
    }

    private func makeTemporaryDirectory() throws -> URL {
        let base = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let directory = base.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

struct CursorMatcherTests {
    @MainActor
    @Test
    func selfTestMatchesRegisteredSystemCursors() {
        let results = CursorMatcher().runSelfTest()
        #expect(!results.isEmpty)
        #expect(results.filter { !$0.passed }.isEmpty)
    }
}

struct CapeExporterTests {
    @MainActor
    @Test
    func exportsCapeFileWithMousecapeKeys() throws {
        let image = NSImage(size: NSSize(width: 16, height: 16))
        image.lockFocus()
        NSColor.white.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 16, height: 16)).fill()
        image.unlockFocus()

        let animation = CursorAnimation(
            frames: [CursorFrame(image: image, delay: 0.2)],
            hotspot: CGPoint(x: 1, y: 1),
            canvasSize: CGSize(width: 16, height: 16)
        )
        let theme = CursorTheme(animations: [
            .arrow: animation,
            .location: animation,
            .working: animation,
            .help: animation,
            .handwriting: animation,
            .person: animation,
            .alternate: animation
        ])

        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("cape")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        try CapeExporter().exportCape(
            name: "Test Cape",
            author: "Tester",
            identifier: "local.test.cape",
            theme: theme,
            to: tempURL
        )

        let data = try Data(contentsOf: tempURL)
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        let cursors = plist?["Cursors"] as? [String: Any]
        let arrow = cursors?["com.apple.coregraphics.Arrow"] as? [String: Any]
        let legacyArrow = cursors?["com.apple.cursor.0"] as? [String: Any]
        let copy = cursors?["com.apple.coregraphics.Copy"] as? [String: Any]
        let wait = cursors?["com.apple.coregraphics.Wait"] as? [String: Any]
        let help = cursors?["com.apple.cursor.40"] as? [String: Any]
        let cell = cursors?["com.apple.cursor.41"] as? [String: Any]
        let alias = cursors?["com.apple.coregraphics.Alias"] as? [String: Any]

        #expect(plist?["CapeName"] as? String == "Test Cape")
        #expect(plist?["Identifier"] as? String == "local.test.cape")
        #expect(arrow?["FrameCount"] as? Int == 1)
        #expect(legacyArrow?["FrameCount"] as? Int == 1)
        #expect(copy?["FrameCount"] as? Int == 1)
        #expect(wait?["FrameCount"] as? Int == 1)
        #expect(help?["FrameCount"] as? Int == 1)
        #expect(cell?["FrameCount"] as? Int == 1)
        #expect(alias?["FrameCount"] as? Int == 1)
        #expect((arrow?["Representations"] as? [Data])?.isEmpty == false)
    }
}
